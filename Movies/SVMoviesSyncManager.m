//
//  SVMoviesSyncManager.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVMoviesSyncManager.h"
#import "SVJsonRequest.h"
#import "SVAppDelegate.h"
#import "SVImageManager.h"
#import "SVHelper.h"

#define kTmdbConfigureUrl @"configuration?api_key="
#define kTmdbSessionIdUrl @"authentication/session/new?api_key="
#define kTmdbTokenUrl @"authentication/token/new?api_key="

static SVMoviesSyncManager* sharedMoviesSyncManager;

@interface SVMoviesSyncManager ()
@property (strong, readonly) SVDatabase* database;
@property (strong, readwrite) SVQuery* sessionIdQuery;
@property (strong, readwrite) SVQuery* moviesQuery;
@property (strong, readwrite) SVTransaction* sessionIdTransaction;
@property (strong, readwrite) SVTransaction* moviesTransaction;
@property (readwrite) dispatch_semaphore_t moviesQuerySemaphore;
@property (strong, readwrite) NSMutableDictionary* tmdbInfo;
@property (strong, readwrite) NSMutableDictionary* moviesActions;
@property (strong, readwrite) NSMutableSet* movies;
@property (strong, readwrite) SVTmdbWatchListRequest* tmdbWatchListRequest;
@property (readwrite, getter = isErrorAlreadyReported) BOOL errorAlreadyReported;

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
			moviesQuery = _moviesQuery,
			movies = _movies,
			moviesTransaction = _moviesTransaction,
			moviesQuerySemaphore = _moviesQuerySemaphore,
			errorAlreadyReported = _errorAlreadyReported,
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
		_moviesQuery = nil;
		_moviesQuerySemaphore = nil;
		_moviesTransaction = nil;
		_errorAlreadyReported = NO;
		_movies = nil;
		_moviesActions = [[NSMutableDictionary alloc] init];
		_tmdbInfo = [[NSMutableDictionary alloc] init];
		[_tmdbInfo setObject:[NSNumber numberWithBool:NO] forKey:@"isLastWebPage"];
		[_tmdbInfo setObject:[NSNumber numberWithBool:NO] forKey:@"isTokenAccepted"];
	}
	return self;
}

