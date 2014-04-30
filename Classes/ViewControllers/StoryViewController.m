//
//  StoryViewController.m
//  Reddit2
//
//  Created by Ross Boucher on 6/12/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import "StoryViewController.h"

#import "GIDAAlertView.h"
#import "iRedditAppDelegate.h"
#import "Constants.h"
#import "LoginController.h"
#import "LoginViewController.h"
#import "SubredditData.h"
#import "SubredditViewController.h"
#import "RedditWebView.h"
#import "PocketAPI.h"

@interface StoryViewController () {
    BOOL		isForComments;
}
@property (strong,nonatomic) NSNumber *count;
@property (strong) UIWebView		  *webview;
@property (weak)   UIButton			  *scoreItem;
@property (weak)   UIButton			  *commentCountItem;
@property (weak)   UIBarButtonItem	  *toggleButtonItem;
@property (strong) UIBarButtonItem	  *moreButtonItem;
@property (strong) UISegmentedControl *segmentedControl;
@property (strong) AlienProgressView  *loadingView;
@property (strong) UIActionSheet      *currentSheet;

@end
@implementation StoryViewController

@synthesize story;

- (id)init {
    self = [super init];
    if (self){
        isForComments = NO;
        _count = [NSNumber numberWithInteger:0];
    }
    return self;
}
- (id)initForComments
{
	self = [super init];
    if (self) {
		isForComments = YES;
        _count = [NSNumber numberWithInteger:0];
	}
	
	return self;
}
-(void)viewDidLoad{
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem.action = @selector(backButtonDidPressed:);
    
    self.navigationController.navigationBar.TintColor = [iRedditAppDelegate redditNavigationBarTintColor];
	self.hidesBottomBarWhenPushed = NO;
    
	
	NSMutableArray *items = [NSMutableArray array];
	
	UIImage *voteUpImage = [UIImage imageNamed:@"voteUp.png"];
	UIImage *voteDownImage = [UIImage imageNamed:@"voteDown.png"];
	
	[items addObject:[[UIBarButtonItem alloc] initWithImage:voteUpImage style:UIBarButtonItemStylePlain target:self action:@selector(voteUp:)]];
	
	_scoreItem = [UIButton buttonWithType:UIButtonTypeCustom];
	_scoreItem.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
	_scoreItem.showsTouchWhenHighlighted = NO;
	_scoreItem.adjustsImageWhenHighlighted = NO;
    
    CGFloat iosVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iosVer >= 7.0) {
        [_scoreItem setTitleColor:[iRedditAppDelegate redditNavigationBarTintColor] forState:UIControlStateNormal];
//        [_scoreItem setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        [_scoreItem setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_scoreItem setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
	
	_scoreItem.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
	
	[items addObject:[[UIBarButtonItem alloc] initWithCustomView:_scoreItem]];
	[items addObject:[[UIBarButtonItem alloc] initWithImage:voteDownImage style:UIBarButtonItemStylePlain target:self action:@selector(voteDown:)]];
	
	[items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    
	if (!isForComments) {
        //NSLog(@"Not for comments");
		self.commentCountItem = [UIButton buttonWithType:UIButtonTypeCustom];
		_commentCountItem.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
		_commentCountItem.showsTouchWhenHighlighted = NO;
		_commentCountItem.adjustsImageWhenHighlighted = NO;
        if (iosVer >= 7.0) {
          //  [_commentCountItem setFrame:CGRectMake(0, 0, 30, 20)];
            [_commentCountItem setTitleColor:[iRedditAppDelegate redditNavigationBarTintColor] forState:UIControlStateNormal];
           // [_commentCountItem setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
        } else {
            [_commentCountItem setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_commentCountItem setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
        }
        [_commentCountItem setTitle:[_count stringValue] forState:UIControlStateNormal];
        [_commentCountItem sizeToFit];
		_commentCountItem.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
		
		[items addObject:[[UIBarButtonItem alloc] initWithCustomView:_commentCountItem]];
		
		[items addObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"commentBubble.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showComments:)]];
	} else {
		[items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(showStory:)]];
	}
	
	self.toggleButtonItem = [items lastObject];
    
	[items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
	if (!_moreButtonItem)
		_moreButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share:)];
	[items addObject:_moreButtonItem];
    
	[self setToolbarItems:items animated:NO];
    
	NSArray *viewControllers = [[self navigationController] viewControllers];
    
	if ([viewControllers count] > 2 && [[viewControllers objectAtIndex:[viewControllers count] - 2] isKindOfClass:[StoryViewController class]])
	{
		_commentCountItem.enabled = NO;
		_toggleButtonItem.enabled = NO;
	}
    
	NSArray *segmentItems = [NSArray arrayWithObjects:
							 [UIImage imageNamed:@"back.png"],
							 [UIImage imageNamed:@"refresh.png"],
							 [UIImage imageNamed:@"forward.png"],
							 nil
							 ];
	
	_segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentItems];
	
	[_segmentedControl setMomentary:YES];
	[_segmentedControl setSegmentedControlStyle:UISegmentedControlStyleBar];
    
	[_segmentedControl setWidth:30.0 forSegmentAtIndex:0];
	[_segmentedControl setWidth:30.0 forSegmentAtIndex:1];
	[_segmentedControl setWidth:30.0 forSegmentAtIndex:2];
	[_segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	
	_segmentedControl.tintColor = self.navigationController.navigationBar.tintColor;
    
	UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:_segmentedControl];
	self.navigationItem.rightBarButtonItem = segmentBarItem;
    
	CGRect navBarFrame = self.navigationController.navigationBar.frame;
	
	UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, navBarFrame.size.height > 40 ? 120 : 280, CGRectGetHeight(navBarFrame) - 4.0)];
	self.navigationItem.titleView = titleView;
	
	[titleView setBackgroundColor:[UIColor clearColor]];
	[titleView setOpaque:NO];
	
	[titleView setFont:[UIFont boldSystemFontOfSize:14.0]];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0) {
        [titleView setMinimumScaleFactor:12.0];
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        [titleView setTextColor:[UIColor whiteColor]];
        [titleView setShadowColor:[UIColor colorWithWhite:0.2 alpha:1.0]];
        [titleView setShadowOffset:CGSizeMake(0, -1)];
    }
	
	[titleView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
	[titleView setNumberOfLines:2];
	[titleView setLineBreakMode:NSLineBreakByTruncatingTail];
	[titleView setTextAlignment:NSTextAlignmentCenter];
	[titleView setAdjustsFontSizeToFitWidth:YES];
	
	self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] ];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	
	_webview = [[RedditWebView alloc] initWithFrame:self.view.bounds];
	_webview.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	_webview.scalesPageToFit = YES;
	
	[self.view addSubview:_webview];
	
	_webview.delegate = (id <UIWebViewDelegate>)self;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:showLoadingAlienKey])
	{
        if (iosVer >= 7.0) {
            _loadingView = [[AlienProgressView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame) - 111.0, CGRectGetHeight(self.view.frame) - 185.0, 101.0, 140.0)];
        } else {
            _loadingView = [[AlienProgressView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame) - 111.0, CGRectGetHeight(self.view.frame) - 150.0, 101.0, 140.0)];
        }
		_loadingView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin;
		[_loadingView setHidden:YES];
		
		[_loadingView setBackgroundColor:[UIColor clearColor]];
		[_loadingView setOpaque:NO];
		
		[self.view addSubview:_loadingView];
	}
    if (story) {
        if (isForComments) {
            [self loadStoryComments];
        } else {
            [self loadStory];
        }
    }
    
}

