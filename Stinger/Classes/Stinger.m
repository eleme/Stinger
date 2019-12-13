//
//  Stinger.m
//  Stinger
//
//  Created by Assuner on 2018/1/9.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import "Stinger.h"
#import <objc/runtime.h>
#import "STHookInfo.h"
#import "STHookInfoPool.h"
#import "STMethodSignature.h"

static void *STSubClassKey = &STSubClassKey;

@implementation NSObject (Stinger)

#pragma mark - For specific class

+ (STHookResult)st_hookInstanceMethod:(SEL)sel option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block {
  return hookMethod(self, sel, option, identifier, block);
}

+ (STHookResult)st_hookClassMethod:(SEL)sel option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block {
  return hookMethod(object_getClass(self), sel, option, identifier, block);
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
    id<STHookInfoPool> infoPool = st_getHookInfoPool(self, key);
    if ([infoPool removeInfoForIdentifier:identifier]) {
      hasRemoved = YES;
    }
    infoPool = st_getHookInfoPool(object_getClass(self), key);
    if ([infoPool removeInfoForIdentifier:identifier]) {
      hasRemoved = YES;
    }
  }
  return hasRemoved;
}

#pragma mark - For specific instance

- (STHookResult)st_hookInstanceMethod:(SEL)sel option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block {
  @synchronized(self) {
    Class stSubClass = getSTSubClass(self);
    if (!stSubClass) return STHookResultOther;
    
    STHookResult hookMethodResult = hookMethod(stSubClass, sel, option, identifier, block);
    if (hookMethodResult != STHookResultSuccuss) return hookMethodResult;
    if (!objc_getAssociatedObject(self, STSubClassKey)) {
      object_setClass(self, stSubClass);
      objc_setAssociatedObject(self, STSubClassKey, stSubClass, OBJC_ASSOCIATION_ASSIGN);
    }
    
    id<STHookInfoPool> instanceHookInfoPool = st_getHookInfoPool(self, sel);
    if (!instanceHookInfoPool) {
      instanceHookInfoPool = [STHookInfoPool poolWithTypeEncoding:nil originalIMP:NULL selector:sel];
      st_setHookInfoPool(self, sel, instanceHookInfoPool);
    }
    
    STHookInfo *instanceHookInfo = [STHookInfo infoWithOption:option withIdentifier:identifier withBlock:block];
    return [instanceHookInfoPool addInfo:instanceHookInfo] ? STHookResultSuccuss : STHookResultErrorIDExisted;
  }
}

- (NSArray<STIdentifier> *)st_allIdentifiersForKey:(SEL)key {
  return getAllIdentifiers(self, key);
}

- (BOOL)st_removeHookWithIdentifier:(STIdentifier)identifier forKey:(SEL)key {
  BOOL hasRemoved = NO;
  @synchronized(self) {
    id<STHookInfoPool> infoPool = st_getHookInfoPool(self, key);
    hasRemoved = [infoPool removeInfoForIdentifier:identifier];
    return hasRemoved;
  }
}

#pragma mark - inline functions

NS_INLINE STHookResult hookMethod(Class hookedCls, SEL sel, STOption option, STIdentifier identifier, id block) {
  NSCParameterAssert(hookedCls);
  NSCParameterAssert(sel);
  NSCParameterAssert(option == 0 || option == 1 || option == 2);
  NSCParameterAssert(identifier);
  NSCParameterAssert(block);
  Method m = class_getInstanceMethod(hookedCls, sel);
  NSCAssert(m, @"SEL (%@) doesn't has a imp in Class (%@) originally", NSStringFromSelector(sel), hookedCls);
  if (!m) return STHookResultErrorMethodNotFound;
  const char * typeEncoding = method_getTypeEncoding(m);
  STMethodSignature *methodSignature = [[STMethodSignature alloc] initWithObjCTypes:[NSString stringWithUTF8String:typeEncoding]];
  STMethodSignature *blockSignature = [[STMethodSignature alloc] initWithObjCTypes:st_getSignatureForBlock(block)];
  if (!isMatched(methodSignature, blockSignature, option, hookedCls, sel, identifier)) {
    return STHookResultErrorBlockNotMatched;
  }
  
  IMP originalImp = method_getImplementation(m);
  @synchronized(hookedCls) {
    id<STHookInfoPool> hookInfoPool = st_getHookInfoPool(hookedCls, sel);
    if (!hookInfoPool) {
      hookInfoPool = [STHookInfoPool poolWithTypeEncoding:[NSString stringWithUTF8String:typeEncoding] originalIMP:NULL selector:sel];
      hookInfoPool.hookedCls = hookedCls;
      hookInfoPool.statedCls = [hookedCls class];
      
      IMP stingerIMP = [hookInfoPool stingerIMP];
      hookInfoPool.originalIMP = originalImp;
      if (!class_addMethod(hookedCls, sel, stingerIMP, typeEncoding)) {
        class_replaceMethod(hookedCls, sel, stingerIMP, typeEncoding);
      }
      
      st_setHookInfoPool(hookedCls, sel, hookInfoPool);
    }
    
    if ([NSStringFromClass(hookedCls) hasPrefix:STClassPrefix]) {
      return STHookResultSuccuss;
    } else {
      STHookInfo *hookInfo = [STHookInfo infoWithOption:option withIdentifier:identifier withBlock:block];
      return [hookInfoPool addInfo:hookInfo] ? STHookResultSuccuss :  STHookResultErrorIDExisted;
    }
  }
}

NS_INLINE Class getSTSubClass(id object) {
  NSCParameterAssert(object);
  Class stSubClass = objc_getAssociatedObject(object, STSubClassKey);
  if (stSubClass) return stSubClass;
    
  Class isaClass = object_getClass(object);
  NSString *isaClassName = NSStringFromClass(isaClass);
  const char *subclassName = [STClassPrefix stringByAppendingString:isaClassName].UTF8String;
  stSubClass = objc_getClass(subclassName);
  if (!stSubClass) {
    stSubClass = objc_allocateClassPair(isaClass, subclassName, 0);
    NSCAssert(stSubClass, @"Class %s allocate failed!", subclassName);
    if (!stSubClass) return nil;
    
  objc_registerClassPair(stSubClass);
  Class realClass = [object class];
  hookGetClassMessage(stSubClass, realClass);
  hookGetClassMessage(object_getClass(stSubClass), realClass);
}
  return stSubClass;
}


NS_INLINE void hookGetClassMessage(Class class, Class retClass) {
  Method method = class_getInstanceMethod(class, @selector(class));
  IMP newIMP = imp_implementationWithBlock(^(id self) {
    return retClass;
  });
  class_replaceMethod(class, @selector(class), newIMP, method_getTypeEncoding(method));
}

NS_INLINE NSArray<STIdentifier> * getAllIdentifiers(id obj, SEL key) {
  NSCParameterAssert(obj);
  NSCParameterAssert(key);
  id<STHookInfoPool> infoPool = st_getHookInfoPool(obj, key);
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
