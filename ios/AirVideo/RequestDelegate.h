//
//  RequestDelegate.h
//  AirVideo
//
//  Created by Thibaut Crenn on 4/1/13.
//
//

#import <Foundation/Foundation.h>
#import "AirVideo.h"

@interface RequestDelegate : NSObject <NSURLConnectionDataDelegate>
{
    AirVideo* controller;
    NSURLRequest* request;
    int position;
    NSMutableData* receivedData;
    NSDate* dl_start;
    NSTimer* watchdog;
    NSURLConnection* active_connection;
    NSURLConnection* secondary_connection;
}

-(id)initWithVideo:(AirVideo*)videoController andRequest:(NSURLRequest *)request forPosition:(int)i;


@property(nonatomic, retain) AirVideo* controller;
@property(nonatomic, retain) NSMutableData* receivedData;
@property(nonatomic, retain) NSURLRequest* request;

@end