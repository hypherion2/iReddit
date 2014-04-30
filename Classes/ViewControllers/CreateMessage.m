//
//  CreateMessageViewController.m
//  iReddit
//
//  Created by Alejandro Paredes Alva on 3/29/13.
//
//

#import "CreateMessage.h"

@interface CreateMessage ()
@property (nonatomic, strong) NSString *captchaID;
@property (nonatomic, strong) UIImage  *captchaImage;
@end

@implementation CreateMessage

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _subject = nil;
        [self newCaptcha];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _subjectLabel.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    _subjectLabel.layer.borderWidth = 1.0f;
    if (_subject) {
        [_subjectField setText:_subject];
    }
    
    _toField.text = _to;
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:60.0/255.0 green:120.0/255.0 blue:225.0/255.0 alpha:1.0];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)]];

    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleBordered target:self action:@selector(send:)]];

}
-(void)newCaptcha {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.reddit.com/api/new_captcha"]];
    [request setHTTPBody:[@"api_type=json" dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPMethod:@"POST"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            
        } else {
            id dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if ([dict isKindOfClass:[NSDictionary class]]) {
                _captchaID = dict[@"json"][@"data"][@"iden"];
                _captchaImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.reddit.com/captcha/%@.png",_captchaID]]]];
            }
        }
    }];
}
-(void)send:(id)sender {
    GIDAAlertView *gav = [[GIDAAlertView alloc] initWithImage:_captchaImage andMessage:@"" cancelButtonTitle:@"cancel" acceptButtonTitle:@"accept"];
    [gav setColor:[UIColor colorWithRed:60.0/255.0 green:120.0/255.0 blue:225.0/255.0 alpha:1.0]];
    [gav setDelegate:self];
    [gav show];
         //
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection {

}
-(void)alertOnClicked:(GIDAAlertView *)alertView {
    if ([alertView accepted]) {
    NSArray *array = [NSArray arrayWithObjects:_toField.text, _subjectField.text, _body.text, _captchaID, [alertView enteredText], nil];
        [self.delegate composeController:self didSendFields:array];
    }
}
-(void)cancel:(id)sender {
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setToLabel:nil];
    [self setSubjectLabel:nil];
    [self setSubjectField:nil];
    [self setToField:nil];
    [self setBody:nil];
    [super viewDidUnload];
}
@end
