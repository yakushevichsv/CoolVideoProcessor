//
//  FilterSettingsVectorCell.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 8/25/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FilterSettingsVectorCell;

@protocol FilterSettingsVectorCellDelegate <NSObject>

-(void)cell:(FilterSettingsVectorCell *)cell withVector:(CIVector*)vector;

-(void)cell:(FilterSettingsVectorCell *)cell didActivateTextField:(UITextField*)field;
-(void)cell:(FilterSettingsVectorCell *)cell willDeactivateTextField:(UITextField*)field;
@end

@interface FilterSettingsVectorCell : UITableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier cellTitles:(NSArray *)cellTitles;

@property (nonatomic,weak) id<FilterSettingsVectorCellDelegate> delegate;
@property (nonatomic,strong) NSArray *cellTitles;

-(void)setCellValues:(CIVector*)cellValues;
-(CIVector*)getValues;

@end
