//
//  hookForSpecificClassTests.m
//  Stinger_Tests
//
//  Created by 李永光 on 2019/12/5.
//  Copyright © 2019 Assuner-Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stinger/Stinger.h>

typedef struct  {
  NSInteger a;
  NSInteger b;
} structA;

typedef struct {
  NSInteger a;
  NSInteger b;
  double c;
  structA structVar;
} structB;


@interface TestClassA : NSObject
- (void)instanceMethodA;
- (void)instanceMethodBWithText:(NSString *)str;
- (NSInteger)instanceMethodCWithNumA:(NSInteger)a numB:(NSInteger)b;
- (NSString *)instanceMethodDWithText:(NSString *)str;
- (void)instanceMethodEWithBlock:(NSString *(^)(NSString *))block;
- (SEL)instanceMethodFWithSelector:(SEL)sel;
- (CGRect)instanceGWithRect:(CGRect)rect;
- (structB)instanceHWithStruct:(structB)rect;
- (CGSize)instanceIWithSize:(CGSize)size;
+ (NSInteger)classMethodAWithNumA:(NSInteger)a numB:(NSInteger)b;
@end

@implementation TestClassA

static NSString *TestClassA_string_a = @"";

- (void)instanceMethodA {
    TestClassA_string_a = [TestClassA_string_a stringByAppendingString:@"original instanceMethodA called--"];
}

- (void)instanceMethodBWithText:(NSString *)str {
    TestClassA_string_a = [TestClassA_string_a stringByAppendingString:[NSString stringWithFormat:@"original instanceMethodBWithText: called, params:%@--", str]];
}

- (NSInteger)instanceMethodCWithNumA:(NSInteger)a numB:(NSInteger)b {
    return a + b;
}

- (NSString *)instanceMethodDWithText:(NSString *)str {
    return [NSString stringWithFormat:@"original instanceMethodDWithText: called, params:%@--", str];
}

- (void)instanceMethodEWithBlock:(NSString *(^)(NSString *))block {
    
}

- (SEL)instanceMethodFWithSelector:(SEL)sel {
    return sel;
}

- (CGRect)instanceGWithRect:(CGRect)rect {
    return CGRectMake(1, 2, 3, rect.size.height);
}

- (structB)instanceHWithStruct:(structB)rect {
  return rect;
}

- (CGSize)instanceIWithSize:(CGSize)size {
  return size;
}


+ (NSInteger)classMethodAWithNumA:(NSInteger)a numB:(NSInteger)b {
    return a+b;
}


@end


@interface HookForSpecificClassTests : XCTestCase

@end

@implementation HookForSpecificClassTests

- (void)setUp {
   TestClassA_string_a = @"";
}

- (void)tearDown {
    
}


- (void)testHookInstanceMethodA {
    [TestClassA st_hookInstanceMethod:@selector(instanceMethodA) option:STOptionBefore usingIdentifier:@"hook InstanceMethodA before 1" withBlock:^(id<StingerParams> params){
        TestClassA_string_a = [TestClassA_string_a stringByAppendingString:@"before 1 instanceMethodA called--"];
    }];
    
    
    [TestClassA st_hookInstanceMethod:@selector(instanceMethodA) option:STOptionBefore usingIdentifier:@"hook InstanceMethodA before 2" withBlock:^(id<StingerParams> params){
           TestClassA_string_a = [TestClassA_string_a stringByAppendingString:@"before 2 instanceMethodA called--"];
    }];
    
    
    [TestClassA st_hookInstanceMethod:@selector(instanceMethodA) option:STOptionAfter usingIdentifier:@"hook InstanceMethodA after 1" withBlock:^(id<StingerParams> params){
              TestClassA_string_a = [TestClassA_string_a stringByAppendingString:@"after 1 instanceMethodA called--"];
    }];
    
    [TestClassA st_hookInstanceMethod:@selector(instanceMethodA) option:STOptionAfter usingIdentifier:@"hook InstanceMethodA after 2" withBlock:^(id<StingerParams> params){
              TestClassA_string_a = [TestClassA_string_a stringByAppendingString:@"after 2 instanceMethodA called--"];
    }];
    
    [[TestClassA new] instanceMethodA];
    NSString *TestClassA_string_a_result = @"before 1 instanceMethodA called--before 2 instanceMethodA called--original instanceMethodA called--after 1 instanceMethodA called--after 2 instanceMethodA called--";
    XCTAssertTrue([TestClassA_string_a isEqualToString:TestClassA_string_a_result], @"should be equal");
    
    NSArray <STIdentifier> *allHookIdentifiers = [TestClassA st_allIdentifiersForKey:@selector(instanceMethodA)];
    
    XCTAssertTrue(allHookIdentifiers.count == 4, @"should be 4");
}


