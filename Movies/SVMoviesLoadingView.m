//
//  SVMoviesLoadingView.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVMoviesLoadingView.h"

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
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		float width = self.frame.size.width;
		float height = self.frame.size.height;
		_activityIndicatorView.frame = CGRectMake(width/2 - 25, height/2 - 25, 50, 50);
		[self addSubview:_activityIndicatorView];
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
	[super drawRect:rect];
	
	NSString* explanation = @"Please wait while we\nsynchronize your watchlist";
	float height = self.frame.size.height;
	float width = self.frame.size.width;
	[[UIColor colorWithRed:0.7333 green:0.7843 blue:0.7961 alpha:1.0000] set];
	[explanation drawInRect:CGRectMake(0, height/2 - 67, width, 100)
				   withFont:[UIFont systemFontOfSize:15]
			  lineBreakMode:nil
				  alignment:NSTextAlignmentCenter];
}


@end
