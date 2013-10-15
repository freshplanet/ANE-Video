//
//  FPYouTubeExtractorDelegate.h
//  AirYouTube
//
//  Created by Alexis Taugeron on 1/11/13.
//
//

@class FPYouTubeExtractor;

@protocol FPYouTubeExtractorDelegate <NSObject>

- (void)youTubeExtractor:(FPYouTubeExtractor *)extractor didSuccessfullyExtractYouTubeURL:(NSURL *)videoURL;
- (void)youTubeExtractor:(FPYouTubeExtractor *)extractor failedExtractingYouTubeURLWithError:(NSError *)error;

@end