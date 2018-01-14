//
//  ASViewController.m
//  Stinger
//
//  Created by Assuner on 12/05/2017.
//  Copyright (c) 2017 Assuner. All rights reserved.
//

#import "ASViewController.h"
#import "Stinger.h"
#import <objc/message.h>
#import "STBlock.h"

@interface ASViewController ()

- (IBAction)execute_class_print:(id)sender;
- (IBAction)execute_print1:(id)sender;
- (IBAction)execute_print2:(id)sender;

@end

@implementation ASViewController

+ (void)load {
  /*
   * hook @selector(class_print:)
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
  
  [self st_hookInstanceMethod:@selector(print1:) option:STOptionAfter usingIdentifier:@"hook_print1_after2" withBlock:^(id<StingerParams> params, NSString *s) {
    NSLog(@"---after2 print1: %@", s);
  }];
  
  /*
   * hook @selector(print2:)
   */
  
  __block NSString *oldRet, *newRet;
  [self st_hookInstanceMethod:@selector(print2:) option:STOptionInstead usingIdentifier:@"hook_print2_instead" withBlock:^NSString * (id<StingerParams> params, NSString *s) {
    [params invokeAndGetOriginalRetValue:&oldRet];
    newRet = [oldRet stringByAppendingString:@" ++ new-st_instead"];
    NSLog(@"---instead print2 old ret: (%@) / new ret: (%@)", oldRet, newRet);
    return newRet;
  }];
  
  [self st_hookInstanceMethod:@selector(print2:) option:STOptionAfter usingIdentifier:@"hook_print2_after1" withBlock:^(id<StingerParams> params, NSString *s) {
    NSLog(@"---after1 print2 self:%@ SEL: %@ p: %@",[params slf], NSStringFromSelector([params sel]), s);
  }];
}

- (void)print1:(NSString *)s{
  NSLog(@"---original print1: %@", s);
}

- (NSString *)print2:(NSString *)s{
  NSLog(@"---original print2: %@", s);
  return [s stringByAppendingString:@"-print2 return"];
}

+ (void)class_print:(NSString *)s {
  NSLog(@"---original class_print: %@", s);
}

#pragma - action

- (IBAction)execute_class_print:(id)sender {
  [ASViewController class_print:@"example"];
}

- (IBAction)execute_print1:(id)sender {
  [self print1:@"example"];
}

- (IBAction)execute_print2:(id)sender {
  NSString *newRet = [self print2:@"example"];
  NSLog(@"---print2 new ret: %@", newRet);
}

- (NSTimeInterval)measureBlock:(void(^)(void))block times:(NSUInteger)times {
  NSDate* tmpStartDate = [NSDate date];
  if (block) {
    for (int i = 0; i < times; i++) {
      block();
    }
  }
  return [[NSDate date] timeIntervalSinceDate:tmpStartDate] * 1000.0 / times;
}

@end
