//
//  MergeVideoView.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 6/10/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MergeVideoView : UIView
@property (nonatomic) BOOL tapped;
@property (nonatomic,strong) UIImage * firstFrame;
@property (nonatomic,strong) NSString * title;
@property (nonatomic) BOOL isLoading;
@property (nonatomic) BOOL bulkReDraw;
@end
