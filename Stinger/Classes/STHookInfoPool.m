//
//  STHookInfoPool.m
//  Stinger
//
//  Created by Assuner on 2018/1/9.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import "STHookInfoPool.h"
#import "ffi.h"
#import "STMethodSignature.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "StingerParams.h"
#import "STHookInfo.h"

#pragma mark - Block_layout

enum {
  BLOCK_DEALLOCATING =      (0x0001),  // runtime
  BLOCK_REFCOUNT_MASK =     (0xfffe),  // runtime
  BLOCK_NEEDS_FREE =        (1 << 24), // runtime
  BLOCK_HAS_COPY_DISPOSE =  (1 << 25), // compiler
  BLOCK_HAS_CTOR =          (1 << 26), // compiler: helpers have C++ code
  BLOCK_IS_GC =             (1 << 27), // runtime
  BLOCK_IS_GLOBAL =         (1 << 28), // compiler
  BLOCK_USE_STRET =         (1 << 29), // compiler: undefined if !BLOCK_HAS_SIGNATURE
  BLOCK_HAS_SIGNATURE  =    (1 << 30)  // compiler
};

// revised new layout

#define BLOCK_DESCRIPTOR_1 1
struct Block_descriptor_1 {
  unsigned long int reserved;
  unsigned long int size;
};

#define BLOCK_DESCRIPTOR_2 1
struct Block_descriptor_2 {
  // requires BLOCK_HAS_COPY_DISPOSE
  void (*copy)(void *dst, const void *src);
  void (*dispose)(const void *);
};

#define BLOCK_DESCRIPTOR_3 1
struct Block_descriptor_3 {
  // requires BLOCK_HAS_SIGNATURE
  const char *signature;
  const char *layout;
};

struct Block_layout {
  void *isa;
  volatile int flags; // contains ref count
  int reserved;
  void (*invoke)(void *, ...);
  struct Block_descriptor_1 *descriptor;
  // imported variables
};


NSString *st_getSignatureForBlock(id block) {
  struct Block_layout *layout = (__bridge void *)block;
  if (!(layout->flags & BLOCK_HAS_SIGNATURE))
    return nil;
  
  void *descRef = layout->descriptor;
  descRef += 2 * sizeof(unsigned long int);
  
  if (layout->flags & BLOCK_HAS_COPY_DISPOSE)
    descRef += 2 * sizeof(void *);
  
  if (!descRef) return nil;
  
  const char *signature = (*(const char **)descRef);
  return [NSString stringWithUTF8String:signature];
}

NS_INLINE void *_st_impForBlock(id block) {
  struct Block_layout *layout = (__bridge void *)block;
  return layout->invoke;
}


#pragma mark - STHookInfoPool

NSString * const STClassPrefix = @"st_class_";


@interface STHookInfoPool ()
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) STMethodSignature *signature;
@property (nonatomic, strong) NSMethodSignature *ns_signature;
@property (nonatomic, assign) NSUInteger argsCount;
@property (nonatomic) SEL uniqueKey;
@end

@implementation STHookInfoPool {
  ffi_cif _cif;
  ffi_cif _blockCif;
  ffi_type **_args;
  ffi_type **_blockArgs;
  ffi_closure *_closure;
}

@synthesize beforeInfos = _beforeInfos;
@synthesize insteadInfo = _insteadInfo;
@synthesize afterInfos = _afterInfos;
@synthesize identifiers = _identifiers;
@synthesize originalIMP = _originalIMP;
@synthesize typeEncoding = _typeEncoding;
@synthesize sel = _sel;
@synthesize stingerIMP = _stingerIMP;
@synthesize hookedCls = _hookedCls;
@synthesize statedCls = _statedCls;
@synthesize isInstanceHook = _isInstanceHook;


+ (instancetype)poolWithTypeEncoding:(NSString *)typeEncoding originalIMP:(IMP)imp selector:(SEL)sel {
  STHookInfoPool *pool = [[STHookInfoPool alloc] init];
  pool.typeEncoding = typeEncoding;
  pool.originalIMP = imp;
  pool.sel = sel;
  return pool;
}


- (instancetype)init {
  if (self = [super init]) {
    _beforeInfos = [[NSMutableArray alloc] init];
    _insteadInfo = nil;
    _afterInfos = [[NSMutableArray alloc] init];
    _identifiers = [[NSMutableArray alloc] init];
    _lock = [[NSLock alloc] init];
  }
  return self;
}


- (void)setTypeEncoding:(NSString *)typeEncoding {
  _typeEncoding = typeEncoding;
  _signature = typeEncoding ? [[STMethodSignature alloc] initWithObjCTypes:typeEncoding] : nil;
  _ns_signature = typeEncoding ? [NSMethodSignature signatureWithObjCTypes:[typeEncoding UTF8String]]: nil;
  _argsCount = _signature.argumentTypes.count;
}


