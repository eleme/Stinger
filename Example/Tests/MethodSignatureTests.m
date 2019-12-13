//
//  MethodSignatureTests.m
//  Stinger_Tests
//
//  Created by 李永光 on 2019/12/5.
//  Copyright © 2019 Assuner-Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stinger/STMethodSignature.h>
#import <Stinger/STHookInfoPool.h>
#import <objc/runtime.h>

@interface MethodSignatureTests : XCTestCase
@end

NSString *getTpyeEncoding(Class cls, SEL sel) {
    Method m = class_getInstanceMethod(cls, sel);
    const char * typeEncoding = method_getTypeEncoding(m);
    return [NSString stringWithUTF8String:typeEncoding];
}

BOOL stringArrayIsEqual(NSArray<NSString *> *a, NSArray<NSString *> *b) {
    BOOL result = YES;
    if (a.count == b.count) {
        for (NSInteger i = 0; i < a.count; i++) {
            if (![a[i] isEqualToString:b[i]]) {
                result = NO;
            }
        }
    } else {
        result = NO;
    }
    return result;
}

@implementation MethodSignatureTests

#define GET_TYPE_ENCODING(sel) getTpyeEncoding(self.class, @selector(sel))
- (void)testSignatureForMethod {
    STMethodSignature *st_signature;
    BOOL pass;

    st_signature = [[STMethodSignature alloc] initWithObjCTypes:GET_TYPE_ENCODING(methodA)];
    XCTAssertTrue([st_signature.types isEqualToString:GET_TYPE_ENCODING(methodA)], @"should equal");
    pass = [st_signature.returnType isEqualToString:@"v"] && stringArrayIsEqual(st_signature.argumentTypes, @[@"@", @":"]);
    XCTAssertTrue(pass, @"should equal");
    
    st_signature = [[STMethodSignature alloc] initWithObjCTypes:GET_TYPE_ENCODING(methodB:)];
    pass = [st_signature.returnType isEqualToString:@"@"] && stringArrayIsEqual(st_signature.argumentTypes, @[@"@", @":", @"@"]);
    XCTAssertTrue(pass, @"should equal");
    
    st_signature = [[STMethodSignature alloc] initWithObjCTypes:GET_TYPE_ENCODING(methodC:)];
    pass = [st_signature.returnType isEqualToString:@"v"] && stringArrayIsEqual(st_signature.argumentTypes, @[@"@", @":", @"@?"]);
    XCTAssertTrue(pass, @"should equal");
    
    st_signature = [[STMethodSignature alloc] initWithObjCTypes:GET_TYPE_ENCODING(methodD:)];
    pass = [st_signature.returnType isEqualToString:@"v"] && stringArrayIsEqual(st_signature.argumentTypes, @[@"@", @":", @"@?"]);
    XCTAssertTrue(pass, @"should equal");
    
    st_signature = [[STMethodSignature alloc] initWithObjCTypes:GET_TYPE_ENCODING(methodE:)];
    pass = [st_signature.returnType isEqualToString:@"{CGPoint=dd}"] && stringArrayIsEqual(st_signature.argumentTypes, @[@"@", @":", @"q"]);
    XCTAssertTrue(pass, @"should equal");
  

    st_signature = [[STMethodSignature alloc] initWithObjCTypes:GET_TYPE_ENCODING(methodF:)];
    pass = [st_signature.returnType isEqualToString:@"{CGRect={CGPoint=dd}{CGSize=dd}}"] && stringArrayIsEqual(st_signature.argumentTypes, @[@"@", @":", @"{CGRect={CGPoint=dd}{CGSize=dd}}"]);
    XCTAssertTrue(pass, @"should equal");
}


