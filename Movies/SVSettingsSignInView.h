//
//  SVSettingsSignInView.h
//  Movies
//
//  Created by Sébastien Villar on 1/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVBackgroundView.h"


@interface SVSettingsSignInView : SVBackgroundView
enum {
	SVSettingsSignInViewNormalState = 0,
	SVSettingsSignInViewErrorState = 1,
	SVSettingsSignInViewUserDeniedState = 2,
};
typedef int SVSettingsSignInViewState;
@property (strong, readonly) UIButton* signInButton;
@property (readwrite) SVSettingsSignInViewState state;
@property (strong, readwrite) UIActivityIndicatorView* activityIndicatorView;
@end
