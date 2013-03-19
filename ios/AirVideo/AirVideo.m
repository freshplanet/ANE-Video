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

FREContext AirVideoCtx = nil;

@interface AirVideo ()

- (void)playerLoadStateDidChange:(NSNotification *)notification;
- (void)playerPlaybackDidFinish:(NSNotification *)notification;
- (void)displayVideo;
@end

@implementation AirVideo

@synthesize player = _player;

#pragma mark - Singleton

static AirVideo *sharedInstance = nil;

+ (AirVideo *)sharedInstance
{
    NSLog(@"[sharedInstance]");
    if (sharedInstance == nil)
    {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    NSLog(@"[allocWithZone]");
    return [self sharedInstance];
}

- (id)copy
{
    NSLog(@"[copy]");
    return self;
}

#pragma mark - NSObject

- (void)dealloc
{
    NSLog(@"[dealloc]");
    [_player release];
    [super dealloc];
}

#pragma mark - AirVideo

- (MPMoviePlayerController *)player
{
    NSLog(@"[player]");
    if (!_player)
    {
        // Initializer movie player
        _player = [[MPMoviePlayerController alloc] init];
        
        // Register for notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerLoadStateDidChange:) name:MPMoviePlayerLoadStateDidChangeNotification object:_player];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:_player];
    }
    
    return _player;
}

+ (void)dispatchEvent:(NSString *)eventName withInfo:(NSString *)info
{
    NSLog(@"[dispatchEvent] %@ - %@", eventName, info);
    if (AirVideoCtx != nil)
    {
        FREDispatchStatusEventAsync(AirVideoCtx, (const uint8_t *)[eventName UTF8String], (const uint8_t *)[info UTF8String]);
    }
}

+ (void)log:(NSString *)message
{
    NSLog(@"[log]");
    [AirVideo dispatchEvent:@"LOGGING" withInfo:message];
}

- (void)playerLoadStateDidChange:(NSNotification *)notification
{
    
    NSLog(@"[playerLoadStateDidChange]");
    if (self.player.loadState == MPMovieLoadStateUnknown)
    {
        NSLog(@"unknown");
    } else if (self.player.loadState == MPMovieLoadStatePlayable)
    {
        NSLog(@"playable");
    } else if (self.player.loadState == MPMovieLoadStatePlaythroughOK)
    {
        NSLog(@"playableOk");
    } else if (self.player.loadState == MPMovieLoadStateStalled)
    {
         NSLog(@"stalled");
    }
    
    if (self.player.loadState == MPMovieLoadStatePlayable)
    {
        UIView *rootView = [[[[UIApplication sharedApplication] keyWindow] rootViewController] view];
        
        // Resize player
        CGSize movieSize = self.player.naturalSize;
        CGRect playerFrame = self.player.view.frame;
        playerFrame.size.width = MIN(rootView.frame.size.width, movieSize.width);
        playerFrame.size.height = playerFrame.size.width * movieSize.height / movieSize.width;
        self.player.view.frame = playerFrame;
        
        // Center player
        self.player.view.center = rootView.center;
        
        
//        [AirVideo dispatchEvent:@"LOAD_STATE_COMPLETE" withInfo:@"message"];
    }
}

- (void)playerPlaybackDidFinish:(NSNotification *)notification
{
    [AirVideo dispatchEvent:@"PLAYBACK_DID_FINISH" withInfo:@"OK"];
}

- (void)displayVideo
{
    NSLog(@"[displayVideo]");
    UIView *rootView = [[[[UIApplication sharedApplication] keyWindow] rootViewController] view];
    
    // Resize player
    CGSize movieSize = self.player.naturalSize;
    CGRect playerFrame = self.player.view.frame;
    playerFrame.size.width = MIN(rootView.frame.size.width, movieSize.width);
    playerFrame.size.height = playerFrame.size.width * movieSize.height / movieSize.width;
    self.player.view.frame = playerFrame;
    
    // Center player
    self.player.view.center = rootView.center;
}

@end


#pragma mark - C interface

DEFINE_ANE_FUNCTION(showPlayer)
{
    NSLog(@"[showPlayer]");
    
    UIView *rootView = [[[[UIApplication sharedApplication] keyWindow] rootViewController] view];
    [rootView addSubview:[[[AirVideo sharedInstance] player] view]];
    
    return nil;
}

DEFINE_ANE_FUNCTION(hidePlayer)
{
    [[[[AirVideo sharedInstance] player] view] removeFromSuperview];
    
    return nil;
}

//DEFINE_ANE_FUNCTION(loadVideo)
//{
//    NSLog(@"[loadVideo]");
//    
//    NSLog(@"start loading video");
//    uint32_t stringLength;
//    
//    NSString *url = nil;
//    const uint8_t *urlString;
//    if (FREGetObjectAsUTF8(argv[0], &stringLength, &urlString) == FRE_OK)
//    {
//        url = [NSString stringWithUTF8String:(const char *)urlString];
//    }
//    
//    if (url)
//    {
////        NSLog(@"url found %@", url);
//        [[[AirVideo sharedInstance] player] setContentURL:[NSURL URLWithString:url]];
//        [[[AirVideo sharedInstance] player] play];
////        [[[AirVideo sharedInstance] player] stop];
//    } else
//    {
////        NSLog(@"url not found");
//    }
//    
//    return nil;
//}

//DEFINE_ANE_FUNCTION(setViewDimensions)
//{
//    // todo set the size
//    return nil;
//}


DEFINE_ANE_FUNCTION(fetchVideo)
{
    NSLog(@"[fetchVideo]");
    
    uint32_t stringLength;
    
    NSString *url = nil;
    const uint8_t *urlString;
    if (FREGetObjectAsUTF8(argv[0], &stringLength, &urlString) == FRE_OK)
    {
        url = [NSString stringWithUTF8String:(const char *)urlString];
    }

    if (url)
    {
        NSLog(@"[fetchVideo] url found: %@", url);
        [[[AirVideo sharedInstance] player] setContentURL:[NSURL URLWithString:url]];
        [[[AirVideo sharedInstance] player] prepareToPlay];
        
        
        [[AirVideo sharedInstance] displayVideo];
        
    } else
    {
        NSLog(@"[fetchVideo] url not found");
    }
    
    // todo set the size
    return nil;
}


//DEFINE_ANE_FUNCTION(setControlStyle)
//{
//    // todo set the controller visibility
//    [[[AirVideo sharedInstance] player] setControlStyle:MPMovieControlStyleNone];
//    return nil;
//}
//
//
//DEFINE_ANE_FUNCTION(playVideo)
//{
//    // todo start displaying the video
//    [[[AirVideo sharedInstance] player] play];
//    return nil;
//}



void AirVideoContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx,
                        uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet) 
{
    
    NSLog(@"[AirVideoContextInitializer]");
    
    // Register the links btwn AS3 and ObjC. (dont forget to modify the nbFuntionsToLink integer if you are adding/removing functions)
    NSInteger nbFuntionsToLink = 3;
    *numFunctionsToTest = nbFuntionsToLink;
    
    FRENamedFunction* func = (FRENamedFunction*) malloc(sizeof(FRENamedFunction) * nbFuntionsToLink);
    
    func[0].name = (const uint8_t*) "showPlayer";
    func[0].functionData = NULL;
    func[0].function = &showPlayer;
    
    func[1].name = (const uint8_t*) "hidePlayer";
    func[1].functionData = NULL;
    func[1].function = &hidePlayer;
    
    func[2].name = (const uint8_t*) "fetchVideo";
    func[2].functionData = NULL;
    func[2].function = &fetchVideo;
    
//    func[3].name = (const uint8_t*) "setViewDimensions";
//    func[3].functionData = NULL;
//    func[3].function = &setViewDimensions;
//    
//    func[4].name = (const uint8_t*) "setControlStyle";
//    func[4].functionData = NULL;
//    func[4].function = &setControlStyle;
//    
//    func[5].name = (const uint8_t*) "playVideo";
//    func[5].functionData = NULL;
//    func[5].function = &playVideo;

    
    *functionsToSet = func;
    
    AirVideoCtx = ctx;
    
    NSLog(@"[AirVideoContextInitializer] done");
}

void AirVideoContextFinalizer(FREContext ctx) { NSLog(@"[AirVideoContextFinalizer]"); }

void AirVideoInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet)
{
    NSLog(@"[AirVideoInitializer]");
	*extDataToSet = NULL;
	*ctxInitializerToSet = &AirVideoContextInitializer;
	*ctxFinalizerToSet = &AirVideoContextFinalizer;
}

void AirVideoFinalizer(void *extData) {  NSLog(@"[AirVideoFinalizer]"); }
