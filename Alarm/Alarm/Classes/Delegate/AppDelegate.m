//
//  AppDelegate.m
//  Alarm
//
//  Created by 廣川政樹 on 2013/09/04.
//  Copyright (c) 2013年 Masaki Hirokawa. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //ユーザーデフォルト初期化
    userDefaults  = [NSUserDefaults standardUserDefaults];
    
    //設定適用
    [self initSettings];
    
    //ユーザーデフォルトの初回読み込みフラグ立てる
    [self setLoadedOnceUserDefaults];
    
    return YES;
}


//ロック&スリープ禁止の切り替え
- (void)setIdleTimer:(BOOL)isDisabled
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:isDisabled];
}

//設定適用
- (void)initSettings
{
    wakeUpTime     = ![self isLoadedOnceUserDefaults] ? DEFAULT_WAKE_UP_TIME : [userDefaults stringForKey:@"UD_WAKE_UP_TIME_KEY"];
    [userDefaults setObject:wakeUpTime forKey:@"UD_WAKE_UP_TIME_KEY"];
    
    [userDefaults synchronize];
}

//ユーザーデフォルトの初回読み込みフラグ立てる
- (void)setLoadedOnceUserDefaults
{
    [userDefaults setBool:YES forKey:@"UD_LOADED_ONCE"];
    [userDefaults synchronize];
}

//ユーザーデフォルトが初期状態であるか
- (BOOL)isLoadedOnceUserDefaults
{
    return [userDefaults boolForKey:@"UD_LOADED_ONCE"];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end
