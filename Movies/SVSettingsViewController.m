//
//  SVSettingsViewController.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVSettingsViewController.h"
#import "SVSettingsDisconnectedView.h"
#import "SVSettingsConnectedView.h"
#import "SVMoviesSyncManager.h"

@interface SVSettingsViewController ()
@property (strong, readwrite) UIWebView* webView;
@property (strong, readwrite) SVSettingsDisconnectedView* settingsDisconnectedView;
@property (strong, readwrite) SVSettingsConnectedView* settingsConnectedView;
@property (strong, readwrite) SVMoviesSyncManager* moviesSyncManager;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVSettingsViewController
@synthesize webView = _webView,
			settingsDisconnectedView = _settingsDisconnectedView,
			settingsConnectedView = _settingsConnectedView,
			moviesSyncManager = _moviesSyncManager;

- (id)init
{
    self = [super init];
    if (self) {
		_webView = nil;
		_settingsDisconnectedView = [[SVSettingsDisconnectedView alloc] initWithFrame:self.view.bounds];
		_settingsConnectedView = [[SVSettingsConnectedView alloc] initWithFrame:self.view.bounds];
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
	self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

- (void)loadDisconnectedSettingsView {
	self.view = self.settingsDisconnectedView;
	[self.settingsDisconnectedView.signInButton addTarget:self action:@selector(disconnect) forControlEvents:UIControlEventAllTouchEvents];
}

- (void)loadConnectedSettingsView {
	self.view = self.settingsConnectedView;
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
	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    self.webView.frame = self.view.bounds;
    [UIView commitAnimations];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
// ACTIONS
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)disconnect {
	self.moviesSyncManager.service = @"tmdb";
	[self.moviesSyncManager connect];
}

@end
