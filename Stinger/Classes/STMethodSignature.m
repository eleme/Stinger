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

/*
 *  sel: v24@0:8@16 -> v,@,:,@
 *  block: v24@?0@\"<StingerParams>\"8@\"NSString\"16 -> v,@?,@,@
 */
- (void)_genarateTypes {
  _argumentTypes = [[NSMutableArray alloc] init];
  NSInteger descNum1 = 0; // num of '\"' in block signature type encoding
  NSInteger descNum2 = 0; // num of '<' or '>' in block signature type encoding
  for (int i = 0; i < _types.length; i ++) {
    unichar c = [_types characterAtIndex:i];
    
    NSString *arg;
    if (c == '\"') ++descNum1;
    if ((descNum1 % 2) != 0 || c == '\"' || isdigit(c)) {
      continue;
    }
    
    if (c == '<' || c == '>') ++descNum2;
    if ((descNum2 % 2) != 0 || c == '<' || c == '>') {
      continue;
    }
    
    BOOL skipNext = NO;
    if (c == '^') {
      skipNext = YES;
      arg = [_types substringWithRange:NSMakeRange(i, 2)];
      
    } else if (c == '?') {
      // @? is block
      arg = [_types substringWithRange:NSMakeRange(i - 1, 2)];
      [_argumentTypes removeLastObject];
      
    } else if (c == '{') {
      NSUInteger end = [[_types substringFromIndex:i] rangeOfString:@"}"].location + i;
      arg = [_types substringWithRange:NSMakeRange(i, end - i + 1)];
      if (i == 0) {
        _returnType = arg;
      } else {
        [_argumentTypes addObject:arg];
      }
      i = (int)end;
      continue;
      
    } else {
      
      arg = [_types substringWithRange:NSMakeRange(i, 1)];
    }
    
    if (i == 0) {
      _returnType = arg;
    } else {
      [_argumentTypes addObject:arg];
    }
    if (skipNext) i++;
  }
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

ffi_type * ffiTypeWithType (NSString *type) {
  if ([type isEqualToString:@"@?"]) {
    return &ffi_type_pointer;
  }
  const char *c = [type UTF8String];
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
    case '@':
      return &ffi_type_pointer;
    case '#':
      return &ffi_type_pointer;
    case ':':
      return &ffi_type_schar;
  }
  
  NSCAssert(NO, @"can't match a ffi_type of %@", type);
  return NULL;
}

@end
