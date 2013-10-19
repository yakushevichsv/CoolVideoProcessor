//
//  AssetFiltration.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 10/13/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "FilterRepresentation.h"
#import "AssetItem.h"


@interface AssetFiltration : NSObject

@property (nonatomic,strong) AssetItem* asset;

- (void)addFilterRepresentation:(FilterRepresentation *)filter forTimeRange:(CMTimeRange)range;

-(FilterRepresentation *)filterAtIndex:(NSUInteger)index;
-(CMTimeRange)durationForFilterAtIndex:(NSUInteger)index;
-(void)useAssetDurationForFilterAtIndex:(NSUInteger)index;

@end
