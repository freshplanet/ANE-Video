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
- (void)playerMovieDidChange:(NSNotification *)notification;
- (void)resizeVideo;
- (void)startBuffering:(NSArray*)urls;
- (void)pauseVideo;
- (void)resume;
@end

@implementation AirVideo

@synthesize player = _player;
@synthesize videosData;
@synthesize requestedFrame = CGRectNull;

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
        
        _player.movieSourceType = MPMovieSourceTypeFile;
        _player.scalingMode = MPMovieScalingModeAspectFit;
        
        // Register for notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerLoadStateDidChange:) name:MPMoviePlayerLoadStateDidChangeNotification object:_player];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:_player];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerMovieDidChange:) name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification object:_player];

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
    } else
    {
        NSLog(@"unkwon state %i", self.player.loadState);
    }
    
    if (self.player.loadState == (MPMovieLoadStatePlayable | MPMovieLoadStatePlaythroughOK) || self.player.loadState == MPMovieLoadStatePlayable || self.player.loadState == MPMovieLoadStatePlaythroughOK)
    {
        UIView *rootView = [[[[UIApplication sharedApplication] keyWindow] rootViewController] view];
        
        // Resize player
        CGSize movieSize = self.player.naturalSize;
        CGRect playerFrame = self.player.view.frame;
        playerFrame.size.width = MIN(rootView.frame.size.width, movieSize.width);
        playerFrame.size.height = playerFrame.size.width * movieSize.height / movieSize.width;
        self.player.view.frame = playerFrame;
        [self resizeVideo];
    }
}

- (void)playerPlaybackDidFinish:(NSNotification *)notification
{
    [AirVideo dispatchEvent:@"PLAYBACK_DID_FINISH" withInfo:@"OK"];
}

- (void)playerMovieDidChange:(NSNotification *)notification
{
    [self.player.view setHidden:NO];
}

- (void)resizeVideo
{
    NSLog(@"[resizeVideo]");

    NSLog(@"%@",NSStringFromCGRect([[AirVideo sharedInstance] requestedFrame]));

    
    if (self.player != nil && self.player.view != nil && !CGRectIsNull(self.requestedFrame))
    {
        // Resize player
        if ([[UIScreen mainScreen] scale] == 2.0) {
            CGRect retinaRect = CGRectMake(CGRectGetMinX(self.requestedFrame)/2, CGRectGetMinY(self.requestedFrame)/2, CGRectGetWidth(self.requestedFrame)/2, CGRectGetHeight(self.requestedFrame)/2);
            self.player.view.frame = retinaRect;
        } else
        {
            self.player.view.frame = [self requestedFrame];
        }
    }
}


-(void)startBuffering:(NSArray*)urls
{
    NSLog(@"Start Buffering");
    NSInteger i = 0;
    [self setVideosData:[NSMutableDictionary dictionary]];
    for (NSString *url in urls) {
        NSLog(@"buffering for url %@", url);
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];

        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   NSLog(@"request received");
                                   NSLog(@"response: %@", [response MIMEType]);
                                   NSLog(@"data length: %i", [data length]);
                                   NSLog(@"error %@", error);
                                   [[AirVideo sharedInstance] storeVideoData:data atPosition:i];
                               }];
        i++;
    }
}

-(void)storeVideoData:(NSData*)data atPosition:(NSInteger)position
{
    if (videosData == nil)
    {
        [self setVideosData:[NSMutableDictionary dictionary]];
    }
    
    if (data == nil)
    {
        NSLog(@"object nil at position %i", position);
    }
    else
    {
        NSLog(@"replacing object at index %i for array length %i", position, [[self videosData] count]);
        [[self videosData] setObject:data forKey:[NSString stringWithFormat:@"%i", position]];
    }
    
    [AirVideo dispatchEvent:@"LOAD_STATE_COMPLETE" withInfo:[NSString stringWithFormat:@"%i", position]];
}


-(void)playForPosition:(NSInteger)position
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"myMove.mp4"];

    NSData *videoData = [[self videosData] objectForKey:[NSString stringWithFormat:@"%i", position]];
    if (videoData != nil)
    {
        NSLog(@"videoData found at position %i", position);
        [videoData writeToFile:path atomically:YES];
        NSURL *moveUrl = [NSURL fileURLWithPath:path];
        [[[AirVideo sharedInstance] player] setContentURL:moveUrl];
        [[[AirVideo sharedInstance] player] prepareToPlay];
    } else
    {
        NSLog(@"videoData not found at position %i", position);
    }
    
}

-(void)pauseVideo
{
    NSLog(@"pause current video");
    [self.player pause];
}

-(void)resume
{
    NSLog(@"resume video");
    [self.player play];
}


-(void)showWhenReady
{
    [self.player.view setHidden:YES];
}


@end


#pragma mark - C interface

DEFINE_ANE_FUNCTION(showPlayer)
{
    NSLog(@"[showPlayer]");
    
    UIView *rootView = [[[[UIApplication sharedApplication] keyWindow] rootViewController] view];
    [rootView addSubview:[[[AirVideo sharedInstance] player] view]];
    [[AirVideo sharedInstance] showWhenReady];
    
    return nil;
}

DEFINE_ANE_FUNCTION(hidePlayer)
{
    [[[[AirVideo sharedInstance] player] view] removeFromSuperview];
    
    return nil;
}


