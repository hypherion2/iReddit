//
//  RootViewController.m
//  Reddit2
//
//  Created by Ross Boucher on 6/13/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import "RootViewController.h"

@interface RootViewController () {
	NSArray *customSubreddits;
}
@property (strong) NSMutableArray *dataSource;
@property (strong) NSArray *sections;

@end
@implementation RootViewController

- (id)init
{
	if (self = [super initWithStyle:UITableViewStyleGrouped])
	{
		self.title = @"Home";
		self.hidesBottomBarWhenPushed = YES;
		
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		[center addObserver:self selector:@selector(messageCountChanged:) name:MessageCountDidChangeNotification object:nil];
		[center addObserver:self selector:@selector(didEndLogin:) name:RedditDidFinishLoggingInNotification object:nil];
		[center addObserver:self selector:@selector(didAddReddit:) name:RedditWasAddedNotification object:nil];
        
        CGFloat iosVer = [[[UIDevice currentDevice] systemVersion] floatValue];
        if (iosVer >= 7.0) {
            CGRect frame = self.tableView.frame;
            frame.size.height -= 64;
            frame.origin.y += 64;
            self.tableView.frame = frame;
        }
	}
    
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView
{
	[super loadView];
	
    UIImage *mainTitleImage;
    CGFloat iosVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iosVer >= 7.0) {
        mainTitleImage = [UIImage imageNamed:@"mainTitle-iOS7"];
    } else {
        mainTitleImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"mainTitle" ofType:@"png"]];
    }
	self.navigationItem.titleView = [[UIImageView alloc] initWithImage:mainTitleImage];
	
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit:)];
    
   

    
}
- (void)viewWillAppear:(BOOL)animated
{
    
	[super viewWillAppear:animated];
    [self.tableView setBackgroundView:nil];
    self.tableView.backgroundColor = [UIColor colorWithRed:229.0/255.0 green:238.0/255.0 blue:1 alpha:1];
	
	self.tableView.allowsSelectionDuringEditing = NO;
	self.tableView.editing = NO;
    
	if ([[LoginController sharedLoginController] isLoggedIn] && [[NSUserDefaults standardUserDefaults] boolForKey:useCustomRedditListKey])
		self.navigationItem.leftBarButtonItem =  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                                target:self
                                                                                                action:@selector(add:)];
	else
		self.navigationItem.leftBarButtonItem = nil;
    
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}

- (void)add:(id)sender
{
	[self presentViewController:[[AddRedditViewController alloc] init] animated:YES completion:nil];
}

- (void)edit:(id)sender
{
	shouldDetectDeviceShake = NO;
    
	[self.tableView setEditing:YES animated:YES];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(stopEditing:)];
}

- (void)stopEditing:(id)sender
{
	self.tableView.editing = NO;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit:)];
    
    NSMutableArray *order = [NSMutableArray array];
    
    NSArray *ds = self.dataSource;
    NSArray *items = [ds objectAtIndex:1];
    
    for (NSDictionary *item in items)
    {
        [order addObject:item[@"url"]];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:order forKey:redditSortOrderKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    shouldDetectDeviceShake = YES;
}

- (void)messageCountChanged:(NSNotification *)note {
	unsigned int count = [[iRedditAppDelegate sharedAppDelegate].messageDataSource unreadMessageCount];
    
	if (count > 0)
		self.title = [NSString stringWithFormat:@"Home (%u)", count];
	else
		self.title = @"Home";
    
    [self createModel];
    [self.tableView reloadData];
}

