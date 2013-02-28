//
//  SVFileManager.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVFileManager.h"

static SVFileManager* sharedFileManager = nil;

@interface SVFileManager ()
@property (strong, readonly) NSString* cachePath;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVFileManager
@synthesize cachePath = _cachePath;

+ (SVFileManager*)sharedFileManager {
	if (!sharedFileManager) {
		sharedFileManager = [[SVFileManager alloc] init];
	}
	return sharedFileManager;
}

- (id)init {
	self = [super init];
	if (self) {
		_cachePath = [self cacheDirectoryPath];
	}
	return self;
}

- (BOOL)writeDataToCache:(NSData*)data withPath:(NSString*)path {
	if (self.cachePath) {
		NSString* lastDirectoryPath = [self lastDirectoryPath:path];
		if (!lastDirectoryPath) {
			return NO;
		}
		NSString* fullDirectoryPath = [self.cachePath stringByAppendingString:lastDirectoryPath];
		NSFileManager* fileManager = [NSFileManager defaultManager];
		if (![fileManager fileExistsAtPath:fullDirectoryPath]) {
			NSError* error = nil;
			[fileManager createDirectoryAtPath:fullDirectoryPath
				   withIntermediateDirectories:YES
									attributes:nil
										 error:&error];
			if (error) {
				return NO;
			}
		}
		NSString* fullPath = [self.cachePath stringByAppendingString:path];
		return [data writeToFile:fullPath atomically:YES];
	}
	return NO;
}

- (NSData*)dataFromCache:(NSString *)path {
	NSString* fullPath = [self.cachePath stringByAppendingString:path];
	return [NSData dataWithContentsOfFile:fullPath];
}
							
- (NSString*)lastDirectoryPath:(NSString*)path {
	NSError* error = nil;
	NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"(.*/)" options:NSRegularExpressionAnchorsMatchLines error:&error];
	if (error) {
		return nil;
	}
	NSArray* matches = [regex matchesInString:path options:0 range:NSMakeRange(0, path.length)];
	NSTextCheckingResult* match = [matches objectAtIndex:0];
	return [path substringWithRange:match.range];
}

- (NSString*)cacheDirectoryPath {
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString* filePath = [paths objectAtIndex:0];
	NSFileManager* fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:filePath]) {
	    NSError *error;
		BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:filePath
												 withIntermediateDirectories:YES
																  attributes:nil
																	   error:&error];
		if (!success) {
			return nil;
		}
	}
	return filePath;
}


@end
