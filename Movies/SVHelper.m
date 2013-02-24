//
//  SVHelper.m
//  Movies
//
//  Created by Sébastien Villar on 22/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import "SVHelper.h"

@implementation SVHelper

+ (NSDate*)dateFromString:(NSString*)dateString {
	if (!dateString || [dateString isEqualToString:@"NULL"])
		return nil;
	
	dateString = [NSString stringWithFormat:@"%@ 00:00:00",dateString];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
	[dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
	NSDate* date = [dateFormatter dateFromString:dateString];
	return date;
}

@end
