//
//  MergeCollectionViewController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 6/10/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "MergeCollectionViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "MergeVideoViewCell.h"
#import "HeaderView.h"
#import <AVFoundation/AVFoundation.h>

#define NUMBER_OF_SECTIONS 2
#define IMAGE_SECTION 0
#define VIDEO_SECTION NUMBER_OF_SECTIONS-1
#define MAX_SIMULTANIOUS_OP 4


@interface CustomAssetInfo : NSObject
@property (nonatomic,strong) NSString * fileName;
@property (nonatomic,strong) NSURL * url;
@end

@implementation CustomAssetInfo
-(void)dealloc
{
    self.fileName =nil;
    self.url =nil;
}

@end

@interface MergeCollectionViewController ()<UICollectionViewDataSource,UICollectionViewDelegate>

@property (nonatomic,strong) NSMutableArray * videoFiles;
@property (nonatomic,strong) NSMutableArray * imageFiles;
@property (nonatomic,strong) NSOperationQueue * queue;
@end

@implementation MergeCollectionViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self =[super initWithCoder:aDecoder])
    {
        [self setup];
        
    }
    return self;
}

-(void)setup
{
    self.queue = [NSOperationQueue new];
    _imageFiles = [NSMutableArray array];
    _videoFiles = [NSMutableArray array];
}

-(void)setFiles:(UICollectionView *)files
{
    if (![_files isEqual:files])
    {
        files.dataSource = self;
        files.delegate = self;
        files.allowsMultipleSelection = TRUE;
        _files =files;
        if (files)
            [self.queue addOperationWithBlock:^{
                [self prepareFiles];
            }];
    }
}

-(void)reloadSection:(NSUInteger)section
{
    NSIndexSet * set =[[NSIndexSet alloc]initWithIndex:section];
    if (![NSThread isMainThread])
    {
        [[NSOperationQueue mainQueue]addOperationWithBlock:^{
            [self.files reloadSections:set];
        }];
    }
    else
        [self.files reloadSections:set];
}

-(void)setVideoFiles:(NSMutableArray *)videoFiles
{
    if (![videoFiles isEqualToArray:_videoFiles])
    {
        _videoFiles = videoFiles;
        
        if (videoFiles.count)
        {
            [self reloadSection:VIDEO_SECTION];
        }
    }
}

-(void)setImageFiles:(NSMutableArray *)imageFiles
{
    if (![_imageFiles isEqualToArray:imageFiles])
    {
        _imageFiles  = imageFiles;
         if (imageFiles.count) [self reloadSection:IMAGE_SECTION];
    }
}


-(void)prepareFiles
{
    [self prepareVideoFiles];
    [self prepareImageFiles];
}

-(void) prepareVideoFiles
{
    [self prepareFiles:[ALAssetsFilter allVideos] assetsGroupType:ALAssetsGroupAll isVideo:TRUE];
}

-(void) prepareImageFiles
{
    [self prepareFiles:[ALAssetsFilter allPhotos] assetsGroupType:ALAssetsGroupSavedPhotos isVideo:FALSE];
}


-(void)prepareFiles:(ALAssetsFilter*)filter assetsGroupType:(ALAssetsGroupType)type isVideo:(BOOL)video
{
    ALAssetsLibrary * libray = [ALAssetsLibrary  new];
    [libray enumerateGroupsWithTypes:type usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        __block NSMutableArray * resArray =[NSMutableArray array];
        
        [group setAssetsFilter:filter];
        
        
        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if (result)
            {
                ALAssetRepresentation * representation = [result defaultRepresentation];
                
                CustomAssetInfo * info =[CustomAssetInfo new];
                
                info.url =representation.url;
                info.fileName = representation.filename;
                
                [resArray addObject:info];
            }
            else
            {
                if (video)
                {
                    self.videoFiles = resArray;
                }
                else
                    self.imageFiles = resArray;
            }
        }];
        
    } failureBlock:^(NSError *error) {
        NSLog(@"Error %@ ",error);
    }];
}

