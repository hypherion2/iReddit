//
//  StoryCell.m
//  Reddit
//
//  Created by Ross Boucher on 11/25/08.
//  Copyright 2008 280 North. All rights reserved.
//

#import "StoryCell.h"
#import "Constants.h"

@implementation StoryCell

@synthesize storyTitleView, storyDescriptionView, storyImage;
@dynamic story;

+ (float)tableView:(UITableView *)aTableView rowHeightForObject:(Story *)aStory
{
    float height = [aStory heightForDeviceMode:[[UIDevice currentDevice] orientation] 
								 withThumbnail:[[NSUserDefaults standardUserDefaults] boolForKey:showStoryThumbnailKey] && [aStory hasThumbnail]] + 46.0;
	
    if ([[NSUserDefaults standardUserDefaults] boolForKey:showStoryThumbnailKey])
		return MAX(height, 68.0);
	else
		return height;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {	
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.opaque = YES;
		self.backgroundColor = [UIColor whiteColor];

		for (UIView *view in [self subviews])
		{
			[view setBackgroundColor:[UIColor whiteColor]];
			[view setOpaque:YES];
		}

		self.superview.opaque = YES;
		self.superview.backgroundColor = [UIColor whiteColor];

		for (UIView *view in [[self superview] subviews])
		{
			[view setBackgroundColor:[UIColor whiteColor]];
			[view setOpaque:YES];
		}
		
		story = nil;

		storyTitleView = [[UILabel alloc] initWithFrame:CGRectZero];		
		storyTitleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

		[storyTitleView setFont:[UIFont boldSystemFontOfSize:14]];
		[storyTitleView setTextColor:[UIColor blueColor]];
		[storyTitleView setLineBreakMode:NSLineBreakByTruncatingTail];
		[storyTitleView setNumberOfLines:0];
		//[storyTitleView setLineBreakMode:UILineBreakModeWordWrap];
		
		storyDescriptionView = [[UILabel alloc] initWithFrame:CGRectZero];
		storyDescriptionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

		[storyDescriptionView setFont:[UIFont boldSystemFontOfSize:12]];
		[storyDescriptionView setTextColor:[UIColor grayColor]];
		[storyDescriptionView setLineBreakMode:NSLineBreakByWordWrapping];
		
		secondaryDescriptionView = [[UILabel alloc] initWithFrame:CGRectZero];
		secondaryDescriptionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
		[secondaryDescriptionView setFont:[UIFont systemFontOfSize:12]];
		[secondaryDescriptionView setTextColor:[UIColor grayColor]];
		[secondaryDescriptionView setLineBreakMode:NSLineBreakByWordWrapping];

		[[self contentView] addSubview:storyTitleView];
		[[self contentView] addSubview:storyDescriptionView];
		[[self contentView] addSubview:secondaryDescriptionView];
        
		storyImage = [[UIImageView alloc] initWithFrame:CGRectZero];
        [storyImage setImage:[UIImage imageNamed:@"noimage.png"]];
		storyImage.autoresizesSubviews = NO;
		storyImage.contentMode = UIViewContentModeScaleAspectFill;
		storyImage.clipsToBounds = YES;
		storyImage.opaque = YES;
		storyImage.backgroundColor = [UIColor whiteColor];
        CALayer * l = [storyImage layer];
        [l setMasksToBounds:YES];
        [l setCornerRadius:10.0];

		[[self contentView] addSubview:storyImage];
    }
	
    return self;
}

- (void)layoutSubviews 
{
	[super layoutSubviews];
	
    CGRect contentRect = self.contentView.bounds;
	CGRect labelRect = contentRect;

	//contentRect.size.width = 320;
	
	float yOffset = 4.0;
	if (contentRect.size.height > 68)
		yOffset = 8.0;
	
	storyImage.frame = CGRectMake(8, yOffset, 60, 60);

	//BOOL showThumbnails = [[NSUserDefaults standardUserDefaults] boolForKey:@"showStoryThumbnails"];
	
    
	if ([storyImage isHidden])
	{
		//[storyImage setHidden:YES];
		
		labelRect.origin.y = contentRect.origin.y + 4.0;
		labelRect.origin.x = contentRect.origin.x + 8.0;
		
		labelRect.size.width = contentRect.size.width - 14.0;
		labelRect.size.height = contentRect.size.height - 44.0;
	}
	else
	{
		//[storyImage setHidden:NO];

		labelRect.origin.y = labelRect.origin.y + 4.0;
		labelRect.origin.x = labelRect.origin.x + 16.0 + storyImage.frame.size.height;
				
		labelRect.size.width = contentRect.size.width - 22.0 - storyImage.frame.size.width;
		labelRect.size.height = contentRect.size.height - 44.0;		
	}
	
	storyTitleView.frame = labelRect;
	storyDescriptionView.frame = CGRectMake(labelRect.origin.x, CGRectGetHeight(contentRect) - 40.0, labelRect.size.width, 16);
	secondaryDescriptionView.frame = CGRectMake(labelRect.origin.x, CGRectGetHeight(contentRect) - 24.0, labelRect.size.width, 16);
}


