//
//  SelectFiltersController.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/23/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIBaseViewController.h"
@class AssetItem,SelectFiltersController;

@protocol SelectFiltersDelegate <NSObject>

-(void)selectFiltersController:(SelectFiltersController*)controller didSelectFiltersChain:(NSArray*)filters info:(NSDictionary*)filtersInfo;

@end

@interface SelectFiltersController : UIBaseViewController
@property (nonatomic,weak) id<SelectFiltersDelegate> delegate;
@property (nonatomic,strong) AssetItem* item;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end
