//
//  iRedditAppDelegate.m
//  iReddit
//
//  Created by Ross Boucher on 6/18/09.
//  Copyright 280 North 2009. All rights reserved.
//

#import "iRedditAppDelegate.h"


extern NSMutableArray *visitedArray;

iRedditAppDelegate *sharedAppDelegate;

@implementation iRedditAppDelegate

+ (UIColor *)redditNavigationBarTintColor
{
	return [UIColor colorWithRed:60.0/255.0 green:120.0/255.0 blue:225.0/255.0 alpha:1.0];
}

+ (iRedditAppDelegate *)sharedAppDelegate
{
	return sharedAppDelegate;
}

@synthesize window, navController, messageDataSource;
-(void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    NSLog(@"Memory Warning!!!!!!");
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}
- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    int cacheSizeMemory = 4*1024*1024; // 4MB
    int cacheSizeDisk = 5*1024*1024; // 32MB
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:cacheSizeMemory diskCapacity:cacheSizeDisk diskPath:@"nsurlcache"];
    [NSURLCache setSharedURLCache:sharedCache];

	sharedAppDelegate = self;
	[[PocketAPI sharedAPI] setConsumerKey:@"12494-5c5d662193512e29902989da"];
	//register defaults
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults registerDefaults:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithBool:YES], showStoryThumbnailKey,
      [NSNumber numberWithBool:YES], shakeForStoryKey,
      [NSNumber numberWithBool:YES], playSoundOnShakeKey,
      [NSNumber numberWithBool:YES], useCustomRedditListKey,
      [NSNumber numberWithBool:YES], showLoadingAlienKey,
      [NSNumber numberWithBool:NO], usePocket,
      [NSNumber numberWithBool:NO], showTabBarKey,
      [NSArray array], visitedStoriesKey,
      [NSArray array], redditSortOrderKey,
      redditSoundLightsaber, shakingSoundKey,
      [NSNumber numberWithBool:YES], allowLandscapeOrientationKey,
      @"/", initialRedditURLKey,
      @"Front Page", initialRedditTitleKey,
      nil
      ]
     ];
    self.window.frame = [[UIScreen mainScreen] bounds];
	
    self.navController = [[UINavigationController alloc] initWithRootViewController:[[RootViewController alloc] init]];
	self.navController.delegate = (id <UINavigationControllerDelegate>)self;
	navController.toolbarHidden = NO;
    self.window.rootViewController = navController;
    //	[window addSubview:navController.view];
	
	NSString *initialRedditURL = [[NSUserDefaults standardUserDefaults] stringForKey:initialRedditURLKey];
	NSString *initialRedditTitle = [[NSUserDefaults standardUserDefaults] stringForKey:initialRedditTitleKey];
	
	SubredditViewController *controller = [[SubredditViewController alloc] initWithField:
                                            [NSDictionary dictionaryWithObjectsAndKeys:initialRedditTitle, @"text", initialRedditURL, @"url", nil]];
	[navController pushViewController:controller animated:NO];
    
	
	//login
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEndLogin:) name:RedditDidFinishLoggingInNotification object:nil];
    if (![[LoginController sharedLoginController] isLoggedIn]) {
        //NSLog(@"Not Logged in, will try to login");
        [[LoginController sharedLoginController] loginWithUsername:[defaults stringForKey:redditUsernameKey]
                                                          password:[defaults stringForKey:redditPasswordKey]];
    } else {
        //NSLog(@"Already logged in");
        [[NSNotificationCenter defaultCenter] postNotificationName:RedditDidFinishLoggingInNotification object:nil];
    }
	
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceDidShake:)
                                                 name:DeviceDidShakeNotification
                                               object:nil];
	
    randomData = [[SubredditData alloc] initWithSubreddit:@"/randomrising/"];
    [self performSelectorInBackground:@selector(loadRandomData) withObject:nil];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }
    
    [[UINavigationBar appearance] setBarTintColor:[iRedditAppDelegate redditNavigationBarTintColor]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    [[UIToolbar appearance] setBarTintColor:[iRedditAppDelegate redditNavigationBarTintColor]];
    [[UIToolbar appearance] setTintColor:[UIColor whiteColor]];
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([[PocketAPI sharedAPI] handleOpenURL:url]) {
        return YES;
    }
    return YES;
}

