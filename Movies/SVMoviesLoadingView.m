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
    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetRGBFillColor(context, 0, 0, 0, 1);
	CGContextFillRect(context, self.bounds);
	
	NSString* explanation = @"Please wait while we \nsynchronize your watchlist";
	float height = self.frame.size.height;
	float width = self.frame.size.width;
	CGContextSetRGBFillColor(context, 203, 203, 203, 1);
	[explanation drawInRect:CGRectMake(20, height/2 - 70, width - 40, 100)
				   withFont:[UIFont systemFontOfSize:15]
			  lineBreakMode:nil
				  alignment:NSTextAlignmentCenter];
}


@end
