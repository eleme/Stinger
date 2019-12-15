![](https://github.com/Assuner-Lee/resource/blob/master/Stinger-2.jpg)
[![CI Status](http://img.shields.io/travis/Assuner-Lee/Stinger.svg?style=flat)](https://travis-ci.org/Assuner-Lee/Stinger)
[![Version](https://img.shields.io/cocoapods/v/Stinger.svg?style=flat)](http://cocoapods.org/pods/Stinger)
[![License](https://img.shields.io/cocoapods/l/Stinger.svg?style=flat)](http://cocoapods.org/pods/Stinger)
[![Platform](https://img.shields.io/cocoapods/p/Stinger.svg?style=flat)](http://cocoapods.org/pods/Stinger)

#### [中文说明](https://github.com/eleme/Stinger/blob/master/README_%E4%B8%AD%E6%96%87.md)   [相关文章1](https://juejin.im/post/5a600d20518825732c539622) [相关文章2](https://juejin.im/post/5c84d4e0f265da2dda6981b4)

Stinger is a high-efficiency library with great compatibility, for aop in Objective-C. It allows you to add code to existing methods, whilst thinking of the insertion point e.g. before/instead/after. Stinger automatically deals with calling super and is easier to use than regular method swizzling, **using libffi instead of Objective-C message forwarding**. It is 20 times faster than the Aspects, from message-sending to Aspect-oriented code ends, please refer to this test case and run it. [PerformanceTests](https://github.com/eleme/Stinger/blob/master/Example/Tests/PerformanceTests.m)

Stinger extends NSObject with the following methods:

```objc
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
```
STIdentifier is a identification of per hook in per class, which can be used to remove hook again.

Stinger uses libffi to hook into messages, not Objective-C message forwarding. This will creat very little overhead compared to Aspects. It can be used in code called 1000 times per second.

Stinger calls and matches block arguments.  The first block argument will be of type `id<StingerParams>`.

## When to use Stinger

Aspect-oriented programming (AOP) is used to encapsulate "cross-cutting" concerns. These are the kind of requirements that cut-across many modules in your system, and so cannot be encapsulated using normal object oriented programming. Some examples of these kinds of requirements:

* Whenever a user invokes a method on the service client, security should be checked.
* Whenever a user interacts with the store, a genius suggestion should be presented, based on their interaction.
* All calls should be logged.

If we implemented the above requirements using regular OOP there'd be some drawbacks:
Good OOP says a class should have a single responsibility, however adding on extra cross-cutting requirements means a class that is taking on other responsibilites. For example you might have a StoreClient that is supposed to be all about making purchases from an online store. Add in some cross-cutting requirements and it might also have to take on the roles of logging, security and recommendations. This is not great because:

Our StoreClient is now harder to understand and maintain.
These cross-cutting requirements are duplicated and spread throughout our app.
AOP lets us modularize these cross-cutting requirements, and then cleanly identify all of the places they should be applied. As shown in the examples above cross-cutting requirements can be either technical or business focused in nature.

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

## Performance Tests
Please refer to [PerformanceTests.m](https://github.com/eleme/Stinger/blob/master/Example/Tests/PerformanceTests.m) and run it.
### 1. Environment
* Device：iPhone 7，iOS 13.2
* Xcode：Version 11.3 (11C29)
* Stinger：`https://github.com/eleme/Stinger` `0.2.8`
* Aspects：`https://github.com/steipete/Aspects` `1.4.1`

### 2. Test Case
#### * Preparation

```
@interface TestClassC : NSObject
- (void)methodBeforeA;
- (void)methodA;
- (void)methodAfterA;
- (void)methodA1;
- (void)methodB1;
- (void)methodA2;
- (void)methodB2;
...
@end

@implementation TestClassC
- (void)methodBeforeA {
}
- (void)methodA {
}
- (void)methodAfterA {
}
- (void)methodA1 {
}
- (void)methodB1 {
}
- (void)methodA2 {
}
- (void)methodB2 {
}
...
@end
```

#### Case1
##### Test Code 
Stinger

```
- (void)testStingerHookMethodA1 {
  [TestClassC st_hookInstanceMethod:@selector(methodA1) option:STOptionBefore usingIdentifier:@"hook methodA1 before" withBlock:^(id<StingerParams> params) {
     }];
  [TestClassC st_hookInstanceMethod:@selector(methodA1) option:STOptionAfter usingIdentifier:@"hook methodA1 After" withBlock:^(id<StingerParams> params) {
  }];
  
  TestClassC *object1 = [TestClassC new];
  [self measureBlock:^{
    for (NSInteger i = 0; i < 1000000; i++) {
      [object1 methodA1];
    }
  }];
}
```
Aspects

```
- (void)testAspectHookMethodB1 {
  [TestClassC aspect_hookSelector:@selector(methodB1) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> params) {
   } error:nil];
  [TestClassC aspect_hookSelector:@selector(methodB1) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> params) {
  } error:nil];
  
  TestClassC *object1 = [TestClassC new];
  [self measureBlock:^{
    for (NSInteger i = 0; i < 1000000; i++) {
      [object1 methodB1];
    }
  }];
}
```
##### Test Result
Stinger
![](https://user-gold-cdn.xitu.io/2019/12/15/16f08dbfb9011fad?w=1872&h=852&f=png&s=390868)

AVG|1| 2 | 3 | 4| 5| 6| 7| 8| 9| 10 
:-: |:-: |:-: |:-: |:-: |:-: |:-: |:-: |:-: |:-: |:-: |
0.283|0.368| 0.273 | 0.277 | 0.273 | 0.271 | 0.271 | 0.272| 0.271| 0.273 |0.270 |

***
Aspects
![](https://user-gold-cdn.xitu.io/2019/12/15/16f08df137616890?w=1898&h=764&f=png&s=392047)

AVG|1| 2 | 3 | 4| 5| 6| 7| 8| 9| 10 
:-: |:-: |:-: |:-: |:-: |:-: |:-: |:-: |:-: |:-: |:-: |
6.135|6.34| 6.19 | 6.12 | 6.19 | 6.11 | 6.1 | 6.12| 6.12| 0.273 |0.270 |

> More case:  https://github.com/eleme/Stinger/blob/master/Example/Tests/PerformanceTests.m


#### Case2
##### Test Code
Stinger

```
- (void)testStingerHookMethodA2 {
  TestClassC *object1 = [TestClassC new];
  [object1 st_hookInstanceMethod:@selector(methodA2) option:STOptionBefore usingIdentifier:@"hook methodA2 before" withBlock:^(id<StingerParams> params) {
     }];
  [object1 st_hookInstanceMethod:@selector(methodA2) option:STOptionAfter usingIdentifier:@"hook methodA2 After" withBlock:^(id<StingerParams> params) {
  }];
  
  [self measureBlock:^{
    for (NSInteger i = 0; i < 1000000; i++) {
      [object1 methodA2];
    }
  }];
}
```

Aspects

```
- (void)testAspectHookMethodB2 {
  TestClassC *object1 = [TestClassC new];
  [object1 aspect_hookSelector:@selector(methodB2) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> params) {
   } error:nil];
  [object1 aspect_hookSelector:@selector(methodB2) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> params) {
  } error:nil];
  
  [self measureBlock:^{
    for (NSInteger i = 0; i < 1000000; i++) {
      [object1 methodB2];
    }
  }];
}
```

##### Test Result
Stinger
![](https://user-gold-cdn.xitu.io/2019/12/15/16f08e8910ba2edd?w=1876&h=840&f=png&s=380580)

AVG|1| 2 | 3 | 4| 5| 6| 7| 8| 9| 10 
:-: |:-: |:-: |:-: |:-: |:-: |:-: |:-: |:-: |:-: |:-: |
0.547|0.567| 0.546 | 0.543 | 0.556 | 0.543 | 0.542 | 0.545| 0.54| 0.544 |0.542 |

*** 

Aspects

![](https://user-gold-cdn.xitu.io/2019/12/15/16f08f152600546b?w=1834&h=744&f=png&s=343505)

AVG|1| 2 | 3 | 4| 5| 6| 7| 8| 9| 10 
:-: |:-: |:-: |:-: |:-: |:-: |:-: |:-: |:-: |:-: |:-: |
6.261|6.32| 6.24 | 6.34 | 6.25 | 6.25 | 6.23 | 6.24| 6.26| 6.23 |6.24 |

## Credits
The idea to use libffi. It can create shell function(`ffi_prep_closure_loc`) having same types compared with signature of hooked method. we can get all arguments and invoke Aspect-oriented code in ffi_function(`void (*fun)(ffi_cif*,void*,void**,void*)`).

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
| 0.1.1 | init. | 
| 0.2.0 | support hooking specific instance.|
| 0.2.1 | Improve compatibility with hook using message-forwarding like aspects or rac.|
| 0.2.2 | fix some bug.|
| 0.2.3 | fix some bug.|
| 0.2.4 | fix specific instance hook crash.|
| 0.2.5 | chg libffi version.|
| 0.2.6 | support struct.|
| 0.2.7 | improve performance.|
| 0.2.8 | improve performance.|

## License

Stinger is available under the MIT license. See the LICENSE file for more info.


