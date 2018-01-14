//
//  StingerInfo.h
//  Stinger
//
//  Created by Assuner on 2018/1/9.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Stinger.h"
#import "StingerParams.h"

@protocol StingerInfo <NSObject>

@required
@property (nonatomic, copy) id block;
@property (nonatomic, assign) STOption option;
@property (nonatomic, copy) STIdentifier identifier;

@optional
+ (instancetype)infoWithOption:(STOption)option withIdentifier:(STIdentifier)identifier withBlock:(id)block;

@end

@interface StingerInfo : NSObject <StingerInfo>

@end
