//
//  FilterSettingsController.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/28/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "UIBaseViewController.h"

@class CIFilter;
@interface FilterSettingsController : UIBaseViewController
@property (nonatomic,strong) CIFilter * filter;
@property (nonatomic,strong) UIImage * originalImage;

@end
