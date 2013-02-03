//
//  SVMovie.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVMovie.h"

@implementation SVMovie
@synthesize	uuid = _uuid,
			identifier = _identifier,
			title = _title,
			dvdReleaseDate = _dvdReleaseDate,
			yearOfRelease = _yearOfRelease,
			imageUrl = _imageUrl,
			imageFileName = _imageFileName,
			smallImageFileName = _smallImageFileName;

- (NSString*)description {
	NSString* description = [NSString stringWithFormat:@"Movie: %@\nTitle: %@\nDvdReleaseDate: %@\nYearOfRelease: %@\nImageUrl: %@\nImageFileName: %@\nSmallImageFileName\n: %@\n",
							 self.identifier,
							 self.title,
							 self.dvdReleaseDate,
							 self.yearOfRelease,
							 self.imageUrl,
							 self.imageFileName,
							 self.smallImageFileName];
	return description;
}

- (BOOL)isEqual:(id)object {
	return ([object isKindOfClass:[SVMovie class]] && [self.title isEqual:((SVMovie*)object).title]);
}

- (NSUInteger)hash {
	return [self.title hash];
}
@end
