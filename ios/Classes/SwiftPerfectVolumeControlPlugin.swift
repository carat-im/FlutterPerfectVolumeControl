import Flutter
import UIKit
import MediaPlayer
import AVFoundation

public class SwiftPerfectVolumeControlPlugin: NSObject, FlutterPlugin {
    /// 音量视图
    let volumeView = MPVolumeView(frame: .zero);

    /// Flutter 消息通道
    var channel: FlutterMethodChannel?;

    override init() {
        super.init();
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftPerfectVolumeControlPlugin()
        instance.channel = FlutterMethodChannel(name: "perfect_volume_control", binaryMessenger: registrar.messenger())
        instance.bindListener()
        registrar.addMethodCallDelegate(instance, channel: instance.channel!)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getVolume":
            self.getVolume(call, result: result);
            break;
        case "setVolume":
            self.setVolume(call, result: result);
            break;
        case "hideUI":
            self.hideUI(call, result: result);
            break;
        case "isAnotherAudioPlaying":
            self.isAnotherAudioPlaying(call, result: result);
            break;
        default:
            result(FlutterMethodNotImplemented);
        }

    }

    /// 获得系统当前音量
    public func getVolume(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient)
            try AVAudioSession.sharedInstance().setActive(true)
            result(AVAudioSession.sharedInstance().outputVolume);
        } catch let error as NSError {
            result(FlutterError(code: String(error.code), message: "\(error.localizedDescription)", details: "\(error.localizedDescription)"));
        }
    }

    /// 设置音量
    public func setVolume(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let volume = Float(((call.arguments as! [String: Any])["volume"]) as! Double);
        let forceSetAgainIfNotUpdated = (((call.arguments as! [String: Any])["forceSetAgainIfNotUpdated"]) as! Bool)
        var slider: UISlider?;
        for item in volumeView.subviews {
            if item is UISlider {
                slider = (item as! UISlider);
                break;
            }
        }

        if slider == nil {
            result(FlutterError(code: "-1", message: "Unable to get uislider", details: "Unable to get uislider"));
            return;
        }

        if slider!.value == volume && forceSetAgainIfNotUpdated {
            slider!.setValue(0, animated: false)
        }
        slider!.setValue(volume, animated: false)
        result(nil);
    }

    /// 隐藏UI
    public func hideUI(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let hide = ((call.arguments as! [String: Any])["hide"]) as! Bool;
        if hide {
            volumeView.alpha = 0.0001
            volumeView.isUserInteractionEnabled = false
            volumeView.showsRouteButton = false
            UIApplication.shared.delegate!.window!?.rootViewController!.view.addSubview(volumeView);
        } else {
            volumeView.removeFromSuperview();
        }
        result(nil);
    }

    func isAnotherAudioPlaying(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint)
    }

    /// 绑定监听器
    public func bindListener() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient)
            try AVAudioSession.sharedInstance().setActive(true)
            AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: [.new], context: nil)
        } catch let error as NSError {
            print("\(error)")
        }
    }

    /// 音量监听(KVO方式)
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let change = change, let value = change[.newKey] as? Float , keyPath == "outputVolume" else { return }
        channel?.invokeMethod("volumeChangeListener", arguments: value)
    }
}
