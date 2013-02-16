//
//  SVTransaction.m
//  Movies
//
//  Created by Sébastien Villar on 1/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVTransaction.h"

@interface SVTransaction ()
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVTransaction
@synthesize sqlStatements = _sqlStatements,
			sender = _sender;

- (id)initWithSender:(id)sender {
	self =[self init];
	_sender = sender;
	_sqlStatements = [[NSMutableArray alloc] init];
	return self;
}

- (id)initWithStatements:(NSArray*)statements andSender:(id)sender {
	self = [self init];
	_sqlStatements = [NSMutableArray arrayWithArray:statements];
	_sender = sender;
	return self;
}

- (void)addStatements:(NSArray*)statements {
	[self.sqlStatements addObjectsFromArray:statements];
}

- (void)addStatement:(NSString*)statement {
	[self.sqlStatements addObject:statement];
}

- (NSString*)description {
	NSMutableString* description = [[NSMutableString alloc] initWithString:@"Transaction: "];
	for (NSString* sqlStatement in self.sqlStatements) {
		[description appendFormat:@"%@\n", sqlStatement];
	}
	return description;
}
@end