- (void)setStory:(Story *)aStory
{
	if (aStory == story)
		return;
    
	story = aStory;
	
	if (!story)
		return;
	
	story.visited = YES;
	
	[_webview stopLoading];
	
    //NSLog(@"CommentCountItem: %@",_commentCountItem);
	if (_commentCountItem) {
		[self loadStory];
      //  NSLog(@"Load Story");
	} else {
		[self loadStoryComments];
        //NSLog(@"Load Comments");
    }
    
	[_loadingView setHidden:NO];
	[_loadingView startAnimating];
    
	if (_commentCountItem)
		self.title = @"Story";
	else
		self.title = @"Comments";
    
	[self setNumberOfComments:story.totalComments];
	[self setScore:story.score];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)setStoryID:(NSString *)storyID commentID:(NSString *)commentID URL:(NSString *)aURL
{
	Story *aStory = [Story storyWithID:storyID];
    
	if (aStory)
	{
		aStory.commentID = commentID;
		[self loadStoryComments];
	}
	else
	{
		self.toggleButtonItem.enabled = NO;
		
		aStory = [[Story alloc] init];
		aStory.identifier = storyID;
		aStory.commentID = commentID;
		aStory.URL = aURL;
        
		self.story = aStory;
		[self loadStoryComments];
	}
}

