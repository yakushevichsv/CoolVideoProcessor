//
//  FilterSettingsScalarCell.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/28/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "FilterSettingsScalarCell.h"

@interface FilterSettingsScalarCell()
{
    CGFloat _oldValue;
}

@end

@implementation FilterSettingsScalarCell

- (IBAction)valueChanged:(UISlider *)sender
{
    if (sender.value!=_oldValue)
    {
        [self.delegate cell:self didChangeNumber:@(sender.value)];
         _oldValue=sender.value;
    }
}

@end
