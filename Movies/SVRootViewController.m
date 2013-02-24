//
//  SVRootViewController.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVRootViewController.h"

typedef int SVAnimationStyle;
static const int SVAnimationStyleNone = 0;
static const int SVAnimationStyleFadeIn = 1;
static const int SVAnimationStyleFadeOut = 2;
static const int SVAnimationStyleSlideDown = 3;

@interface SVRootViewController ()
@property (strong, readonly) SVDatabase* database;
@property (strong, readonly) SVMoviesSyncManager* moviesSyncManager;
@property (strong, readwrite) UIViewController* currentViewController;
@property (strong, readwrite) SVQuery* currentServiceQuery;
@property (strong, readonly) NSDictionary* viewControllers;
@property (strong, readonly) NSNotificationCenter* notificationCenter;
@property (strong, readwrite) UIViewController* myPresentedViewController;
@property (readwrite, getter = isDataAvailable) BOOL dataAvailable;
@property (readwrite, getter = isFirstConnection) BOOL firstConnection;
@property (strong, readwrite) NSString* lastButtonIdentifier;
@property (strong, readwrite) SVTransaction* logOutTransaction;
@property (readwrite) int nbOfSyncTries;

@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVRootViewController
@synthesize database = _database,
			currentServiceQuery = _currentServiceQuery,
			viewControllers = _viewControllers,
			notificationCenter = _notificationCenter,
			currentViewController = _currentViewController,
			myPresentedViewController = _myPresentedViewController,
			dataAvailable = _databaseAvailable,
			lastButtonIdentifier = _lastButtonIdentifier,
			logOutTransaction = _logOutTransaction,
			nbOfSyncTries = _nbOfSyncTries,
			moviesSyncManager = _moviesSyncManager;

