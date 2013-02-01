//
//  SVMoviesSyncManager.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVMoviesSyncManager.h"
#import "SVTmdbWatchListRequest.h"

static SVMoviesSyncManager* sharedMoviesSyncManager;

@interface SVMoviesSyncManager ()
@property (strong, readonly) SVDatabase* database;
@property (strong, readwrite) SVQuery* sessionIdQuery;
@property (strong, readwrite) NSString* sessionId;
@property (strong, readwrite) NSString* token;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVMoviesSyncManager
@synthesize service = _service,
			sessionIdQuery = _sessionIdQuery,
			sessionId = _sessionId,
			token = _token;

+ (SVMoviesSyncManager*)sharedMoviesSyncManager {
	if (!sharedMoviesSyncManager) {
		sharedMoviesSyncManager = [[self alloc] init];
	}
	return sharedMoviesSyncManager;
}

- (id)init {
	self = [super init];
	if (self) {
		_database = [SVDatabase sharedDatabase];
		_service = nil;
		_sessionIdQuery = nil;
		_sessionId = nil;
		_token = nil;
	}
	return self;
}

- (void)connect {
	if ([self.service isEqualToString:@"tmdb"]) {
		NSString* sqlQuery = @"SELECT session_id FROM watchlist_service WHERE name='tmdb'";
		self.sessionIdQuery = [[SVQuery alloc] initWithQuery:sqlQuery andSender:self];
		[self.database executeQuery:self.sessionIdQuery];
	}
}


- (void)database:(SVDatabase *)database didFinishQuery:(SVQuery *)query {
	NSArray* result = query.result;
	if (query == self.sessionIdQuery) {
		if (result) {
			self.sessionId = [[result objectAtIndex:0] objectAtIndex:0];
			if (self.sessionId) {
				[self.delegate movieSyncManagerDidConnect:self];
				return;
			}
		}
		NSArray* result = [self fetchTokenAndCallback];
		if (!result) {
			[self.delegate movieSyncManagerConnectionDidFail:self];
			return;
		}
		self.token = [result objectAtIndex:0];
		NSURL* callbackUrl = [NSURL URLWithString:[result objectAtIndex:1]];
		[self.delegate movieSyncManagerNeedsApproval:self withUrl:callbackUrl];
	}
}

- (NSArray*)fetchTokenAndCallback {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", kTmdbUrl, @"authentication/token/new?api_key=", kTmdbKey]];
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:&response error:nil];
    if (!data) {
		return nil;
    }
	NSDictionary *jsonDictionary = [self serializeJson:data];
	NSString *token = [jsonDictionary objectForKey:@"request_token"];
	NSString *authenticationCallback = nil;
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
	if ([response respondsToSelector:@selector(allHeaderFields)]) {
		NSDictionary *headersDictionary = [httpResponse allHeaderFields];
		authenticationCallback = [headersDictionary objectForKey:@"Authentication-callback"];
	}
	NSArray* result = [[NSArray alloc] initWithObjects:token, authenticationCallback, nil];
	return result;
}

- (NSDictionary *)serializeJson:(NSData *)data {
    NSError *error;
    NSObject *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (json && [json isKindOfClass:[NSDictionary class]]) {
        NSDictionary *jsonDictionary = (NSDictionary *)json;
        return jsonDictionary;
    }
	NSLog(@"SVMoviesSyncManager: Json is nil or not a dictionary");
    return nil;
}

- (NSString*)fetchSessionId {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@%@", kTmdbUrl, @"/3/authentication/session/new?api_key=", kTmdbUrl, @"&request_token=", self.token]];
    NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:nil error:nil];
    if (!data) {
		return nil;
    }
    else {
        NSDictionary *jsonDictionary = [self serializeJson:data];
        BOOL success = (BOOL)[jsonDictionary objectForKey:@"success"];
        if (success) {
            return (NSString*)[jsonDictionary objectForKey:@"session_id"];
        }
    }
	return nil;
}

@end