- (void)setHookedCls:(Class)hookedCls {
  _hookedCls = hookedCls;
  _isInstanceHook = [NSStringFromClass(hookedCls) hasPrefix:STClassPrefix];
}


- (void)setSel:(SEL)sel {
  _sel = sel;
  _uniqueKey = NSSelectorFromString([NSString stringWithFormat:@"%@%@", STSelectorPrefix, NSStringFromSelector(sel)]);
}


- (BOOL)addInfo:(id<STHookInfo>)info {
  NSParameterAssert(info);
  [_lock lock];
  if (![_identifiers containsObject:info.identifier]) {
    switch (info.option) {
      case STOptionBefore: {
        [_beforeInfos addObject:info];
        break;
      }
      case STOptionInstead: {
        _insteadInfo = info;
        break;
      }
      case STOptionAfter:
      default: {
        [_afterInfos addObject:info];
        break;
      }
    }
    [_identifiers addObject:info.identifier];
    [_lock unlock];
    return YES;
  }
  [_lock unlock];
  return NO;
}


- (BOOL)removeInfoForIdentifier:(STIdentifier)identifier {
  if ([self _removeInfoForIdentifier:identifier inInfos:self.beforeInfos]) return YES;
  if (_insteadInfo && [_insteadInfo.identifier isEqualToString:identifier]) {
    _insteadInfo = nil;
    return YES;
  }
  if ([self _removeInfoForIdentifier:identifier inInfos:self.afterInfos]) return YES;
  return NO;
}


- (StingerIMP)stingerIMP {
  if (_stingerIMP == NULL) {
    ffi_type *returnType = st_ffiTypeWithType(self.signature.returnType);
    NSAssert(returnType, @"can't find a ffi_type of %@", self.signature.returnType);
    
    NSUInteger argumentCount = self->_argsCount;
    _args = malloc(sizeof(ffi_type *) * argumentCount) ;
    
    for (int i = 0; i < argumentCount; i++) {
      ffi_type* current_ffi_type = st_ffiTypeWithType(self.signature.argumentTypes[i]);
      NSAssert(current_ffi_type, @"can't find a ffi_type of %@", self.signature.argumentTypes[i]);
      _args[i] = current_ffi_type;
    }
    
    _closure = ffi_closure_alloc(sizeof(ffi_closure), (void **)&_stingerIMP);
    
    if(ffi_prep_cif(&_cif, FFI_DEFAULT_ABI, (unsigned int)argumentCount, returnType, _args) == FFI_OK) {
      if (ffi_prep_closure_loc(_closure, &_cif, _st_ffi_function, (__bridge void *)(self), _stingerIMP) != FFI_OK) {
        NSAssert(NO, @"genarate IMP failed");
      }
    } else {
      NSAssert(NO, @"FUCK");
    }
    
    [self _genarateBlockCif];
  }
  return _stingerIMP;
}


- (void)dealloc {
  if (_closure != NULL) ffi_closure_free(_closure);
  if (_args != NULL) free(_args);
  if (_blockArgs != NULL) free(_blockArgs);
}

#pragma mark - Private methods

- (BOOL)_removeInfoForIdentifier:(STIdentifier)identifier inInfos:(NSMutableArray<id<STHookInfo>> *)infos {
  [_lock lock];
  BOOL flag = NO;
  for (int i = 0; i < infos.count; i ++) {
    id<STHookInfo> info = infos[i];
    if ([info.identifier isEqualToString:identifier]) {
      [infos removeObject:info];
      [_identifiers removeObject:identifier];
      flag = YES;
      break;
    }
  }
  [_lock unlock];
  return flag;
}

- (void)_genarateBlockCif {
  ffi_type *returnType = st_ffiTypeWithType(self.signature.returnType);
  
  NSUInteger argumentCount = self->_argsCount;
  _blockArgs = malloc(sizeof(ffi_type *) *argumentCount);
  
  ffi_type *current_ffi_type_0 = st_ffiTypeWithType(@"@?");
  _blockArgs[0] = current_ffi_type_0;
  ffi_type *current_ffi_type_1 = st_ffiTypeWithType(@"@");
  _blockArgs[1] = current_ffi_type_1;
  
  for (int i = 2; i < argumentCount; i++){
    ffi_type* current_ffi_type = st_ffiTypeWithType(self.signature.argumentTypes[i]);
    _blockArgs[i] = current_ffi_type;
  }
  
  if(ffi_prep_cif(&_blockCif, FFI_DEFAULT_ABI, (unsigned int)argumentCount, returnType, _blockArgs) != FFI_OK) {
    NSAssert(NO, @"FUCK");
  }
}


#pragma mark - _st_ffi_function

