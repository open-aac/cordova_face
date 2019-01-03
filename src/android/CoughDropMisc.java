package com.mycoughdrop.coughdrop;

import android.app.Activity;
import android.os.Bundle;
import android.hardware.Sensor;
import android.hardware.SensorEventListener;
import android.hardware.SensorEvent;
import android.hardware.SensorManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;
import com.mycoughdrop.coughdrop.R;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;


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

public class CoughDropMisc extends CordovaPlugin implements SensorEventListener {
  private static final String TAG = "CoughDropMisc";
  private SensorManager sensorManager;
  private CallbackContext lastSensorCallback = null;
  public static float lux = -1;
  
  @Override
  public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
    if (action.equals("listFiles")) {
      String dir = args.getJSONObject(0).getString("dir");
      JSONObject res = listFiles(dir);
      callbackContext.success(res);
      return true;
    } else if(action.equals("lux")) {
      if(CoughDropMisc.lux == -1) {
        lastSensorCallback = callbackContext;
        this.listen();
      } else {
        String message = Float.toString(CoughDropMisc.lux);
        callbackContext.success(message);
      }
      return true;
    } else if(action.equals("listApps")) {
      ArrayList<String> packages = new ArrayList<String>();
      PackageManager mgr = cordova.getActivity().getApplicationContext().getPackageManager();
      List<ApplicationInfo> apps = mgr.getInstalledApplications(0);
      for(ApplicationInfo info : apps) {
        packages.add(info.packageName.toString());
      }
      JSONArray list = new JSONArray(packages);
      callbackContext.success(list);
    }
    return false;
  }
  
  private JSONObject listFiles(String dir) throws JSONException {
    JSONObject result = new JSONObject();
    
    File root = new File(dir);
    result.put("my_path", dir);
    if(root.exists()) {
      result.put("valid", true);
    } else {
      result.put("valid", false);
    }
    result.put("path", cordova.getActivity().getApplicationContext().getFilesDir().getAbsolutePath());
    DirList dirs = walk(root);
    result.put("size", dirs.size);
    JSONArray js_array = new JSONArray(dirs.filenames);
    result.put("files", js_array);
    return result;
  }
  
  private class DirList {
    public long size = 0;
    public ArrayList<String> filenames;
    public DirList() {
      filenames = new ArrayList<String>();
    }
  }

  private DirList walk(File root) {
    DirList dir = new DirList();
    dir.filenames = new ArrayList<String>();
    
    if(root.exists() && root.isDirectory()) {
      File[] list = root.listFiles();

      for (File f : list) {
        if (f.isDirectory()) {
          DirList sub_dir = walk(f);
          dir.size = dir.size + sub_dir.size;
          dir.filenames.addAll(sub_dir.filenames);
        }

        else {
          dir.size = dir.size + f.length();
          dir.filenames.add(f.getName());
        }
      }
    }
    return dir;
  }
    
  private void handleSensorCallback() {
    if(lastSensorCallback != null) {
      if(CoughDropMisc.lux != -1) {
        lastSensorCallback.success(Float.toString(CoughDropMisc.lux));
      } else {
        lastSensorCallback.error("error");
      }
      lastSensorCallback = null;
    }
  }
  
  public void initialize(CordovaInterface cordova, CordovaWebView webView) {
    super.initialize(cordova, webView);
    this.sensorManager = (SensorManager) cordova.getActivity().getSystemService(Context.SENSOR_SERVICE);
  }
  
  public void listen() {
    List<Sensor> list = this.sensorManager.getSensorList(Sensor.TYPE_LIGHT);
    if(list != null && list.size() > 0) {
      Sensor sensor = list.get(0);
      this.sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL);
    }
  }
  
  @Override
  public final void onAccuracyChanged(Sensor sensor, int accuracy) {
    // Do something here if sensor accuracy changes.
  }

  @Override
  public final void onSensorChanged(SensorEvent event) {
    CoughDropMisc.lux = event.values[0];
    this.handleSensorCallback();
    // Do something with this sensor data.
  }
  

  /**
   * Called when listener is to be shut down and object is being destroyed.
   */
  public void onDestroy() {
    this.stop_sensors();
  }

  /**
   * Called when app has navigated and JS listeners have been destroyed.
   */
  public void onReset() {
    this.stop_sensors();
  }  
  
  /**
   * Stop listening to compass sensor.
   */
  public void stop_sensors() {
    this.sensorManager.unregisterListener(this);
  }
}