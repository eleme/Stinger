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
  return hook(self, sel, option, identifier, block);
}

+ (BOOL)st_hookClassMethod:(SEL)sel option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block {
  return hook(object_getClass(self), sel, option, identifier, block);
}

+ (NSArray<STIdentifier> *)st_allIdentifiersForKey:(SEL)key {
  NSMutableArray *mArray = [[NSMutableArray alloc] init];
  @synchronized(self) {
    [mArray addObjectsFromArray:getAllIdentifiers(self, key)];
    [mArray addObjectsFromArray:getAllIdentifiers(object_getClass(self), key)];
  }
  return [mArray copy];
}

+ (BOOL)st_removeHookWithIdentifier:(STIdentifier)identifier forKey:(SEL)key {
  BOOL hasRemoved = NO;
  @synchronized(self) {
    id<StingerInfoPool> infoPool = getStingerInfoPool(self, key);
    if ([infoPool removeInfoForIdentifier:identifier]) {
      hasRemoved = YES;
    }
    infoPool = getStingerInfoPool(object_getClass(self), key);
    if ([infoPool removeInfoForIdentifier:identifier]) {
      hasRemoved = YES;
    }
  }
  return hasRemoved;
}

#pragma - inline functions

NS_INLINE BOOL hook(Class cls, SEL sel, STOption option, STIdentifier identifier, id block) {
  NSCParameterAssert(cls);
  NSCParameterAssert(sel);
  NSCParameterAssert(option == 0 || option == 1 || option == 2);
  NSCParameterAssert(identifier);
  NSCParameterAssert(block);
  
  Method m = class_getInstanceMethod(cls, sel);
  NSCAssert(m, @"SEL (%@) doesn't has a imp in Class (%@) originally", NSStringFromSelector(sel), cls);
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
    id<StingerInfoPool> infoPool = getStingerInfoPool(cls, sel);
    
    if (infoPool) {
      return [infoPool addInfo:info];
    }
    
    infoPool = [StingerInfoPool poolWithTypeEncoding:[NSString stringWithUTF8String:typeEncoding] originalIMP:originalImp selector:sel];
    infoPool.cls = cls;
    
    IMP stingerIMP = [infoPool stingerIMP];
    
    class_replaceMethod(cls, sel, stingerIMP, typeEncoding);
    const char * st_original_SelName = [[@"st_original_" stringByAppendingString:NSStringFromSelector(sel)] UTF8String];
    class_addMethod(cls, sel_registerName(st_original_SelName), originalImp, typeEncoding);
    
    setStingerInfoPool(cls, sel, infoPool);
    return [infoPool addInfo:info];
  }
}

NS_INLINE id<StingerInfoPool> getStingerInfoPool(Class cls, SEL key) {
  NSCParameterAssert(cls);
  NSCParameterAssert(key);
  return objc_getAssociatedObject(cls, key);
}

NS_INLINE void setStingerInfoPool(Class cls, SEL key, id<StingerInfoPool> infoPool) {
  NSCParameterAssert(cls);
  NSCParameterAssert(key);
  objc_setAssociatedObject(cls, key, infoPool, OBJC_ASSOCIATION_RETAIN);
}

NS_INLINE NSArray<STIdentifier> * getAllIdentifiers(Class cls, SEL key) {
  NSCParameterAssert(cls);
  NSCParameterAssert(key);
  id<StingerInfoPool> infoPool = getStingerInfoPool(cls, key);
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
