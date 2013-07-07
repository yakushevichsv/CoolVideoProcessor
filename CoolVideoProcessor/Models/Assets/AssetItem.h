//
//  AssetItem.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/7/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^completitionBlock)(void);

@interface AssetItem : NSObject

-(id)initWithURL:(NSURL*)url;

- (NSString *)loadTitleWithCompletitionHandler:(completitionBlock)completionHandler;
- (UIImage *)loadThumbnailWithCompletitionHandler:(completitionBlock)completionHandler;

-(void)flush;

@property (nonatomic,strong) NSString * title;
@property (nonatomic,strong) NSURL * url;

@end
