//
//  SVMoviesSyncManager.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVMoviesSyncManager.h"
#import "SVJsonRequest.h"

static SVMoviesSyncManager* sharedMoviesSyncManager;

@interface SVMoviesSyncManager ()
@property (strong, readonly) SVDatabase* database;
@property (strong, readwrite) SVQuery* sessionIdQuery;
@property (strong, readwrite) SVTransaction* sessionIdTransaction;
@property (strong, readwrite) NSMutableDictionary* tmdbInfo;
@property (strong, readwrite) SVTmdbWatchListRequest* tmdbWatchListRequest;
@property (readwrite, getter = isSyncing) BOOL syncing;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVMoviesSyncManager
@synthesize service = _service,
			sessionIdQuery = _sessionIdQuery,
			sessionIdTransaction = _sessionIdTransaction,
			tmdbWatchListRequest = _tmdbWatchListRequest,
			syncing = _syncing,
			tmdbInfo = _tmdbInfo;

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
		_sessionIdTransaction = nil;
		_tmdbWatchListRequest = nil;
		_syncing = NO;
		_tmdbInfo = [[NSMutableDictionary alloc] init];
		[_tmdbInfo setObject:[NSNumber numberWithBool:NO] forKey:@"isLastWebPage"];
		[_tmdbInfo setObject:[NSNumber numberWithBool:NO] forKey:@"isTokenAccepted"];
	}
	return self;
}

- (void)connect {
	if ([self.service isEqualToString:@"tmdb"]) {
		if (![self configure]) {
			return;
		}
		NSString* sqlQuery = @"SELECT session_id FROM watchlist_service WHERE name='tmdb'";
		self.sessionIdQuery = [[SVQuery alloc] initWithQuery:sqlQuery andSender:self];
		[self.database executeQuery:self.sessionIdQuery];
	}
}

- (void)sync {
	if (self.isSyncing) {
		return;
	}
	self.syncing = YES;
	if ([self.service isEqualToString:@"tmdb"]) {
		self.tmdbWatchListRequest = [[SVTmdbWatchListRequest alloc] initWithSessionId:[self.tmdbInfo objectForKey:(@"sessionId")]
																		  andImageUrl:[self.tmdbInfo objectForKey:(@"imageUrl")]];
		self.tmdbWatchListRequest.delegate = self;
		[self.tmdbWatchListRequest fetch];
		[self.delegate moviesSyncManagerDidStartSyncing:self];
	}
}

- (void)database:(SVDatabase *)database didFinishQuery:(SVQuery *)query {
	NSArray* result = query.result;
	if (query == self.sessionIdQuery) {
		if (result && result.count != 0) {
			[self.tmdbInfo setObject:(NSString*)[[result objectAtIndex:0] objectAtIndex:0] forKey:@"sessionId"];
			if ([self.tmdbInfo objectForKey:@"sessionId"]) {
				[self.delegate moviesSyncManagerDidConnect:self];
				return;
			}
		}
		NSArray* result = [self fetchTokenAndCallback];
		if (!result) {
			[self.delegate moviesSyncManagerConnectionDidFail:self];
			return;
		}
		[self.tmdbInfo setObject:(NSString*)[result objectAtIndex:0] forKey:@"token"];
		NSURL* callbackUrl = [NSURL URLWithString:[result objectAtIndex:1]];
		[self.delegate moviesSyncManagerNeedsApproval:self withUrl:callbackUrl];
	}
}

- (void)database:(SVDatabase *)database didFinishTransaction:(SVTransaction *)transaction withSuccess:(BOOL)success {
	NSLog(@"couldn't add session Id");
}

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
#pragma mark - Tmdb
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////
#pragma mark - SVTmdbWatchListRequestDelegate
//////////////////////////////////////////////////////////////////////

- (void)tmdbWatchListRequestDidFinish:(SVTmdbWatchListRequest *)request {
	self.syncing = NO;
	NSSet* result = request.result;
}

- (void)tmdbWatchListRequestDidFail:(SVTmdbWatchListRequest *)request {
	self.syncing = NO;
	[self.delegate moviesSyncManagerDidFailToSync:self];
}

