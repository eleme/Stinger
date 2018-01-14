//
//  StingerInfo.m
//  Stinger
//
//  Created by Assuner on 2018/1/9.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import "StingerInfo.h"
#import "STMethodSignature.h"

@implementation StingerInfo

@synthesize identifier = _identifier;
@synthesize option = _option;
@synthesize block = _block;

+ (instancetype)infoWithOption:(STOption)option withIdentifier:(STIdentifier)identifier withBlock:(id)block {
  NSAssert((option == 0 || option == 1 || option == 2), @"invalid STOption of %zd", option);
  NSParameterAssert(identifier);
  NSParameterAssert(block);
  
  StingerInfo *info = [[StingerInfo alloc] init];
  info.option = option;
  info.identifier = identifier;
  info.block = block;
  return info;
}

@end
