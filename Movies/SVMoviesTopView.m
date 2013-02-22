//
//  SVMoviesTopView.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVMoviesTopView.h"

@implementation SVMoviesTopView

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
	[[UIColor yellowColor] set];
    [[UIBezierPath bezierPathWithRect:self.bounds] fill];
}

@end
