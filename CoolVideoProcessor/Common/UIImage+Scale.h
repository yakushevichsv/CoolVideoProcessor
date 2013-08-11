//
//  UIImage+Scale.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 8/11/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Scale)

-(UIImage*)scaleToSize:(CGSize)size;
-(UIImage*)scaleToSizeWithAspectRatio:(CGSize)size;

@end
