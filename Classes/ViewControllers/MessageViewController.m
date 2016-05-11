//
//  MessageViewController.m
//  Reddit2
//
//  Created by Ross Boucher on 6/16/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import "MessageViewController.h"
#import "iRedditAppDelegate.h"
#import "RedditMessage.h"
#import "Constants.h"
#import "LoginController.h"
#import "RedditWebView.h"

@interface MessageViewController ()
@property (nonatomic, strong) MessageDataSource *dataSource;
@property (nonatomic, strong) UINavigationBar *navigationBar;
@property (nonatomic, strong) UITableView *tableView;
@property (strong, nonatomic) CreateMessage *controller;
@end

@implementation MessageViewController

- (void)loadView
{
	[super loadView];
	
	self.title = @"Inbox";
	
	//self.variableHeightRows = YES;

	self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
	
	[self.view addSubview:self.tableView];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(compose:)];
    [self messageCountChanged:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageCountChanged:) name:MessageCountDidChangeNotification object:nil];
}

- (void)messageCountChanged:(NSNotification *)notif
{
    [self createModel];
    [[self tableView] reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

-(void)createModel 
{
	self.dataSource = [iRedditAppDelegate sharedAppDelegate].messageDataSource;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [MessageCell tableView:tableView rowHeightForObject:(RedditMessage *)[_dataSource messageAtIndex:indexPath.row]];
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_dataSource count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id cell = [tableView dequeueReusableCellWithIdentifier:@"message"];
    if (!cell) {
        cell = [[MessageCell alloc] init];
    }
    [(MessageCell *)cell setMessage:[_dataSource messageAtIndex:indexPath.row]];
    return cell;
}
- (void)compose:(id)sender
{
    _controller = [[CreateMessage alloc] init];
    _controller.subject = @"";
    _controller.to = @"";
    _controller.delegate = self;
    UINavigationController* navController = [[UINavigationController alloc] init];
    _controller.title = @"New Message";
    [navController pushViewController:_controller animated:NO];
    
    [self presentViewController:navController animated:YES completion:nil];
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    RedditMessage *message = [_dataSource messageAtIndex:indexPath.row];
    _controller = [[CreateMessage alloc] init];
    _controller.subject = [NSString stringWithFormat:@"RE: %@", message.subject];
    _controller.to = message.author;
    _controller.delegate = self;
    UINavigationController* navController = [[UINavigationController alloc] init];
    [navController pushViewController:_controller animated:NO];
    _controller.title = _controller.subject;
    [self presentViewController:navController animated:YES completion:nil];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)composeController:(CreateMessage *)controller didSendFields:(NSArray*)fields {
	NSString *toField = [fields objectAtIndex:0];
	NSString *subjectField = [fields objectAtIndex:1];
	NSString *messageBody = [fields objectAtIndex:2];
    NSString *captchaID = [fields objectAtIndex:3];
    NSString *captchaText = [fields objectAtIndex:4];
	NSString *url = [NSString stringWithFormat:@"%@%@", RedditBaseURLString, RedditComposeMessageAPIString];
	
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setHTTPShouldHandleCookies:[[LoginController sharedLoginController] isLoggedIn] ? YES : NO];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"id=%@&uh=%@&to=%@&subject=%@&text=%@&iden=%@&captcha=%@",
                           @"%23compose-message",
                           [[LoginController sharedLoginController] modhash],
                           [[toField stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                           [[subjectField stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                           [[messageBody stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                           [[captchaID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                           [[captchaText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]
                           ] dataUsingEncoding:NSASCIIStringEncoding]];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (error) {
                                   [[[UIAlertView alloc] initWithTitle:@"Error Sending Message"
                                                               message:@"Could not send your message at this time. Please try again later."
                                                              delegate:nil
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil] show];
                               } else {
                                   NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                   
                                   if([responseBody rangeOfString:@"error"].location != NSNotFound)
                                   {
                                       [[[UIAlertView alloc] initWithTitle:@"Error Sending Message"
                                                                   message:@"Could not send your message at this time. Please try again later."
                                                                  delegate:nil
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil] show];
                                       [_controller newCaptcha];
                                   } else {
                                       [_controller dismissViewControllerAnimated:YES completion:nil];
                                   }
                               }
                           }];
}


// for the message composer!
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(BOOL)shouldAutorotate {
    return YES;
}
-(NSUInteger)supportedInterfaceOrientations {
    return [[NSUserDefaults standardUserDefaults] boolForKey:allowLandscapeOrientationKey] ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // this interface is portrait only, but allow it to operate in *either* portrait
    return [[NSUserDefaults standardUserDefaults] boolForKey:allowLandscapeOrientationKey] ? YES : (interfaceOrientation == UIInterfaceOrientationPortrait) ? YES : NO ;
}
@end
