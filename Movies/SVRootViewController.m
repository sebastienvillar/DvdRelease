//
//  SVRootViewController.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVRootViewController.h"
#import "SVSettingsViewController.h"

@interface SVRootViewController ()
@property (strong, readonly) SVDatabase* database;
@property (strong, readonly) SVMoviesSyncManager* moviesSyncManager;
@property (strong, readwrite) SVSettingsViewController* settingsViewController;
@property (strong, readwrite) SVQuery* currentServiceQuery;
@property (strong, readonly) NSNotificationCenter* notificationCenter;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVRootViewController
@synthesize database = _database,
			currentServiceQuery = _currentServiceQuery,
			settingsViewController = _settingsViewController,
			notificationCenter = _notificationCenter,
			moviesSyncManager = _moviesSyncManager;

- (id)init {
	self = [super init];
	if (self) {
		_database = [SVDatabase sharedDatabase];
		_moviesSyncManager = [SVMoviesSyncManager sharedMoviesSyncManager];
		_moviesSyncManager.delegate = self;
		_settingsViewController = nil;
		_notificationCenter = [NSNotificationCenter defaultCenter];
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	NSString* sqlQuery = @"SELECT name FROM watchlist_service WHERE is_current_service = 1;";
	_currentServiceQuery = [[SVQuery alloc] initWithQuery:sqlQuery andSender:self];
	[_database executeQuery:_currentServiceQuery];
	self.view.backgroundColor = [UIColor redColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

//////////////////////////////////////////////////////////////////////
#pragma mark - SVDatabaseSenderProtocol
//////////////////////////////////////////////////////////////////////

- (void)database:(SVDatabase *)database didFinishQuery:(SVQuery *)query {
	NSArray* result = query.result;
	if (query == self.currentServiceQuery) {
		if (result && result.count != 0) {
			self.moviesSyncManager.service = [[result objectAtIndex:0] objectAtIndex:0];
			[self.moviesSyncManager connect];
		}
		else {
			self.settingsViewController = [[SVSettingsViewController alloc] init];
			self.settingsViewController.view.frame = self.view.bounds;
			[self.view addSubview:self.settingsViewController.view];
		}
	}
}

//////////////////////////////////////////////////////////////////////
#pragma mark - SVMoviesSyncManagerDelegate
//////////////////////////////////////////////////////////////////////

- (void)moviesSyncManagerDidStartSyncing:(SVMoviesSyncManager *)aManager {
	[self.notificationCenter postNotificationName:@"moviesSyncManagerDidStartSyncingNotification"
										   object:self];
}

- (void)moviesSyncManagerDidFinishSyncing:(SVMoviesSyncManager *)aManager {
	[self.notificationCenter postNotificationName:@"moviesSyncManagerDidFinishSyncingNotification"
										   object:self];
}

- (void)moviesSyncManagerDidConnect:(SVMoviesSyncManager *)aManager {
	[self.notificationCenter postNotificationName:@"moviesSyncManagerDidConnectNotification"
										   object:self];
	[aManager sync];
}

- (void)moviesSyncManagerConnectionDidFail:(SVMoviesSyncManager *)aManager {
	[self.notificationCenter postNotificationName:@"moviesSyncManagerConnectionDidFailNotification"
										   object:self];
}

- (void)moviesSyncManagerUserDeniedConnection:(SVMoviesSyncManager *)aManager {
	[self.notificationCenter postNotificationName:@"moviesSyncManagerUserDeniedConnectoinNotification"
										   object:self];
}

- (void)moviesSyncManagerDidFailToSync:(SVMoviesSyncManager *)aManager {
	[self.notificationCenter postNotificationName:@"moviesSyncManagerDidFailToSyncNotification"
										   object:self];
}

- (void)moviesSyncManagerNeedsApproval:(SVMoviesSyncManager *)aManager withUrl:(NSURL *)url {
	NSDictionary* dictionary = [NSDictionary dictionaryWithObject:url forKey:@"callbackUrl"];
	[self.notificationCenter postNotificationName:@"moviesSyncManagerNeedsApprovalNotification"
										   object:self
										 userInfo:dictionary];
}

@end
