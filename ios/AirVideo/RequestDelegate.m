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
    watchdog = [[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(watchdogDidTrigger:) userInfo:Nil repeats:NO] retain];
    return self;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"connection failed with error");
    [AirVideo dispatchEvent:@"ERROR" withInfo:[error description]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    
    if( active_connection == nil ){
        active_connection = [connection retain];
        NSLog(@"%@ connection prevailed", (active_connection == secondary_connection)?@"Secondary":@"Primary");
    }
    
    if( connection != active_connection )
    {
        [connection cancel];
        return;
    }
    
    [receivedData appendData:data];
    
    if(watchdog != nil)
    {
        [watchdog invalidate];
        [watchdog release];
        watchdog = nil;
    }
    
//    if( dl_start != NULL )
//    {
//        NSTimeInterval timeSinceDlStart = -[dl_start timeIntervalSinceNow];
//        NSLog(@"bp:%d %f %f",[receivedData length], timeSinceDlStart, [receivedData length]/timeSinceDlStart);
//        if( [receivedData length] > 10000 && [receivedData length]/timeSinceDlStart > 1000 )
//            NSLog(@"slow download detected");
//    }
    
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

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [dl_start release];
    if(secondary_connection != NULL) [secondary_connection release];
    [active_connection release];
    // release the connection, and the data object
    [controller storeVideoData:receivedData atPosition:position];
}

- (void)watchdogDidTrigger:(NSTimer *)t
{
    [watchdog release];
    watchdog = nil;
    NSLog(@"Server Request took more than 1s to be treated, sending request again");
    secondary_connection = [[NSURLConnection connectionWithRequest:request delegate:self] retain];
}


@end
