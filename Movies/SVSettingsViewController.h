//
//  SVSettingsViewController.h
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SVSettingsViewController;

@protocol SVSettingsViewControllerDelegate <NSObject>
- (void)settingsViewControllerDidClickHomeButton:(SVSettingsViewController*)settingsViewController;
- (void)settingsViewControllerDidClickSignInButton:(SVSettingsViewController*)settingsViewController;
- (void)settingsViewControllerDidClickLogOutButton:(SVSettingsViewController*)settingsViewController;
@end

@interface SVSettingsViewController : UIViewController
@property (weak, readwrite) id delegate;
- (void)loadWebViewWithUrl:(NSURL*)url;
- (void)loadSignInView;
- (void)loadLogOutView;
@end
