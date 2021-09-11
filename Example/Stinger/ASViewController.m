//
//  ASViewController.m
//  Stinger
//
//  Created by Assuner on 12/05/2017.
//  Copyright (c) 2017 Assuner. All rights reserved.
//

#import "ASViewController.h"
#import <Stinger/Stinger.h>
#import <Aspects/Aspects.h>

@interface ASViewController ()

- (IBAction)test:(id)sender;

@end

@implementation ASViewController

- (void)methodA {
  
}

- (void)setFrame:(CGRect)rect {
  
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.class st_hookInstanceMethod:@selector(methodA) option:STOptionBefore usingIdentifier:@"hook methodA before" withBlock:^(id<StingerParams> params) {

  }];
  [self.class st_hookInstanceMethod:@selector(methodA) option:STOptionAfter usingIdentifier:@"hook methodA after" withBlock:^(id<StingerParams> params) {

  }];
  
//  [self.class aspect_hookSelector:@selector(methodA) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> params) {
//
//  } error:nil];
//
//  [self.class aspect_hookSelector:@selector(methodA) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> params) {
//
//  } error:nil];
}

- (IBAction)test:(id)sender {
  for (NSInteger i = 0; i < 1000000; i++) {
    [self methodA];
  }
  NSLog(@"clicked!!");
  NSURL *url = [[NSURL alloc] initWithString:@"https://www.google.com"];
  [url st_hookInstanceMethod:@selector(absoluteString) option:(STOptionBefore) usingIdentifier:@"123" withBlock:^(id<StingerParams> params) {
      NSLog(@"");
  }];
  [url absoluteString];
}
@end
