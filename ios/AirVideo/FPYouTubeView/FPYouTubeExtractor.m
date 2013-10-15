//
//  FPYouTubeExtractor.m
//  AirYouTube
//
//  Created by Daniel Rodriguez on 12/4/12.
//
//

#import "FPYouTubeExtractor.h"
#import "FPYouTubeExtractorDelegate.h"

@interface FPYouTubeExtractor ()
{
    NSURLConnection *_connection;
    NSMutableData *_buffer;
}

- (NSURL *)extractURLFromFile:(NSString *)html error:(NSError **)error;
- (void)closeConnection;

-(NSString *)unescapeHTML:(NSString *)string;
-(NSString *)unescapeUnicode:(NSString *)string;
-(NSString *)regExpMatch:(NSString *)target pattern:(NSString *)pattern error:(NSError **)error;

@end

@implementation FPYouTubeExtractor

@synthesize youtubeURL = _youtubeURL;
@synthesize extractedURL = _extractedURL;
@synthesize delegate = _delegate;

#pragma mark - NSObject

- (void)dealloc
{
    [self closeConnection];
}

#pragma mark - FPYouTubeExtractor

- (id)initWithVideoId:(NSString *)videoId delegate:(id<FPYouTubeExtractorDelegate>)delegate
{
    self = [super init];
    
    if (self)
    {
        _youtubeURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@",videoId]];
        _delegate = delegate;
    }
    
    return self;
}

- (void)startExtracting
{
    if (!_buffer || !_extractedURL)
    {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_youtubeURL];
        
        _connection = [NSURLConnection connectionWithRequest:request delegate:self];
        [_connection start];
    }
}

-(NSString *)extractYoutubeParameter:(NSString*)bloc param:(NSString*)param
{
    param = [@"\"" stringByAppendingString: param];
    param = [param stringByAppendingString: @"\": \""];

    NSRange startRange = [bloc rangeOfString: param];
    if (startRange.location != NSNotFound) {
        NSString *extract = [bloc substringFromIndex: startRange.location + [param length]];
        NSRange endRange = [extract rangeOfString: @"\""];
        if (endRange.location != NSNotFound) {
            extract = [extract substringToIndex: endRange.location];
            return extract;
        }
        else {
            NSLog(@"parameter not found: %@, no closing quote found", param);
            return nil;
        }
    }
    else {
        NSLog(@"parameter not found: %@", param);
        return nil;
    }
}

