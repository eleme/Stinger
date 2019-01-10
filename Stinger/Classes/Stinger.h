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
  STOptionAfter = 0,     // Called after the original implementation (default)
  STOptionInstead = 1,   // Will replace the original implementation.
  STOptionBefore = 2,    // Called before the original implementation.
};

typedef NS_ENUM(NSInteger, STHookResult) {
  STHookResultSuccuss = 1,
  STHookResultErrorMethodNotFound = -1,
  STHookResultErrorBlockNotMatched = -2,
  STHookResultErrorIDExisted = -3,
  STHookResultOther = -4,
};

@interface NSObject (Stinger)

#pragma mark - For specific class

/* Adds a block of code before/instead/after the current 'sel'.
 * @param block. The first parameter will be `id<StingerParams>`, followed by all parameters of the method.
 * @param STIdentifier. The string is a identifier for a specific hook.
 * @return hook result.
 */
+ (STHookResult)st_hookInstanceMethod:(SEL)sel option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block;
+ (STHookResult)st_hookClassMethod:(SEL)sel option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block;

/*
 *  Get all hook identifiers for a specific key.
 */
+ (NSArray<STIdentifier> *)st_allIdentifiersForKey:(SEL)key;

/*
 *  Remove a specific hook.
 */
+ (BOOL)st_removeHookWithIdentifier:(STIdentifier)identifier forKey:(SEL)key;


#pragma mark - For specific instance

- (STHookResult)st_hookInstanceMethod:(SEL)sel option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block;

- (NSArray<STIdentifier> *)st_allIdentifiersForKey:(SEL)key;

- (BOOL)st_removeHookWithIdentifier:(STIdentifier)identifier forKey:(SEL)key;

@end