- (void)deviceDidShake:(NSNotification *)notif
{
    if(shouldDetectDeviceShake){
		if ([[NSUserDefaults standardUserDefaults] boolForKey:shakeForStoryKey])
			[self showRandomStory];
    }
}
-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url  {
    UIAlertView *alertView;
    NSString *text = [[url host] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    alertView = [[UIAlertView alloc] initWithTitle:@"Text" message:text delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    return YES;
}
- (void)didEndLogin:(NSNotification *)notif
{
    if([[LoginController sharedLoginController] isLoggedIn] && !messageDataSource && !messageTimer)
    {
        messageDataSource = [[MessageDataSource alloc] init];
        [messageDataSource loadMore:NO];
        
        messageTimer = [NSTimer scheduledTimerWithTimeInterval:60.0
                                                         target:self
                                                       selector:@selector(reloadMessages)
                                                       userInfo:nil
                                                        repeats:YES];
    }
    else {
        [messageDataSource cancel];
        messageDataSource = nil;
        
        [messageTimer invalidate];
        messageTimer = nil;
    }
}

- (void)reloadMessages
{
    [messageDataSource loadMore:NO];
}

- (void)loadRandomData
{
	[randomData loadMore:NO];
   // [self performSelector:@selector(loadRandomData) withObject:nil afterDelay:60.0];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Save data if appropriate
	[[NSUserDefaults standardUserDefaults] setObject:[visitedArray subarrayWithRange:NSMakeRange(0, MIN(500, [visitedArray count]))]
											  forKey:visitedStoriesKey];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	//[[Beacon shared] endBeacon];
    //Remove temp files
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSString *saveDirectory = NSTemporaryDirectory();
    NSArray *cacheFiles = [fileManager contentsOfDirectoryAtPath:saveDirectory error:&error];
    for (NSString *file in cacheFiles) {
        error = nil;
        [fileManager removeItemAtPath:[saveDirectory stringByAppendingPathComponent:file] error:&error];
        /* handle error */
    }
}



- (void)dealloc
{
	
    [messageTimer invalidate];
    
}

- (void)showRandomStory
{
	if (!randomData || ![randomData isLoaded])
		return;
    
	if (!randomController)
	{
		randomController= [[StoryViewController alloc] init];
		//[[Beacon shared] startSubBeaconWithName:@"serendipityTime" timeSession:YES];
	}
	
    NSInteger count = [randomData totalStories];
	NSInteger randomIndex = count > 0 ? arc4random() % count : 0;
	
	Story *story = nil;
	
	int i=0;
	while (!story && i++ < count)
	{
		story = [randomData storyWithIndex:(randomIndex++)%count];
        
		if ([story visited] && i < count - 1)
			story = nil;
	}
	
	if (!story)
	{
		[randomData loadMore:YES];
		return;
	}
    
	if (navController.topViewController != randomController)
	{
		if (![navController.viewControllers containsObject:randomController])
			[navController pushViewController:randomController animated:YES];
		else if ([navController.topViewController isKindOfClass:[StoryViewController class]])
			[(StoryViewController *)(navController.topViewController) setStory:story];
	}
	
	[randomController setStory:story];
}

- (void)dismissRandomViewController
{
	
	messageDataSource = nil;
	
	randomController = nil;
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	if (![navigationController.viewControllers containsObject:randomController])
	{
		randomController = nil;
	}
}
-(NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    NSUInteger orientations = UIInterfaceOrientationMaskAllButUpsideDown;
    
    if(self.window.rootViewController){
        UIViewController *presentedViewController = [[(UINavigationController *)self.window.rootViewController viewControllers] lastObject];
        orientations = [presentedViewController supportedInterfaceOrientations];
    }
    
    return orientations;
}

@end

