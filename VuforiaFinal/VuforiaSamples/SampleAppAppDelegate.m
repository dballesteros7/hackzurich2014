/*===============================================================================
Copyright (c) 2012-2014 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
Confidential and Proprietary - Qualcomm Connected Experiences, Inc.
Vuforia is a trademark of QUALCOMM Incorporated, registered in the United States 
and other countries. Trademarks of QUALCOMM Incorporated are used with permission.
===============================================================================*/

#import "SampleAppAppDelegate.h"
#import "SampleAppAboutViewController.h"
#import "SampleAppSelectorViewController.h"

@interface SampleAppAppDelegate()
@property (strong, nonatomic) UITabBarController *tabBarController;
@end
@implementation SampleAppAppDelegate

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    Class vc1Class = NSClassFromString(@"CloudRecoViewController");
    UIViewController *vc = [[[vc1Class alloc] initWithNibName:nil bundle:nil] autorelease];
    
    UINavigationController * nc = [[UINavigationController alloc]initWithRootViewController:vc];
    nc.navigationBar.barStyle = UIBarStyleDefault;
    
    
//    Class vc1Class = NSClassFromString(@"CloudRecoViewController");
//    UIViewController *viewController1 = [[[vc1Class alloc] initWithNibName:nil bundle:nil] autorelease];
//    nc1.title = @"Post";
//    viewController1.title = @"Cloud";
    
//    UINavigationController *nc2;
//    nc2 = [[UINavigationController alloc] init];
//    [nc2.navigationBar setTintColor:[UIColor blackColor]];
//    UIViewController *viewController2 = [[[UIViewController alloc] initWithNibName:nil bundle:nil] autorelease];;
//    nc2.viewControllers = [NSArray arrayWithObjects:viewController2, nil];
//    nc2.title = @"View";

//    self.tabBarController = [[[UITabBarController alloc] init] autorelease];
//    self.tabBarController.viewControllers = [NSArray arrayWithObjects:viewController1,viewController2,nil];
//    
//    
    self.window.rootViewController = nc;
    [self.window makeKeyAndVisible];
    [nc release];
    return YES;
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
