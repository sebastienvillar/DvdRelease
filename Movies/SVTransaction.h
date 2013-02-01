//
//  SVTransaction.h
//  Movies
//
//  Created by Sébastien Villar on 1/02/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol SVDatabaseSenderProtocol;

@interface SVTransaction : NSObject
@property (strong, readonly) NSArray* sqlStatements;
@property (strong, readonly) NSObject<SVDatabaseSenderProtocol>* sender;

- (id)initWithStatements:(NSArray*)statement andSender:(NSObject<SVDatabaseSenderProtocol>*)sender;
@end
