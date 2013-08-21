//
//  VideoProcessor.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 8/11/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * kVideoProcessorFilterAppliedNotification;

@class FilterInfo;
@interface VideoProcessor : NSObject

-(void)applyFilter:(FilterInfo*)filterInfo withCompletition:(void (^)(NSURL* url))completitionBlock;

@end
