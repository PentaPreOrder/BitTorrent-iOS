//
//  AppDelegate.m
//  Example
//
//  Created by xinglei on 2020/9/10.
//  Copyright © 2020 xinglei. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [UIWindow new];
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:[ViewController new]];
    self.window.rootViewController = navi;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
