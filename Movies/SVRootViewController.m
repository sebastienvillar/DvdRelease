//
//  SVRootViewController.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVRootViewController.h"
#import "SVHelper.h"

typedef int SVAnimationStyle;
enum {
	SVAnimationStyleNone = 0,
	SVAnimationStyleFadeIn = 1,
	SVAnimationStyleFadeOut = 2,
	SVAnimationStyleSlideDown = 3,
	SVAnimationStyleSlideUp = 4,
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
	SVLayoutWebViewState = 8,
};

@interface SVRootViewController ()
@property (strong, readonly) SVDatabase* database;
@property (strong, readonly) SVMoviesSyncManager* moviesSyncManager;
@property (strong, readwrite) UIViewController* currentViewController;
@property (strong, readwrite) SVQuery* currentServiceQuery;
@property (strong, readonly) NSDictionary* viewControllers;
@property (strong, readonly) NSNotificationCenter* notificationCenter;
@property (readwrite, getter = isFirstConnection) BOOL firstConnection;
@property (strong, readwrite) SVTransaction* logOutTransaction;
@property (readwrite) int nbOfSyncTries;
@property (readwrite) SVLayoutState currentLayoutState;
@property (readwrite, getter = isIgnoreFlagEnabled) BOOL ignoreFlagEnabled;
@property (readwrite, getter = isAnimationFinished) BOOL animationFinished;
@property (strong, readwrite) SVQuery* scheduleLocalNotificationsQuery;

@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVRootViewController
@synthesize database = _database,
			currentServiceQuery = _currentServiceQuery,
			viewControllers = _viewControllers,
			notificationCenter = _notificationCenter,
			currentViewController = _currentViewController,
			logOutTransaction = _logOutTransaction,
			nbOfSyncTries = _nbOfSyncTries,
			ignoreFlagEnabled = _ignoreFlagEnabled,
			moviesSyncManager = _moviesSyncManager,
			animationFinished = _animationFinished,
			scheduleLocalNotificationsQuery = _scheduleLocalNotificationsQuery,
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
		SVWebViewController* webViewController = [[SVWebViewController alloc] init];
		webViewController.delegate = self;
		_viewControllers = [[NSDictionary alloc] initWithObjectsAndKeys:settingsViewController, @"settingsViewController", moviesViewController, @"moviesViewController", webViewController, @"webViewController", nil];
		_currentViewController = nil;
		_firstConnection = NO;
		_logOutTransaction = nil;
		_nbOfSyncTries = 0;
		_ignoreFlagEnabled = NO;
		_currentLayoutState = -1;
		_animationFinished = YES;
		_scheduleLocalNotificationsQuery = nil;
		_notificationCenter = [NSNotificationCenter defaultCenter];
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.view.backgroundColor = [UIColor blackColor];
	NSString* sqlQuery = @"SELECT name FROM watchlist_service;";
	self.currentServiceQuery = [[SVQuery alloc] initWithQuery:sqlQuery andSender:self];
	[self.database executeQuery:self.currentServiceQuery];
}

- (void)loadView {
	self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)scheduleLocalNotifications {
	NSDate *now= [NSDate date];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd"];
	NSString* dateString = [dateFormatter stringFromDate:now];
	NSString* sqlQuery = [NSString stringWithFormat:@"SELECT title, dvd_release_date FROM movie WHERE dvd_release_date > '%@' ORDER BY dvd_release_date ASC;", dateString];
	self.scheduleLocalNotificationsQuery = [[SVQuery alloc] initWithQuery:sqlQuery andSender:self];
	[self.database executeQuery:self.scheduleLocalNotificationsQuery];
}

