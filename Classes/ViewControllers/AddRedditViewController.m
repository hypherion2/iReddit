//
//  AddRedditViewController.m
//  iReddit
//
//  Created by Ross Boucher on 7/2/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import "AddRedditViewController.h"
#import "iRedditAppDelegate.h"
#import "Constants.h"
#import "LoginController.h"

@interface AddRedditViewController (){
	UINavigationBar *navigationBar;
	BOOL shouldViewOnly;
}

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;
- (void)loadReddit:(NSString *)redditURL;
- (void)requestFailed;
@property (strong) NSArray *dataSource;
@property (strong) NSArray *section;
@property (nonatomic, strong) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@end

@implementation AddRedditViewController

@synthesize navigationBar;

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)save:(id)sender
{
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	UITableViewCell *cell = (UITableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
	UITextField *textField = (UITextField *)cell.accessoryView;
	if (textField)
	{
		[self loadReddit:textField.text];
	}
}
- (id)initForViewing
{
	if (self = [super init])
	{
		shouldViewOnly = YES;
	}
	
	return self;
}

- (void)loadView {
    
    [super loadView];
    
	self.navigationBar = [[UINavigationBar alloc] init];
	
	[self.navigationBar sizeToFit];
	
	UINavigationItem *item = nil;
	if (shouldViewOnly)
	{
		item = [[UINavigationItem alloc] initWithTitle:@"view reddit"];
		item.prompt = @"View any reddit by entering a URL";
	} else {
		item = [[UINavigationItem alloc] initWithTitle:@"add reddit"];
		item.prompt = @"Subscribe to a new reddit by entering a URL";
	}
	
	item.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                            target:self
                                                                            action:@selector(cancel:)];
	item.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                             target:self
                                                                             action:@selector(save:)];
    
	[self.navigationBar pushNavigationItem:item animated:NO];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 75.0, self.view.bounds.size.width, self.view.bounds.size.height - 75.0)
                                                   style:UITableViewStyleGrouped];
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.tableView setBackgroundView:nil];
	self.tableView.backgroundColor = [UIColor colorWithRed:229.0/255.0 green:238.0/255.0 blue:1 alpha:1];
	
	self.tableView.allowsSelectionDuringEditing = NO;
	self.tableView.editing = NO;
	self.tableView.scrollEnabled = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate =self;
    [self.navigationBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
	[self.view addSubview:self.navigationBar];
    [self.view addSubview:self.tableView];
    [self createModel];
    [[self tableView] reloadData];
    
    self.navigationController.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationController.extendedLayoutIncludesOpaqueBars = NO;
}

-(void)createModel {
    self.dataSource = [NSArray arrayWithObject:[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"reddit.com/r/",@"title",@"pics",@"placeholder",@"",@"key",[NSNumber numberWithBool:NO],@"secure", @"text", @"type", nil]]];
    self.section = [NSArray arrayWithObject:@"Enter a reddit URL (e.g. /r/pics)"];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_section count];
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [_section objectAtIndex:section];
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_dataSource count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id cell = [tableView dequeueReusableCellWithIdentifier:@"settings"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"settings"];
    }
    
    [cell setAccessoryView:nil];
    NSDictionary *cellData = [[_dataSource objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    [[cell textLabel] setText:[cellData objectForKey:@"title"]];
    if ([[cellData objectForKey:@"type"] isEqualToString:@"switch"]) {
        UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
        [switchview setOn:[cellData[@"value"] boolValue]];
        
        [cell setAccessoryView:switchview];
        [switchview addTarget:self action:@selector(valueChange:) forControlEvents:UIControlEventValueChanged];
        
    } else {
        if ([cellData[@"type"] isEqualToString:@"check"]) {
            if ([cellData[@"value"] boolValue]) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            }
        } else {
            if ([cellData[@"type"] isEqualToString:@"text"]) {
                CGFloat width = 162;
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                    width = 490;
                }
                UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, width, 24)];
                [textField setDelegate:self];
                [textField setText:cellData[@"value"]];
                [textField setBackgroundColor:[UIColor clearColor]];
                [textField setSpellCheckingType:UITextSpellCheckingTypeNo];
                [textField setAutocorrectionType:UITextAutocorrectionTypeNo];
                [textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                [textField setPlaceholder:cellData[@"placeholder"]];
                if ([cellData[@"secure"] boolValue]) {
                    [textField setSecureTextEntry:YES];
                }
                [textField becomeFirstResponder];
                [cell setAccessoryView:textField];
            }
        }
    }
    return cell;
}

