//
//  SVNoMoviesView.m
//  Movies
//
//  Created by Sébastien Villar on 27/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVNoMoviesView.h"
#import "SVBackgroundView.h"


@implementation SVNoMoviesView
@synthesize activityIndicatorView = _activityIndicatorView,
			refreshButton = _refreshButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		SVBackgroundView* backgroundView = [[SVBackgroundView alloc] initWithFrame:frame];
		[self addSubview:backgroundView];
		_activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		CGRect indicatorRect = _activityIndicatorView.frame;
		float width = frame.size.width;
		float height = frame.size.height;
		indicatorRect.origin.x = width/2 - 37/2;
		indicatorRect.origin.y = height/2 - 120;
		_activityIndicatorView.frame = indicatorRect;
		[self addSubview:_activityIndicatorView];
		_refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
		UIImage* buttonImage = [[UIImage imageNamed:@"button.png"]
								resizableImageWithCapInsets:UIEdgeInsetsMake(0, 40, 0, 40)
								resizingMode:UIImageResizingModeTile];
		UIImage* activeButtonImage = [[UIImage imageNamed:@"button_active.png"]
									  resizableImageWithCapInsets:UIEdgeInsetsMake(0, 40, 0, 40)
									  resizingMode:UIImageResizingModeTile];
		[_refreshButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
		[_refreshButton setBackgroundImage:activeButtonImage forState:UIControlStateHighlighted];
		
		[self addSubview:_refreshButton];
		float buttonWidth = 130;
		float buttonHeight = buttonImage.size.height;
		_refreshButton.frame = CGRectMake(self.frame.size.width/2 - buttonWidth/2, frame.size.height/2 - buttonHeight/2, buttonWidth, buttonHeight);
		[_refreshButton setTitle:@"Refresh" forState:UIControlStateNormal];
		[_refreshButton setTitle:@"Refresh" forState:UIControlStateHighlighted];
		[_refreshButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[_refreshButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
		_refreshButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
		[_refreshButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[_refreshButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
		_refreshButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
		UILabel* explanationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, _refreshButton.frame.origin.y - 49, frame.size.width, 40)];
		explanationLabel.backgroundColor = [UIColor clearColor];
		explanationLabel.text = @"Your watchlist is empty\nVisit TMDB and add some movies !";
		explanationLabel.textColor = [UIColor colorWithRed:0.7961 green:0.7922 blue:0.7490 alpha:1.0000];
		explanationLabel.font = [UIFont systemFontOfSize:15];
		explanationLabel.textAlignment = NSTextAlignmentCenter;
		explanationLabel.numberOfLines = 2;
		[self addSubview:explanationLabel];
    }
    return self;
}

@end
