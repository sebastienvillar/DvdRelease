//
//  SVRTDvdReleaseDateRequest.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVRTDvdReleaseDateRequest.h"
#import "SVJsonRequest.h"
#import "SVHelper.h"

#define kRottenTomatoeKey @"apiKey"
#define kRottenTomatoeUrl @"http://api.rottentomatoes.com/api/public/v1.0/"
#define kRottenTomatoeMoviesUrl @"movies.json?apikey="

@interface SVRTDvdReleaseDateRequest ()
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVRTDvdReleaseDateRequest
@synthesize movie = _movie,
			result = _result;

- (id)initWithMovie:(SVMovie*)movie {
	self = [super init];
	_movie = movie;
	return self;
}

- (id)init {
	self = [super init];
	if (self) {
		_result = nil;
	}
	return self;
}

- (void)fetch {
    NSString* urlString = [NSString stringWithFormat:@"%@%@%@%@%@", kRottenTomatoeUrl, kRottenTomatoeMoviesUrl, kRottenTomatoeKey, @"&q=", [self.movie.title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL* url = [NSURL URLWithString:urlString];
    void(^callbackBlock)(NSObject* json) = ^(NSObject* json) {
		if (!json) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.delegate dvdReleaseDateRequestDidFail:self];
			});
			return;
		}
        if ([json isKindOfClass:[NSDictionary class]]) {
            NSDictionary* jsonDictionary = (NSDictionary*) json;
			NSString* error = [jsonDictionary objectForKey:@"error"];
			if (error && [error isEqualToString:@"Account Over Queries Per Second Limit"]) {
				NSTimeInterval delay = 1.0;
				[self performSelector:@selector(fetch) withObject:nil afterDelay:delay];
				return;
			}
			NSDictionary* resultMovieDictionary = nil;
			NSArray* moviesArray = [jsonDictionary objectForKey:@"movies"];
			int bestYearDifference = 2;
			for (NSDictionary* aMovieDictionary in moviesArray) {
				int yearOfRelease = [[aMovieDictionary objectForKey:@"year"] intValue];
				NSString *title = [aMovieDictionary objectForKey:@"title"];
				int yearDifference = self.movie.yearOfRelease.intValue - yearOfRelease;
				if ((abs(yearDifference) < bestYearDifference) && [title caseInsensitiveCompare:self.movie.title] == NSOrderedSame) {
					bestYearDifference = yearDifference;
					resultMovieDictionary = aMovieDictionary;
				}
			}
			if (resultMovieDictionary) {
                NSDictionary* releaseDates = [resultMovieDictionary objectForKey:@"release_dates"];
                NSString* dateString = [releaseDates objectForKey:@"dvd"];
				self.result = [SVHelper dateFromString:dateString];
			}
        }
        else {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.delegate dvdReleaseDateRequestDidFail:self];
			});
			return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate dvdReleaseDateRequestDidFinish:self];
        });
    };
    SVJsonRequest* request = [[SVJsonRequest alloc] initWithUrl:url];
	[request fetchJson:callbackBlock];
}
@end