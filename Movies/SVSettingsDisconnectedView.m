//
//  SVSettingsView.m
//  Movies
//
//  Created by Sébastien Villar on 1/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVSettingsDisconnectedView.h"

@implementation SVSettingsDisconnectedView
@synthesize signInButton = _signInButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		_signInButton = [UIButton buttonWithType:UIButtonTypeCustom];
		UIImage* buttonImage = [[UIImage imageNamed:@"button.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 40, 0, 40) resizingMode:UIImageResizingModeTile];
		[_signInButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
		[_signInButton setBackgroundImage:buttonImage forState:UIControlStateHighlighted];

		[self addSubview:_signInButton];
		float buttonWidth = 130;
		float buttonHeight = buttonImage.size.height;
		_signInButton.frame = CGRectMake(self.frame.size.width/2 - buttonWidth/2, self.frame.size.height/2 - 23, buttonWidth, buttonHeight);
		[_signInButton setTitle:@"Sign in" forState:UIControlStateNormal];
		[_signInButton setTitle:@"Sign in" forState:UIControlStateHighlighted];
		[_signInButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[_signInButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
		_signInButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
		[_signInButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[_signInButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
		_signInButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
    }
	return self;
}


- (void)drawRect:(CGRect)rect
{
	//Background
	[[UIColor blackColor] set];
	[[UIBezierPath bezierPathWithRect:self.bounds] fill];
	UIImage* backgroundImage = [UIImage imageNamed:@"settings_background-568.png"];
	CGRect imageRect = CGRectMake(0, 0, backgroundImage.size.width, backgroundImage.size.height);
	[backgroundImage drawInRect:imageRect blendMode:kCGBlendModeNormal alpha:0.2];
	
	NSString* explanation = @"This application uses TMDB to\n synchronize your movie watchlist and\n display DVD release dates";
	float height = self.frame.size.height;
	float width = self.frame.size.width;
	[[UIColor colorWithRed:0.9333 green:0.9255 blue:0.8353 alpha:1.0000] set];
	[explanation drawInRect:CGRectMake(20, height/2 - 80, width - 40, 100)
				   withFont:[UIFont systemFontOfSize:15]
			  lineBreakMode:nil
				  alignment:NSTextAlignmentCenter];

}

@end
