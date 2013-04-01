//
//  RequestDelegate.m
//  AirVideo
//
//  Created by Thibaut Crenn on 4/1/13.
//
//

#import "RequestDelegate.h"

@implementation RequestDelegate
@synthesize controller, receivedData;

-(id)initWithVideo:(AirVideo*)videoController forPosition:(int)i
{
    [super init];
    self.controller = videoController;
    self.receivedData = [[NSMutableData data] retain];
    position = i;
    return self;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [receivedData setLength:0];

}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // release the connection, and the data object
    [controller storeVideoData:receivedData atPosition:position];
}


@end
