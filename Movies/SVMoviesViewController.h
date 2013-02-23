//
//  SVMoviesViewController.h
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVDatabase.h"

@class SVMoviesViewController;

@protocol SVMoviesViewControllerDelegate <NSObject>
- (void)moviesViewControllerDidClickSettingsButton:(SVMoviesViewController*)moviesViewController;
@end

@interface SVMoviesViewController : UIViewController <SVDatabaseSenderProtocol, UITableViewDataSource, UITableViewDelegate>
@property (weak, readwrite)id delegate;
- (void)loadLoadingView;
- (void)loadMainView;
- (void)loadData;
- (void)clearData;
@end
