#import "VideoEffectsSDKContext.h"
#import "VideoEffectsSDKExts.h"

typedef enum ColorFilterMode_ {
	noColorFilter,
	mlColorCorrection,
	colorGrading,
	lowLight,
} ColorFilterMode;

static TSVBRotation toTSVBRotation(RTCVideoRotation rtcRotation) 
{
	return (TSVBRotation)((360 - (int)rtcRotation) % 360);
}

static ColorFilterMode mapColorFilterName(NSString* mode) {
	NSDictionary<NSString*, NSNumber*>* modeNameMap = @{
		@"ColorCorrectionMode.noFilterMode" : @(noColorFilter),
		@"ColorCorrectionMode.colorCorrectionMode" : @(mlColorCorrection),
		@"ColorCorrectionMode.colorGradingMode" : @(colorGrading),
		@"ColorCorrectionMode.lowLightMode" : @(lowLight),
	};
	
	NSNumber* modeNum = modeNameMap[mode];
	return [modeNum intValue];
}

// Copies the numbers of `source` into `target`; null (NSNull) and other values are skipped.
static void mergeNumbers(NSMutableDictionary<NSString*, NSNumber*>* target, NSDictionary* source)
{
	[source enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop) {
		if ([key isKindOfClass:[NSString class]] && [value isKindOfClass:[NSNumber class]]) {
			target[key] = value;
		}
	}];
}

// The pipeline is thread-safe (SDK 2.6.0+): effects are configured from the main thread while
// frames are processed on the capturer thread, which is the only caller of process.
@implementation VideoEffectsSDKPipelineWrapper
{
	id<TSVBPipeline> _sdkPipeline;
	id<TSVBReplacementController> _replacementController;
	id<TSVBFrameFactory> _frameFactory;
	bool _sourceIsCamera;
	
	NSMutableData* _bgraData;
	id<TSVBFrame> _bgraInput;
}

@synthesize replacementController = _replacementController;
@synthesize sourceIsCamera = _sourceIsCamera;

-(instancetype)initWithSDKPipeline:(id<TSVBPipeline>)pipeline frameFactory:(id<TSVBFrameFactory> _Nonnull)frameFactory {
	self = [super init];
	if (self) {
		_sdkPipeline = pipeline;
		_frameFactory = frameFactory;
	}
	return self;
}

- (nonnull RTC_OBJC_TYPE(RTCVideoFrame)*)onFrame:(RTC_OBJC_TYPE(RTCVideoFrame)* _Nonnull)frame {
	id<RTC_OBJC_TYPE(RTCVideoFrameBuffer)> frameBuffer = [frame buffer];
	bool isPixelBuffer = [frameBuffer isKindOfClass:[RTC_OBJC_TYPE(RTCCVPixelBuffer) class]];
	
	id<TSVBFrame> result = nil;
	if (isPixelBuffer) {
		RTC_OBJC_TYPE(RTCCVPixelBuffer)* pb = frameBuffer;
		result = [_sdkPipeline processCVPixelBuffer:pb.pixelBuffer
									metalCompatible:_sourceIsCamera
										   rotation:toTSVBRotation(frame.rotation)
											  error:nil];
	}
	else {
		id<TSVBFrame> inputFrame = [self toTSVBFrame:frame];
		result = [_sdkPipeline process:inputFrame error:nil];
	}
	if (nil != result) {
		return [self toRTCFrame:result rotation:frame.rotation timestamp:frame.timeStampNs];
	}
	return frame;
}

