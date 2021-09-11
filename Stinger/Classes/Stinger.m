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
    if (hookMethodResult != STHookResultSuccess) return hookMethodResult;
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
    return [instanceHookInfoPool addInfo:instanceHookInfo] ? STHookResultSuccess : STHookResultErrorIDExisted;
  }
}

- (NSArray<STIdentifier> *)st_allIdentifiersForKey:(SEL)key {
   @synchronized(self) {
      return getAllIdentifiers(self, key);
   }
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
  NSCParameterAssert(identifier);
  NSCParameterAssert(block);
  Method m = class_getInstanceMethod(hookedCls, sel);
  NSCAssert(m, @"SEL (%@) doesn't has a imp in Class (%@) originally", NSStringFromSelector(sel), hookedCls);
  if (!m) return STHookResultErrorMethodNotFound;
  const char * typeEncoding = method_getTypeEncoding(m);
  NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:typeEncoding];
  NSMethodSignature *blockSignature = st_getSignatureForBlock(block);

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
    if (st_isIntanceHookCls(hookedCls)) {
      return STHookResultSuccess;
    } else {
      STHookInfo *hookInfo = [STHookInfo infoWithOption:option withIdentifier:identifier withBlock:block];
      return [hookInfoPool addInfo:hookInfo] ? STHookResultSuccess :  STHookResultErrorIDExisted;
    }
  }
}

NS_INLINE Class getSTSubClass(id object) {
  NSCParameterAssert(object);
  Class stSubClass = objc_getAssociatedObject(object, STSubClassKey);
  if (stSubClass) return stSubClass;
    
  Class isaClass = object_getClass(object);
  NSString *isaClassName = NSStringFromClass(isaClass);
  if ([isaClassName hasPrefix:KVOClassPrefix]) {
    return isaClass;
  } else {
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
  return infoPool.allIdentifiers;
}


NS_INLINE BOOL isMatched(NSMethodSignature *methodSignature, NSMethodSignature *blockSignature, STOption option, Class cls, SEL sel, NSString *identifier) {
  BOOL strictCheck = ((option & STOptionWeakCheckSignature) == 0);
  //argument count
  if (strictCheck && methodSignature.numberOfArguments != blockSignature.numberOfArguments) {
    NSCAssert(NO, @"count of arguments isn't equal. Class: (%@), SEL: (%@), Identifier: (%@)", cls, NSStringFromSelector(sel), identifier);
    return NO;
  };
  // loc 1 should be id<StingerParams>.
  const char *firstArgumentType = [blockSignature getArgumentTypeAtIndex:1];
  if (!firstArgumentType || firstArgumentType[0] != '@') {
     NSCAssert(NO, @"argument 1 should be object type. Class: (%@), SEL: (%@), Identifier: (%@)", cls, NSStringFromSelector(sel), identifier);
    return NO;
  }
  /// only strict check
  if (strictCheck) {
    // from loc 2.
    for (NSInteger i = 2; i < methodSignature.numberOfArguments; i++) {
      const char *methodType = [methodSignature getArgumentTypeAtIndex:i];
      const char *blockType = [blockSignature getArgumentTypeAtIndex:i];
      if (!methodType || !blockType || methodType[0] != blockType[0]) {
        NSCAssert(NO, @"argument (%zd) type isn't equal. Class: (%@), SEL: (%@), Identifier: (%@)", i, cls, NSStringFromSelector(sel), identifier);
        return NO;
      }
    }
  }
  // when STOptionInstead, returnType
  if ((option & StingerPositionFilter) == STOptionInstead) {
    const char *methodReturnType = methodSignature.methodReturnType;
    const char *blockReturnType = blockSignature.methodReturnType;
    if (!methodReturnType || !blockReturnType || methodReturnType[0] != blockReturnType[0]) {
      NSCAssert(NO, @"return type isn't equal. Class: (%@), SEL: (%@), Identifier: (%@)", cls, NSStringFromSelector(sel), identifier);
      return NO;
    }
  }
  
  return YES;
}

@end
