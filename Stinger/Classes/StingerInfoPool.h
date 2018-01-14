//
//  StingerInfoPool.h
//  Stinger
//
//  Created by Assuner on 2018/1/9.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StingerInfo.h"

typedef void *StingerIMP;

@protocol StingerInfoPool <NSObject>

@required
@property (nonatomic, strong, readonly) NSMutableArray<id<StingerInfo>> *beforeInfos;
@property (nonatomic, strong, readonly) NSMutableArray<id<StingerInfo>> *insteadInfos;
@property (nonatomic, strong, readonly) NSMutableArray<id<StingerInfo>> *afterInfos;
@property (nonatomic, strong, readonly) NSMutableArray<NSString *> *identifiers;

@property (nonatomic, copy) NSString *typeEncoding;
@property (nonatomic) IMP originalIMP;
@property (nonatomic) SEL sel;

- (StingerIMP)stingerIMP;
- (BOOL)addInfo:(id<StingerInfo>)info;
- (BOOL)removeInfoForIdentifier:(STIdentifier)identifier;

@optional
@property (nonatomic, weak) Class cls;
+ (instancetype)poolWithTypeEncoding:(NSString *)typeEncoding originalIMP:(IMP)imp selector:(SEL)sel;

@end

@interface StingerInfoPool : NSObject <StingerInfoPool>

@end
