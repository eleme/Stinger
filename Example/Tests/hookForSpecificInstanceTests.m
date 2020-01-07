//
//  hookForSpecificInstanceTests.m
//  Stinger_Tests
//
//  Created by 李永光 on 2019/12/8.
//  Copyright © 2019 Assuner-Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stinger/Stinger.h>

@interface TestClassB : NSObject
- (void)instanceMethodA;
- (void)instanceMethodB;
- (double)instanceMethodCWithNumA:(double)a numB:(double)b;
- (void)instanceMethodD;
@end

static NSString *TestClassB_string_b = @"";

@implementation TestClassB

- (void)instanceMethodA {
  TestClassB_string_b = [TestClassB_string_b stringByAppendingString:@"original instanceMethodA called--"];
}

- (void)instanceMethodB {
  TestClassB_string_b = [TestClassB_string_b stringByAppendingString:@"original instanceMethodB called--"];
}

- (double)instanceMethodCWithNumA:(double)a numB:(double)b {
  return a+b;
}

- (void)instanceMethodD {
    
}

@end


@interface HookForSpecificInstanceTests : XCTestCase

@end

@implementation HookForSpecificInstanceTests
- (void)setUp {
   TestClassB_string_b = @"";
}


- (void)tearDown {
    
}


- (void)testMethodA {
  TestClassB *object1 = [TestClassB new];
  [object1 st_hookInstanceMethod:@selector(instanceMethodA) option:STOptionBefore usingIdentifier:@"hook InstanceMethodA before 1" withBlock:^(id<StingerParams> params){
      TestClassB_string_b = [TestClassB_string_b stringByAppendingString:@"before 1 instanceMethodA called--"];
    XCTAssertTrue(object1 == params.slf, @"should be equal");
    XCTAssertTrue(@selector(instanceMethodA) == params.sel, @"should be equal");
  }];
  [object1 st_hookInstanceMethod:@selector(instanceMethodA) option:STOptionBefore usingIdentifier:@"hook InstanceMethodA before 2" withBlock:^(id<StingerParams> params){
         TestClassB_string_b = [TestClassB_string_b stringByAppendingString:@"before 2 instanceMethodA called--"];
  }];
  [object1 st_hookInstanceMethod:@selector(instanceMethodA) option:STOptionAfter usingIdentifier:@"hook InstanceMethodA after 1" withBlock:^(id<StingerParams> params){
            TestClassB_string_b = [TestClassB_string_b stringByAppendingString:@"after 1 instanceMethodA called--"];
  }];
  [object1 st_hookInstanceMethod:@selector(instanceMethodA) option:STOptionAfter usingIdentifier:@"hook InstanceMethodA after 2" withBlock:^(id<StingerParams> params){
            TestClassB_string_b = [TestClassB_string_b stringByAppendingString:@"after 2 instanceMethodA called--"];
  }];
  [object1 instanceMethodA];
  NSString *TestClassB_string_b_result = @"before 1 instanceMethodA called--before 2 instanceMethodA called--original instanceMethodA called--after 1 instanceMethodA called--after 2 instanceMethodA called--";
  XCTAssertTrue([TestClassB_string_b isEqualToString:TestClassB_string_b_result], @"should be equal");
  
  NSArray <STIdentifier> *allHookIdentifiers = [object1 st_allIdentifiersForKey:@selector(instanceMethodA)];
  XCTAssertTrue(allHookIdentifiers.count == 4, @"should be 4");
  
  TestClassB *object2 = [TestClassB new];
  TestClassB_string_b = @"";
  [object2 instanceMethodA];
  TestClassB_string_b_result = @"original instanceMethodA called--";
  XCTAssertTrue([TestClassB_string_b isEqualToString:TestClassB_string_b_result], @"should be equal");
  
  TestClassB_string_b = @"";
  [object2 st_hookInstanceMethod:@selector(instanceMethodA) option:STOptionInstead usingIdentifier:@"hook InstanceMethodA instead object2" withBlock:^(id<StingerParams> params){
             TestClassB_string_b = [TestClassB_string_b stringByAppendingString:@"inserad instanceMethodA in object2 called--"];
  }];
  [object2 st_hookInstanceMethod:@selector(instanceMethodA) option:STOptionAfter usingIdentifier:@"hook InstanceMethodA after 1 object2" withBlock:^(id<StingerParams> params){
             TestClassB_string_b = [TestClassB_string_b stringByAppendingString:@"after 2 instanceMethodA in object2 called--"];
  }];
  [object2 instanceMethodA];
  TestClassB_string_b_result = @"inserad instanceMethodA in object2 called--after 2 instanceMethodA in object2 called--";
  XCTAssertTrue([TestClassB_string_b isEqualToString:TestClassB_string_b_result], @"should be equal");
  allHookIdentifiers = [object2 st_allIdentifiersForKey:@selector(instanceMethodA)];
  XCTAssertTrue(allHookIdentifiers.count == 2 && [allHookIdentifiers containsObject:@"hook InstanceMethodA instead object2"] && [allHookIdentifiers containsObject:@"hook InstanceMethodA after 1 object2"], @"should be 2");
  
  
  [object1 st_removeHookWithIdentifier:@"hook InstanceMethodA after 2" forKey:@selector(instanceMethodA)];
  [object1 st_removeHookWithIdentifier:@"hook InstanceMethodA before 1" forKey:@selector(instanceMethodA)];
  TestClassB_string_b = @"";
  [object1 instanceMethodA];
  TestClassB_string_b_result = @"before 2 instanceMethodA called--original instanceMethodA called--after 1 instanceMethodA called--";
  XCTAssertTrue([TestClassB_string_b isEqualToString:TestClassB_string_b_result], @"should be equal");
  allHookIdentifiers = [object1 st_allIdentifiersForKey:@selector(instanceMethodA)];
  XCTAssertTrue(allHookIdentifiers.count == 2, @"should be 2");
}


