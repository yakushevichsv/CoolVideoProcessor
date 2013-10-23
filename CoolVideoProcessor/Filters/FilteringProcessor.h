//
//  FilteringProcessor.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 10/13/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AssetFiltration.h"

typedef void (^filteringProcessorCompletitionBlock)(void);

@class FilteringProcessor;

@protocol FilterProcessorDelegate <NSObject>

- (void)filteringProcessor:(FilteringProcessor *)processor willStartApplyingFiltration:(AssetFiltration *)filter withIndex:(NSUInteger)index;

- (void)filteringProcessor:(FilteringProcessor *)processor didApplyingFiltration:(AssetFiltration *)filter withIndex:(NSUInteger)index;

@end

@interface FilteringProcessor : NSObject

@property (nonatomic, strong) AssetFiltration *filtration;

+ (void)correctFilter:(CIFilter **)filterPtr withInputImage:(CIImage *)image;

- (void)processAssetWithTimeRange:(CMTimeRange)range completitionBlock:(filteringProcessorCompletitionBlock)completitionBlock;

- (void)processAssetWithCompletitionBlock:(filteringProcessorCompletitionBlock)completitionBlock;

@end
