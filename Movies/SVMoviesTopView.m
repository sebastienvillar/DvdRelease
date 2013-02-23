//
//  SVMoviesTopView.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVMoviesTopView.h"

static const int triangleTop = 5;
static const int explanationTop = triangleTop + 3;
static const int explanationHeight = 14;

@interface SVMoviesTopView ()
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVMoviesTopView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
	//Background
	[[UIColor blackColor] set];
    [[UIBezierPath bezierPathWithRect:self.bounds] fill];
	
	//Image
	UIImage* errorImage =  [UIImage imageNamed:@"error_icon.png"];
	[errorImage drawInRect:CGRectMake(self.frame.size.width / 2 - errorImage.size.width / 2, triangleTop, errorImage.size.width, errorImage.size.height)];

	//Explanation text
	[[UIColor colorWithRed:0.7961 green:0.7961 blue:0.7961 alpha:1.0000] set];
	NSString* explanation = @"Sorry, we couldn't synchronize your watchlist";
	[explanation drawInRect:CGRectMake(0, errorImage.size.height + explanationTop, self.frame.size.width, explanationHeight)
				   withFont:[UIFont boldSystemFontOfSize:12]
			  lineBreakMode:NSLineBreakByTruncatingMiddle
				  alignment:NSTextAlignmentCenter];
}

@end