-(id<TSVBFrame>)toTSVBFrame:(RTC_OBJC_TYPE(RTCVideoFrame)* _Nonnull)rtcFrame {
	id<RTC_OBJC_TYPE(RTCVideoFrameBuffer)> buffer = [rtcFrame buffer];
	id<RTC_OBJC_TYPE(RTCI420Buffer)> i420Buffer = [buffer toI420];
	id<TSVBFrame> bgraFrame = [self provideBGRAFrameWithWidth:rtcFrame.width height:rtcFrame.height];
	if (nil == bgraFrame) {
		return nil;
	}
	bgraFrame.rotation = toTSVBRotation(rtcFrame.rotation);
	
	id<TSVBLockedFrameData> lockedFrameData = [bgraFrame lock:TSVBFrameLockWrite];
	[RTC_OBJC_TYPE(RTCYUVHelper) I420ToARGB:i420Buffer.dataY
								 srcStrideY:i420Buffer.strideY
									   srcU:i420Buffer.dataU
								 srcStrideU:i420Buffer.strideU
									   srcV:i420Buffer.dataV
								 srcStrideV:i420Buffer.strideV
									dstARGB:[lockedFrameData dataPointerOfPlanar:0]
							  dstStrideARGB:[lockedFrameData bytesPerLineOfPlanar:0]
									  width:rtcFrame.width
									 height:rtcFrame.height];
	lockedFrameData = nil;
	return bgraFrame;
}

-(id<TSVBFrame>)provideBGRAFrameWithWidth:(int)w height:(int)h {
	if (nil != _bgraInput) {
		if ((_bgraInput.width != w) || (_bgraInput.height != h)) {
			_bgraInput = nil;
		}
	}
	if (nil != _bgraInput) {
		return _bgraInput;
	}
	
	size_t requiredSize = w * h * 4;
	if ((nil == _bgraData) || (_bgraData.length < requiredSize)) {
		_bgraData = [NSMutableData dataWithLength:requiredSize];
		if (nil == _bgraData) {
			return nil;
		}
	}
	
	_bgraInput = [_frameFactory newFrameWithFormat:TSVBFrameFormatBgra32
											  data:[_bgraData mutableBytes]
									  bytesPerLine:w * 4
											 width:w
											height:h
										  makeCopy:false];
	return _bgraInput;
}

-(RTC_OBJC_TYPE(RTCVideoFrame)*)toRTCFrame:(id<TSVBFrame>)frame rotation:(RTCVideoRotation)rotation timestamp:(int64_t)timestamp{
	RTC_OBJC_TYPE(RTCCVPixelBuffer)* buffer =
		[[RTC_OBJC_TYPE(RTCCVPixelBuffer) alloc] initWithPixelBuffer:[frame toCVPixelBuffer]];
	return [[RTC_OBJC_TYPE(RTCVideoFrame) alloc] initWithBuffer:buffer rotation:rotation timeStampNs:timestamp];
}

-(id<TSVBPipeline>)pipeline {
	return _sdkPipeline;
}

@end

@implementation VideoEffectsSDKPipelineController
{
	TSVBSDKFactory* _sdkFactory;
	id<TSVBFrameFactory> _frameFactory;
	VideoProcessingAdapter* _adapter;
	
	VideoEffectsSDKPipelineWrapper* _wrapper;
	id<TSVBFrame> _background;
	id<TSVBFrame> _colorGradingReference;
	bool _isInserted;
	
	float _blurPower;
	float _beautificationPower;
	float _zoomLevel;
	float _sharpeningStrength;
	float _colorFilterStrength;
	
	bool _blurEnabled;
	bool _replaceEnabled;
	bool _removeEnabled;
	bool _beautificationEnabled;
	bool _zoomEnabled;
	bool _sharpeningEnabled;
	bool _noiseSuppressionEnabled;
	bool _portraitLightingEnabled;
	ColorFilterMode _colorFilterMode;

	// Set by Dart, applied to every new pipeline: the pipeline is dropped while no effect is enabled.
	NSMutableDictionary<NSString*, NSNumber*>* _portraitLightingOptions;
	NSMutableDictionary<NSString*, NSNumber*>* _colorCorrectionConfig;
}

