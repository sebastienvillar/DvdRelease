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
	
	NSDate* date = [[NSDate alloc] init];
	NSArray* dateArray = [dateString componentsSeparatedByString:@"-"];
	NSCalendar* calendar = [NSCalendar currentCalendar];
	NSDateComponents* dateComponents = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit fromDate:date];
	dateComponents.year = [[dateArray objectAtIndex:0] intValue];
	dateComponents.month = [[dateArray objectAtIndex:1] intValue];
	dateComponents.day = [[dateArray objectAtIndex:2] intValue];
	dateComponents.timeZone = [NSTimeZone localTimeZone];
	dateComponents.hour = 0;
	dateComponents.minute = 0;
	dateComponents.second = 0;
	date = [calendar dateFromComponents:dateComponents];
	return date;
}

@end