- (void)loadStory
{
    //NSLog(@"LOAD: %@",story.URL);
	[_webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:story.URL]]];
}

- (void)loadStoryComments
{
	[_webview loadRequest:
	 [NSURLRequest requestWithURL:
	  [NSURL URLWithString:
	   [NSString stringWithFormat:@"%@/comments/%@/%@", RedditBaseURLString, story.identifier, story.commentID]
	   ]
	  ]
	 ];
    //NSLog(@"%@",[NSString stringWithFormat:@"%@/comments/%@/%@", RedditBaseURLString, story.identifier, story.commentID]);
}

- (void)setScore:(int)score
{
    CGFloat iosVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    
	[_scoreItem setTitle:[NSString stringWithFormat:@"%i", score] forState:UIControlStateNormal];
	[_scoreItem sizeToFit];
	
	if (story.likes)
		[_scoreItem setTitleColor:[UIColor colorWithRed:255.0/255.0 green:139.0/255.0 blue:96.0/255.0 alpha:1.0] forState:UIControlStateNormal];
	else if (story.dislikes)
		[_scoreItem setTitleColor:[UIColor colorWithRed:148.0/255.0 green:148.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
	else {
        if (iosVer >= 7.0) {
            [_scoreItem setTitleColor:[iRedditAppDelegate redditNavigationBarTintColor] forState:UIControlStateNormal];
        } else {
            [_scoreItem setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
    }
}

- (void)setNumberOfComments:(NSUInteger)commentCount {
    _count = [NSNumber numberWithInteger:commentCount];
}

- (void)voteUp:(id)sender
{
	if (![[LoginController sharedLoginController] isLoggedIn] && sender != self)
	{
		[LoginViewController presentWithDelegate:(id <LoginViewControllerDelegate>)self context:@"voteUp"];
		return;
	}
    
	NSString *url = [NSString stringWithFormat:@"%@%@", RedditBaseURLString, RedditVoteAPIString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setHTTPShouldHandleCookies:[[LoginController sharedLoginController] isLoggedIn] ? YES : NO];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"dir=%d&uh=%@&id=%@&_=", story.likes ? 0 : 1,
                           [[LoginController sharedLoginController] modhash], story.name]
                          dataUsingEncoding:NSASCIIStringEncoding]];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:nil];
    [connection start];
	
	story.likes = !story.likes;
	story.dislikes = NO;
	
	[self setScore:story.score];
	
	//[[Beacon shared] startSubBeaconWithName:@"votedUp" timeSession:NO];
}