- (nonnull instancetype)initWithSDKFactory:(nonnull TSVBSDKFactory *)factory frameFactory:(nonnull id<TSVBFrameFactory>)frameFactory adapter:(nonnull VideoProcessingAdapter*)adapter{
	self = [super init];
	if (self) {
		_sdkFactory = factory;
		_frameFactory = frameFactory;
		_adapter = adapter;
		_blurPower = 0.7;
		_beautificationPower = 0.7;
		_zoomLevel = 0.7;
		_sharpeningStrength = 0.7;
		_colorFilterStrength = 0.7;
		_portraitLightingOptions = [NSMutableDictionary new];
		_colorCorrectionConfig = [NSMutableDictionary new];
	}
	return self;
}

-(nonnull NSString*)getPipelineMode
{
	if (_blurEnabled) {
		return @"BLUR";
	}
	if (_replaceEnabled) {
		return @"REPLACE";
	}
	if (_removeEnabled) {
		return @"REMOVE";
	}
	return @"NO_EFFECTS";
}

- (nullable FlutterError*)setPipelineMode:(nonnull NSString*)mode {
	if ([@"PipelineMode.noEffects" isEqualToString:mode] && (nil == _wrapper)) {
		return nil;
	}
	VideoEffectsSDKPipelineWrapper* wrapper = [self provideWrapper];
	
	TSVBPipelineError result = [self setPipelineModeImpl:mode wrapper:wrapper];
	
	[self ensureWrapper];
	
	return [self flutterErrorWithPipelineError:result method:@"setPipelineMode"];
}

- (TSVBPipelineError)setPipelineModeImpl:(nonnull NSString*)mode wrapper:(nonnull VideoEffectsSDKPipelineWrapper*)wrapper {
	if ([@"PipelineMode.noEffects" isEqualToString:mode]) {
		[wrapper.pipeline disableBlurBackground];
		_blurEnabled = false;
		[wrapper.pipeline disableReplaceBackground];
		wrapper.replacementController = nil;
		_removeEnabled = false;
		_replaceEnabled = false;
		return TSVBPipelineErrorOk;
	}
	
	if ([@"PipelineMode.blur" isEqualToString:mode]) {
		TSVBPipelineError result = [wrapper.pipeline enableBlurBackgroundWithPower:_blurPower];
		_blurEnabled = (TSVBPipelineErrorOk == result);
		if (_blurEnabled) {
			[wrapper.pipeline disableReplaceBackground];
			wrapper.replacementController = nil;
			_removeEnabled = false;
			_replaceEnabled = false;
		}
		return result;
	}
	
	bool isReplacement =
	[@"PipelineMode.replace" isEqualToString:mode] || [@"PipelineMode.remove" isEqualToString:mode];
	if (isReplacement && (nil == wrapper.replacementController)) {
		id<TSVBReplacementController> controller;
		TSVBPipelineError result = [wrapper.pipeline enableReplaceBackground:&controller];
		if (TSVBPipelineErrorOk == result) {
			wrapper.replacementController = controller;
			[wrapper.pipeline disableBlurBackground];
			_blurEnabled = false;
		}
		else {
			return result;
		}
	}
	
	if ([@"PipelineMode.replace" isEqualToString:mode]) {
		_removeEnabled = false;
		_replaceEnabled = true;
		if (nil == _background) {
			_background = [self defaultBackground];
		}
		wrapper.replacementController.background = _background;
		return TSVBPipelineErrorOk;
	}
	if([@"PipelineMode.remove" isEqualToString:mode]) {
		_removeEnabled = true;
		_replaceEnabled = false;
		wrapper.replacementController.background = nil;
		return TSVBPipelineErrorOk;
	}
	
	return TSVBPipelineErrorInvalidArgument;
}

-(float)blurPower {
	return self->_blurPower;
}

-(void)setBlurPower:(float)blurPower {
	self->_blurPower = blurPower;
	if (_blurEnabled) {
		[[_wrapper pipeline] enableBlurBackgroundWithPower:blurPower];
	}
}

-(id<TSVBFrame>)background {
	return _background;
}

-(void)setBackground:(id<TSVBFrame>)background {
	_background = background;
	if (_replaceEnabled) {
		[[_wrapper replacementController] setBackground:background];
	}
}

