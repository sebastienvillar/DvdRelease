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
@property (strong, readwrite) SVTransaction* sessionIdTransaction;
@property (strong, readwrite) NSString* sessionId;
@property (strong, readwrite) NSString* token;
@property (readwrite, getter = isTokenAccepted) BOOL tokenAccepted;
@property (readwrite, getter = isLastWebPage) BOOL lastWebPage;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVMoviesSyncManager
@synthesize service = _service,
			sessionIdQuery = _sessionIdQuery,
			sessionIdTransaction = _sessionIdTransaction,
			sessionId = _sessionId,
			tokenAccepted = _tokenAccepted,
			lastWebPage = _lastWebPage,
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
		_tokenAccepted = NO;
		_lastWebPage = NO;
		_sessionIdTransaction = nil;
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
		if (result && result.count != 0) {
			self.sessionId = [[result objectAtIndex:0] objectAtIndex:0];
			if (self.sessionId) {
				[self.delegate moviesSyncManagerDidConnect:self];
				return;
			}
		}
		NSArray* result = [self fetchTokenAndCallback];
		if (!result) {
			[self.delegate moviesSyncManagerConnectionDidFail:self];
			return;
		}
		self.token = [result objectAtIndex:0];
		NSURL* callbackUrl = [NSURL URLWithString:[result objectAtIndex:1]];
		[self.delegate moviesSyncManagerNeedsApproval:self withUrl:callbackUrl];
	}
}

- (void)database:(SVDatabase *)database didFinishTransaction:(SVTransaction *)transaction withSuccess:(BOOL)success {
	NSLog(@"couldn't add session Id");
}

//////////////////////////////////////////////////////////////////////
#pragma mark - Tmdb
//////////////////////////////////////////////////////////////////////

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

- (NSString*)fetchSessionId {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@%@", kTmdbUrl, @"authentication/session/new?api_key=", kTmdbKey, @"&request_token=", self.token]];
    NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:nil error:nil];
    if (!data) {
		return nil;
    }
	NSDictionary *jsonDictionary = [self serializeJson:data];
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
            self.tokenAccepted = YES;
        }
        self.lastWebPage = YES;
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (self.isLastWebPage) {
        if (self.isTokenAccepted) {
			if (self.sessionId = [self fetchSessionId])
				[self.delegate moviesSyncManagerDidConnect:self];
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
