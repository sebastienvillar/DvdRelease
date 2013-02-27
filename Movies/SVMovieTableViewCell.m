//
//  SVMovieTableViewCell.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVMovieTableViewCell.h"
#import "SVImageManager.h"

#define kTitleMaxWidth 150
#define kTitleMaxHeight 50
#define kTitleLeft 133
#define kTitleTop 14
#define kReleaseDateHeight 19
#define kReleaseDateLeft 133
#define kImageWidth 120
#define kImageHeight 175
#define kImageLeft 0
#define kOverlayHeight 79
#define kOverlayWidth 120

static NSCache* imagesCache = nil;

@interface SVMovieTableViewCell ()
@property (strong, readonly) SVImageManager* imageManager;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVMovieTableViewCell
@synthesize movie = _movie,
			tableViewParent = _tableViewParent,
			needTopLine = _needTopLine,
			imageManager = _imageManager;

+ (void)initialize {
	[super initialize];
	imagesCache = [[NSCache alloc] init];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		_imageManager = [SVImageManager sharedImageManager];
		_tableViewParent = nil;
		_needTopLine = NO;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	//Background
	[[UIColor blackColor] set];
	[[UIBezierPath bezierPathWithRect:self.bounds] fill];
	int imageTop = 0;
	
	if (self.needTopLine) {
		imageTop = 1;
		CGContextSetLineCap(context, kCGLineCapSquare);
		CGContextSetLineWidth(context, 1.0);
		CGContextSetRGBStrokeColor(context, 0.2431, 0.2431, 0.2431, 1.0);
		CGContextBeginPath(context);
		CGContextMoveToPoint(context, 0, 0);
		CGContextAddLineToPoint(context, self.frame.size.width, 0);
		CGContextClosePath(context);
		CGContextStrokePath(context);
	}
	//Title
	NSString* title = self.movie.title;
	CGSize titleSize = [title sizeWithFont:[UIFont boldSystemFontOfSize:18] constrainedToSize:CGSizeMake(kTitleMaxWidth, kTitleMaxHeight)];
	[[UIColor colorWithRed:0.9333 green:0.9255 blue:0.8353 alpha:1.0000] set];
	[self.movie.title drawInRect:CGRectMake(kTitleLeft, kTitleTop, titleSize.width, titleSize.height)
						withFont:[UIFont boldSystemFontOfSize:18]
				   lineBreakMode:NSLineBreakByTruncatingMiddle];
	
	//Release date
	NSString* releaseText = nil;
	if (self.movie.dvdReleaseDate) {
		NSDate* releaseDate = self.movie.dvdReleaseDate;
		NSDate *today = [NSDate date];
		NSCalendar *calendar = [NSCalendar currentCalendar];
		NSDateComponents *dateComponents = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:today];
		dateComponents.timeZone = [NSTimeZone localTimeZone];
		dateComponents.hour = 0;
		dateComponents.minute = 0;
		dateComponents.second = 0;
		today = [calendar dateFromComponents:dateComponents];
		NSComparisonResult comparisonResult = [releaseDate compare:today];
		if (comparisonResult == NSOrderedAscending || comparisonResult == NSOrderedSame) {
			[[UIColor colorWithRed:0.3216 green:0.8549 blue:0.0000 alpha:1.0000] set];
			releaseText = @"Available";
		}
		else {
			[[UIColor colorWithRed:1.0000 green:0.7294 blue:0.0000 alpha:1.0000] set];
			NSTimeInterval timeInterval = [releaseDate timeIntervalSinceDate:today];
			int numberOfDays = ceil(timeInterval / (3600 * 24));
			if (numberOfDays <= 1)
				releaseText = [NSString stringWithFormat:@"In %d day", numberOfDays];
			else
				releaseText = [NSString stringWithFormat:@"In %d days", numberOfDays];
		}
	}
	else {
		[[UIColor colorWithRed:0.9072 green:0.2488 blue:0.2532 alpha:1.0000] set];
		releaseText = @"Unknown";
	}
	
	CGSize releaseDateSize = [releaseText sizeWithFont:[UIFont boldSystemFontOfSize:12]];
	CGRect releaseDateRect = CGRectMake(kTitleLeft, kTitleTop + titleSize.height + 5, releaseDateSize.width + 12, kReleaseDateHeight);
	[[UIBezierPath bezierPathWithRoundedRect:releaseDateRect cornerRadius:kReleaseDateHeight/2] fill];
	
	[[UIColor blackColor] set];
	[releaseText drawInRect:CGRectMake(kTitleLeft + kReleaseDateHeight/2, kTitleTop + titleSize.height + 5 + 3, 80, kReleaseDateHeight)
				   withFont:[UIFont boldSystemFontOfSize:11]
			  lineBreakMode:NSLineBreakByTruncatingMiddle];
	
	//Image
	UIImage* image = [imagesCache objectForKey:self.movie.imageUrl];
	CGRect imageRect = CGRectMake(kImageLeft, imageTop, kImageWidth, kImageHeight);
	if (image) {
		[image drawInRect:imageRect];
		CGRect overlayRect = CGRectMake(kImageLeft, 0, kOverlayWidth, kOverlayHeight);
		UIImage* overlayImage = [UIImage imageNamed:@"dvd_overlay.png"];
		[overlayImage drawInRect:overlayRect];
	}
	else {
		UIImage* notCoverImage = [UIImage imageNamed:@"no_cover.png"];
		[notCoverImage drawInRect:imageRect];
		[self cacheImage];
	}
}

- (void)cacheImage {
	SVMovie* movie = self.movie;
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        UIImage *image = [self.imageManager imageForMovie:movie];
		if (image) {
			[imagesCache setObject:image forKey:movie.imageUrl];
		}
		else {
			NSError *error;
			NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:movie.imageUrl] returningResponse:nil error:&error];
			if (!error) {
				image = [UIImage imageWithData:data];
				[self.imageManager addImage:image forMovie:movie];
			}
			else {
				return;
			}
			image = [self generateSmallImage:image];
			[imagesCache setObject:image forKey:movie.imageUrl];
			[self.imageManager addImage:image forMovie:movie];
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			NSIndexPath *indexPath = [self.tableViewParent indexPathForCell:self];
            if (indexPath) {
                [self.tableViewParent reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
		});
	});
}

- (UIImage*)generateSmallImage:(UIImage*)image {
	float width = image.size.width;
	float height = image.size.height;
	float xOffset = 0;
	float yOffset = 0;
	float ratio = 0;
	float finalWidth = kImageWidth;
	float finalHeight = kImageHeight;
	if (width / kImageWidth <= height / kImageHeight) {
		ratio = width / kImageWidth;
		finalHeight = height / ratio;
		yOffset = -(finalHeight - kImageHeight) / 2;
	}
	else {
		ratio = height / kImageHeight;
		finalWidth = width / ratio;
		xOffset = -(finalWidth - kImageWidth) / 2;
	}
	
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(kImageWidth, kImageHeight), NO, 0.0);
	[image drawInRect:CGRectMake(xOffset, yOffset, finalWidth, finalHeight)];
	UIImage* smallImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return smallImage;
}

@end
