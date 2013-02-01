//
//  SVJsonRequest.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVJsonRequest.h"

@interface SVJsonRequest () <NSURLConnectionDelegate>

@property (strong, readwrite) void(^callbackBlock)(NSObject *json);
@property (strong, readwrite) NSMutableData *mutableData;

@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVJsonRequest

@synthesize callbackBlock = _callbackBlock,
			url = _url,
			mutableData = _mutableData;

- (id)initWithUrl:(NSURL*)aUrl {
    self = [super init];
    if (self) {
        _callbackBlock = nil;
        _mutableData = nil;
        _url = aUrl;
    }
    return self;
}

- (void)fetchJson:(void(^)(NSObject * json))callbackBlock {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.url];
        [request setHTTPMethod:@"GET"];
        [request setAllHTTPHeaderFields:[NSDictionary dictionaryWithObjectsAndKeys:@"Accept", @"application/json", nil]];
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        if (!connection) {
            callbackBlock(nil);
        }
        else {
            self.callbackBlock = callbackBlock;
            self.mutableData = [[NSMutableData alloc] init];
            CFRunLoopRun();
        }
    });
}

#pragma NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.mutableData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	self.callbackBlock(nil);
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSError *error;
    NSObject *json = [NSJSONSerialization JSONObjectWithData:self.mutableData options:0 error:&error];
    if (json) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.callbackBlock(json);
        });
    }
    else {
        self.callbackBlock(nil);
    }
    CFRunLoopStop(CFRunLoopGetCurrent());
}

@end