- (void)voteDown:(id)sender
{
	if (![[LoginController sharedLoginController] isLoggedIn] && sender != self)
	{
		[LoginViewController presentWithDelegate:(id <LoginViewControllerDelegate>)self context:@"voteDown"];
		return;
	}
    
	NSString *url = [NSString stringWithFormat:@"%@%@", RedditBaseURLString, RedditVoteAPIString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setHTTPShouldHandleCookies:[[LoginController sharedLoginController] isLoggedIn] ? YES : NO];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"dir=%d&uh=%@&id=%@&_=", story.dislikes ? 0 : -1,
                           [[LoginController sharedLoginController] modhash], story.name]
                          dataUsingEncoding:NSASCIIStringEncoding]];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:nil];
    [connection start];
    
    
	story.likes = NO;
	story.dislikes = !story.dislikes;
	
	[self setScore:story.score];
	
	//[[Beacon shared] startSubBeaconWithName:@"votedDown" timeSession:NO];
}

- (IBAction)showComments:(id)sender
{
	NSArray *viewControllers = [[self navigationController] viewControllers];
	
	if (story.isSelfReddit || ([viewControllers count] > 2 && [[viewControllers objectAtIndex:[viewControllers count] - 2] isKindOfClass:[StoryViewController class]]))
		return;
    
	StoryViewController *commentsController = [[StoryViewController alloc] initForComments];
	[[self navigationController] pushViewController:commentsController animated:YES];
    
	[commentsController setStory:story];
}

- (IBAction)showStory:(id)sender
{
	NSArray *viewControllers = [[self navigationController] viewControllers];
    
	if (story.isSelfReddit || ([viewControllers count] > 2 && [[viewControllers objectAtIndex:[viewControllers count] - 2] isKindOfClass:[StoryViewController class]]))
		return;
	
	StoryViewController *storyController = [[StoryViewController alloc] init];
	[[self navigationController] pushViewController:storyController animated:YES];
	
	[storyController setStory:story];
}


- (IBAction)share:(id)sender {
	if (_currentSheet) {
		[_currentSheet dismissWithClickedButtonIndex:_currentSheet.cancelButtonIndex animated:YES];
		_currentSheet = nil;
	} else {
        NSMutableArray *otherButtonTitles;
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"usePocket"] boolValue]) {
            if (![[PocketAPI sharedAPI] isLoggedIn]) {
                [[PocketAPI sharedAPI] loginWithHandler: ^(PocketAPI *API, NSError *error){
                    if (error != nil)
                    {
                        // There was an error when authorizing the user.
                        // The most common error is that the user denied access to your application.
                        // The error object will contain a human readable error message that you
                        // should display to the user. Ex: Show an UIAlertView with the message
                        // from error.localizedDescription
                        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:usePocket];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        NSLog(@"%@",error.localizedDescription);
                        GIDAAlertView *gav = [[GIDAAlertView alloc] initWithXMarkWith:@"Could not log in to Pocket"];
                        [gav setColor:[iRedditAppDelegate redditNavigationBarTintColor]];
                        [gav presentAlertFor:1.08];
                        
                    }
                    else
                    {
                        // The user logged in successfully, your app can now make requests.
                        // [API username] will return the logged-in user’s username
                        // and API.loggedIn will == YES
                        
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:usePocket];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        GIDAAlertView *gav = [[GIDAAlertView alloc] initWithCheckMarkAndMessage:@"Logged in to Pocket"];
                        [gav setColor:[iRedditAppDelegate redditNavigationBarTintColor]];
                        [gav presentAlertFor:1.08];
                    }
                }];
            }
            otherButtonTitles = [NSMutableArray arrayWithObjects:@"E-mail Link", @"Open Link in browser", @"Hide on reddit", @"Save on reddit", @"Save on Pocket", nil];
		} else {
            otherButtonTitles = [NSMutableArray arrayWithObjects:@"E-mail Link", @"Open Link in browser", @"Hide on reddit", @"Save on reddit", nil];
            
        }
       // MFMessageComposeViewController *mfmcvc = [[MFMessageComposeViewController alloc] init];
        if ([MFMessageComposeViewController canSendText]) {
            [otherButtonTitles addObject:@"Send SMS"];
        }
        _currentSheet = [[UIActionSheet alloc]
                         initWithTitle:@""
                         delegate:(id <UIActionSheetDelegate>)self
                         cancelButtonTitle:nil
                         destructiveButtonTitle:nil
                         otherButtonTitles:nil];
        for( NSString *title in otherButtonTitles)  {
            [_currentSheet addButtonWithTitle:title];
        }
        [_currentSheet addButtonWithTitle:@"Cancel"];
        [_currentSheet setCancelButtonIndex:[otherButtonTitles count]];
      //  [_currentSheet addButtonWithTitle:title:cancelString];
		_currentSheet.actionSheetStyle = UIActionSheetStyleDefault;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
			[_currentSheet showInView:self.navigationController.view];
		} else {
			[_currentSheet showFromBarButtonItem:_moreButtonItem animated:YES];
		}
	}
}

