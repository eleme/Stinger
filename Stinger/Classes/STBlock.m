//
//  STBlock.m
//  Stinger
//
//  Created by Assuner on 2018/1/9.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import "STBlock.h"
#import <objc/runtime.h>

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

#define NSBlock NSClassFromString(@"NSBlock")

void addInstanceMethodForBlock(SEL sel) {
  Method m = class_getInstanceMethod(STBlock.class, sel);
  if (!m) return;
  IMP imp = method_getImplementation(m);
  const char *typeEncoding = method_getTypeEncoding(m);
  class_addMethod(NSBlock, sel, imp, typeEncoding);
}

@implementation STBlock

+ (void)load {
  addInstanceMethodForBlock(@selector(signature));
  addInstanceMethodForBlock(@selector(blockIMP));
}

NSString *signatureForBlock(id block) {
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

BlockIMP impForBlock(id block) {
  struct Block_layout *layout = (__bridge void *)block;
  return layout->invoke;
}

- (NSString *)signature {
  return signatureForBlock(self);
}

- (BlockIMP)blockIMP {
  return impForBlock(self);
}



@end