-(NSURL *)extractURLFromFile:(NSString*)html error:(NSError *__autoreleasing*)error
{
    // More information: http://userscripts.org/scripts/review/25105
    
    // Use XPath to find the video data in the web page.
    
    NSLog(@"Entering extractURLFromFile");
    
    NSLog(@"%@", html);
    
    NSString *content = @"";
    NSRange dataRange = [html rangeOfString: @"id=\"player\""]; // should be the same result as <div id="player">
    if (dataRange.location != NSNotFound) {
        html = [html substringFromIndex: dataRange.location];
    }
    else {
        NSLog(@"div not found: %@", @"<div id=\"player\">");
        *error = [NSError errorWithDomain:@"MyDomain" code:3 userInfo:[NSDictionary dictionaryWithObject:@"Incomplete data.  YouTube server change?" forKey:NSLocalizedDescriptionKey]];
        return nil;
    }
    
    dataRange = [html rangeOfString:@"ytplayer.config = "] ;
    if (dataRange.location != NSNotFound) {
        html = [html substringFromIndex: dataRange.location];
    } else {
        NSLog(@"string not found \"ytplayer.config = \" in div player");
        *error = [NSError errorWithDomain:@"MyDomain" code:3 userInfo:[NSDictionary dictionaryWithObject:@"Incomplete data.  YouTube server change?" forKey:NSLocalizedDescriptionKey]];
        return nil;
    }
    
    dataRange = [html rangeOfString: @"</script>"];
    if (dataRange.location != NSNotFound) {
        content = [html substringToIndex: dataRange.location];
    }
    else {
        NSLog(@"script closure not found");
        *error = [NSError errorWithDomain:@"MyDomain" code:3 userInfo:[NSDictionary dictionaryWithObject:@"Incomplete data.  YouTube server change?" forKey:NSLocalizedDescriptionKey]];
        return nil;
    }
    
    NSString *videoId = [self extractYoutubeParameter: content param:@"video_id"];
    NSString *videoTicket = [self extractYoutubeParameter: content param:@"t"];
    NSString *videoFormats = [self extractYoutubeParameter: content param:@"url_encoded_fmt_stream_map"];
    
    if (!videoId || !videoTicket || !videoFormats)
    {
        *error = [NSError errorWithDomain:@"MyDomain" code:3 userInfo:[NSDictionary dictionaryWithObject:@"Incomplete data.  YouTube server change?" forKey:NSLocalizedDescriptionKey]];
        return nil;
    }
    
    NSMutableDictionary *availableVideoURLS = [NSMutableDictionary dictionary];
    
    // Go over the data and extract the data needed to build each URL
    
    
    NSString *sep1 = @"%2C";
    NSString *sep2 = @"%26";
    NSString *sep3 = @"%3D";
    
    if ([videoFormats rangeOfString:@","].location != NSNotFound) {
        sep1 = @",";
        if ([videoFormats rangeOfString:@"&"].location != NSNotFound) {
            sep2 = @"&";
        }
        else {
            sep2 = @"\\u0026";
        }
        sep3 = @"=";
    }

    
    NSArray *videoFormatGroups = [videoFormats componentsSeparatedByString:sep1];
    for (NSString *videoFormatGroup in videoFormatGroups)
    {
        //NSLog(@"===== NEW VIDEO FORMAT");
        //NSLog(@"videoFormat = %@", videoFormatGroup);
        
        NSArray *videoFormatElements = [videoFormatGroup componentsSeparatedByString:sep2];
        
        NSMutableDictionary *videoFormatData = [NSMutableDictionary dictionary];
        
        NSString *sig = nil;
        NSString *url = nil;
            
        for (NSString *videoFormatElement in videoFormatElements)
        {
            if (videoFormatElement) {
                        
                NSArray *data = [videoFormatElement componentsSeparatedByString:sep3];
                        
                if (data.count >= 2) {
                    [videoFormatData setObject:[data objectAtIndex:1] forKey:[data objectAtIndex:0]];
                            
                            //NSLog(@"-----videoFormatData = %@", videoFormatData);
                }
            }
        }
        
        //NSLog(@"-----videoFormatData = %@", videoFormatData);
        
        NSString *itag = [videoFormatData objectForKey:@"itag"];
                    
        if ( ([itag isEqual: @"18"]) || ([itag isEqual: @"22"]) || ([itag isEqual: @"38"]) || ([itag isEqual: @"37"]) ) {
            url = [videoFormatData objectForKey:@"url"];
            sig = [videoFormatData objectForKey:@"sig"];
            
            if (url && sig) {
                if ([url rangeOfString: @","].location != NSNotFound) {
                    url = [url substringToIndex:([url rangeOfString: @","].location) ];
                }
                
                if ([sig rangeOfString: @","].location != NSNotFound) {
                    sig = [sig substringToIndex:([sig rangeOfString: @","].location) ];
                }            
                url = [[self unescapeHTML:url] stringByAppendingString:[NSString stringWithFormat:@"&signature=%@", sig]];
                [availableVideoURLS setObject:url forKey:itag];
            }
        }
    }
    
    // Report error when there are no MP4 videos available
    if ([availableVideoURLS count] <= 0)
    {
        *error = [NSError errorWithDomain:@"MyDomain" code:4 userInfo:[NSDictionary dictionaryWithObject:@"The video is not available in an iOS Friendly format (MP4)." forKey:NSLocalizedDescriptionKey]];
        return nil;
    }
    
    NSLog(@"log 4");
    
    // Return the highest quality video found
    // 38 = MP4 HD 4K (HD)
    // 37 = MP4 HD 1080p (HD)
    // 22 = MP4 720p (HD)
    // 18 = MP4 360p
    NSURL *highestQualityVideoURL = nil;
    for (id key in [NSArray arrayWithObjects:@"18", nil])
    {
        highestQualityVideoURL = [NSURL URLWithString:[availableVideoURLS objectForKey:key]];
        if (highestQualityVideoURL)
        {
            DLog(@"[FPYouTubeExtractor] - Media format type = %@. videoURL = %@", key, highestQualityVideoURL);
            return highestQualityVideoURL;
        }
    }
    NSLog(@"log 5");
    
    return nil;
}

