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

FREContext AirVideoContext = nil;

DEFINE_ANE_FUNCTION(airVideoShowPlayer)
{
    DLog(@"Entering airVideoShowPlayer");
    [[AirYouTubeController sharedInstance] addVideoToStage];
    DLog(@"Exiting airVideoShowPlayer");
    return nil;
}

DEFINE_ANE_FUNCTION(airVideoDisposePlayer)
{
    DLog(@"Entering airVideoDisposePlayer");
    [[AirYouTubeController sharedInstance] dispose];
    DLog(@"Exiting airVideoDisposePlayer");
    return nil;
}

DEFINE_ANE_FUNCTION(airVideoResizeVideo)
{
    DLog(@"Entering airVideoResizeVideo");
    
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
    
    CGRect frame;
    frame.origin.x = x;
    frame.origin.y = y;
    frame.size.width = w;
    frame.size.height = h;
    
    [[AirYouTubeController sharedInstance] resizeVideo:frame];
    
    DLog(@"Exiting airVideoResizeVideo");
    
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
    
    NSLog(@"loadVideo path = %@, isLocalFile = %c", path, isLocalFile);
    
    NSURL *url;
    if (path)
    {
        if (isLocalFile) {
            url = [NSURL fileURLWithPath:path isDirectory:NO];
            NSError *unreachableError;
            if ( [url checkResourceIsReachableAndReturnError:&unreachableError] == NO )
            {
                NSLog(@"FileUnreachableError. Error: %@",unreachableError.localizedDescription);
                NSLog(@"Exiting loadVideo");
                return nil;
            }
        }
        else {
            url = [NSURL URLWithString:path];
        }
        [[AirYouTubeController sharedInstance] loadVideoFromUrl:url];
    }
    
    NSLog(@"Exiting airVideoLoadVideo");
    return nil;
}

DEFINE_ANE_FUNCTION(airVideoLoadYoutube)
{
    DLog(@"Entering airVideoLoadYoutube");
    
    uint32_t stringlength;
    
    const uint8_t *htmlString;
    NSString *videoID = nil;
    if (FREGetObjectAsUTF8(argv[0], &stringlength, &htmlString) == FRE_OK)
    {
        videoID = [NSString stringWithUTF8String:(char*) htmlString];
    }
    
    [[AirYouTubeController sharedInstance] loadVideoFromID:videoID];
    DLog(@"Exiting airVideoLoadYoutube");
    
    return nil;
}

void AirVideoContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx,
                        uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet) 
{
    // Register the links btwn AS3 and ObjC. (dont forget to modify the nbFuntionsToLink integer if you are adding/removing functions)
    NSInteger nbFuntionsToLink = 5;
    *numFunctionsToTest = nbFuntionsToLink;
    
    FRENamedFunction* func = (FRENamedFunction*) malloc(sizeof(FRENamedFunction) * nbFuntionsToLink);
    
    func[0].name = (const uint8_t*) "airVideoShowPlayer";
    func[0].functionData = NULL;
    func[0].function = &airVideoShowPlayer;
    
    func[1].name = (const uint8_t*) "airVideoHidePlayer";
    func[1].functionData = NULL;
    func[1].function = &airVideoDisposePlayer;
    
    func[2].name = (const uint8_t*) "airVideoLoadVideo";
    func[2].functionData = NULL;
    func[2].function = &airVideoLoadVideo;
    
    func[3].name = (const uint8_t*) "airVideoLoadYoutube";
    func[3].functionData = NULL;
    func[3].function = &airVideoLoadYoutube;
    
    func[4].name = (const uint8_t*) "airVideoResizeVideo";
    func[4].functionData = NULL;
    func[4].function = &airVideoResizeVideo;
    
    *functionsToSet = func;
    
    AirVideoContext = ctx;
}

void AirVideoContextFinalizer(FREContext ctx) { }

void AirVideoInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet)
{
	*extDataToSet = NULL;
	*ctxInitializerToSet = &AirVideoContextInitializer;
	*ctxFinalizerToSet = &AirVideoContextFinalizer;
}

void AirVideoFinalizer(void *extData) { }