#pragma mark - UICollectionViewDataSource

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
   MergeVideoViewCell * view = (MergeVideoViewCell*) [collectionView cellForItemAtIndexPath:indexPath];
    view.MergeVideo.tapped = TRUE;
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MergeVideoViewCell * view = (MergeVideoViewCell*) [collectionView cellForItemAtIndexPath:indexPath];
    
    view.MergeVideo.tapped = FALSE;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
   return [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    return [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:kind withIndexPath:indexPath];
}
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if ([self.files isEqual:collectionView])
    {
        return NUMBER_OF_SECTIONS;
    }
    return 0;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSArray * array;
    if (section == VIDEO_SECTION)
    {
        array = self.videoFiles;
    }
    else if (section == IMAGE_SECTION)
    {
        array = self.imageFiles;
    }
    else
    {
        array = nil;
    }
    return array.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    static BOOL done = TRUE;
    if (kind == UICollectionElementKindSectionHeader)
    {
        static NSString * headerCellName = @"TitleHeader";
        if (MIN(VIDEO_SECTION,IMAGE_SECTION) ==indexPath.section && !done)
        {
            
            [collectionView registerClass:[HeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerCellName];
            
            done = TRUE;
        }
        
        HeaderView *headerView = (HeaderView*)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerCellName forIndexPath:indexPath];
        NSString * title;
        if (indexPath.section == VIDEO_SECTION)
        {
            title = @"Videos";
        }
        else if (indexPath.section == IMAGE_SECTION)
        {
            title = @"Images";
        }
        NSMutableAttributedString * mutableString =[[NSMutableAttributedString alloc]initWithString:title];
        
        [mutableString addAttribute:NSForegroundColorAttributeName
                              value:[UIColor blackColor] range:NSMakeRange(0, title.length)];
        

        headerView.headerLabel.attributedText = mutableString;
        
        return headerView;
    }
    else
        return nil;
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString * cellName = @"MergeCell";
    MergeVideoViewCell * cell;
    if (!(cell = (MergeVideoViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:cellName forIndexPath:indexPath]))
    {
        cell = [MergeVideoViewCell new];
    }
    
    cell.isLoading = TRUE;
    cell.MergeVideo.bulkReDraw = TRUE;
    
    cell.MergeVideo.tapped = FALSE;
    
    if (self.queue.operationCount > MAX_SIMULTANIOUS_OP)
    {
        [self.queue waitUntilAllOperationsAreFinished];
    }
    
    //[self.queue addOperationWithBlock:^{
    if (indexPath.section == VIDEO_SECTION)
    {
        [self fillVideoCell:cell atIndexPath:indexPath];
    }
    else if (indexPath.section == IMAGE_SECTION)
    {
        [self fillImageCell:cell atIndexPath:indexPath];
    }
        
    //}];
    
    return cell;
}

-(void)fillVideoCell:(MergeVideoViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    
    CustomAssetInfo* info =
    (CustomAssetInfo*)self.videoFiles[indexPath.row];
    if (info.fileName.length)
    {
        cell.MergeVideo.title = info.fileName;
    }
    
    
    [self establishFirstFrameForCell:@[cell,info]];
    
}

-(void)fillImageCell:(MergeVideoViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    
    CustomAssetInfo* info =
    (CustomAssetInfo*)self.imageFiles[indexPath.row];
    if (info.fileName.length)
    {
        cell.MergeVideo.title = info.fileName;
    }
    
    [self establishFirstImageForCell:@[cell,info]];
}

-(void)establishFirstImageForCell:(NSArray*)array
{
    MergeVideoViewCell* cell = (MergeVideoViewCell*)array[0];
    CustomAssetInfo * info = (CustomAssetInfo *)array.lastObject;
    NSURL* url = info.url;
    
    ALAssetsLibrary * library = [ALAssetsLibrary new];
    [library assetForURL:url resultBlock:^(ALAsset *asset) {
      UIImage*  image = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
                if (image ) [self establishCell:cell image:image title:info.fileName];
    } failureBlock:nil];


}


-(void)establishFirstFrameForCell:(NSArray*)array
{
    MergeVideoViewCell* cell = (MergeVideoViewCell*)array[0];
    CustomAssetInfo * info = (CustomAssetInfo *)array.lastObject;
    NSURL* url = info.url;
    
   /* AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
    AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    UIImage* image = [UIImage imageWithCGImage:[imageGenerator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:nil error:nil]];
    
    
    [self establishCell:cell image:image  title:info.fileName];*/
    
    ALAssetsLibrary * library = [ALAssetsLibrary new];
    [library assetForURL:url resultBlock:^(ALAsset *asset) {
        UIImage*  image = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
        if (image ) [self establishCell:cell image:image title:info.fileName];
    } failureBlock:nil];
    

}

-(void)establishCell:(MergeVideoViewCell*)cell image:(UIImage*)image title:(NSString*)fileName
{
    [[NSOperationQueue mainQueue]addOperationWithBlock:^{
        cell.MergeVideo.title = fileName;
        cell.MergeVideo.firstFrame = image;
        cell.MergeVideo.bulkReDraw = FALSE;
        cell.isLoading  = FALSE;
    }];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MergeTimeLineSegue"])
    {
            NSArray * arr = [self.files indexPathsForSelectedItems];
            NSLog(@"Count %d",arr.count);
            
            for (NSIndexPath * path in arr)
            {
                
            }
    }
}
@end
