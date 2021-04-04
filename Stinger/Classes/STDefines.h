//
//  STDefines.h
//  Pods
//
//  Created by 李永光 on 2019/12/11.
//

#ifndef STDefines_h
#define STDefines_h

typedef NSString *STIdentifier;
typedef void *StingerIMP;


#pragma mark - enum

typedef NS_OPTIONS(NSInteger, STOption) {
  STOptionAfter = 0,     // Called after the original implementation (default)
  STOptionInstead = 1,   // Will replace the original implementation.
  STOptionBefore = 2,    // Called before the original implementation.
  STOptionAutomaticRemoval = 1 << 3 // Will remove the hook after the first execution.
};


typedef NS_ENUM(NSInteger, STHookResult) {
  STHookResultSuccuss = 1,
  STHookResultErrorMethodNotFound = -1,
  STHookResultErrorBlockNotMatched = -2,
  STHookResultErrorIDExisted = -3,
  STHookResultOther = -4,
};


#pragma mark - protocol

@protocol STHookInfo <NSObject>
@required
@property (nonatomic, copy) id block;
@property (nonatomic, assign) STOption option;
@property (nonatomic, copy) STIdentifier identifier;

@optional
+ (instancetype)infoWithOption:(STOption)option withIdentifier:(STIdentifier)identifier withBlock:(id)block;
@end


@protocol StingerParams
@required
- (id)slf;
- (SEL)sel;
- (void)invokeAndGetOriginalRetValue:(void *)retLoc;

/// 调用原实现, 需要重新传入消息接收目标target和其余参数(如果有的话)
/// @param target 接收目标
- (NSValue *)invokeOriginalWithTarget:(id)target, ... ;
@end


@protocol STHookInfoPool <NSObject>
@required
@property (nonatomic, strong, readonly) NSMutableArray<id<STHookInfo>> *beforeInfos;
@property (nonatomic, strong, readonly) id<STHookInfo> insteadInfo;
@property (nonatomic, strong, readonly) NSMutableArray<id<STHookInfo>> *afterInfos;
@property (nonatomic, copy) NSString *typeEncoding;
@property (nonatomic) IMP originalIMP;
@property (nonatomic) SEL sel;
@property (nonatomic) StingerIMP stingerIMP;

- (BOOL)addInfo:(id<STHookInfo>)info;
- (BOOL)removeInfoForIdentifier:(STIdentifier)identifier;
- (NSArray<STIdentifier> *)allIdentifiers;

@optional
@property (nonatomic, weak) Class hookedCls;
@property (nonatomic, weak) Class statedCls;
@property (nonatomic, assign) BOOL isInstanceHook;

+ (instancetype)poolWithTypeEncoding:(NSString *)typeEncoding originalIMP:(IMP)imp selector:(SEL)sel;
@end


#endif /* STDefines_h */
