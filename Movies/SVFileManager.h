//
//  SVFileManager.h
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVFileManager : NSObject
+ (SVFileManager*)sharedFileManager;
- (BOOL)writeDataToCache:(NSData*)data withPath:(NSString*)path;
- (NSData*)dataFromCache:(NSString*)path;

@end