-(bool)beautificationEnabled {
	return _beautificationEnabled;
}

-(nullable FlutterError*)setBeautificationEnabled:(bool)enabled
{
	if (enabled == _beautificationEnabled) {
		return nil;
	}
	
	VideoEffectsSDKPipelineWrapper* wrapper = [self provideWrapper];
	
	TSVBPipelineError result = [self setBeautificationEnabledImpl:enabled wrapper:wrapper];
	
	[self ensureWrapper];
	
	return 	[self flutterErrorWithPipelineError:result method:@"enableBeautification"];
}

-(TSVBPipelineError)setBeautificationEnabledImpl:(bool)enabled wrapper:(nonnull VideoEffectsSDKPipelineWrapper*)wrapper
{
	if (!enabled) {
		[wrapper.pipeline disableBeautification];
		_beautificationEnabled = false;
		return TSVBPipelineErrorOk;
	}
	
	TSVBPipelineError result = [wrapper.pipeline enableBeautification];
	_beautificationEnabled = (TSVBPipelineErrorOk == result);
	if (_beautificationEnabled) {
		wrapper.pipeline.beautificationLevel = _beautificationPower;
	}
	
	return result;
}

-(float)beautificationPower {
	return _beautificationPower;
}

-(void)setBeautificationPower:(float)beautificationPower {
	_beautificationPower = beautificationPower;
	if (_beautificationEnabled) {
		_wrapper.pipeline.beautificationLevel = _beautificationPower;
	}
}

-(float)zoomLevel {
	return _zoomLevel;
}

-(nullable FlutterError*)setZoomLevel:(float)value {
	value = MIN(MAX(value, 0), 1);
	if (value == _zoomLevel) {
		return nil;
	}
	
	VideoEffectsSDKPipelineWrapper* wrapper = [self provideWrapper];
	
	TSVBPipelineError result = [self setZoomLevel:value wrapper:wrapper];
	
	[self ensureWrapper];
	
	return [self flutterErrorWithPipelineError:result method:@"setZoomLevel"];
}

-(TSVBPipelineError)setZoomLevel:(float)value wrapper:(nonnull VideoEffectsSDKPipelineWrapper*)wrapper
{
	if (value < 0.0001) {
		[wrapper.pipeline disableSmartZoom];
		_zoomEnabled = false;
		_zoomLevel = value;
		return TSVBPipelineErrorOk;
	}
	
	TSVBPipelineError result = [wrapper.pipeline enableSmartZoom];
	_zoomEnabled = (TSVBPipelineErrorOk == result);
	if (_zoomEnabled) {
		wrapper.pipeline.smartZoomLevel = value;
		_zoomLevel = value;
	}
	
	return result;
}

-(nullable FlutterError*)setSharpeningEnabled:(bool)enabled {
	if (enabled == _sharpeningEnabled) {
		return nil;
	}
	
	VideoEffectsSDKPipelineWrapper* wrapper = [self provideWrapper];
	
	TSVBPipelineError result = [self setSharpeningEnabled:enabled wrapper:wrapper];
	
	[self ensureWrapper];
	
	return [self flutterErrorWithPipelineError:result method:@"enableSharpening"];
}

-(TSVBPipelineError)setSharpeningEnabled:(bool)enabled wrapper:(nonnull VideoEffectsSDKPipelineWrapper*)wrapper
{
	if (!enabled) {
		[wrapper.pipeline disableSharpening];
		_sharpeningEnabled = false;
		return TSVBPipelineErrorOk;
	}
	
	TSVBPipelineError result = [wrapper.pipeline enableSharpening];
	_sharpeningEnabled = (TSVBPipelineErrorOk == result);
	if (_sharpeningEnabled) {
		wrapper.pipeline.sharpeningPower = _sharpeningStrength;
	}
	
	return result;
}

-(float)sharpeningStrength {
	return _sharpeningStrength;
}

-(void)setSharpeningStrength:(float)value {
	_sharpeningStrength = value;
	if (_sharpeningEnabled) {
		[[_wrapper pipeline] setSharpeningPower:value];
	}
}

