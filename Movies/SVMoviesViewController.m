//
//  SVMoviesViewController.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVMoviesViewController.h"
#import "SVMovie.h"

@interface SVMoviesViewController ()
@property (strong, readonly) NSNotificationCenter* notificationCenter;
@property (strong, readonly) SVDatabase* database;
@property (strong, readwrite) SVQuery* moviesQuery;
@property (strong, readwrite) NSSet* movies;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVMoviesViewController
@synthesize notificationCenter = _notificationCenter,
			moviesQuery = _moviesQuery,
			database = _database;

- (id)init
{
    self = [super init];
    if (self) {
		_moviesQuery = nil;
		_database = [SVDatabase sharedDatabase];
		_notificationCenter = [NSNotificationCenter defaultCenter];
		//[_notificationCenter addObserver:self selector:@selector(nilSymbol) name:@"moviesSyncManagerDidStartSyncingNotification" object:nil];
		[_notificationCenter addObserver:self selector:@selector(loadData) name:@"moviesSyncManagerDidFinishSyncingNotification" object:nil];
		//[_notificationCenter addObserver:self selector:@selector(nilSymbol) name:@"moviesSyncManagerDidFailToSyncNotification" object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)loadData {
	NSString* sqlStatement = @"SELECT * FROM movie ORDER BY dvd_release_date DESC;";
	self.moviesQuery =  [[SVQuery alloc] initWithQuery:sqlStatement andSender:self];
	[self.database executeQuery:self.moviesQuery];
}

- (void)database:(SVDatabase *)database didFinishQuery:(SVQuery *)query {
	NSArray* result = query.result;
	if (query == self.moviesQuery) {
		/*for (NSArray movieArray in result) {
			SVMovie*
		}*/
	}
}

@end
