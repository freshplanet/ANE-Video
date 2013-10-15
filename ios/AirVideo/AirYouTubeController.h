//
//  AirYouTubeController.h
//  AirYouTube
//
//  Created by Daniel Rodriguez on 11/28/12.
//
//

#import "FPYouTubeView/FPYouTubePlayerControllerDelegate.h"
#import "FPYouTubeView/FPYouTube.h"

static const CGRect AirYouTubeResolutionPhone     =   {{ 0.0f, 0.0f },{320.0f, 200.0f}};  // iPhone 3GS, iPhone 4, iPhone 4S, iPod Touch
static const CGRect AirYouTubeResolutionPhone5    =   {{ 0.0f, 0.0f },{320.0f, 200.0f}};  // iPhone 5 -- still need to check on the actual device.
static const CGRect AirYouTubeResolutionPad       =   {{ 0.0f, 0.0f },{768.0f, 500.0f}};  // iPad 1G, 2G, 3G, 4G, Mini

// -----------------------------------------------------------------
//  AirYouTube

@class FPYouTubePlayerController;

@interface AirYouTubeController : NSObject <FPYouTubePlayerControllerDelegate>

@property (nonatomic, strong) FPYouTubePlayerController *controller;
@property (nonatomic, strong) NSTimer *mediaProgress;
@property (nonatomic) BOOL reached80Percent;

+ (AirYouTubeController *)sharedInstance;

+ (void)dispatchEvent:(NSString *)eventName withInfo:(NSString *)info;

- (void)loadVideoFromUrl:(NSURL *)videoUrl;
- (void)loadVideoFromID:(NSString *)videoId;
- (void)addVideoToStage;
- (void)pause;
- (void)dispose;
- (void)resizeVideo:(CGRect)displayRect;

@end
