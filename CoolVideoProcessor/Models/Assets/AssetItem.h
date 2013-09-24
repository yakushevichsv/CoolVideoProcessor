//
//  AssetItem.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/7/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    AssetItemTypeNone = 0x00,
    AssetItemTypeAV = 0x01,
    AssetItemTypeAL = 0x02
}AssetItemType;

typedef  enum {
    AssetItemMediaTypeNone = 0x00,
    AssetItemMediaTypeVideo = 0x01,
    AssetItemMediaTypeImage = 0x02
}AssetItemMediaType;

typedef void (^completitionBlock)(void);

@interface AssetItem : NSObject

-(id)initWithURL:(NSURL*)url type:(AssetItemType)type mediaType:(AssetItemMediaType)mediaType;

- (NSString *)loadTitleWithCompletitionHandler:(completitionBlock)completionHandler;
- (UIImage *)loadThumbnailWithCompletitionHandler:(completitionBlock)completionHandler;

-(NSTimeInterval)loadDurationWithCompletitionHandler:(completitionBlock)completionHandler;

-(void)flush;

@property (nonatomic,strong,readonly) NSURL *url;
@property (nonatomic) AssetItemType type;
@property (nonatomic) AssetItemMediaType mediaType;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic,strong) NSString *title;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic) BOOL done;

@end
