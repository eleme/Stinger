![](https://github.com/Assuner-Lee/resource/blob/master/Stinger-2.jpg)
[![CI Status](http://img.shields.io/travis/Assuner-Lee/Stinger.svg?style=flat)](https://travis-ci.org/Assuner-Lee/Stinger)
[![Version](https://img.shields.io/cocoapods/v/Stinger.svg?style=flat)](http://cocoapods.org/pods/Stinger)
[![License](https://img.shields.io/cocoapods/l/Stinger.svg?style=flat)](http://cocoapods.org/pods/Stinger)
[![Platform](https://img.shields.io/cocoapods/p/Stinger.svg?style=flat)](http://cocoapods.org/pods/Stinger)

Stinger is a high-efficiency library with great compatibility, for aop in Objective-C. It allows you to add code to existing methods, whilst thinking of the insertion point e.g. before/instead/after. Aspects automatically deals with calling super and is easier to use than regular method swizzling, **using libffi instead of Objective-C message forwarding**.

Stinger extends NSObject with the following methods:

```
typedef NSString *STIdentifier;

typedef NS_ENUM(NSInteger, STOption) {
  STOptionAfter = 0,
  STOptionInstead = 1,
  STOptionBefore = 2,
};

@interface NSObject (Stinger)

+ (BOOL)st_hookInstanceMethod:(SEL)sel option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block;

+ (BOOL)st_hookClassMethod:(SEL)sel option:(STOption)option usingIdentifier:(STIdentifier)identifier withBlock:(id)block;

+ (NSArray<STIdentifier> *)st_allIdentifiersForKey:(SEL)key;

+ (BOOL)st_removeHookWithIdentifier:(STIdentifier)identifier forKey:(SEL)key;

@end
```
STIdentifier is a identification of per hook in per class, which can be used to remove hook again.

Stinger uses libffi to hook into messages, not Objective-C message forwarding. This will creat very little overhead compared to Aspects. It can be used in code called 1000 times per second.

Stinger calls and matches block arguments. Blocks without arguments are supported as well. The first block argument will be of type id<StingerParams>.

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

### Using Stinger with void return types

```
#import "ASViewController+hook.h"

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

### Using Stinger with non-void return types

```
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

## License

Stinger is available under the MIT license. See the LICENSE file for more info.
