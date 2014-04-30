//
//  CreateMessageViewController.h
//  iReddit
//
//  Created by Alejandro Paredes Alva on 3/29/13.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "GIDAAlertView.h"
//#import "iRedditAppDelegate.h"

@class CreateMessage;

@protocol CreateMessageDelegate <NSObject>
- (void)composeController:(CreateMessage *)controller didSendFields:(NSArray*)fields;
@end

@interface CreateMessage : UIViewController  <GIDAAlertViewDelegate>
-(void)newCaptcha;
@property (strong, nonatomic) id<CreateMessageDelegate> delegate;
@property (strong, nonatomic) NSString *subject;
@property (strong, nonatomic) NSString *to;
@property (strong, nonatomic) IBOutlet UILabel *toLabel;
@property (strong, nonatomic) IBOutlet UILabel *subjectLabel;
@property (strong, nonatomic) IBOutlet UITextField *subjectField;
@property (strong, nonatomic) IBOutlet UITextField *toField;
@property (strong, nonatomic) IBOutlet UITextView *body;

@end

