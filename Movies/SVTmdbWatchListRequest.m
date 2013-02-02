//
//  SVTmdbWatchListRequest.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVTmdbWatchListRequest.h"
#import "SVJsonRequest.h"
#import "SVMovie.h"

@interface SVTmdbWatchListRequest ()
@property (strong, readonly) NSString* sessionId;
@property (strong, readonly) NSString* imageUrl;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVTmdbWatchListRequest
@synthesize result = _result,
			imageUrl = _imageUrl,
			sessionId = _sessionId;

- (id)init {
	self = [super init];
	if (self) {
		_result = [[NSMutableSet alloc] init];
	}
	return self;
}

- (id)initWithSessionId:(NSString*)sessionId andImageUrl:(NSString*)imageUrl {
	self = [self init];
	_sessionId = sessionId;
	_imageUrl = imageUrl;
	return self;
}

- (void)fetch {
	NSLog(@"fetch");
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self fetchPage:1];		
	});
}

- (void)fetchPage:(int)page {
	NSLog(@"fetch page");
    NSString* urlString = [NSString stringWithFormat:@"%@account/%@/movie_watchlist?api_key=%@&session_id=%@&page=%d", kTmdbUrl, self.sessionId, kTmdbKey, self.sessionId, page];
    NSURL* url = [NSURL URLWithString:urlString];
	NSLog(@"url : %@",urlString);
    void(^callbackBlock)(NSObject* json) = ^(NSObject* json) {
		if (!json) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.delegate tmdbWatchListRequestDidFail:self];
			});
			return;
		}
        if ([json isKindOfClass:[NSDictionary class]]) {
            NSDictionary *jsonDictionary = (NSDictionary*)json;
            int numberOfPages = [[jsonDictionary objectForKey:@"total_pages"] intValue];
            NSArray *resultsArray = [jsonDictionary objectForKey:@"results"];
            for (NSDictionary *aMovie in resultsArray) {
                SVMovie *resultMovie = [[SVMovie alloc] init];
                NSURL* imageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.imageUrl, [aMovie objectForKey:@"poster_path"]]];
				NSString *releaseDate = [aMovie objectForKey:@"release_date"];
				NSString *yearOfReleaseString = [[releaseDate componentsSeparatedByString:@"-"] objectAtIndex:0];
				NSNumber *yearOfRelease = [NSNumber numberWithInt:yearOfReleaseString.intValue];
				resultMovie.yearOfRelease = yearOfRelease;
				resultMovie.imageUrl = imageUrl;
                resultMovie.title = [aMovie objectForKey:@"original_title"];
				[self.result addObject:resultMovie];
            }
			if (page < numberOfPages) {
				dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
				dispatch_async(queue, ^{
					[self fetchPage:page + 1];
				});
            }
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.delegate tmdbWatchListRequestDidFinish:self];
				});
			}
        }
        else {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.delegate tmdbWatchListRequestDidFail:self];
			});
			return;
        }
    };
    SVJsonRequest* request = [[SVJsonRequest alloc] initWithUrl:url];
	[request fetchJson:callbackBlock];
}
@end
