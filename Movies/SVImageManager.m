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

static SVImageManager* sharedImageManager = nil;

@interface SVImageManager ()
@property (strong, readwrite) NSString* originalImagesPath;
@property (strong, readwrite) NSString* smallImagesPath;
@property (strong, readwrite) SVDatabase* database;
@property (strong, readonly) SVFileManager* fileManager;
@end

@implementation SVImageManager
@synthesize originalImagesPath = _originalImagesPath,
			smallImagesPath = _smallImagesPath,
			fileManager = _fileManager,
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
		_originalImagesPath = [NSString stringWithFormat:@"/Images/OriginalImages"];
		_smallImagesPath = [NSString stringWithFormat:@"/Images/SmallImages"];
		_fileManager = [SVFileManager sharedFileManager];
	}
	return self;
}

- (UIImage*)imageForMovie:(SVMovie*)movie {
	if (!movie.imageFileName) {
		return nil;
	}
	NSString* path = [NSString stringWithFormat:@"%@/%@", self.originalImagesPath, movie.imageFileName];
	NSData* imageData = [self.fileManager dataFromCache:path];
	return [UIImage imageWithData:imageData scale:2.0];
}

- (void)addImage:(UIImage*)image forMovie:(SVMovie*)movie {
	NSString* uuid = [SVAppDelegate uuid];
	movie.imageFileName = uuid;
	NSString* path = [NSString stringWithFormat:@"%@/%@", self.originalImagesPath, movie.imageFileName];
	[self storeImage:image forMovie:movie andPath:path];
}

- (UIImage*)smallImageForMovie:(SVMovie*)movie {
	if (!movie.smallImageFileName) {
		return nil;
	}
	NSString* path = [NSString stringWithFormat:@"%@/%@", self.smallImagesPath, movie.smallImageFileName];
	NSData* imageData = [self.fileManager dataFromCache:path];
	return [UIImage imageWithData:imageData scale:2.0];
}

- (void)addSmallImage:(UIImage*)image forMovie:(SVMovie*)movie {
	NSString* uuid = [SVAppDelegate uuid];
	movie.smallImageFileName = uuid;
	NSString* path = [NSString stringWithFormat:@"%@/%@", self.smallImagesPath, movie.smallImageFileName];
	[self storeImage:image forMovie:movie andPath:path];
}

- (void)storeImage:(UIImage*)image forMovie:(SVMovie*)movie andPath:(NSString*)path {
	BOOL success = [self.fileManager writeDataToCache:UIImagePNGRepresentation(image)
											 withPath:path];
	if (!success) {
		NSLog(@"could't write image to file");
	}
	
	NSString* sqlStatement = nil;
	if ([path rangeOfString:@"OriginalImages"].location != NSNotFound) {
		sqlStatement = [NSString stringWithFormat:@"UPDATE movie SET image_file_name = '%@' WHERE id = %@;", movie.imageFileName, movie.identifier];
	}
	else if ([path rangeOfString:@"SmallImages"].location != NSNotFound) {
 		sqlStatement = [NSString stringWithFormat:@"UPDATE movie SET small_image_file_name = '%@' WHERE id = %@;", movie.smallImageFileName, movie.identifier];
	}
	SVTransaction* transaction = [[SVTransaction alloc] initWithStatements:[[NSArray alloc] initWithObjects:sqlStatement, nil]
																 andSender:self];
	[self.database executeTransaction:transaction];
}

@end
