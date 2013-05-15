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
    NSLog(@"connection failed with error");
    [AirVideo dispatchEvent:@"ERROR" withInfo:[error description]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    [receivedData setLength:0];
    if (httpResponse.statusCode != 200)
    {
        NSLog(@"connection failed with error");
        NSString *info = [NSString stringWithFormat:@"%i", httpResponse.statusCode];
        [AirVideo dispatchEvent:@"ERROR" withInfo:info];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // release the connection, and the data object
    [controller storeVideoData:receivedData atPosition:position];
}


@end
