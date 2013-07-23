//
//  SelectFiltersController.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/23/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AssetItem,SelectFiltersController;

@protocol SelectFiltersDelegate <NSObject>

-(void)selectFiltersController:(SelectFiltersController*)controller didSelectFiltersChain:(NSArray*)filters info:(NSDictionary*)filtersInfo;

@end

@interface SelectFiltersController : UIViewController
@property (nonatomic,weak) id<SelectFiltersDelegate> delegate;
@property (nonatomic,strong) AssetItem* item;

@end
