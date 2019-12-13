//
//  CompatibilityTests.m
//  Stinger_Tests
//
//  Created by 李永光 on 2019/12/13.
//  Copyright © 2019 Assuner-Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stinger/Stinger.h>
#import <Aspects/Aspects.h>

@interface TestClassD : NSObject
- (void)methodA;
- (void)methodB;
- (void)methodC;
- (void)methodD;
@end

static NSString *TestClassD_string = @"";

@implementation TestClassD

- (void)methodA {
  TestClassD_string = [TestClassD_string stringByAppendingFormat:@"original methodA called--"];
}

- (void)methodB {
  TestClassD_string = [TestClassD_string stringByAppendingFormat:@"original methodB called--"];
}

- (void)methodC {
  TestClassD_string = [TestClassD_string stringByAppendingFormat:@"original methodC called--"];
}

- (void)methodD {
  TestClassD_string = [TestClassD_string stringByAppendingFormat:@"original methodD called--"];
}

@end

@interface CompatibilityTests : XCTestCase

@end

@implementation CompatibilityTests


- (void)testMethodA {
  TestClassD *object1 = [TestClassD new];
  NSString *result = nil;
  [TestClassD st_hookInstanceMethod:@selector(methodA) option:STOptionAfter usingIdentifier:@"hook methodA after1" withBlock:^(id<StingerParams> params) {
    TestClassD_string = [TestClassD_string stringByAppendingFormat:@"Stinger methodA after1 called--"];
  }];
  
  [TestClassD aspect_hookSelector:@selector(methodA) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> params) {
    TestClassD_string = [TestClassD_string stringByAppendingFormat:@"Aspect methodA after1 called--"];
  } error:nil];
  
  TestClassD_string = @"";
  [object1 methodA];
  result = @"original methodA called--Stinger methodA after1 called--Aspect methodA after1 called--";
  XCTAssertTrue([TestClassD_string isEqualToString:result], @"should be equal");
}

- (void)testMerhodB {
  TestClassD *object1 = [TestClassD new];
  NSString *result = nil;
  
  [TestClassD aspect_hookSelector:@selector(methodB) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> params) {
    TestClassD_string = [TestClassD_string stringByAppendingFormat:@"Aspect methodB after1 called--"];
  } error:nil];
  
  [TestClassD st_hookInstanceMethod:@selector(methodB) option:STOptionAfter usingIdentifier:@"hook methodB after1" withBlock:^(id<StingerParams> params) {
    TestClassD_string = [TestClassD_string stringByAppendingFormat:@"Stinger methodB after1 called--"];
  }];
  
  TestClassD_string = @"";
  [object1 methodB];
  result = @"original methodB called--Aspect methodB after1 called--Stinger methodB after1 called--";
  XCTAssertTrue([TestClassD_string isEqualToString:result], @"should be equal");
}


- (void)testMethodC {
  TestClassD *object1 = [TestClassD new];
  NSString *result = nil;
  [object1 st_hookInstanceMethod:@selector(methodC) option:STOptionAfter usingIdentifier:@"hook methodC after1" withBlock:^(id<StingerParams> params) {
    TestClassD_string = [TestClassD_string stringByAppendingFormat:@"Stinger methodC after1 called--"];
  }];
  
  [object1 aspect_hookSelector:@selector(methodC) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> params) {
    TestClassD_string = [TestClassD_string stringByAppendingFormat:@"Aspect methodC after1 called--"];
  } error:nil];
  
  TestClassD_string = @"";
  [object1 methodC];
  result = @"original methodC called--Stinger methodC after1 called--Aspect methodC after1 called--";
  XCTAssertTrue([TestClassD_string isEqualToString:result], @"should be equal");
}

- (void)testMerhodD {
  TestClassD *object1 = [TestClassD new];
  NSString *result = nil;
  
  [object1 aspect_hookSelector:@selector(methodD) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> params) {
    TestClassD_string = [TestClassD_string stringByAppendingFormat:@"Aspect methodD after1 called--"];
  } error:nil];
  
  [object1 st_hookInstanceMethod:@selector(methodD) option:STOptionAfter usingIdentifier:@"hook methodD after1" withBlock:^(id<StingerParams> params) {
    TestClassD_string = [TestClassD_string stringByAppendingFormat:@"Stinger methodD after1 called--"];
  }];
  
  TestClassD_string = @"";
  [object1 methodD];
  result = @"original methodD called--Aspect methodD after1 called--Stinger methodD after1 called--";
  XCTAssertTrue([TestClassD_string isEqualToString:result], @"should be equal");
}


@end
