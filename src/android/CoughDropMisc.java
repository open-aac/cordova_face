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
import android.media.AudioManager;
import android.media.AudioDeviceInfo;

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
      return true;
    } else if(action.equals("getAudioDevices")) {
      JSONArray list = new JSONArray(getAudioDevices());
      callbackContext.success(list);
    } else if(action.equals("setAudioMode")) {
      String mode = args.getString(0);
      return setAudioMode(mode, callbackContext);
    } else if(action.equals('bundleId')) {
      return bundleInfo(callbackContext);
    }
    return false;
  }

  private ArrayList<String> getAudioDevices() {
    Context context = webView.getContext();
    AudioManager audioManager = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);    
    
    ArrayList<String> devices = new ArrayList<String>();
    AudioDeviceInfo[] list = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS);
    for(AudioDeviceInfo device : list) {
      int type = device.getType();
      if(type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP || type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO) {
        devices.add("bluetooth");
      } else if(type == AudioDeviceInfo.TYPE_BUILTIN_EARPIECE) {
        devices.add("earpiece");
      } else if(type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER) {
        devices.add("speaker");
      } else if(type == 0x00000017 || // AudioDeviceInfo.TYPE_HEARING_AID
            type == AudioDeviceInfo.TYPE_USB_HEADSET || 
            type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES || 
            type == AudioDeviceInfo.TYPE_WIRED_HEADSET) {
        devices.add("headset");
      }
    }
    return devices;
  }

  private boolean bundleInfo(CallbackContext callbackContext) throws JSONException {
    JSONObject result = new JSONObject();
    result.put("bundle_id", this.cordova.getActivity().getApplicationContext().getPackageName());
    try {
      PackageInfo pInfo = context.getPackageManager().getPackageInfo(result.get('bundle_id'), 0);
      String version = pInfo.versionName;
      result.put('version', version);
    } catch (PackageManager.NameNotFoundException e) { }
    callbackContext.success(result);
    return true;
  }
  
  private boolean setAudioMode(String mode, CallbackContext callbackContext) throws JSONException {
    Context context = webView.getContext();
    AudioManager audioManager = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);    
    int previous_mode = audioManager.getMode();
    int new_mode = previous_mode;
    boolean previous_speaker = audioManager.isSpeakerphoneOn();
    boolean new_speaker = previous_speaker;
    if(mode.equals("bluetooth")) {
      new_mode = AudioManager.MODE_NORMAL;
      new_speaker = false;
    } else if(mode.equals("earpiece")) {
      new_mode = AudioManager.MODE_IN_COMMUNICATION;
      new_speaker = false;
    } else if(mode.equals("speaker")) {
      new_mode = AudioManager.MODE_IN_COMMUNICATION;
      new_speaker = true;
    } else if(mode.equals("headset")) {
      new_mode = AudioManager.MODE_NORMAL;
      new_speaker = false;
    } else if(mode.equals("default")) {
      new_mode = AudioManager.MODE_NORMAL;
      new_speaker = false;
    }
    int delay = 0;
    if(previous_mode != new_mode) {
      if(previous_mode != AudioManager.MODE_IN_COMMUNICATION && new_mode == AudioManager.MODE_IN_COMMUNICATION) {
        delay = 2000;
      }
      audioManager.setMode(new_mode);
    }
    if(previous_speaker != new_speaker) {
      if(!previous_speaker && new_speaker) {
        delay = 2000;
      }
      audioManager.setSpeakerphoneOn(new_speaker);
    }
    // set delay to 2000 mode or speakerphone was changed
    // res = {mode: mode, delay: 0};
    JSONObject result = new JSONObject();
    result.put("mode", mode);
    result.put("delay", delay);
    callbackContext.success(result);
    return true;
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