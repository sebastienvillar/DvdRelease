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
	if (state == SVSettingsViewSignInState) {
		[self displayView:[self.views objectForKey:@"signInView"]];
	}
	else if (state == SVSettingsViewLogOutState) {
		[self displayView:[self.views objectForKey:@"logOutView"]];		
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

- (void)loadWebViewWithUrl:(NSNotification*)notification {
	NSHTTPCookie *cookie;
	NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	for (cookie in [storage cookies]) {
		if (!NSEqualRanges([cookie.domain rangeOfString:@"themoviedb.org"], NSMakeRange(NSNotFound, 0))) {
			[storage deleteCookie:cookie];
		}
	}
	NSDictionary* dictionary = notification.userInfo;
	NSURL* url = [dictionary objectForKey:@"callbackUrl"];
	NSURLRequest* urlRequest = [NSURLRequest requestWithURL:url];
	self.webView = [[UIWebView alloc] init];
	self.webView.delegate = self.moviesSyncManager;
	[self.view addSubview:self.webView];
	[self.webView loadRequest:urlRequest];
	self.webView.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.height, self.view.frame.size.width);
	void(^animationBlock)(void) = ^{
		self.webView.frame = self.view.bounds;
	};
	void(^completionBlock)(BOOL isFinished) = ^(BOOL isFinished){
		if (isFinished) {
			[self.currentView removeFromSuperview];
			self.currentView = self.webView;
		}
	};
	[UIView animateWithDuration:0.5
						  delay:0
						options:UIViewAnimationCurveLinear
					 animations:animationBlock
					 completion:completionBlock];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)didClickSignIn {
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
