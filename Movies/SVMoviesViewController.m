//
//  SVMoviesViewController.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVMoviesViewController.h"
#import "SVMoviesLoadingView.h"
#import "SVMovieTableViewCell.h"
#import "SVMovie.h"
#import "SVHelper.h"
#import "SVMoviesTopView.h"

static NSString* kCellIdentifier = @"movieCell";
static int const kTopViewHeight = 48;
static int const kSettingsButtonBottom = 7;
static int const kSettingsButtonRight = 7;

@interface SVMoviesViewController ()
@property (strong, readonly) NSNotificationCenter* notificationCenter;
@property (strong, readonly) SVDatabase* database;
@property (strong, readwrite) SVQuery* moviesQuery;
@property (strong, readwrite) NSMutableArray* movies;
@property (strong, readwrite) UIView* currentView;
@property (strong, readonly) SVMoviesLoadingView* loadingView;
@property (strong, readonly) UITableView* tableView;
@property (strong, readonly) SVMoviesTopView* topView;
@property (strong, readonly) UIButton* settingsButton;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVMoviesViewController
@synthesize notificationCenter = _notificationCenter,
			moviesQuery = _moviesQuery,
			movies = _movies,
			currentView = _currentView,
			loadingView = _loadingView,
			topView = _topView,
			settingsButton = _settingsButton,
			database = _database;

- (id)init
{
    self = [super init];
    if (self) {
		_moviesQuery = nil;
		_database = [SVDatabase sharedDatabase];
		_notificationCenter = [NSNotificationCenter defaultCenter];
		_movies = [[NSMutableArray alloc] init];
		_loadingView = [[SVMoviesLoadingView alloc] initWithFrame:self.view.bounds];
		_currentView = nil;
		_tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
		[_tableView registerClass:[SVMovieTableViewCell class] forCellReuseIdentifier:kCellIdentifier];
		_tableView.delegate = self;
		_tableView.dataSource = self;
		_tableView.separatorColor = [UIColor colorWithRed:0.2431 green:0.2431 blue:0.2431 alpha:1.0000];
		_tableView.backgroundColor = [UIColor blackColor];
		_settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
		UIImage* settingsButtonImage = [UIImage imageNamed:@"settings_button.png"];
		[_settingsButton setBackgroundImage:settingsButtonImage forState:UIControlStateNormal];
		[_settingsButton setBackgroundImage:settingsButtonImage forState:UIControlStateHighlighted];
		_settingsButton.frame = CGRectMake(self.view.frame.size.width - settingsButtonImage.size.width - kSettingsButtonRight, self.view.frame.size.height - settingsButtonImage.size.height - kSettingsButtonBottom, settingsButtonImage.size.width, settingsButtonImage.size.height);
		[_settingsButton addTarget:self action:@selector(didClickSettingsButton) forControlEvents:UIControlEventTouchDown];
		_topView = [[SVMoviesTopView alloc] initWithFrame:CGRectMake(0, -kTopViewHeight, self.view.frame.size.width, kTopViewHeight)];
		//[_notificationCenter addObserver:self selector:@selector(nilSymbol) name:@"moviesSyncManagerDidStartSyncingNotification" object:nil];
		[_notificationCenter addObserver:self selector:@selector(loadData) name:@"moviesSyncManagerDidFinishSyncingNotification" object:nil];
		[_notificationCenter addObserver:self selector:@selector(loadErrorView) name:@"moviesSyncManagerConnectionDidFailNotification" object:nil];
		[_notificationCenter addObserver:self selector:@selector(loadErrorView) name:@"moviesSyncManagerDidFailSyncingNotification" object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)loadView {
	CGRect rect = [UIScreen mainScreen].applicationFrame;
	rect.origin.y = 0;
	self.view = [[UIView alloc] initWithFrame:rect];
}

- (void)loadView:(UIView*)view {
	if (self.currentView) {
		[self.currentView removeFromSuperview];
	}
	self.currentView = view;
	[self.view addSubview:self.currentView];
}

- (void)loadLoadingView {
	[self loadView:self.loadingView];
	[self.loadingView.activityIndicatorView startAnimating];
}

- (void)loadErrorView {
	[self.view addSubview:self.topView];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	self.topView.frame = CGRectMake(0, 0, self.topView.frame.size.width, self.topView.frame.size.height);
	self.currentView.frame = CGRectMake(self.currentView.frame.origin.x, self.currentView.frame.origin.y + self.topView.frame.size.height, self.currentView.frame.size.width, self.currentView.frame.size.height - self.topView.frame.size.height);
	[UIView commitAnimations];
}

- (void)loadMainView {
	[self loadView:self.tableView];
	[self.view addSubview:self.settingsButton];
}

- (void)loadData {
	NSString* sqlStatement = @"SELECT * FROM movie ORDER BY CASE WHEN dvd_release_date IS NULL THEN 0 ELSE 1 END, dvd_release_date DESC;";
	self.moviesQuery =  [[SVQuery alloc] initWithQuery:sqlStatement andSender:self];
	[self.database executeQuery:self.moviesQuery];
}

- (void)clearData {
	[self.movies removeAllObjects];
	[self.tableView reloadData];
}

- (void)didClickSettingsButton {
	if ([self.delegate respondsToSelector:@selector(moviesViewControllerDidClickSettingsButton:)])
		[self.delegate moviesViewControllerDidClickSettingsButton:self];
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
