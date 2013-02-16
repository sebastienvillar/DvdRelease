//
//  SVQuery.m
//  Movies
//
//  Created by Sébastien Villar on 1/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVQuery.h"

@interface SVQuery ()
@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

@implementation SVQuery
@synthesize sqlQuery = _sqlQuery,
			sender = _sender,
			result = _result;

- (id)initWithQuery:(NSString*)query andSender:(id)sender {
	self = [super init];
	if (self) {
		_sqlQuery = query;
		_sender = sender;
	}
	return self;
}
@end
