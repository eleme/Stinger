//
//  ASViewController.m
//  Stinger
//
//  Created by Assuner on 12/05/2017.
//  Copyright (c) 2017 Assuner. All rights reserved.
//

#import "ASViewController.h"
#import <Stinger/Stinger.h>
#import <Stinger/ffi.h>
#import <Stinger/STBlock.h>
#import <objc/runtime.h>

@interface ASViewController ()

@end

@implementation ASViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // hook for specific instance
  [self st_hookInstanceMethod:@selector(print3:) option:STOptionAfter usingIdentifier:@"hook_print3_after1" withBlock:^(id<StingerParams> params, NSString *s) {
    NSLog(@"---instance after print3: %@", s);
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
  [self print3:@"---instance 0"];
  
  ASViewController *otherInstance1 = [ASViewController new];
  [otherInstance1 print3:@"---instance 1"];
  
  ASViewController *otherInstance2 = [ASViewController new];
  [otherInstance2 st_hookInstanceMethod:@selector(print3:) option:STOptionAfter usingIdentifier:@"hook_print3_after1" withBlock:^(id<StingerParams> params, NSString *s) {
    NSLog(@"---instance2 after print3: %@", s);
  }];
  [otherInstance2 print3:@"---instance 2"];
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
