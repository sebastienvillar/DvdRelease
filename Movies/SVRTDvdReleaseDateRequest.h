//
//  SVRTDvdReleaseDateRequest.h
//  Movies
//
//  Created by Sébastien Villar on 30/01/13.
//  Copyright (c) 2013 Sébastien Villar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVMovie.h"
@class SVRTDvdReleaseDateRequest;

@protocol SVRTDvdReleaseDateRequestDelegate <NSObject>
- (void)dvdReleaseDateRequestDidFinish:(SVRTDvdReleaseDateRequest*)request;
- (void)dvdReleaseDateRequestDidFail:(SVRTDvdReleaseDateRequest*)request;
@end

@interface SVRTDvdReleaseDateRequest : NSObject
@property (weak, readwrite) NSObject<SVRTDvdReleaseDateRequestDelegate>* delegate;
- (id)initWithMovie:(SVMovie*)movie;
@end
