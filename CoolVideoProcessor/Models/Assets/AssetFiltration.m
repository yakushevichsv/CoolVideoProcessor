//
//  AssetFiltration.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 10/13/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "AssetFiltration.h"
#import "FilterRepresentation.h"
#import "AssetItem.h"

@interface AssetFiltration()
{
    NSMutableArray *_filterRepresentation;
    NSMutableArray *_timeRange;
    NSMutableArray *_assetTimeIndexes;
    CMTimeRange _assetTimeRange;
}
@end


@implementation AssetFiltration

-(id)init
{
    if (self = [super init])
    {
        _filterRepresentation = [NSMutableArray new];
        _timeRange = [NSMutableArray new];
    }
    return self;
}

- (void)addTimRange:(CMTimeRange)range
{
    CFDictionaryRef dicRef = CMTimeRangeCopyAsDictionary(range, NULL);
    
    [_timeRange addObject:(__bridge id)(dicRef)];
    
     CFRelease(dicRef);
}

- (void)insertTimeRange:(CMTimeRange)range atIndex:(NSUInteger)index
{
    CFDictionaryRef dicRef = CMTimeRangeCopyAsDictionary(range, NULL);
    
    [_timeRange insertObject:(__bridge id)(dicRef) atIndex:index];
    
    CFRelease(dicRef);
}

- (void)addFilterRepresentation:(FilterRepresentation *)filter forTimeRange:(CMTimeRange)range
{
    [_filterRepresentation addObject:filter];
    
    [self addTimRange:range];
}

-(FilterRepresentation *)filterAtIndex:(NSUInteger)index
{
    return index < _filterRepresentation.count ? _filterRepresentation[index] : nil;
}


-(CMTimeRange)durationForFilterAtIndex:(NSUInteger)index
{
    if (index < _timeRange.count)
    {
        NSDictionary *dict = (NSDictionary *)_timeRange[index];
        return CMTimeRangeMakeFromDictionary((__bridge CFDictionaryRef)(dict));
    }
    else
        return kCMTimeRangeInvalid;
}

- (void)setAsset:(AssetItem *)asset
{
    if (_asset!=asset && ![_asset.url isEqual:asset.url])
    {
        _asset = asset;
        _assetTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(self.asset.duration, 1));
        for (NSNumber * indexValue in _assetTimeIndexes)
        {
            NSUInteger index = [indexValue unsignedIntegerValue];
            
            if (index < _timeRange.count)
            {
                [self insertTimeRange:_assetTimeRange atIndex:index];
            }
            else
            {
                [self addTimRange:_assetTimeRange];
            }
        }
    }
}

-(void)useAssetDurationForFilterAtIndex:(NSUInteger)index
{
   if (index < _filterRepresentation.count)
   {
       if (!self.asset)
       {
           [_assetTimeIndexes addObject:@(index)];
       }
       else
       {
           if (index < _timeRange.count)
           {
               [self insertTimeRange:_assetTimeRange atIndex:index];
           }
           else
           {
               [self addTimRange:_assetTimeRange];
           }
       }
   }
}

@end
