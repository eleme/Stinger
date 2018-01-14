//
//  StingerParams.h
//  Stinger
//
//  Created by Assuner on 2018/1/10.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ST_NO_RET NULL

@protocol StingerParams

@required
@property (nonatomic, unsafe_unretained) id slf;
@property (nonatomic) SEL sel;

- (void)invokeAndGetOriginalRetValue:(void *)retLoc;

@end


@interface StingerParams : NSObject <StingerParams>

- (void)addOriginalInvocation:(NSInvocation *)invocation;
- (void)addOriginalIMP:(IMP)imp;

@end
