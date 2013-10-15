//
//  AirYouTubeController.m
//  AirYouTube
//
//  Created by Daniel Rodriguez on 11/28/12.
//
//

#import "AirYouTubeController.h"
#import "AirVideo.h"
#import "FPYouTubeView/FPYouTube.h"
#import "SystemVersion.h"

@interface AirYouTubeController ()

- (void)timerAction:(NSTimer *)timer;
- (void)moviePlayerPlaybackStateChanged:(NSNotification *)notification;

@end

@implementation AirYouTubeController

@synthesize controller, mediaProgress, reached80Percent;

#pragma mark - Singleton

static AirYouTubeController *sharedInstance = nil;

+ (AirYouTubeController *)sharedInstance
{
    if (sharedInstance == nil)
    {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedInstance];
}

- (id) copy
{
    return self;
}

#pragma mark - NSObject

- (void)dealloc
{
    self.controller.delegate = nil;
}

#pragma mark - AirYouTubeController

+ (void)dispatchEvent:(NSString *)eventName withInfo:(NSString *)info
{
    if (AirVideoContext)
    {
        FREDispatchStatusEventAsync(AirVideoContext, (const uint8_t *)[eventName UTF8String], (const uint8_t *)[info UTF8String]);
    }
}

- (void)loadVideoFromUrl:(NSURL *)videoUrl
{
    if (!self.controller)
    {
        // Initialize and resize video player
        self.controller = [[FPYouTubePlayerController alloc] initWithVideoId:nil delegate:self];
        self.controller.view.frame  = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? AirYouTubeResolutionPad : AirYouTubeResolutionPhone;
        
        // Register for playback state
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerPlaybackStateChanged:) name:MPMoviePlayerLoadStateDidChangeNotification object:self.controller];
    }
    else
    {
        [self.mediaProgress invalidate];
        self.mediaProgress = nil;
        
        [AirYouTubeController dispatchEvent:VIDEO_LOADED_EVENT withInfo:@"Video Load Successful"];
        [self.controller setContentURL:videoUrl];
        [self.controller play];
    }
}

- (void)loadVideoFromID:(NSString *)videoId
{
    if (!self.controller)
    {
        // Initialize and resize video player
        self.controller = [[FPYouTubePlayerController alloc] initWithVideoId:videoId delegate:self];
        self.controller.view.frame  = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? AirYouTubeResolutionPad : AirYouTubeResolutionPhone;
        
        // Register for playback state
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerPlaybackStateChanged:) name:MPMoviePlayerLoadStateDidChangeNotification object:self.controller];
    }
    else
    {
        [self.mediaProgress invalidate];
        self.mediaProgress = nil;
        self.controller.videoId = videoId;
    }
}

- (void)addVideoToStage
{
    // Add video player at the center of root view
    UIViewController *root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    //self.controller.view.center = root.view.center;
    [root.view addSubview:self.controller.view];
}

- (void)pause
{
    [self.controller pause];
}

- (void)dispose
{
    // Dispose timer
    [self.mediaProgress invalidate];
    self.mediaProgress = nil;
    
    // Dispose player controller
    [self.controller dispose];
    self.controller = nil;
}

- (void)resizeVideo:(CGRect)displayRect
{
    CGRect frame;
    if ( IS_RETINA )
    {
        frame = CGRectMake(CGRectGetMinX(displayRect)/2,
                            CGRectGetMinY(displayRect)/2,
                            CGRectGetWidth(displayRect)/2,
                            CGRectGetHeight(displayRect)/2);
    }
    else
    {
        frame = displayRect;
    }
    self.controller.view.frame = frame;
}

- (void)timerAction:(NSTimer*)timer
{
    double progress = self.controller.currentPlaybackTime / self.controller.duration;
    
    DLog(@"timer progress =%f",progress);
    
    if (progress >= 0.999)
    {
        [timer invalidate];
        self.mediaProgress = nil;
        
        DLog(@"timer DISPATCHES PLAYER_PLAYBACK_FINISHED!");
        [AirYouTubeController dispatchEvent:@"PLAYER_PLAYBACK_FINISHED" withInfo:@"OK"];
    }
    else if (progress >= 0.8 && self.reached80Percent == NO)
    {
        self.reached80Percent = YES;
        
        DLog(@"timer DISPATCHES PLAYER_REACHED_PROGRESS!");
        [AirYouTubeController dispatchEvent:@"PLAYER_REACHED_PROGRESS" withInfo:[NSString stringWithFormat:@"%f", progress]];
    }
}

#pragma mark - NSMediaPlayerNotifications

- (void)moviePlayerPlaybackStateChanged:(NSNotification *)notification
{
    if (self.mediaProgress == nil && self.controller.playbackState == MPMoviePlaybackStatePlaying)
    {
        DLog(@"movie playback started, check for the timer! ");
        self.mediaProgress = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
    }
}

#pragma mark - FPYouTubePlayerControllerDelegate

- (void)youTubePlayerController:(FPYouTubePlayerController *)controller didSuccessfullyExtractYouTubeURL:(NSURL *)videoURL
{
    DLog(@"Video Load Successful");
    [AirYouTubeController dispatchEvent:VIDEO_LOADED_EVENT withInfo:@"Video Load Successful"];
}

- (void)youTubePlayerController:(FPYouTubePlayerController *)controller failedExtractingYouTubeURLWithError:(NSError *)error
{
    [AirYouTubeController dispatchEvent:YOUTUBE_EXTRACTION_ERROR withInfo:[error description]];
}

@end