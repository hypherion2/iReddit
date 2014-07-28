//
//  MessageViewController.h
//  Reddit2
//
//  Created by Ross Boucher on 6/16/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CreateMessage.h"
#import "MessageCell.h"

@interface MessageViewController : UIViewController <CreateMessageDelegate,UITableViewDataSource,UITableViewDelegate>

@end
