//
//  ARAppDelegate.m
//  FSNetworkingSearchController
//
//  Created by alexruperez on 03/30/2015.
//  Copyright (c) 2014 alexruperez. All rights reserved.
//

#import "ARAppDelegate.h"
#import <FSNetworkingSearchController/FSNetworkingSearchController.h>

@implementation ARAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [FSNetworkingSearchController configureWithClientID:@"OD2N3R1GVY1QEXUX1VIBECCDSBF32K5MGAVDJ2GIDWXRVL3E" clientSecret:@"0TW5L1EC3TFZPCREUA4GFDKXT2DSPGANSW5WNAILTAAAI3ZQ" redirectURI:@"fsnetworkingsearchcontroller://foursquare"];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [FSNetworkingSearchController handleOpenURL:url];
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

@end
