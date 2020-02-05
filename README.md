# Cordova Face/Head Tracking
Face/Head Tracking for Cordova

```
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
}, 'CoughDropFace', 'status', []);
```

```
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
}, 'CoughDropFace', 'listen', [{bacon: "asdf", gaze: true, eyes: true, head: false, layout: layout}]);
```

```
cordova.exec(function(res) { 
  console.log("STOPPED", res);
}, function(err) { 
  console.error('ERROR STOPPING', err); 
}, 'CoughDropFace', 'stop_listening', []);
```
s
## TODO
- Add js interface

## License
MIT License
