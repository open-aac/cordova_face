import UIKit
import ARKit

struct GazeData {
    var gazeX: Double
    var gazeY: Double
    var headX: Double
    var headY: Double
    var action: String
}
struct FaceExpressions {
    var smileLeft: Float = 0.0;
    var smileRight: Float = 0.0;
    var dimpleLeft: Float = 0.0;
    var dimpleRight: Float = 0.0;
    var jawOpen: Float = 0.0;
    var mouthPucker: Float = 0.0;
    var blinkLeft: Float = 0.0;
    var blinkRight: Float = 0.0;
    var squintLeft: Float = 0.0;
    var squintRight: Float = 0.0;
    var smirkLeft: Float = 0.0;
    var smirkRight: Float = 0.0;
    var cheekPuff: Float = 0.0;
    var browInnerUp: Float = 0.0;
    var tongueOut: Float = 0.0;
    var face_action: String?;
    @available(iOS 11.0, *)
    init(anchor: ARFaceAnchor?) {
        if(anchor != nil) {
            let shapes = anchor!.blendShapes;
            let smileLeft = shapes[.mouthSmileLeft]
            if(smileLeft != nil) { self.smileLeft = smileLeft!.floatValue; }
            let smileRight = shapes[.mouthSmileRight]
            if(smileRight != nil) { self.smileRight = smileRight!.floatValue; }
            let dimpleLeft = shapes[.mouthDimpleLeft]
            if(dimpleLeft != nil) { self.dimpleLeft = dimpleLeft!.floatValue; }
            let dimpleRight = shapes[.mouthDimpleRight]
            if(dimpleRight != nil) { self.dimpleRight = dimpleRight!.floatValue; }
            let jawOpen = shapes[.jawOpen]
            if(jawOpen != nil) { self.jawOpen = jawOpen!.floatValue; }
            let mouthPucker = shapes[.mouthPucker]
            if(mouthPucker != nil) { self.mouthPucker = mouthPucker!.floatValue; }
            let blinkLeft = shapes[.eyeBlinkLeft]
            if(blinkLeft != nil) { self.blinkLeft = blinkLeft!.floatValue; }
            let blinkRight = shapes[.eyeBlinkRight]
            if(blinkRight != nil) { self.blinkRight = blinkRight!.floatValue; }
            let squintLeft = shapes[.eyeSquintLeft]
            if(squintLeft != nil) { self.squintLeft = squintLeft!.floatValue; }
            let squintRight = shapes[.eyeSquintRight]
            if(squintRight != nil) { self.squintRight = squintRight!.floatValue; }
            let smirkLeft = shapes[.mouthStretchLeft]
            if(smirkLeft != nil) { self.smirkLeft = smirkLeft!.floatValue; }
            let smirkRight = shapes[.mouthStretchRight]
            if(smirkRight != nil) { self.smirkRight = smirkRight!.floatValue; }
            let cheekPuff = shapes[.cheekPuff]
            if(cheekPuff != nil) { self.cheekPuff = cheekPuff!.floatValue; }
            let browInnerUp = shapes[.browInnerUp]
            if(browInnerUp != nil) { self.browInnerUp = browInnerUp!.floatValue; }
            if #available(iOS 12.0, *) {
                // We currently don't use lookAtPoint, and instead extrapolate
                // from both eye transforms so in the future we can support only one eye if desired
                // Tongue is an iOS-12 feature
                let tongue = shapes[.tongueOut]
                if(tongue != nil) {
                    self.tongueOut = tongue!.floatValue;
                }
            }
            
            //            NSLog("sl\(smileLeft) dl\(dimpleLeft) sr\(smileRight) dr\(dimpleRight)")
            // Simple classifiers for identifying some facial gestures
            let expr = self;
            let lsmirk = expr.smirkLeft > 0.7 || expr.dimpleLeft > 0.3 || expr.smileLeft > 0.3;
            let rsmirk = expr.smirkRight > 0.7 || expr.dimpleRight > 0.3 || expr.smileRight > 0.3;
            if((expr.blinkLeft > 0.6 && expr.blinkRight < 0.4) || (expr.blinkLeft < 0.4 && expr.blinkRight > 0.6)) {
                self.face_action = "wink";
            } else if((expr.squintLeft > 0.8 && expr.squintRight < 0.3) || (expr.squintLeft < 0.3 && expr.squintRight > 0.8)) {
                self.face_action = "wink";
            } else if((lsmirk && !rsmirk) || (!lsmirk && rsmirk)) {
                self.face_action = "smirk";
            } else if(expr.smileLeft > 0.3 && expr.smileRight > 0.3) {
                self.face_action = "smile";
            } else if(expr.dimpleLeft > 0.5 && expr.dimpleRight > 0.5) {
                self.face_action = "smile";
            } else if(expr.tongueOut > 0.02) {
                self.face_action = "tongue";
            } else if(expr.jawOpen > 0.5) {
                self.face_action = "mouth_open";
            } else if(expr.mouthPucker > 0.5) {
                self.face_action = "kiss";
            } else if(expr.cheekPuff > 0.5) {
                self.face_action = "puff";
            } else if(expr.browInnerUp > 0.4) {
                self.face_action = "eyebrows";
            }

        }
    }
}