- (void)testInstanceMethodB {
    [TestClassA st_hookInstanceMethod:@selector(instanceMethodBWithText:) option:STOptionBefore usingIdentifier:@"hook instanceMethodBWithText: before 1" withBlock:^(id<StingerParams> params, NSString *str) {
        TestClassA_string_a = [TestClassA_string_a stringByAppendingString:[NSString stringWithFormat:@"before 1 instanceMethodBWithText: called, params:%@--", str]];
    }];
    
    
    [TestClassA st_hookInstanceMethod:@selector(instanceMethodBWithText:) option:STOptionAfter usingIdentifier:@"hook instanceMethodBWithText: after 1" withBlock:^(id<StingerParams> params, NSString *str) {
              TestClassA_string_a = [TestClassA_string_a stringByAppendingString:[NSString stringWithFormat:@"after 1 instanceMethodBWithText: called, params:%@--", str]];
    }];
    
    TestClassA *objectA = [TestClassA new];
    [objectA instanceMethodBWithText:@"xxx"];
    NSString *TestClassA_string_a_result = @"before 1 instanceMethodBWithText: called, params:xxx--original instanceMethodBWithText: called, params:xxx--after 1 instanceMethodBWithText: called, params:xxx--";
    XCTAssertTrue([TestClassA_string_a isEqualToString:TestClassA_string_a_result], @"should be equal");
    
    [TestClassA st_removeHookWithIdentifier:@"hook instanceMethodBWithText: before 1" forKey:@selector(instanceMethodBWithText:)];
    [TestClassA st_removeHookWithIdentifier:@"hook instanceMethodBWithText: after 1" forKey:@selector(instanceMethodBWithText:)];
    
    TestClassA_string_a = @"";
    [objectA instanceMethodBWithText:@"ccc"];
    TestClassA_string_a_result = @"original instanceMethodBWithText: called, params:ccc--";
    XCTAssertTrue([TestClassA_string_a isEqualToString:TestClassA_string_a_result], @"should be equal");
}


