//
//  FPYouTubePlayerControllerDelegate.h
//  AirYouTube
//
//  Created by Alexis Taugeron on 1/11/13.
//
//

@class FPYouTubePlayerController;

@protocol FPYouTubePlayerControllerDelegate <NSObject>

- (void)youTubePlayerController:(FPYouTubePlayerController *)controller didSuccessfullyExtractYouTubeURL:(NSURL *)videoURL;
- (void)youTubePlayerController:(FPYouTubePlayerController *)controller failedExtractingYouTubeURLWithError:(NSError *)error;

@end