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
		_movies = [[NSMutableSet alloc] init];
		_moviesActions = [[NSMutableDictionary alloc] init];
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
		self.moviesQuerySemaphore = dispatch_semaphore_create(0);
		sqlQuery = @"SELECT * FROM movie";
		self.moviesQuery = [[SVQuery alloc] initWithQuery:sqlQuery andSender:self];
		[self.database executeQuery:self.moviesQuery];
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

	if (query == self.moviesQuery) {
		if (result) {
			for (NSArray* row in result) {
				SVMovie* movie = [[SVMovie alloc] init];
				movie.uuid = [SVAppDelegate uuid];
				movie.identifier = [row objectAtIndex:0];
				movie.title = [row objectAtIndex:1];
				NSString* dateString = [row objectAtIndex:2];
				if (![dateString isEqualToString:@"NULL"]) {
					NSArray* dateArray = [dateString componentsSeparatedByString:@"-"];
					NSCalendar* calendar = [NSCalendar currentCalendar];
					NSDateComponents* dateComponents = [[NSDateComponents alloc] init];
					dateComponents.year = [[dateArray objectAtIndex:0] intValue];
					dateComponents.month = [[dateArray objectAtIndex:1] intValue];
					dateComponents.day = [[dateArray objectAtIndex:2] intValue];
					movie.dvdReleaseDate = [calendar dateFromComponents:dateComponents];
				}
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
		NSArray* fetch = [self fetchTokenAndCallback];
		if (!fetch) {
			[self.delegate moviesSyncManagerConnectionDidFail:self];
			return;
		}
		[self.tmdbInfo setObject:(NSString*)[fetch objectAtIndex:0] forKey:@"token"];
		NSURL* callbackUrl = [NSURL URLWithString:[fetch objectAtIndex:1]];
		[self.delegate moviesSyncManagerNeedsApproval:self withUrl:callbackUrl];
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
		if (transaction == self.sessionIdTransaction) {
			[self.delegate moviesSyncManagerConnectionDidFail:self];
		}
		else if (transaction == self.moviesTransaction) {
			[self.delegate moviesSyncManagerConnectionDidFail:self];
		}
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

		NSMutableSet* toRevoveMovies = [[NSMutableSet alloc] initWithSet:self.movies];
		[toRevoveMovies minusSet:movies];
		[self.movies minusSet:toRevoveMovies];
		
		NSMutableSet* toAddMovies = [[NSMutableSet alloc] initWithSet:movies];
		[toAddMovies minusSet:self.movies];
		
		NSPredicate* predicate = [NSPredicate predicateWithFormat:@"dvdReleaseDate == nil"];
		NSMutableSet* toUpdateMovies = [[NSMutableSet alloc] initWithSet:self.movies];
		[toUpdateMovies filterUsingPredicate:predicate];
		
		for (SVMovie* movie in toRevoveMovies) {
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
			if (toRevoveMovies) {
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
	[self.delegate moviesSyncManagerDidFailSyncing:self];
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
		NSString* statement = [NSString stringWithFormat:@"INSERT INTO movie (title, dvd_release_date, year_of_release) VALUES ('%@', %@, %@);",
							  movie.title,
							  dvdReleaseDate,
							  movie.yearOfRelease];
		[self.moviesTransaction addStatement:statement];
	}
	[self.moviesActions removeObjectForKey:movie.uuid];
	
	if (self.moviesActions.count == 0) {
		[self.database executeTransaction:self.moviesTransaction];
	}
}

- (void)dvdReleaseDateRequestDidFail:(SVRTDvdReleaseDateRequest *)request {
	[self.delegate moviesSyncManagerDidFailSyncing:self];
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
