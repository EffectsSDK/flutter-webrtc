#import "LocalVideoTrack.h"

@class VideoEffectsSDKPipelineController;

@interface LocalVideoTrack (VideoEffectsSDK)

@property(nonatomic, strong, nullable) VideoEffectsSDKPipelineController* sdkPipelineController;

@end

@interface VideoProcessingAdapter (VideoEffectsSDK)

@property(nonatomic) bool sourceIsCamera;

@end
