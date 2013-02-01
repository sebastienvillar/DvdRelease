//
//  SVDatabaseWrapper.h
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVTransaction.h"
#import "SVQuery.h"
@class SVDatabase;

@protocol SVDatabaseSenderProtocol <NSObject>
@optional
- (void)database:(SVDatabase*)database didFinishTransaction:(SVTransaction*)transaction withSuccess:(BOOL)success;
- (void)database:(SVDatabase*)database didFinishQuery:(SVQuery*)query;
@end

@interface SVDatabase : NSObject
+ (SVDatabase*)sharedDatabase;
- (void)executeQuery:(SVQuery*)query;
- (void)executeTransaction:(SVTransaction*)transaction;
- (BOOL)open;
- (void)close;
@end
