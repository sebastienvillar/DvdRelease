//
//  SVWebViewController.m
//  Movies
//
//  Created by Sébastien Villar on 25/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVWebViewController.h"
#import "SVMoviesSyncManager.h"

#define kUINavigationBarHeight 44

@interface SVWebViewController ()
@property (strong, readonly) UIWebView* webView;
@end

@implementation SVWebViewController

- (id)init {
	self = [super init];
	if (self) {
		UINavigationBar* navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
		navigationBar.barStyle = UIBarStyleBlack;
		UINavigationItem* navigationItem = [[UINavigationItem alloc] init];
		navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didClickCancel)];
		[navigationBar pushNavigationItem:navigationItem animated:NO];
		[self.view addSubview:navigationBar];
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

- (void)loadUrl:(NSURL*)url {
	if (self.view.subviews.count > 1)
		[[self.view.subviews objectAtIndex:1] removeFromSuperview];		
	UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, kUINavigationBarHeight, self.view.frame.size.width, self.view.frame.size.height - kUINavigationBarHeight)];
	webView.delegate = [SVMoviesSyncManager sharedMoviesSyncManager];
	webView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:webView];
	NSHTTPCookie *cookie;
	NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	for (cookie in [storage cookies]) {
		if (!NSEqualRanges([cookie.domain rangeOfString:@"themoviedb.org"], NSMakeRange(NSNotFound, 0))) {
			[storage deleteCookie:cookie];
		}
	}
	NSURLRequest* urlRequest = [NSURLRequest requestWithURL:url];	
	[webView loadRequest:urlRequest];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)didClickCancel {
	if ([self.delegate respondsToSelector:@selector(webViewControllerDidClickCancelButton:)]) {
		[self.delegate webViewControllerDidClickCancelButton:self];
	}
}

@end
