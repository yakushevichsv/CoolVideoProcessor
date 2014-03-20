//
//  AppDelegate.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 5/12/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "AppDelegate.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

static NSString *g_AppKey = @"ApplicationVersion";

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self setupAudioSession];
    return YES;
}

- (void)setupAudioSession
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    
    BOOL success = [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (!success)
    {
        NSLog(@"Error %@",error);
        return;
    }
    
    success = [session setActive:YES error:&error];
    if (!success)
    {
        NSLog(@"Error %@",error);
        return;
    }
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    return [[coder decodeObjectForKey:g_AppKey] isEqualToString:[self appShortVersion]];
}

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
    return YES;
}

- (void)application:(UIApplication *)application willEncodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSString *appVersion = [self appShortVersion];
    [coder encodeObject:appVersion forKey:g_AppKey];
}
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Private Methods

- (NSString *)appShortVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

@end
