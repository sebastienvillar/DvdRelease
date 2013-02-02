//
//  SVSettingsViewController.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVSettingsViewController.h"
#import "SVSettingsView.h"
#import "SVMoviesSyncManager.h"

@interface SVSettingsViewController ()
@property (strong, readwrite) UIView* currentView;
@property (strong, readwrite) UIWebView* webView;
@property (strong, readwrite) SVSettingsView* settingsView;
@property (strong, readwrite) SVMoviesSyncManager* moviesSyncManager;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVSettingsViewController
@synthesize webView = _webView,
			settingsView = _settingsView,
			moviesSyncManager = _moviesSyncManager,
			currentView = _currentView;

- (id)init
{
    self = [super init];
    if (self) {
		_webView = nil;
		_settingsView = [[SVSettingsView alloc] init];
		_currentView = _settingsView;
		_moviesSyncManager = [SVMoviesSyncManager sharedMoviesSyncManager];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadWebViewWithUrl:) name:@"moviesSyncManagerNeedsApprovalNotification" object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.currentView.frame = self.view.bounds;
	[self.view addSubview:self.currentView];
	//For testing
	/////////////
	self.moviesSyncManager.service = @"tmdb";
	[self.moviesSyncManager connect];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadWebViewWithUrl:(NSNotification*)notification {
	NSDictionary* dictionary = notification.userInfo;
	NSURL* url = [dictionary objectForKey:@"callbackUrl"];
	NSURLRequest* urlRequest = [NSURLRequest requestWithURL:url];
	self.webView = [[UIWebView alloc] init];
	self.webView.delegate = self.moviesSyncManager;
	[self.currentView removeFromSuperview];
	self.currentView = self.webView;
	[self.view addSubview:self.currentView];
	[self.webView loadRequest:urlRequest];
	self.webView.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.height, self.view.frame.size.width);
	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    self.webView.frame = self.view.bounds;
    [UIView commitAnimations];
}

@end
