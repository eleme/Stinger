//
//  STHookInfoPool.h
//  Stinger
//
//  Created by Assuner on 2018/1/9.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STHookInfo.h"


typedef void *StingerIMP;

extern NSString * const STClassPrefix;
extern void st_setHookInfoPool(id obj, SEL key, id infoPool);
extern id st_getHookInfoPool(id obj, SEL key);

@protocol STHookInfoPool <NSObject>

@required
@property (nonatomic, strong, readonly) NSMutableArray<id<STHookInfo>> *beforeInfos;
@property (nonatomic, strong, readonly) NSMutableArray<id<STHookInfo>> *insteadInfos;
@property (nonatomic, strong, readonly) NSMutableArray<id<STHookInfo>> *afterInfos;
@property (nonatomic, strong, readonly) NSMutableArray<NSString *> *identifiers;

@property (nonatomic, copy) NSString *typeEncoding;
@property (nonatomic) IMP originalIMP;
@property (nonatomic) SEL sel;

- (StingerIMP)stingerIMP;
- (BOOL)addInfo:(id<STHookInfo>)info;
- (BOOL)removeInfoForIdentifier:(STIdentifier)identifier;

@optional
@property (nonatomic, weak) Class cls;
+ (instancetype)poolWithTypeEncoding:(NSString *)typeEncoding originalIMP:(IMP)imp selector:(SEL)sel;

@end

@interface STHookInfoPool : NSObject <STHookInfoPool>

@end
