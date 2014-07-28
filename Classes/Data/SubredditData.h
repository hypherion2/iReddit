//
//  SubredditDataModel.h
//  iReddit
//
//  Created by Ryan Bruels on 7/21/10.
//  Modified by Alejandro Paredes Alva 2013
//

#import <Foundation/Foundation.h>
#import "Constants.h"
#import "Story.h"
#import "LoginController.h"

@interface SubredditData : NSObject {
    NSString *_subreddit;
    int newsModeIndex;
    
    BOOL canLoadMore;
    NSUInteger totalStories;
}
@property (nonatomic, readonly) NSString *subreddit;
@property (readonly) NSArray *stories;

@property (nonatomic, assign) int newsModeIndex;
- (Story *)storyWithIndex:(int)anIndex;
-(void)removeStory:(Story *)story;
- (void)loadMore:(BOOL)more;
- (id)initWithSubreddit:(NSString *)subreddit;
- (NSString *)newsModeString;
- (NSUInteger)totalStories;
- (NSString *)fullURL;
- (BOOL)canLoadMore;
- (BOOL)isLoaded;
- (void)invalidate:(BOOL)erase;
@end