- (id)init {
	self = [super init];
	if (self) {
		_database = [SVDatabase sharedDatabase];
		_moviesSyncManager = [SVMoviesSyncManager sharedMoviesSyncManager];
		_moviesSyncManager.delegate = self;
		SVSettingsViewController* settingsViewController = [[SVSettingsViewController alloc] init];
		settingsViewController.delegate = self;
		SVMoviesViewController* moviesViewController = [[SVMoviesViewController alloc] init];
		moviesViewController.delegate = self;
		_viewControllers = [[NSDictionary alloc] initWithObjectsAndKeys:settingsViewController, @"settingsViewController", moviesViewController, @"moviesViewController", nil];
		_currentViewController = nil;
		_databaseAvailable = NO;
		_lastButtonIdentifier = nil;
		_firstConnection = NO;
		_logOutTransaction = nil;
		_nbOfSyncTries = 0;
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

- (void)layoutControllers {
	UIViewController* currentViewController = self.currentViewController;
	if (!currentViewController) {
		if (self.isFirstConnection) {
			SVSettingsViewController* settingsViewController = (SVSettingsViewController*)[self.viewControllers objectForKey:@"settingsViewController"];
			[settingsViewController displayViewForState:SVSettingsViewSignInState];
			[self loadController:settingsViewController withAnimation:SVAnimationStyleNone];
		}
		else {
			SVMoviesViewController* moviesViewController = (SVMoviesViewController*)[self.viewControllers objectForKey:@"moviesViewController"];
			[moviesViewController displayViewForState:SVMoviesViewDisplayState];
			[self loadController:moviesViewController withAnimation:SVAnimationStyleNone];
		}
	}
	else if (currentViewController == [self.viewControllers objectForKey:@"settingsViewController"]) {
		SVSettingsViewController* settingsViewController = (SVSettingsViewController*)currentViewController;
		if (settingsViewController.currentState == SVSettingsViewSignInState) {
			SVMoviesViewController* moviesViewController = (SVMoviesViewController*)[self.viewControllers objectForKey:@"moviesViewController"];
			[moviesViewController displayViewForState:SVMoviesViewLoadingState];
			[self loadController:moviesViewController withAnimation:SVAnimationStyleSlideDown];
		}
		else if (settingsViewController.currentState == SVSettingsViewLogOutState) {
			if ([self.lastButtonIdentifier isEqualToString:@"home"]) {
				SVMoviesViewController* moviesViewController = (SVMoviesViewController*)[self.viewControllers objectForKey:@"moviesViewController"];
				[moviesViewController displayViewForState:SVMoviesViewDisplayState];
				[self loadController:moviesViewController withAnimation:SVAnimationStyleFadeOut];
			}
			else if ([self.lastButtonIdentifier isEqualToString:@"logOut"]) {
				[settingsViewController displayViewForState:SVSettingsViewSignInState];
				[self loadController:settingsViewController withAnimation:SVAnimationStyleNone];
			}
			self.lastButtonIdentifier = nil;
		}
	}
	else if (currentViewController == [self.viewControllers objectForKey:@"moviesViewController"]) {
		SVMoviesViewController* moviesViewController = (SVMoviesViewController*)currentViewController;
		if (moviesViewController.currentState == SVMoviesViewLoadingState) {
			[moviesViewController displayViewForState:SVMoviesViewDisplayState];
			[self loadController:moviesViewController withAnimation:SVAnimationStyleFadeIn];
		}
		else if (moviesViewController.currentState == SVMoviesViewDisplayState) {
			SVSettingsViewController* settingsViewController = (SVSettingsViewController*)[self.viewControllers objectForKey:@"settingsViewController"];
			[settingsViewController displayViewForState:SVSettingsViewLogOutState];
			[self loadController:settingsViewController withAnimation:SVAnimationStyleFadeIn];
		}
	}
}

- (void)loadController:(UIViewController*)viewController withAnimation:(SVAnimationStyle)animationStyle {
	if (animationStyle == SVAnimationStyleNone) {
		if (self.currentViewController) {
			[self.currentViewController.view removeFromSuperview];
		}
		[self.view addSubview:viewController.view];
	}
	else if (animationStyle == SVAnimationStyleSlideDown) {
		[self.view insertSubview:viewController.view belowSubview:self.currentViewController.view];
		UIViewController* currentViewController = self.currentViewController;
		void (^animationBlock)(void) = ^{
			CGRect rect = currentViewController.view.frame;
			rect.origin.y = self.view.frame.size.height;
			currentViewController.view.frame = rect;
		};
		void (^completionBlock)(BOOL isFinished) = ^(BOOL isFinished){
			if (isFinished) {
				[currentViewController.view removeFromSuperview];
			}
		};
		[UIView animateWithDuration:0.5
							  delay:0
							options:UIViewAnimationCurveLinear
						 animations:animationBlock completion:completionBlock];
	}
	else if (animationStyle == SVAnimationStyleFadeIn) {
		viewController.view.alpha = 0;
		viewController.view.frame = self.view.bounds;
		[self.view addSubview:viewController.view];
		void (^animationBlock)(void) = ^{
			viewController.view.alpha = 1;
		};
		[UIView animateWithDuration:0.3
							  delay:0
							options:UIViewAnimationCurveLinear
						 animations:animationBlock
						 completion:NULL];
	}
	else if (animationStyle == SVAnimationStyleFadeOut) {
		UIViewController* currentViewController = self.currentViewController;
		void (^animationBlock)(void) = ^{
			currentViewController.view.alpha = 0;
		};
		void (^completionBlock)(BOOL isFinished) = ^(BOOL isFinished){
			if (isFinished) {
				[currentViewController.view removeFromSuperview];
			}
		};
		[UIView animateWithDuration:0.3
							  delay:0
							options:UIViewAnimationCurveLinear
						 animations:animationBlock completion:completionBlock];
	}
	self.currentViewController = viewController;
}

//////////////////////////////////////////////////////////////////////
#pragma mark - SVDatabaseSenderProtocol
//////////////////////////////////////////////////////////////////////


- (void)database:(SVDatabase *)database didFinishQuery:(SVQuery *)query {
	NSArray* result = query.result;
	if (query == self.currentServiceQuery) {
		if (result && result.count != 0) {
			self.moviesSyncManager.service = [[result objectAtIndex:0] objectAtIndex:0];
		}
		else {
			self.firstConnection = YES;
		}
		[self layoutControllers];
		[self.moviesSyncManager connect];
	}
}

//////////////////////////////////////////////////////////////////////
#pragma mark - SVMoviesSyncManagerDelegate
//////////////////////////////////////////////////////////////////////

- (void)moviesSyncManagerDidStartSyncing:(SVMoviesSyncManager *)aManager {
	[self.notificationCenter postNotificationName:@"moviesSyncManagerDidStartSyncingNotification"
										   object:self];
	self.nbOfSyncTries++;
}

- (void)moviesSyncManagerDidFinishSyncing:(SVMoviesSyncManager *)aManager {
	[self.notificationCenter postNotificationName:@"moviesSyncManagerDidFinishSyncingNotification"
										   object:self];
	if (self.isFirstConnection) {
		self.firstConnection = NO;
		[self layoutControllers];
	}
}

- (void)moviesSyncManagerDidConnect:(SVMoviesSyncManager *)aManager {
	[self.notificationCenter postNotificationName:@"moviesSyncManagerDidConnectNotification"
										   object:self];
	if (self.isFirstConnection) {
		[self layoutControllers];
	}
	[aManager sync];
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

- (void)moviesSyncManagerDidFailSyncing:(SVMoviesSyncManager *)aManager withError:(NSError *)error {
	if (self.nbOfSyncTries < 4) {
		[aManager sync];
	}
	else {
		[self.notificationCenter postNotificationName:@"moviesSyncManagerDidFailSyncingNotification"
											   object:self];
	}
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
	self.lastButtonIdentifier = @"settings";
	[self layoutControllers];
}

//////////////////////////////////////////////////////////////////////
#pragma mark - SVSettingsViewControllerDelegate
//////////////////////////////////////////////////////////////////////

- (void)settingsViewControllerDidClickHomeButton:(SVSettingsViewController *)settingsViewController {
	self.lastButtonIdentifier = @"home";
	[self layoutControllers];
}

- (void)settingsViewControllerDidClickSignInButton:(SVSettingsViewController *)settingsViewController {
	self.firstConnection = YES;
	self.lastButtonIdentifier = @"signIn";
	self.moviesSyncManager.service = @"tmdb";
	[self.moviesSyncManager connect];
}

- (void)settingsViewControllerDidClickLogOutButton:(SVSettingsViewController *)settingsViewController {
	NSString* statement = @"DELETE FROM watchlist_service;";
	NSString* statement2 = @"DELETE FROM movie;";
	NSArray* statements = [[NSArray alloc] initWithObjects:statement, statement2, nil];
	self.logOutTransaction = [[SVTransaction alloc] initWithStatements:statements andSender:self];
	[self.database executeTransaction:self.logOutTransaction];
}

//////////////////////////////////////////////////////////////////////
#pragma mark - SVDatabaseSenderProtocol
//////////////////////////////////////////////////////////////////////

- (void)database:(SVDatabase *)database didFinishTransaction:(SVTransaction *)transaction withSuccess:(BOOL)success {
	if (transaction == self.logOutTransaction) {
		if (success) {
			self.lastButtonIdentifier = @"logOut";
			[self layoutControllers];
		}
	}
}

@end
