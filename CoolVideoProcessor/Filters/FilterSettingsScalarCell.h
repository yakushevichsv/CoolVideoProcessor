//
//  FilterSettingsScalarCell.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/28/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FilterSettingsScalarCell;
@protocol FilterSettingsScalarCellDelegate <NSObject>

-(void)cell:(FilterSettingsScalarCell*)cell didChangeNumber:(NSNumber*)number;

@end

@interface FilterSettingsScalarCell : UITableViewCell

@property (nonatomic,weak) IBOutlet UISlider * slider;
@property (nonatomic,weak) id<FilterSettingsScalarCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *cellTitle;

@end
