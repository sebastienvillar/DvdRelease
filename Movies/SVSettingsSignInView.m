//
//  SVSettingsView.m
//  Movies
//
//  Created by Sébastien Villar on 1/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVSettingsSignInView.h"
#import "SVBackgroundView.h"

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVSettingsSignInView
@synthesize signInButton = _signInButton,
			explanationLabel = _explanationLabel,
	activityIndicatorView = _activityIndicatorView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		SVBackgroundView* backgroundView = [[SVBackgroundView alloc] initWithFrame:frame];
		backgroundView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
		[self addSubview:backgroundView];
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
		_signInButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
		[self addSubview:_signInButton];
		float buttonWidth = 130;
		float buttonHeight = buttonImage.size.height;
		_signInButton.frame = CGRectMake(self.frame.size.width/2 - buttonWidth/2, frame.size.height/2 - buttonHeight/2, buttonWidth, buttonHeight);
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
		_explanationLabel = [[UILabel alloc] init];
		_explanationLabel.backgroundColor = [UIColor clearColor];
		_explanationLabel.textColor = [UIColor colorWithRed:0.7961 green:0.7922 blue:0.7490 alpha:1.0000];
		_explanationLabel.font = [UIFont systemFontOfSize:15];
		_explanationLabel.textAlignment = NSTextAlignmentCenter;
		_explanationLabel.numberOfLines = 3;
		_explanationLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
		[self addSubview:_explanationLabel];
		_activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		_activityIndicatorView.frame = CGRectMake(frame.size.width/2 - 25, 136, 50, 50);
		_activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
		[self addSubview:_activityIndicatorView];
    }
	return self;
}

- (void)setTextLabel:(NSString*)labelText {
	int nbOfLineBreak = [labelText componentsSeparatedByString:@"\n"].count;
	self.explanationLabel.numberOfLines = nbOfLineBreak;
	self.explanationLabel.text = labelText;
	self.explanationLabel.frame = CGRectMake(0, self.frame.size.height/2 - 29 - nbOfLineBreak * 20, self.frame.size.width, nbOfLineBreak * 60 / 3);
	self.activityIndicatorView.frame = CGRectMake(self.frame.size.width/2 - 25, self.frame.size.height/2 - 75 - nbOfLineBreak * 20, 50, 50);
}

@end