- (void)testInstanceMethodC {
    TestClassA *objectA = [TestClassA new];
    NSInteger result;
    
    [TestClassA st_hookInstanceMethod:@selector(instanceMethodCWithNumA:numB:) option:STOptionBefore usingIdentifier:@"hook instanceMethodCWithNumA:numB: before 1" withBlock:^(id<StingerParams> params, NSInteger a, NSInteger b) {
         TestClassA_string_a = [TestClassA_string_a stringByAppendingString:[NSString stringWithFormat:@"before 1 instanceMethodCWithNumA:numB: called, params:%zd %zd--", a, b]];
    }];
    
    [TestClassA st_hookInstanceMethod:@selector(instanceMethodCWithNumA:numB:) option:STOptionInstead usingIdentifier:@"hook instanceMethodCWithNumA:numB: instead" withBlock:^NSInteger (id<StingerParams> params, NSInteger a, NSInteger b) {
        NSInteger oldRet;
        [params invokeAndGetOriginalRetValue:&oldRet];
        return (oldRet + 1);
    }];
    
    [TestClassA st_hookInstanceMethod:@selector(instanceMethodCWithNumA:numB:) option:STOptionAfter usingIdentifier:@"hook instanceMethodCWithNumA:numB: after 1" withBlock:^(id<StingerParams> params, NSInteger a, NSInteger b) {
         TestClassA_string_a = [TestClassA_string_a stringByAppendingString:[NSString stringWithFormat:@"after 1 instanceMethodCWithNumA:numB: called, params:%zd %zd--", a, b]];
    }];
    
//    [TestClassA aspect_hookSelector:@selector(instanceMethodCWithNumA:numB:) withOptions:AspectPositionInstead usingBlock:^NSInteger (id<AspectInfo> params, NSInteger a, NSInteger b) {
//        NSInteger oldRet;
//        NSInteger newRet;
//        NSInvocation *invocation = params.originalInvocation;
//        [invocation invoke];
//        [invocation getReturnValue:&oldRet];
//        newRet = (oldRet + 1);
//        return newRet;
//    } error:nil];
    
    result = [objectA instanceMethodCWithNumA:1 numB:2];
    XCTAssertTrue(result == 4, @"should be 4");
    
    NSString *TestClassA_string_a_result = @"before 1 instanceMethodCWithNumA:numB: called, params:1 2--after 1 instanceMethodCWithNumA:numB: called, params:1 2--";
    XCTAssertTrue([TestClassA_string_a isEqualToString:TestClassA_string_a_result], @"should be equal");
    
    [TestClassA st_removeHookWithIdentifier:@"hook instanceMethodCWithNumA:numB: instead" forKey:@selector(instanceMethodCWithNumA:numB:)];
    
    result = [objectA instanceMethodCWithNumA:1 numB:2];
    XCTAssertTrue(result == 3, @"should be 3");
}


- (void)testInstanceMethodD {
    __block NSString *newRet, *oldRet;
    [TestClassA st_hookInstanceMethod:@selector(instanceMethodDWithText:) option:STOptionInstead usingIdentifier:@"hook instanceMethodDWithText: instead" withBlock:^NSString *(id <StingerParams> params, NSString *str) {
//        NSString *oldRet;
        [params invokeAndGetOriginalRetValue:&oldRet];
        newRet = [oldRet stringByAppendingFormat:@"instead instanceMethodDWithText:called, params:%@--", str];
        return newRet;
    }];
    
    NSString *ret = [[TestClassA new] instanceMethodDWithText:@"xxx"];
    NSString *shouldResult = @"original instanceMethodDWithText: called, params:xxx--instead instanceMethodDWithText:called, params:xxx--";
    BOOL beEqual = [ret isEqualToString:shouldResult];
    XCTAssertTrue(beEqual, @"should be equal");
}

- (void)testInstanceMethodE {
    __block NSString *str;
    [TestClassA st_hookInstanceMethod:@selector(instanceMethodEWithBlock:) option:STOptionAfter usingIdentifier:@"after hook instanceMethodEWithBlock:" withBlock:^(id<StingerParams> params, NSString *(^block)(NSString *)) {
        str = block(@"hello");
    }];
    
    [[TestClassA new] instanceMethodEWithBlock:^NSString *(NSString *str) {
        return [str stringByAppendingFormat:@"-xxx"];
    }];
    
    BOOL beEqual = [str isEqualToString:@"hello-xxx"];
    XCTAssertTrue(beEqual, @"should be equal");
}


