//////////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 2012 Freshplanet (http://freshplanet.com | opensource@freshplanet.com)
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//  
//////////////////////////////////////////////////////////////////////////////////////
//

#import "AirVideo.h"

FREContext AirCenterVideoCtx = nil;

@interface AirCenterVideo ()

- (void)resize;
- (void)playerLoadStateDidChange:(NSNotification *)notification;
- (void)playerPlaybackDidFinish:(NSNotification *)notification;

@end

@implementation AirCenterVideo

@synthesize player = _player;
@synthesize requestedFrame = CGRectNull;

#pragma mark - Singleton

static AirCenterVideo *sharedInstance = nil;

+ (AirCenterVideo *)sharedInstance
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

- (id)copy
{
    return self;
}

#pragma mark - NSObject

- (void)dealloc
{
    [_player release];
    [super dealloc];
}

#pragma mark - AirVideo

- (MPMoviePlayerController *)player
{
    if (!_player)
    {
        // Initializer movie player
        _player = [[MPMoviePlayerController alloc] init];
        
        _player.scalingMode = MPMovieScalingModeAspectFit;
        
        // Register for notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerLoadStateDidChange:) name:MPMoviePlayerLoadStateDidChangeNotification object:_player];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:_player];
    }
    
    return _player;
}

+ (void)dispatchEvent:(NSString *)eventName withInfo:(NSString *)info
{
    if (AirCenterVideoCtx != nil)
    {
        FREDispatchStatusEventAsync(AirCenterVideoCtx, (const uint8_t *)[eventName UTF8String], (const uint8_t *)[info UTF8String]);
    }
}

+ (void)log:(NSString *)message
{
    [AirCenterVideo dispatchEvent:@"LOGGING" withInfo:message];
}

- (void)playerLoadStateDidChange:(NSNotification *)notification
{
    if (self.player.loadState == MPMovieLoadStateUnknown)
    {
        [AirCenterVideo log:@"playerLoadStateDidChange = MPMovieLoadStateUnknown"];
    } else if (self.player.loadState == MPMovieLoadStatePlaythroughOK)
    {
        [AirCenterVideo log:@"playerLoadStateDidChange = MPMovieLoadStatePlaythroughOK"];
    } else if (self.player.loadState == MPMovieLoadStateStalled)
    {
        [AirCenterVideo log:@"playerLoadStateDidChange = MPMovieLoadStateStalled"];
    } else if (self.player.loadState == MPMovieLoadStatePlayable)
    {
        [AirCenterVideo log:@"playerLoadStateDidChange = MPMovieLoadStatePlayable"];
    } else {
        [AirCenterVideo log:[NSString stringWithFormat:@"playerLoadStateDidChange unknown state = %i", self.player.loadState]];
    }
    
    if (self.player.loadState == (MPMovieLoadStatePlayable | MPMovieLoadStatePlaythroughOK) || self.player.loadState == MPMovieLoadStatePlayable || self.player.loadState == MPMovieLoadStatePlaythroughOK)
    {
        [self resize];
    }

}

- (void) resize
{
    CGRect frame;
    if ( CGRectIsNull(self.requestedFrame) )
    {
        UIView *rootView = [[[[UIApplication sharedApplication] keyWindow] rootViewController] view];
        CGSize movieSize = self.player.naturalSize;
        frame = self.player.view.frame;
        
        frame.size.width = MIN(rootView.frame.size.width, movieSize.width);
        frame.size.height = frame.size.width * movieSize.height / movieSize.width;
        self.player.view.frame = frame;
        self.player.view.center = rootView.center;
    }
    else
    {
        if ( IS_RETINA ) {
            frame = CGRectMake(CGRectGetMinX(self.requestedFrame)/2,
                               CGRectGetMinY(self.requestedFrame)/2,
                               CGRectGetWidth(self.requestedFrame)/2,
                               CGRectGetHeight(self.requestedFrame)/2);
        } else {
            frame = self.requestedFrame;
        }
        self.player.view.frame = frame;
    }
}

- (void)playerPlaybackDidFinish:(NSNotification *)notification
{
    if ([notification.userInfo objectForKey:@"error"] != nil)
    {
        NSError *playbackFinishedError = [notification.userInfo objectForKey:@"error"];
        [AirCenterVideo log:[NSString stringWithFormat:@"playbackFinishedError.  Error: %@",playbackFinishedError]];
        [AirCenterVideo dispatchEvent:@"VIDEO_PLAYBACK_ERROR" withInfo:[playbackFinishedError localizedDescription]];
    }
    else
    {
        [AirCenterVideo dispatchEvent:@"PLAYBACK_DID_FINISH" withInfo:@"OK"];
    }
}

@end


#pragma mark - C interface

DEFINE_ANE_FUNCTION(airVideoShowPlayer)
{
    UIView *rootView = [[[[UIApplication sharedApplication] keyWindow] rootViewController] view];
    [rootView addSubview:[[[AirCenterVideo sharedInstance] player] view]];
    
    return nil;
}

DEFINE_ANE_FUNCTION(airVideoDisposePlayer)
{
    [[[AirCenterVideo sharedInstance] player] stop];
    [[AirCenterVideo sharedInstance] player].fullscreen = false;
    [[[[AirCenterVideo sharedInstance] player] view] removeFromSuperview];
    
    return nil;
}

