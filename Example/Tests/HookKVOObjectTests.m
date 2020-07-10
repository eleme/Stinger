//
//  HookKVOObjectTests.m
//  Stinger_Tests
//
//  Created by Zuopeng Liu on 2020/7/10.
//  Copyright © 2020 Assuner-Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stinger/Stinger.h>

@interface KVOObject : NSObject

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, copy) NSString *name;

@end

@implementation KVOObject

- (NSString *)methodA
{
    return @"default";
}

@end


@interface HookKVOObjectTests : XCTestCase

@property (nonatomic, strong) KVOObject *obj;

@end

@implementation HookKVOObjectTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.obj = [KVOObject new];
    [self.obj addObserver:self forKeyPath:@"index" options:NSKeyValueObservingOptionNew context:NULL];
    [self.obj addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:NULL];
    self.obj.name = @"gogogo";
    self.obj.index = 2;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [self.obj removeObserver:self forKeyPath:@"index"];
    [self.obj removeObserver:self forKeyPath:@"name"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"%@对象的%@属性改变了：%@", object, keyPath, change);
}

- (void)testInstanceHookBefore {
    __block NSInteger i = 0;
    [self.obj st_hookInstanceMethod:@selector(methodA)
                          option:STOptionBefore
                 usingIdentifier:@"hook_methodA_before"
                       withBlock:^(id<StingerParams> params) {
        i = 100;
    }];

    XCTAssertTrue(i == 0);
    [self.obj methodA];
    NSLog(@"I = %@", @(i));
    XCTAssertTrue(i == 100);
}

- (void)testInstanceHookInstead {
    XCTAssertTrue([[self.obj methodA] isEqualToString:@"default"]);
    
    [self.obj st_hookInstanceMethod:@selector(methodA)
                             option:STOptionInstead
                    usingIdentifier:@"hook_methodA_instead"
                          withBlock:^NSString* (id<StingerParams> params) {
        return @"new_return";
    }];
    
    XCTAssertTrue([[self.obj methodA] isEqualToString:@"new_return"]);
}

- (void)testInstanceHookAfter {
    __block NSInteger i = 0;
    [self.obj st_hookInstanceMethod:@selector(methodA)
                             option:STOptionAfter
                    usingIdentifier:@"hook_methodA_after"
                          withBlock:^(id<StingerParams> params) {
        i = 1000;
    }];
    
    XCTAssertTrue(i == 0);
    [self.obj methodA];
    XCTAssertTrue(i == 1000);
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