- (void)testInstanceMethodB {
  TestClassB *object1 = [TestClassB new];
  [object1 st_hookInstanceMethod:@selector(instanceMethodB) option:STOptionBefore usingIdentifier:@"hook instanceMethodB before 1" withBlock:^(id<StingerParams> params){
      TestClassB_string_b = [TestClassB_string_b stringByAppendingString:@"before 1 instanceMethodB called--"];
  }];
  [object1 st_hookInstanceMethod:@selector(instanceMethodB) option:STOptionAfter usingIdentifier:@"hook instanceMethodB after 1" withBlock:^(id<StingerParams> params){
            TestClassB_string_b = [TestClassB_string_b stringByAppendingString:@"after 1 instanceMethodB called--"];
  }];
  [object1 instanceMethodB];
  NSString *TestClassB_string_b_result = @"before 1 instanceMethodB called--original instanceMethodB called--after 1 instanceMethodB called--";
  XCTAssertTrue([TestClassB_string_b isEqualToString:TestClassB_string_b_result], @"should be equal");
  
  
  [TestClassB st_hookInstanceMethod:@selector(instanceMethodB) option:STOptionBefore usingIdentifier:@"hook instanceMethodB before 1" withBlock:^(id<StingerParams> params){
      TestClassB_string_b = [TestClassB_string_b stringByAppendingString:@"before 1 instanceMethodB in class called--"];
  }];
  [TestClassB st_hookInstanceMethod:@selector(instanceMethodB) option:STOptionAfter usingIdentifier:@"hook instanceMethodB after 1" withBlock:^(id<StingerParams> params){
            TestClassB_string_b = [TestClassB_string_b stringByAppendingString:@"after 1 instanceMethodB in class called--"];
  }];
  TestClassB_string_b = @"";
  [object1 instanceMethodB];
  TestClassB_string_b_result = @"before 1 instanceMethodB in class called--before 1 instanceMethodB called--original instanceMethodB called--after 1 instanceMethodB in class called--after 1 instanceMethodB called--";
  XCTAssertTrue([TestClassB_string_b isEqualToString:TestClassB_string_b_result], @"should be equal");
  
  TestClassB *object2 = [TestClassB new];
  [object2 st_hookInstanceMethod:@selector(instanceMethodB) option:STOptionInstead usingIdentifier:@"hook instanceMethodB instead in object2" withBlock:^(id<StingerParams> params){
            TestClassB_string_b = [TestClassB_string_b stringByAppendingString:@"instead instanceMethodB in object2 called--"];
  }];
  TestClassB_string_b = @"";
  [object2 instanceMethodB];
  TestClassB_string_b_result = @"before 1 instanceMethodB in class called--instead instanceMethodB in object2 called--after 1 instanceMethodB in class called--";
  XCTAssertTrue([TestClassB_string_b isEqualToString:TestClassB_string_b_result], @"should be equal");
  
  [object2 st_removeHookWithIdentifier:@"hook instanceMethodB instead in object2" forKey:@selector(instanceMethodB)];
  TestClassB_string_b = @"";
  [object2 instanceMethodB];
  TestClassB_string_b_result = @"before 1 instanceMethodB in class called--original instanceMethodB called--after 1 instanceMethodB in class called--";
  XCTAssertTrue([TestClassB_string_b isEqualToString:TestClassB_string_b_result], @"should be equal");
  
  
  TestClassB_string_b = @"";
  [TestClassB.new instanceMethodB];
  TestClassB_string_b_result = @"before 1 instanceMethodB in class called--original instanceMethodB called--after 1 instanceMethodB in class called--";
  XCTAssertTrue([TestClassB_string_b isEqualToString:TestClassB_string_b_result], @"should be equal");
}


