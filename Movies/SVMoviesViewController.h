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

typedef int SVMoviesViewState;
static const int SVMoviesViewLoadingState = 0;
static const int SVMoviesViewDisplayState = 1;
static const int SVMoviesViewErrorState = 2;

@protocol SVMoviesViewControllerDelegate <NSObject>
- (void)moviesViewControllerDidClickSettingsButton:(SVMoviesViewController*)moviesViewController;
@end

@interface SVMoviesViewController : UIViewController <SVDatabaseSenderProtocol, UITableViewDataSource, UITableViewDelegate>
@property (weak, readwrite)id delegate;
@property (readonly) SVMoviesViewState currentState;
- (void)displayViewForState:(SVMoviesViewState)state;
@end
