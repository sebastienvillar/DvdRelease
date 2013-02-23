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
@property (strong, readwrite) SVSettingsLogOutView* settingsLogOutView;
@property (strong, readwrite) SVSettingsSignInView* settingsSignInView;
@property (strong, readwrite) SVMoviesSyncManager* moviesSyncManager;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVSettingsViewController
@synthesize webView = _webView,
			settingsLogOutView = _settingsLogOutView,
			settingsSignInView = _settingsSignInView,
			moviesSyncManager = _moviesSyncManager;

- (id)init
{
    self = [super init];
    if (self) {
		_webView = nil;
		_settingsSignInView = [[SVSettingsSignInView alloc] initWithFrame:self.view.bounds];
		_settingsLogOutView = [[SVSettingsLogOutView alloc] initWithFrame:self.view.bounds];
		_moviesSyncManager = [SVMoviesSyncManager sharedMoviesSyncManager];
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
    // Dispose of any resources that can be recreated.
}

- (void)loadView {
	CGRect rect = [UIScreen mainScreen].applicationFrame;
	rect.origin.y = 0;
	self.view = [[UIView alloc] initWithFrame:rect];
}

- (void)loadSignInView {
	[self.webView removeFromSuperview];
	self.view = self.settingsSignInView;
	[self.settingsSignInView.signInButton addTarget:self action:@selector(didClickSignIn) forControlEvents:UIControlEventTouchDown];
}

- (void)loadLogOutView {
	self.view = self.settingsLogOutView;
	[self.settingsLogOutView.logoutButton addTarget:self action:@selector(didClickSignOut) forControlEvents:UIControlEventTouchDown];
	[self.settingsLogOutView.homeButton addTarget:self action:@selector(didClickHome) forControlEvents:UIControlEventTouchDown];
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
	[UIView animateWithDuration:0.5
						  delay:0
						options:UIViewAnimationCurveLinear
					 animations:animationBlock
					 completion:NULL];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
// ACTIONS
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
