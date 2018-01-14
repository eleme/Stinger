//
//  testTests.m
//  testTests
//
//  Created by Assuner on 2017/8/17.
//  Copyright © 2017年 Assuner. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ASViewController.h"
#import "stinger.h"
static ASViewController *_vc;

@interface testTests : XCTestCase


@end

@implementation testTests

- (void)setUp {
  [super setUp];
  _vc = [ASViewController new];
}

- (void)tearDown {
  [super tearDown];
  _vc = nil;
}

- (void)testExample {
  // This is an example of a functional test case.
  // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample2 {
  // This is an example of a performance test case.
  [self measureBlock:^{
    for (int i = 0; i < 100; i++) {
      [_vc print1:@"stttttttt"];
    }
  }];
}

@end

