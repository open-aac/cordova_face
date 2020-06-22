import UIKit
import ARKit

@available(iOS 11.0, *)
@objc(MobileFace) class MobileFace : CDVPlugin {
  var triggerCallbackId:String = "";
  var triggerSet:Bool = false;
  let session = ARSession();
  var arViewController: MobileFaceController!
  @IBOutlet weak var sceneView: SCNView!

  @objc(echo:)
  func echo(command: CDVInvokedUrlCommand) {
    var pluginResult = CDVPluginResult(
      status: CDVCommandStatus_ERROR
    )

    let msg = command.arguments[0] as? String ?? ""

    if !msg.isEmpty {
      let toastController: UIAlertController =
        UIAlertController(
          title: "",
          message: msg,
          preferredStyle: .alert
        )
      
      self.viewController?.present(
        toastController,
        animated: true,
        completion: nil
      )

      DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        toastController.dismiss(
            animated: true,
            completion: nil
        )
      }
        
      pluginResult = CDVPluginResult(
        status: CDVCommandStatus_OK,
        messageAs: msg
      )
    }

    self.commandDelegate!.send(
      pluginResult,
      callbackId: command.callbackId
    )
  }
    @objc(status:)
    func status(command: CDVInvokedUrlCommand) {
        let supported = ARFaceTrackingConfiguration.isSupported;

        let res = ["supported":supported, "status":"ready"] as [AnyHashable:Any]
        
        let pluginResult = CDVPluginResult(
          status: CDVCommandStatus_OK,
          messageAs: res
        )

        self.commandDelegate!.send(
          pluginResult,
          callbackId: command.callbackId
        )
    }

    var already_listening = false;
    
    @objc(listen:)
    func listen(command: CDVInvokedUrlCommand) {
        NSLog("FACE SETUP")
        if(!triggerSet) { triggerCallbackId = ""; }
        if(!already_listening) {
            already_listening = true;
            let storyboard = UIStoryboard(name: "MobileFace",
                                          bundle: nil)
            guard let arViewController = storyboard.instantiateViewController(withIdentifier: "MobileFaceController") as? MobilesFaceController else {
                // TODO: 
                let res = ["error":true, "message": "MobileFaceController is not set in storyboard"] as [AnyHashable:Any]
                let pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAs: res
                )
                self.commandDelegate!.send(
                    pluginResult,
                    callbackId: command.callbackId
                );
                return;
            }
            self.arViewController = arViewController
            func action(_ data:GazeData) -> Bool {
              if(triggerSet && data.action != "none") {
                  let res = ["action":data.action, "gaze_x":data.gazeX, "gaze_y":data.gazeY, "head_tilt_x":data.headX, "head_tilt_y":data.headY, "eyes": (data.action == "gaze")] as [AnyHashable:Any]
                  
                  let pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAs: res
                  )
                  pluginResult?.setKeepCallbackAs(true)

                  self.commandDelegate!.send(
                    pluginResult,
                    callbackId: triggerCallbackId
                  )
              }
              return true;
            }
            self.arViewController.faceAction = [action];

            guard let superview = self.webView.superview else { return }
            superview.insertSubview(self.arViewController.view,
            belowSubview: self.webView)

        }
        var hashable:[AnyHashable:Any] = [:];
        if(command.arguments?.count ?? 0 > 0) {
            if(command.arguments?[0] != nil) {
                hashable = command.arguments?[0] as! [AnyHashable:Any];
            }
        }
        self.arViewController.gaze_enabled = (hashable["gaze"] as! Bool) || false;
        self.arViewController.head_enabled = (hashable["head"] as! Bool) || false;
        self.arViewController.follow_eyes = (hashable["eyes"] as! Bool) || false;
        self.arViewController.layout_fallback = "none";
        if(hashable["layout"] != nil) {
            self.arViewController.layout_fallback = (hashable["layout"] as! String);
        }
        NSLog("LAYOUT: \(hashable["layout"] ?? "n/a") \(self.arViewController.layout_fallback)")
        // TODO: support options for left-or-right-eye-only
        
        NSLog("Trigger Check")
        if(triggerSet) {
            let res = ["action":"end"] as [AnyHashable:Any]
            let pluginResult = CDVPluginResult(
              status: CDVCommandStatus_OK,
              messageAs: res
            )

            self.commandDelegate!.send(
              pluginResult,
              callbackId: triggerCallbackId
            )
        }
        triggerCallbackId = command.callbackId;
        triggerSet = true;
        NSLog("Trigger Set \(triggerCallbackId)")

        let res = ["action":"ready"] as [AnyHashable:Any]
        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: res
        )
        pluginResult?.setKeepCallbackAs(true)

        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
    }

    @objc(stop_listening:)
    func stop_listening(command: CDVInvokedUrlCommand) {
        NSLog("FACE TEARDOWN")
        
        if(!triggerSet) { triggerCallbackId = ""; }
        if(triggerSet) {
            let res = ["action":"end"] as [AnyHashable:Any]
            let pluginResult = CDVPluginResult(
              status: CDVCommandStatus_OK,
              messageAs: res
            )

            self.commandDelegate!.send(
              pluginResult,
              callbackId: triggerCallbackId
            )
            triggerCallbackId = "";
        }
        triggerSet = false;

        if(arViewController == nil) { return; }
        already_listening = false;
        self.arViewController.gaze_enabled = false;
        self.arViewController.head_enabled = true;
        self.arViewController.follow_eyes = true;
        self.arViewController.startx =  nil;
        self.arViewController.starty =  nil;
        self.arViewController.startz =  nil;


        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: "done"
        )

        arViewController.view.removeFromSuperview();
        arViewController.currentFrame = nil;
        arViewController.currentFaceAnchor = nil;
        self.arViewController = nil;
        
        
        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
    }
}
