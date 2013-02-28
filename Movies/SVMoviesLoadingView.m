//
//  SVMoviesLoadingView.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVMoviesLoadingView.h"
#import "SVBackgroundView.h"

@interface SVMoviesLoadingView ()
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVMoviesLoadingView
@synthesize activityIndicatorView = _activityIndicatorView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		SVBackgroundView* backgroundView = [[SVBackgroundView alloc] initWithFrame:frame];
		[self addSubview:backgroundView];
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		float width = self.frame.size.width;
		float height = self.frame.size.height;
		UILabel* explanationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.height/2 - 69, frame.size.width, 40)];
		explanationLabel.backgroundColor = [UIColor clearColor];
		explanationLabel.text = @"Please wait while we\nsynchronize your watchlist";
		explanationLabel.textColor = [UIColor colorWithRed:0.7333 green:0.7843 blue:0.7961 alpha:1.0000];
		explanationLabel.font = [UIFont systemFontOfSize:15];
		explanationLabel.textAlignment = NSTextAlignmentCenter;
		explanationLabel.numberOfLines = 2;
		[self addSubview:explanationLabel];
		_activityIndicatorView.frame = CGRectMake(width/2 - 25, height/2 - 25, 50, 50);
		[self addSubview:_activityIndicatorView];
    }
    return self;
}

@end
