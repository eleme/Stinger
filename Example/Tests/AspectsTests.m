//
//  AspectsTests.m
//  Stinger_Tests
//
//  Created by 李永光 on 2020/2/9.
//  Copyright © 2020 Assuner-Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Aspects/Aspects.h>
#import <objc/runtime.h>

@interface TestClassE : NSObject
+ (void)methodA;
- (void)methodB;
@end

@implementation TestClassE
+ (void)methodA {
  
}

- (void)methodB {
  
}
@end


@interface AspectsTests : XCTestCase
@end

@implementation AspectsTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
  [object_getClass(TestClassE.class) aspect_hookSelector:@selector(methodA) withOptions:AspectPositionAfter usingBlock:^(id aspectInfo) {
    
  } error:nil];
  
  [TestClassE.class aspect_hookSelector:@selector(methodB) withOptions:AspectPositionAfter usingBlock:^(id aspectInfo) {
    
  } error:nil];
  
  [TestClassE methodA];
  [TestClassE.new methodB];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