- (void)connect {
	if ([self.service isEqualToString:@"tmdb"]) {
		[self configure];
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

//////////////////////////////////////////////////////////////////////
#pragma mark - SVDatabaseSenderProtocol
//////////////////////////////////////////////////////////////////////

- (void)database:(SVDatabase *)database didFinishQuery:(SVQuery *)query {
	NSArray* result = query.result;

	if (query == self.moviesQuery) {
		if (result) {
			for (NSArray* row in result) {
				SVMovie* movie = [[SVMovie alloc] init];
				movie.uuid = [SVAppDelegate uuid];
				movie.identifier = [row objectAtIndex:0];
				movie.title = [row objectAtIndex:1];
				NSString* dateString = [row objectAtIndex:2];
				movie.dvdReleaseDate = [SVHelper dateFromString:dateString];
				movie.yearOfRelease = [row objectAtIndex:3];
				movie.imageUrl = [NSURL URLWithString:[row objectAtIndex:4]];
				movie.imageFileName = [row objectAtIndex:5];
				movie.smallImageFileName = [row objectAtIndex:6];
				[self.movies addObject:movie];
			}
		}
		dispatch_semaphore_signal(self.moviesQuerySemaphore);
	}
	
	else if (query == self.sessionIdQuery) {
		if (result && result.count != 0) {
			[self.tmdbInfo setObject:(NSString*)[[result objectAtIndex:0] objectAtIndex:0] forKey:@"sessionId"];
			if ([self.tmdbInfo objectForKey:@"sessionId"]) {
				[self.delegate moviesSyncManagerDidConnect:self];
				return;
			}
		}
		[self fetchToken];
	}
}

- (void)database:(SVDatabase *)database didFinishTransaction:(SVTransaction *)transaction withSuccess:(BOOL)success {
	if (success) {
		if (transaction == self.moviesTransaction) {
			[self.delegate moviesSyncManagerDidFinishSyncing:self];
			self.syncing = NO;
		}
	}
	else {
		NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];
		[userInfo setObject:[NSString stringWithFormat:@"Transaction %@ failed", transaction] forKey:NSLocalizedDescriptionKey];
		NSError* error = [[NSError alloc] initWithDomain:@"MovieSyncManager" code:0 userInfo:userInfo];
		[self.delegate moviesSyncManagerConnectionDidFail:self withError:error];
	}
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
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		if (self.moviesQuerySemaphore) {
			dispatch_semaphore_wait(self.moviesQuerySemaphore, DISPATCH_TIME_FOREVER);
			self.moviesQuerySemaphore = nil;
		}
		NSMutableSet* movies = request.result;
		self.moviesTransaction = [[SVTransaction alloc] initWithSender:self];

		NSMutableSet* toRemoveMovies = [[NSMutableSet alloc] initWithSet:self.movies];
		[toRemoveMovies minusSet:movies];
		[self.movies minusSet:toRemoveMovies];
		
		NSMutableSet* toAddMovies = [[NSMutableSet alloc] initWithSet:movies];
		[toAddMovies minusSet:self.movies];
		
		NSPredicate* predicate = [NSPredicate predicateWithFormat:@"dvdReleaseDate == nil"];
		NSMutableSet* toUpdateMovies = [[NSMutableSet alloc] initWithSet:self.movies];
		[toUpdateMovies filterUsingPredicate:predicate];
		
		for (SVMovie* movie in toRemoveMovies) {
			NSString* sqlStatement = [NSString stringWithFormat:@"DELETE FROM movie WHERE id = %@;", movie.identifier];
			[self.moviesTransaction addStatement:sqlStatement];
		}
		
		for (SVMovie* movie in toUpdateMovies) {
			[self.moviesActions setObject:@"update" forKey:movie.uuid];
		}
		
		for (SVMovie* movie in toAddMovies) {
			movie.uuid = [SVAppDelegate uuid];
			[self.moviesActions setObject:@"add" forKey:movie.uuid];
		}

		NSMutableSet* toFetchMovies = [[NSMutableSet alloc] initWithSet:toUpdateMovies];
		[toFetchMovies unionSet:toAddMovies];
		
		for (SVMovie* movie in toFetchMovies) {
			SVRTDvdReleaseDateRequest* dvdReleaseDateRequest = [[SVRTDvdReleaseDateRequest alloc] initWithMovie:movie];
			dvdReleaseDateRequest.delegate = self;
			[dvdReleaseDateRequest fetch];
		}
		if (toFetchMovies.count == 0) {
			if (toRemoveMovies) {
				[self.database executeTransaction:self.moviesTransaction];
			}
			else {
				[self.delegate moviesSyncManagerDidFinishSyncing:self];
				self.syncing = NO;
			}
		}
	});
}

- (void)tmdbWatchListRequestDidFail:(SVTmdbWatchListRequest *)request {
	self.syncing = NO;
	NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject:@"WatchList request failed" forKey:NSLocalizedDescriptionKey];
	NSError* error = [[NSError alloc] initWithDomain:@"MovieSyncManager" code:0 userInfo:userInfo];
	[self.delegate moviesSyncManagerDidFailSyncing:self withError:error];
}

//////////////////////////////////////////////////////////////////////
#pragma mark - Tmdb Helpers
//////////////////////////////////////////////////////////////////////

