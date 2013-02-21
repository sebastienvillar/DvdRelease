//
//  SVSettingsViewController.h
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SVSettingsViewController : UIViewController
- (void)loadWebViewWithUrl:(NSURL*)url;
- (void)loadDisconnectedSettingsView;
- (void)loadConnectedSettingsView;
@end
