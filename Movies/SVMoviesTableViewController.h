//
//  SVMoviesTableViewController.h
//  Movies
//
//  Created by Sébastien Villar on 24/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SVMoviesTableViewController : UITableViewController
- (void)loadData;
- (void)displayError;
- (void)hideError;
- (void)beginRefreshing;
- (void)endRefreshing;
@end