- (void)layoutControllerWithState:(SVLayoutState)state {
	SVLayoutState currentLayoutState = self.currentLayoutState;
	switch (state) {
		case SVLayoutLoggedOutState: {
			SVSettingsViewController* settingsViewController = [self.viewControllers objectForKey:@"settingsViewController"];
			[settingsViewController displayViewForState:SVSettingsViewLoggedOutState];
			if ((currentLayoutState == SVLayoutSettingsState) || (currentLayoutState == -1)) {
				[self loadController:settingsViewController withAnimation:SVAnimationStyleNone];
			}
			else {
				[self loadController:settingsViewController withAnimation:SVAnimationStyleSlideDown];
			}
			break;
		}
			
		case SVLayoutLoggedOutUserDeniedState: {
			SVSettingsViewController* settingsViewController = [self.viewControllers objectForKey:@"settingsViewController"];
			[settingsViewController displayViewForState:SVSettingsViewLoggedOutUserDeniedState];
			if (currentLayoutState == SVLayoutWebViewState) {
				[self loadController:settingsViewController withAnimation:SVAnimationStyleSlideDown];
			}
			else {
				[self loadController:settingsViewController withAnimation:SVAnimationStyleNone];
			}
			break;
		}
			
		case SVLayoutLoggedOutErrorState: {
			SVSettingsViewController* settingsViewController = [self.viewControllers objectForKey:@"settingsViewController"];
			[settingsViewController displayViewForState:SVSettingsViewLoggedOutErrorState];
			if (currentLayoutState == SVLayoutWebViewState) {
				[self loadController:settingsViewController withAnimation:SVAnimationStyleSlideDown];
			}
			else {
				[self loadController:settingsViewController withAnimation:SVAnimationStyleNone];
			}
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
			if ((currentLayoutState == SVLayoutLoadingState) || (currentLayoutState == -1)) {
				[self loadController:moviesViewController withAnimation:SVAnimationStyleNone];
			}
			else if (currentLayoutState == SVLayoutSettingsState) {
				[self loadController:moviesViewController withAnimation:SVAnimationStyleFadeOut];
			}
			break;
		}
		
		case SVLayoutSettingsState: {
			SVSettingsViewController* settingsViewController = [self.viewControllers objectForKey:@"settingsViewController"];
			[settingsViewController displayViewForState:SVSettingsViewSignedInState];
			[self loadController:settingsViewController withAnimation:SVAnimationStyleFadeIn];
			break;
		}
			
		case SVLayoutWebViewState: {
			SVWebViewController* webViewController = [self.viewControllers objectForKey:@"webViewController"];
			[self loadController:webViewController withAnimation:SVAnimationStyleSlideUp];
		}
			
		default: {
			break;
		}
	}
	self.currentLayoutState = state;
}