- (void)configure {
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", kTmdbUrl, kTmdbConfigureUrl, kTmdbKey]];
	SVJsonRequest* jsonRequest = [[SVJsonRequest alloc] initWithUrl:url];
	void (^callbackBlock) (NSObject* json) = ^(NSObject* json){
		dispatch_async(dispatch_get_main_queue(), ^{
			if (!json) {
				NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];
				[userInfo setObject:[NSString stringWithFormat:@"Configure failed"] forKey:NSLocalizedDescriptionKey];
				NSError* error = [[NSError alloc] initWithDomain:@"MovieSyncManager" code:0 userInfo:userInfo];
				[self.delegate moviesSyncManagerConnectionDidFail:self withError:error];
				return;
			}
			NSDictionary *jsonDictionary = (NSDictionary*)json;
			NSDictionary* imageInformation = [jsonDictionary objectForKey:@"images"];
			NSString* baseUrl = [imageInformation objectForKey:@"base_url"];
			NSString* size = [(NSArray*)[imageInformation objectForKey:@"logo_sizes"] objectAtIndex:4];
			[self.tmdbInfo setObject:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseUrl, size]] forKey:@"imageUrl"];

			self.movies = [[NSMutableSet alloc] init];
			NSString* sqlQuery = @"SELECT session_id FROM watchlist_service WHERE name='tmdb'";
			self.sessionIdQuery = [[SVQuery alloc] initWithQuery:sqlQuery andSender:self];
			[self.database executeQuery:self.sessionIdQuery];
			self.moviesQuerySemaphore = dispatch_semaphore_create(0);
			sqlQuery = @"SELECT * FROM movie";
			self.moviesQuery = [[SVQuery alloc] initWithQuery:sqlQuery andSender:self];
			[self.database executeQuery:self.moviesQuery];
		});
	};
	[jsonRequest fetchJson:callbackBlock];
}

- (void)fetchToken {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", kTmdbUrl, kTmdbTokenUrl, kTmdbKey]];
	SVJsonRequest* jsonRequest = [[SVJsonRequest alloc] initWithUrl:url];
	void (^callbackBlock) (NSObject* json) = ^(NSObject* json) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (!json) {
				NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];
				[userInfo setObject:[NSString stringWithFormat:@"FetchToken failed"] forKey:NSLocalizedDescriptionKey];
				NSError* error = [[NSError alloc] initWithDomain:@"MovieSyncManager" code:0 userInfo:userInfo];
				[self.delegate moviesSyncManagerConnectionDidFail:self withError:error];
				return;
			}
			NSDictionary *jsonDictionary = (NSDictionary*)json;
			NSString *token = [jsonDictionary objectForKey:@"request_token"];
			NSString *authenticationCallback = nil;
			NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)jsonRequest.response;
			if ([httpResponse respondsToSelector:@selector(allHeaderFields)]) {
				NSDictionary *headersDictionary = [httpResponse allHeaderFields];
				authenticationCallback = [headersDictionary objectForKey:@"Authentication-callback"];
				[self.tmdbInfo setObject:token forKey:@"token"];
				NSURL* callbackUrl = [NSURL URLWithString:authenticationCallback];
				[self.delegate moviesSyncManagerNeedsApproval:self withUrl:callbackUrl];
			}
			else {
				NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];
				[userInfo setObject:[NSString stringWithFormat:@"Callback url not found"] forKey:NSLocalizedDescriptionKey];
				NSError* error = [[NSError alloc] initWithDomain:@"MovieSyncManager" code:0 userInfo:userInfo];
				[self.delegate moviesSyncManagerConnectionDidFail:self withError:error];
			}
		});
	};
	[jsonRequest fetchJson:callbackBlock];
}

