//
//  SVJsonRequest.h
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVJsonRequest : NSObject <NSURLConnectionDelegate>
@property (strong, readwrite) NSURL *url;

+ (NSDictionary *)serializeJson:(NSData *)data;
- (id)initWithUrl:(NSURL*)aUrl;
- (void)fetchJson:(void (^)(NSObject * json))callbackBlock;
@end
