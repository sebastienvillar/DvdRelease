//
//  SVRootViewController.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVRootViewController.h"

typedef int SVAnimationStyle;
enum {
	SVAnimationStyleNone = 0,
	SVAnimationStyleFadeIn = 1,
	SVAnimationStyleFadeOut = 2,
	SVAnimationStyleSlideDown = 3,
};

typedef int SVLayoutState;
enum {
	SVLayoutLoggedOutState = 1,
	SVLayoutLoadingState = 2,
	SVLayoutDisplayState = 3,
	SVLayoutSignInState = 4,
	SVLayoutSettingsState = 5,
	SVLayoutLoggedOutErrorState = 6,
	SVLayoutLoggedOutUserDeniedState = 7,
};

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
@property (strong, readwrite) SVTransaction* logOutTransaction;
@property (readwrite) int nbOfSyncTries;
@property (readwrite) SVLayoutState currentLayoutState;
@property (readwrite, getter = isIgnoreFlagEnabled) BOOL ignoreFlagEnabled;

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
			logOutTransaction = _logOutTransaction,
			nbOfSyncTries = _nbOfSyncTries,
			ignoreFlagEnabled = _ignoreFlagEnabled,
			moviesSyncManager = _moviesSyncManager,
			currentLayoutState =_currentLayoutState;

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
		_firstConnection = NO;
		_logOutTransaction = nil;
		_nbOfSyncTries = 0;
		_ignoreFlagEnabled = NO;
		_currentLayoutState = SVLayoutLoggedOutState;
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

- (void)layoutControllerWithState:(SVLayoutState)state {
	SVLayoutState currentLayoutState = self.currentLayoutState;
	switch (state) {
		case SVLayoutLoggedOutState: {
			SVSettingsViewController* settingsViewController = [self.viewControllers objectForKey:@"settingsViewController"];
			[settingsViewController displayViewForState:SVSettingsViewLoggedOutState];
			[self loadController:settingsViewController withAnimation:SVAnimationStyleNone];
			break;
		}
			
		case SVLayoutLoggedOutUserDeniedState: {
			SVSettingsViewController* settingsViewController = [self.viewControllers objectForKey:@"settingsViewController"];
			[settingsViewController displayViewForState:SVSettingsViewLoggedOutUserDeniedState];
			[self loadController:settingsViewController withAnimation:SVAnimationStyleNone];
			break;
		}
			
		case SVLayoutLoggedOutErrorState: {
			SVSettingsViewController* settingsViewController = [self.viewControllers objectForKey:@"settingsViewController"];
			[settingsViewController displayViewForState:SVSettingsViewLoggedOutErrorState];
			[self loadController:settingsViewController withAnimation:SVAnimationStyleNone];
			break;
		}
			
		case SVLayoutLoadingState: {
			SVMoviesViewController* moviesViewController = [self.viewControllers objectForKey:@"moviesViewController"];
			[moviesViewController displayViewForState:SVMoviesViewLoadingState];
			[self loadController:moviesViewController withAnimation:SVAnimationStyleSlideDown];
			break;
		}
			
		case SVLayoutDisplayState: {
			SVMoviesViewController* moviesViewController = [self.viewControllers objectForKey:@"moviesViewController"];
			[moviesViewController displayViewForState:SVMoviesViewDisplayState];
			if (currentLayoutState == SVLayoutLoadingState) {
				[self loadController:moviesViewController withAnimation:SVAnimationStyleNone];
			}
			else if (currentLayoutState == SVLayoutSettingsState) {
				[self loadController:moviesViewController withAnimation:SVAnimationStyleFadeOut];
			}
			else {
				[self loadController:moviesViewController withAnimation:SVAnimationStyleNone];
			}
			break;
		}
		
		case SVLayoutSettingsState: {
			SVSettingsViewController* settingsViewController = [self.viewControllers objectForKey:@"settingsViewController"];
			[settingsViewController displayViewForState:SVSettingsViewSignedInState];
			[self loadController:settingsViewController withAnimation:SVAnimationStyleFadeIn];
			break;
		}
		default: {
			break;
		}
	}
	self.currentLayoutState = state;
}

- (void)loadController:(UIViewController*)viewController withAnimation:(SVAnimationStyle)animationStyle {
	switch (animationStyle) {
		case SVAnimationStyleNone: {
			if (self.currentViewController) {
				[self.currentViewController.view removeFromSuperview];
			}
			CGRect rect = viewController.view.frame;
			rect.origin.y = 0;
			viewController.view.frame = rect;
			[self.view addSubview:viewController.view];
			break;
		}
		
		case SVAnimationStyleSlideDown: {
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
			break;
		}
			
		case SVAnimationStyleFadeIn: {
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
			break;
		}
			
		case SVAnimationStyleFadeOut: {
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
			break;
		}
			
		default:
			break;
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
			[self layoutControllerWithState:SVLayoutDisplayState];
		}
		else {
			self.firstConnection = YES;
			[self layoutControllerWithState:SVLayoutLoggedOutState];
		}
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
	if (!self.isIgnoreFlagEnabled) {
		[self.notificationCenter postNotificationName:@"moviesSyncManagerDidFinishSyncingNotification"
											   object:self];
		self.nbOfSyncTries = 0;
		if (self.isFirstConnection) {
			self.firstConnection = NO;
			[self layoutControllerWithState:SVLayoutDisplayState];
		}
	}
	else {
		self.ignoreFlagEnabled = NO;	
	}
}

