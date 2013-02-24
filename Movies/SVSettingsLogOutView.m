//
//  SVSettingsConnectedView.m
//  Movies
//
//  Created by Sébastien Villar on 21/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVSettingsLogOutView.h"

static const int  kHomeButtonBottom = 7;
static const int kHomeButtonRight = 7;
static const int kThanksBottom = 17;
static const int kThanksLeft = 23;

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVSettingsLogOutView
@synthesize logoutButton = _logoutButton,
			homeButton = _homeButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		_logoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
		UIImage* buttonImage = [[UIImage imageNamed:@"button.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 40, 0, 40) resizingMode:UIImageResizingModeTile];
		[_logoutButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
		[_logoutButton setBackgroundImage:buttonImage forState:UIControlStateHighlighted];
		
		[self addSubview:_logoutButton];
		float buttonWidth = 130;
		float buttonHeight = buttonImage.size.height;
		_logoutButton.frame = CGRectMake(self.frame.size.width/2 - buttonWidth/2, self.frame.size.height/2 - buttonHeight/2, buttonWidth, buttonHeight);
		[_logoutButton setTitle:@"Log out" forState:UIControlStateNormal];
		[_logoutButton setTitle:@"Log out" forState:UIControlStateHighlighted];
		[_logoutButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[_logoutButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
		_logoutButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
		[_logoutButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[_logoutButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
		_logoutButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
		
		_homeButton = [UIButton buttonWithType:UIButtonTypeCustom];
		UIImage* homeButtonImage = [UIImage imageNamed:@"home_button.png"];
		[_homeButton setBackgroundImage:homeButtonImage forState:UIControlStateNormal];
		[_homeButton setBackgroundImage:homeButtonImage forState:UIControlStateHighlighted];
		_homeButton.frame = CGRectMake(self.frame.size.width - homeButtonImage.size.width - kHomeButtonRight, self.frame.size.height - homeButtonImage.size.height - kHomeButtonRight, homeButtonImage.size.width, homeButtonImage.size.height);
		self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
		[self addSubview:_homeButton];
    }
	return self;
}


- (void)drawRect:(CGRect)rect
{
	NSString* thanks = @"Thanks to RottenTomatoes";
	
	float width = self.frame.size.width;
	[[UIColor colorWithRed:0.4667 green:0.4902 blue:0.4902 alpha:1.0000] set];
	[thanks drawInRect:CGRectMake(kThanksLeft, self.frame.size.height - kThanksBottom - 20, width - 2 * kThanksLeft, 20)
				   withFont:[UIFont systemFontOfSize:14]
			  lineBreakMode:nil
				  alignment:NSTextAlignmentCenter];

}



@end