- (void)fetchSessionId {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@%@", kTmdbUrl, kTmdbSessionIdUrl, kTmdbKey, @"&request_token=", [self.tmdbInfo objectForKey:@"token"]]];
	SVJsonRequest* jsonRequest = [[SVJsonRequest alloc] initWithUrl:url];
	void (^callbackBlock) (NSObject* json) = ^(NSObject* json) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (!json) {
				NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];
				[userInfo setObject:[NSString stringWithFormat:@"FetchSessionId failed"] forKey:NSLocalizedDescriptionKey];
				NSError* error = [[NSError alloc] initWithDomain:@"MovieSyncManager" code:0 userInfo:userInfo];
				[self.delegate moviesSyncManagerConnectionDidFail:self withError:error];
				return;
			}
			NSDictionary *jsonDictionary = (NSDictionary*)json;
			BOOL success = (BOOL)[jsonDictionary objectForKey:@"success"];
			if (success) {
				NSString* sessionId = (NSString*)[jsonDictionary objectForKey:@"session_id"];
				NSString* sqlStatement = [NSString stringWithFormat: @"INSERT INTO watchlist_service (name, session_id) VALUES ('tmdb', '%@');", sessionId];
				self.sessionIdTransaction = [[SVTransaction alloc] initWithStatements:[[NSArray alloc] initWithObjects:sqlStatement, nil] andSender:self];
				[self.database executeTransaction:self.sessionIdTransaction];
				[self.tmdbInfo setObject:sessionId forKey:@"sessionId"];
				[self.delegate moviesSyncManagerDidConnect:self];
			}
			else {
				NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];
				[userInfo setObject:[NSString stringWithFormat:@"FetchSessionId denied"] forKey:NSLocalizedDescriptionKey];
				NSError* error = [[NSError alloc] initWithDomain:@"MovieSyncManager" code:0 userInfo:userInfo];
				[self.delegate moviesSyncManagerConnectionDidFail:self withError:error];
			}
		});
	};
	[jsonRequest fetchJson:callbackBlock];
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
	NSDate* date = request.result;
	SVMovie* movie = request.movie;
	NSString* dvdReleaseDate = @"NULL";
	if (date) {
		NSCalendar* calendar = [NSCalendar currentCalendar];
		NSDateComponents* components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date];
		dvdReleaseDate = [NSString stringWithFormat:@"'%d-%d-%d'", components.year, components.month, components.day];
		if ([((NSString*)[self.moviesActions objectForKey:movie.uuid]) isEqualToString:@"update"]) {
			NSString* statement = [NSString stringWithFormat:@"UPDATE movie SET dvd_release_date = %@ WHERE id = %@;",
								   dvdReleaseDate,
								   movie.identifier];
			[self.moviesTransaction addStatement:statement];
		}
	}
	if ([((NSString*)[self.moviesActions objectForKey:movie.uuid]) isEqualToString:@"add"]) {
		NSString* statement = [NSString stringWithFormat:@"INSERT INTO movie (title, dvd_release_date, year_of_release, image_url) VALUES ('%@', %@, %@, '%@');",
							  movie.title,
							  dvdReleaseDate,
							  movie.yearOfRelease,
							  movie.imageUrl.absoluteString];
		[self.moviesTransaction addStatement:statement];
	}
	[self.moviesActions removeObjectForKey:movie.uuid];
	
	if (self.moviesActions.count == 0) {
		if (!self.isErrorAlreadyReported) {
			[self.database executeTransaction:self.moviesTransaction];
		}
		self.errorAlreadyReported = NO;
	}
}

- (void)dvdReleaseDateRequestDidFail:(SVRTDvdReleaseDateRequest *)request {
	NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject:@"DvdReleaseDateRequest failed" forKey:NSLocalizedDescriptionKey];
	NSError* error = [[NSError alloc] initWithDomain:@"MovieSyncManager" code:0 userInfo:userInfo];
	if (!self.isErrorAlreadyReported) {
		[self.delegate moviesSyncManagerDidFailSyncing:self withError:error];
	}
	[self.moviesActions removeObjectForKey:request.movie.uuid];
	self.errorAlreadyReported = YES;
	if (self.moviesActions.count == 0)
		self.errorAlreadyReported = NO;
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
		[self.tmdbInfo setObject:[[NSNumber alloc] initWithBool:NO] forKey:@"isLastWebPage"];
        if (((NSNumber*)[self.tmdbInfo objectForKey:@"isTokenAccepted"]).boolValue) {
			[self.tmdbInfo setObject:[[NSNumber alloc] initWithBool:NO] forKey:@"isTokenAccepted"];
			[self fetchSessionId];
        }
        else {
			[self.delegate moviesSyncManagerUserDeniedConnection:self];
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.delegate moviesSyncManagerConnectionDidFail:self withError:error];
}

@end
