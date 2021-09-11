//
//  StingerParams.h
//  Stinger
//
//  Created by Assuner on 2018/1/10.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Stinger/STDefines.h>


@interface StingerParams : NSObject <StingerParams>
- (instancetype)initWithType:(NSString *)types originalIMP:(IMP)imp sel:(SEL)sel args:(void **)args argumentTypes:(NSArray *)argumentTypes;
@end
