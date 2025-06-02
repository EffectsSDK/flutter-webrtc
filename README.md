# Flutter-WebRTC with Video Effects SDK

This repository contains the fork of [Flutter-WebRTC](https://github.com/flutter-webrtc/flutter-webrtc) with [Video Effects SDK](https://effectssdk.ai) integration. **Video Effects SDK** has built-in real-time AI video enhancements that makes video meeting experience more effective and comfortable to your application.  
  
This fork adds functional of **Video Effects SDK** into [Flutter-WebRTC](https://github.com/flutter-webrtc/flutter-webrtc) API and you can easily use it. **Video Effects SDK** has effect only when enabled, the SDK applies enhancements to frames in local video stream, else is the same as original flutter-webrtc.  
  
Supported platforms:  
* Android
* iOS

## How to use

1. Add git url into your dependencies. If original **Flutter-WebRTC** is already used, replace it with this fork.  

pubspec.yaml
```yaml
dependencies:
  flutter-webrtc:
    git:
      url: https://github.com/EffectsSDK/flutter-webrtc.git
```

2. Add `effectsSdkRequired` flag to your getUserMedia request

```dart
final mediaConstraints = <String, dynamic>{
  'audio': false,
  'video': {
    'mandatory': {
      'minWidth': '640',
      'minHeight': '480',
      'minFrameRate': '30',
    },
    'facingMode': 'user',
    'effectsSdkRequired': true,
    'optional': [],
  }
};
var stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
```

2. Call EffectsSDK methods by using VideoEffectsSdk

```dart
var status = await VideoEffectsSdk.auth(stream.getVideoTracks().first, 'YOUR_CUSTOMER_ID');
switch (status) {
    case AuthStatus.active:
    await VideoEffectsSdk.setPipelineMode(stream.getVideoTracks().first, PipelineMode.blur);
    await VideoEffectsSdk.setBlurPower(stream.getVideoTracks().first, 0.6);
    case AuthStatus.expired:
    // TODO: Handle this case.
    case AuthStatus.inactive:
    // TODO: Handle this case.
    case AuthStatus.unavailable:
    // TODO: Handle this case.
}
```

## Effects SDK API

Read about Effects SDK API you can on the  
[Effects SDK integration API Reference](https://effectssdk.ai/sdk/flutter-webrtc/)

## Technical details

Effects SDK included by using custom CameraVideoCapturer instance for Effects SDK camera pipeline(
android).
You can modify our solution as you need or try another way for integration (for example with custom
VideoProcessor).
Also you can replace CameraPipeline to lite version of it.

## Additional links

1. Platform documentation ([iOS](https://effectssdk.ai/sdk/ios/documentation/tsvb/), [android](https://github.com/EffectsSDK/android-integration-sample))
2. Effects SDK [site](https://effectssdk.ai/)