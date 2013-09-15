//
//  FileProcessor.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 9/14/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

@class AssetItem;

@interface ProcessingImageInfo : NSObject

@property (nonatomic) CMTime timeRange;
@property (nonatomic,strong) CIFilter *filter;
@property (nonatomic,strong) AssetItem *item;

@end


@interface FileProcessor : NSObject

- (void)applyFiltersToArray:(NSArray *)array withCompletition:(void (^)(NSURL* url))completitionBlock;

@end
