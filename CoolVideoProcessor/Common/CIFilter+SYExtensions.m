//
//  CIFilter+SYExtensions.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 10/5/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "CIFilter+SYExtensions.h"

@interface CIFilter()

@property (nonatomic,strong) NSMutableArray *paramArray;
@end

@implementation CIFilter (SYExtensions)

- (NSArray *)nameOfParametersForInputImage
{
    return [NSArray arrayWithArray:self.paramArray];
}

- (void)addImageParameter:(NSString*)parameter
{
    if (!self.paramArray)
        self.paramArray = [NSMutableArray array];
    
    [self.paramArray addObject:parameter];
}

@end
