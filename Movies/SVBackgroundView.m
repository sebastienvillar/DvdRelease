//
//  SVBackgroundView.m
//  Movies
//
//  Created by Sébastien Villar on 27/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVBackgroundView.h"

@implementation SVBackgroundView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
	[[UIColor blackColor] set];
	[[UIBezierPath bezierPathWithRect:self.bounds] fill];
	UIImage* backgroundImage = [UIImage imageNamed:@"background.png"];
	CGRect imageRect = CGRectMake(0, 0, backgroundImage.size.width, backgroundImage.size.height);
	[backgroundImage drawInRect:imageRect blendMode:kCGBlendModeNormal alpha:0.2];
}

@end
