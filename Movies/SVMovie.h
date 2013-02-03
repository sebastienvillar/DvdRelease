//
//  SVMovie.h
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVMovie : NSObject
@property (readwrite) NSString* uuid;
@property (strong, readwrite) NSNumber* identifier;
@property (strong, readwrite) NSString *title;
@property (strong, readwrite) NSDate *dvdReleaseDate;
@property (strong, readwrite) NSNumber *yearOfRelease;
@property (strong, readwrite) NSURL *imageUrl;
@property (strong, readwrite) NSString* imageFileName;
@property (strong, readwrite) NSString* smallImageFileName;
@end
