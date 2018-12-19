//
//  PriorityQueue.m
//  Credit Cache
//
//  Created by Ari Cohen on 1/1/17.
//  Copyright © 2017 La Costa Kids. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PriorityQueue.h"

@implementation PriorityQueue

-(id) init {
    return [self initWithCompare:NULL];
}

-(id) initWithCompare:(SEL)comparator {
    self = [super init];
    if(self) {
        arr = [[NSMutableArray alloc] init];
        comp = comparator;
    }
    return self;
}

-(void) push:(id)item {
    [arr addObject:item];
    [arr sortUsingSelector:comp];
}

-(void) clear {
    [arr removeAllObjects];
}

-(id) pop {
    id thing = [arr lastObject];
    [arr removeLastObject];
    return thing;
}

-(id) top {
    return [arr lastObject];
}

-(NSUInteger) size {
    return [arr count];
}

-(bool) empty {
    return ([arr count] == 0);
}

@end