- (void)testInstanceMethodC {
  TestClassB *object1 = [TestClassB new];
  TestClassB *object2 = [TestClassB new];
  TestClassB *object3 = [TestClassB new];
  [object1 st_hookInstanceMethod:@selector(instanceMethodCWithNumA:numB:) option:STOptionInstead usingIdentifier:@"hook instanceMethodC instead in object1" withBlock:^double (id<StingerParams> params, double a, double b){
      return a+b+1.0;
  }];
  
  [object2 st_hookInstanceMethod:@selector(instanceMethodCWithNumA:numB:) option:STOptionInstead usingIdentifier:@"hook instanceMethodC instead in object2" withBlock:^double (id<StingerParams> params, double a, double b){
      return a+b+3.0;
  }];
  
  [TestClassB st_hookInstanceMethod:@selector(instanceMethodCWithNumA:numB:) option:STOptionInstead usingIdentifier:@"hook instanceMethodC instead" withBlock:^double (id<StingerParams> params, double a, double b){
      return a+b+2.0;
  }];
  
  double result = [object1 instanceMethodCWithNumA:1.1 numB:2.2];
  XCTAssertTrue(([[NSString stringWithFormat:@"%.1f", result] isEqualToString:@"4.3"]), @"should be equal");
  result = [object2 instanceMethodCWithNumA:1.1 numB:2.2];
  XCTAssertTrue(([[NSString stringWithFormat:@"%.1f", result] isEqualToString:@"6.3"]), @"should be equal");
  result = [object3 instanceMethodCWithNumA:1.1 numB:2.2];
  XCTAssertTrue(([[NSString stringWithFormat:@"%.1f", result] isEqualToString:@"5.3"]), @"should be equal");
  
  [object1 st_removeHookWithIdentifier:@"hook instanceMethodC instead in object1" forKey:@selector(instanceMethodCWithNumA:numB:)];
  result = [object1 instanceMethodCWithNumA:1.1 numB:2.2];
  XCTAssertTrue(([[NSString stringWithFormat:@"%.1f", result] isEqualToString:@"5.3"]), @"should be equal");
  
  [TestClassB st_removeHookWithIdentifier:@"hook instanceMethodC instead" forKey:@selector(instanceMethodCWithNumA:numB:)];
  result = [object1 instanceMethodCWithNumA:1.1 numB:2.2];
  XCTAssertTrue(([[NSString stringWithFormat:@"%.1f", result] isEqualToString:@"3.3"]), @"should be equal");
  result = [object2 instanceMethodCWithNumA:1.1 numB:2.2];
  XCTAssertTrue(([[NSString stringWithFormat:@"%.1f", result] isEqualToString:@"6.3"]), @"should be equal");
  result = [object3 instanceMethodCWithNumA:1.1 numB:2.2];
  XCTAssertTrue(([[NSString stringWithFormat:@"%.1f", result] isEqualToString:@"3.3"]), @"should be equal");
}

- (void)testInstanceMethodD {
  TestClassB *object1 = [TestClassB new];
  [object1 st_hookInstanceMethod:@selector(instanceMethodD) option:STOptionAfter | STOptionAutomaticRemoval usingIdentifier:@"hook instanceMethodD After 1" withBlock:^(id<StingerParams> params){
    NSLog(@"hook instanceMethodD After 1");
  }];
  
  [object1 st_hookInstanceMethod:@selector(instanceMethodD) option:STOptionAfter | STOptionAutomaticRemoval usingIdentifier:@"hook instanceMethodD After 2" withBlock:^(id<StingerParams> params){
    NSLog(@"hook instanceMethodD After 2");
  }];
  
  [object1 st_hookInstanceMethod:@selector(instanceMethodD) option:STOptionAfter usingIdentifier:@"hook instanceMethodD After 3" withBlock:^(id<StingerParams> params){
    NSLog(@"hook instanceMethodD After 3");
  }];
  
  [object1 st_hookInstanceMethod:@selector(instanceMethodD) option:STOptionAfter
   | STOptionAutomaticRemoval usingIdentifier:@"hook instanceMethodD After 4" withBlock:^(id<StingerParams> params){
    NSLog(@"hook instanceMethodD After 4");
  }];
  
  NSArray *allIdentifiers = [object1 st_allIdentifiersForKey:@selector(instanceMethodD)];
  XCTAssertTrue(allIdentifiers.count == 4, @"should equal");
  
  [object1 instanceMethodD];
  allIdentifiers = [object1 st_allIdentifiersForKey:@selector(instanceMethodD)];
  XCTAssertTrue(allIdentifiers.count == 1, @"should equal");
}

@end
