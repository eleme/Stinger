//
//  BlockSignature.m
//  Stinger_Tests
//
//  Created by 李永光 on 2019/12/6.
//  Copyright © 2019 Assuner-Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stinger/STBlock.h>

@interface BlockTests : XCTestCase

@end


@implementation BlockTests

- (void)testBlock {
    id block;
    
    block = ^NSString *(NSString *str){
        return [str stringByAppendingString:@"-xxx"];
    };
    
    NSString *sig = [block signature];
    XCTAssertTrue([sig isEqualToString:@"@\"NSString\"16@?0@\"NSString\"8"], @"should be equal");
    
    IMP imp = [block blockIMP];
    NSString *(*fun)(id block, NSString *str) = (NSString *(*)(id block, NSString *str))imp;
    NSString *strResult = fun(nil, @"str");
    XCTAssertTrue([strResult isEqualToString:@"str-xxx"], @"should be equal");
}


@end
