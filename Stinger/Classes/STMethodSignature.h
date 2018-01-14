//
//  STMethodSignature.h
//  Stinger
//
//  Created by Assuner on 2018/1/9.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ffi.h"

@interface STMethodSignature : NSObject

@property (nonatomic, readonly) NSString *types;
@property (nonatomic, readonly) NSArray *argumentTypes;
@property (nonatomic, readonly) NSString *returnType;

- (instancetype)initWithObjCTypes:(NSString *)objCTypes; // type encoding of method or block

ffi_type * ffiTypeWithType (NSString *type);

@end
