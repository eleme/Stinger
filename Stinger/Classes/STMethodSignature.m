//
//  STMethodSignature.m
//  Stinger
//
//  Created by Assuner on 2018/1/9.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import "STMethodSignature.h"

@implementation STMethodSignature {
  NSString *_typeNames;
  NSMutableArray *_argumentTypes;
  NSString *_returnType;
  NSString *_types;
}

- (instancetype)initWithObjCTypes:(NSString *)objCTypes {
  self = [super init];
  if (self) {
    _types = objCTypes;
    [self _genarateTypes];
  }
  return self;
}

- (NSArray *)argumentTypes {
  return _argumentTypes;
}

- (NSString *)types {
  return _types;
}

- (NSString *)returnType {
  return _returnType;
}

ffi_type *st_ffiTypeWithType(NSString *type) {
  return _st_ffiTypeWithType(type.UTF8String);
}


#pragma mark - Private

/*
 *  sel: v24@0:8@16 -> v,@,:,@
 *  block: v24@?0@\"<StingerParams>\"8@\"NSString\"16 -> v,@?,@,@
 */
- (void)_genarateTypes {
  _argumentTypes = [[NSMutableArray alloc] init];
  NSInteger descNum1 = 0; // num of '\"' in signature type encoding
  NSInteger descNum2 = 0; // num of '<' in block signature type encoding
  NSInteger descNum3 = 0; // num of '{' in signature type encoding
  NSInteger structBLoc = 0; // loc of '{' in signature type encoding
  NSInteger structELoc = 0; // loc of '}' in signature type encoding
  BOOL skipNext;
  NSString *arg;
  NSMutableArray *argArray = [NSMutableArray array];
  
  for (int i = 0; i < _types.length; i ++) {
    unichar c = [_types characterAtIndex:i];
    skipNext = NO;
    arg = nil;
    
    if (c == '\"') ++descNum1;
    if ((descNum1 % 2) != 0 || c == '\"' || isdigit(c)) {
      continue;
    }
    
    
    if (c == '<') ++descNum2;
    if (descNum2 > 0) {
      if (c == '>') {
        --descNum2;
      }
      continue;
    }
      
      
    if (c == '{') {
      if (descNum3 == 0) {
        structBLoc = i;
      }
      ++descNum3;
    }
    if (descNum3 > 0) {
      if (c == '}') {
        --descNum3;
        if (descNum3 == 0) {
          structELoc = i;
          arg = [_types substringWithRange:NSMakeRange(structBLoc, structELoc - structBLoc + 1)];
          structBLoc = 0;
          structELoc = 0;
        }
      }
        
      if (descNum3 > 0) {
        continue;
      }
    }
      
    
    if (!arg) {
      if (c == '^') {
        skipNext = YES;
        arg = [_types substringWithRange:NSMakeRange(i, 2)];
      } else if (c == '?') {
        // @? is block
        arg = [_types substringWithRange:NSMakeRange(i - 1, 2)];
        [argArray removeLastObject];
      } else {
        arg = [_types substringWithRange:NSMakeRange(i, 1)];
      }
    }
    
    if (arg) {
      [argArray addObject:arg];
    }
    if (skipNext) i++;
  }

  if (argArray.count > 1) {
    _returnType = argArray.firstObject;
    [argArray removeObjectAtIndex:0];
    _argumentTypes = argArray;
  }
}


NS_INLINE ffi_type *_st_ffiTypeWithType(const char *c) {
  switch (c[0]) {
      case 'v':
        return &ffi_type_void;
      case 'c':
        return &ffi_type_schar;
      case 'C':
        return &ffi_type_uchar;
      case 's':
        return &ffi_type_sshort;
      case 'S':
        return &ffi_type_ushort;
      case 'i':
        return &ffi_type_sint;
      case 'I':
        return &ffi_type_uint;
      case 'l':
        return &ffi_type_slong;
      case 'L':
        return &ffi_type_ulong;
      case 'q':
        return &ffi_type_sint64;
      case 'Q':
        return &ffi_type_uint64;
      case 'f':
        return &ffi_type_float;
      case 'd':
        return &ffi_type_double;
      case 'F':
  #if CGFLOAT_IS_DOUBLE
        return &ffi_type_double;
  #else
        return &ffi_type_float;
  #endif
      case 'B':
        return &ffi_type_uint8;
      case '^':
        return &ffi_type_pointer;
      case '*':
        return &ffi_type_pointer;
      case '@':
        return &ffi_type_pointer;
      case '#':
        return &ffi_type_pointer;
      case ':':
        return &ffi_type_pointer;
      case '{': {
        // http://www.chiark.greenend.org.uk/doc/libffi-dev/html/Type-Example.html
        ffi_type *type = malloc(sizeof(ffi_type));
        type->type = FFI_TYPE_STRUCT;
        NSUInteger size = 0;
        NSUInteger alignment = 0;
        NSGetSizeAndAlignment(c, &size, &alignment);
        type->alignment = alignment;
        type->size = size;
        while (c[0] != '=') ++c; ++c;
        
        NSPointerArray *pointArray = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsOpaqueMemory];
        while (c[0] != '}') {
          ffi_type *elementType = NULL;
          elementType = _st_ffiTypeWithType(c);
          if (elementType) {
            [pointArray addPointer:elementType];
            c = NSGetSizeAndAlignment(c, NULL, NULL);
          } else {
            return NULL;
          }
        }
        NSInteger count = pointArray.count;
        ffi_type **types = malloc(sizeof(ffi_type *) * (count + 1));
        for (NSInteger i = 0; i < count; i++) {
          types[i] = [pointArray pointerAtIndex:i];
        }
        types[count] = NULL; // terminated element is NULL
        
        type->elements = types;
        return type;
      }
    }
    return NULL;
}

@end
