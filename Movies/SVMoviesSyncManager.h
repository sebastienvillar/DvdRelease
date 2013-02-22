//
//  SVMoviesSyncManager.h
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVDatabase.h"
#import "SVTmdbWatchListRequest.h"
#import "SVRTDvdReleaseDateRequest.h"
@class SVMoviesSyncManager;

@protocol SVMoviesSyncManagerDelegate <NSObject>
- (void)moviesSyncManagerDidConnect:(SVMoviesSyncManager*)aManager;
- (void)moviesSyncManagerConnectionDidFail:(SVMoviesSyncManager*)aManager withError:(NSError*)error;
- (void)moviesSyncManagerNeedsApproval:(SVMoviesSyncManager*)aManager withUrl:(NSURL*)aUrl;
- (void)moviesSyncManagerUserDeniedConnection:(SVMoviesSyncManager*)aManager;
- (void)moviesSyncManagerDidStartSyncing:(SVMoviesSyncManager*)aManager;
- (void)moviesSyncManagerDidFinishSyncing:(SVMoviesSyncManager*)aManager;
- (void)moviesSyncManagerDidFailSyncing:(SVMoviesSyncManager*)aManager withError:(NSError*)error;
@end

@interface SVMoviesSyncManager : NSObject <SVDatabaseSenderProtocol, UIWebViewDelegate, SVTmdbWatchListRequestDelegate, SVRTDvdReleaseDateRequestDelegate>
@property (strong, readwrite) NSString* service;
@property (weak, readwrite) NSObject<SVMoviesSyncManagerDelegate>* delegate;

+ (SVMoviesSyncManager*)sharedMoviesSyncManager;
- (void)connect;
- (void)sync;
@end
