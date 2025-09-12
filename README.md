# Flutter-WebRTC with Video Effects SDK

This repository contains the fork of [Flutter-WebRTC](https://github.com/flutter-webrtc/flutter-webrtc) with [Video Effects SDK](https://effectssdk.ai) integration. **Video Effects SDK** has built-in real-time AI video enhancements that makes video meeting experience more effective and comfortable to your application.  
  
This fork adds functional of **Video Effects SDK** into [Flutter-WebRTC](https://github.com/flutter-webrtc/flutter-webrtc) API and you can easily use it. **Video Effects SDK** has effect only when enabled, the SDK applies enhancements to frames in local video stream, else is the same as original flutter-webrtc.  
  
Supported platforms:  
* Android
* iOS
* Web

## How to use

1. Add git url into your dependencies. If original **Flutter-WebRTC** is already used, replace it with this fork.  

There is some API differences between Web platform and mobile platforms.

pubspec.yaml
```yaml
dependencies:
  flutter-webrtc:
    git:
      url: https://github.com/EffectsSDK/flutter-webrtc.git
```

For the web, add the next line to your index.html.
```html
<script src="https://effectssdk.ai/sdk/web/3.5.7/tsvb-web.js"></script>
```

2. Initialize Video Effects SDK.

For the Web, call the [VideoEffectsSdk.initialize](https://effectssdk.ai/sdk/flutter-webrtc/flutter_webrtc/VideoEffectsSdk/initialize.html) method. This method should be called before creating the first local stream.

```dart
VideoEffectsSdk.initialize('YOUR_CUSTOMER_ID');
```
[VideoEffectsSdk.initialize](https://effectssdk.ai/sdk/flutter-webrtc/flutter_webrtc/VideoEffectsSdk/initialize.html) has an effect only on the web.

For Android and iOS, add the `effectsSdkRequired` flag to your getUserMedia request.

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

For the web, use [VideoEffectsSdk.wrapStream](https://effectssdk.ai/sdk/flutter-webrtc/flutter_webrtc/VideoEffectsSdk/wrapStream.html). 

```dart 
var stream = await VideoEffectsSdk.wrapStream(originalStream);
await VideoEffectsSdk.setPipelineMode(stream.getVideoTracks().first, PipelineMode.blur);
```

For the Android/iOS, use [VideoEffectsSdk.auth](https://effectssdk.ai/sdk/flutter-webrtc/flutter_webrtc/VideoEffectsSdk/auth.html).

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

The [VideoEffectsSdk.auth](https://effectssdk.ai/sdk/flutter-webrtc/flutter_webrtc/VideoEffectsSdk/auth.html) is optional for the web and can be skipped. For Android and iOS must be called before any Video Effects SDK filter is enabled.

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

1. Platform documentation ([iOS](https://effectssdk.ai/sdk/ios/documentation/tsvb/), [android](https://github.com/EffectsSDK/android-integration-sample), [web](https://effectssdk.ai/sdk/web/docs/classes/tsvb.html))
2. Effects SDK [site](https://effectssdk.ai/)