- (void)didEndLogin:(NSNotification *)note {
	customSubreddits = nil;
	if ([[LoginController sharedLoginController] isLoggedIn]  && [[NSUserDefaults standardUserDefaults] boolForKey:useCustomRedditListKey])
		self.navigationItem.leftBarButtonItem =  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add:)];
	else
		self.navigationItem.leftBarButtonItem = nil;
    
    [self.tableView setContentOffset:CGPointZero animated:NO];
    
	if (![[LoginController sharedLoginController] isLoggedIn] || ![[NSUserDefaults standardUserDefaults] boolForKey:useCustomRedditListKey])
    {
        if([[LoginController sharedLoginController] isLoggedIn])
        {
            self.title = @"Home";
        }
        [self createModel];
        [self.tableView reloadData];
		return;
    }
    
    NSString *url = [NSString stringWithFormat:@"%@%@?limit=500", RedditBaseURLString, CustomRedditsAPIString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setHTTPShouldHandleCookies:[[LoginController sharedLoginController] isLoggedIn] ? YES : NO];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (error) {
                                   [self createModel];
                                   [self.tableView reloadData];
                               } else {
                                   id json = [NSJSONSerialization JSONObjectWithData:data
                                                                             options:NSJSONReadingMutableContainers
                                                                               error:nil];
                                   if (![json isKindOfClass:[NSDictionary class]] || ![json objectForKey:@"data"])
                                   {
                                       [self createModel];
                                       [self.tableView reloadData];
                                       return;
                                   }
                                   
                                   NSDictionary *data = [json objectForKey:@"data"];
                                   NSMutableArray *loadedReddits = [NSMutableArray array];
                                   NSArray *children = [data objectForKey:@"children"];
                                   
                                   for (int i=0, count=[children count]; i<count; i++)
                                   {
                                       NSDictionary *thisReddit = [[children objectAtIndex:i] objectForKey:@"data"];
                                       [loadedReddits addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                 [thisReddit objectForKey:@"title"], @"text",
                                                                 [thisReddit objectForKey:@"url"], @"url",
                                                                 [thisReddit objectForKey:@"name"], @"tag",
                                                                 nil]];
                                   }
                                   
                                   customSubreddits = [loadedReddits copy];
                                   [self createModel];
                                   [self.tableView reloadData];
                               }
                           }];
}

- (void)didAddReddit:(NSNotification *)note
{
	if ([(AddRedditViewController *)[note object] shouldViewOnly])
	{
		NSDictionary *redditInfo = (NSDictionary *)[note userInfo];
		SubredditViewController *controller = [[SubredditViewController alloc] initWithField:
                                                [NSDictionary dictionaryWithObjectsAndKeys:[redditInfo objectForKey:@"subreddit"], @"text", [redditInfo objectForKey:@"subreddit_url"], @"url", nil]];
        
		[[self navigationController] pushViewController:controller animated:YES];
	}
	else {
		NSDictionary *redditInfo = (NSDictionary *)[note userInfo];
        
		if (!customSubreddits)
			return;
        
		for (int i=0, count = [customSubreddits count]; i<count; i++)
		{
			NSDictionary *item = [customSubreddits objectAtIndex:i];
			
			if ([item[@"URL"] isEqual:[redditInfo objectForKey:@"subreddit_url"]])
			{
				NSMutableArray *items = [customSubreddits mutableCopy];
				
				id item = [items objectAtIndex:i];
				
				[items removeObjectAtIndex:i];
				[items insertObject:item atIndex:0];
                
				
				customSubreddits = items;
                
				NSArray *sortOrder = [[NSUserDefaults standardUserDefaults] objectForKey:redditSortOrderKey];
				NSMutableArray *newSortOrder = [NSMutableArray arrayWithArray:sortOrder];
				
				int currentIndex = [sortOrder indexOfObject:[redditInfo objectForKey:@"subreddit_url"]];
				
				if (currentIndex != NSNotFound)
					[newSortOrder removeObjectAtIndex:currentIndex];
                
				[newSortOrder insertObject:[redditInfo objectForKey:@"subreddit_url"] atIndex:0];
				
				[[NSUserDefaults standardUserDefaults] setObject:newSortOrder forKey:redditSortOrderKey];
				[[NSUserDefaults standardUserDefaults] synchronize];
                
                [self createModel];
                [self.tableView reloadData];
                
				return;
			}
		}
        NSString *url = [NSString stringWithFormat:@"%@%@", RedditBaseURLString, RedditSubscribeAPIString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
        [request setHTTPShouldHandleCookies:[[LoginController sharedLoginController] isLoggedIn] ? YES : NO];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[[NSString stringWithFormat:@"uh=%@&sr=%@&action=sub",
                               [[LoginController sharedLoginController] modhash], [redditInfo objectForKey:@"subreddit_id"]]
                              dataUsingEncoding:NSASCIIStringEncoding]];
        NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:nil];
        [connection start];
        
		NSDictionary *newRedditField = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [redditInfo objectForKey:@"subreddit"],@"text",
                                        [redditInfo objectForKey:@"subreddit_url"],@"url",
                                        [redditInfo objectForKey:@"subreddit_id"],@"tag",
                                        nil];
        
		NSMutableArray *newRedditList = [customSubreddits mutableCopy];
		[newRedditList insertObject:newRedditField atIndex:0];
        
		customSubreddits = newRedditList;
        
		NSArray *sortOrder = [[NSUserDefaults standardUserDefaults] objectForKey:redditSortOrderKey];
		NSMutableArray *newSortOrder = [NSMutableArray arrayWithArray:sortOrder];
        
		[newSortOrder insertObject:[redditInfo objectForKey:@"subreddit_url"] atIndex:0];
        
		[[NSUserDefaults standardUserDefaults] setObject:newSortOrder forKey:redditSortOrderKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
        
        [self createModel];
        [self.tableView reloadData];
	}
}

