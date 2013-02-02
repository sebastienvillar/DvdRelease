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

@protocol SVMoviesSyncManagerDelegate <NSObject>
- (void)moviesSyncManagerDidConnect:(SVMoviesSyncManager*)aManager;
- (void)moviesSyncManagerConnectionDidFail:(SVMoviesSyncManager*)aManager;
- (void)moviesSyncManagerNeedsApproval:(SVMoviesSyncManager*)aManager withUrl:(NSURL*)aUrl;
- (void)moviesSyncManagerUserDeniedConnection:(SVMoviesSyncManager*)aManager;
- (void)moviesSyncManager:(SVMoviesSyncManager*)aManager didFetchWatchList:(NSArray*)movies;
- (void)moviesSyncManagerDidFailToSync:(SVMoviesSyncManager*)aManager;
@end

@interface SVMoviesSyncManager : NSObject <SVDatabaseSenderProtocol, UIWebViewDelegate>
@property (strong, readwrite) NSString* service;
@property (weak, readwrite) NSObject<SVMoviesSyncManagerDelegate>* delegate;

+ (SVMoviesSyncManager*)sharedMoviesSyncManager;
- (void)connect;
@end
