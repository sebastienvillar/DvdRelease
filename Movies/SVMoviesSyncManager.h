//
//  SVMoviesSyncManager.h
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVDatabase.h"
@class SVMoviesSyncManager;

@protocol SVMovieSyncManagerDelegate <NSObject>
- (void)movieSyncManagerDidConnect:(SVMoviesSyncManager*)aManager;
- (void)movieSyncManagerConnectionDidFail:(SVMoviesSyncManager*)aManager;
- (void)movieSyncManagerNeedsApproval:(SVMoviesSyncManager*)aManager withUrl:(NSURL*)aUrl;
- (void)movieSyncManagerDeniedConnection:(SVMoviesSyncManager*)aManager;
- (void)movieSyncManager:(SVMoviesSyncManager*)aManager didFetchWatchList:(NSArray*)movies;
- (void)movieSyncManagerDidFailToSync:(SVMoviesSyncManager*)aManager;
@end

@interface SVMoviesSyncManager : NSObject <SVDatabaseSenderProtocol>
@property (strong, readwrite) NSString* service;
@property (weak, readwrite) NSObject<SVMovieSyncManagerDelegate>* delegate;

+ (SVMoviesSyncManager*)sharedMoviesSyncManager;
- (void)connect;
@end
