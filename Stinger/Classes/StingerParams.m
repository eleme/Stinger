//
//  StingerParams.m
//  Stinger
//
//  Created by Assuner on 2018/1/10.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import "StingerParams.h"
#import <objc/runtime.h>

@interface NSInvocation (STInvoke)
- (void)invokeUsingIMP:(IMP)imp;
@end

@interface StingerParams ()
@property (nonatomic, strong) NSString *types;
@property (nonatomic) SEL sel;
@property (nonatomic) IMP originalIMP;
@property (nonatomic) void **args;
@end

@implementation StingerParams

- (instancetype)initWithType:(NSString *)types originalIMP:(IMP)imp sel:(SEL)sel args:(void **)args {
  if (self = [super init]) {
    _types = types;
    _sel = sel;
    _originalIMP = imp;
    _args = args;
  }
  return self;
}

- (id)slf {
  void **slfPointer = _args[0];
  return (__bridge id)(*slfPointer);
}

- (SEL)sel {
  return _sel;
}


- (void)invokeAndGetOriginalRetValue:(void *)retLoc {
  NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:_types.UTF8String];
  NSInteger count = signature.numberOfArguments;
  NSInvocation *originalInvocation = [NSInvocation invocationWithMethodSignature:signature];
  for (int i = 0; i < count; i ++) {
    [originalInvocation setArgument:_args[i] atIndex:i];
  }
  [originalInvocation invokeUsingIMP:_originalIMP];
  if (originalInvocation.methodSignature.methodReturnLength && !(retLoc == NULL)) {
    [originalInvocation getReturnValue:retLoc];
  }
}