-(float)colorFilterStrength {
	return _colorFilterStrength;
}

-(void)setColorFilterStrength:(float)value {
	_colorFilterStrength = value;
	switch (_colorFilterMode) {
		case mlColorCorrection:
		case colorGrading:
			[[_wrapper pipeline] setColorCorrectionPower:value];
			break;
		case lowLight:
			[[_wrapper pipeline] setLowLightAdjustmentPower:value];
			break;
		case noColorFilter:
			break;
	}
}

- (nullable FlutterError*)setColorFilterMode:(NSString *)modeName {
	const ColorFilterMode mode = mapColorFilterName(modeName);
	if (mode == _colorFilterMode) {
		return nil;
	}
	
	VideoEffectsSDKPipelineWrapper* wrapper = [self provideWrapper];
	
	FlutterError* error = [self setColorFilterMode:mode wrapper:wrapper];
	
	[self ensureWrapper];
	
	return error;
}

- (nullable FlutterError*)setColorFilterMode:(ColorFilterMode)mode wrapper:(nonnull VideoEffectsSDKPipelineWrapper*)wrapper {
	TSVBPipelineError errorCode = TSVBPipelineErrorOk;
	switch (mode){
		case noColorFilter: {
			[wrapper.pipeline disableLowLightAdjustment];
			[wrapper.pipeline disableColorCorrection];
			_colorFilterMode = noColorFilter;
		} break;
		case mlColorCorrection: {
			errorCode = [wrapper.pipeline enableColorCorrection];
			if (TSVBPipelineErrorOk == errorCode) {
				[wrapper.pipeline disableLowLightAdjustment];
				wrapper.pipeline.colorCorrectionPower = _colorFilterStrength;
				_colorFilterMode = mlColorCorrection;
			}
		} break;
		case colorGrading: {
			if (nil == _colorGradingReference) {
				return [FlutterError
						errorWithCode:@"setColorCorrectionMode failed"
						message:@"Error: Cannot activate color grading until reference image is set"
						details:nil
				];
			}
			errorCode =
				[wrapper.pipeline enableColorCorrectionWithReference:_colorGradingReference];
			if (TSVBPipelineErrorOk == errorCode) {
				[wrapper.pipeline disableLowLightAdjustment];
				wrapper.pipeline.colorCorrectionPower = _colorFilterStrength;
				_colorFilterMode = colorGrading;
			}
		} break;
		case lowLight: {
			errorCode = [wrapper.pipeline enableLowLightAdjustment];
			if (TSVBPipelineErrorOk == errorCode) {
				[wrapper.pipeline disableColorCorrection];
				wrapper.pipeline.lowLightAdjustmentPower = _colorFilterStrength;
				_colorFilterMode = lowLight;
			}
		} break;
	}
	
	return [self flutterErrorWithPipelineError:errorCode method:@"setColorFilterMode"];
}

-(id<TSVBFrame>)colorGradingReference {
	return _colorGradingReference;
}

-(void)setColorGradingReference:(id<TSVBFrame>)colorGradingReference {
	_colorGradingReference = colorGradingReference;
	if (colorGrading == _colorFilterMode) {
		[[_wrapper pipeline] enableColorCorrectionWithReference:colorGradingReference];
	}
}

-(nullable FlutterError*)setNoiseSuppressionEnabled:(bool)enabled {
	if (enabled == _noiseSuppressionEnabled) {
		return nil;
	}

	VideoEffectsSDKPipelineWrapper* wrapper = [self provideWrapper];

	TSVBPipelineError result = TSVBPipelineErrorOk;
	if (enabled) {
		result = [wrapper.pipeline enableNoiseSuppression];
		_noiseSuppressionEnabled = (TSVBPipelineErrorOk == result);
	}
	else {
		[wrapper.pipeline disableNoiseSuppression];
		_noiseSuppressionEnabled = false;
	}

	[self ensureWrapper];

	return [self flutterErrorWithPipelineError:result method:@"enableNoiseSuppression"];
}

