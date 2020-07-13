
package com.mycoughdrop.coughdrop;

/** extends CordovaActivity */

import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import org.openaac.cordova_face.*;

public class MainActivity extends FragmentActivity implements ArMainActivity
{
    private static final String TAG = "MainActivity";

    public CordovaFragment currentFragment;
    public FaceArFragment arFragment = null;
    private boolean arPaused = false;

    @Override
    public void onCreate(Bundle savedInstanceState)
    {

        super.onCreate(savedInstanceState);
        currentFragment = new CordovaFragment();
        android.app.FragmentTransaction ft = getFragmentManager().beginTransaction();
        ft.add(android.R.id.content, currentFragment);
        ft.commit();
        
    }

    public FaceArFragment assertArFragment()
    {
        if(arFragment == null) {
            arFragment = new FaceArFragment();
            android.support.v4.app.FragmentTransaction ft2 = getSupportFragmentManager().beginTransaction();
            ft2.add(android.R.id.content, arFragment);
            ft2.hide(arFragment);
            ft2.commit();
            arPaused = false;
        } else if(arPaused) {
            try {
                arFragment.resumeAR();
                arPaused = false;
            } catch(Exception e) { }
        }
        return arFragment;
    }

    public void arPause()
    {
        if(arFragment != null && !arPaused) {
            arFragment.pauseAR();
            arPaused = true;
        }
    }

    /**
     * Called when the system is about to start resuming a previous activity.
     */
    @Override
    protected void onPause() {
        super.onPause();
        currentFragment.onPause();
    }

    /**
     * Called when the activity will start interacting with the user.
     */
    @Override
    protected void onResume() {
        super.onResume();
        currentFragment.onResume();
    }

    /**
     * Called when the activity is no longer visible to the user.
     */
    @Override
    protected void onStop() {
        super.onStop();
        currentFragment.onStop();
    }

    /**
     * Called when the activity is becoming visible to the user.
     */
    @Override
    protected void onStart() {
        super.onStart();
        currentFragment.onStart();
    }

    /**
     * The final call you receive before your activity is destroyed.
     */
    @Override
    public void onDestroy() {
        super.onDestroy();
        currentFragment.onDestroy();
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode,resultCode,data);
        currentFragment.onActivityResult(requestCode,resultCode,data);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String permissions[],
                                            int[] grantResults) {
        currentFragment.onRequestPermissionsResult(requestCode,permissions,grantResults);
    }
}

// /*
//        Licensed to the Apache Software Foundation (ASF) under one
//        or more contributor license agreements.  See the NOTICE file
//        distributed with this work for additional information
//        regarding copyright ownership.  The ASF licenses this file
//        to you under the Apache License, Version 2.0 (the
//        "License"); you may not use this file except in compliance
//        with the License.  You may obtain a copy of the License at

//          http://www.apache.org/licenses/LICENSE-2.0

//        Unless required by applicable law or agreed to in writing,
//        software distributed under the License is distributed on an
//        "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//        KIND, either express or implied.  See the License for the
//        specific language governing permissions and limitations
//        under the License.
//  */

// package org.openaac.cordova_face;

// import android.os.Bundle;
// import org.apache.cordova.*;

// public class MainActivity extends CordovaActivity
// {
//     @Override
//     public void onCreate(Bundle savedInstanceState)
//     {
//         super.onCreate(savedInstanceState);

//         // enable Cordova apps to be started in the background
//         Bundle extras = getIntent().getExtras();
//         if (extras != null && extras.getBoolean("cdvStartInBackground", false)) {
//             moveTaskToBack(true);
//         }

//         // Set by <content src="index.html" /> in config.xml
//         loadUrl(launchUrl);
//     }
// }
