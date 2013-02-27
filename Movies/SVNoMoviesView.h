//
//  SVNoMoviesView.h
//  Movies
//
//  Created by Sébastien Villar on 27/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVBackgroundView.h"

@interface SVNoMoviesView : SVBackgroundView
@property (strong, readonly) UIActivityIndicatorView* activityIndicatorView;
@property (strong, readonly) UIButton* refreshButton;
@end