@available(iOS 11.0, *)
class MobileFaceController: UIViewController, ARSessionDelegate {
    
    @IBOutlet weak var sceneView: SCNView!
    let session = ARSession()
    // session.pause()
    // session.run(session.configuration);
    
    var faceAction: [(_ type:GazeData) -> Bool] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.backgroundColor = .clear
        self.sceneView.scene = SCNScene()
        self.sceneView.rendersContinuously = true
        
        // floating mask node
        if let device = MTLCreateSystemDefaultDevice(), let geo = ARSCNFaceGeometry(device: device) {
        }
        
        // configure our ARKit tracking session for facial recognition
        let config = ARFaceTrackingConfiguration()
        // set the camera as coordinates origin
        config.worldAlignment = .camera
        session.delegate = self
        session.run(config, options: [])
    }
    
    
    var currentFaceAnchor: ARFaceAnchor?
    var currentFrame: ARFrame?
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        self.currentFrame = frame
        DispatchQueue.main.async {
            // need to call heart beat on main thread
            self.processNewARFrame()
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }
        self.currentFaceAnchor = faceAnchor
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }
        if(faceAnchor == self.currentFaceAnchor) {
            self.currentFaceAnchor = nil
        }
    }
    
    // 5 different levels of movement are supported, based on how far they turn
    let l4:Float = 0.1;
    let l3:Float = 0.08;
    let l2:Float = 0.07;
    let l1:Float = 0.05;
    let l0:Float = 0.035;
    func tilt_scale(tilt: Float, factor: Float) -> Double {
        var scale = 0.0;
        if(tilt > l4/factor) {
            scale = 5; // down
        } else if(tilt > l3/factor) {
            scale = 3;
        } else if(tilt > l2/factor) {
            scale = 2;
        } else if(tilt > l1/factor) {
            scale = 1;
        } else if(tilt > l0/factor) {
            scale = 0.5;
        } else if(tilt < -l4/factor) {
            scale = -5; // up
        } else if(tilt < -l3/factor) {
            scale = -3;
        } else if(tilt < -l2/factor) {
            scale = -2;
        } else if(tilt < -l1/factor) {
            scale = -1;
        } else if(tilt < -l0/factor) {
            scale = -0.5;
        }
        return scale;
    }
    
    func head_tilts(node: SCNNode) -> (Double, Double) {
        // Rotation is used for head-as-a-joystick
        var vertfactor:Float = 1.5;
        var horizfactor:Float = 1.0;
        if((self.layout_fallback == "none" && (UIDevice.current.orientation == .landscapeLeft ||  UIApplication.shared.statusBarOrientation == .landscapeLeft)) || self.layout_fallback == "landscape-primary") {
        } else if((self.layout_fallback == "none" && (UIDevice.current.orientation == .portrait || UIApplication.shared.statusBarOrientation == .portrait)) || self.layout_fallback == "portrait-primary") {
            node.localRotate(by:SCNQuaternion.init(0.0, 0.0, 1.0, 0.785))
            vertfactor = 1.0;
            horizfactor = 1.5;
        } else if((self.layout_fallback == "none" && (UIDevice.current.orientation == .landscapeRight ||  UIApplication.shared.statusBarOrientation == .landscapeRight)) || self.layout_fallback == "landscape-secondary") {
        } else if((self.layout_fallback == "none" && (UIDevice.current.orientation == .portraitUpsideDown || UIApplication.shared.statusBarOrientation == .portraitUpsideDown)) || self.layout_fallback == "portrait-secondary") {
            node.localRotate(by:SCNQuaternion.init(0.0, 0.0, 1.0, 0.785))
            vertfactor = 1.0;
            horizfactor = 1.5;
        }
        let rotation = node.worldOrientation
        if(startx == nil) { startx = rotation.x; }
        if(starty == nil) { starty = rotation.y; }
        if(startz == nil) { startz = rotation.z; }
        let vert = rotation.x - startx;
        let horiz = rotation.y - starty;
        
        var vertscale = tilt_scale(tilt: vert, factor: vertfactor * tilt_factor);
        var horizscale = tilt_scale(tilt: horiz, factor: horizfactor * tilt_factor);

        if((self.layout_fallback == "none" && (UIDevice.current.orientation == .landscapeLeft ||  UIApplication.shared.statusBarOrientation == .landscapeLeft)) || self.layout_fallback == "landscape-primary") {
        } else if((self.layout_fallback == "none" && (UIDevice.current.orientation == .portrait || UIApplication.shared.statusBarOrientation == .portrait)) || self.layout_fallback == "portrait-primary") {
        } else if((self.layout_fallback == "none" && (UIDevice.current.orientation == .landscapeRight ||  UIApplication.shared.statusBarOrientation == .landscapeRight)) || self.layout_fallback == "landscape-secondary") {
            let ref = horizscale;
            horizscale = -1 * vertscale;
            vertscale = ref;
        } else if((self.layout_fallback == "none" && (UIDevice.current.orientation == .portraitUpsideDown || UIApplication.shared.statusBarOrientation == .portraitUpsideDown)) || self.layout_fallback == "portrait-secondary") {
            let ref = horizscale;
            horizscale = vertscale;
            vertscale = -1 * ref;
        }
        return (vertscale, horizscale);
    }
    
    func eye_locations(node: SCNNode) -> (SCNVector3, SCNVector3) {
        // The eye transforms are defined relative to the head position, so
        // we need to multiple the matrices to get the correct orientation
        let faceMatrix = SCNMatrix4.init(self.currentFaceAnchor!.transform)
        let faceNode = SCNNode()
        faceNode.transform = faceMatrix;
        if((self.layout_fallback == "none" && (UIDevice.current.orientation == .landscapeLeft ||  UIApplication.shared.statusBarOrientation == .landscapeLeft)) || self.layout_fallback == "landscape-primary") {
            // landscape defaults have a slight head tilt that needs to be factored in
            let orientation = faceNode.orientation
            var glQuaternion = GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w)

            // Rotate around Z axis
            let multiplier = GLKQuaternionMakeWithAngleAndAxis(-0.1, 0, 0, 1)
            glQuaternion = GLKQuaternionMultiply(glQuaternion, multiplier)

            faceNode.orientation = SCNQuaternion(x: glQuaternion.x, y: glQuaternion.y, z: glQuaternion.z, w: glQuaternion.w)
        } else if((self.layout_fallback == "none" && (UIDevice.current.orientation == .portrait || UIApplication.shared.statusBarOrientation == .portrait)) || self.layout_fallback == "portrait-primary") {
        } else if((self.layout_fallback == "none" && (UIDevice.current.orientation == .landscapeRight ||  UIApplication.shared.statusBarOrientation == .landscapeRight)) || self.layout_fallback == "landscape-secondary") {
            // landscape defaults have a slight head tilt that needs to be factored in
            let orientation = faceNode.orientation
            var glQuaternion = GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w)

            // Rotate around Z axis
            let multiplier = GLKQuaternionMakeWithAngleAndAxis(0.1, 0, 0, 1)
            glQuaternion = GLKQuaternionMultiply(glQuaternion, multiplier)

            faceNode.orientation = SCNQuaternion(x: glQuaternion.x, y: glQuaternion.y, z: glQuaternion.z, w: glQuaternion.w)
        } else if((self.layout_fallback == "none" && (UIDevice.current.orientation == .portraitUpsideDown || UIApplication.shared.statusBarOrientation == .portraitUpsideDown)) || self.layout_fallback == "portrait-secondary") {
        }
        var leftEyeWorldLocation = node.worldPosition;
        var rightEyeWorldLocation = node.worldPosition;
        if #available(iOS 12.0, *) {
            let leftEyeMatrix = simd_mul(simd_float4x4(faceNode.transform), self.currentFaceAnchor!.leftEyeTransform)
            node.transform = SCNMatrix4.init(leftEyeMatrix);
            // Next we send a vector straight "ahead", which will help us
            // project the point onto the plane where z=0 (screen coordinates)
            node.localTranslate(by:SCNVector3.init(0.0, 0.0, 1.0))
            leftEyeWorldLocation = node.worldPosition;
            let rightEyeMatrix = simd_mul(simd_float4x4(faceNode.transform), self.currentFaceAnchor!.rightEyeTransform)
            node.transform = SCNMatrix4.init(rightEyeMatrix);
            node.localTranslate(by:SCNVector3.init(0.0, 0.0, 1.0))
            rightEyeWorldLocation = node.worldPosition;
        }
        return (leftEyeWorldLocation, rightEyeWorldLocation);
    }
    
    func current_orientation() -> (String) {
        var screen_orientation = "portrait-primary";
        var can_check_io = false;
        if #available(iOS 13.0, *) {
            can_check_io = true;
        }
        if(UIDevice.current.orientation.isValidInterfaceOrientation || !can_check_io) {
            if(UIDevice.current.orientation == .portrait) {
                screen_orientation = "portrait-primary";
            } else if(UIDevice.current.orientation == .portraitUpsideDown) {
                screen_orientation = "portrait-secondary";
            } else if(UIDevice.current.orientation == .landscapeLeft) {
                screen_orientation = "landscape-secondary";
            } else if(UIDevice.current.orientation == .landscapeRight) {
                screen_orientation = "landscape-primary";
            }
        } else {
            if #available(iOS 13.0, *) {
                let io = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
                if(io == .portrait) {
                    screen_orientation = "portrait-primary";
                } else if(io == .portraitUpsideDown) {
                    screen_orientation = "portrait-secondary";
                } else if(io == .landscapeLeft) {
                    screen_orientation = "landscape-secondary";
                } else if(io == .landscapeRight) {
                    screen_orientation = "landscape-primary";
                }
            };
        }
        return screen_orientation;
    }
    
    func project_to_z(left: SCNVector3, right: SCNVector3, eyes: Bool, head: SCNVector3) -> (Double, Double) {
        // World location of the current gaze for both eyes
        let headx = head.x*100;
        let heady = head.y*100;
        let headz = head.z*100;
        var leftx = left.x*100// - headx;
        var lefty = left.y*100// - heady;
        var leftz = left.z*100// - headz;
        var rightx = right.x*100// - headx;
        var righty = right.y*100// - heady;
        var rightz = right.z*100// - headz;
        // head_factor is a sensitivity setting
        // NOTE: we are ignoring tilt_factor here because we factor it in elsewhere.
        // If you would like to use it, you will need to know the ppi for the device,
        // shift based on the screen center, apply the tilt_factor and then shift back
        var head_factor:Float = 0.2; // absolute max of 0.8, 0.6 is manageable
        // head_factor of 0.0 is pretty sensitive imo, 0.2 is a fine default
        if(!eyes) {
            // If using head as a pointer, we soften the angle slightly
            // to support a little broader range of motion.
            leftx -= (leftx - headx) * head_factor;
            lefty -= (lefty - heady) * (head_factor + 0.15);
            rightx -= (rightx - headx) * head_factor;
            righty -= (righty - heady) * (head_factor + 0.15);
        }
        // This section is using ratios of similar triangles to
        // help us determine x and y location of eye each vector when z=0
        let lratiox = abs(headx - leftx) / abs(headz - leftz);
        let lratioy = abs(heady - lefty) / abs(headz - leftz);
        let rratiox = abs(headx - rightx) / abs(headz - rightz);
        let rratioy = abs(heady - righty) / abs(headz - rightz);
        let meters_to_inches = 39.3701; // Useful since we'll be relying on ppi
        var lx = headx - abs(lratiox * headz);
        var ly = heady - abs(lratioy * headz);
        // bx and by were a sanity-check, since they should always equal ax and ay
//                var bx = leftx + abs(lratiox * leftz);
//                var by = lefty + abs(lratioy * leftz);
        var rx = headx - abs(rratiox * headz);
        var ry = heady - abs(rratioy * headz);
        if(headx < leftx) {
            lx = headx + abs(lratiox * headz);
//                    bx = leftx - abs(lratiox * leftz);
        }
        if(heady < lefty) {
            ly = heady + abs(lratioy * headz);
//                    by = lefty - abs(lratioy * leftz);
        }
        if(headx < rightx) {
            rx = headx + abs(rratiox * headz);
        }
        if(heady < righty) {
            ry = heady + abs(rratioy * headz);
        }
        // Last we convert to inches since absolute coordinates can leverage
        // known ppi to convert gaze to actual pixel coordinates.
        // NOTE: If you are including a calibration step these conversions
        // aren't really necessary, but they won't get in the way either.
        var originx = (Double((lx + rx) / 2.0) * meters_to_inches);
        var originy = (Double((ly + ry) / 2.0) * meters_to_inches);
        var mode = "some";
        // We normalize our coordinates based on the following assumptions:
        // Origin (x=0, y=0 should be the currrent location of the camera)
        // For x: looking left of the camera = negative, looking right = positive
        // For y: looking above the camera = positive, looking down = negative
        
        let screen_orientation = current_orientation();
        
        if((self.layout_fallback == "none" && screen_orientation == "landscape-primary") || self.layout_fallback == "landscape-primary") {
            // Magic numbers for a better "default" (NOTE: only tested on iPad Pro 13 & 10")
            originx -= 140;
            originy -= 40;
            originy *= -3
            mode = "landleft";
        } else if((self.layout_fallback == "none" && screen_orientation == "portrait-primary") || self.layout_fallback == "portrait-primary") {
            let ref = originx;
            originx = originy;
            originy = ref;
            // Magic numbers for a better "default" (NOTE: only tested on iPad Pro 13 & 10")
            originx -= 30;
            originx *= 3;
            originy -= 150;
            originy *= 4;
            mode = "portrait"
        } else if((self.layout_fallback == "none" && screen_orientation == "landscape-secondary") || self.layout_fallback == "landscape-secondary") {
            originy *= -1;
            originx *= -1;
            // Magic numbers for a better "default" (NOTE: only tested on iPad Pro 13 & 10")
            originx += 50;
            originx *= 1.7;
            originy -= 300;
            originy *= -4;
            mode = "landright";
        } else if((self.layout_fallback == "none" && screen_orientation == "portrait-secondary") || self.layout_fallback == "portrait-secondary") {
            let ref = originx;
            originx = originy;
            originy = ref;
            originx *= -1;
            // Magic numbers for a better "default" (NOTE: only tested on iPad Pro 13 & 10")
            originx -= 100
            originx *= 1.7
            originy -= 350
            originy *= -1.35
            mode = "portrait-upside-down"
        }
        return (originx, originy);
    }
    
    
    var last_action = "none";
    var action_count = 0;
    var gaze_tally = 0;
    var head_tally = 0;
    var startx:Float!, starty:Float!, startz:Float!;
    var gaze_enabled = true;
    var head_enabled = true;
    var left_eye_only = false;
    var right_eye_only = false;
    var tilt_factor:Float! = 1.0;
    var follow_eyes = true;
    var layout_fallback = "none";
    var gaze_sum_x = 0.0, gaze_sum_y = 0.0;
    var originx_history:[Double] = [];
    var originy_history:[Double] = [];
    var lastx:Double = -1;
    var lasty:Double = -1;
    func processNewARFrame() {
        // Called each time ARKit updates our frame (aka we have new facial recognition data)
        if(self.currentFrame == nil || self.currentFaceAnchor == nil) {
            return;
        }
        if(!(self.currentFaceAnchor?.isTracked ?? false)) {
            return;
        }

        // Sample useful facial gesturess
        let expr = FaceExpressions(anchor: self.currentFaceAnchor);
        var eyeLocation:SCNVector3!
        if #available(iOS 12.0, *) {
            // We currently don't use lookAtPoint, and instead extrapolate
            // from both eye transforms so in the future we can support only one eye if desired
            if(self.currentFaceAnchor != nil) {
                eyeLocation = SCNVector3.init(self.currentFaceAnchor!.lookAtPoint);
            }
        }
        // Head orientation is our starting transform (the camera is located at the origin)
        let headOrientation = self.currentFaceAnchor?.transform
        if(headOrientation != nil) {
            let faceMatrix = SCNMatrix4.init(self.currentFaceAnchor!.transform)
            let node = SCNNode()

            node.transform = faceMatrix
            let tilts = head_tilts(node: node);
            let vertscale = tilts.0;
            let horizscale = tilts.1;

            if(eyeLocation != nil) {
                let headWorldLocation = node.worldPosition;
                var leftEyeWorldLocation = node.worldPosition;
                var rightEyeWorldLocation = node.worldPosition;
                var eyes_used = false;
                if(follow_eyes) {
                    if #available(iOS 12.0, *) {
                        // Measure both eyes so we can take an average of their positions
                        eyes_used = true;
                        let eyes = eye_locations(node: node);
                        leftEyeWorldLocation = eyes.0;
                        rightEyeWorldLocation = eyes.1;
                        if(left_eye_only) {
                            rightEyeWorldLocation = leftEyeWorldLocation;
                        } else if(right_eye_only) {
                            leftEyeWorldLocation = rightEyeWorldLocation;
                        }
                    }
                }
                if(!eyes_used) {
                    // Use head direction as a proxy for eye location (assume eyes are fixed)
                    node.localTranslate(by:SCNVector3.init(0.0, 0.0, 1.0))
                    leftEyeWorldLocation = node.worldPosition;
                    rightEyeWorldLocation = node.worldPosition;
                }

                
                let projection = project_to_z(left: leftEyeWorldLocation, right: rightEyeWorldLocation, eyes: eyes_used, head: headWorldLocation);
                var originx = projection.0;
                var originy = projection.1;

                // We average out clusters of events to reduce some noise
                // NOTE: additional smoothing may prove useful, but is left for future work
                let gaze_cutoff = 10;
                if(gaze_enabled) {
                    gaze_tally += 1;
                    while(originx_history.count > 30) {
                        originx_history.remove(at: 0);
                    }
                    while(originy_history.count > 30) {
                        originy_history.remove(at: 0);
                    }
                    if(gaze_tally >= gaze_cutoff) {
                        var action = "gaze";
                        if(!eyes_used) {
                            action = "head_point";
                        }
                        if(originx_history.count > 5) {
                            let tallyx = originx_history.reduce(0, +);
                            let tallyy = originy_history.reduce(0, +);
                            originx = tallyx / Double(originx_history.count);
                            originy = tallyy / Double(originy_history.count);
                            
                            if(lastx != -1 || lasty != -1)
                            {
                                // If the previous cluster center is nearer to the new
                                // cluster center than a factor of the average distance of the
                                // cells in the current cluster, then use the previous center
                                // cluster plus slightly shifted
                                let origin_mapx = originx_history.map { abs($0 - originx) };
                                let distancex = origin_mapx.reduce(0, +) / Double(originx_history.count);
                                let origin_mapy = originy_history.map { abs($0 - originx) };
                                let distancey = origin_mapy.reduce(0, +) / Double(originy_history.count);
                                let prior_distancex = abs(lastx - originx);
                                let prior_distancey = abs(lasty - originy);
                                let distance_factor = 1.05;
                                if(prior_distancex < distancex * distance_factor && prior_distancey < distancey * distance_factor) {
                                    originx = (originx + (lastx * 4.0)) / 5.0;
                                    originy = (originy + (lasty * 4.0)) / 5.0;
                                }
                            }
                        } else if(gaze_cutoff <= 20) {
                            // Collect events between messages for a smoothing average
                            originx = (originx + gaze_sum_x) / Double(gaze_tally + 1);
                            originy = (originy + gaze_sum_y) / Double(gaze_tally + 1);
                        }
                        
                        lastx = originx;
                        lasty = originy;
                        self.faceAction[0](GazeData(gazeX:originx/100.0, gazeY:originy/100.0, headX: 0, headY: 0, action: action)); 
//                        NSLog("\(self.layout_fallback)")
//                        NSLog("\(mode) \(self.layout_fallback)\norig: \(originx),\(originy)\nhead: \(headx),\(heady),\(headz)\nturn: \(rotation.x),\(rotation.y),\(rotation.z)\nlook: \(eyeLocation.x*100),\(eyeLocation.y*100),\(eyeLocation.z*100)\nleft: \(leftx),\(lefty),\(leftz)\nrght:\(rightx),\(righty),\(rightz)\n")
                        gaze_tally = 0;
                        gaze_sum_x = 0.0;
                        gaze_sum_y = 0.0;
                    } else {
                        originx_history.append(originx);
                        originy_history.append(originy);
                    }
                }
            }
            var action = "none";
            if(expr.face_action != nil) {
                action = expr.face_action!;
            }

            if(action == last_action && action != "none") {
                action_count += 1;
            } else {
                action_count = 0;
                last_action = action;
            }
            if(action_count > 3) {
                // Require a tiny "hold" of the gesture before it is activated
                self.faceAction[0](GazeData(gazeX: 0, gazeY: 0, headX: 0, headY: 0, action: action));
                action_count = -200;
            } else if(vertscale != 0 || horizscale != 0) {
                if(head_enabled) {
                    head_tally += 1;
                    if(head_tally >= 5) {
                        self.faceAction[0](GazeData(gazeX: 0, gazeY: 0, headX: horizscale, headY: vertscale, action: "head"));
                        head_tally = 0;
                    }
                }
            }
        } else {
            // TODO: only clear this on calibrate, trigger calibration if unset
            startx = nil;
            starty = nil;
            startz = nil;
        }
    }
}
