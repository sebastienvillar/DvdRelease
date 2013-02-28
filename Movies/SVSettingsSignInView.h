//
//  SVSettingsSignInView.h
//  Movies
//
//  Created by Sébastien Villar on 1/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SVSettingsSignInView : UIView
@property (strong, readonly) UIButton* signInButton;
@property (strong, readwrite) UIActivityIndicatorView* activityIndicatorView;
@property (strong, readonly) UILabel* explanationLabel;
- (void)setTextLabel:(NSString*)labelString;
@end
