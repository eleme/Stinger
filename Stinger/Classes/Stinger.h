//
//  Stinger.h
//  Stinger
//
//  Created by Assuner on 2018/1/9.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StingerParams.h"

typedef NSString *STIdentifier;

typedef NS_ENUM(NSInteger, STOption) {
  STOptionAfter = 0,
  STOptionInstead = 1,
  STOptionBefore = 2,
};

@interface NSObject (Stinger)

+ (BOOL)st_hookInstanceMethod:(SEL)sel option:(STOption)option usingIdentifier:(STIdentifier)Identifier withBlock:(id)block;

+ (BOOL)st_hookClassMethod:(SEL)sel option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block;

@end
