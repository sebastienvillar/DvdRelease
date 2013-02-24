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

static NSString* kCellIdentifier = @"movieCell";

@interface SVMoviesTableViewController ()
@property (strong, readonly) SVDatabase* database;
@property (strong, readwrite) SVQuery* moviesQuery;
@property (strong, readwrite) NSMutableArray* movies;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVMoviesTableViewController
@synthesize database = _database,
			movies = _movies,
			moviesQuery = _moviesQuery;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
		self.refreshControl = [[UIRefreshControl alloc] init];
		SVMoviesSyncManager* syncManager = [SVMoviesSyncManager sharedMoviesSyncManager];
		[self.refreshControl addTarget:syncManager action:@selector(sync) forControlEvents:UIControlEventValueChanged];
		self.refreshControl.tintColor = [UIColor colorWithRed:0.7961 green:0.7922 blue:0.7490 alpha:1.0000];
		_moviesQuery = nil;
		_database = [SVDatabase sharedDatabase];
		_movies = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.tableView registerClass:[SVMovieTableViewCell class] forCellReuseIdentifier:kCellIdentifier];
	self.tableView.separatorColor = [UIColor colorWithRed:0.2431 green:0.2431 blue:0.2431 alpha:1.0000];
	self.tableView.backgroundColor = [UIColor blackColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)loadData {
	NSString* sqlStatement = @"SELECT * FROM movie ORDER BY CASE WHEN dvd_release_date IS NULL THEN 0 ELSE 1 END, dvd_release_date DESC;";
	self.moviesQuery =  [[SVQuery alloc] initWithQuery:sqlStatement andSender:self];
	[self.database executeQuery:self.moviesQuery];
}

- (void)database:(SVDatabase *)database didFinishQuery:(SVQuery *)query {
	NSArray* result = query.result;
	for (NSArray* movie in result ){
		//NSLog(@"\nmovie: %@\n date: %@", [movie objectAtIndex:1], [movie objectAtIndex:2]);
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
			movie.smallImageFileName = [movieArray objectAtIndex:6];
			[self.movies addObject:movie];
		}
	}
	[self.tableView reloadData];
}

//////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDelegate
//////////////////////////////////////////////////////////////////////

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	CGFloat height = kCellHeight;
	return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

//////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDataSource
//////////////////////////////////////////////////////////////////////

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	SVMovieTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
	cell.movie = [self.movies objectAtIndex:indexPath.row];
	cell.tableViewParent = tableView;
	[cell setNeedsDisplay];
	return cell;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.movies.count;
}

- (int)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

@end
