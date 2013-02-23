//
//  SVRootViewController.h
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVDatabase.h"
#import "SVMoviesViewController.h"
#import "SVSettingsViewController.h"
#import "SVMoviesSyncManager.h"

@interface SVRootViewController : UIViewController <SVDatabaseSenderProtocol, SVMoviesSyncManagerDelegate, SVMoviesViewControllerDelegate, SVSettingsViewControllerDelegate>

@end
