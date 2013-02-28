//
//  SVMoviesViewController.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVMoviesViewController.h"
#import "SVMoviesLoadingView.h"
#import "SVMoviesErrorViewCell.h"
#import "SVMoviesTableViewController.h"

#define kSettingsButtonBottom 7
#define kSettingsButtonRight 7

@interface SVMoviesViewController ()
@property (strong, readonly) NSNotificationCenter* notificationCenter;
@property (strong, readwrite) NSDictionary* views;
@property (strong, readwrite) UIView* currentView;
@property (readwrite) SVMoviesViewState currentState;
@property (strong, readonly) SVMoviesTableViewController* tableViewController;
@property (strong, readonly) UIButton* settingsButton;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVMoviesViewController
@synthesize notificationCenter = _notificationCenter,
			currentView = _currentView,
			views = _views,
			delegate = _delegate,
			tableViewController = _tableViewController,
			settingsButton = _settingsButton;

- (id)init
{
    self = [super init];
    if (self) {
		_notificationCenter = [NSNotificationCenter defaultCenter];
		_currentView = nil;
		SVMoviesLoadingView* loadingView = [[SVMoviesLoadingView alloc] initWithFrame:self.view.bounds];
		loadingView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		_settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
		UIImage* settingsButtonImage = [UIImage imageNamed:@"settings_button.png"];
		UIImage* activeSettingsButtonImage = [UIImage imageNamed:@"settings_button_active.png"];
		[_settingsButton setBackgroundImage:settingsButtonImage forState:UIControlStateNormal];
		[_settingsButton setBackgroundImage:activeSettingsButtonImage forState:UIControlStateHighlighted];
		_settingsButton.frame = CGRectMake(self.view.frame.size.width - settingsButtonImage.size.width - kSettingsButtonRight, self.view.frame.size.height - settingsButtonImage.size.height - kSettingsButtonBottom, settingsButtonImage.size.width, settingsButtonImage.size.height);
		[_settingsButton addTarget:self action:@selector(didClickSettingsButton) forControlEvents:UIControlEventTouchDown];
		_tableViewController = [[SVMoviesTableViewController alloc] init];
		UIView* moviesView = [[UIView alloc] initWithFrame:self.view.bounds];
		moviesView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		_tableViewController.tableView.frame = _tableViewController.view.bounds;
		_tableViewController.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		[moviesView addSubview:_tableViewController.tableView];
		_settingsButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
		[moviesView addSubview:_settingsButton];
		_views = [[NSDictionary alloc] initWithObjectsAndKeys:loadingView, @"loadingView", moviesView, @"moviesView", nil];
		[_notificationCenter addObserver:self selector:@selector(connectionDidFail:) name:@"moviesSyncManagerConnectionDidFailNotification" object:nil];
		[_notificationCenter addObserver:self selector:@selector(didStartSyncing:) name:@"moviesSyncManagerDidStartSyncingNotification" object:nil];
		[_notificationCenter addObserver:self selector:@selector(didFinishSyncing:) name:@"moviesSyncManagerDidFinishSyncingNotification" object:nil];
		[_notificationCenter addObserver:self selector:@selector(didFailSyncing:) name:@"moviesSyncManagerDidFailSyncingNotification" object:nil];
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

- (void)loadView {
	CGRect rect = [UIScreen mainScreen].applicationFrame;
	rect.origin.y = 0;
	self.view = [[UIView alloc] initWithFrame:rect];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
}

- (void)displayViewForState:(SVMoviesViewState)state {
	if (state == SVMoviesViewLoadingState) {
		SVMoviesLoadingView* loadingView = [self.views objectForKey:@"loadingView"];
		[loadingView.activityIndicatorView startAnimating];
		[self displayView:[self.views objectForKey:@"loadingView"]];
	}
	else if (state == SVMoviesViewDisplayState) {
		[self.tableViewController loadData];
		UIView* moviesView = [self.views objectForKey:@"moviesView"];
		[self displayView:moviesView];
	}
	self.currentState = state;
}

- (void)displayView:(UIView*)view {
	if (self.currentView) {
		[self.currentView removeFromSuperview];
	}
	self.currentView = view;
	[self.view addSubview:self.currentView];
}


//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Notification actions
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)didStartSyncing:(NSNotification*)notification {
	[self.tableViewController beginRefreshing];
}

- (void)didFinishSyncing:(NSNotification*)notification {
	[self.tableViewController endRefreshing];
	[self.tableViewController loadData];
	[self.tableViewController performSelector:@selector(hideError) withObject:nil afterDelay:0.5];
}

- (void)didFailSyncing:(NSNotification*)notification {
	[self.tableViewController endRefreshing];
	[self.tableViewController displayError];
}

- (void)connectionDidFail:(NSNotification*)notification {
	[self.tableViewController endRefreshing];
	[self.tableViewController displayError];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)didClickSettingsButton {
	if ([self.delegate respondsToSelector:@selector(moviesViewControllerDidClickSettingsButton:)])
		[self.delegate moviesViewControllerDidClickSettingsButton:self];
}


@end