-(nullable FlutterError*)setPortraitLightingEnabled:(bool)enabled {
	if (enabled == _portraitLightingEnabled) {
		return nil;
	}

	VideoEffectsSDKPipelineWrapper* wrapper = [self provideWrapper];

	TSVBPipelineError result = TSVBPipelineErrorOk;
	if (enabled) {
		result = [wrapper.pipeline enablePortraitLighting];
		_portraitLightingEnabled = (TSVBPipelineErrorOk == result);
	}
	else {
		[wrapper.pipeline disablePortraitLighting];
		_portraitLightingEnabled = false;
	}

	[self ensureWrapper];

	return [self flutterErrorWithPipelineError:result method:@"enablePortraitLighting"];
}

-(void)setPortraitLightingOptions:(nonnull NSDictionary*)options {
	mergeNumbers(_portraitLightingOptions, options);
	if (nil != _wrapper) {
		[self applyPortraitLightingOptionsTo:_wrapper.pipeline];
	}
}

-(void)setColorCorrectionConfig:(nonnull NSDictionary*)config {
	mergeNumbers(_colorCorrectionConfig, config);
	if (nil != _wrapper) {
		[self applyColorCorrectionConfigTo:_wrapper.pipeline];
	}
}

-(void)applyPortraitLightingOptionsTo:(nonnull id<TSVBPipeline>)pipeline {
	id<TSVBPortraitLightingSettings> settings = pipeline.portraitLighting;
	NSNumber* value = nil;
	if ((value = _portraitLightingOptions[@"lightStrength"])) {
		settings.lightStrength = value.floatValue;
	}
	if ((value = _portraitLightingOptions[@"backgroundDarkness"])) {
		settings.backgroundDarkening = value.floatValue;
	}
}

-(void)applyColorCorrectionConfigTo:(nonnull id<TSVBPipeline>)pipeline {
	id<TSVBColorCorrectionSettings> settings = pipeline.colorCorrection;
	NSNumber* value = nil;
	if ((value = _colorCorrectionConfig[@"autoMode"])) {
		settings.autoModeEnabled = value.boolValue;
	}
	if ((value = _colorCorrectionConfig[@"whiteBalance"])) {
		settings.whiteBalance = value.floatValue;
	}
	if ((value = _colorCorrectionConfig[@"exposure"])) {
		settings.exposure = value.floatValue;
	}
	if ((value = _colorCorrectionConfig[@"temperature"])) {
		settings.temperature = value.floatValue;
	}
	if ((value = _colorCorrectionConfig[@"tint"])) {
		settings.tint = value.floatValue;
	}
	if ((value = _colorCorrectionConfig[@"vibrance"])) {
		settings.vibrance = value.floatValue;
	}
	if ((value = _colorCorrectionConfig[@"contrast"])) {
		settings.contrast = value.floatValue;
	}
	if ((value = _colorCorrectionConfig[@"updatePeriodMs"])) {
		settings.updateInterval = value.doubleValue / 1000.0;
	}
}

-(VideoEffectsSDKPipelineWrapper*)provideWrapper{
	if (nil == _wrapper) {
		id<TSVBPipeline> pipeline = [_sdkFactory newPipeline];
		// The pipeline keeps these settings while their effects are disabled.
		[self applyPortraitLightingOptionsTo:pipeline];
		[self applyColorCorrectionConfigTo:pipeline];
		_wrapper = [[VideoEffectsSDKPipelineWrapper alloc] initWithSDKPipeline:pipeline frameFactory:_frameFactory];
	}

	return _wrapper;
}

-(void)ensureWrapper {
	if ([self hasEnabledFeatures]) {
		if (!_isInserted && (nil != _wrapper)) {
			_wrapper.sourceIsCamera = _adapter.sourceIsCamera;
			[_adapter addProcessing:_wrapper];
			_isInserted = true;
		}
	}
	else {
		if (_isInserted) {
			[_adapter removeProcessing:_wrapper];
			_isInserted = false;
		}
		_wrapper = nil;
	}
}

