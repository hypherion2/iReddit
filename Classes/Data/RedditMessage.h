//
//  Message.h
//  Reddit
//
//  Created by Ross Boucher on 3/10/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RedditMessage : NSObject 
{
	NSAttributedString	*body;
    NSString        *name;
    NSString        *identifier;
    NSString        *author;
    NSString        *destination;
    NSString        *subject;
    NSString        *created;
    NSString        *context;
    BOOL            isCommentReply;
    BOOL            isNew;
	
	float           heights[2];
}

+ (RedditMessage *)messageWithDictionary:(NSDictionary *)dict;

- (CGFloat)heightForDeviceMode:(UIDeviceOrientation)orientation;


//private
- (void)setHeight:(CGFloat)aHeight forIndex:(int)anIndex;


@property (nonatomic, strong) NSAttributedString	*body;
@property (nonatomic, strong) NSString	*name;
@property (nonatomic, strong) NSString	*identifier;
@property (nonatomic, strong) NSString	*author;
@property (nonatomic, strong) NSString	*destination;
@property (nonatomic, strong) NSString	*subject;
@property (nonatomic, strong) NSString	*context;
@property (nonatomic, strong) NSString	*created;
@property (nonatomic, assign) BOOL		isCommentReply;
@property (nonatomic, assign) BOOL		isNew;

@end
