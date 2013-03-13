//
//  SVMoviesTableViewController.m
//  Movies
//
//  Created by Sébastien Villar on 24/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVMoviesTableViewController.h"
#import "SVMovieTableViewCell.h"
#import "SVDatabase.h"
#import "SVHelper.h"
#import "SVMoviesSyncManager.h"
#import "SVNoMoviesView.h"
#import "SVMoviesErrorViewCell.h"

#define kMovieCellIdentifier @"movieCell"
#define kErrorCellIdentifier @"errorCell"
#define kErrorViewCellHeight 43

@interface SVMoviesTableViewController ()
@property (strong, readonly) SVDatabase* database;
@property (strong, readwrite) SVQuery* moviesQuery;
@property (strong, readwrite) NSMutableArray* movies;
@property (strong, readwrite) SVNoMoviesView* noMoviesBackground;
@property (strong, readwrite) UIView* currentView;
@property (readwrite, getter = isErrorDisplayed) BOOL errorDisplayed;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVMoviesTableViewController
@synthesize database = _database,
			movies = _movies,
			errorDisplayed = _errorDisplayed,
			noMoviesBackground = _noMoviesBackground,
			currentView = _currentView,
			moviesQuery = _moviesQuery;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
		_moviesQuery = nil;
		_errorDisplayed = NO;
		_database = [SVDatabase sharedDatabase];
		_movies = [[NSMutableArray alloc] init];
		_noMoviesBackground = nil;
		_currentView = nil;
	}
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.tableView registerClass:[SVMovieTableViewCell class] forCellReuseIdentifier:kMovieCellIdentifier];
	[self.tableView registerClass:[SVMoviesErrorViewCell class] forCellReuseIdentifier:kErrorCellIdentifier];
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.backgroundColor = [UIColor blackColor];
	self.tableView.frame = self.view.bounds;
	self.noMoviesBackground = [[SVNoMoviesView alloc] initWithFrame:self.view.bounds];
	[self.noMoviesBackground.refreshButton addTarget:[SVMoviesSyncManager sharedMoviesSyncManager]
										  action:@selector(sync)
								forControlEvents:UIControlEventTouchDown];
	self.currentView = self.tableView;
	self.noMoviesBackground.autoresizingMask = UIViewAutoresizingFlexibleHeight;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)displayError {
	if (!self.isErrorDisplayed) {
		self.errorDisplayed = YES;
		NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
		[self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationBottom];
	}
}

- (void)hideError {
	if (self.isErrorDisplayed) {
		self.errorDisplayed = NO;
		NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
		[self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationTop];
	}
}

- (void)beginRefreshing {
	if (self.currentView == self.noMoviesBackground) {
		[self.noMoviesBackground.activityIndicatorView startAnimating];
	}
	else {
		if (!self.refreshControl) {
			self.refreshControl = [[UIRefreshControl alloc] init];
			SVMoviesSyncManager* syncManager = [SVMoviesSyncManager sharedMoviesSyncManager];
			[self.refreshControl addTarget:syncManager action:@selector(sync) forControlEvents:UIControlEventValueChanged];
			self.refreshControl.tintColor = [UIColor colorWithWhite:0.5 alpha:1];
		}
		if (!self.refreshControl.isRefreshing) {
			[self.refreshControl beginRefreshing];
		}
	}
}

- (void)endRefreshing {
	if (self.currentView == self.noMoviesBackground) {
		[self.noMoviesBackground.activityIndicatorView stopAnimating];
	}
	else {
		if (self.refreshControl.isRefreshing) {
			[self.refreshControl endRefreshing];
		}
	}
}

- (void)loadData {
	NSString* sqlStatement = @"SELECT * FROM movie ORDER BY dvd_release_date DESC;";
	self.moviesQuery =  [[SVQuery alloc] initWithQuery:sqlStatement andSender:self];
	[self.database executeQuery:self.moviesQuery];
}

- (void)database:(SVDatabase *)database didFinishQuery:(SVQuery *)query {
	NSArray* result = query.result;
	for (NSArray* movie in result ){
	}
	if (query == self.moviesQuery) {
		[self.movies removeAllObjects];
		for (NSArray* movieArray in result) {
			SVMovie* movie = [[SVMovie alloc] init];
			movie.identifier = [movieArray objectAtIndex:0];
			movie.title = [movieArray objectAtIndex:1];
			movie.dvdReleaseDate = [SVHelper dateFromString:[movieArray objectAtIndex:2]];
			movie.yearOfRelease = [movieArray objectAtIndex:3];
			movie.imageUrl = [NSURL URLWithString:[movieArray objectAtIndex:4]];
			movie.imageFileName = [movieArray objectAtIndex:5];
			[self.movies addObject:movie];
		}
	}
	NSLog(@"result.count : %d", result.count);
	if (result.count == 0) {
		if (self.currentView == self.tableView)
			[self.view addSubview:self.noMoviesBackground];
		self.currentView = self.noMoviesBackground;
	}
		
	else {
		if (self.currentView == self.noMoviesBackground) {
			[self.noMoviesBackground removeFromSuperview];
		}
		self.currentView = self.tableView;
	}
	
	[self.tableView reloadData];
}

//////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDelegate
//////////////////////////////////////////////////////////////////////

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	CGFloat height = 0;
	if (!self.isErrorDisplayed) {
		height = kMovieCellHeight;
	}
	else {
		if (indexPath.section == 0) {
			height = kErrorViewCellHeight;
		}
		else if (indexPath.section == 1) {
			height = kMovieCellHeight;
		}
	}
	return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

//////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDataSource
//////////////////////////////////////////////////////////////////////

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = nil;
	if (!self.isErrorDisplayed) {
		cell = [tableView dequeueReusableCellWithIdentifier:kMovieCellIdentifier forIndexPath:indexPath];
		SVMovieTableViewCell* moviesCell = (SVMovieTableViewCell*)cell;
		if (indexPath.row == 0)
			moviesCell.needTopLine = NO;
		else
			moviesCell.needTopLine = YES;
		
		moviesCell.movie = [self.movies objectAtIndex:indexPath.row];
		moviesCell.tableViewParent = tableView;
		[moviesCell setNeedsDisplay];
	}
	
	else {
		if (indexPath.section == 0) {
			cell = [tableView dequeueReusableCellWithIdentifier:kErrorCellIdentifier forIndexPath:indexPath];
		}
		else if (indexPath.section == 1) {
			cell = [tableView dequeueReusableCellWithIdentifier:kMovieCellIdentifier forIndexPath:indexPath];
			SVMovieTableViewCell* moviesCell = (SVMovieTableViewCell*)cell;
			if (indexPath.row == 0)
				moviesCell.needTopLine = NO;
			else
				moviesCell.needTopLine = YES;
			moviesCell.movie = [self.movies objectAtIndex:indexPath.row];
			moviesCell.tableViewParent = tableView;
			[moviesCell setNeedsDisplay];
		}
	}
	return cell;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (!self.isErrorDisplayed) {
		return self.movies.count;
	}
	else {
		if (section == 0) {
			return 1;
		}
		else if (section == 1) {
			return self.movies.count;
		}
	}
	return 0;
}

- (int)numberOfSectionsInTableView:(UITableView *)tableView {
	if (self.isErrorDisplayed) {
		return 2;
	}
	return 1;
}

@end
