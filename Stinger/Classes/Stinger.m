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
#import "STBlock.h"
#import "STMethodSignature.h"

NSString * const STMethodPrefix = @"st_original_";

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
  Class stSubClass = getSTSubClass(self);
  if (!stSubClass) return STHookResultOther;
  STHookResult hookMethodResult = hookMethod(stSubClass, sel, option, identifier, block);
  if (hookMethodResult != STHookResultSuccuss) return hookMethodResult;
  object_setClass(self, stSubClass);
  
  @synchronized(self) {
    id<STHookInfoPool> instanceHookInfoPool = st_getHookInfoPool(self, sel);
    if (!instanceHookInfoPool) {
      instanceHookInfoPool = [STHookInfoPool poolWithTypeEncoding:nil originalIMP:NULL selector:sel];
      st_setHookInfoPool(self, sel, instanceHookInfoPool);
    }
    
    STHookInfo *instanceHookInfo = [STHookInfo infoWithOption:option withIdentifier:identifier withBlock:block];
    return [instanceHookInfoPool addInfo:instanceHookInfo] ? STHookResultErrorIDExisted : STHookResultSuccuss;
  }
}

- (NSArray<STIdentifier> *)st_allIdentifiersForKey:(SEL)key {
  return getAllIdentifiers(self, key);
}

- (BOOL)st_removeHookWithIdentifier:(STIdentifier)identifier forKey:(SEL)key {
  BOOL hasRemoved = NO;
  @synchronized(self) {
    id<STHookInfoPool> infoPool = st_getHookInfoPool(self, key);
    if ([infoPool removeInfoForIdentifier:identifier]) {
      hasRemoved = YES;
      if (!infoPool.identifiers.count) {
        object_setClass(self, class_getSuperclass(object_getClass(self)));
      }
    }
  }
  return hasRemoved;
}

#pragma mark - inline functions

NS_INLINE STHookResult hookMethod(Class cls, SEL sel, STOption option, STIdentifier identifier, id block) {
  NSCParameterAssert(cls);
  NSCParameterAssert(sel);
  NSCParameterAssert(option == 0 || option == 1 || option == 2);
  NSCParameterAssert(identifier);
  NSCParameterAssert(block);
  Method m = class_getInstanceMethod(cls, sel);
  NSCAssert(m, @"SEL (%@) doesn't has a imp in Class (%@) originally", NSStringFromSelector(sel), cls);
  if (!m) return STHookResultErrorMethodNotFound;
  const char * typeEncoding = method_getTypeEncoding(m);
  STMethodSignature *methodSignature = [[STMethodSignature alloc] initWithObjCTypes:[NSString stringWithUTF8String:typeEncoding]];
  STMethodSignature *blockSignature = [[STMethodSignature alloc] initWithObjCTypes:signatureForBlock(block)];
  if (! isMatched(methodSignature, blockSignature, option, cls, sel, identifier)) {
    return STHookResultErrorBlockNotMatched;
  }

  IMP originalImp = method_getImplementation(m);
  
  @synchronized(cls) {
    id<STHookInfoPool> hookInfoPool = st_getHookInfoPool(cls, sel);
    if (!hookInfoPool) {
      hookInfoPool = [STHookInfoPool poolWithTypeEncoding:[NSString stringWithUTF8String:typeEncoding] originalIMP:originalImp selector:sel];
      hookInfoPool.cls = cls;
      
      IMP stingerIMP = [hookInfoPool stingerIMP];
      
      if (!(class_addMethod(cls, sel, stingerIMP, typeEncoding))) {
        class_replaceMethod(cls, sel, stingerIMP, typeEncoding);
      }
      const char * st_original_SelName = [[STMethodPrefix stringByAppendingString:NSStringFromSelector(sel)] UTF8String];
      class_addMethod(cls, sel_registerName(st_original_SelName), originalImp, typeEncoding);
      
      st_setHookInfoPool(cls, sel, hookInfoPool);
    }
    
    if ([NSStringFromClass(cls) hasPrefix:STClassPrefix]) {
      return STHookResultSuccuss;
    } else {
      
      STHookInfo *hookInfo = [STHookInfo infoWithOption:option withIdentifier:identifier withBlock:block];
      return [hookInfoPool addInfo:hookInfo] ? STHookResultErrorIDExisted : STHookResultSuccuss;
    }
  }
}

NS_INLINE Class getSTSubClass(id object) {
  NSCParameterAssert(object);
  Class isaClass = object_getClass(object);
  NSString *isaClassName = NSStringFromClass(isaClass);
  if ([isaClassName hasPrefix:STClassPrefix]) {
    return isaClass;
  }
    
  const char *subclassName = [STClassPrefix stringByAppendingString:isaClassName].UTF8String;
  Class subclass = objc_getClass(subclassName);
  if (!subclass) {
    subclass = objc_allocateClassPair(isaClass, subclassName, 0);
    NSCAssert(subclass, @"Class %s allocate failed!", subclassName);
    if (!subclass) {
        return nil;
    }
    
  objc_registerClassPair(subclass);
  Class realClass = [object class];
  hookGetClassMessage(subclass, realClass);
  hookGetClassMessage(object_getClass(subclass), realClass);
}
  return subclass;
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
