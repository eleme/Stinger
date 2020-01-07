//
//  STHookInfo.h
//  Stinger
//
//  Created by Assuner on 2018/1/9.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Stinger/STDefines.h>

@interface STHookInfo : NSObject <STHookInfo>
{
  @public
  id _block;
  BOOL automaticRemoval;
}
@end
