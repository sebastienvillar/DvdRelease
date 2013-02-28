//
//  SVSettingsConnectedView.m
//  Movies
//
//  Created by Sébastien Villar on 21/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVSettingsLogOutView.h"

#define kHomeButtonBottom 7
#define kHomeButtonRight 7
#define kThanksBottom 37

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
		_logoutButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
										 UIViewAutoresizingFlexibleBottomMargin;
		UIImage* buttonImage = [[UIImage imageNamed:@"button.png"]
								resizableImageWithCapInsets:UIEdgeInsetsMake(0, 40, 0, 40)
												resizingMode:UIImageResizingModeTile];
		UIImage* activeButtonImage = [[UIImage imageNamed:@"button_active.png"]
								resizableImageWithCapInsets:UIEdgeInsetsMake(0, 40, 0, 40)
								resizingMode:UIImageResizingModeTile];
		[_logoutButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
		[_logoutButton setBackgroundImage:activeButtonImage forState:UIControlStateHighlighted];
		
		[self addSubview:_logoutButton];
		float buttonWidth = 130;
		float buttonHeight = buttonImage.size.height;
		_logoutButton.frame = CGRectMake(self.frame.size.width/2 - buttonWidth/2, self.frame.size.height/2 - buttonHeight/2, buttonWidth, buttonHeight);
		[_logoutButton setTitle:@"Sign out" forState:UIControlStateNormal];
		[_logoutButton setTitle:@"Sign out" forState:UIControlStateHighlighted];
		[_logoutButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[_logoutButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
		_logoutButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
		[_logoutButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[_logoutButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
		_logoutButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
		
		_homeButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_homeButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
		UIImage* homeButtonImage = [UIImage imageNamed:@"home_button.png"];
		UIImage* activeHomeButtonImage = [UIImage imageNamed:@"home_button_active.png"];
		[_homeButton setBackgroundImage:homeButtonImage forState:UIControlStateNormal];
		[_homeButton setBackgroundImage:activeHomeButtonImage forState:UIControlStateHighlighted];
		_homeButton.frame = CGRectMake(self.frame.size.width - homeButtonImage.size.width - kHomeButtonRight, frame.size.height - homeButtonImage.size.height - kHomeButtonRight, homeButtonImage.size.width, homeButtonImage.size.height);
		self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
		[self addSubview:_homeButton];
		UILabel* explanationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, _logoutButton.frame.origin.y - 30, frame.size.width, 20)];
		explanationLabel.backgroundColor = [UIColor clearColor];
		explanationLabel.text = @"You are currently signed in to TMDB";
		explanationLabel.textColor = [UIColor colorWithRed:0.7961 green:0.7922 blue:0.7490 alpha:1.0000];
		explanationLabel.font = [UIFont systemFontOfSize:15];
		explanationLabel.textAlignment = NSTextAlignmentCenter;
		explanationLabel.numberOfLines = 1;
		[self addSubview:explanationLabel];
		UILabel* thanksLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.height - kThanksBottom, frame.size.width, 20)];
		thanksLabel.backgroundColor = [UIColor clearColor];
		thanksLabel.text = @"Thanks to RottenTomatoes";
		thanksLabel.textColor = [UIColor colorWithRed:0.4667 green:0.4902 blue:0.4902 alpha:1.0000];
		thanksLabel.font = [UIFont systemFontOfSize:13];
		thanksLabel.textAlignment = NSTextAlignmentCenter;
		thanksLabel.numberOfLines = 2;
		[self addSubview:thanksLabel];
    }
	return self;
}

@end