-(bool)hasEnabledFeatures {
	return 
		_blurEnabled ||
		_replaceEnabled ||
		_removeEnabled ||
		_beautificationEnabled ||
		_zoomEnabled ||
		_sharpeningEnabled ||
		_noiseSuppressionEnabled ||
		_portraitLightingEnabled ||
		(noColorFilter != _colorFilterMode);
}

-(id<TSVBFrame>)defaultBackground {
	return [SDKFrameFactoryHelper solidFrameWithRed:0 green:0.8 blue:0 factory:_frameFactory];
}

-(FlutterError*)flutterErrorWithPipelineError:(TSVBPipelineError)error method:(NSString*)method {
	if (TSVBPipelineErrorOk == error) {
		return nil;
	}
	
	NSString* errorText = nil;
	switch (error) {
		case TSVBPipelineErrorInvalidArgument:
			errorText = @"Error: Passed one or more invalid arguments";
			break;
			
		// Just to prevent warning
		case TSVBPipelineErrorOk:
		case TSVBPipelineErrorNoFeaturesEnabled:
			break;
			
		case TSVBPipelineErrorResourceAllocationError:
			errorText = @"Error: Resource allocation error";
			break;
			
		case TSVBPipelineErrorEngineInitializationError:
			errorText = @"Error: Failed to initialize engine";
			break;

		case TSVBPipelineErrorNotSupportedByBackend:
			errorText = @"Error: The effect is not supported by the current backend";
			break;

		case TSVBPipelineErrorEnabledUnsupportedFeatures:
			errorText = @"Error: An enabled effect is not supported by the requested backend";
			break;

		case TSVBPipelineErrorInvalidUsage:
			errorText = @"Error: Invalid usage of the SDK";
			break;
	}
	
	return [FlutterError errorWithCode:[NSString stringWithFormat:@"%@ failed", method]
							  message:errorText
								details:nil];
}

@end

@implementation VideoEffectsSDKContext
{
	enum AuthState _authState;
	TSVBSDKFactory* _sdkFactory;
	id<TSVBFrameFactory> _frameFactory;
}

-(instancetype)init {
	self = [super init];
	if (self) {
		_authState = AuthStateNotAuthorized;
		_sdkFactory = [TSVBSDKFactory new];
		_frameFactory = [_sdkFactory newFrameFactory];
	}
	
	return self;
}

@synthesize sdkFactory = _sdkFactory;
@synthesize frameFactory = _frameFactory;

@synthesize authState = _authState;

- (VideoEffectsSDKPipelineController *)newPipelineControllerWithAdapter:(nonnull VideoProcessingAdapter *)adapter {
	return [[VideoEffectsSDKPipelineController alloc] initWithSDKFactory:_sdkFactory frameFactory:_frameFactory adapter:adapter];
}

@end

@implementation SDKFrameFactoryHelper

+ (id<TSVBFrame>)solidFrameWithRed:(float)r green:(float)g blue:(float)b factory:(id<TSVBFrameFactory>)factory {
	uint32_t pixel =
		(MIN(MAX((int)(r * 255), 0), 255)      ) |
		(MIN(MAX((int)(g * 255), 0), 255) << 8 ) |
		(MIN(MAX((int)(b * 255), 0), 255) << 16) |
		(0xff << 24);
	return [factory newFrameWithFormat:TSVBFrameFormatRgba32
										data:&pixel
								bytesPerLine:sizeof(pixel)
									   width:1
									  height:1
									makeCopy:true];
}

@end

NSString* nameOfAuthStatus(TSVBAuthStatus status) {
	switch (status) {
		case TSVBAuthStatusActive:
			return @"ACTIVE";
			
		case TSVBAuthStatusExpired:
			return @"EXPIRED";
			
		case TSVBAuthStatusInactive:
			return @"INACTIVE";
			
		default:
			return @"ERROR";
	}
}
