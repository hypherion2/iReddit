//
//  LoginController.m
//  Reddit2
//
//  Created by Ross Boucher on 6/15/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import "LoginController.h"
#import "Constants.h"

LoginController *SharedLoginController = nil;

@implementation LoginController

@synthesize modhash, lastLoginTime;

+ (id)sharedLoginController
{
	if (!SharedLoginController)
	{
		SharedLoginController = [[self alloc] init];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults boolForKey:hasModHash]) {
            NSDate *last = [defaults objectForKey:@"lastLoginTime"];
            NSDate *now = [NSDate date];
            NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
            NSDateComponents *components = [calendar components:NSDayCalendarUnit fromDate:last toDate:now options:0];
            if ([components day] < 7) {
                SharedLoginController.modhash = [defaults objectForKey:redditModHash];
            } else {
                SharedLoginController.modhash = @"";
            }
        }   else
            SharedLoginController.modhash = @"";
	}
	
	return SharedLoginController;
}


- (BOOL)isLoggedIn {
    if (lastLoginTime == nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults boolForKey:hasModHash]) {
            id last = [defaults objectForKey:@"lastLoginTime"];
            if ([last isKindOfClass:[NSDate class]]) {
                NSDate *now = [NSDate date];
                NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                NSDateComponents *components = [calendar components:NSDayCalendarUnit fromDate:last toDate:now options:0];
                if ([components day] < 7) {
                    lastLoginTime = [defaults objectForKey:@"lastLoginTime"];
                } else {
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    [defaults setBool:NO forKey:hasModHash];
                    [defaults setObject:@"" forKey:@"lastLoginTime"];
                    [defaults setObject:@"" forKey:redditModHash];
                    [defaults synchronize];
                    self.modhash = @"";
                    self.lastLoginTime = nil;
                }
            }
        }
    }
    return lastLoginTime != nil;
}

- (BOOL)isLoggingIn {
    return isLoggingIn;
}

- (void)loginWithUsername:(NSString *)aUsername password:(NSString *)aPassword {
    self.lastLoginTime = nil;
    
    if (!aUsername || !aPassword || ![aUsername length] || ![aPassword length])
    {
        [self logOut];
        [[NSNotificationCenter defaultCenter] postNotificationName:RedditDidFinishLoggingInNotification object:nil];
        return;
    }
	
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:aUsername forKey:redditUsernameKey];
    [defaults setObject:aPassword forKey:redditPasswordKey];
    [defaults synchronize];
	isLoggingIn = YES;
	
	NSString *loadURL = [NSString stringWithFormat:@"%@%@", RedditBaseURLString, @"/api/login"];
	
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:loadURL]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"rem=on&passwd=%@&user=%@&api_type=json",
                           [aPassword stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                           [aUsername stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]
                          dataUsingEncoding:NSASCIIStringEncoding]];
    
    
  /*  [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://ssl.reddit.com/api/v1/authorize?client_id=wzfZMXgXtgjfMg&response_type=TYPE&state=holacomoestas&redirect_uri=http://com.paredesalva.ireddit&duration=permament&scope=identity,privatemesssages,mysubreddit,report,save,submit,subscribe,vote"]] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@",string);
    }];
    NSString *loadURL = @"https://ssl.reddit.com/api/v1/access_token";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:loadURL]];
    [request setHTTPMethod:@"POST"];
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", @"wzfZMXgXtgjfMg", @"sHMzzKyGB1-Ns9ZECLmWRpcSQPY"];
    NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength]];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    NSString *postData = [NSString stringWithFormat:@"{granttype:password, username:aparedes, password: chivas}"];
    [request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
   */
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (error) {
                                   NSLog(@"Error login in: %@",[error description]);
                                   isLoggingIn = NO;
                                   self.lastLoginTime = nil;
                                   [[NSNotificationCenter defaultCenter] postNotificationName:RedditDidFinishLoggingInNotification object:nil];
                               } else {
                                   [[NSNotificationCenter defaultCenter] postNotificationName:RedditDidBeginLoggingInNotification object:nil];
                                   NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                                   NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                   NSLog(@"%@",string);
                                   NSDictionary *responseJSON = [(NSDictionary *)json valueForKey:@"json"];
                                   BOOL loggedIn = !error && [responseJSON objectForKey:@"data"];
                                   
                                   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                   if (loggedIn) {
                                       self.modhash = (NSString *)[(NSDictionary *)[responseJSON objectForKey:@"data"] objectForKey:@"modhash"];
                                       self.lastLoginTime = [NSDate date];
                                       [defaults setBool:YES forKey:hasModHash];
                                       [defaults setObject:self.lastLoginTime forKey:@"lastLoginTime"];
                                   } else {
                                       self.modhash = @"";
                                       self.lastLoginTime = nil;
                                       NSLog(@"%@",responseJSON[@"errors"]);
                                       [defaults setObject:@"" forKey:redditUsernameKey];
                                       [defaults setObject:@"" forKey:redditPasswordKey];
                                       [defaults setBool:NO forKey:hasModHash];
                                       [defaults setObject:@"" forKey:@"lastLoginTime"];
                                       self.modhash = @"";
                                       self.lastLoginTime = nil;
                                   }
                                   [defaults setObject:self.modhash forKey:redditModHash];
                                   [defaults synchronize];
                                   
                                   isLoggingIn = NO;
                                   [[NSNotificationCenter defaultCenter] postNotificationName:RedditDidFinishLoggingInNotification object:nil];
                               }
                           }];
}
-(void)logOut {
    if ([self isLoggedIn]){
        self.modhash = @"";
        self.lastLoginTime = nil;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@"" forKey:redditUsernameKey];
        [defaults setObject:@"" forKey:redditPasswordKey];
        [defaults setBool:NO forKey:hasModHash];
        [defaults setObject:@"" forKey:@"lastLoginTime"];
        [defaults setObject:@"" forKey:redditModHash];
        [defaults synchronize];
        lastLoginTime = nil;
    }
}

@end
