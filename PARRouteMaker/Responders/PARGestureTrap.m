//
//  PARGestureTrap.m
//  PARRouteMaker
//
//  Created by Paul Rolfe on 6/13/15.
//  Copyright (c) 2015 paulrolfe. All rights reserved.
//

#import "PARGestureTrap.h"

@implementation PARGestureTrap

-(id) init{
    if (self = [super init])
    {
        self.cancelsTouchesInView = NO;
    }
    return self;
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer{
    return NO;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer{
    return NO;
}

@end
