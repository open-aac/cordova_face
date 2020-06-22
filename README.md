# Cordova Face/Head Tracking
Face/Head Tracking for Cordova. Using ARKit and ARCore, we
can leverage device hardware to add support for tracking
head position, facial expressions, and possibly eye gaze
location.

This Cordova head tracking plugin isn't built to support
facial overlays/masks that are popular for video chat, this
plugin is focused on extracting raw head/face information
to be used, for example, by accessibility apps for head
tracking and custom screen activation. There could be
other uses as well, but that is our focus.

## Installation
```
cordova plugin add https://github.com/open-aac/cordova_face
```

Look at src/android/MainActivity for an example replacement
for MainActivity.java in your app. There are other plugins
that do this, I didn't make up the idea, and they work fine
in my tests.

This plugin needs to add
a custom fragment in order to support face tracking (open
to other solutions if you have them!), hence the need to 
change the basic implementation.

## Usage

### Check Status
```js
cordova.exec(function(res) { 
  if(res && res.supported) {
    console.log("Face Tracking/TrueDepth is supported!");
    if(res.head !== false) {
      // head tracking is not supported
    }
    if(res.eyes !== false) {
      // eye tracking is not supported
    }
    if(res.ppi) {
      // ppi is useful for eye tracking
    }
  }
}, function(err) { 
  console.error('Exec Error', err); 
}, 'MobileFace', 'status', []);
```

### Listen for Updates
```js
cordova.exec(function(res) { 
  console.log("LISTEN EVENT", res);
  if(res.action == "ready") {
    // listen correctly initialized
  } else if(res.aciton == "end") {
    // listen session was terminated
  } else if(res.action == "gaze" || res.action == "head_point") {
    res.eyes; // bool for whether using eye tracking
    res.gaze_x; // x distance from camera in inches
    res.gaze_y; // y distance from camrea in inches
  } else if(res.action == "head_point") {

  } else if(res.action == "head") {
    res.head_tilt_x; // range [-5 (far left), 5 (far right)]
    res.head_tilt_y; // range [-5 (far up), 5 (far down)]
  } else {
    res.action; // expression (kiss, smile, wink, etc.)
  }
}, function(err) { 
  console.error('ERROR LISTENING', err); 
}, 'MobileFace', 'listen', [{gaze: true, eyes: true, head: false, layout: layout}]);
```

Note that for head-pointing and gaze tracking, screen location
data is <b>not</b> in pixels, but in inches from the camera. It
will be up to you to use ppi/dpi, devicePixelRatio and known
camera location to convert to screen coordinates.

### Stop Listening
```js
cordova.exec(function(res) { 
  console.log("STOPPED", res);
}, function(err) { 
  console.error('ERROR STOPPING', err); 
}, 'MobileFace', 'stop_listening', []);
```

## TODO
- Add js interface
- Implement https://github.com/ReallySmallSoftware/cordova-plugin-android-fragmentactivity/blob/master/scripts/android/afterPluginInstall.js, but include the original file in a comment so nothing is lost
- Auto-convert distance in inches to screen location
- Android doesn't actually stop tracking, hangs around forever (because it would crash when I tried to pause), this would be a great thing to fix :-D

## License
MIT License
