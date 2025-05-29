# Flutter EffectsSDK integration

Tested for **flutter-webrtc v0.14.0**

## Instructions

Clone [flutter WebRTC](https://github.com/flutter-webrtc/flutter-webrtc) repository
```sh
git clone https://github.com/flutter-webrtc/flutter-webrtc.git
```

Go to the cloned dir.
```sh 
cd flutter-webrtc
```

[Optional] Switch to the required version
```sh
git switch -d v0.14.0
```
_For other versions, conflicts may occur._

Apply the [patch](flutter-webrtc-effects-sdk.patch) to the flutter-webrtc repo
```sh
curl https://raw.githubusercontent.com/EffectsSDK/flutter-webrtc-integration/refs/heads/main/flutter-webrtc-effects-sdk.patch | git apply
```
_You can mannually download the [patch](flutter-webrtc-effects-sdk.patch) and apply it with git apply path/to/patch_

Add flutter-webrtc as dependency to your project by path

pubspec.yaml
```yaml
dependencies:
  flutter_webrtc:
    path: path/to/flutter-webrtc
```

### Android

For android platform additionally you need:

1. Download the Video Effects SDK release for Android
2. Add the SDK as a WebRTC dependency by placing it in: **path/to/flutter-webrtc/android/libs/**

## How to use

1. Add effectsSdkRequired flag to your getUserMedia request

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

2. Call EffectsSDK methods by using WebRTC Helper

```dart

var status = await Helper.auth(stream.getVideoTracks().first, 'YOUR_CUSTOMER_ID');
switch (status) {
    case AuthStatus.active:
    await Helper.setEffectsSdkPipelineMode(stream.getVideoTracks().first, PipelineMode.blur);
    await Helper.setEffectsSdkBlurPower(stream.getVideoTracks().first, 0.6);
    case AuthStatus.expired:
    // TODO: Handle this case.
    case AuthStatus.inactive:
    // TODO: Handle this case.
    case AuthStatus.unavailable:
    // TODO: Handle this case.
}
```

## EffectsSDK methods

Check platform specifications:

1. [iOS](https://github.com/EffectsSDK/swift-video-effects-sdk)
2. [android](https://github.com/EffectsSDK/android-integration-sample)

### Effects SDK Image

Image proxy for iOS/android compatibility.

Can be created from:

1. raw data
2. file
3. encoded data
4. rgb color

### Color correction options

4 different methods are supported:

1. Color correction - use ML model for color correction
2. Color grading - made color filter by using reference image color scheme
3. Low light - use ML model for color correction (ust it only in dark places)
4. Preset - predefined cube lut


### Helper methods

| Name                                    | Summary                                                                                                   |
|-----------------------------------------|-----------------------------------------------------------------------------------------------------------|
| auth                                    | Future<rtc.AuthStatus> auth(String customerId, {String? apiUrl})<br/>Auth sdk by using customer ID        |
| localAuth                               | Future<rtc.AuthStatus> localAuth(String localKey)<br/>Auth SDK by using local key                         |
| getEffectsSdkPipelineMode               | Future<rtc.PipelineMode> getPipelineMode()<br/>Return current background processing mode                  |
| setEffectsSdkPipelineMode               | void setPipelineMode(rtc.PipelineMode mode)<br/>Set background processing mode                            |
| setEffectsSdkBlurPower                  | void setBlurPower(double blurPower)<br/>Set blur power                                                    |
| setEffectsSdkBackgroundImage            | void setBackgroundImage(rtc.EffectsSdkImage data)<br/>Set background image                                |
| enableEffectsSdkBeautification          | void enableBeautification(bool enable)<br/>Enable beautification feature                                  |
| isEffectsSdkBeautificationEnabled       | Future<bool> isBeautificationEnabled()<br/>Return true if beautification enabled                          |
| setEffectsSdkBeautificationPower        | void setBeautificationPower(double power)<br/>Set beautification power                                    |
| getEffectsSdkZoomLevel                  | Future<double> getZoomLevel()<br/>Get current zoom level                                                  |
| setEffectsSdkZoomLevel                  | void setZoomLevel(double zoomLevel)<br/>Set zoom level                                                    |
| enableEffectsSdkSharpening              | void enableSharpening(bool enable)<br/>Enable sharpening mode                                             |
| getEffectsSdkSharpeningStrength         | Future<double> getSharpeningStrength()<br/>Return current sharpening power                                |
| setEffectsSdkSharpeningStrength         | void setSharpeningStrength(double strength)<br/>Set sharpening power                                      |
| setEffectsSdkColorCorrectionMode        | void setColorCorrectionMode(rtc.ColorCorrectionMode colorCorrectionMode)<br/>Set color correction mode    |
| setEffectsSdkColorFilterStrength        | void setColorFilterStrength(double strength)<br/>Set color filter strength                                |
| setEffectsSdkColorGradingReferenceImage | void setColorGradingReferenceImage(rtc.EffectsSdkImage data)<br/>Set reference image for color correction |


## Technical details

Effects SDK included by using custom CameraVideoCapturer instance for Effects SDK camera pipeline(
android).
You can modify our solution as you need or try another way for integration (for example with custom
VideoProcessor).
Also you can replace CameraPipeline to lite version of it.

## Additional links

1. Platform documentation ([iOS](https://effectssdk.ai/sdk/ios/documentation/tsvb/), [android](https://github.com/EffectsSDK/android-integration-sample))
2. Effects SDK [site](https://effectssdk.ai/)
