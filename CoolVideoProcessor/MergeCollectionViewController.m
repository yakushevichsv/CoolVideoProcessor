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
#import "Constants.h"
#import "PositionViewController.h"
#import "AssetsLibrary.h"
#import "AssetItem.h"

#define NUMBER_OF_SECTIONS 2

@interface MergeCollectionViewController ()<UICollectionViewDataSource,UICollectionViewDelegate>

@property (nonatomic,strong) AssetsLibrary * library;
@end

@implementation MergeCollectionViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self =[super initWithCoder:aDecoder])
    {
        self.library = [[AssetsLibrary alloc]initWithLibraryChangedHandler:^{
            [self.files reloadData];
        }];
    }
    return self;
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
        {
            [self.library loadLibraryWithCompletitionBlock:^{
                   [self.files reloadData];
               }];
        }
    }
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
        array = self.library.videoAssetItems;
    }
    else if (section == IMAGES_SECTION)
    {
        array = self.library.imageAssetItems;
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
        if (MIN(VIDEO_SECTION,IMAGES_SECTION) ==indexPath.section && !done)
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
        else if (indexPath.section == IMAGES_SECTION)
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
    
    if (!cell.MergeVideo.title && !cell.MergeVideo.firstFrame)
    {
        cell.isLoading = TRUE;
        cell.MergeVideo.bulkReDraw = TRUE;
        cell.MergeVideo.tapped = FALSE;
    }
    
    AssetItem * item;
    
    if (indexPath.section == VIDEO_SECTION)
    {
        item = (AssetItem *)self.library.videoAssetItems[indexPath.row];
    }
    else if (indexPath.section == IMAGES_SECTION)
    {
        item = (AssetItem *)self.library.imageAssetItems[indexPath.row];
    }
        
    cell.MergeVideo.title =  [item loadTitleWithCompletitionHandler:^{
        //[collectionView reloadItemsAtIndexPaths:@[indexPath]];
        MergeVideoViewCell* retCell = (MergeVideoViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
        retCell.MergeVideo.title = item.title;
        retCell.MergeVideo.firstFrame = [item loadThumbnailWithCompletitionHandler:^{
            MergeVideoViewCell* retCell2 = (MergeVideoViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
            retCell2.MergeVideo.firstFrame = item.image;
            retCell2.MergeVideo.bulkReDraw = FALSE;
            retCell2.isLoading  = FALSE;
            [retCell2 setNeedsDisplay];
        }];
    }];
    
    
    return cell;
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MergeTimeLineSegue"])
    {
        NSArray * arr = [self.files indexPathsForSelectedItems];
        NSLog(@"Count %d",arr.count);
        
        NSMutableArray * resArray = [NSMutableArray arrayWithCapacity:arr.count];
        
        for (NSIndexPath * path in arr)
        {
            if (path.section == VIDEO_SECTION)
                [resArray addObject:self.library.videoAssetItems[path.row]];
            else if (path.section == IMAGES_SECTION)
                    [resArray addObject:self.library.imageAssetItems[path.row]];
        }
        
        
        PositionViewController * controller =
        (PositionViewController *)segue.destinationViewController;
        controller.items = resArray;
    }
}
@end
