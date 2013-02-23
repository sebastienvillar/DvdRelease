//
//  SVRootViewController.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVRootViewController.h"

@interface SVRootViewController ()
@property (strong, readonly) SVDatabase* database;
@property (strong, readonly) SVMoviesSyncManager* moviesSyncManager;
@property (strong, readwrite) SVSettingsViewController* settingsViewController;
@property (strong, readwrite) SVMoviesViewController* moviesViewController;
@property (strong, readwrite) UIViewController* currentController;
@property (strong, readwrite) SVQuery* currentServiceQuery;
@property (strong, readonly) NSNotificationCenter* notificationCenter;
@property (strong, readwrite) UIViewController* myPresentedViewController;
@property (readwrite, getter = isDataAvailable) BOOL dataAvailable;
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
			myPresentedViewController = _myPresentedViewController,
			dataAvailable = _databaseAvailable,
			moviesSyncManager = _moviesSyncManager;

- (id)init {
	self = [super init];
	if (self) {
		_database = [SVDatabase sharedDatabase];
		_moviesSyncManager = [SVMoviesSyncManager sharedMoviesSyncManager];
		_moviesSyncManager.delegate = self;
		_settingsViewController = [[SVSettingsViewController alloc] init];
		_settingsViewController.delegate = self;
		_currentController = nil;
		_databaseAvailable = NO;
		_moviesViewController = [[SVMoviesViewController alloc] init];
		_moviesViewController.delegate = self;
		_notificationCenter = [NSNotificationCenter defaultCenter];
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.view.backgroundColor = [UIColor blackColor];
	NSString* sqlQuery = @"SELECT name FROM watchlist_service;";
	_currentServiceQuery = [[SVQuery alloc] initWithQuery:sqlQuery andSender:self];
	[_database executeQuery:_currentServiceQuery];
}

- (void)loadView {
	self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)loadController:(UIViewController*)controller {
	if (self.currentController) {
		[self.currentController.view removeFromSuperview];
	}
	self.currentController = controller;
	[self.view addSubview:self.currentController.view];
}

- (void)presentViewController:(UIViewController*)viewController withAnimation:(BOOL)isAnimated {
	self.myPresentedViewController = viewController;
	self.myPresentedViewController.view.frame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.size.height, self.currentController.view.bounds.size.width, self.currentController.view.bounds.size.height);
	if (isAnimated) {
		void (^animationBlock)(void) = ^{
			self.myPresentedViewController.view.frame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.currentController.view.bounds.size.width, self.currentController.view.bounds.size.height);
		};
		[UIView animateWithDuration:0.5
							  delay:0
							options:UIViewAnimationCurveLinear
						 animations:animationBlock
						 completion:NULL];
	}
	else {
		self.myPresentedViewController.view.frame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.currentController.view.bounds.size.width, self.currentController.view.bounds.size.height);
	}
	[self.view addSubview:self.myPresentedViewController.view];
}

- (void)dismissViewControllerWithAnimation:(BOOL)isAnimated {
	if (self.myPresentedViewController) {
		if (isAnimated) {
			void (^animationBlock)(void) = ^{
				self.myPresentedViewController.view.frame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.size.height, self.currentController.view.bounds.size.width, self.currentController.view.bounds.size.height);
			};
			void (^completionBlock)(BOOL) = ^(BOOL isFinished){
				if (isFinished) {
					[self.myPresentedViewController.view removeFromSuperview];
					self.myPresentedViewController = nil;
				}
			};
			[UIView animateWithDuration:0.5
								  delay:0 options:UIViewAnimationCurveLinear
							 animations:animationBlock
							 completion:completionBlock];
		}
		else {
			self.myPresentedViewController.view.frame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.size.height, self.currentController.view.bounds.size.width, self.currentController.view.bounds.size.height);
			[self.myPresentedViewController.view removeFromSuperview];
			self.myPresentedViewController = nil;
		}
	}
}


//////////////////////////////////////////////////////////////////////
#pragma mark - SVDatabaseSenderProtocol
//////////////////////////////////////////////////////////////////////


- (void)database:(SVDatabase *)database didFinishQuery:(SVQuery *)query {
	NSArray* result = query.result;
	if (query == self.currentServiceQuery) {
		if (result && result.count != 0) {
			self.moviesSyncManager.service = [[result objectAtIndex:0] objectAtIndex:0];
			[self.moviesViewController loadMainView];
			[self.moviesViewController loadData];
			[self loadController:self.moviesViewController];
			self.dataAvailable = YES;
			[self.moviesSyncManager connect];
		}
		else {
			self.currentController = self.settingsViewController;
			[self.moviesViewController loadLoadingView];
			[self loadController:self.moviesViewController];
			[self presentViewController:self.settingsViewController withAnimation:NO];
			[self.settingsViewController loadSignInView];
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
	if (!self.isDataAvailable) {
		self.dataAvailable = YES;
		[self.moviesViewController loadMainView];
	}
}

- (void)moviesSyncManagerDidConnect:(SVMoviesSyncManager *)aManager {
	[self.notificationCenter postNotificationName:@"moviesSyncManagerDidConnectNotification"
										   object:self];
	[aManager sync];
	if (!self.isDataAvailable) {
		[self.moviesViewController loadLoadingView];
	}
	if (self.myPresentedViewController) {
		[self dismissViewControllerWithAnimation:YES];
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

//////////////////////////////////////////////////////////////////////
#pragma mark - SVMoviesViewControllerDelegate
//////////////////////////////////////////////////////////////////////

- (void)moviesViewControllerDidClickSettingsButton:(SVMoviesViewController *)moviesViewController {
	[self.settingsViewController loadLogOutView];
	[self presentViewController:self.settingsViewController withAnimation:YES];
}

//////////////////////////////////////////////////////////////////////
#pragma mark - SVSettingsViewControllerDelegate
//////////////////////////////////////////////////////////////////////

- (void)settingsViewControllerDidClickHomeButton:(SVSettingsViewController *)settingsViewController {
	if (self.myPresentedViewController) {
		[self dismissViewControllerWithAnimation:YES];
	}
}

- (void)settingsViewControllerDidClickSignInButton:(SVSettingsViewController *)settingsViewController {
	self.moviesSyncManager.service = @"tmdb";
	self.dataAvailable = NO;
	[self.moviesSyncManager connect];
}

- (void)settingsViewControllerDidClickLogOutButton:(SVSettingsViewController *)settingsViewController {
	NSString* statement = @"DELETE FROM watchlist_service;";
	NSString* statement2 = @"DELETE FROM movie;";
	NSArray* statements = [[NSArray alloc] initWithObjects:statement, statement2, nil];
	SVTransaction* transaction = [[SVTransaction alloc] initWithStatements:statements andSender:self];
	[self.database executeTransaction:transaction];
	[self.moviesViewController clearData];
	[settingsViewController loadSignInView];
}

@end
