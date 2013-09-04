//
//  AppDelegate.h
//  Alarm
//
//  Created by 廣川政樹 on 2013/09/04.
//  Copyright (c) 2013年 Masaki Hirokawa. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

#pragma mark property prototype
@property (strong, nonatomic) UIWindow *window;

#pragma mark method prototype
- (void)setIdleTimer:(BOOL)isDisabled;

@end
