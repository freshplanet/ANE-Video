//
//  RequestDelegate.m
//  AirVideo
//
//  Created by Thibaut Crenn on 4/1/13.
//
//

#import "RequestDelegate.h"

@implementation RequestDelegate
@synthesize controller, receivedData, request;

-(id)initWithVideo:(AirVideo*)videoController andRequest:(NSURLRequest *)_request forPosition:(int)i
{
    [super init];
    self.controller = videoController;
    self.request = [_request retain];
    self.receivedData = [[NSMutableData data] retain];
    position = i;
    dl_start = NULL;
    connection = [[NSURLConnection connectionWithRequest:request delegate:self] retain];
    return self;
}

-(void)setWatchdogTo:(float) time
{
    watchdog = [[NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(watchdogDidTrigger:) userInfo:Nil repeats:NO] retain];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"connection failed with error");
    [AirVideo dispatchEvent:@"ERROR" withInfo:[error description]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    
    [receivedData appendData:data];
    
    if(watchdog != nil)
    {
        [watchdog invalidate];
        [watchdog release];
        watchdog = nil;
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    [receivedData setLength:0];
    dl_start = [[NSDate date] retain];
    if (httpResponse.statusCode != 200)	
    {
        NSLog(@"connection failed with error");
        NSString *info = [NSString stringWithFormat:@"%i", httpResponse.statusCode];
        [AirVideo dispatchEvent:@"ERROR" withInfo:info];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)_connection
{
    [dl_start release];
    // release the connection, and the data object
    [connection release];
    [controller storeVideoData:receivedData atPosition:position];
}

- (void)watchdogDidTrigger:(NSTimer *)t
{
    [watchdog release];
    watchdog = nil;
    NSLog(@"Server Request reached time limit, sending request again");
    [connection cancel];
    [connection release];
    connection = [[NSURLConnection connectionWithRequest:request delegate:self] retain];
}


@end
