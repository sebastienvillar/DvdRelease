//
//  SVMoviesLoadingView.h
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVBackgroundView.h"

@interface SVMoviesLoadingView : SVBackgroundView
@property (strong, readonly) UIActivityIndicatorView* activityIndicatorView;
@end
