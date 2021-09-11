//
//  STHookInfo.m
//  Stinger
//
//  Created by Assuner on 2018/1/9.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import "STHookInfo.h"

@implementation STHookInfo

@synthesize identifier = _identifier;
@synthesize option = _option;
@synthesize block = _block;

+ (instancetype)infoWithOption:(STOption)option withIdentifier:(STIdentifier)identifier withBlock:(id)block {
  NSParameterAssert(identifier);
  NSParameterAssert(block);
  
  STHookInfo *info = [[STHookInfo alloc] init];
  info.option = option;
  info.identifier = identifier;
  info.block = block;
  return info;
}

- (void)setOption:(STOption)option {
  _option = option;
  self->automaticRemoval = option & STOptionAutomaticRemoval;
}

@end
