//
//  MergeVideoViewCell.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 6/10/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "MergeVideoViewCell.h"

@implementation MergeVideoViewCell

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
    CGRect destRect = CGRectMake(CGRectGetMidX(self.bounds)-CGRectGetMidX(self.indicator.bounds), CGRectGetMidY(self.bounds)-CGRectGetMidY(self.indicator.bounds), CGRectGetWidth(self.indicator.bounds), CGRectGetHeight(self.indicator.bounds));
    
    self.indicator.frame =destRect;
}

-(void)setIsLoading:(BOOL)isLoading
{
    if (_isLoading!=isLoading)
    {
        _isLoading = isLoading;
        
        self.indicator.hidden = !isLoading;
        if (isLoading)
        {
            self.MergeVideo.firstFrame = nil;
            self.MergeVideo.title = nil;
            //self.firstFrame = nil;
            //self.title = nil;
            self.MergeVideo.hidden = TRUE;
            self.indicator.hidden = FALSE;
            [self.indicator startAnimating];
        }
        else
        {
            [self.indicator stopAnimating];
                        self.indicator.hidden = TRUE;
                        self.MergeVideo.hidden = FALSE;
            [self.MergeVideo setNeedsDisplay];
        }
    }
}



@end