- (void)testClassMethodA {
    [TestClassA st_hookClassMethod:@selector(classMethodAWithNumA:numB:) option:STOptionBefore usingIdentifier:@"hook classMethodAWithNumA:numB: before 1" withBlock:^(id<StingerParams> params, NSInteger a, NSInteger b) {
             TestClassA_string_a = [TestClassA_string_a stringByAppendingString:[NSString stringWithFormat:@"before 1 classMethodAWithNumA:numB: called, params:%zd %zd--", a, b]];
        }];
        
    [TestClassA st_hookClassMethod:@selector(classMethodAWithNumA:numB:) option:STOptionInstead usingIdentifier:@"hook classMethodAWithNumA:numB: instead" withBlock:^NSInteger (id<StingerParams> params, NSInteger a, NSInteger b) {
        NSInteger oldRet;
        [params invokeAndGetOriginalRetValue:&oldRet];
        return (oldRet + 1);
    }];
    
    [TestClassA st_hookClassMethod:@selector(classMethodAWithNumA:numB:) option:STOptionAfter usingIdentifier:@"hook classMethodAWithNumA:numB: after 1" withBlock:^(id<StingerParams> params, NSInteger a, NSInteger b) {
         TestClassA_string_a = [TestClassA_string_a stringByAppendingString:[NSString stringWithFormat:@"after 1 classMethodAWithNumA:numB: called, params:%zd %zd--", a, b]];
    }];
    
    NSInteger result;
    result = [TestClassA classMethodAWithNumA:1 numB:2];
    XCTAssertTrue(result == 4, @"should be 4");
    NSString *TestClassA_string_a_result = @"before 1 classMethodAWithNumA:numB: called, params:1 2--after 1 classMethodAWithNumA:numB: called, params:1 2--";
    XCTAssertTrue([TestClassA_string_a isEqualToString:TestClassA_string_a_result], @"should be equal");
    
    [TestClassA st_removeHookWithIdentifier:@"hook classMethodAWithNumA:numB: instead" forKey:@selector(classMethodAWithNumA:numB:)];
    
    result = [TestClassA classMethodAWithNumA:1 numB:2];
    XCTAssertTrue(result == 3, @"should be 3");
}


- (void)testInstanceMethodF {
    [TestClassA st_hookInstanceMethod:@selector(instanceMethodFWithSelector:) option:STOptionInstead usingIdentifier:@"instead hook instanceMethodFWithSelector:" withBlock:^SEL(id<StingerParams> params, SEL sel){
        return NSSelectorFromString([@"test_" stringByAppendingString:NSStringFromSelector(sel)]);
    }];
    
    SEL newRetSel = [[TestClassA new] instanceMethodFWithSelector:@selector(instanceMethodA)];
    XCTAssertTrue(newRetSel == NSSelectorFromString(@"test_instanceMethodA"), @"should be 3");
}


- (void)testClassMethodG {
   [TestClassA st_hookInstanceMethod:@selector(instanceGWithRect:) option:STOptionInstead usingIdentifier:@"instead hook instanceGWithRect:" withBlock:^CGRect(id<StingerParams> params, CGRect rect){
     CGRect oldValue;
     [params invokeAndGetOriginalRetValue:&oldValue];
     return CGRectMake(1, 2, 3, oldValue.size.height+1);
   }];
  
  CGRect result = [[TestClassA new] instanceGWithRect:CGRectMake(2, 2, 2, 4)];
  XCTAssertTrue(CGRectEqualToRect(result, CGRectMake(1, 2, 3, 5)), @"should be equal");
}


- (void)testInstanceMethodH {
  [TestClassA st_hookInstanceMethod:@selector(instanceHWithStruct:) option:STOptionInstead usingIdentifier:@"instead hook instanceHWithStruct:" withBlock:^structB(id<StingerParams> params, structB rect) {
    structB oldValue;
    [params invokeAndGetOriginalRetValue:&oldValue];
    oldValue.a++;
    return oldValue;
  }];
  
  structB arg;
  arg.a = 1;
  arg.b = 2;
  arg.c = 1.1;
  structA structVar;
  structVar.a = 3;
  structVar.b = 4;
  arg.structVar = structVar;
  structB result = [[TestClassA new] instanceHWithStruct:arg];
  XCTAssertTrue(result.a == 2, @"should be equal");
}


- (void)testInstanceMethodI {
  [TestClassA st_hookInstanceMethod:@selector(instanceIWithSize:) option:STOptionInstead usingIdentifier:@"instead hook instanceHWithStruct:" withBlock:^CGSize(id<StingerParams> params, CGSize size) {
    CGSize oldValue;
    [params invokeAndGetOriginalRetValue:&oldValue];
    oldValue.width++;
    return oldValue;
  }];
  
  CGSize result = [[TestClassA new] instanceIWithSize:CGSizeMake(1, 1)];
  XCTAssertTrue(CGSizeEqualToSize(result, CGSizeMake(2, 1)), @"should be equal");
}


@end
