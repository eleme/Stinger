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

- (IBAction)execute_class_print:(id)sender;
- (IBAction)execute_print1:(id)sender;
- (IBAction)execute_print2:(id)sender;
- (IBAction)execute_print3:(id)sender;

@end

@implementation ASViewController

- (void)print1:(NSString *)s{
  NSLog(@"---original print1: %@", s);
}

- (NSString *)print2:(NSString *)s{
  NSLog(@"---original print2: %@", s);
  return [s stringByAppendingString:@"-print2 return"];
}

- (void)print3:(NSString *)s{
  NSLog(@"---original print1: %@", s);
}

- (void)testBlock:(testBlock)block {
  NSLog(@"---original testBlock %f", block(5, 15));
}

+ (void)class_print:(NSString *)s {
  NSLog(@"---original class_print: %@", s);
}


#pragma - action

- (IBAction)execute_class_print:(id)sender {
  [self measureBlock:^{
    [ASViewController class_print:@"example"];
  } times:10];
}

- (IBAction)execute_print1:(id)sender {
  [self measureBlock:^{
    [self print1:@"example"];
  } times:100];
}

- (IBAction)execute_print2:(id)sender {
  [self measureBlock:^{
    NSString *newRet = [self print2:@"example"];
    NSLog(@"---print2 new ret: %@", newRet);
  } times:10];
}

- (IBAction)execute_print3:(id)sender {
  [self testBlock:^double(double x, double y) {
    return x + y;
  }];
}

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
