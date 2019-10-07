#import "Tweak.h"
#import <AVFoundation/AVPlayer.h>


// Global instances
id playerControllerInstance;
AVSystemController* systemController;

// Global variables
float oldVolume;
float oldBrightness;
CGPoint translatedDistance;
CGPoint startLocation;
CGRect videoFrame;


// Enum for panGesture
typedef enum {
    touchDidNotPassThreshold=0,
    volumeMode,
    brightnessMode
} SwipePanGestureTouchState;

SwipePanGestureTouchState touchState;




// Hooks
%hook AVPlayerLayerAndContentOverlayContainerView
-(void)setContentFrame:(CGRect)arg1 {
	%orig;
	videoFrame = arg1; // Set videoFrame as the frame of the video
	
}
%end


%hook AVPlaybackControlsController

-(void)playbackControlsViewDidLoad:(id)arg1 {
	%orig;
	
	// Get all the instances of the classes
	AVPlaybackControlsView* playbackControlsView = MSHookIvar<AVPlaybackControlsView *>(self, "_playbackControlsView");
	playerControllerInstance = MSHookIvar<AVPlayerController *>(self, "_playerController");
	systemController = [%c(AVSystemController) sharedAVSystemController];


	// Setup UIGestureRecognizers on playbackControlsView 
	UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:playbackControlsView action:@selector(handleSingleTap:)];
	singleTapGesture.delegate = (id<UIGestureRecognizerDelegate>)playbackControlsView;
	singleTapGesture.numberOfTapsRequired = 2;
	singleTapGesture.cancelsTouchesInView = NO;
	[playbackControlsView addGestureRecognizer:singleTapGesture];

	
	UIPanGestureRecognizer* swipePanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:playbackControlsView action:@selector(handlePan:)];
	swipePanGesture.minimumNumberOfTouches = 2;
	swipePanGesture.delegate = (id<UIGestureRecognizerDelegate>)playbackControlsView;
	swipePanGesture.cancelsTouchesInView = NO;
	[playbackControlsView addGestureRecognizer:swipePanGesture];

}

%end



%hook AVPlaybackControlsView

%new
-(void)handleSingleTap:(UITapGestureRecognizer *)tapGesture {
	CGPoint point = [tapGesture locationInView:self];
	CGFloat videoWidth = CGRectGetWidth(videoFrame);

	if (CGRectContainsPoint(videoFrame, point)) { // Check if the tapped location is in the videoFrame
		float currentTime = [playerControllerInstance currentTimeWithinEndTimes];
		if (point.x < videoWidth/2) { // Left tap
			[playerControllerInstance seekToTime:CMTimeMakeWithSeconds(currentTime - 10, NSEC_PER_SEC)]; // Rewind 10 seconds
		}
		else { // Right tap
			[playerControllerInstance seekToTime:CMTimeMakeWithSeconds(currentTime + 10, NSEC_PER_SEC)]; // Skip 10 seconds
		}
	}

}


%new
-(void)handlePan:(UIPanGestureRecognizer *)swipePanGesture {
	CGPoint velocity = [swipePanGesture velocityInView:self];
	
	if (swipePanGesture.state == UIGestureRecognizerStateEnded) {
		touchState = touchDidNotPassThreshold; // Reset touchState
	}
	else if (swipePanGesture.state == UIGestureRecognizerStateBegan) {
		// Get the startLocation of the touch, current brightness and volume
		startLocation = [swipePanGesture locationInView:self];
		oldBrightness = [[UIScreen mainScreen] brightness];
		[systemController getVolume:&oldVolume forCategory:@"Audio/Video"];

	}
	else if (swipePanGesture.state == UIGestureRecognizerStateChanged) {
		if (touchState == touchDidNotPassThreshold) {
			if (velocity.y > 75) { // DOWN (brightness up)
				touchState = brightnessMode;
			}		
			else if (velocity.y < -75) { // UP (brightness down)
				touchState = brightnessMode;
			}
			else if (velocity.x > 25) { // RIGHT (volume up)
				touchState = volumeMode;
			}
			else if (velocity.x < -25) { // LEFT (volume down)
				touchState = volumeMode;
			}
			
		}

		if (touchState == volumeMode) {
			// Get the moved distance
			translatedDistance = [swipePanGesture translationInView:self];
			double volumeChangeAllowed;
			
			// Check if the moved distance is on the left side of the start location
			if (translatedDistance.x < 0) {
				if (oldVolume == 0) { // Check if volume is 0
					volumeChangeAllowed = 1;
				} 
				else {
					volumeChangeAllowed = oldVolume;
				}
			}
			else {
				if (oldVolume == 1) {
					volumeChangeAllowed = 1;
				}
				else {
					volumeChangeAllowed = 1 - oldVolume;
				}
				
			}
			// Calculations for volume. Credits to DGh0st for helping me out with this
			double distanceAllowedToMoveInDirection = videoFrame.size.width / 2 * volumeChangeAllowed;
			double percentageOfMovement = translatedDistance.x / distanceAllowedToMoveInDirection;
			double volumeToChangeTo = oldVolume + (percentageOfMovement * volumeChangeAllowed);
			[systemController setVolumeTo:volumeToChangeTo forCategory:@"Audio/Video"];
		}

		else if (touchState == brightnessMode) {
			translatedDistance = [swipePanGesture translationInView:self];
			double brightnessChangeAllowed;
			NSLog(@"TWEAK TAP222: DISTANCE: %f", translatedDistance.y);

			if (translatedDistance.y < 0) {
				if (oldBrightness == 0) { // Check if brightness is 0
					brightnessChangeAllowed = 1;
				}
				else {
					brightnessChangeAllowed = oldBrightness;
				}
			}
			else {
				if (oldBrightness == 1) { // Check if brightness is max (1)
					brightnessChangeAllowed = 1;
				}
				else {
					brightnessChangeAllowed = 1 - oldBrightness;
				}
			}

			// Calculations for brightness. Credits to DGh0st for helping me out with this
			double distanceAllowedToMoveInDirection = videoFrame.size.height * brightnessChangeAllowed;
			double percentageOfMovement = translatedDistance.y / distanceAllowedToMoveInDirection;
			double brightnessToChangeTo = oldBrightness - (percentageOfMovement * brightnessChangeAllowed);
			[[UIScreen mainScreen] setBrightness:brightnessToChangeTo];
		}
	}
	
}


%end