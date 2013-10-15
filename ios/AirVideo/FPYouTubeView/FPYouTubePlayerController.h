//
//  FPYouTubePlayerController.h
//  AirYouTube
//
//  Created by Daniel Rodriguez on 12/4/12.
//
//

#import <MediaPlayer/MediaPlayer.h>
#import "FPYouTubeExtractorDelegate.h"

@class FPYouTubeExtractor;
@protocol FPYouTubePlayerControllerDelegate;

@interface FPYouTubePlayerController : MPMoviePlayerController <FPYouTubeExtractorDelegate>

@property (nonatomic, strong) NSString *videoId;

@property (nonatomic, strong, readonly) FPYouTubeExtractor *extractor;
@property (nonatomic, unsafe_unretained) id<FPYouTubePlayerControllerDelegate> delegate;

- (id)initWithVideoId:(NSString *)videoId delegate:(id)delegate;
- (void)dispose;
    
@end
