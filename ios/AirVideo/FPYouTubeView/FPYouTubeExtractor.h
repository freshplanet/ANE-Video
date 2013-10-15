//
//  FPYouTubeExtractor.h
//  AirYouTube
//
//  Created by Daniel Rodriguez on 12/4/12.
//
//

#import "XPathQuery.h"

@protocol FPYouTubeExtractorDelegate;

@interface FPYouTubeExtractor : NSObject <NSURLConnectionDelegate>

@property (nonatomic, strong, readonly) NSURL *youtubeURL;
@property (nonatomic, strong, readonly) NSURL *extractedURL;
@property (nonatomic, unsafe_unretained) id<FPYouTubeExtractorDelegate> delegate;

- (id)initWithVideoId:(NSString*)videoId delegate:(id<FPYouTubeExtractorDelegate>)delegate;
- (void)startExtracting;

@end

