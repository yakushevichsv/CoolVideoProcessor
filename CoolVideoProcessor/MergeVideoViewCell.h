//
//  MergeVideoViewCell.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 6/10/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MergeVideoView.h"

@interface MergeVideoViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet MergeVideoView *MergeVideo;
@property (nonatomic) BOOL isLoading;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@end
