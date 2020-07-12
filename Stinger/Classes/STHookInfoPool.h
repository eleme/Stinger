//
//  STHookInfoPool.h
//  Stinger
//
//  Created by Assuner on 2018/1/9.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Stinger/STDefines.h>

extern NSString *st_getSignatureForBlock(id block);
extern NSString * const STClassPrefix;
extern NSString * const KVOClassPrefix;
extern void st_setHookInfoPool(id obj, SEL key, id infoPool);
extern id st_getHookInfoPool(id obj, SEL key);
extern BOOL st_isIntanceHookCls(Class cls);

static NSString * const STSelectorPrefix = @"st_sel";

@interface STHookInfoPool : NSObject <STHookInfoPool>
@end
