//
//  SVWebViewController.h
//  Movies
//
//  Created by Sébastien Villar on 25/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SVWebViewController;

@protocol SVWebViewControllerDelegate <NSObject>
- (void)webViewControllerDidClickCancelButton:(SVWebViewController*)webViewController;
@end

@interface SVWebViewController : UIViewController
@property (weak, readwrite) id delegate;
- (void)loadUrl:(NSURL*)url;
@end
