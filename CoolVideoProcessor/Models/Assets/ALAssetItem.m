//
//  ALAssetItem.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/14/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetItem.h"

@interface ALAssetItem()

@property(nonatomic, readonly, unsafe_unretained) dispatch_once_t token;
@property (nonatomic,strong) ALAssetsLibrary *library;

@end

@implementation ALAssetItem

-(id)initWithURL:(NSURL *)url mediaType:(AssetItemMediaType)mediaType
{
    if (self = [super initWithURL:url type:AssetItemTypeAL mediaType:mediaType])
    {
        [self setup];
    }
    return self;
}

-(void)setup
{
    [self flush];
    
    self.library =[ALAssetsLibrary new];
}

- (ALAssetsLibrary *)library
{
    if (!_library)
    {
        _library =[ALAssetsLibrary new];

    }
    return _library;
}

- (NSString *)loadTitleWithCompletitionHandler:(completitionBlock)completionHandler
{
    [self performActionWithCompletitionBlock:completionHandler];
    return self.title;
}

-(UIImage*)loadThumbnailWithCompletitionHandler:(completitionBlock)completionHandler
{
    [self performActionWithCompletitionBlock:completionHandler];
    
    return self.image;
}

-(NSTimeInterval)loadDurationWithCompletitionHandler:(completitionBlock)completionHandler
{
    [self performActionWithCompletitionBlock:completionHandler];
    return self.duration;
}

-(void)performActionWithCompletitionBlock:(completitionBlock)completionHandler
{
    dispatch_once(&_token, ^{
		// Load the title from AVMetadataCommonKeyTitle
		NSLog(@"Loading Bulk of data...");
		
        [self.library assetForURL:self.url resultBlock:^(ALAsset *asset) {
            self.image = [[UIImage alloc]initWithCGImage:asset.aspectRatioThumbnail];
            
            self.title = asset.defaultRepresentation.filename;
            
            id durationObj =[asset valueForProperty:ALAssetPropertyDuration] ;
            
            self.duration = [durationObj doubleValue];
            self.done = TRUE;
            completionHandler();
            NSLog(@"Done Loading bulk of data ...");
        } failureBlock:^(NSError *error) {
            NSLog(@"error %@",error);
            [self flush];
        }];
    });
}


-(void)loadImageWithCompletitionHandler:(void (^)(UIImage*image))completitionBlock
{
    [self.library assetForURL:self.url resultBlock:^(ALAsset *asset) {
        UIImage * image =[UIImage imageWithCGImage:        asset.defaultRepresentation.fullResolutionImage scale:1.0 orientation:(UIImageOrientation)asset.defaultRepresentation.orientation];
        completitionBlock(image);
    } failureBlock:^(NSError *error) {
        completitionBlock(nil);
    }];
}

-(void)flush
{
    _token = nil;
    _library = nil;
    [super flush];
}


@end