#define REAL_STATED_CALSS_INFO_POOL (statedClassInfoPool ?: hookedClassInfoPool)

#define ffi_call_infos(infos) \
for (STHookInfo *info in infos) { \
  innerArgs[0] = &(info->_block); \
  ffi_call(&(hookedClassInfoPool->_blockCif), _st_impForBlock(info->_block), NULL, innerArgs); \
}  \

NS_INLINE void _st_ffi_function(ffi_cif *cif, void *ret, void **args, void *userdata) {
  STHookInfoPool *hookedClassInfoPool = (__bridge STHookInfoPool *)userdata;
  STHookInfoPool *statedClassInfoPool = nil;
  STHookInfoPool *instanceInfoPool = nil;
  
  void **innerArgs = alloca(hookedClassInfoPool->_argsCount * sizeof(*innerArgs));
  void **slf = args[0];
  
  if (hookedClassInfoPool->_isInstanceHook) {
    statedClassInfoPool = _st_fast_get_HookInfoPool(hookedClassInfoPool->_statedCls, hookedClassInfoPool->_uniqueKey);
    instanceInfoPool = _st_fast_get_HookInfoPool((__bridge id)(*slf), hookedClassInfoPool->_uniqueKey);
  }

  StingerParams *params = [[StingerParams alloc] initWithType:hookedClassInfoPool->_typeEncoding originalIMP:hookedClassInfoPool->_originalIMP sel:hookedClassInfoPool->_sel args:args];
  innerArgs[1] = &params;
  
  memcpy(innerArgs + 2, args + 2, (hookedClassInfoPool->_argsCount - 2) * sizeof(*args));
  
  // before hooks
  if (REAL_STATED_CALSS_INFO_POOL) ffi_call_infos(REAL_STATED_CALSS_INFO_POOL->_beforeInfos);
  if (instanceInfoPool) ffi_call_infos(instanceInfoPool->_beforeInfos);

  // instead hooks
  if (instanceInfoPool && instanceInfoPool->_insteadInfo) {
    innerArgs[0] = &(((STHookInfo *)(instanceInfoPool->_insteadInfo))->_block);
    ffi_call(&(hookedClassInfoPool->_blockCif), _st_impForBlock(((STHookInfo *)(instanceInfoPool->_insteadInfo))->_block), ret, innerArgs);
  } else if (REAL_STATED_CALSS_INFO_POOL && REAL_STATED_CALSS_INFO_POOL->_insteadInfo) {
    innerArgs[0] = &(((STHookInfo *)(REAL_STATED_CALSS_INFO_POOL->_insteadInfo))->_block);
    ffi_call(&(hookedClassInfoPool->_blockCif), _st_impForBlock(((STHookInfo *)(REAL_STATED_CALSS_INFO_POOL->_insteadInfo))->_block), ret, innerArgs);
  } else {
    /// original IMP
    /// if original selector is hooked by aspects or jspatch.., which use message-forwarding, invoke invacation.
    BOOL isForward = hookedClassInfoPool->_originalIMP == _objc_msgForward
#if !defined(__arm64__)
    || hookedClassInfoPool->_originalIMP == (IMP)_objc_msgForward_stret
#endif
    ;
    if (isForward) {
      [params invokeAndGetOriginalRetValue:ret];
    } else {
      ffi_call(cif, (void (*)(void))hookedClassInfoPool->_originalIMP, ret, args);
    }
  }
  // after hooks
  if (REAL_STATED_CALSS_INFO_POOL) ffi_call_infos(REAL_STATED_CALSS_INFO_POOL->_afterInfos);
  if (instanceInfoPool) ffi_call_infos(instanceInfoPool->_afterInfos);
}


#pragma mark - Get or set HookInfoPool

void st_setHookInfoPool(id obj, SEL key, id<STHookInfoPool> infoPool) {
  NSCParameterAssert(obj);
  NSCParameterAssert(key);
  objc_setAssociatedObject(obj, NSSelectorFromString([STSelectorPrefix stringByAppendingString:NSStringFromSelector(key)]), infoPool, OBJC_ASSOCIATION_RETAIN);
}


id<STHookInfoPool> st_getHookInfoPool(id obj, SEL key) {
  NSCParameterAssert(obj);
  NSCParameterAssert(key);
  return objc_getAssociatedObject(obj, NSSelectorFromString([NSString stringWithFormat:@"%@%@", STSelectorPrefix, NSStringFromSelector(key)]));
}


// mush faster than id<STHookInfoPool> st_getHookInfoPool(id obj, SEL key)
NS_INLINE id<STHookInfoPool> _st_fast_get_HookInfoPool(id obj, SEL uqiqueKey) {
  return objc_getAssociatedObject(obj, uqiqueKey);
}

@end
