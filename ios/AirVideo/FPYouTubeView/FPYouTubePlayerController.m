//
//  FPYouTubePlayerController.m
//  AirYouTube
//
//  Created by Daniel Rodriguez on 12/4/12.
//
//

#import "FPYouTubePlayerController.h"
#import "FPYouTubeExtractor.h"
#import "FPYouTubePlayerControllerDelegate.h"


@implementation FPYouTubePlayerController

@synthesize videoId = _videoId;
@synthesize extractor = _extractor;
@synthesize delegate = _delegate;

#pragma mark - NSObject

- (void)dealloc
{
    self.extractor.delegate = nil;
}

#pragma mark - FPYouTubePlayerController

- (id)initWithVideoId:(NSString *)videoId delegate:(id)delegate
{
    self = [super init];
    
    if (self)
    {
        self.delegate = delegate;
        self.videoId = videoId;
    }
    
    return self;
}

- (void)setVideoId:(NSString *)videoId
{
    [self stop];
    self.extractor.delegate = nil;
    _extractor = [[FPYouTubeExtractor alloc] initWithVideoId:videoId delegate:self];
    [self.extractor startExtracting];
}

- (void)dispose
{
    DLog(@"[FPYouTubePlayerController] - Disposing player...");
    
    [self stop];
    self.fullscreen = NO;
    [self.view removeFromSuperview];
    self.delegate = nil;
}

#pragma mark - FPYouTubeExtractorDelegate

- (void)youTubeExtractor:(FPYouTubeExtractor *)extractor didSuccessfullyExtractYouTubeURL:(NSURL *)videoURL
{
    if ([self.delegate respondsToSelector:@selector(youTubePlayerController:didSuccessfullyExtractYouTubeURL:)])
    {
        [self.delegate youTubePlayerController:self didSuccessfullyExtractYouTubeURL:videoURL];
    }
    else
    {
        DLog(@"[FPYouTubePlayerController] - [delegate respondsToSelector] returned false, delegate = %@", self.delegate);
    }
    
    self.contentURL = videoURL;
    [self play];
}

- (void)youTubeExtractor:(FPYouTubeExtractor *)extractor failedExtractingYouTubeURLWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(youTubePlayerController:failedExtractingYouTubeURLWithError:)])
    {
        [self.delegate youTubePlayerController:self failedExtractingYouTubeURLWithError:error];
    }
    else
    {
        DLog(@"[FPYouTubePlayerController] - [delegate respondsToSelector] returned false, delegate = %@", self.delegate);
    }
}

@end