- (void)testSignatureForBlock {
    STMethodSignature *st_signature;
    BOOL pass;
    
    id block = ^{
        
    };
    st_signature = [[STMethodSignature alloc] initWithObjCTypes:st_getSignatureForBlock(block)];
    pass = [st_signature.returnType isEqualToString:@"v"] && stringArrayIsEqual(st_signature.argumentTypes, @[@"@?"]);
    XCTAssertTrue(pass, @"should equal");
    
    
    block = ^NSString *(NSString *str){
        return @"xxx";
    };
    st_signature = [[STMethodSignature alloc] initWithObjCTypes:st_getSignatureForBlock(block)];
    pass = [st_signature.returnType isEqualToString:@"@"] && stringArrayIsEqual(st_signature.argumentTypes, @[@"@?", @"@"]);
    XCTAssertTrue(pass, @"should equal");
    
    block = ^NSInteger (int a, float b) {
        return a+b;
    };
    st_signature = [[STMethodSignature alloc] initWithObjCTypes:st_getSignatureForBlock(block)];
    pass = [st_signature.returnType isEqualToString:@"q"] && stringArrayIsEqual(st_signature.argumentTypes, @[@"@?", @"i", @"f"]);
    XCTAssertTrue(pass, @"should equal");
    
    block = ^NSInteger (id<NSCopying> object) {
        return 1;
    };
    st_signature = [[STMethodSignature alloc] initWithObjCTypes:st_getSignatureForBlock(block)];
    pass = [st_signature.returnType isEqualToString:@"q"] && stringArrayIsEqual(st_signature.argumentTypes, @[@"@?", @"@"]);
    XCTAssertTrue(pass, @"should equal");
    
    
    block = ^NSUInteger (void(^aBlock)(NSString *)) {
           return 1;
       };
    st_signature = [[STMethodSignature alloc] initWithObjCTypes:st_getSignatureForBlock(block)];
    pass = [st_signature.returnType isEqualToString:@"Q"] && stringArrayIsEqual(st_signature.argumentTypes, @[@"@?", @"@?"]);
    XCTAssertTrue(pass, @"should equal");
    
    block = ^NSUInteger (void(^aBlock)(void(^blockParams)(NSString *x))) {
           return 1;
    };
    st_signature = [[STMethodSignature alloc] initWithObjCTypes:st_getSignatureForBlock(block)];
    pass = [st_signature.returnType isEqualToString:@"Q"] && stringArrayIsEqual(st_signature.argumentTypes, @[@"@?", @"@?"]);
    XCTAssertTrue(pass, @"should equal");
    
    block = ^NSUInteger (void(^aBlock)(void(^blockParams)(NSString<NSCopying> *x))) {
           return 1;
    };
    st_signature = [[STMethodSignature alloc] initWithObjCTypes:st_getSignatureForBlock(block)];
    pass = [st_signature.returnType isEqualToString:@"Q"] && stringArrayIsEqual(st_signature.argumentTypes, @[@"@?", @"@?"]);
    XCTAssertTrue(pass, @"should equal");
    
    block = ^NSUInteger (CGPoint point) {
           return 1;
    };
    st_signature = [[STMethodSignature alloc] initWithObjCTypes:st_getSignatureForBlock(block)];
    pass = [st_signature.returnType isEqualToString:@"Q"] && stringArrayIsEqual(st_signature.argumentTypes, @[@"@?", @"{CGPoint=dd}"]);
    XCTAssertTrue(pass, @"should equal");
    
    block = ^CGRect (CGPoint point) {
        return CGRectMake(1, 2, 3, 4);
    };
    st_signature = [[STMethodSignature alloc] initWithObjCTypes:st_getSignatureForBlock(block)];
    pass = [st_signature.returnType isEqualToString:@"{CGRect={CGPoint=dd}{CGSize=dd}}"] && stringArrayIsEqual(st_signature.argumentTypes, @[@"@?", @"{CGPoint=dd}"]);
    XCTAssertTrue(pass, @"should equal");
  
    block = ^CGRect (CGRect rect) {
        return CGRectMake(1, 2, 3, 4);
    };
    st_signature = [[STMethodSignature alloc] initWithObjCTypes:st_getSignatureForBlock(block)];
    pass = [st_signature.returnType isEqualToString:@"{CGRect={CGPoint=dd}{CGSize=dd}}"] && stringArrayIsEqual(st_signature.argumentTypes, @[@"@?", @"{CGRect={CGPoint=dd}{CGSize=dd}}"]);
    XCTAssertTrue(pass, @"should equal");
    
    block = ^NSUInteger (void *pointer) {
        return 1;
    };
    st_signature = [[STMethodSignature alloc] initWithObjCTypes:st_getSignatureForBlock(block)];
    pass = [st_signature.returnType isEqualToString:@"Q"] && stringArrayIsEqual(st_signature.argumentTypes, @[@"@?", @"^v"]);
    XCTAssertTrue(pass, @"should equal");
    
    block = ^NSUInteger (SEL sel) {
        return 1;
    };
    st_signature = [[STMethodSignature alloc] initWithObjCTypes:st_getSignatureForBlock(block)];
    pass = [st_signature.returnType isEqualToString:@"Q"] && stringArrayIsEqual(st_signature.argumentTypes, @[@"@?", @":"]);
    XCTAssertTrue(pass, @"should equal");
}



#pragma mark - Example method

- (void)methodA {
    
}

- (NSString *)methodB:(NSString *)str {
    return @"xxx";
}

- (void)methodC:(void(^)(void))block {
    
}

- (void)methodD:(NSString *(^)(void(^aBlock)(NSString *str)))block {
    
}

- (CGPoint)methodE:(NSInteger)num {
    return CGPointZero;
}

- (CGRect)methodF:(CGRect)rect {
   return CGRectZero;
}

@end
