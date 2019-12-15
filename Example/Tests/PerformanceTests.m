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
- (void)methodBeforeA;
- (void)methodA;
- (void)methodAfterA;

- (void)methodA1;
- (void)methodB1;

- (void)methodA2;
- (void)methodB2;

- (void)methodA3:(NSString *)str num:(double)num rect:(CGRect)rect;
- (void)methodB3:(NSString *)str num:(double)num rect:(CGRect)rect;

- (NSString *)methodA4;
- (NSString *)methodB4;

- (NSString *)methodA5:(NSString *)str num:(double)num rect:(CGRect)rect;
- (NSString *)methodB5:(NSString *)str num:(double)num rect:(CGRect)rect;



- (NSString *)methodC:(NSString *)str;
- (NSString *)methodD:(NSString *)str;
@end

@implementation TestClassC

- (void)methodBeforeA {
}

- (void)methodA {
}

- (void)methodAfterA {
}


- (void)methodA1 {
}

- (void)methodB1 {
}


- (void)methodA2 {
}

- (void)methodB2 {
}


- (void)methodA3:(NSString *)str num:(double)num rect:(CGRect)rect {
  
}

- (void)methodB3:(NSString *)str num:(double)num rect:(CGRect)rect {
  
}

- (NSString *)methodA4 {
  return @"";
}

- (NSString *)methodB4 {
  return @"";
}

- (NSString *)methodA5:(NSString *)str num:(double)num rect:(CGRect)rect {
  return @"";
}

- (NSString *)methodB5:(NSString *)str num:(double)num rect:(CGRect)rect {
  return @"";
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


- (void)testaBlankMethod {
  [self measureBlock:^{
    for (NSInteger i = 0; i < 1000000; i++) {
      
    }
  }];
}

- (void)testMethodA {
  TestClassC *object1 = [TestClassC new];
  [self measureBlock:^{
    for (NSInteger i = 0; i < 1000000; i++) {
      [object1 methodBeforeA];
      [object1 methodA];
      [object1 methodAfterA];
    }
  }];
}

- (void)testStingerHookMethodA1 {
  [TestClassC st_hookInstanceMethod:@selector(methodA1) option:STOptionBefore usingIdentifier:@"hook methodA1 before" withBlock:^(id<StingerParams> params) {
     }];
  [TestClassC st_hookInstanceMethod:@selector(methodA1) option:STOptionAfter usingIdentifier:@"hook methodA1 After" withBlock:^(id<StingerParams> params) {
  }];
  
  TestClassC *object1 = [TestClassC new];
  [self measureBlock:^{
    for (NSInteger i = 0; i < 1000000; i++) {
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
    for (NSInteger i = 0; i < 1000000; i++) {
      [object1 methodB1];
    }
  }];
}

- (void)testStingerHookMethodA2 {
  TestClassC *object1 = [TestClassC new];
  [object1 st_hookInstanceMethod:@selector(methodA2) option:STOptionBefore usingIdentifier:@"hook methodA2 before" withBlock:^(id<StingerParams> params) {
     }];
  [object1 st_hookInstanceMethod:@selector(methodA2) option:STOptionAfter usingIdentifier:@"hook methodA2 After" withBlock:^(id<StingerParams> params) {
  }];
  
  [self measureBlock:^{
    for (NSInteger i = 0; i < 1000000; i++) {
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
    for (NSInteger i = 0; i < 1000000; i++) {
      [object1 methodB2];
    }
  }];
}


- (void)testOne {
  [self measureBlock:^{
    for (NSInteger i = 0; i < 1000000; i++) {
      NSString *str = @"";
      double num = 0.1;
      CGRect rect = CGRectMake(1, 1, 1.1, 1.1);
    }
  }];
}


- (void)testMethodA3 {
  [TestClassC st_hookInstanceMethod:@selector(methodA3:num:rect:) option:STOptionBefore usingIdentifier:@"hook methodA3 before" withBlock:^(id<StingerParams> params, NSString *str, double num, CGRect rect) {
     }];
  [TestClassC st_hookInstanceMethod:@selector(methodA3:num:rect:) option:STOptionAfter usingIdentifier:@"hook methodA3 After" withBlock:^(id<StingerParams> params, NSString *str, double num, CGRect rect) {
  }];
  
  TestClassC *object1 = [TestClassC new];
  NSString *str = @"";
  double num = 0.1;
  CGRect rect = CGRectMake(1, 1, 1.1, 1.1);
  [self measureBlock:^{
    for (NSInteger i = 0; i < 1000000; i++) {
      [object1 methodA3:str num:num rect:rect];
    }
  }];
}



- (void)testMethodB3 {
  [TestClassC aspect_hookSelector:@selector(methodB3:num:rect:) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> params, NSString *str, double num, CGRect rect) {
    } error:nil];
   [TestClassC aspect_hookSelector:@selector(methodB3:num:rect:) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> params, NSString *str, double num, CGRect rect) {
   } error:nil];
  
  TestClassC *object1 = [TestClassC new];
  NSString *str = @"";
  double num = 0.1;
   CGRect rect = CGRectMake(1, 1, 1.1, 1.1);
   [self measureBlock:^{
     for (NSInteger i = 0; i < 1000000; i++) {
       [object1 methodB3:str num:num rect:rect];
     }
   }];
}


- (void)testMethodA4 {
  [TestClassC st_hookInstanceMethod:@selector(methodA4) option:STOptionBefore usingIdentifier:@"hook methodA4 before" withBlock:^(id<StingerParams> params) {
     }];
  [TestClassC st_hookInstanceMethod:@selector(methodA4) option:STOptionAfter usingIdentifier:@"hook methodA4 After" withBlock:^(id<StingerParams> params) {
  }];
  
  TestClassC *object1 = [TestClassC new];
  [self measureBlock:^{
    for (NSInteger i = 0; i < 1000000; i++) {
    [object1 methodA4];
    }
  }];
}


- (void)testMethodB4 {
  [TestClassC aspect_hookSelector:@selector(methodB4) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> params) {
    } error:nil];
   [TestClassC aspect_hookSelector:@selector(methodB4) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> params) {
   } error:nil];
   
   TestClassC *object1 = [TestClassC new];
   [self measureBlock:^{
     for (NSInteger i = 0; i < 1000000; i++) {
       [object1 methodB4];
     }
   }];
}


