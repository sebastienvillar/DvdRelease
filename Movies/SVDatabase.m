//
//  SVDatabaseWrapper.m
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVDatabase.h"
#import "sqlite3.h"

static SVDatabase* sharedDatabase = nil;

@interface SVDatabase ()
@property (readonly) dispatch_queue_t queue;
@property (strong, readonly) NSString* databasePath;
@property (readonly) sqlite3* database;
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVDatabase
@synthesize queue = _queue,
			databasePath = _databasePath;

+ (SVDatabase*)sharedDatabase {
	if (!sharedDatabase) {
		sharedDatabase = [[self alloc] init];
	}
	return sharedDatabase;
}

- (id)init {
    self = [super init];
    if (self) {
		_queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
		NSString* applicationSupportDirectoryPath = [self applicationSupportDirectoryPath];
		_databasePath = [NSString stringWithFormat:@"%@%@",applicationSupportDirectoryPath, @"/database.db"];
		if (![[NSFileManager defaultManager] fileExistsAtPath:_databasePath]) {
			NSString *createServiceStatement = @"CREATE TABLE watchlist_service (id INTEGER PRIMARY KEY,"
			"name TEXT,"
			"session_id TEXT,"
			"is_current_service INTEGER);";
			NSString *createMovieStatement = @"CREATE TABLE movie (id INTEGER PRIMARY KEY,"
			"title TEXT,"
			"dvd_release_date DATE, "
			"year_of_release INTEGER,"
			"image_url TEXT,"
			"image_file_name TEXT,"
			"small_image_file_name TEXT);";
			
			[self open];
			NSArray* statements = [[NSArray alloc] initWithObjects:createServiceStatement, createMovieStatement, nil];
			SVTransaction* transaction = [[SVTransaction alloc] initWithStatements:statements andSender:nil];
			[self executeTransaction:transaction];
		}
		else {
			[self open];
		}
	}
    return self;
}

- (BOOL)open {
	return sqlite3_open_v2([self.databasePath UTF8String], &_database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) == SQLITE_OK;
}
				
- (void)close {
	sqlite3_close(self.database);
}

- (void)executeTransaction:(SVTransaction *)transaction {
	dispatch_async(self.queue, ^{
		BOOL success = YES;
		[self executeSQLStatement:@"BEGIN"];
		for (NSString* statement in transaction.sqlStatements) {
			if (![self executeSQLStatement:statement]) {
				[self executeSQLStatement:@"ROLLBACK"];
				success = NO;
				break;
			}
		}
		if (success) {
			[self executeSQLStatement:@"COMMIT"];
		}
		if ([transaction.sender respondsToSelector:@selector(database:didFinishTransaction:withSuccess:)]) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[transaction.sender database:self didFinishTransaction:transaction withSuccess:success];
			});
		}
	});
}

- (void)executeQuery:(SVQuery *)query {
	dispatch_async(self.queue, ^{
		query.result = [self executeSQLQuery:query.sqlQuery];
		if ([query.sender respondsToSelector:@selector(database:didFinishQuery:)]) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[query.sender database:self didFinishQuery:query];
			});
		}
	});
}

- (NSString*)applicationSupportDirectoryPath {
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString* filePath = [paths objectAtIndex:0];
	NSFileManager* fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:filePath]) {
	    NSError *error;
		BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:filePath
												 withIntermediateDirectories:YES
																  attributes:nil
																	   error:&error];
		if (!success) {
			NSLog(@"RLDatabase: Couldn't create application support directory : %@", error.description);
			return nil;
		}
	}
	return filePath;
}

- (BOOL)executeSQLStatement:(NSString*)statement {
	char* error;
	if (sqlite3_exec(self.database, [statement UTF8String], NULL, NULL, &error) != SQLITE_OK) {
		NSLog(@"RLDatabase: Failed to execute the statement : %@\n%s", statement, error);
		return NO;
	}
	return YES;
}

- (NSArray*)executeSQLQuery:(NSString*)query {
	sqlite3_stmt* statement;
	NSMutableArray* result = nil;
	if (sqlite3_prepare_v2(self.database, [query UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		result = [[NSMutableArray alloc] init];
		while (sqlite3_step(statement) == SQLITE_ROW) {
			NSMutableArray* row = [[NSMutableArray alloc] init];
			int count = sqlite3_column_count(statement);
			for (int i = 0; i < count; i++) {
				int type = sqlite3_column_type(statement, i);
				if (type == SQLITE_INTEGER) {
					NSNumber* number = [NSNumber numberWithInt:sqlite3_column_int(statement, i)];
					[row addObject:number];
				}
				
				else if (type == SQLITE_TEXT) {
					NSString* text = [NSString stringWithUTF8String: (const char*) sqlite3_column_text(statement, i)];
					[row addObject:text];
				}
				
				else if (type == SQLITE_NULL) {
					[row addObject:@"NULL"];
				}
				
				else {
					NSLog(@"RLDatabase: not supposed to get this datatype from the query");
				}
			}
			[result addObject:row];
		}
		sqlite3_finalize(statement);
	}
	return result;
}

@end
