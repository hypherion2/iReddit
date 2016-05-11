//
//  LoginViewController.m
//  Reddit2
//
//  Created by Ross Boucher on 6/15/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import "LoginViewController.h"
#import "LoginController.h"
#import "iRedditAppDelegate.h"
#import "Constants.h"

@interface LoginViewController () 
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *dataSource;
@property (nonatomic, strong) NSArray *headers;
@property (nonatomic, strong) UINavigationBar *navigationBar;
@end

@implementation LoginViewController

@synthesize delegate, context;

+ (void)presentWithDelegate:(id <LoginViewControllerDelegate>)aDelegate context:(id)aContext {
	LoginViewController *controller = [[self alloc] init];
	
	controller.delegate = aDelegate;
	controller.context = aContext;
	
	[[NSNotificationCenter defaultCenter] addObserver:controller selector:@selector(loginDidStart:) name:RedditDidBeginLoggingInNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:controller selector:@selector(loginDidEnd:) name:RedditDidFinishLoggingInNotification object:nil];
	
	[[iRedditAppDelegate sharedAppDelegate].navController presentViewController:controller animated:YES completion:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (void)loadView {
	[super loadView];
	[self createModel];
	self.title = @"Login";
    
    self.navigationBar = [[UINavigationBar alloc] init];
	
	[self.navigationBar sizeToFit];
	
	UINavigationItem *item = nil;
    item = [[UINavigationItem alloc] initWithTitle:@"Login"];

	
	[self.navigationBar pushNavigationItem:item animated:NO];
    [self.view addSubview:_navigationBar];
	self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 44.0, self.view.bounds.size.width, self.view.bounds.size.height - 44.0)
                                                   style:UITableViewStyleGrouped];
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.tableView.backgroundColor = [UIColor colorWithRed:229.0/255.0 green:238.0/255.0 blue:1 alpha:1];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
	UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	cancelButton.frame = CGRectMake(10.0, 150.0, ([[UIScreen mainScreen] applicationFrame].size.width - 30.0) / 2.0, 40.0);
	[cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
	[cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
	
	[self.tableView addSubview:cancelButton];
	
	loginButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	loginButton.frame = CGRectMake(CGRectGetMaxX(cancelButton.frame) + 10.0, 150.0, ([[UIScreen mainScreen] applicationFrame].size.width -30.0) / 2.0, 40.0);
	[loginButton setTitle:@"Login" forState:UIControlStateNormal];
	[loginButton addTarget:self action:@selector(login:) forControlEvents:UIControlEventTouchUpInside];
	
	statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 145.0, CGRectGetWidth(self.view.frame) - 20.0, 24.0)];
	
	statusLabel.textAlignment = NSTextAlignmentCenter;
	statusLabel.opaque = NO;
	statusLabel.backgroundColor = [UIColor clearColor];
	statusLabel.textColor = [UIColor darkTextColor];
	statusLabel.shadowColor = [UIColor whiteColor];
	statusLabel.shadowOffset = CGSizeMake(0, 1);
	
	[self.tableView addSubview:statusLabel];
	
	[self.tableView addSubview:loginButton];
	
	[self.view addSubview:self.tableView];
}

- (void)cancel:(id)sender {
	[self dismiss:sender];
}

- (void)dismiss:(id)sender {
	if ([(id)self.delegate respondsToSelector:@selector(loginViewController:didFinishWithContext:)])
		[self.delegate loginViewController:self didFinishWithContext:self.context];

	[[iRedditAppDelegate sharedAppDelegate].navController dismissViewControllerAnimated:YES completion:nil];
}

-(void)createModel {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
    self.headers = [NSArray arrayWithObject:@"reddit Account Information"];
    self.dataSource = [NSArray arrayWithObject:[NSArray arrayWithObjects:
     [NSDictionary dictionaryWithObjectsAndKeys:@"Username",@"title",redditUsernameKey, @"key",@"text", @"type",[NSNumber numberWithBool:NO],@"secure",@"splashy", @"placeholder",[defaults stringForKey:redditUsernameKey],@"value",nil],
     [NSDictionary dictionaryWithObjectsAndKeys:@"Password",@"title",redditPasswordKey, @"key",@"text", @"type",[NSNumber numberWithBool:YES],@"secure",@"••••••", @"placeholder",[defaults stringForKey:redditPasswordKey],@"value",nil],
     nil]];
}
-(BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.headers objectAtIndex:section];
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.headers count];
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.dataSource objectAtIndex:section] count];
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
                CGFloat width = 180;
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                    width = 544;
                }
                UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, width, 24)];
                [textField setDelegate:self];
                [textField setText:cellData[@"value"]];
                [textField setSpellCheckingType:UITextSpellCheckingTypeNo];
                [textField setAutocorrectionType:UITextAutocorrectionTypeNo];
                [textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                [textField setPlaceholder:cellData[@"placeholder"]];
                if ([cellData[@"secure"] boolValue]) {
                    [textField setSecureTextEntry:YES];
                }
                [cell setAccessoryView:textField];
            }
        }
    }
    return cell;
}
- (void)login:(id)sender {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    NSString *usernameField = [(UITextField *)[[self.tableView cellForRowAtIndexPath:indexPath] accessoryView] text];
    indexPath = [NSIndexPath indexPathForItem:1 inSection:0];
    NSString *passwordField = [(UITextField *)[[self.tableView cellForRowAtIndexPath:indexPath] accessoryView] text];
	[[LoginController sharedLoginController] loginWithUsername:usernameField password:passwordField];
}

- (void)loginDidStart:(NSNotification *)note {
	[loginButton setEnabled:NO];
	statusLabel.text = @"Logging in...";
}

- (void)loginDidEnd:(NSNotification *)note {
	[loginButton setEnabled:YES];

	if ([[LoginController sharedLoginController] isLoggedIn])
	{
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
        NSString *usernameField = [(UITextField *)[[self.tableView cellForRowAtIndexPath:indexPath] accessoryView] text];
        indexPath = [NSIndexPath indexPathForItem:1 inSection:0];
        NSString *passwordField = [(UITextField *)[[self.tableView cellForRowAtIndexPath:indexPath] accessoryView] text];
		statusLabel.text = [NSString stringWithFormat:@"Logged in as %@", usernameField];
		[self performSelector:@selector(dismiss:) withObject:self afterDelay:1.5];

		[[NSUserDefaults standardUserDefaults] setObject:usernameField forKey:redditUsernameKey];
		[[NSUserDefaults standardUserDefaults] setObject:passwordField forKey:redditPasswordKey];
	}
	else
	{
		statusLabel.text = @"Unable to Login";
	}
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
