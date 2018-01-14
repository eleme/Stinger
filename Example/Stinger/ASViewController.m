//
//  ASViewController.m
//  Stinger
//
//  Created by Assuner-Lee on 12/05/2017.
//  Copyright (c) 2017 Assuner-Lee. All rights reserved.
//

#import "ASViewController.h"
#import "Stinger.h"
#import <objc/message.h>
#import "STBlock.h"

@interface ASViewController ()
- (IBAction)touch:(id)sender;

@end

@implementation ASViewController

+ (void)load {
  NSString *o;
  [self st_hookInstanceMethod:@selector(print3:) option:STOptionAfter usingIdentifier:@"3333" withBlock:^NSString *(id<StingerParams> params, NSString *s) {
    [params invokeAndGetOriginalRetValue:ST_NO_RET];
    NSLog(@"instead %@ --original %@", s, o);
    return [NSString stringWithFormat:@"instead %@", s];
  }];
  
  [self st_hookClassMethod:@selector(class_print:) option:STOptionBefore usingIdentifier:@"class_hool" withBlock:^(id<StingerParams> params, NSString *s) {
    NSLog(@"before class_hookhhh %@", s);
  }];
}

- (void)print2:(NSString *)s {
  NSLog(@"print 2%@", s);
}

- (void)print1:(NSString *)s{
  NSLog(@"print 1%@", s);
}

- (NSString *)print3:(NSString *)s{
  NSLog(@"return--- %@", s);
  return [s stringByAppendingString:@"++"];
}

+ (void)class_print:(NSString *)s {
  NSLog(@"class_print %@", s);
}

- (void)viewDidLoad {
  [super viewDidLoad];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)touch:(id)sender {
//  NSLog(@">>>>>>>>>>cost1 time = %f ms", [self measureBlock:^{
////    dispatch_async(dispatch_get_global_queue(0, 0), ^{
////      [[ASClassA new] print:@"asclass A"];
////    });
////    dispatch_async(dispatch_get_global_queue(0, 0), ^{
////       [self print1:@"ssss"];;
////    });
//   // [self print1:@"ssss"];;
//    NSString *mss = [self print3:@"pppppp"];
//    NSLog(@"mss %@", mss);
//  } times:1]);
  [ASViewController class_print:@"class"];
}
@end