- (void)testMethodA5 {
  [TestClassC st_hookInstanceMethod:@selector(methodA5:num:rect:) option:STOptionBefore usingIdentifier:@"hook methodA5 before" withBlock:^(id<StingerParams> params, NSString *str, double num, CGRect rect) {
      }];
   [TestClassC st_hookInstanceMethod:@selector(methodA5:num:rect:) option:STOptionAfter usingIdentifier:@"hook methodA5 After" withBlock:^(id<StingerParams> params, NSString *str, double num, CGRect rect) {
   }];
   
   TestClassC *object1 = [TestClassC new];
   NSString *str = @"";
   double num = 0.1;
   CGRect rect = CGRectMake(1, 1, 1.1, 1.1);
   [self measureBlock:^{
     for (NSInteger i = 0; i < 1000000; i++) {
       [object1 methodA5:str num:num rect:rect];
     }
   }];
}


- (void)testMethodB5 {
  [TestClassC aspect_hookSelector:@selector(methodB5:num:rect:) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> params, NSString *str, double num, CGRect rect) {
    } error:nil];
   [TestClassC aspect_hookSelector:@selector(methodB5:num:rect:) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> params, NSString *str, double num, CGRect rect) {
   } error:nil];
  
  TestClassC *object1 = [TestClassC new];
  NSString *str = @"";
  double num = 0.1;
   CGRect rect = CGRectMake(1, 1, 1.1, 1.1);
   [self measureBlock:^{
     for (NSInteger i = 0; i < 1000000; i++) {
       [object1 methodB5:str num:num rect:rect];
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
    for (NSInteger i = 0; i < 1000000; i++) {
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
    for (NSInteger i = 0; i < 1000000; i++) {
      result = [object1 methodD:@""];
    }
  }];
}
@end
