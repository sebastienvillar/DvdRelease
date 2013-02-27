//
//  SVSettingsView.m
//  Movies
//
//  Created by Sébastien Villar on 1/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVSettingsSignInView.h"

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVSettingsSignInView
@synthesize signInButton = _signInButton,
	activityIndicatorView = _activityIndicatorView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		_activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		[self addSubview:_activityIndicatorView];
		_signInButton = [UIButton buttonWithType:UIButtonTypeCustom];
		UIImage* buttonImage = [[UIImage imageNamed:@"button.png"]
								resizableImageWithCapInsets:UIEdgeInsetsMake(0, 40, 0, 40)
								resizingMode:UIImageResizingModeTile];
		UIImage* activeButtonImage = [[UIImage imageNamed:@"button_active.png"]
									  resizableImageWithCapInsets:UIEdgeInsetsMake(0, 40, 0, 40)
									  resizingMode:UIImageResizingModeTile];
		[_signInButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
		[_signInButton setBackgroundImage:activeButtonImage forState:UIControlStateHighlighted];
		[_signInButton setBackgroundImage:buttonImage forState:UIControlStateDisabled];

		[self addSubview:_signInButton];
		float buttonWidth = 130;
		float buttonHeight = buttonImage.size.height;
		_signInButton.frame = CGRectMake(self.frame.size.width/2 - buttonWidth/2, self.frame.size.height/2 - buttonHeight/2, buttonWidth, buttonHeight);
		[_signInButton setTitle:@"Sign in" forState:UIControlStateNormal];
		[_signInButton setTitle:@"Sign in" forState:UIControlStateHighlighted];
		[_signInButton setTitle:@"Sign in" forState:UIControlStateDisabled];
		[_signInButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[_signInButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
		[_signInButton setTitleColor:[UIColor blackColor] forState:UIControlStateDisabled];
		_signInButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
		[_signInButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[_signInButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
		[_signInButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateDisabled];
		_signInButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
    }
	return self;
}


- (void)drawRect:(CGRect)rect
{
	[super drawRect:rect];
	
	NSString* explanation = nil;
	int bottomOffset = 0;
	switch (self.state) {
		case SVSettingsSignInViewNormalState: {
			explanation = @"This application uses TMDB to\nsynchronize your movie watchlist and\ndisplay DVD release dates";
			bottomOffset = 70;
			break;
		}
		case SVSettingsSignInViewErrorState: {
			explanation = @"An error occured while connecting\nto TMDB. Please try again";
			bottomOffset = 50;
			break;
		}
		case SVSettingsSignInViewUserDeniedState: {
			explanation = @"You must accept the token\nso that we can access your watchlist";
			bottomOffset = 50;
			break;
		}
		default:
			break;
	}
	
	float width = self.frame.size.width;
	self.activityIndicatorView.frame = CGRectMake(width/2 - 25, self.signInButton.frame.origin.y - bottomOffset - 50 - 5, 50, 50);
	
	[[UIColor colorWithRed:0.7961 green:0.7922 blue:0.7490 alpha:1.0000] set];
	[explanation drawInRect:CGRectMake(0, self.signInButton.frame.origin.y - bottomOffset, width, 100)
				   withFont:[UIFont systemFontOfSize:15]
			  lineBreakMode:nil
				  alignment:NSTextAlignmentCenter];

}

@end
