//
//  SVMoviesViewController.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVMoviesViewController.h"
#import "SVMoviesLoadingView.h"
#import "SVMoviesTopView.h"
#import "SVMoviesTableViewController.h"

static int const kTopViewHeight = 48;
static int const kSettingsButtonBottom = 7;
static int const kSettingsButtonRight = 7;

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
		SVMoviesTopView* topView = [[SVMoviesTopView alloc] initWithFrame:CGRectMake(0, -kTopViewHeight, self.view.frame.size.width, kTopViewHeight)];
		_settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
		UIImage* settingsButtonImage = [UIImage imageNamed:@"settings_button.png"];
		[_settingsButton setBackgroundImage:settingsButtonImage forState:UIControlStateNormal];
		[_settingsButton setBackgroundImage:settingsButtonImage forState:UIControlStateHighlighted];
		_settingsButton.frame = CGRectMake(self.view.frame.size.width - settingsButtonImage.size.width - kSettingsButtonRight, self.view.frame.size.height - settingsButtonImage.size.height - kSettingsButtonBottom, settingsButtonImage.size.width, settingsButtonImage.size.height);
		[_settingsButton addTarget:self action:@selector(didClickSettingsButton) forControlEvents:UIControlEventTouchDown];
		_tableViewController = [[SVMoviesTableViewController alloc] init];
		UIView* moviesView = [[UIView alloc] initWithFrame:self.view.bounds];
		[moviesView addSubview:_tableViewController.view];
		[moviesView addSubview:_settingsButton];
		_views = [[NSDictionary alloc] initWithObjectsAndKeys:loadingView, @"loadingView", topView, @"topView", moviesView, @"moviesView", nil];
		//[_notificationCenter addObserver:self selector:@selector(nilSymbol) name:@"moviesSyncManagerDidStartSyncingNotification" object:nil];
		[_notificationCenter addObserver:self selector:@selector(didFinishSyncing) name:@"moviesSyncManagerDidFinishSyncingNotification" object:nil];
		[_notificationCenter addObserver:self selector:@selector(connectionDidFail) name:@"moviesSyncManagerConnectionDidFailNotification" object:nil];
		[_notificationCenter addObserver:self selector:@selector(didFailSyncing) name:@"moviesSyncManagerDidFailSyncingNotification" object:nil];
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

- (void)didFinishSyncing {
	[self.tableViewController loadData];
}

- (void)didFailSyncing {

}

- (void)connectionDidFail {
	
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)didClickSettingsButton {
	if ([self.delegate respondsToSelector:@selector(moviesViewControllerDidClickSettingsButton:)])
		[self.delegate moviesViewControllerDidClickSettingsButton:self];
}


@end