- (void *)invokeOriginalWithTarget:(id)target, ... {
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:_types.UTF8String];
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:signature];
    // 传参
    [inv setTarget:target];
    [inv setArgument:_args[1] atIndex:1];
    
    va_list args;
    va_start(args, target);
    
    NSInteger count = signature.numberOfArguments;
    for (int index = 2; index < count; index++) {
        char *type = (char *)[signature getArgumentTypeAtIndex:index];
        while (*type == 'r' || // const
               *type == 'n' || // in
               *type == 'N' || // inout
               *type == 'o' || // out
               *type == 'O' || // bycopy
               *type == 'R' || // byref
               *type == 'V') { // oneway
            type++; // cutoff useless prefix
        }
        
        BOOL unsupportedType = NO;
        switch (*type) {
            case 'v': // 1: void
            case 'B': // 1: bool
            case 'c': // 1: char / BOOL
            case 'C': // 1: unsigned char
            case 's': // 2: short
            case 'S': // 2: unsigned short
            case 'i': // 4: int / NSInteger(32bit)
            case 'I': // 4: unsigned int / NSUInteger(32bit)
            case 'l': // 4: long(32bit)
            case 'L': // 4: unsigned long(32bit)
            { // 'char' and 'short' will be promoted to 'int'.
                int arg = va_arg(args, int);
                [inv setArgument:&arg atIndex:index];
            } break;
                
            case 'q': // 8: long long / long(64bit) / NSInteger(64bit)
            case 'Q': // 8: unsigned long long / unsigned long(64bit) / NSUInteger(64bit)
            {
                long long arg = va_arg(args, long long);
                [inv setArgument:&arg atIndex:index];
            } break;
                
            case 'f': // 4: float / CGFloat(32bit)
            { // 'float' will be promoted to 'double'.
                double arg = va_arg(args, double);
                float argf = arg;
                [inv setArgument:&argf atIndex:index];
            } break;
                
            case 'd': // 8: double / CGFloat(64bit)
            {
                double arg = va_arg(args, double);
                [inv setArgument:&arg atIndex:index];
            } break;
                
            case 'D': // 16: long double
            {
                long double arg = va_arg(args, long double);
                [inv setArgument:&arg atIndex:index];
            } break;
                
            case '*': // char *
            case '^': // pointer
            {
                void *arg = va_arg(args, void *);
                [inv setArgument:&arg atIndex:index];
            } break;
                
            case ':': // SEL
            {
                SEL arg = va_arg(args, SEL);
                [inv setArgument:&arg atIndex:index];
            } break;
                
            case '#': // Class
            {
                Class arg = va_arg(args, Class);
                [inv setArgument:&arg atIndex:index];
            } break;
                
            case '@': // id
            {
                id arg = va_arg(args, id);
                [inv setArgument:&arg atIndex:index];
            } break;
                
            case '{': // struct
            {
                if (strcmp(type, @encode(CGPoint)) == 0) {
                    CGPoint arg = va_arg(args, CGPoint);
                    [inv setArgument:&arg atIndex:index];
                } else if (strcmp(type, @encode(CGSize)) == 0) {
                    CGSize arg = va_arg(args, CGSize);
                    [inv setArgument:&arg atIndex:index];
                } else if (strcmp(type, @encode(CGRect)) == 0) {
                    CGRect arg = va_arg(args, CGRect);
                    [inv setArgument:&arg atIndex:index];
                } else if (strcmp(type, @encode(CGVector)) == 0) {
                    CGVector arg = va_arg(args, CGVector);
                    [inv setArgument:&arg atIndex:index];
                } else if (strcmp(type, @encode(CGAffineTransform)) == 0) {
                    CGAffineTransform arg = va_arg(args, CGAffineTransform);
                    [inv setArgument:&arg atIndex:index];
                } else if (strcmp(type, @encode(CATransform3D)) == 0) {
                    CATransform3D arg = va_arg(args, CATransform3D);
                    [inv setArgument:&arg atIndex:index];
                } else if (strcmp(type, @encode(NSRange)) == 0) {
                    NSRange arg = va_arg(args, NSRange);
                    [inv setArgument:&arg atIndex:index];
                } else if (strcmp(type, @encode(UIOffset)) == 0) {
                    UIOffset arg = va_arg(args, UIOffset);
                    [inv setArgument:&arg atIndex:index];
                } else if (strcmp(type, @encode(UIEdgeInsets)) == 0) {
                    UIEdgeInsets arg = va_arg(args, UIEdgeInsets);
                    [inv setArgument:&arg atIndex:index];
                } else {
                    unsupportedType = YES;
                }
            } break;
                
            case '(': // union
            {
                unsupportedType = YES;
            } break;
                
            case '[': // array
            {
                unsupportedType = YES;
            } break;
                
            default: // what?!
            {
                unsupportedType = YES;
            } break;
        }
        
        if (unsupportedType) {
            // Try with some dummy type...
            
            NSUInteger size = 0;
            NSGetSizeAndAlignment(type, &size, NULL);
            
#define case_size(_size_) \
else if (size <= 4 * _size_ ) { \
    struct dummy { char tmp[4 * _size_]; }; \
    struct dummy arg = va_arg(args, struct dummy); \
    [inv setArgument:&arg atIndex:index]; \
}
            if (size == 0) { }
            case_size( 1) case_size( 2) case_size( 3) case_size( 4)
            case_size( 5) case_size( 6) case_size( 7) case_size( 8)
            case_size( 9) case_size(10) case_size(11) case_size(12)
            case_size(13) case_size(14) case_size(15) case_size(16)
            case_size(17) case_size(18) case_size(19) case_size(20)
            case_size(21) case_size(22) case_size(23) case_size(24)
            case_size(25) case_size(26) case_size(27) case_size(28)
            case_size(29) case_size(30) case_size(31) case_size(32)
            case_size(33) case_size(34) case_size(35) case_size(36)
            case_size(37) case_size(38) case_size(39) case_size(40)
            case_size(41) case_size(42) case_size(43) case_size(44)
            case_size(45) case_size(46) case_size(47) case_size(48)
            case_size(49) case_size(50) case_size(51) case_size(52)
            case_size(53) case_size(54) case_size(55) case_size(56)
            case_size(57) case_size(58) case_size(59) case_size(60)
            case_size(61) case_size(62) case_size(63) case_size(64)
            else {
                /*
                 Larger than 256 byte?! I don't want to deal with this stuff up...
                 Ignore this argument.
                 */
                struct dummy {char tmp;};
                for (int i = 0; i < size; i++) va_arg(args, struct dummy);
                NSLog(@"StingerParams invokeOriginalAndGetReturnValue unsupported type:%s (%lu bytes)",
                      [signature getArgumentTypeAtIndex:index],(unsigned long)size);
            }
#undef case_size

        }
    }
    
    va_end(args);
    
    // 调用原实现
    [inv invokeUsingIMP:_originalIMP];
    size_t returnSize = inv.methodSignature.methodReturnLength;
    if (returnSize) {
        // 申请栈上内存
        void *buffer = alloca(returnSize);
        [inv getReturnValue:buffer];
        return buffer;
    }
    return nil;
}

@end