DEFINE_ANE_FUNCTION(setViewDimensions)
{
    // todo set the size
    
    if (argc < 4)
    {
        NSLog(@"not enough args");
        return nil;
    }
    
    double x;
    double y;
    double width;
    double height;
    if (FREGetObjectAsDouble(argv[0], &x) == FRE_OK)
    {
        NSLog(@"x: %f", x);
    } else
    {
        NSLog(@"couldnt parse number");
        return nil;
    }
    
    if (FREGetObjectAsDouble(argv[1], &y) == FRE_OK)
    {
        NSLog(@"y: %f", y);
    } else
    {
        NSLog(@"couldnt parse number");
        return nil;
    }

    if (FREGetObjectAsDouble(argv[2], &width) == FRE_OK)
    {
        NSLog(@"width: %f", width);
    } else
    {
        NSLog(@"couldnt parse number");
        return nil;
    }

    if (FREGetObjectAsDouble(argv[3], &height) == FRE_OK)
    {
        NSLog(@"height: %f", height);
    } else
    {
        NSLog(@"couldnt parse number");
        return nil;
    }

    [[AirVideo sharedInstance] setRequestedFrame:CGRectMake(x, y, width, height)];
    
    NSLog(@"%@",NSStringFromCGRect([[AirVideo sharedInstance] requestedFrame]));
    
    [[AirVideo sharedInstance] resizeVideo];
    return nil;
}


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
            
    } else
    {
        NSLog(@"[fetchVideo] url not found");
    }
    
    // todo set the size
    return nil;
}


DEFINE_ANE_FUNCTION(setControlStyle)
{
    // todo set the controller visibility
    int32_t value;
    if (FREGetObjectAsInt32(argv[0], &value) == FRE_OK)
    {
        NSLog(@"playing for position %i", value);
        [[AirVideo sharedInstance] playForPosition:value];
    } else
    {
        NSLog(@"couldnt parse position");
    }
    if (value == 0)
    {
        [[[AirVideo sharedInstance] player] setControlStyle:MPMovieControlStyleDefault];
    } else if (value == 1)
    {
        [[[AirVideo sharedInstance] player] setControlStyle:MPMovieControlStyleNone];
    }
    
    return nil;
}


DEFINE_ANE_FUNCTION(playVideo)
{
    NSLog(@"play Video");
    int32_t value;
    if (FREGetObjectAsInt32(argv[0], &value) == FRE_OK)
    {
        NSLog(@"playing for position %i", value);
        [[AirVideo sharedInstance] playForPosition:value];
    } else
    {
        NSLog(@"couldnt parse position");
    }
    
    return nil;
}

DEFINE_ANE_FUNCTION(pauseCurrentVideo)
{
    NSLog(@"pause Video");
    [[AirVideo sharedInstance] pauseVideo];
    return nil;
}



DEFINE_ANE_FUNCTION(bufferVideos)
{
    // todo start displaying the video
    
    
    FREObject arr = argv[0]; // array
    uint32_t arr_len; // array length
    
    FREGetArrayLength(arr, &arr_len);
    
    FREObject populatedArray = NULL;
    // Create a new AS3 Array, pass 0 arguments to the constructor (and no arguments values = NULL)
    FRENewObject((const uint8_t*)"Array", 0, NULL, &populatedArray, nil);
    
    FRESetArrayLength(populatedArray, arr_len);
    
    NSLog(@"Going through the array: %d",arr_len);
    
    NSMutableArray *urls = [NSMutableArray array];
    for(int32_t i=0; i< arr_len;i++){
        
        FREObject element;
        FREGetArrayElementAt(arr, i, &element);
        
        NSString *url = nil;
        const uint8_t *urlString;
        if (FREGetObjectAsUTF8(element, &arr_len, &urlString) == FRE_OK)
        {
            url = [NSString stringWithUTF8String:(const char *)urlString];
        }
        
        if (url)
        {
            [urls addObject:url];
        }
    }

    [[AirVideo sharedInstance] startBuffering:urls];
    
    return nil;
}


DEFINE_ANE_FUNCTION(resumeVideo)
{
    NSLog(@"pause Video");
    [[AirVideo sharedInstance] resume];
    return nil;
}



void AirVideoContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx,
                        uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet) 
{
    
    NSLog(@"[AirVideoContextInitializer]");
    
    // Register the links btwn AS3 and ObjC. (dont forget to modify the nbFuntionsToLink integer if you are adding/removing functions)
    NSInteger nbFuntionsToLink = 9;
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
    
    func[3].name = (const uint8_t*) "setViewDimensions";
    func[3].functionData = NULL;
    func[3].function = &setViewDimensions;
    
    func[4].name = (const uint8_t*) "setControlStyle";
    func[4].functionData = NULL;
    func[4].function = &setControlStyle;
    
    func[5].name = (const uint8_t*) "playVideo";
    func[5].functionData = NULL;
    func[5].function = &playVideo;

    func[6].name = (const uint8_t*) "bufferVideos";
    func[6].functionData = NULL;
    func[6].function = &bufferVideos;

    func[7].name = (const uint8_t*) "pauseCurrentVideo";
    func[7].functionData = NULL;
    func[7].function = &pauseCurrentVideo;

    func[8].name = (const uint8_t*) "resumeVideo";
    func[8].functionData = NULL;
    func[8].function = &resumeVideo;
    
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
