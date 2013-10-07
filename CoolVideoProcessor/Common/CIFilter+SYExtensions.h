//
//  CIFilter+SYExtensions.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 10/5/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <CoreImage/CoreImage.h>

@interface CIFilter (SYExtensions)

@property (nonatomic,strong,readonly) NSArray * nameOfParametersForInputImage;

- (void)addImageParameter:(NSString*)parameter;

@end