- (void)actionSheetCancel:(id)sender
{
	_currentSheet = nil;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	_currentSheet = nil;
	NSString *url = story.URL;
	if (isForComments && story.commentsURL)
		url = story.commentsURL;
    NSString *nurl = self.webview.request.URL.absoluteString;
    if (![nurl isEqualToString:story.URL] && ![nurl isEqualToString:story.commentsURL]) {
        url = nurl;
    }
    if ([actionSheet numberOfButtons] < 7 && buttonIndex > 3) {
        buttonIndex++;
    }
	switch (buttonIndex) {
        case 0:
            //email link
            if ([MFMailComposeViewController canSendMail])
            {
                MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
                controller.mailComposeDelegate = (id <MFMailComposeViewControllerDelegate>)self;
                
                NSString *user = [[NSUserDefaults standardUserDefaults] stringForKey:redditUsernameKey];
                
                if (user)
                    [controller setSubject:[NSString stringWithFormat:@"[ireddit] %@ thinks you're going to like this link", user]];
                else
                    [controller setSubject:[NSString stringWithFormat:@"[ireddit] check out this link from %@",
                                            story.subreddit ? [NSString stringWithFormat:@"the %@ reddit", story.subreddit] : @"reddit"]];
                
                [controller setMessageBody:[NSString stringWithFormat:@"%@ shared a link with you from iReddit (http://reddit.com/iphone):\n\n%@\n\n\"%@\"\n\n%@\n\n%@",
                                            user ? user : @"someone",
                                            story.URL,
                                            story.title ? story.title : @"sorry, we couldn't find the title. you'll have to click to find out",
                                            story.totalComments ? @"there's also a discussion going on here:" : @"",
                                            story.totalComments ? story.commentsURL : @""]
                                    isHTML:NO];
                
                [self presentViewController:controller animated:YES completion:nil];
                
                //[[Beacon shared] startSubBeaconWithName:@"emailedStory" timeSession:NO];
            }
            else
            {
                [[[UIAlertView alloc] initWithTitle:@"E-mail Error"
                                            message:@"Your device is not configured to send mail. Update your mail information in the Settings application and try again."
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            }
            break;
        case 1:
            //open link in safari
            //[[Beacon shared] startSubBeaconWithName:@"openedInSafari" timeSession:NO];
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"]) {
                NSString *appName =
                [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
                url = [NSString stringWithFormat:
                       @"googlechrome-x-callback://x-callback-url/open/?x-source=%@&x-success=%@&url=%@&create-new-tab",
                       encodeByAddingPercentEscapes(appName),
                       encodeByAddingPercentEscapes(@"ireddit://"),
                       encodeByAddingPercentEscapes(url)];
            }
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
            break;
        case 2:
            if (![[LoginController sharedLoginController] isLoggedIn])
                [LoginViewController presentWithDelegate:(id <LoginViewControllerDelegate>)self context:@"hide"];
            else
            {
                [self hideCurrentStory:nil];
                //	[[Beacon shared] startSubBeaconWithName:@"savedOnReddit" timeSession:NO];
            }
            break;
        case 3:
            if (![[LoginController sharedLoginController] isLoggedIn])
                [LoginViewController presentWithDelegate:(id <LoginViewControllerDelegate>)self context:@"save"];
            else
            {
                [self saveCurrentStory:nil];
                //	[[Beacon shared] startSubBeaconWithName:@"savedOnReddit" timeSession:NO];
            }
            break;
        case 4:
            //		[self saveOnInstapaper:nil];
            //		//[[Beacon shared] startSubBeaconWithName:@"instapaper" timeSession:NO];
            //break;
            //case 5:
            [self saveOnPocket:nil];
            break;
        case 5:
        {
            MFMessageComposeViewController *message = [[MFMessageComposeViewController alloc] init];
            message.messageComposeDelegate = self;
            [message setBody:self.webview.request.URL.absoluteString];
            [self presentViewController:message animated:YES completion:nil];
        }
        default:
            [self actionSheetCancel:_currentSheet];
            break;
    }
}

-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    switch (result) {
        case MessageComposeResultSent:
            NSLog(@"Message Sent");
            break;
        case MessageComposeResultCancelled:
            NSLog(@"Message Cancelled");
            break;
        case MessageComposeResultFailed:
            NSLog(@"Message Failed");
            break;
        default:
            NSLog(@"Message Other");
            break;
    }
    [controller dismissViewControllerAnimated:YES completion:nil];

}

static NSString * encodeByAddingPercentEscapes(NSString *input) {
    NSString *encodedValue =
    (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                          kCFAllocatorDefault,
                                                                          (CFStringRef)input,
                                                                          NULL,
                                                                          (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                          kCFStringEncodingUTF8));
    return encodedValue;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)saveOnInstapaper:(id)sender
{
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:instapaperUsernameKey];
    NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:instapaperPasswordKey];
    
    if (!password || [password isEqual:@""])
        password = @"password";
    
    if (!username || [username isEqual:@""])
    {
        [[[UIAlertView alloc] initWithTitle:@"Instapaper Error"
                                    message:@"You must provide an Instapaper username to save stories with Instapaper. You can add a username in the iReddit settings."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;
    }
    
    NSString *url = story.URL;
    if (isForComments && story.commentsURL)
        url = story.commentsURL;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:InstapaperAPIString]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setValue:username forKey:@"username"];
    [request setValue:password forKey:@"password"];
    [request setValue:url forKey:@"url"];
    [request setValue:(story.title ? story.title : @"no title") forKey:@"title"];
    
    [request setHTTPMethod:@"POST"];
    
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:nil];
    [connection start];
    
}
- (void)saveOnPocket:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"usePocket"]) {
        if ([PocketAPI sharedAPI].isLoggedIn) {
            NSString *stringURL = self.webview.request.URL.absoluteString;
            if (isForComments && story.commentsURL)
                stringURL = story.commentsURL;
            NSURL *url = [NSURL URLWithString:stringURL];
            [[PocketAPI sharedAPI] saveURL:url handler: ^(PocketAPI *API, NSURL *URL,
                                                          NSError *error){
                if(error){
                    // there was an issue connecting to Pocket
                    // present some UI to notify if necessary
                }else{
                    
                    GIDAAlertView *gav = [[GIDAAlertView alloc] initWithCheckMarkAndMessage:@"Saved to Pocket"];
                    [gav setColor:[iRedditAppDelegate redditNavigationBarTintColor]];
                    [gav presentAlertFor:1.07];
                    // the URL was saved successfully
                }
            }];
        } else {
            
        }
    }
}