- (void)closeConnection
{
    [_connection cancel];
    _connection = nil;
    _buffer = nil;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSUInteger capacity = (response.expectedContentLength != NSURLResponseUnknownLength) ? response.expectedContentLength : 0;
    _buffer = [[NSMutableData alloc] initWithCapacity:capacity];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_buffer appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *html = [[NSString alloc] initWithData:_buffer encoding:NSUTF8StringEncoding];
    
    [self closeConnection];
    
    NSError *error = nil;
    _extractedURL = [self extractURLFromFile:html error:&error];
    
    if (error)
    {
        if ([self.delegate respondsToSelector:@selector(youTubeExtractor:failedExtractingYouTubeURLWithError:)])
        {
            [self.delegate youTubeExtractor:self failedExtractingYouTubeURLWithError:error];
        }
    }
    else
    {
        if ([self.delegate respondsToSelector:@selector(youTubeExtractor:didSuccessfullyExtractYouTubeURL:)])
        {
            [self.delegate youTubeExtractor:self didSuccessfullyExtractYouTubeURL:_extractedURL];
        }
    }
}

#pragma mark - Extractor Helper Methods

- (NSString *)unescapeHTML:(NSString *)string
{
    // %253A ----> :
    NSString* esc = [string stringByReplacingOccurrencesOfString:@"%25" withString:@"%"];
    
    // %253A ----> :
    esc = [esc stringByReplacingOccurrencesOfString:@"%3A" withString:@":"];
    
    // %252F ----> /
    esc = [esc stringByReplacingOccurrencesOfString:@"%2F" withString:@"/"];
    
    // %253f ----> ?
    esc = [esc stringByReplacingOccurrencesOfString:@"%3F" withString:@"?"];
    
    // %253D ----> =
    esc = [esc stringByReplacingOccurrencesOfString:@"%3D" withString:@"="];
    
    // %2526 ----> &
    esc = [esc stringByReplacingOccurrencesOfString:@"%26" withString:@"&"];
    
    // %25252C ----> %2C
    esc = [esc stringByReplacingOccurrencesOfString:@"%2C" withString:@","];
    
    return esc;
}



- (NSString *)unescapeUnicode:(NSString *)string
{
    // will cause trouble if you have "abc\\\\uvw"
    // \u   --->    \U
    NSString *esc1 = [string stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
    
    // "    --->    \"
    NSString *esc2 = [esc1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    
    // \\"  --->    \"
    NSString *esc3 = [esc2 stringByReplacingOccurrencesOfString:@"\\\\\"" withString:@"\\\""];
    
    NSString *quoted = [[@"\"" stringByAppendingString:esc3] stringByAppendingString:@"\""];
    NSData *data = [quoted dataUsingEncoding:NSUTF8StringEncoding];
    
    //  NSPropertyListFormat format = 0;
    //  NSString *errorDescr = nil;
    NSString *unesc = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
    
    if ([unesc isKindOfClass:[NSString class]])
    {
        // \U   --->    \u
        return [unesc stringByReplacingOccurrencesOfString:@"\\U" withString:@"\\u"];
    }
    
    return nil;
}

- (NSString *)regExpMatch:(NSString *)target pattern:(NSString *)pattern error:(NSError*__autoreleasing*)error
{
    
    // Create Regular Expression from Pattern
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:error];
    
    // Get the range of the first match
    NSRange range = [regex rangeOfFirstMatchInString:target options:0 range:NSMakeRange(0, [target length])];
    
    if (range.location == NSNotFound) {
        return nil;
    }
    // Return the first match (via substringwithRange)
    return [target substringWithRange:range];
    
}

@end