- (NSArray *)subreddits
{
	BOOL useCustomReddits = [[NSUserDefaults standardUserDefaults] boolForKey:useCustomRedditListKey];
	
	NSMutableArray *result = [NSMutableArray array];
    
	if (customSubreddits && useCustomReddits) {
		[result addObjectsFromArray:customSubreddits];
	}
	else{
        if (useCustomReddits && ([[LoginController sharedLoginController] isLoggingIn])) {
            [result addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Loading custom reddits...", @"text", @"", @"url", nil]];
        } else {
            [result addObjectsFromArray:
             [NSArray arrayWithObjects:
              [NSDictionary dictionaryWithObjectsAndKeys:@"reddit",           @"text", @"/r/reddit.com/", @"url", nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"programming",      @"text", @"/r/programming/", @"url", nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"pics",             @"text", @"/r/pics/", @"url", nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"politics",         @"text", @"/r/politics/", @"url", nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"technology",       @"text", @"/r/technology/", @"url", nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"world news",       @"text", @"/r/worldnews/", @"url", nil],
              [NSDictionary dictionaryWithObjectsAndKeys:@"best of reddit",   @"text", @"/r/bestof/", @"url", nil],
              nil]
             ];
        }
    }
    [result sortUsingComparator:^NSComparisonResult(NSDictionary *id1, NSDictionary *id2){
        NSArray *sortedURLs = (NSArray *)[[NSUserDefaults standardUserDefaults] objectForKey:redditSortOrderKey];
        
        int index = [sortedURLs indexOfObject:id1[@"url"]];
        int otherIndex = [sortedURLs indexOfObject:id2[@"url"]];
        
        if (index > otherIndex)
            return NSOrderedDescending;
        else if (index < otherIndex)
            return NSOrderedAscending;
        else
            return NSOrderedSame;
    }];
	return result;
}

- (NSArray *)extraItems{
	return [NSArray arrayWithObjects:
            [NSDictionary dictionaryWithObjectsAndKeys:@"All reddits combined",   @"text", @"/r/all/", @"url", nil],
            [NSDictionary dictionaryWithObjectsAndKeys:@"Other reddit...",   @"text", @"/other/", @"url", nil],
			nil];
    
}

- (NSArray *)topItems{
    NSDictionary *homeField = [[NSDictionary alloc] initWithObjectsAndKeys:@"reddit Front Page",   @"text", @"/", @"url", nil];
	if ([[LoginController sharedLoginController] isLoggedIn]) {
		unsigned int count = [[iRedditAppDelegate sharedAppDelegate].messageDataSource unreadMessageCount];
		NSString *mailboxString = count > 0 ? [NSString stringWithFormat:@"Inbox (%u)", count] : @"Inbox";
        NSDictionary *saved = [[NSDictionary alloc] initWithObjectsAndKeys:@"Saved",   @"text", @"/saved/", @"url", nil];
        NSDictionary *mailboxField = [[NSDictionary alloc] initWithObjectsAndKeys:mailboxString,   @"text", @"/messages/", @"url", nil];
        
		return [[NSArray alloc] initWithObjects:homeField, mailboxField, saved, nil];
	}
	else
    {
        return [[NSArray alloc] initWithObjects:homeField,nil];
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.sections count];
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.sections objectAtIndex:section];
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[_dataSource objectAtIndex:section] count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = @"root";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    NSDictionary *item = [[self.dataSource objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    [[cell textLabel] setText:item[@"text"]];
    [cell setShowsReorderControl:YES];
    return  cell;
}

-(void)createModel{
	NSArray *topItems   = [self topItems];
	NSArray *subreddits = [self subreddits];
	NSArray *extra      = [self extraItems];
	NSArray *settingsItems = [[NSArray alloc] initWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Settings", @"text", @"/settings/", @"url", nil],nil];
    _sections = [[NSArray alloc] initWithObjects:@"",@"reddits",@"",@"", nil];
	_dataSource = [[NSMutableArray alloc] initWithObjects:topItems,subreddits,extra,settingsItems, nil];
    [self.tableView reloadData];
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *cell = [[_dataSource objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    id controller = nil;
    switch (indexPath.section) {
        case 0:
            if ([cell[@"url"] isEqualToString:@"/messages/"]) {
                controller = [[MessageViewController alloc] init];
            } else {
                controller = [[SubredditViewController alloc] initWithField:cell];
            }
            break;
        case 2:
            if ([cell[@"url"] isEqualToString:@"/other/"]) {
                [self presentViewController:[[AddRedditViewController alloc] initForViewing] animated:YES completion:nil];
            } else {
                controller = [[SubredditViewController alloc] initWithField:cell];
            }
            break;
        case 3:
            controller = [[SettingsViewController alloc] init];
            break;
        default:
            controller = [[SubredditViewController alloc] initWithField:cell];
            break;
    }
    [[self navigationController] pushViewController:controller animated:YES];
}
-(NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
        NSInteger row = 0;
        if (sourceIndexPath.section < proposedDestinationIndexPath.section) {
            row = [tableView numberOfRowsInSection:sourceIndexPath.section] - 1;
        }
        return [NSIndexPath indexPathForRow:row inSection:sourceIndexPath.section];
    }
    
    return proposedDestinationIndexPath;
}
-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && [[_dataSource objectAtIndex:1] count]>1) {
        return YES;
    }
    return NO;
}
-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (destinationIndexPath.section == 1 && sourceIndexPath.section == 1) {
        NSMutableArray *data = [_dataSource objectAtIndex:1];
        NSDictionary *temp = [data objectAtIndex:sourceIndexPath.row];
        [data removeObjectAtIndex:sourceIndexPath.row];
        [data insertObject:temp atIndex:destinationIndexPath.row];
        [_dataSource setObject:data atIndexedSubscript:1];
        customSubreddits = data;
    }
}
-(BOOL)shouldAutorotate {
    return YES;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // this interface is portrait only, but allow it to operate in *either* portrait
    return [[NSUserDefaults standardUserDefaults] boolForKey:allowLandscapeOrientationKey] ? YES : (interfaceOrientation == UIInterfaceOrientationPortrait) ? YES : NO ;
}
-(NSUInteger)supportedInterfaceOrientations {
    return [[NSUserDefaults standardUserDefaults] boolForKey:allowLandscapeOrientationKey] ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath
{
	if ([indexPath section] == 1 && [[LoginController sharedLoginController] isLoggedIn] && [[NSUserDefaults standardUserDefaults] boolForKey:useCustomRedditListKey])
		return UITableViewCellEditingStyleDelete;
	else
		return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [indexPath section] == 1 && [self tableView:tableView editingStyleForRowAtIndexPath:indexPath] != UITableViewCellEditingStyleNone;
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		NSMutableArray *items = [[_dataSource objectAtIndex:1] mutableCopy];
        
		NSDictionary *item = [items objectAtIndex:indexPath.row];
        
		[items removeObjectAtIndex:indexPath.row];
        
        [_dataSource setObject:items atIndexedSubscript:1];
        customSubreddits = items;
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
		if (item[@"tag"])
		{
            NSString *url = [NSString stringWithFormat:@"%@%@", RedditBaseURLString, RedditSubscribeAPIString];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
            [request setHTTPShouldHandleCookies:[[LoginController sharedLoginController] isLoggedIn] ? YES : NO];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPMethod:@"POST"];
            [request setHTTPBody:[[NSString stringWithFormat:@"uh=%@&sr=%@&action=unsub",
                                   [[LoginController sharedLoginController] modhash], item[@"tag"]]
                                  dataUsingEncoding:NSASCIIStringEncoding]];
            NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:nil];
            [connection start];
        }
        
	}
}

@end

