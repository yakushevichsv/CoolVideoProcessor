//
//  MergeVideoView.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 6/10/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "MergeVideoView.h"
#define CHECK_IMAGE @"checkButton.png"

@interface MergeVideoView()
@property (nonatomic) UIActivityIndicatorView * indicator;
@end

@implementation MergeVideoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self= [super initWithCoder:aDecoder])
    {
        [self setup];
    }
    return self;
}

-(void)setup
{
    UITapGestureRecognizer * recognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapped:)];
    [self addGestureRecognizer:recognizer];
    
    self.indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.indicator.hidden = TRUE;
    self.indicator.hidesWhenStopped = TRUE;
}

-(void)setIsLoading:(BOOL)isLoading
{
    if (_isLoading!=isLoading)
    {
        _isLoading = isLoading;
        self.indicator.hidden = !isLoading;
        if (isLoading)
        {
            self.firstFrame = nil;
            self.title = nil;
            [self.indicator startAnimating];
        }
        else
        {
            [self.indicator stopAnimating];
        }
        
       if (!self.bulkReDraw) [self setNeedsDisplay];
    }
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

-(void)indicatorDrawRect:(CGRect)rect
{
    self.indicator.frame = CGRectMake(CGRectGetMidX(rect)-CGRectGetMidX(self.indicator.bounds), CGRectGetMidY(rect)-CGRectGetMidY(self.indicator.bounds), CGRectGetWidth(self.indicator.bounds), CGRectGetHeight(self.indicator.bounds));
}

+(UIImage*)imageWithImage: (UIImage*) sourceImage scaledToSize: (CGSize) size
{
    float oldWidth = sourceImage.size.width;
    float oldH = sourceImage.size.height;
    float scaleFactor = MIN(size.width / oldWidth,size.height/oldH);
    
    float newHeight = round(oldH * scaleFactor);
    float newWidth = round(oldWidth * scaleFactor);
    
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(newWidth, newHeight),NO,0);
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [self.backgroundColor setFill];
    UIRectFill(rect);
    
    if (self.isLoading)
    {
        [self indicatorDrawRect:rect];
        return;
    }
    if (self.firstFrame)
    {
        UIImage * newImage = [[self class]imageWithImage:self.firstFrame scaledToSize:rect.size];
        
        CGPoint offset = {CGRectGetMidX(rect)-newImage.size.width*0.5,CGRectGetMidY(rect)-newImage.size.height*0.5};
        
        [newImage drawAtPoint:offset];
    }
    
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