//////////////////////////////////////////////////////////////////////
#pragma mark - Tmdb Helpers
//////////////////////////////////////////////////////////////////////

- (BOOL)configure {
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", kTmdbUrl, @"configuration?api_key=", kTmdbKey]];
	NSURLResponse *response;
	NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:&response error:nil];
	if (!data) {
		[self.delegate moviesSyncManagerConnectionDidFail:self];
		return NO;
	}
	else {
		NSDictionary *jsonDictionary = [SVJsonRequest serializeJson:data];
		NSDictionary* imageInformation = [jsonDictionary objectForKey:@"images"];
		NSString* baseUrl = [imageInformation objectForKey:@"base_url"];
		NSString* size = [(NSArray*)[imageInformation objectForKey:@"logo_sizes"] objectAtIndex:1];
		[self.tmdbInfo setObject:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseUrl, size]] forKey:@"imageUrl"];
	}
	return YES;
}

- (NSArray*)fetchTokenAndCallback {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", kTmdbUrl, @"authentication/token/new?api_key=", kTmdbKey]];
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:&response error:nil];
    if (!data) {
		return nil;
    }
	NSDictionary *jsonDictionary = [SVJsonRequest serializeJson:data];
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

- (NSString*)fetchSessionId {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@%@", kTmdbUrl, @"authentication/session/new?api_key=", kTmdbKey, @"&request_token=", [self.tmdbInfo objectForKey:@"token"]]];
    NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:nil error:nil];
    if (!data) {
		return nil;
    }
	NSDictionary *jsonDictionary = [SVJsonRequest serializeJson:data];
	BOOL success = (BOOL)[jsonDictionary objectForKey:@"success"];
	if (success) {
		NSString* sessionId = (NSString*)[jsonDictionary objectForKey:@"session_id"];
		NSString* sqlStatement = [NSString stringWithFormat: @"INSERT INTO watchlist_service (name, session_id, is_current_service) VALUES ('tmdb', '%@', 1);", sessionId];
		self.sessionIdTransaction = [[SVTransaction alloc] initWithStatements:[[NSArray alloc] initWithObjects:sqlStatement, nil] andSender:self];
		[self.database executeTransaction:self.sessionIdTransaction];
		return sessionId;
	}
	return nil;
}

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
#pragma mark - RottenTomatoe
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////
#pragma mark - SVRTDvdReleaseDateRequestDelegate
//////////////////////////////////////////////////////////////////////

- (void)dvdReleaseDateRequestDidFinish:(SVRTDvdReleaseDateRequest *)request {
	
}

- (void)dvdReleaseDateRequestDidFail:(SVRTDvdReleaseDateRequest *)request {
	
}

//////////////////////////////////////////////////////////////////////
#pragma mark - UIWebViewDelegate
//////////////////////////////////////////////////////////////////////

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"/(allow|deny)$" options:0 error:nil];
    NSArray *matches = [regex matchesInString:request.URL.description options:NSMatchingReportCompletion range:NSRangeFromString([NSString stringWithFormat:@"0,%d", request.URL.description.length])];
    NSString *matchString = nil;
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match rangeAtIndex:1];
        matchString = [request.URL.description substringWithRange:matchRange];
    }
    if (matchString) {
        if ([matchString isEqualToString:@"allow"]) {
            [self.tmdbInfo setObject:[[NSNumber alloc] initWithBool:YES] forKey:@"isTokenAccepted"];
        }
		[self.tmdbInfo setObject:[[NSNumber alloc] initWithBool:YES] forKey:@"isLastWebPage"];
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (((NSNumber*)[self.tmdbInfo objectForKey:@"isLastWebPage"]).boolValue) {
        if (((NSNumber*)[self.tmdbInfo objectForKey:@"isTokenAccepted"]).boolValue) {
			NSString* sessionId = [self fetchSessionId];
			if (sessionId) {
				[self.tmdbInfo setObject:sessionId forKey:@"sessionId"];
				[self.delegate moviesSyncManagerDidConnect:self];
			}
			else
				[self.delegate moviesSyncManagerConnectionDidFail:self];
        }
        else {
			[self.delegate moviesSyncManagerUserDeniedConnection:self];
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.delegate moviesSyncManagerConnectionDidFail:self];
}

@end
