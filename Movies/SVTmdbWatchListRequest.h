//
//  SVTmdbWatchListRequest.h
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kTmdbKey @"apiKey"
#define kTmdbUrl @"https://api.themoviedb.org/3/"

@class SVTmdbWatchListRequest;

@protocol SVTmdbWatchListRequestDelegate <NSObject>
- (void)tmdbWatchListRequestDidFinish:(SVTmdbWatchListRequest*)request;
- (void)tmdbWatchListRequestDidFail:(SVTmdbWatchListRequest*)request;
@end

@interface SVTmdbWatchListRequest : NSObject
@property (strong, readwrite) NSMutableSet* result;
@property (weak, readwrite) NSObject<SVTmdbWatchListRequestDelegate>* delegate;

- (id)initWithSessionId:(NSString*)sessionId andImageUrl:(NSString*)imageUrl;
- (void)fetch;
@end