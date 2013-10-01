//
//  FilterSettingsBackImageCell.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 9/29/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FilterSettingsBackImageCell;

@protocol FilterSettingsBackImageCellDelegate <NSObject>

-(void)filterSettingsBackImageCell:(FilterSettingsBackImageCell *)cell didSelectImage:(UIImage *)image useTheSameImage:(BOOL)sameImage;

@end

@interface FilterSettingsBackImageCell : UITableViewCell

@property (weak,nonatomic) UIViewController<FilterSettingsBackImageCellDelegate> *delegate;
@property (weak,nonatomic) IBOutlet UILabel *parameterName;
@property (weak,nonatomic) IBOutlet UIButton *takePicture;

@end
