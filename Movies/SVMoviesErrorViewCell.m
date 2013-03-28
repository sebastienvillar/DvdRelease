//
//  SVMoviesTopView.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVMoviesErrorViewCell.h"

#define kTriangleTop 3
#define kExplanationTop 5
#define kExplanationHeight 14

@interface SVMoviesErrorViewCell ()
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVMoviesErrorViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
	//Background
	//[[UIColor blackColor] set];
	[[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2] set];
    [[UIBezierPath bezierPathWithRect:self.bounds] fill];
	
	//Image
	UIImage* errorImage =  [UIImage imageNamed:@"error_icon.png"];
	[errorImage drawInRect:CGRectMake(self.frame.size.width / 2 - errorImage.size.width / 2, kTriangleTop, errorImage.size.width, errorImage.size.height)];

	//Explanation text
	[[UIColor colorWithRed:0.7961 green:0.7961 blue:0.7961 alpha:1.0000] set];
	NSString* explanation = @"Sorry, we couldn't synchronize your watchlist";
	[explanation drawInRect:CGRectMake(0, errorImage.size.height + kExplanationTop, self.frame.size.width, kExplanationHeight)
				   withFont:[UIFont boldSystemFontOfSize:12]
			  lineBreakMode:NSLineBreakByTruncatingMiddle
				  alignment:NSTextAlignmentCenter];
}

@end