- (void)loadController:(UIViewController*)viewController withAnimation:(SVAnimationStyle)animationStyle {
	int delay = 0;
	if (!self.animationFinished) {
		delay = 0.3;
	}
	self.animationFinished = NO;
	switch (animationStyle) {
		case SVAnimationStyleNone: {
			if (self.view.subviews) {
				for (UIView* view in self.view.subviews) {
					[view removeFromSuperview];
				}
			}
			
			void (^animationBlock)(void) = ^{
				CGRect rect = viewController.view.frame;
				rect.origin.y = 0;
				viewController.view.frame = rect;
				[self.view addSubview:viewController.view];
			};
			void (^completionBlock)(BOOL isFinished) = ^(BOOL isFinished){
				if (isFinished) {
					self.animationFinished = YES;
				}
			};
			[UIView animateWithDuration:0
								  delay:delay
								options:UIViewAnimationCurveLinear
							 animations:animationBlock completion:completionBlock];
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
					self.animationFinished = YES;
					[currentViewController.view removeFromSuperview];
				}
			};
			[UIView animateWithDuration:0.5
								  delay:delay
								options:UIViewAnimationCurveLinear
							 animations:animationBlock completion:completionBlock];
			break;
		}
			
		case SVAnimationStyleSlideUp: {
			UIViewController* currentViewController = self.currentViewController;
			CGRect rect = viewController.view.frame;
			rect.origin.y = self.view.frame.size.height;
			viewController.view.frame = rect;
			[self.view addSubview:viewController.view];
			void (^animationBlock)(void) = ^{
				CGRect rect = viewController.view.frame;
				rect.origin.y = 0;
				viewController.view.frame = rect;
			};
			void (^completionBlock)(BOOL isFinished) = ^(BOOL isFinished){
				if (isFinished) {
					self.animationFinished = YES;
					[currentViewController.view removeFromSuperview];
				}
			};
			[UIView animateWithDuration:0.5
								  delay:delay
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
			void (^completionBlock)(BOOL isFinished) = ^(BOOL isFinished){
				if (isFinished) {
					self.animationFinished = YES;
				}
			};
			[UIView animateWithDuration:0.3
								  delay:delay
								options:UIViewAnimationCurveLinear
							 animations:animationBlock
							 completion:completionBlock];
			break;
		}
			
		case SVAnimationStyleFadeOut: {
			UIViewController* currentViewController = self.currentViewController;
			void (^animationBlock)(void) = ^{
				currentViewController.view.alpha = 0;
			};
			void (^completionBlock)(BOOL isFinished) = ^(BOOL isFinished){
				if (isFinished) {
					self.animationFinished = YES;
					[currentViewController.view removeFromSuperview];
				}
			};
			[UIView animateWithDuration:0.3
								  delay:delay
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
	if (query == self.scheduleLocalNotificationsQuery) {
		if (result && result.count != 0) {
			NSMutableArray* notifications = [[NSMutableArray alloc] init];
			for (NSArray* movie in result) {
				NSString* title = [movie objectAtIndex:0];
				NSString* dateString = [movie objectAtIndex:1];
				NSDate* date = [SVHelper dateFromString:dateString];
				NSCalendar *calendar = [NSCalendar currentCalendar];
				NSDateComponents *dateComponents = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date];
				dateComponents.timeZone = [NSTimeZone localTimeZone];
				dateComponents.hour = 16;
				date = [calendar dateFromComponents:dateComponents];
				UILocalNotification* notification = [[UILocalNotification alloc] init];
				notification.fireDate = date;
				notification.alertAction = @"Open";
				notification.alertBody = [NSString stringWithFormat:@"%@ is now available", title];
				[notifications addObject:notification];
			}
			[UIApplication sharedApplication].scheduledLocalNotifications = notifications;
		}
	}
}

//////////////////////////////////////////////////////////////////////
#pragma mark - SVMoviesSyncManagerDelegate
//////////////////////////////////////////////////////////////////////

- (void)moviesSyncManagerDidStartSyncing:(SVMoviesSyncManager *)aManager {
	NSLog(@"did start syncing");
	[self.notificationCenter postNotificationName:@"moviesSyncManagerDidStartSyncingNotification"
										   object:self];
	self.nbOfSyncTries++;
}

- (void)moviesSyncManagerDidFinishSyncing:(SVMoviesSyncManager *)aManager {
	NSLog(@"did finish syncing");
	if (!self.isIgnoreFlagEnabled) {
		[self.notificationCenter postNotificationName:@"moviesSyncManagerDidFinishSyncingNotification"
											   object:self];
		self.nbOfSyncTries = 0;
		if (self.isFirstConnection) {
			self.firstConnection = NO;
			[self layoutControllerWithState:SVLayoutDisplayState];
		}
		[self scheduleLocalNotifications];
	}
	else {
		self.ignoreFlagEnabled = NO;	
	}
}

- (void)moviesSyncManagerDidConnect:(SVMoviesSyncManager *)aManager {
	NSLog(@"did connect");
	[self.notificationCenter postNotificationName:@"moviesSyncManagerDidConnectNotification"
										   object:self];
	[aManager sync];
	if (self.isFirstConnection) {
		[self layoutControllerWithState:SVLayoutLoadingState];
	}
}

- (void)moviesSyncManagerConnectionDidFail:(SVMoviesSyncManager *)aManager withError:(NSError *)error{
	NSLog(@"error : %@", error);

	[self.notificationCenter postNotificationName:@"moviesSyncManagerConnectionDidFailNotification"
										   object:self];

	if (self.isFirstConnection) {
		if (self.isIgnoreFlagEnabled) {
			[aManager performSelector:@selector(connect) withObject:nil afterDelay:1];
		}
		else {
			[self layoutControllerWithState:SVLayoutLoggedOutErrorState];
		}
	}
}

- (void)moviesSyncManagerUserDeniedConnection:(SVMoviesSyncManager *)aManager {
	[self.notificationCenter postNotificationName:@"moviesSyncManagerUserDeniedConnectionNotification"
										   object:self];
	[self layoutControllerWithState:SVLayoutLoggedOutUserDeniedState];
}

- (void)moviesSyncManagerDidFailSyncing:(SVMoviesSyncManager *)aManager withError:(NSError *)error {
	NSLog(@"error : %@", error);
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
	}
	else {
		self.ignoreFlagEnabled = NO;
	}
}

- (void)moviesSyncManagerNeedsApproval:(SVMoviesSyncManager *)aManager withUrl:(NSURL *)url {
	self.currentLayoutState = SVLayoutSignInState;
	SVWebViewController* webViewController = [self.viewControllers objectForKey:@"webViewController"];
	[webViewController loadUrl:url];
	[self layoutControllerWithState:SVLayoutWebViewState];
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
	[[UIApplication sharedApplication] cancelAllLocalNotifications];
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

//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - SVWebViewControllerDelegate
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)webViewControllerDidClickCancelButton:(SVWebViewController *)webViewController {
	[self layoutControllerWithState:SVLayoutLoggedOutState];
}

@end
