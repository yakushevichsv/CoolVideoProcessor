//
//  AssetsLibrary.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/7/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^alCompletitionBlock)(NSError *error);

@class AVMutableComposition;
@interface AssetsLibrary : NSObject

+(void)exportComposition:(AVMutableComposition*)composition atPath:(NSString*)path competition:(alCompletitionBlock)competition;

+(void)exportComposition:(AVMutableComposition*)composition aURL:(NSURL*)url competition:(alCompletitionBlock)competition;

@end
