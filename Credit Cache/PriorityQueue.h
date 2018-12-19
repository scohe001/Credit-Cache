//
//  PriorityQueue.h
//  Credit Cache
//
//  Created by Ari Cohen on 1/1/17.
//  Copyright © 2017 La Costa Kids. All rights reserved.
//

#ifndef PriorityQueue_h
#define PriorityQueue_h

@interface PriorityQueue : NSObject {
    @private NSMutableArray *arr;
    @private SEL comp;
}

-(id) init;
-(id) initWithCompare:(SEL)comparator;
-(void) push:(id) item;
-(void) clear;
-(id) pop;
-(id) top;
-(NSUInteger) size;
-(bool) empty;


@end

#endif /* PriorityQueue_h */
