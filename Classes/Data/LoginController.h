//
//  LoginController.h
//  Reddit2
//
//  Created by Ross Boucher on 6/15/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LoginController : NSObject
{
	NSString *modhash;
	NSDate *lastLoginTime;
    BOOL isLoggingIn;
}

@property (nonatomic, strong) NSString *modhash;
@property (nonatomic, strong) NSDate *lastLoginTime;

+ (id)sharedLoginController;

- (BOOL)isLoggedIn;
- (BOOL)isLoggingIn;

- (void)loginWithUsername:(NSString *)aUsername password:(NSString *)aPassword;
- (void)logOut;
@end