- (void)setHighlighted:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
	
	//UIColor *titleColor = selected ? [UIColor colorWithRed:85.0/255.0 green:26.0/255.0 blue:139.0/255.0 alpha:1.0] : [UIColor blueColor];
	UIColor *titleColor = story.visited ? [UIColor colorWithRed:85.0/255.0 green:26.0/255.0 blue:139.0/255.0 alpha:1.0] : [UIColor blueColor];
	UIColor *finalColor = selected ? [UIColor whiteColor] : titleColor;
	UIColor *descriptionColor = selected ? [UIColor colorWithWhite:0.8 alpha:1.0] : [UIColor grayColor];
	
	[storyTitleView setTextColor:finalColor];
	[storyDescriptionView setTextColor:descriptionColor];
	[secondaryDescriptionView setTextColor:descriptionColor];
}

- (Story *)story
{
	return story;
}

- (void)setStory:(Story *)aStory 
{		
	story = aStory;

	if (!story)
	{
        [storyImage setImage:nil];
		//[storyImage setUrlPath:nil];
		[storyTitleView setText:@""];
		[storyDescriptionView setText:@""];
		[secondaryDescriptionView setText:@""];
		return;
	}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:showStoryThumbnailKey])
	{
		if ([story hasThumbnail])
		{
			[storyImage setHidden:NO];
            [storyImage setImage:[UIImage imageNamed:@"noimage.png"]];
		   if (![story.thumbnailURL isEqualToString:@"self"] && ![story.thumbnailURL isEqualToString:@"nsfw"] && ![story.thumbnailURL isEqualToString:@"default"]) {
                NSString *temp = [story.thumbnailURL stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
                temp = [temp stringByReplacingOccurrencesOfString:@":" withString:@"_"];
                temp = [NSTemporaryDirectory() stringByAppendingString:temp];
                if (![[NSFileManager defaultManager] fileExistsAtPath:temp]) {
                    [self performSelectorInBackground:@selector(setThumbnail) withObject:nil];
                } else {
                    [storyImage setImage:[UIImage imageWithContentsOfFile:temp]];
                }
                
            }
		}
		else
		{
			[storyImage setHidden:YES];
		}
	}
	else
		[storyImage setHidden:YES];
	
	UIColor *titleColor = story.visited ? [UIColor colorWithRed:85.0/255.0 green:26.0/255.0 blue:139.0/255.0 alpha:1.0] : [UIColor blueColor];
	[storyTitleView setTextColor:titleColor];
	story.title = [story.title stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    story.title = [story.title stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    story.title = [story.title stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
	[storyTitleView setText:story.title];
    
	[storyTitleView setNeedsDisplay];
	
	[storyDescriptionView setText:[NSString stringWithFormat:@"%@", story.domain]];
	[storyDescriptionView setNeedsDisplay];
	
	[secondaryDescriptionView setText:[NSString stringWithFormat:@"%d points in %@ by %@", story.score, story.subreddit, story.author ]];//]], story.totalComments, story.totalComments == 1  ? @"" : @"s"]];
	[secondaryDescriptionView setNeedsDisplay];
}
-(void)setThumbnail {
    NSString *temp = [story.thumbnailURL stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    temp = [temp stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    temp = [NSTemporaryDirectory() stringByAppendingString:temp];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:story.thumbnailURL]];
    [data writeToFile:temp atomically:YES];
    [storyImage setImage:[UIImage imageWithContentsOfFile:temp]];
}
@end
