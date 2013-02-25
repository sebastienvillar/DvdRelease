//
//  SVSettingsViewController.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVSettingsViewController.h"
#import "SVSettingsLogOutView.h"
#import "SVSettingsSignInView.h"
#import "SVMoviesSyncManager.h"

@interface SVSettingsViewController ()
@property (strong, readwrite) UIWebView* webView;
@property (strong, readonly) NSDictionary* views;
@property (strong, readwrite) UIView* currentView;
@property (readwrite) SVSettingsViewState currentState;
@property (strong, readwrite) SVMoviesSyncManager* moviesSyncManager;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVSettingsViewController
@synthesize webView = _webView,
			views = _views,
			currentState = _currentState,
			currentView = _currentView,
			delegate = _delegate,
			moviesSyncManager = _moviesSyncManager;

- (id)init
{
    self = [super init];
    if (self) {
		_webView = nil;
		SVSettingsSignInView* signInView = [[SVSettingsSignInView alloc] initWithFrame:self.view.bounds];
		[signInView.signInButton addTarget:self action:@selector(didClickSignIn) forControlEvents:UIControlEventTouchDown];
		SVSettingsLogOutView* logOutView = [[SVSettingsLogOutView alloc] initWithFrame:self.view.bounds];
		[logOutView.logoutButton addTarget:self action:@selector(didClickSignOut) forControlEvents:UIControlEventTouchDown];
		[logOutView.homeButton addTarget:self action:@selector(didClickHome) forControlEvents:UIControlEventTouchDown];
		_views = [[NSDictionary alloc] initWithObjectsAndKeys:signInView, @"signInView", logOutView, @"logOutView", nil];
		_moviesSyncManager = [SVMoviesSyncManager sharedMoviesSyncManager];
		_delegate = nil;
		_currentView = nil;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadWebViewWithUrl:) name:@"moviesSyncManagerNeedsApprovalNotification" object:nil];
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

- (void)displayViewForState:(SVSettingsViewState)state {
	switch (state) {
		case SVSettingsViewLoggedOutState: {
			SVSettingsSignInView* view = [self.views objectForKey:@"signInView"];
			view.state = SVSettingsSignInViewNormalState;
			[view.activityIndicatorView stopAnimating];
			[self displayView:view];
			break;
		}
			
		case SVSettingsViewSignedInState: {
			SVSettingsLogOutView* view = [self.views objectForKey:@"logOutView"];
			[self displayView:view];
			break;
		}
			
		case SVSettingsViewLoggedOutErrorState: {
			SVSettingsSignInView* view = [self.views objectForKey:@"signInView"];
			view.state = SVSettingsSignInViewErrorState;
			[view.activityIndicatorView stopAnimating];
			[self displayView:view];
			break;
		}
			
		case SVSettingsViewLoggedOutUserDeniedState: {
			SVSettingsSignInView* view = [self.views objectForKey:@"signInView"];
			view.state = SVSettingsSignInViewUserDeniedState;
			[view.activityIndicatorView stopAnimating];
			[self displayView:view];
			break;
		}
		default:
			break;
	}
	self.currentState = state;
}

- (void)displayView:(UIView*)view {
	if (self.currentView) {
		[self.currentView removeFromSuperview];
	}
	self.currentView = view;
	[self.currentView setNeedsDisplay];
	[self.view addSubview:self.currentView];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)didClickSignIn {
	SVSettingsSignInView* view = [self.views objectForKey:@"signInView"];
	[view.activityIndicatorView startAnimating];
	if ([self.delegate respondsToSelector:@selector(settingsViewControllerDidClickSignInButton:)]) {
		[self.delegate settingsViewControllerDidClickSignInButton:self];
	}
}

- (void)didClickSignOut {
	if ([self.delegate respondsToSelector:@selector(settingsViewControllerDidClickLogOutButton:)]) {
		[self.delegate settingsViewControllerDidClickLogOutButton:self];
	}
}

- (void)didClickHome {
	if ([self.delegate respondsToSelector:@selector(settingsViewControllerDidClickHomeButton:)]) {
		[self.delegate settingsViewControllerDidClickHomeButton:self];
	}
}

@end
