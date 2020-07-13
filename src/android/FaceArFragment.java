package org.openaac.cordova_face;

import android.os.Bundle;
import android.support.annotation.Nullable;
import android.view.LayoutInflater;
import android.view.View;
import android.util.Log;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import com.google.ar.core.Config;
import com.google.ar.core.Config.AugmentedFaceMode;
import com.google.ar.core.exceptions.CameraNotAvailableException;
import com.google.ar.core.Session;
import com.google.ar.sceneform.ux.ArFragment;
import java.util.EnumSet;
import java.util.Set;

/** Implements ArFragment and configures the session for using the augmented faces feature. */
public class FaceArFragment extends ArFragment {

  @Override
  protected Config getSessionConfiguration(Session session) {
    Config config = new Config(session);
    config.setAugmentedFaceMode(AugmentedFaceMode.MESH3D);
    return config;
  }

  @Override
  protected Set<Session.Feature> getSessionFeatures() {
    return EnumSet.of(Session.Feature.FRONT_CAMERA);
  }

  /**
   * Override to turn off planeDiscoveryController. Plane trackables are not supported with the
   * front camera.
   */
  @Override
  public View onCreateView(
      LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
    FrameLayout frameLayout =
        (FrameLayout) super.onCreateView(inflater, container, savedInstanceState);

    getPlaneDiscoveryController().hide();
    getPlaneDiscoveryController().setInstructionView(null);

    return frameLayout;
  }

  public void pauseAR() {
    if(this.getArSceneView() != null) {
      // try {
      //   this.getArSceneView().pause();
      // } catch(Exception err) {
      //   Log.d("ARCRASH", "PAUSE:" + err.toString());
      // }
    }
    // this.onPause();
  }

  public void resumeAR() {
    if(this.getArSceneView() != null) {
      // try {
      //   this.getArSceneView().resume();
      // } catch(CameraNotAvailableException e) { }
      // catch(Exception err) {
      //   Log.d("ARCRASH", "RESUME:" + err.toString());

      // }
    }
    // this.onResume();
  }

}