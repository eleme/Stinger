//
//  STHookInfoPool.h
//  Stinger
//
//  Created by Assuner on 2018/1/9.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Stinger/STDefines.h>

extern NSString *signatureForBlock(id block);
extern NSString * const STClassPrefix;
extern void st_setHookInfoPool(id obj, SEL key, id infoPool);
extern id st_getHookInfoPool(id obj, SEL key);

@interface STHookInfoPool : NSObject <STHookInfoPool>
@end
