//
//  test.h
//  Credit Cache
//
//  Created by Ari Cohen on 1/1/17.
//  Copyright © 2017 La Costa Kids. All rights reserved.
//

#ifndef test_h
#define test_h

@interface Car : NSObject

@property (copy) NSNumber *model;

- (NSComparisonResult)myCompare:(Car *)otherCar;
- (void)drive;

@end

////////////////////////////////////////////////////////////////////////////////

@implementation Car {
    // Private instance variables
    double _odometer;
}


- (NSComparisonResult)myCompare:(Car *)otherCar {
    //return [otherCar.model compare:_model];
    return [_model compare:otherCar.model];
}

- (void)drive {
    NSLog(@"Driving a %@. Vrooooom!", self.model);
}

@end

#endif /* test_h */
