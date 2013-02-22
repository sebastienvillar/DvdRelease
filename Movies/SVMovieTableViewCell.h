//
//  SVMovieTableViewCell.h
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVMovie.h"

static const int kCellHeight = 176;
@interface SVMovieTableViewCell : UITableViewCell
@property (strong, readwrite) SVMovie* movie;
@property (weak, readwrite) UITableView* tableViewParent;

@end
