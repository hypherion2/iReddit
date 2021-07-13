//
//  iRedditAppDelegate.h
//  iReddit
//
//  Created by Ross Boucher on 6/18/09.
//  Copyright 280 North 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SubredditData.h"
#import "MessageDataSource.h"
#import "RootViewController.h"
#import "SubredditViewController.h"
#import "Story.h"
#import "Constants.h"
#import "LoginController.h"
#import "StoryViewController.h"

@interface iRedditAppDelegate : NSObject <UIApplicationDelegate> 
{
    UIWindow *window;
	UINavigationController *navController;
	
	SubredditData *randomData;
    StoryViewController *randomController;
	
	MessageDataSource *messageDataSource;
    NSTimer *messageTimer;
}

+ (UIColor *)redditNavigationBarTintColor;
+ (iRedditAppDelegate *)sharedAppDelegate;

- (void)showRandomStory;

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) UINavigationController *navController;
@property (nonatomic, strong) MessageDataSource *messageDataSource;

@end
