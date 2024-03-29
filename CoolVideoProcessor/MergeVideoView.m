//
//  MergeVideoView.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 6/10/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "MergeVideoView.h"
#import "UIImage+Scale.h"
#define CHECK_IMAGE @"checkButton.png"

@implementation MergeVideoView

-(void)setTapped:(BOOL)tapped
{
    if (_tapped!=tapped)
    {
        _tapped =tapped;
        
        [self setNeedsDisplay];
    }
}

-(void)setFirstFrame:(UIImage *)firstFrame
{
    if (_firstFrame!=firstFrame)
    {
        _firstFrame = firstFrame;
        if (_firstFrame) if (!self.bulkReDraw) [self setNeedsDisplay];
    }
}

-(void)setTitle:(NSString *)title
{
    if (![_title isEqualToString:title])
    {
        _title = title;
        if (_title.length) if (!self.bulkReDraw)[self setNeedsDisplay];
    }
}

-(CGRect) imageFrame
{
    CGPoint offset = {CGRectGetMidX(self.frame)-self.firstFrame.size.width*0.5,CGRectGetMidY(self.frame)-self.firstFrame.size.height*0.5};
    
    return (CGRect){.origin = offset,.size = self.firstFrame.size};
}


-(void)drawScaledImage:(UIImage*)image inRect:(CGRect)rect
{
    if (image)
    {
        UIImage * newImage = [image scaleToSizeWithAspectRatio:rect.size];
        
        CGPoint offset = {CGRectGetMidX(rect)-newImage.size.width*0.5,CGRectGetMidY(rect)-newImage.size.height*0.5};
        
        [newImage drawAtPoint:offset];
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [self.backgroundColor setFill];
    UIRectFill(rect);
    
    
    [self drawScaledImage:self.firstFrame inRect:rect];
    
    //[self.firstFrame  drawInRect:rect];
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
