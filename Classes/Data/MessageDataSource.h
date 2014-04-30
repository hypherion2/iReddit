//
//  MessageDataSource.h
//  Reddit2
//
//  Created by Ross Boucher on 6/16/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RedditMessage.h"

@interface MessageDataSource : NSObject
{	
    NSDate *lastLoadedTime;
    BOOL isLoading;
    BOOL isLoadingMore;
	BOOL canLoadMore;
    
	unsigned int unreadMessageCount;
	
	//TTURLRequest *activeRequest;
}
- (void)loadMore:(BOOL)more;
-(RedditMessage *)messageAtIndex:(NSInteger)index;
-(NSInteger)count;
- (unsigned int)unreadMessageCount;
// marking as read doesn't actually work from the API, so let's not pretend it does
//- (void)markRead:(id)sender;
- (BOOL)canLoadMore;
- (void)cancel;

@end
