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
@property (strong, readonly) NSMutableArray* sqlStatements;
@property (strong, readonly) id sender;

- (id)initWithStatements:(NSArray*)statements andSender:(id)sender;
- (id)initWithSender:(id)sender;
- (void)addStatements:(NSArray*)statements;
- (void)addStatement:(NSString*)statement;
@end
