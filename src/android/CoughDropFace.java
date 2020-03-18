package com.mycoughdrop.coughdrop;

import android.app.Activity;
import android.os.Bundle;
import android.content.Context;

import com.google.ar.core.ArCoreApk;
import com.google.ar.core.TrackingState;
import com.google.ar.core.AugmentedFace;
import com.google.ar.core.Pose;
import com.google.ar.core.exceptions.*;
import java.util.EnumSet;
import java.util.Collection;
import com.google.ar.sceneform.ArSceneView;
import com.google.ar.sceneform.FrameTime;
import com.google.ar.sceneform.Scene;
import android.support.v4.app.FragmentTransaction;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import com.google.ar.sceneform.ux.ArFragment;
import java.nio.FloatBuffer;
import java.util.LinkedList;
import java.util.Queue;

import com.mycoughdrop.coughdrop.R;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;

import android.util.DisplayMetrics;

import android.util.Log;

import java.io.File;
import java.util.List;
import java.util.ArrayList;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Helper libraries used by CoughDrop mobile app
**/

public class CoughDropFace extends CordovaPlugin  {
  private static final String TAG = "CoughDropFace";
  private CallbackContext headCallback = null;
  
  @Override
  public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
    if(action.equals("status")) {
      return face_status(callbackContext);
    } else if(action.equals("face_start")) {
      return face_start(callbackContext);
    }
    return false;
  }

  // Display Metrics example, https://github.com/groupe-sii/cordova-plugin-device-display-metrics
  private boolean face_status(CallbackContext callbackContext) throws JSONException {
    JSONObject result = new JSONObject();
    ArCoreApk.Availability availability = ArCoreApk.getInstance().checkAvailability(this.cordova.getActivity().getApplicationContext());
    // TODO: https://developers.google.com/ar/develop/java/enable-arcore#check_supported
    // may need to re-check, also allow prompt when supported but not installed
    if(availability == ArCoreApk.Availability.SUPPORTED_INSTALLED) {
      result.put("supported", true);
      result.put("eyes", false);
      result.put("head", true);
      result.put("expressions", true);
    }
    DisplayMetrics metrics = this.cordova.getActivity().getApplicationContext().getResources().getDisplayMetrics();
    result.put("ppi", metrics.densityDpi);
    callbackContext.success(result);
    return true;
  }


  private double vert_distance(FloatBuffer buff, int i, int j) {
    float ax = buff.get(i * 3), ay = buff.get((i * 3) + 1), az = buff.get((i * 3) + 2);
    float bx = buff.get(j * 3), by = buff.get((j * 3) + 1), bz = buff.get((j * 3) + 2);
    // Don't bother with square roots
    float xdiff = (ax - bx) * (ax - bx);
    float ydiff = (ay - by) * (ay - by);
    float zdiff = (az - bz) * (az - bz);
    return xdiff + ydiff + zdiff;
  }

  private boolean check_state(Queue<Double> history, double current, double cutoff) {
    if(history.size() > 10) {
      history.poll();
    }
    Object[] past = history.toArray();
    boolean past_threshold = false;
    if(past.length > 5) {
      double avg = (((Double) past[0]).doubleValue() + ((Double) past[1]).doubleValue() + ((Double) past[2]).doubleValue()) / 3.0;
      if(cutoff > 0) {
        past_threshold = (current - avg) > cutoff;
      } else {
        past_threshold = (current - avg) < cutoff;
      }
    }
    if(!past_threshold) {
      history.offer(current);
    }
    return past_threshold;
  }

  private double[] euler_angles(AugmentedFace face) {
    double[] res = new double[3];
    Pose pose = face.getCenterPose();
    float[] quat = pose.getRotationQuaternion();
    double sqw = quat[3]*quat[3];
    double sqx = quat[0]*quat[0];
    double sqy = quat[1]*quat[1];
    double sqz = quat[2]*quat[2];
    res[0] = Math.atan2(2.0 * (quat[0]*quat[1] + quat[2]*quat[3]),(sqx - sqy - sqz + sqw));
    res[1] = Math.atan2(2.0 * (quat[1]*quat[2] + quat[0]*quat[3]),(-sqx - sqy + sqz + sqw));
    res[2] = Math.asin(-2.0 * (quat[0]*quat[2] - quat[1]*quat[3])/(sqx + sqy + sqz + sqw));
    return res;
  }

  double l4 = 0.4, l3 = 0.3, l2 = 0.2, l1 = 0.15;
  private double tilt_scale(double tilt, double factor) {
    double scale = 0;
    if(tilt > l4/factor) {
      scale = -5;
    } else if(tilt > l3/factor) {
      scale = -3; 
    } else if(tilt > l2/factor) {
      scale = -2;
    } else if(tilt > l1/factor) {
      scale = -1;
    } else if(tilt < -1*l4/factor) {
      scale = 5;
    } else if(tilt < -1*l3/factor) {
      scale = 3;
    } else if(tilt < -1*l2/factor) {
      scale = 2;
    } else if(tilt < -1*l1/factor) {
      scale = 1;
    }
    return scale;
  }

  private double heading = 0, bank = 0, attitude = 0;
  private double start_bank = -1, start_attitude = -1;
  private double last_bank = -1, last_attitude = -1;
  private Queue<Double> left_lids = new LinkedList<>();
  private Queue<Double> right_lids = new LinkedList<>();
  private Queue<Double> left_brows = new LinkedList<>();
  private Queue<Double> right_brows = new LinkedList<>();
  private Queue<Double> all_lips = new LinkedList<>();
  private Queue<Double> left_corners = new LinkedList<>();
  private Queue<Double> right_corners = new LinkedList<>();
  private Queue<Double> edge_corners = new LinkedList<>();
  private int head_tally = 0, same_head_tally = 0;
  private String last_action = "none";
  private int action_count = 0;
  private boolean face_start(CallbackContext callbackContext) throws JSONException {
    JSONObject result = new JSONObject();

    ArFragment currentFragment = ((MainActivity) cordova.getActivity()).assertArFragment();
    ArSceneView sceneView = currentFragment.getArSceneView();
    start_bank = -1;
    start_attitude = -1;
    if(sceneView == null) {
      result.put("error", true);
      result.put("ready", false);
      callbackContext.error(result);
      return true;
    }
    try {
      // sceneView.resume();
      Scene scene = sceneView.getScene();

      scene.addOnUpdateListener(
        (FrameTime frameTime) -> {
          Collection<AugmentedFace> faceList =
              sceneView.getSession().getAllTrackables(AugmentedFace.class);

          boolean lwink = false, rwink = false, lbrow = false, rbrow = false;
          boolean mouth = false, pucker = false, lsmirk = false, rsmirk = false;
          double left_lid = -1, right_lid = -1, left_brow = -1, right_brow = -1;
          double lips = -1, left_corner = -1, right_corner = -1, corners = -1;
          String action = "none";
          // Make new AugmentedFaceNodes for any new faces.
          for (AugmentedFace face : faceList) {
            if(face.getTrackingState() == TrackingState.TRACKING) {
              double[] euler = euler_angles(face);
              heading = euler[0];
              bank = euler[1];
              attitude = euler[2];

              // https://github.com/ManuelTS/augmentedFaceMeshIndices
              FloatBuffer vertices = face.getMeshVertices();
              // Calibrate - distance from 5 (top) to 4, nose height
              double nose_height = vert_distance(vertices, 5, 4);
              if(nose_height > 0) {
                // // Left wink - distance from 159 (top) to 145 should approach 0
                left_lid = vert_distance(vertices, 159, 145) / nose_height;
                lwink = check_state(left_lids, left_lid, -0.1);
                // // Right wink - distance from 386 (top) to 374 should approach 0
                right_lid = vert_distance(vertices, 386, 374) / nose_height;
                rwink = check_state(right_lids, right_lid, -0.1);
                double lid_diff = Math.abs(left_lid - right_lid);
                if((lwink || rwink) && lid_diff > 0.03) { action = "wink"; }
                // // Left eyebrow - distance from 223 (top) to 159 should increase
                left_brow = vert_distance(vertices, 223, 159) / nose_height;
                lbrow = check_state(left_brows, left_brow, 0.7);
                // // Right eyebrow - distance from 443 (top) to 386 should increase
                right_brow = vert_distance(vertices, 443, 386) / nose_height;
                rbrow = check_state(right_brows, right_brow, 0.7);
                if(lbrow && rbrow) { action = "eyebrows"; }
                // // Open mouth - distance from 11 (top) to 16 should increase
                lips = vert_distance(vertices, 11, 16) / nose_height;
                mouth = check_state(all_lips, lips, 20);
                if(mouth) { action = "mouth"; }
                // // Left smirk - distance from 206 (top) to 57 should decrease
                left_corner = vert_distance(vertices, 223, 184) / nose_height;
                lsmirk = check_state(left_corners, left_corner, -8);
                // // Right smirk - distance from 426 (top) to 287 should decrease
                right_corner = vert_distance(vertices, 191, 415) / nose_height;
                rsmirk = check_state(right_corners, right_corner, -6);
                if(lsmirk && rsmirk) {
                  action = "smile";
                } else if(lsmirk || rsmirk) {
                  action = "smirk";
                }
                // // Pucker - lips should part and distance from 78 to 308 should decrease
                corners = vert_distance(vertices, 78, 308) / nose_height;
                pucker = check_state(edge_corners, corners, -3);
                if(pucker && !mouth && lips > 3) { action = "kiss"; }
              }
            }
          }
          if(start_bank == -1 && start_attitude == -1) {
            start_bank = bank;
            start_attitude = attitude;
          }
          // negative bank == tilt up, negative == tilt right
          double vertscale = tilt_scale(start_bank - bank, 1.5);
          double horizscale = tilt_scale(attitude - start_attitude, 1.0);

          if(headCallback != null) {
            head_tally = head_tally + 1;
            // If head position is exactly the same, that
            // means it's not picking up new data and we
            // shouldn't send any events
            if(last_bank == bank && last_attitude == attitude) {
              same_head_tally++;
              if(same_head_tally > 20) {
                same_head_tally = 20;
              }
            } else {
              same_head_tally = 0;
            }
            last_bank = bank;
            last_attitude = attitude;
            if(action.equals(last_action) && !action.equals("none")) {
              action_count = action_count + 1;
            } else {
              action_count = 0;
            }
            last_action = action;
            if(head_tally >= 5 && same_head_tally < 20) {
              head_tally = 0;
              try {
                JSONObject head = new JSONObject();
                head.put("action", "head");
                if(action_count > 3) {
                  head.put("action", action);
                  left_lids.clear();
                  right_lids.clear();
                  left_brows.clear();
                  right_brows.clear();
                  all_lips.clear();
                  left_corners.clear();
                  right_corners.clear();
                  edge_corners.clear();
                }
                head.put("headX", horizscale);
                head.put("headY", vertscale);

                PluginResult pr = new PluginResult(PluginResult.Status.OK, head);
                pr.setKeepCallback(true);
                headCallback.sendPluginResult(pr);
              } catch(JSONException e) { }
            }
          }
        }
      );
      result.put("listening", true);
    } catch(Exception e) {
      result.put("error", true);
      result.put("type", e.toString());
    }

    headCallback = callbackContext;
    PluginResult pr = new PluginResult(PluginResult.Status.OK, result);
    pr.setKeepCallback(true);
    headCallback.sendPluginResult(pr);

    return true;
  }
}