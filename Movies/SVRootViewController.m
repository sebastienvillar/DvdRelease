//
//  SVRootViewController.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVRootViewController.h"
#import "SVSettingsViewController.h"
#import "SVMoviesViewController.h"

@interface SVRootViewController ()
@property (strong, readonly) SVDatabase* database;
@property (strong, readonly) SVMoviesSyncManager* moviesSyncManager;
@property (strong, readwrite) SVSettingsViewController* settingsViewController;
@property (strong, readwrite) SVMoviesViewController* moviesViewController;
@property (strong, readwrite) UIViewController* currentController;
@property (strong, readwrite) SVQuery* currentServiceQuery;
@property (strong, readonly) NSNotificationCenter* notificationCenter;
@property (readwrite, getter = isFirstSync) BOOL firstSync;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVRootViewController
@synthesize database = _database,
			currentServiceQuery = _currentServiceQuery,
			settingsViewController = _settingsViewController,
			moviesViewController = _moviesViewController,
			notificationCenter = _notificationCenter,
			currentController = _currentController,
			firstSync = _firstSync,
			moviesSyncManager = _moviesSyncManager;

- (id)init {
	self = [super init];
	if (self) {
		_database = [SVDatabase sharedDatabase];
		_moviesSyncManager = [SVMoviesSyncManager sharedMoviesSyncManager];
		_moviesSyncManager.delegate = self;
		_settingsViewController = [[SVSettingsViewController alloc] init];
		_currentController = nil;
		_firstSync = NO;
		_moviesViewController = [[SVMoviesViewController alloc] init];
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
}

- (void)loadView {
	self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

//////////////////////////////////////////////////////////////////////
#pragma mark - SVDatabaseSenderProtocol
//////////////////////////////////////////////////////////////////////

- (void)loadController:(UIViewController*)controller{
	if (self.currentController) {
		[self.currentController.view removeFromSuperview];
	}
	self.currentController = controller;
	[self.view addSubview:self.currentController.view];
}

- (void)database:(SVDatabase *)database didFinishQuery:(SVQuery *)query {
	NSArray* result = query.result;
	if (query == self.currentServiceQuery) {
		if (result && result.count != 0) {
			self.moviesSyncManager.service = [[result objectAtIndex:0] objectAtIndex:0];
			[self.moviesSyncManager connect];
			[self.notificationCenter postNotificationName:@"moviesSyncManagerDidFinishSyncingNotification"
												   object:self];
			[self loadController:self.moviesViewController];
			[self.moviesViewController loadMainView];
		}
		else {
			self.firstSync = YES;
			self.currentController = self.settingsViewController;
			[self loadController:self.moviesViewController];
			[self.moviesViewController loadLoadingView];
			[self presentViewController:self.settingsViewController animated:NO completion:NULL];
			[self.settingsViewController loadDisconnectedSettingsView];
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
	if (self.isFirstSync) {
		[self.moviesViewController loadMainView];
	}
}

- (void)moviesSyncManagerDidConnect:(SVMoviesSyncManager *)aManager {
	[self.notificationCenter postNotificationName:@"moviesSyncManagerDidConnectNotification"
										   object:self];
	[aManager sync];
	if (self.presentedViewController) {
		[self.presentedViewController dismissViewControllerAnimated:YES completion:NULL];
	}
}

- (void)moviesSyncManagerConnectionDidFail:(SVMoviesSyncManager *)aManager withError:(NSError *)error{
	[self.notificationCenter postNotificationName:@"moviesSyncManagerConnectionDidFailNotification"
										   object:self];
	NSLog(@"Error: %@, description: %@", error.domain, error.localizedDescription);
}

- (void)moviesSyncManagerUserDeniedConnection:(SVMoviesSyncManager *)aManager {
	[self.notificationCenter postNotificationName:@"moviesSyncManagerUserDeniedConnectionNotification"
										   object:self];
	NSLog(@"user denied connection");
}

- (void)moviesSyncManagerDidFailSyncing:(SVMoviesSyncManager *)aManager withError:(NSError *)error{
	[self.notificationCenter postNotificationName:@"moviesSyncManagerDidFailSyncingNotification"
										   object:self];
	NSLog(@"Error: %@, description: %@", error.domain, error.localizedDescription);
}

- (void)moviesSyncManagerNeedsApproval:(SVMoviesSyncManager *)aManager withUrl:(NSURL *)url {
	NSDictionary* dictionary = [NSDictionary dictionaryWithObject:url forKey:@"callbackUrl"];
	[self.notificationCenter postNotificationName:@"moviesSyncManagerNeedsApprovalNotification"
										   object:self
										 userInfo:dictionary];
}

@end
