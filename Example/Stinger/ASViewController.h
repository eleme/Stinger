//
//  ASViewController.h
//  Stinger
//
//  Created by Assuner on 12/05/2017.
//  Copyright (c) 2017 Assuner. All rights reserved.
//

@import UIKit;

typedef double (^testBlock)(double x, double y);

@interface ASViewController : UIViewController

- (void)print1:(NSString *)s;

- (NSString *)print2:(NSString *)s;

- (void)print3:(NSString *)s;

- (void)testBlock:(testBlock)block;

+ (void)class_print:(NSString *)s;

@end
