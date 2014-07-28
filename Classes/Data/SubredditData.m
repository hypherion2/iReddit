//
//  SubredditDataModel.m
//  iReddit
//
//  Created by Ryan Bruels on 7/21/10.
//  Modified by Alejandro Paredes Alva 2013
//

#import "SubredditData.h"

@interface SubredditData ()
@property (nonatomic, strong) NSMutableSet *addresses;
@property (nonatomic, strong) NSMutableArray *storiesArray;
@end

@implementation SubredditData
@synthesize subreddit = _subreddit;
@synthesize newsModeIndex;

- (id)initWithSubreddit:(NSString *)subreddit
{
	if (self = [super init])
	{
        self.newsModeIndex = 0;
		_subreddit = subreddit;
        self.storiesArray = [[NSMutableArray alloc] init];
        _addresses = [NSMutableSet set];
    }
	
	return self;
}
-(Story *)storyWithIndex:(int)anIndex {
    return [self.storiesArray  objectAtIndex:anIndex];
}
-(void)removeStory:(Story *)story {
    [self.storiesArray  removeObject:story];
}
- (BOOL)canLoadMore
{
    return canLoadMore;
}

- (BOOL)isLoaded
{
    return [self.storiesArray  count] > 0;
}

- (NSArray *)stories {
    return self.storiesArray;
}
- (void)loadMore:(BOOL)more
{
    NSString *loadURL = [self fullURL];
    
    if(more) {
        id object = [self.stories lastObject];

        Story *story = (Story *)object;
        NSString *lastItemID = story.name;

        loadURL = [NSString stringWithFormat:@"%@%@%@", [self fullURL], MoreItemsFormattedString, lastItemID];
    } else {
        // clear the stories for this subreddit
        [self.storiesArray  removeAllObjects];
        self.storiesArray  = [NSMutableArray array];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:loadURL]];
   // [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"GET"];
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error) {
        NSLog(@"%@",error.description);
        return;
    }
       // parse the JSON data that we retrieved from the server
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    NSInteger totalCount = 0;
    // drill down into the JSON object to get the part 
    // that we're actually interested in.
	if (![json isKindOfClass:[NSDictionary class]])
	{
		return;
	}
    NSDictionary *resultSet = [json objectForKey:@"data"];
    NSArray *results = [resultSet objectForKey:@"children"];
   
    for (NSDictionary *result in results) {
		NSDictionary *data = [result objectForKey:@"data"];
		
		Story *theStory = [Story storyWithDictionary:data inReddit:self];
		theStory.index = [self.storiesArray count];
        
        if (![_addresses containsObject:theStory.name]) {
            [_addresses addObject:theStory.name];
            [self.storiesArray  addObject:theStory];
        }
	}
    
	canLoadMore = [self.storiesArray  count] > totalCount;
    
}
- (NSString *)fullURL {
	return [NSString stringWithFormat:@"%@%@%@%@", RedditBaseURLString, self.subreddit, [self newsModeString], RedditAPIExtensionString];
}

- (NSUInteger)totalStories
{
    return [self.storiesArray count];
}

- (NSString *)newsModeString
{
	switch (newsModeIndex)
	{
		case 0:
			return SubRedditNewsModeHot;
		case 1:
			return SubRedditNewsModeNew;
        case 2:
            return SubRedditNewsModeRising;
		case 3:
			return SubRedditNewsModeTop;
		case 4:
			return SubRedditNewsModeControversial;
	}
	
	return @"";
}

- (void)invalidate:(BOOL)erase 
{
    if (erase) {
        [self.storiesArray  removeAllObjects];
        [self.addresses removeAllObjects];
    }
}



@end
