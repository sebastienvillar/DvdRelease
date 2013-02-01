//
//  SVRootViewController.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVRootViewController.h"
#import "SVMoviesSyncManager.h"

@interface SVRootViewController ()
@property (strong, readonly) SVDatabase* database;
@property (strong, readonly) SVMoviesSyncManager* moviesSyncManager;
@property (strong, readwrite) SVQuery* currentServiceQuery;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVRootViewController
@synthesize database = _database,
			currentServiceQuery = _currentServiceQuery,
			moviesSyncManager = _moviesSyncManager;

- (id)init {
	self = [super init];
	if (self) {
		_database = [SVDatabase sharedDatabase];
		_moviesSyncManager = [SVMoviesSyncManager sharedMoviesSyncManager];
		_moviesSyncManager.service = @"tmdb";
		NSString* sqlQuery = @"SELECT name FROM watchlist_service WHERE is_current_service = 1;";
		_currentServiceQuery = [[SVQuery alloc] initWithQuery:sqlQuery andSender:self];
		[_database executeQuery:_currentServiceQuery];
	}
	return self;
}

- (void)database:(SVDatabase *)database didFinishQuery:(SVQuery *)query {
	NSArray* result = query.result;
	NSLog(@"result : %@",result);
	if (query == self.currentServiceQuery) {
		if (result) {
			NSLog(@"result");
			self.moviesSyncManager.service = [[result objectAtIndex:0] objectAtIndex:0];
			[self.moviesSyncManager connect];
		}
		else {
			//Call settings view controller...
		}
	}
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
