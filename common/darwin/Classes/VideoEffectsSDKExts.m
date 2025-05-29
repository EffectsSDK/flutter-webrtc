#import "VideoEffectsSDKExts.h"
#import <objc/runtime.h>

@implementation LocalVideoTrack (VideoEffectsSDK)

- (VideoEffectsSDKPipelineController*)sdkPipelineController {
	return objc_getAssociatedObject(self, _cmd);
}

- (void)setSdkPipelineController:(id)controller {
	objc_setAssociatedObject(
		self,
		@selector(sdkPipelineController),
		controller,
		OBJC_ASSOCIATION_RETAIN_NONATOMIC
	);
}

@end

@implementation VideoProcessingAdapter (VideoEffectsSDK)

- (bool)sourceIsCamera {
	NSNumber* num = objc_getAssociatedObject(self, _cmd);
	return [num boolValue];
}

- (void)setSourceIsCamera:(bool)value {
	NSNumber* newNum = value? [NSNumber numberWithBool:value] : nil;
	objc_setAssociatedObject(
		self,
		@selector(sourceIsCamera),
		newNum,
		OBJC_ASSOCIATION_RETAIN_NONATOMIC
	);
}

@end
