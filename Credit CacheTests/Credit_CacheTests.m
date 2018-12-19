//
//  Credit_CacheTests.m
//  Credit CacheTests
//
//  Created by Ari Cohen on 3/28/14.
//  Copyright (c) 2014 La Costa Kids. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "test.h"
#import "PriorityQueue.h"

@interface Credit_CacheTests : XCTestCase

@end

@implementation Credit_CacheTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)customClassTest
{
    Car *test = [[Car alloc] init];
    test.model = @"TEST";
    [test drive];
}

@end
