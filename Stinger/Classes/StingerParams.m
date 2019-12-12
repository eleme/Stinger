//
//  StingerParams.m
//  Stinger
//
//  Created by Assuner on 2018/1/10.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import "StingerParams.h"

@interface NSInvocation (STInvoke)
- (void)invokeUsingIMP:(IMP)imp;
@end

@interface StingerParams ()
@property (nonatomic, strong) NSString *types;
@property (nonatomic) SEL sel;
@property (nonatomic) IMP originalIMP;
@property (nonatomic) void **args;
@end

@implementation StingerParams

- (instancetype)initWithType:(NSString *)types originalIMP:(IMP)imp sel:(SEL)sel args:(void **)args {
  if (self = [super init]) {
    _types = types;
    _sel = sel;
    _originalIMP = imp;
    _args = args;
  }
  return self;
}

- (id)slf {
  void **slfPointer = _args[0];
  return (__bridge id)(*slfPointer);
}

- (SEL)sel {
  return _sel;
}


- (void)invokeAndGetOriginalRetValue:(void *)retLoc {
  NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:_types.UTF8String];
  NSInteger count = signature.numberOfArguments;
  NSInvocation *originalInvocation = [NSInvocation invocationWithMethodSignature:signature];
  for (int i = 0; i < count; i ++) {
    [originalInvocation setArgument:_args[i] atIndex:i];
  }
  [originalInvocation invokeUsingIMP:_originalIMP];
  if (originalInvocation.methodSignature.methodReturnLength && !(retLoc == NULL)) {
    [originalInvocation getReturnValue:retLoc];
  }
}

@end
