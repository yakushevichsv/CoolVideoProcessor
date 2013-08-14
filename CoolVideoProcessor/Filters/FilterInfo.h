//
//  FilterInfo.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 8/11/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@class AssetItem,CIFilter;

@interface FilterInfo : NSObject
@property (nonatomic,strong) AssetItem* item;
@property (nonatomic,strong) CIFilter* filter;
@property (nonatomic) CMTimeRange range;
@end
