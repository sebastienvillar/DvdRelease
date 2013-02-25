//
//  SVImageManager.h
//  Movies
//
//  Created by Sébastien Villar on 16/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVDatabase.h"
#import "SVMovie.h"

@interface SVImageManager : NSObject 
+ (SVImageManager*)sharedImageManager;
- (UIImage*)imageForMovie:(SVMovie*)movie;
- (void)addImage:(UIImage*)image forMovie:(SVMovie*)movie;
@end
