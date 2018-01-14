#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "ffi.h"
#import "ffitarget.h"
#import "ffitarget_arm.h"
#import "ffitarget_arm64.h"
#import "ffitarget_i386.h"
#import "ffitarget_x86_64.h"
#import "ffi_arm.h"
#import "ffi_arm64.h"
#import "ffi_i386.h"
#import "ffi_x86_64.h"
#import "MABlockClosure.h"
#import "NSObject+Stinger.h"
#import "Stinger.h"

FOUNDATION_EXPORT double StingerVersionNumber;
FOUNDATION_EXPORT const unsigned char StingerVersionString[];

