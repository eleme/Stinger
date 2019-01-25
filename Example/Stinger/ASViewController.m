//
//  ASViewController.m
//  Stinger
//
//  Created by Assuner on 12/05/2017.
//  Copyright (c) 2017 Assuner. All rights reserved.
//

#import "ASViewController.h"
#import <Stinger/Stinger.h>
#import <Stinger/STBlock.h>
#import <objc/runtime.h>
#import "Aspects.h"

@interface ASViewController ()

@end

@implementation ASViewController

+ (void)load {
  /*
   * hook class method @selector(class_print:)
   */
  [self st_hookClassMethod:@selector(class_print:) option:STOptionBefore usingIdentifier:@"hook_class_print_before" withBlock:^(id<StingerParams> params, NSString *s) {
    NSLog(@"---before class_print: %@", s);
  }];
  
  /*
   * hook @selector(print1:)
   */
  [self st_hookInstanceMethod:@selector(print1:) option:STOptionBefore usingIdentifier:@"hook_print1_before1" withBlock:^(id<StingerParams> params, NSString *s) {
    NSLog(@"---before1 print1: %@", s);
  }];
  
  [self st_hookInstanceMethod:@selector(print1:) option:STOptionBefore usingIdentifier:@"hook_print1_before2" withBlock:^(id<StingerParams> params, NSString *s) {
    NSLog(@"---before2 print1: %@", s);
  }];
  
  [self st_hookInstanceMethod:@selector(print1:) option:STOptionAfter usingIdentifier:@"hook_print1_after1" withBlock:^(id<StingerParams> params, NSString *s) {
    NSLog(@"---after1 print1: %@", s);
  }];
  
  
  /*
   * hook @selector(print2:)
   */
  __block NSString *oldRet;
  [self st_hookInstanceMethod:@selector(print2:) option:STOptionInstead usingIdentifier:@"hook_print2_instead" withBlock:^NSString * (id<StingerParams> params, NSString *s) {
    [params invokeAndGetOriginalRetValue:&oldRet];
    NSString *newRet = [oldRet stringByAppendingString:@" ++ new-st_instead"];
    NSLog(@"---instead print2 old ret: (%@) / new ret: (%@)", oldRet, newRet);
    return newRet;
  }];
  
  
  /*
   * hook @selector(testBlock:) test block
   */
  
  [self st_hookInstanceMethod:@selector(testBlock:) option:STOptionAfter usingIdentifier:@"hook_testBlock_after1" withBlock:^(id<StingerParams> params, testBlock block) {
    NSLog(@"test block value %f", block(2, 3));
  }];
  
  
  
  // test  compatibility with like-aspects
  
  [self aspect_hookSelector:@selector(print4:) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> info, NSString *s){
    NSLog(@"aspect after1 print4 %@", s);
  } error:nil];
  
  [self st_hookInstanceMethod:@selector(print4:) option:STOptionAfter usingIdentifier:@"st_hook_print4_after1" withBlock:^(id<StingerParams> params, NSString *s) {
    NSLog(@"st hook after1 print4 %@", s);
  }];
  
  [self aspect_hookSelector:@selector(print4:) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> info, NSString *s){
    NSLog(@"aspect after2 print4 %@", s);
  } error:nil];

  [self st_hookInstanceMethod:@selector(print4:) option:STOptionAfter usingIdentifier:@"st_hook_print4_after2" withBlock:^(id<StingerParams> params, NSString *s) {
    NSLog(@"st hook after2 print4 %@", s);
  }];
  
}




- (void)viewDidLoad {
  [super viewDidLoad];
  // hook for specific instance
  [self st_hookInstanceMethod:@selector(print3:) option:STOptionAfter usingIdentifier:@"hook_print3_after1" withBlock:^(id<StingerParams> params, NSString *s) {
    NSLog(@"---specific instance-self after print3: %@", s);
  }];
  
  [self.class st_hookInstanceMethod:@selector(print3:) option:STOptionAfter usingIdentifier:@"all_hook_print3_after1" withBlock:^(id<StingerParams> params, NSString *s) {
    NSLog(@"---specific class after print3: %@", s);
  }];
}

#pragma mark - methods

+ (void)class_print:(NSString *)s {
  NSLog(@"---original class_print: %@", s);
}

- (void)print1:(NSString *)s {
  NSLog(@"---original print1: %@", s);
}

- (NSString *)print2:(NSString *)s{
  NSLog(@"---original print2: %@", s);
  return [s stringByAppendingString:@"-print2 return"];
}


- (void)testBlock:(testBlock)block {
  NSLog(@"---original testBlock %f", block(5, 15));
}

- (void)print3:(NSString *)s {
   NSLog(@"---original print3: %@", s);
}


- (void)print4:(NSString *)s {
  NSLog(@"---original print4: %@", s);
}

#pragma mark - action

- (IBAction)hookClassMethod:(id)sender {
  [self measureBlock:^{
    [ASViewController class_print:@"example"];
  } times:1];
}

- (IBAction)hookInstanceMethod1:(id)sender {
  [self measureBlock:^{
    [self print1:@"example"];
  } times:1];
}

- (IBAction)hookInstanceMethod2:(id)sender {
  NSString *newRet = [self print2:@"example"];
  NSLog(@"---print2 new ret: %@", newRet);
}

- (IBAction)testMethodWithBlockParams:(id)sender {
  [self testBlock:^double(double x, double y) {
    return x + y;
  }];
}

- (IBAction)hookForSpecificIntance:(id)sender {
  [self print3:@"---instance-self"];
  
  ASViewController *otherInstance1 = [ASViewController new];
  [otherInstance1 print3:@"---instance 1"];
  
  ASViewController *otherInstance2 = [ASViewController new];
  [otherInstance2 st_hookInstanceMethod:@selector(print3:) option:STOptionAfter usingIdentifier:@"hook_print3_after1" withBlock:^(id<StingerParams> params, NSString *s) {
    NSLog(@"---specific-instance2 after print3: %@", s);
  }];
  [otherInstance2 print3:@"---instance 2"];
  
  [self st_removeHookWithIdentifier:@"hook_print3_after1" forKey:@selector(print3:)];
}

- (IBAction)testCompatibilityWithLikeAspects:(id)sender {
  [self print4:@"ssss"];
}


#pragma mark - masure

- (NSTimeInterval)measureBlock:(void(^)(void))block times:(NSUInteger)times {
  NSDate* tmpStartDate = [NSDate date];
  if (block) {
    for (int i = 0; i < times; i++) {
      block();
    }
  }
  NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:tmpStartDate] * 1000.0 / times;
  NSLog(@"*** %f ms", time);
  return time;
}

@end
