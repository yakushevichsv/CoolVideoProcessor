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
{
    BOOL _doneImage,_doneTitle,_doneDuration;
}
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

-(void)reset
{
    _token = nil;
    _doneDuration =_doneTitle=_doneTitle = FALSE;
}

-(void)setup
{
    [self reset];
    
    self.library =[ALAssetsLibrary new];
}

- (NSString *)loadTitleWithCompletitionHandler:(completitionBlock)completionHandler
{
    if (!_doneTitle && (_doneImage || _doneDuration))
    {
        completionHandler();
        _doneTitle = TRUE;
    }
    else
    [self performActionWithCompletitionBlock:completionHandler ptr:&_doneTitle];
    return self.title;
}

-(UIImage*)loadThumbnailWithCompletitionHandler:(completitionBlock)completionHandler
{
    if (!_doneImage && (_doneTitle || _doneDuration))
    {
        completionHandler();
        _doneImage = TRUE;
    }
    else
    [self performActionWithCompletitionBlock:completionHandler ptr:&_doneImage];
    
    return self.image;
}

-(NSTimeInterval)loadDurationWithCompletitionHandler:(completitionBlock)completionHandler
{
    if (!_doneDuration && (_doneImage || _doneTitle))
    {
        completionHandler();
        _doneDuration = TRUE;
    }
    else
    [self performActionWithCompletitionBlock:completionHandler ptr:&_doneDuration];
    return self.duration;
}

-(void)performActionWithCompletitionBlock:(completitionBlock)completionHandler ptr:(BOOL*)boolPtr
{
    dispatch_once(&_token, ^{
		// Load the title from AVMetadataCommonKeyTitle
		NSLog(@"Loading title...");
		
        [self.library assetForURL:self.url resultBlock:^(ALAsset *asset) {
            self.image = [[UIImage alloc]initWithCGImage:asset.aspectRatioThumbnail];
            
            self.title = asset.defaultRepresentation.filename;
            
            id durationObj =[asset valueForProperty:ALAssetPropertyDuration] ;
            
            self.duration = [durationObj doubleValue];
            *boolPtr = TRUE;
            completionHandler();
        } failureBlock:^(NSError *error) {
            NSLog(@"error %@",error);
            [self reset];
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

@end
