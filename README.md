![](https://github.com/Assuner-Lee/resource/blob/master/Stinger-2.jpg)
[![CI Status](http://img.shields.io/travis/Assuner-Lee/Stinger.svg?style=flat)](https://travis-ci.org/Assuner-Lee/Stinger)
[![Version](https://img.shields.io/cocoapods/v/Stinger.svg?style=flat)](http://cocoapods.org/pods/Stinger)
[![License](https://img.shields.io/cocoapods/l/Stinger.svg?style=flat)](http://cocoapods.org/pods/Stinger)
[![Platform](https://img.shields.io/cocoapods/p/Stinger.svg?style=flat)](http://cocoapods.org/pods/Stinger)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.
```
@import UIKit;

@interface ASViewController : UIViewController

- (void)print1:(NSString *)s;

- (NSString *)print2:(NSString *)s;

- (void)print3:(NSString *)s;

+ (void)class_print:(NSString *)s;

@end
```
...

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

[self st_hookInstanceMethod:@selector(print1:) option:STOptionBefore usingIdentifier:@"hook_print1_before2" withBlock:^(id<StingerParams> params, NSString *s) {
NSLog(@"---before2 print1: %@", s);
}];

[self st_hookInstanceMethod:@selector(print1:) option:STOptionAfter usingIdentifier:@"hook_print1_after1" withBlock:^(id<StingerParams> params, NSString *s) {
NSLog(@"---after1 print1: %@", s);
}];

[self st_hookInstanceMethod:@selector(print1:) option:STOptionAfter usingIdentifier:@"hook_print1_after2" withBlock:^(id<StingerParams> params, NSString *s) {
NSLog(@"---after2 print1: %@", s);
}];

/*
* hook @selector(print2:)
*/

__block NSString *oldRet, *newRet;
[self st_hookInstanceMethod:@selector(print2:) option:STOptionInstead usingIdentifier:@"hook_print2_instead" withBlock:^NSString * (id<StingerParams> params, NSString *s) {
[params invokeAndGetOriginalRetValue:&oldRet];
newRet = [oldRet stringByAppendingString:@" ++ new-st_instead"];
NSLog(@"---instead print2 old ret: (%@) / new ret: (%@)", oldRet, newRet);
return newRet;
}];

[self st_hookInstanceMethod:@selector(print2:) option:STOptionAfter usingIdentifier:@"hook_print2_after1" withBlock:^(id<StingerParams> params, NSString *s) {
NSLog(@"---after1 print2 self:%@ SEL: %@ p: %@",[params slf], NSStringFromSelector([params sel]), s);
}];
}
@end

```

## Requirements

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
