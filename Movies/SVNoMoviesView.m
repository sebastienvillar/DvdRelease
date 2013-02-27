//
//  SVNoMoviesView.m
//  Movies
//
//  Created by Sébastien Villar on 27/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVNoMoviesView.h"

@implementation SVNoMoviesView

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
	UIImage* backgroundImage = [UIImage imageNamed:@"background.png"];
	CGRect imageRect = CGRectMake(0, 0, backgroundImage.size.width, backgroundImage.size.height);
	[backgroundImage drawInRect:imageRect blendMode:kCGBlendModeNormal alpha:0.2];
	
	NSString* explanation = @"You have no movie in your watchlist\nVisit TMDB and fill it in!";
	float height = self.frame.size.height;
	float width = self.frame.size.width;
	[[UIColor colorWithRed:0.7333 green:0.7843 blue:0.7961 alpha:1.0000] set];
	[explanation drawInRect:CGRectMake(0, height/2 - 40, width, 100)
				   withFont:[UIFont systemFontOfSize:15]
			  lineBreakMode:nil
				  alignment:NSTextAlignmentCenter];
}

@end
