//
//  RootViewController.h
//  Reddit2
//
//  Created by Ross Boucher on 6/13/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iRedditAppDelegate.h"
#import "SubredditViewController.h"
#import "SettingsViewController.h"
#import "LoginController.h"
#import "Constants.h"
#import "MessageViewController.h"
#import "AddRedditViewController.h"

@interface RootViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>

- (NSArray *)topItems;
- (NSArray *)subreddits;
- (NSArray *)extraItems;

@end