- (BOOL)textFieldShouldReturn:(UITextField *)aField {
    [self loadReddit:aField.text];
    return YES;
}

- (void)loadReddit:(NSString *)redditURL
{

    NSString *url = [NSString stringWithFormat:@"%@/r/%@/.json", RedditBaseURLString, redditURL];
    GIDAAlertView *gav = [[GIDAAlertView alloc] initWithProgressBarWith:@"Loading reddit" andURL:[NSURL URLWithString:url]];
    [gav setProgressBarColor:[UIColor blueColor]];
    [gav setDelegate:self];
    [gav setColor:[iRedditAppDelegate redditNavigationBarTintColor]];
    [gav progresBarStartDownload];
}
-(BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}
-(void)alertFinished:(GIDAAlertView *)alertView
{
    NSDictionary *response = [alertView getDownloadedData];
    if (!response) {
        [self requestFailed];
        return;
    }
    NSError *error = nil;
    // parse the JSON data that we retrieved from the server
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:response[@"data"] options:NSJSONReadingMutableContainers error:&error];
    
    if (error != nil || ![json isKindOfClass:[NSDictionary class]] || ![json objectForKey:@"data"])
    {
        [self requestFailed];
    //    [self updateView];
        return;
    }
    
    NSDictionary *data = [json objectForKey:@"data"];
    NSArray *children = [data objectForKey:@"children"];
    
    if (![children count])
    {
        [self requestFailed];
   //     [self updateView];
        return;
    }
    
    NSDictionary *firstStory = [[children objectAtIndex:0] objectForKey:@"data"];
    NSMutableDictionary *completeRedditInfo = [NSMutableDictionary dictionaryWithDictionary:firstStory];
    
    NSString *url = [[response[@"url"] absoluteString] substringFromIndex:NSMaxRange([[response[@"url"] absoluteString] rangeOfString:RedditBaseURLString])];
    url = [url stringByReplacingOccurrencesOfString:@".json" withString:@""];
    
    [completeRedditInfo setObject:url forKey:@"subreddit_url"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RedditWasAddedNotification object:self userInfo:completeRedditInfo];
    
 //   [self updateView];
    
    [self performSelector:@selector(cancel:) withObject:self afterDelay:1.0];
}

- (BOOL)shouldViewOnly
{
    return shouldViewOnly;
}

- (void)requestFailed
{
    GIDAAlertView *gav = [[GIDAAlertView alloc] initWithTitle:@"Whoops!" message:@"This is not the reddit you were looking for. We couldn't find anything at that URL. Try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [gav setColor:[iRedditAppDelegate redditNavigationBarTintColor]];
    [gav show];
}

- (void)viewDidUnload
{
    self.navigationBar = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // this interface is portrait only, but allow it to operate in *either* portrait
    return [[NSUserDefaults standardUserDefaults] boolForKey:allowLandscapeOrientationKey] ? YES : (interfaceOrientation == UIInterfaceOrientationPortrait) ? YES : NO ;
}


-(BOOL)shouldAutorotate {
    return YES;
}
-(NSUInteger)supportedInterfaceOrientations {
    return [[NSUserDefaults standardUserDefaults] boolForKey:allowLandscapeOrientationKey] ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
}

@end
