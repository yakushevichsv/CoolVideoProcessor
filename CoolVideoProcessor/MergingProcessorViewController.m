//
//  MergingProcessorViewController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/2/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "MergingProcessorViewController.h"

@interface MergingProcessorViewController ()
@property (nonatomic,strong) ALAssetsLibrary * library;
@property (nonatomic,strong) NSOperationQueue * queue;
@property (nonatomic,strong) NSURL * mergedVideo;
@end

@implementation MergingProcessorViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setup];
    }
    return self;
}

+(NSURL*)pathForResultVideo
{
   return [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"mov"]]];
}

-(void)setup
{
    self.library = [ALAssetsLibrary new];
    self.queue = [NSOperationQueue new];
    self.mergedVideo = [[self class]pathForResultVideo];
}

-(NSTimeInterval)startTime:(id)key
{
   return (NSTimeInterval)[[self.dictionary[key] objectAtIndex:0]doubleValue];
}

-(void)setDictionary:(NSMutableDictionary *)dictionary
{
    if (![dictionary isEqualToDictionary:_dictionary])
    {
        _dictionary = dictionary;
        if (dictionary)
            [self processDictionary];
    }
}

-(void)processDictionary
{
    [self.queue addOperationWithBlock:^{
        NSArray * sortedKeys = [self.dictionary.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSTimeInterval start1 =[self startTime:obj1];
            NSTimeInterval start2 =[self startTime:obj2];
            if (start1<start2)
            {
                return NSOrderedAscending;
            }
            else if (start1>start2)
            {
                return NSOrderedDescending;
            }
            else
            {
                return NSOrderedSame;
            }
        }];
        NSMutableDictionary * newDic =[NSMutableDictionary dictionaryWithCapacity:sortedKeys.count];
        for (id key in sortedKeys)
        {
            [newDic setObject:self.dictionary[key] forKey:key];
        }
        self.dictionary =nil;
        _dictionary = newDic;
        
        [self executeTask];
    }];
}


-(void)executeTask
{
    AVMutableComposition * composition = [AVMutableComposition composition];
    //AVAssetReaderOutput
    for (id key in self.dictionary)
    {
        AVURLAsset * asset = [[AVURLAsset alloc]initWithURL:key options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)}];
        AVAssetReader * reader =[AVAssetReader assetReaderWithAsset:asset error:nil];
        if (reader.status !=AVAssetReaderStatusFailed)
        {
            NSArray * valueObj = self.dictionary[key];
            NSTimeInterval startTime =(NSTimeInterval)[valueObj[1] doubleValue];
            NSTimeInterval durationTime =(NSTimeInterval)[valueObj.lastObject doubleValue];
            CMTime start = CMTimeMakeWithSeconds(startTime, 1);
            CMTime duration = CMTimeMakeWithSeconds(durationTime, 1);
            reader.timeRange = CMTimeRangeMake(start, duration);
            
        }
    }
}

@end
