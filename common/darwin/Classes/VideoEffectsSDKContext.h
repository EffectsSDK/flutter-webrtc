#import <TSVB/TSVB.h>
#import <Flutter/Flutter.h>
#import "VideoProcessingAdapter.h"

typedef NS_ENUM(NSUInteger, AuthState) {
	AuthStateNotAuthorized,
	AuthStateAuthorizing,
	AuthStateAuthorized
};

typedef NS_ENUM(NSUInteger, ColorFilterError) {
	noError,
	unknownMode,
	noGradingReference,
	initializationFailed
};

NSString* _Nonnull nameOfAuthStatus(TSVBAuthStatus status);

@interface VideoEffectsSDKPipelineWrapper : NSObject<ExternalVideoProcessingDelegate>

- (nonnull instancetype)initWithSDKPipeline:(nonnull id<TSVBPipeline>)pipeline frameFactory:(nonnull id<TSVBFrameFactory>)frameFactory;

@property(nonatomic, readonly, nonnull) id<TSVBPipeline> pipeline;
@property(nonatomic, strong, nullable) id<TSVBReplacementController> replacementController;
@property(nonatomic) bool sourceIsCamera;

-(void)lock;
-(void)unlock;

@end

@interface VideoEffectsSDKPipelineController: NSObject

-(nonnull instancetype)initWithSDKFactory:(nonnull TSVBSDKFactory*)factory frameFactory:(nonnull id<TSVBFrameFactory>)frameFactory adapter:(nonnull VideoProcessingAdapter*)adapter;

-(nullable FlutterError*)setPipelineMode:(nonnull NSString*)mode;
-(nullable FlutterError*)setBeautificationEnabled:(bool)enabled;
-(nullable FlutterError*)setZoomLevel:(float)level;
-(nullable FlutterError*)setSharpeningEnabled:(bool)enabled;
-(nullable FlutterError*)setColorFilterMode:(nonnull NSString*)mode;

@property(nonatomic) float blurPower;
@property(nonatomic, readonly) bool beautificationEnabled;
@property(nonatomic) float beautificationPower;
@property(nonatomic, readonly) float zoomLevel;
@property(nonatomic) float sharpeningStrength;
@property(nonatomic) float colorFilterStrength;
@property(nonatomic, strong) _Nullable id<TSVBFrame> background;
@property(nonatomic, strong) _Nullable id<TSVBFrame> colorGradingReference;

@end

@interface VideoEffectsSDKContext : NSObject

@property(nonatomic, strong, readonly, nullable) TSVBSDKFactory* sdkFactory;
@property(nonatomic, strong, readonly, nullable) id<TSVBFrameFactory> frameFactory;

@property(atomic) enum AuthState authState;

-(nonnull VideoEffectsSDKPipelineController*) newPipelineControllerWithAdapter:(nonnull VideoProcessingAdapter*)adapter;

@end

@interface SDKFrameFactoryHelper : NSObject

+(nullable id<TSVBFrame>)solidFrameWithRed:(float)r green:(float)g blue:(float)b factory:(nullable  id<TSVBFrameFactory>)factory;

@end
