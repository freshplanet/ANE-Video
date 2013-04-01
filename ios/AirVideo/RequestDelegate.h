//
//  RequestDelegate.h
//  AirVideo
//
//  Created by Thibaut Crenn on 4/1/13.
//
//

#import <Foundation/Foundation.h>
#import "AirVideo.h"

@interface RequestDelegate : NSObject <NSURLConnectionDelegate>
{
    AirVideo* controller;
    int position;
    NSMutableData* receivedData;
}

-(id)initWithVideo:(AirVideo*)videoController forPosition:(int)i;


@property(nonatomic, retain) AirVideo* controller;
@property(nonatomic, retain) NSMutableData* receivedData;

@end
