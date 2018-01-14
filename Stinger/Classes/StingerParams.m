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

@property (nonatomic, strong) NSInvocation *originalInvocation;
@property (nonatomic) IMP originalIMP;

@end

@implementation StingerParams

@synthesize slf = _slf;
@synthesize sel = _sel;

- (void)invokeAndGetOriginalRetValue:(void *)retLoc {
  [self.originalInvocation invokeUsingIMP:self.originalIMP];
  if (self.originalInvocation.methodSignature.methodReturnLength && !(retLoc == NULL)) {
    [self.originalInvocation getReturnValue:retLoc];
  }
}

- (void)addOriginalInvocation:(NSInvocation *)invocation {
  self.originalInvocation = invocation;
}

- (void)addOriginalIMP:(IMP)imp {
  self.originalIMP = imp;
}

@end
