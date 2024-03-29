//
//  MergingProcessorViewController.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/2/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIBaseViewController.h"

@interface MergingProcessorViewController : UIBaseViewController

@property (nonatomic,strong) NSMutableDictionary* dictionary;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UIProgressView *pvProgress;
@property (nonatomic,readonly) NSURL * mergedVideo;
@property (nonatomic,strong) NSArray *pureImages;
@end
