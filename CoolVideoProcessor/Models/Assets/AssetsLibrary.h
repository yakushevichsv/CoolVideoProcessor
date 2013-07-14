//
//  AssetsLibrary.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/7/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^alCompletitionBlock)(NSError *error);
typedef void (^alVoidCompletitionBlock)(void);
@class AVMutableComposition;
@interface AssetsLibrary : NSObject

-(id)initWithLibraryChangedHandler:(alVoidCompletitionBlock)completitionBlock;
-(void)loadLibraryWithCompletitionBlock:(alVoidCompletitionBlock)completitionBlock;


@property (nonatomic,strong) NSMutableArray *videoAssetItems;
@property (nonatomic,strong) NSMutableArray *imageAssetItems;
@property (nonatomic,strong) alVoidCompletitionBlock completitionBlock;

+(void)exportComposition:(AVMutableComposition*)composition atPath:(NSString*)path competition:(alCompletitionBlock)competition;

+(void)exportComposition:(AVMutableComposition*)composition aURL:(NSURL*)url competition:(alCompletitionBlock)competition;

@end