DEFINE_ANE_FUNCTION(airVideoResizeVideo)
{
    double x;
    double y;
    double w;
    double h;
    
    if (FREGetObjectAsDouble(argv[0], &x) == FRE_OK) {
        NSLog(@"x: %f", x);
    } else {
        NSLog(@"couldnt parse number");
        return nil;
    }
    if (FREGetObjectAsDouble(argv[1], &y) == FRE_OK) {
        NSLog(@"y: %f", y);
    } else {
        NSLog(@"couldnt parse number");
        return nil;
    }
    if (FREGetObjectAsDouble(argv[2], &w) == FRE_OK) {
        NSLog(@"width: %f", w);
    } else {
        NSLog(@"couldnt parse number");
        return nil;
    }
    if (FREGetObjectAsDouble(argv[3], &h) == FRE_OK) {
        NSLog(@"height: %f", h);
    } else {
        NSLog(@"couldnt parse number");
        return nil;
    }
    [[AirCenterVideo sharedInstance] setRequestedFrame:CGRectMake(x, y, w, h)];
    NSLog(@"will resize video to %@", NSStringFromCGRect([[AirCenterVideo sharedInstance]requestedFrame]));
    
    [[AirCenterVideo sharedInstance] resize];
    
    return nil;
}

DEFINE_ANE_FUNCTION(airVideoLoadVideo)
{
    NSLog(@"Entering airVideoLoadVideo");
    uint32_t stringLength;
    
    NSString *path = nil;
    const uint8_t *pathString;
    if (FREGetObjectAsUTF8(argv[0], &stringLength, &pathString) == FRE_OK)
    {
        path = [NSString stringWithUTF8String:(const char *)pathString];
    }
    
    uint32_t isLocalFileValue;
    FREObject isLocalFileObj = argv[1];
    FREGetObjectAsBool(isLocalFileObj, &isLocalFileValue);
    BOOL isLocalFile = (isLocalFileValue != 0);
    
    if (argc > 2)
    {
        double x;
        double y;
        double w;
        double h;

        if (FREGetObjectAsDouble(argv[2], &x) == FRE_OK) {
            NSLog(@"x: %f", x);
        } else {
            NSLog(@"couldnt parse number");
            return nil;
        }
        if (FREGetObjectAsDouble(argv[3], &y) == FRE_OK) {
            NSLog(@"y: %f", y);
        } else {
            NSLog(@"couldnt parse number");
            return nil;
        }
        if (FREGetObjectAsDouble(argv[4], &w) == FRE_OK) {
            NSLog(@"width: %f", w);
        } else {
            NSLog(@"couldnt parse number");
            return nil;
        }
        if (FREGetObjectAsDouble(argv[5], &h) == FRE_OK) {
            NSLog(@"height: %f", h);
        } else {
            NSLog(@"couldnt parse number");
            return nil;
        }
        [[AirCenterVideo sharedInstance] setRequestedFrame:CGRectMake(x, y, w, h)];
        NSLog(@"will resize video to %@", NSStringFromCGRect([[AirCenterVideo sharedInstance]requestedFrame]));
    } else {
        [[AirCenterVideo sharedInstance] setRequestedFrame:CGRectNull];
    }
    
    NSLog(@"loadVideo path = %@, isLocalFile = %c", path, isLocalFile);
    
    NSURL *url;
    if (path)
    {
        if (isLocalFile) {
            url = [NSURL fileURLWithPath:path isDirectory:NO];
            NSError *unreachableError;
            if ( [url checkResourceIsReachableAndReturnError:&unreachableError] == NO )
            {
                [AirCenterVideo log:[NSString stringWithFormat:@"FileUnreachableError. Error: %@",unreachableError]];
                NSLog(@"FileUnreachableError. Error: %@",unreachableError.localizedDescription);
                NSLog(@"Exiting loadVideo");
                return nil;
            }
        }
        else {
            url = [NSURL URLWithString:path];
        }
        [[[AirCenterVideo sharedInstance] player] setContentURL:url];
        [[[AirCenterVideo sharedInstance] player] play];
    }
    
    NSLog(@"Exiting airVideoLoadVideo");
    return nil;
}

void AirCenterVideoContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx,
                        uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet) 
{
    // Register the links btwn AS3 and ObjC. (dont forget to modify the nbFuntionsToLink integer if you are adding/removing functions)
    NSInteger nbFuntionsToLink = 4;
    *numFunctionsToTest = nbFuntionsToLink;
    
    FRENamedFunction* func = (FRENamedFunction*) malloc(sizeof(FRENamedFunction) * nbFuntionsToLink);
    
    func[0].name = (const uint8_t*) "airCenterVideoShowPlayer";
    func[0].functionData = NULL;
    func[0].function = &airVideoShowPlayer;
    
    func[1].name = (const uint8_t*) "airCenterVideoHidePlayer";
    func[1].functionData = NULL;
    func[1].function = &airVideoDisposePlayer;
    
    func[2].name = (const uint8_t*) "airCenterVideoLoadVideo";
    func[2].functionData = NULL;
    func[2].function = &airVideoLoadVideo;
    
    func[3].name = (const uint8_t*) "airCenterVideoResizeVideo";
    func[3].functionData = NULL;
    func[3].function = &airVideoResizeVideo;
    
    *functionsToSet = func;
    
    AirCenterVideoCtx = ctx;
}

void AirCenterVideoContextFinalizer(FREContext ctx) { }

void AirCenterVideoInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet)
{
	*extDataToSet = NULL;
	*ctxInitializerToSet = &AirCenterVideoContextInitializer;
	*ctxFinalizerToSet = &AirCenterVideoContextFinalizer;
}

void AirCenterVideoFinalizer(void *extData) { }