- (void)moviesSyncManagerDidConnect:(SVMoviesSyncManager *)aManager {
	[self.notificationCenter postNotificationName:@"moviesSyncManagerDidConnectNotification"
										   object:self];
	[aManager sync];
	if (self.isFirstConnection) {
		[self layoutControllerWithState:SVLayoutLoadingState];
	}
}

- (void)moviesSyncManagerConnectionDidFail:(SVMoviesSyncManager *)aManager withError:(NSError *)error{
	[self.notificationCenter postNotificationName:@"moviesSyncManagerConnectionDidFailNotification"
										   object:self];

	if (self.isFirstConnection) {
		[self layoutControllerWithState:SVLayoutLoggedOutErrorState];
	}
	NSLog(@"Error: %@, description: %@", error.domain, error.localizedDescription);
}

- (void)moviesSyncManagerUserDeniedConnection:(SVMoviesSyncManager *)aManager {
	[self.notificationCenter postNotificationName:@"moviesSyncManagerUserDeniedConnectionNotification"
										   object:self];
	[self layoutControllerWithState:SVLayoutLoggedOutUserDeniedState];
}

- (void)moviesSyncManagerDidFailSyncing:(SVMoviesSyncManager *)aManager withError:(NSError *)error {
	if (!self.isIgnoreFlagEnabled) {
		if (self.nbOfSyncTries < 4) {
			[aManager sync];
			return;
		}
		[self.notificationCenter postNotificationName:@"moviesSyncManagerDidFailSyncingNotification"
												   object:self];
		if (self.isFirstConnection) {
			NSString* statement = @"DELETE FROM watchlist_service;";
			NSArray* statements = [[NSArray alloc] initWithObjects:statement, nil];
			self.logOutTransaction = [[SVTransaction alloc] initWithStatements:statements andSender:self];
			[self.database executeTransaction:self.logOutTransaction];
			self.firstConnection = NO;
			[self layoutControllerWithState:SVLayoutLoggedOutErrorState];
		}
		NSLog(@"Error: %@, description: %@", error.domain, error.localizedDescription);
	}
	else {
		self.ignoreFlagEnabled = NO;
	}
}

- (void)moviesSyncManagerNeedsApproval:(SVMoviesSyncManager *)aManager withUrl:(NSURL *)url {
	self.currentLayoutState = SVLayoutSignInState;
	NSDictionary* dictionary = [NSDictionary dictionaryWithObject:url forKey:@"callbackUrl"];
	[self.notificationCenter postNotificationName:@"moviesSyncManagerNeedsApprovalNotification"
										   object:self
										 userInfo:dictionary];
}

//////////////////////////////////////////////////////////////////////
#pragma mark - SVMoviesViewControllerDelegate
//////////////////////////////////////////////////////////////////////

- (void)moviesViewControllerDidClickSettingsButton:(SVMoviesViewController *)moviesViewController {
	[self layoutControllerWithState:SVLayoutSettingsState];
}

//////////////////////////////////////////////////////////////////////
#pragma mark - SVSettingsViewControllerDelegate
//////////////////////////////////////////////////////////////////////

- (void)settingsViewControllerDidClickHomeButton:(SVSettingsViewController *)settingsViewController {
	[self layoutControllerWithState:SVLayoutDisplayState];
}

- (void)settingsViewControllerDidClickSignInButton:(SVSettingsViewController *)settingsViewController {
	self.firstConnection = YES;
	self.moviesSyncManager.service = @"tmdb";
	[self.moviesSyncManager connect];
}

- (void)settingsViewControllerDidClickLogOutButton:(SVSettingsViewController *)settingsViewController {
	if (self.moviesSyncManager.isSyncing) {
		self.ignoreFlagEnabled = YES;
	}
	NSString* statement = @"DELETE FROM watchlist_service;";
	NSString* statement2 = @"DELETE FROM movie;";
	NSArray* statements = [[NSArray alloc] initWithObjects:statement, statement2, nil];
	self.logOutTransaction = [[SVTransaction alloc] initWithStatements:statements andSender:self];
	[self.database executeTransaction:self.logOutTransaction];
	[self layoutControllerWithState:SVLayoutLoggedOutState];
}

@end