- (void)saveCurrentStory:(id)sender
{
    NSString *url = [NSString stringWithFormat:@"%@%@", RedditBaseURLString, RedditSaveStoryAPIString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setHTTPShouldHandleCookies:[[LoginController sharedLoginController] isLoggedIn] ? YES : NO];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"uh=%@&id=%@&_=",
                           [[LoginController sharedLoginController] modhash], story.name]
                          dataUsingEncoding:NSASCIIStringEncoding]];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:nil];
    [connection start];
    
}

- (void)hideCurrentStory:(id)sender
{
    NSString *url = [NSString stringWithFormat:@"%@%@", RedditBaseURLString, RedditHideStoryAPIString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"uh=%@&id=%@&executed=hidden",
                           [[LoginController sharedLoginController] modhash], story.name]
                          dataUsingEncoding:NSASCIIStringEncoding]];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:nil];
    [connection start];
    
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    if ([viewControllers count] > 2 && [[viewControllers objectAtIndex:[viewControllers count] - 2] isKindOfClass:[SubredditViewController class]])
    {
        SubredditViewController *controller = (SubredditViewController *)[viewControllers objectAtIndex:[viewControllers count] - 2];
        SubredditData *ds = (SubredditData *)controller.dataSource;
        [ds removeStory:self.story];
    }
}

