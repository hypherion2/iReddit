//
//  MessageDataSource.m
//  Reddit2
//
//  Created by Ross Boucher on 6/16/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import "MessageDataSource.h"
#import "Constants.h"
#import "RedditMessage.h"
#import "MessageCell.h"
#import "LoginController.h"

@interface MessageDataSource ()
@property (nonatomic, strong) NSMutableArray *items;
@end

@implementation MessageDataSource

- (id)init
{
	if (self = [super init])
	{
		canLoadMore = YES;
        _items = [NSMutableArray array];
	}
    
	return self;
}
-(NSInteger)count {
    return _items.count;
}
-(RedditMessage *)messageAtIndex:(NSInteger)index {
    return [_items objectAtIndex:index];
}
- (void)dealloc
{
	[self cancel];
}

- (BOOL)canLoadMore
{
	return canLoadMore;
}

- (NSDate *)loadedTime
{
    return lastLoadedTime;
}

- (BOOL)isLoading
{
    return isLoading;
}

- (BOOL)isLoadingMore
{
    return isLoadingMore;
}

- (BOOL)isLoaded
{
    return lastLoadedTime != nil;
}

- (void)invalidate:(BOOL)erase
{
	[self.items removeAllObjects];
}

- (void)cancel
{
    
}

- (void)didStartLoad
{
    isLoading = YES;
}

- (void)didFinishLoad
{
    isLoading = NO;
    isLoadingMore = NO;
    lastLoadedTime = [NSDate date];
}

- (void)didFailLoadWithError:(NSError*)error
{
    isLoading = NO;
    isLoadingMore = NO;
}

- (void)didCancelLoad
{
    isLoading = NO;
    isLoadingMore = NO;
}

- (unsigned int)unreadMessageCount
{
	return unreadMessageCount;
}

- (unsigned int)messageCount
{
	return [self.items count];
}

- (void)loadMore:(BOOL)more {
	NSString *loadURL = [NSString stringWithFormat:@"%@%@", RedditBaseURLString, RedditMessagesAPIString];
    
	if (more) {
		id object = [self.items lastObject];
		
		RedditMessage *lastMessage = (RedditMessage *)object;
		loadURL = [NSString stringWithFormat:@"%@&after=%@", loadURL, lastMessage.name];
	} else {
		// remove any previous items
		[self.items removeAllObjects];
		unreadMessageCount = 0;
	}
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:loadURL]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setHTTPShouldHandleCookies:YES];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"GET"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"ERROR GETTING MESSAGES: %@",error.description);
        } else {
            canLoadMore = NO;
            
            int totalCount = [self.items count];
            NSError *error = nil;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
            if (error) {
                NSLog(@"%@",error.description);
                NSString *stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"%@",stringData);
            }
            if (![json isKindOfClass:[NSDictionary class]])
            {
                [self didFinishLoad];
                return;
            }
            
            NSArray *results = [[json objectForKey:@"data"] objectForKey:@"children"];
            
            unreadMessageCount = 0;
            for (NSDictionary *result in results)
            {
                RedditMessage *newMessage = [RedditMessage messageWithDictionary:[result objectForKey:@"data"]];
                if (newMessage)
                {
                    [self.items	addObject:newMessage];
                    
                    if (newMessage.isNew)
                        unreadMessageCount++;
                }
            }
            
            canLoadMore = [self.items count] > totalCount;
            
            [self didFinishLoad];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:MessageCountDidChangeNotification object:nil];
        }
    }];
}
@end
