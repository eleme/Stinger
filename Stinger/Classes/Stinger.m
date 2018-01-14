//
//  Stinger.m
//  Stinger
//
//  Created by Assuner on 2018/1/9.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import "Stinger.h"
#import <objc/runtime.h>
#import "StingerInfo.h"
#import "StingerInfoPool.h"
#import "STBlock.h"
#import "STMethodSignature.h"

@implementation NSObject (Stinger)

#pragma - public

+ (BOOL)st_hookInstanceMethod:(SEL)sel option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block {
  return [self _hookInstanceMethod:sel class:self.class option:option usingIdentifier:identifier withBlock:block];
}

+ (BOOL)st_hookClassMethod:(SEL)sel option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block {
  return [self _hookInstanceMethod:sel class:object_getClass(self) option:option usingIdentifier:identifier withBlock:block];
}

#pragma - private

+ (BOOL)_hookInstanceMethod:(SEL)sel class:(Class)cls option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block {
  Method m = class_getInstanceMethod(cls, sel);
  NSAssert(m, @"SEL (%@) doesn't has a imp in Class (%@) originally", NSStringFromSelector(sel), cls);
  if (!m) return NO;
  
  const char * typeEncoding = method_getTypeEncoding(m);
  STMethodSignature *methodSignature = [[STMethodSignature alloc] initWithObjCTypes:[NSString stringWithUTF8String:typeEncoding]];
  STMethodSignature *blockSignature = [[STMethodSignature alloc] initWithObjCTypes:signatureForBlock(block)];
  if (! isMatched(methodSignature, blockSignature, option, cls, sel, identifier)) {
    return NO;
  }
  

  IMP originalImp = method_getImplementation(m);
  
  @synchronized(cls) {
    StingerInfo *info = [StingerInfo infoWithOption:option withIdentifier:identifier withBlock:block];
    id<StingerInfoPool> infoPool = [cls _stingerInfoPoolForKey:sel];
    
    if (infoPool) {
      return [infoPool addInfo:info];
    }
    
    infoPool = [StingerInfoPool poolWithTypeEncoding:[NSString stringWithUTF8String:typeEncoding] originalIMP:originalImp selector:sel];
    infoPool.cls = cls;
    
    IMP stingerIMP = [infoPool stingerIMP];
    
    class_replaceMethod(cls, sel, stingerIMP, typeEncoding);
    const char * st_original_SelName = [[@"st_original_" stringByAppendingString:NSStringFromSelector(sel)] UTF8String];
    class_addMethod(cls, sel_registerName(st_original_SelName), originalImp, typeEncoding);
    
    [cls _setStingerInfoPool:infoPool ForKey:sel];
    return [infoPool addInfo:info];
  }
}

+ (id<StingerInfoPool>)_stingerInfoPoolForKey:(SEL)key {
  return objc_getAssociatedObject(self, key);
}

+ (void)_setStingerInfoPool:(id<StingerInfoPool>)infoPool ForKey:(SEL)key {
  objc_setAssociatedObject(self, key, infoPool, OBJC_ASSOCIATION_RETAIN);
}

+ (NSArray<STIdentifier> *)_allIdentifiersForKey:(SEL)key withClass:(Class)cls {
  id<StingerInfoPool> infoPool = [cls _stingerInfoPoolForKey:key];
  return infoPool.identifiers;
}


NS_INLINE BOOL isMatched(STMethodSignature *methodSignature, STMethodSignature *blockSignature, STOption option, Class cls, SEL sel, NSString *identifier) {
  //argument count
  if (methodSignature.argumentTypes.count != blockSignature.argumentTypes.count) {
    NSCAssert(NO, @"count of arguments isn't equal. Class: (%@), SEL: (%@), Identifier: (%@)", cls, NSStringFromSelector(sel), identifier);
    return NO;
  };
  // loc 1 should be id<StingerParams>.
  if (![blockSignature.argumentTypes[1] isEqualToString:@"@"]) {
     NSCAssert(NO, @"argument 1 should be object type. Class: (%@), SEL: (%@), Identifier: (%@)", cls, NSStringFromSelector(sel), identifier);
    return NO;
  }
  // from loc 2.
  for (NSInteger i = 2; i < methodSignature.argumentTypes.count; i++) {
    if (![blockSignature.argumentTypes[i] isEqualToString:methodSignature.argumentTypes[i]]) {
      NSCAssert(NO, @"argument (%zd) type isn't equal. Class: (%@), SEL: (%@), Identifier: (%@)", i, cls, NSStringFromSelector(sel), identifier);
      return NO;
    }
  }
  // when STOptionInstead, returnType
  if (option == STOptionInstead && ![blockSignature.returnType isEqualToString:methodSignature.returnType]) {
    NSCAssert(NO, @"return type isn't equal. Class: (%@), SEL: (%@), Identifier: (%@)", cls, NSStringFromSelector(sel), identifier);
    return NO;
  }
  
  return YES;
}

@end
