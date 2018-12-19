//
//  Transaction.h
//  Credit Cache
//
//  Created by Ari Cohen on 1/1/17.
//  Copyright © 2017 La Costa Kids. All rights reserved.
//

#ifndef Transaction_h
#define Transaction_h

typedef NS_ENUM(NSInteger, Transaction) {
    RETURN,
    RESALE,
    PURCHASE,
    CASH_OUT
};

@interface Trans : NSObject

@property (copy) NSDate *date;
@property double value;
@property Transaction type;

- (NSComparisonResult)transCompare:(Trans *)otherTrans;
- (id) init;
- (id) initWithValue:(double) val Date:(NSDate*) dat Type:(Transaction) t;
+ (bool) isLegacyDate:(NSDate*) date;

@end

/////////////////////////////////////////////////
////////// IMPLEMENTATION ///////////////////////
/////////////////////////////////////////////////

@implementation Trans

- (NSComparisonResult)transCompare:(Trans *)otherTrans {
    if([Trans isLegacyDate:_date])
        return NSOrderedDescending;
    if([[_date laterDate:otherTrans.date] isEqualToDate:_date])
        return NSOrderedAscending;
    return NSOrderedDescending;
}

-(id) init {
    return [self initWithValue:0.0 Date:NULL Type:PURCHASE];
}


-(id) initWithValue:(double)val Date:(NSDate *)dat Type:(Transaction)t {
    self = [super init];
    if(self) {
        _date = [[NSDate alloc] initWithTimeInterval:0 sinceDate:dat];
        _value = val;
        _type = t;
    }
    return self;
}

+(bool) isLegacyDate:(NSDate *)date {
    //Create our cutoff date:
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:01];
    [comps setMonth:01];
    [comps setYear:2017]; //Changed for testing, should be 2017
    NSDate *cutoff = [[NSCalendar currentCalendar] dateFromComponents:comps];
    
    return ([[cutoff laterDate:date] isEqualToDate:cutoff]);
}

@end

#endif /* Transaction_h */
