@interface AVPlayerController : UIResponder
-(double)currentTimeWithinEndTimes;
@end

@interface AVPlayerLayerAndContentOverlayContainerView : UIView
@end

@interface AVPlaybackControlsController : NSObject
@end

@interface AVSystemController
+(AVSystemController*)sharedAVSystemController;
-(BOOL)setVolumeTo:(float)volume forCategory:(NSString*)category ;
-(BOOL)getVolume:(float*)volume forCategory:(NSString*)category ;
@end

@interface AVPlaybackControlsView : UIView

@end