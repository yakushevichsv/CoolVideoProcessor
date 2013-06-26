//
//  MergeVideoViewCell.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 6/10/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "MergeVideoViewCell.h"

@implementation MergeVideoViewCell

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
