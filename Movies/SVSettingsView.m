//
//  SVSettingsView.m
//  Movies
//
//  Created by Sébastien Villar on 1/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVSettingsView.h"

@implementation SVSettingsView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
    NSString* string = @"Settings";
	[[UIColor blackColor] set];
	[string drawAtPoint:CGPointMake(110, 250) withFont:[UIFont systemFontOfSize:24]];
}

@end
