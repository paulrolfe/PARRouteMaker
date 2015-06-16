
//
//  PARAppDelegate.m
//  PARRouteMaker
//
//  Created by Paul Rolfe on 6/12/15
//  Copyright (c) 2015 paulrolfe. All rights reserved.
//

#import "PARAppDelegate.h"
#import "PARMapViewController.h"

@implementation PARAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    PARMapViewController * initalVC = [[PARMapViewController alloc] initWithNibName:@"PARMapViewController" bundle:nil];
    UINavigationController * nav = [[UINavigationController alloc] initWithRootViewController:initalVC];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    
    [[UINavigationBar appearance] setTintColor:[UIColor greenColor]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor blackColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor greenColor]}];
    [[UIBarButtonItem appearance] setTintColor:[UIColor greenColor]];
    
    return YES;
}

@end