- (void)loginViewController:(LoginViewController *)aController didFinishWithContext:(id)aContext
{
    if ([[LoginController sharedLoginController] isLoggedIn])
    {
        if ([aContext isEqual:@"save"])
            [self saveCurrentStory:self];
        else if ([aContext isEqual:@"voteUp"])
            [self voteUp:self];
        else if ([aContext isEqual:@"voteDown"])
            [self voteDown:self];
        else if ([aContext isEqual:@"hide"])
            [self hideCurrentStory:self];
    }
}

- (IBAction)segmentAction:(id)sender
{
    switch ([sender selectedSegmentIndex])
    {
        case 0:
            [_webview goBack];
            break;
        case 1:
            if ([_webview isLoading])
            {
                [_webview stopLoading];
                [self webViewDidFinishLoad:_webview];
            }
            else
            {
                [_webview reload];
            }
            
            break;
        case 2:
            [_webview goForward];
            break;
    }
    //[[Beacon shared] startSubBeaconWithName:@"usedSegmentNav" timeSession:NO];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
 //   if(((RedditWebView *)webView).currentNavigationType != UIWebViewNavigationTypeOther) {
    if (_loadingView) {
        [_loadingView setHidden:NO];
        [_loadingView startAnimating];
    }
    [(UILabel *)(self.navigationItem.titleView) setText:@"Loading..."];
    [_segmentedControl setEnabled:[webView canGoBack] forSegmentAtIndex:0];
    [_segmentedControl setEnabled:[webView canGoForward] forSegmentAtIndex:2];
    [_segmentedControl setImage:[UIImage imageNamed:@"stop.png"] forSegmentAtIndex:1];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if ([_loadingView isAnimating])
    {
        [_loadingView setHidden:YES];
        [_loadingView stopAnimating];
    }
    
    [_segmentedControl setEnabled:[webView canGoBack] forSegmentAtIndex:0];
    [_segmentedControl setEnabled:[webView canGoForward] forSegmentAtIndex:2];
    [_segmentedControl setImage:[UIImage imageNamed:@"refresh.png"] forSegmentAtIndex:1];
    
    [(UILabel *)(self.navigationItem.titleView) setText:[webView stringByEvaluatingJavaScriptFromString:@"document.title"]];
}
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setScore:story.score];
    
    CGFloat iosVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iosVer >= 7.0) {
        self.navigationController.toolbar.tintColor = [iRedditAppDelegate redditNavigationBarTintColor];
    } else {
    self.navigationController.toolbar.tintColor = [UIColor blackColor];
    }
    
    if (self.navigationController.toolbarHidden)
        [self.navigationController setToolbarHidden:NO animated:YES];
}
-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
    if ([self isMovingFromParentViewController]){
        //specific stuff for being popped off stack
        self.story = nil;
        self.scoreItem = nil;
        self.commentCountItem = nil;
        self.toggleButtonItem = nil;
        self.segmentedControl = nil;
        self.loadingView = nil;
        
        [_webview stopLoading];
        [_webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        
        CGRect frame = self.webview.frame;
        frame.size.height += self.navigationController.toolbar.frame.size.height;
        self.webview.frame = frame;
        
        [self.navigationController setToolbarHidden:YES animated:YES];
        [_webview setDelegate:nil];
        [_webview removeFromSuperview];
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        
    }
}
-(void)backButtonDidPressed:(id)sender {
    //[super viewDidUnload];
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
