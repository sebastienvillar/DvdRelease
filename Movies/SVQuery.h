//
//  SVQuery.h
//  Movies
//
//  Created by Sébastien Villar on 1/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol SVDatabaseSenderProtocol;

@interface SVQuery : NSObject
@property (strong, readonly) NSString* sqlQuery;
@property (strong, readonly) NSObject<SVDatabaseSenderProtocol>* sender;
@property (strong, readwrite) NSArray* result;

- (id)initWithQuery:(NSString*)query andSender:(NSObject<SVDatabaseSenderProtocol>*)sender;
@end
