//
//  Message.m
//  Reddit
//
//  Created by Ross Boucher on 3/10/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import "RedditMessage.h"
#import "Constants.h"
#define PORTRAIT_INDEX 0
#define LANDSCAPE_INDEX 1


@implementation RedditMessage

@synthesize body, name, created, subject, identifier, destination, author, context, isCommentReply, isNew;

+ (RedditMessage *)messageWithDictionary:(NSDictionary *)dict
{			
    RedditMessage *aMessage = [[RedditMessage alloc] init];
	NSString *messageBody = (NSString *)[dict objectForKey:@"body_html"];
    //NSLog(@"$%@",messageBody);
    messageBody = [messageBody stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    messageBody = [messageBody stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    messageBody = [messageBody stringByReplacingOccurrencesOfString:@"&amp;lt;" withString:@"&lt;"];
    messageBody = [messageBody stringByReplacingOccurrencesOfString:@"&amp;gt;" withString:@"&gt;"];
    
    //NSLog(@"$%@",messageBody);
    NSData *htmlData = [messageBody dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *options = @{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType };
    NSError      *error = nil;
    aMessage.body = [[NSAttributedString alloc] initWithData:htmlData options:options documentAttributes:nil error:&error];
	aMessage.author = (NSString *)[dict objectForKey:@"author"];
	aMessage.subject = (NSString *)[dict objectForKey:@"subject"];
	aMessage.destination = (NSString *)[dict objectForKey:@"destination"];
	aMessage.identifier = (NSString *)[dict objectForKey:@"id"];
	aMessage.name = (NSString *)[dict objectForKey:@"name"];
	aMessage.context = [NSString stringWithFormat:@"%@%@", RedditBaseURLString, (NSString *)[dict objectForKey:@"context"]];
	//aMessage.created = (NSString *)[(NSNumber *)[dict objectForKey:@"created"] stringValue];
    double unixTimeStamp =[(NSNumber *)[dict objectForKey:@"created"] doubleValue];
    NSTimeInterval _interval=unixTimeStamp;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_interval];
    NSDateFormatter *_formatter=[[NSDateFormatter alloc]init];
    [_formatter setTimeZone:[NSTimeZone localTimeZone]];
   // [_formatter setLocale:[NSLocale currentLocale]];
    [_formatter setDateFormat:@"yyyy.MM.dd HH:mm:ss"];

    aMessage.created =[_formatter stringFromDate:date];
    //NSLog(@"%@\t%0.0f",aMessage.created,[NSDate timeIntervalSinceReferenceDate]);
	aMessage.isNew = [(NSNumber *)[dict objectForKey:@"new"] boolValue];
	aMessage.isCommentReply = [(NSNumber *)[dict objectForKey:@"was_comment"] boolValue];

	// precompute the height of the resulting cell
	
	
	UIFont *subjectFont = [UIFont boldSystemFontOfSize:14.0];
	CGFloat height;
	
    // sets up the TTStyledText's width, which allows "height" to do the proper calculation (for body only)
    CGSize constrainedSize = CGSizeMake(280, 1000);
  //  aMessage.body.size.width = constrainedSize.width;
    CGRect frame;
        frame = [aMessage.body boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
    
	height = frame.size.height;
	height += (CGFloat)([aMessage.subject sizeWithFont:subjectFont constrainedToSize:constrainedSize lineBreakMode:NSLineBreakByTruncatingTail]).height;
	height += 18.0 + 12.0 + 12.0;
	
	[aMessage setHeight:height forIndex:PORTRAIT_INDEX];

    constrainedSize = CGSizeMake(440, 1000);
        frame = [aMessage.body boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
   
	height = frame.size.height;
    height += (CGFloat)([aMessage.subject sizeWithFont:subjectFont constrainedToSize:constrainedSize lineBreakMode:NSLineBreakByCharWrapping]).height;
	height += 18.0 + 12.0 + 12.0;

	[aMessage setHeight:height forIndex:LANDSCAPE_INDEX];	
	
	
	return aMessage;
}

- (void)setHeight:(CGFloat)aHeight forIndex:(int)anIndex
{
	heights[anIndex] = aHeight;
}

- (CGFloat)heightForDeviceMode:(UIDeviceOrientation)orientation
{	
	if (UIDeviceOrientationIsPortrait(orientation) || !UIDeviceOrientationIsValidInterfaceOrientation(orientation))
		return heights[PORTRAIT_INDEX];
	else
		return heights[LANDSCAPE_INDEX];
}


@end
