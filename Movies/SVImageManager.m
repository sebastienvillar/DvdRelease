//
//  SVImageManager.m
//  Movies
//
//  Created by Sébastien Villar on 16/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVImageManager.h"
#import "SVAppDelegate.h"
#import "SVFileManager.h"

#define kImagePath @"/Images/"

static SVImageManager* sharedImageManager = nil;

@interface SVImageManager ()
@property (strong, readwrite) SVDatabase* database;
@property (strong, readonly) SVFileManager* fileManager;
@end

@implementation SVImageManager
@synthesize fileManager = _fileManager,
			database = _database;

+ (SVImageManager*)sharedImageManager {
	if (!sharedImageManager) {
		sharedImageManager = [[SVImageManager alloc] init];
	}
	return sharedImageManager;
}

- (id)init {
	self = [super init];
	if (self) {
		_database = [SVDatabase sharedDatabase];
		_fileManager = [SVFileManager sharedFileManager];
	}
	return self;
}

- (UIImage*)imageForMovie:(SVMovie*)movie {
	if (!movie.imageFileName) {
		return nil;
	}
	NSString* path = [NSString stringWithFormat:@"%@/%@", kImagePath, movie.imageFileName];
	NSData* imageData = [self.fileManager dataFromCache:path];
	return [UIImage imageWithData:imageData scale:2.0];
}

- (void)addImage:(UIImage*)image forMovie:(SVMovie*)movie {
	NSString* uuid = [SVAppDelegate uuid];
	movie.imageFileName = uuid;
	NSString* path = [NSString stringWithFormat:@"%@/%@", kImagePath, movie.imageFileName];
	BOOL success = [self.fileManager writeDataToCache:UIImagePNGRepresentation(image)
											 withPath:path];
	if (!success) {
		NSLog(@"could't write image to file");
	}
	NSString* sqlStatement = [NSString stringWithFormat:@"UPDATE movie SET image_file_name = '%@' WHERE id = %@;", movie.imageFileName, movie.identifier];
	SVTransaction* transaction = [[SVTransaction alloc] initWithStatements:[[NSArray alloc] initWithObjects:sqlStatement, nil]
																 andSender:self];
	[self.database executeTransaction:transaction];
}

@end
