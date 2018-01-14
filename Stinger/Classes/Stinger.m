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

@implementation NSObject (Stinger)

#pragma - public

+ (void)st_hookInstanceMethod:(SEL)sel option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block {
  [self _hookInstanceMethod:sel class:self.class option:option usingIdentifier:identifier withBlock:block];
}

+ (void)st_hookClassMethod:(SEL)sel option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block {
  [self _hookInstanceMethod:sel class:object_getClass(self) option:option usingIdentifier:identifier withBlock:block];
}

#pragma - private

+ (void)_hookInstanceMethod:(SEL)sel class:(Class)cls option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block {
  Method m = class_getInstanceMethod(cls, sel);
  IMP originalImp = method_getImplementation(m);
  const char * typeEncoding = method_getTypeEncoding(m);
  
  StingerInfo *info = [StingerInfo infoWithOption:option withIdentifier:identifier withBlock:block];
  id<StingerInfoPool> infoPool = [cls _stingerInfoPoolForKey:sel];
  
  if (infoPool) {
    [infoPool addInfo:info];
    return;
  }
  
  infoPool = [StingerInfoPool poolWithTypeEncoding:[NSString stringWithUTF8String:typeEncoding] originalIMP:originalImp selector:sel];
  IMP stingerIMP = [infoPool stingerIMP];
  
  if (!class_addMethod(cls, sel, stingerIMP, typeEncoding)) {
    class_replaceMethod(cls, sel, stingerIMP, typeEncoding);
    const char * st_original_SelName = [[@"st_original_" stringByAppendingString:NSStringFromSelector(sel)] UTF8String];
    class_addMethod(cls, sel_registerName(st_original_SelName), originalImp, typeEncoding);
  }
  [infoPool addInfo:info];
  [cls _setStingerInfoPool:infoPool ForKey:sel];
}

+ (id<StingerInfoPool>)_stingerInfoPoolForKey:(SEL)key {
  return objc_getAssociatedObject(self, key);
}

+ (void)_setStingerInfoPool:(id<StingerInfoPool>)infoPool ForKey:(SEL)key {
  objc_setAssociatedObject(self, key, infoPool, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSArray<STIdentifier> *)_allIdentifiersForKey:(SEL)key withClass:(Class)cls {
  id<StingerInfoPool> infoPool = [cls _stingerInfoPoolForKey:key];
  return infoPool.identifiers;
}

@end
