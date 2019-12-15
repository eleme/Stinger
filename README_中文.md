![](https://github.com/Assuner-Lee/resource/blob/master/Stinger-2.jpg)
[![CI Status](http://img.shields.io/travis/Assuner-Lee/Stinger.svg?style=flat)](https://travis-ci.org/Assuner-Lee/Stinger)
[![Version](https://img.shields.io/cocoapods/v/Stinger.svg?style=flat)](http://cocoapods.org/pods/Stinger)
[![License](https://img.shields.io/cocoapods/l/Stinger.svg?style=flat)](http://cocoapods.org/pods/Stinger)
[![Platform](https://img.shields.io/cocoapods/p/Stinger.svg?style=flat)](http://cocoapods.org/pods/Stinger)


Stinger是一个实现Objective-C AOP功能的库，有着良好的兼容性。你可以使用它在原方法的 前/替换/后位置插入(或替换)代码，实现起来比常规的方法交换更容易和灵活。**Stinger使用了libffi，没有使用OC的消息转发**。从消息发送到切面代码执行完毕，Stinger比Aspects快20倍，请参阅和运行这个`test case`。 [PerformanceTests](https://github.com/eleme/Stinger/blob/master/Example/Tests/PerformanceTests.m)

Stinger 对NSObject做了以下方法扩展：

```objc
typedef NSString *STIdentifier;

typedef NS_ENUM(NSInteger, STOption) {
  STOptionAfter = 0,     // 在原方法后调用（默认）
  STOptionInstead = 1,   // 替换原实现
  STOptionBefore = 2,    // 在原方法前调用
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

/* 在方法前后以block增加代码或替换.
* @param block. block的第一个参数必须为 `id<StingerParams>`, 后面跟着原方法的参数(如果原方法有返回值，选项为替换，则block也必须有返回值)。
* @param STIdentifier. 标识特定hook的一个字符串，同一个对象的同一个方法的hook标识不能重复，可以使用此标识去帮助移除hook。
* @return hook结果.
*/
+ (STHookResult)st_hookInstanceMethod:(SEL)sel option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block;
+ (STHookResult)st_hookClassMethod:(SEL)sel option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block;

/*
*  获得这个sel下的所有hook标识。
*/
+ (NSArray<STIdentifier> *)st_allIdentifiersForKey:(SEL)key;

/*
*  移除一个hook.
*/
+ (BOOL)st_removeHookWithIdentifier:(STIdentifier)identifier forKey:(SEL)key;


#pragma mark - For specific instance

- (STHookResult)st_hookInstanceMethod:(SEL)sel option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block;

- (NSArray<STIdentifier> *)st_allIdentifiersForKey:(SEL)key;

- (BOOL)st_removeHookWithIdentifier:(STIdentifier)identifier forKey:(SEL)key;

@end
```

STIdentifier是一个hook的标识，它可以用来帮助移除Hook。

Stinger使用libffi及解析方法签名构建壳函数，替换原方法实现以感知方法调用和捕获参数；使用同一cif模板及函数指针直接执行原实现和所有切面block。

Stinger不使用消息转发指针替换原实现，hook兼容性更好；调用方法不经过消息转发过程，执行原实现及切面代码过程中无手动构建invocation等，效率更高。

Stinger会匹配block的参数，第一个参数必须为`id<StingerParams>`。

## How to use Stinger
### For specific class
```objc
@interface ASViewController : UIViewController

- (void)print1:(NSString *)s;
- (NSString *)print2:(NSString *)s;
+ (void)class_print:(NSString *)s;

@end

```

#### Using Stinger with void return types

```objc
@implementation ASViewController (hook)

+ (void)load {
  /*
  * hook class method @selector(class_print:)
  */
  [self st_hookClassMethod:@selector(class_print:) option:STOptionBefore usingIdentifier:@"hook_class_print_before" withBlock:^(id<StingerParams> params, NSString *s) {
    NSLog(@"---before class_print: %@", s);
  }];

  /*
  * hook @selector(print1:)
  */
  [self st_hookInstanceMethod:@selector(print1:) option:STOptionBefore usingIdentifier:@"hook_print1_before1" withBlock:^(id<StingerParams> params, NSString *s) {
    NSLog(@"---before1 print1: %@", s);
  }];

```

#### Using Stinger with non-void return types

```objc
@implementation ASViewController (hook)

+ (void)load {
  __block NSString *oldRet, *newRet;
  [self st_hookInstanceMethod:@selector(print2:) option:STOptionInstead usingIdentifier:@"hook_print2_instead" withBlock:^NSString * (id<StingerParams> params, NSString *s) {
    [params invokeAndGetOriginalRetValue:&oldRet];
    newRet = [oldRet stringByAppendingString:@" ++ new-st_instead"];
    NSLog(@"---instead print2 old ret: (%@) / new ret: (%@)", oldRet, newRet);
    return newRet;
  }];
}
@end

```
### For specific instance
```objc
// For specific instance
@implementation ASViewController
- (void)viewDidLoad {
  [super viewDidLoad];
  [self st_hookInstanceMethod:@selector(print3:) option:STOptionAfter usingIdentifier:@"hook_print3_after1" withBlock:^(id<StingerParams> params, NSString *s) {
    NSLog(@"---instance after print3: %@", s);
  }];
}
@end

```

## 性能测试
[亮剑: Stinger到底能比Aspects快多少](https://juejin.im/post/5df5dcbc6fb9a0166138ff23)

## Credits
利用libffi， 可以使用(`ffi_prep_closure_loc`)创建和原方法有着相同参数和返回值的壳函数。可以在ffi_function(`void (*fun)(ffi_cif*,void*,void**,void*)`) 中得到所有的参数和调用所有的切面代码及原函数。

## Installation

Stinger is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Stinger'
```

## Author

Assuner-Lee, assuner@foxmail.com

## Release note
| version | note |
| ------ | ------ | 
| 0.1.1 | 初始化 | 
| 0.2.0 | 支持hook特定实例对象|
| 0.2.1 | 提升了与使用消息转发hook方式的兼容性，如aspects, rac等|
| 0.2.2 | 修掉一些Bug.|
| 0.2.3 | 修掉一些Bug.|
| 0.2.4 | 解决实例对象Hook的一个crash.|
| 0.2.5 | 更正libffi版本.|
| 0.2.6 | 支持结构体.|
| 0.2.7 | 提升性能.|
| 0.2.8 | 进一步提升实例对象hook的性能.|

## License

Stinger is available under the MIT license. See the LICENSE file for more info.

