//
//  MergeVideoView.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 6/10/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "MergeVideoView.h"
#define CHECK_IMAGE @"checkButton.png"

@implementation MergeVideoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)setup
{
    UITapGestureRecognizer * recognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapped:)];
    [self addGestureRecognizer:recognizer];
}

-(void)tapped:(UITapGestureRecognizer*)recognizer
{
   if (recognizer.state == UIGestureRecognizerStateEnded)
   {
       self.tapped = !self.tapped;
   }
}

-(void)setFirstFrame:(UIImage *)firstFrame
{
    if (_firstFrame!=firstFrame)
    {
        _firstFrame = firstFrame;
        if (_firstFrame) [self setNeedsDisplay];
    }
}

-(void)setTitle:(NSString *)title
{
    if ([_title isEqualToString:title])
    {
        _title = title;
        if (_title) [self setNeedsDisplay];
    }
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    
    [self.firstFrame drawInRect:rect];
    CGPoint point;
    point.x = CGRectGetMinX(rect);
    point.y = CGRectGetHeight(rect)*0.2;
    [self.title drawAtPoint:point withFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];
    
    if (self.tapped)
    {
        UIImage * checkImage = [UIImage imageNamed:CHECK_IMAGE];
        CGSize checkImageSize = checkImage.size;
        CGFloat y = CGRectGetHeight(rect)*0.8 -checkImageSize.height;
        CGFloat x = CGRectGetMaxX(rect)- checkImageSize.width;
        [checkImage drawAtPoint:CGPointMake(x, y) blendMode:kCGBlendModeNormal alpha:0.8];
    }
}


@end
