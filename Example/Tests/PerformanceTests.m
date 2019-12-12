//
//  PerformanceTests.m
//  Stinger_Tests
//
//  Created by 李永光 on 2019/12/11.
//  Copyright © 2019 Assuner-Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stinger/Stinger.h>
#import <Aspects/Aspects.h>

@interface TestClassC : NSObject
- (void)methodA1;
- (void)methodB1;
- (void)methodA2;
- (void)methodB2;
- (NSString *)methodC:(NSString *)str;
- (NSString *)methodD:(NSString *)str;
@end

@implementation TestClassC

- (void)methodA1 {
}

- (void)methodB1 {
}

- (void)methodA2 {
}

- (void)methodB2 {
}

- (NSString *)methodC:(NSString *)str {
  return [str stringByAppendingFormat:@"xx"];
}

- (NSString *)methodD:(NSString *)str {
  return [str stringByAppendingFormat:@"xx"];
}

@end

@interface PerformanceTests : XCTestCase

@end


@implementation PerformanceTests

- (void)testStingerHookMethodA1 {
  [TestClassC st_hookInstanceMethod:@selector(methodA1) option:STOptionBefore usingIdentifier:@"hook methodA before" withBlock:^(id<StingerParams> params) {
     }];
  [TestClassC st_hookInstanceMethod:@selector(methodA1) option:STOptionAfter usingIdentifier:@"hook methodA After" withBlock:^(id<StingerParams> params) {
  }];
  
  TestClassC *object1 = [TestClassC new];
  [self measureBlock:^{
    for (NSInteger i = 0; i < 10000; i++) {
      [object1 methodA1];
    }
  }];
}

- (void)testAspectHookMethodB1 {
  [TestClassC aspect_hookSelector:@selector(methodB1) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> params) {
   } error:nil];
  [TestClassC aspect_hookSelector:@selector(methodB1) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> params) {
  } error:nil];
  
  TestClassC *object1 = [TestClassC new];
  [self measureBlock:^{
    for (NSInteger i = 0; i < 10000; i++) {
      [object1 methodB1];
    }
  }];
}

- (void)testStingerHookMethodA2 {
  TestClassC *object1 = [TestClassC new];
  [object1 st_hookInstanceMethod:@selector(methodA2) option:STOptionBefore usingIdentifier:@"hook methodA before" withBlock:^(id<StingerParams> params) {
     }];
  [object1 st_hookInstanceMethod:@selector(methodA2) option:STOptionAfter usingIdentifier:@"hook methodA After" withBlock:^(id<StingerParams> params) {
  }];
  
  [self measureBlock:^{
    for (NSInteger i = 0; i < 10000; i++) {
      [object1 methodA2];
    }
  }];
}

- (void)testAspectHookMethodB2 {
  TestClassC *object1 = [TestClassC new];
  [object1 aspect_hookSelector:@selector(methodB2) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> params) {
   } error:nil];
  [object1 aspect_hookSelector:@selector(methodB2) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> params) {
  } error:nil];
  
  [self measureBlock:^{
    for (NSInteger i = 0; i < 10000; i++) {
      [object1 methodB2];
    }
  }];
}


- (void)testStingerHookMethodC {
  TestClassC *object1 = [TestClassC new];
  __block NSString *oldRet, *ret;
  [TestClassC st_hookInstanceMethod:@selector(methodC:) option:STOptionInstead usingIdentifier:@"hook methodC instead" withBlock:^NSString *(id<StingerParams> params, NSString *str) {
    [params invokeAndGetOriginalRetValue:&oldRet];
    ret = [oldRet stringByAppendingFormat:@"++"];
    return ret;
  }];
  
  __block NSString *result;
  [self measureBlock:^{
    for (NSInteger i = 0; i < 10000; i++) {
      result = [object1 methodC:@""];
    }
  }];
}

- (void)testAspectHookMethodD {
   __block NSString *oldRet, *ret;
  [TestClassC aspect_hookSelector:@selector(methodD:) withOptions:AspectPositionInstead usingBlock:^(id<AspectInfo> params, NSString *str) {
    [params.originalInvocation invoke];
    [params.originalInvocation getReturnValue:&oldRet];
    ret = [oldRet stringByAppendingFormat:@"++"];
    [params.originalInvocation setReturnValue:&ret];
  } error:nil];
  
  TestClassC *object1 = [TestClassC new];
  __block NSString *result;
  [self measureBlock:^{
    for (NSInteger i = 0; i < 10000; i++) {
      result = [object1 methodD:@""];
    }
  }];
}
@end
