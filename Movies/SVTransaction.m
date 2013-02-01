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

- (id)initWithStatements:(NSArray*)statements andSender:(NSObject<SVDatabaseSenderProtocol>*)sender {
	self = [super init];
	if (self) {
		_sqlStatements = statements;
		_sender = sender;
	}
	return self;
}
@end
