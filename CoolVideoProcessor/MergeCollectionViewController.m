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
#import "External/FWTPopoverView/FWTPopoverView.h"

#define NUMBER_OF_SECTIONS 2

@interface MergeCollectionViewController ()<UICollectionViewDataSource,UICollectionViewDelegate>

@property (nonatomic,strong) NSMutableDictionary * activeCellsDic;
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

#pragma mark - FWTPopoverView

- (FWTPopoverView*)constructViewFromCell:(MergeVideoViewCell *)cell
{
    FWTPopoverView *popoverView = [FWTPopoverView new];
    
    UIImageView * imageView = [[UIImageView alloc]initWithImage:cell.MergeVideo.firstFrame];
    const CGFloat offset = 20.0;
    const CGFloat margin = 10.0;
    
    CGPoint offsetPoint = CGPointMake(offset, offset);
    imageView.frame = (CGRect){.origin = offsetPoint,.size=imageView.bounds.size};
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    CGFloat xStartPos = CGRectGetMaxX(imageView.frame)+margin;
    UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    CGSize size = CGSizeMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    
    CGSize titleSize = [cell.MergeVideo.title sizeWithFont:font constrainedToSize:size lineBreakMode:NSLineBreakByWordWrapping];
    
    titleSize.height +=2*margin;
    CGFloat yStartPos = CGRectGetMidY(imageView.frame);
    
    UITextView * textView = [[UITextView alloc]initWithFrame:(CGRect){.origin=CGPointMake(xStartPos, yStartPos),.size = titleSize}];
    textView.contentOffset = CGPointMake(margin, 0);
    textView.editable  = FALSE;
    textView.text = cell.MergeVideo.title;
    textView.textColor = [UIColor whiteColor];
    textView.backgroundColor = [UIColor clearColor];
    
    yStartPos = CGRectGetMaxY(textView.frame)+margin;
    xStartPos = CGRectGetMinX(imageView.frame);
    
    
    UITextView * durationView = [[UITextView alloc]initWithFrame:(CGRect){.origin=CGPointMake(xStartPos, yStartPos),.size = titleSize}];
    durationView.contentOffset = CGPointMake(margin, 0);
    durationView.editable  = FALSE;
    AssetItem *item;
    
    NSIndexPath *indexPath = [self.files indexPathForCell:cell];
    
    if (indexPath.section == VIDEO_SECTION)
    {
        item = (AssetItem *)self.library.videoAssetItems[indexPath.row];
    }
    else if (indexPath.section == IMAGES_SECTION)
    {
        item = (AssetItem *)self.library.imageAssetItems[indexPath.row];
    }
    
    double duration =  [item loadDurationWithCompletitionHandler:^{}];
    NSParameterAssert(duration == 0 && indexPath.section == IMAGES_SECTION || indexPath.section == VIDEO_SECTION);
    durationView.textColor = [UIColor whiteColor];
    durationView.text = [PositionViewController formatDuration:duration];
    durationView.backgroundColor = [UIColor clearColor];

    UIButton * button1 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button1.bounds = CGRectMake(0, 0, 60, 20);
    [button1 setTitle:@"Select" forState:UIControlStateNormal];//.text =@"Select";
    button1.tag = 0;
    UIEdgeInsets insets;
    insets.left = 5;
    insets.right = 5;
    insets.bottom = 5;
    insets.top = 5;
    button1.titleEdgeInsets =insets;
    button1.center = CGPointMake(CGRectGetMinX(imageView.frame) +CGRectGetMidX(button1.bounds), CGRectGetMaxY(durationView.frame)+margin*2);
    [button1 addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
   
    NSLog(@"Frame %@",NSStringFromCGRect(button1.frame));
    
    UIButton * button2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button2.bounds = CGRectMake(0, 0, 60, 20);
    button2.tag = 1;
    [button2 setTitle:@"Cancel" forState:UIControlStateNormal];
    button2.center = CGPointMake(CGRectGetMaxX(button1.bounds)*2+margin, button1.center.y);
    [button2 addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    NSLog(@"Frame %@",NSStringFromCGRect(button2.frame));

    
    CGFloat maxX =  MAX(CGRectGetMaxX(textView.frame),CGRectGetMaxX(durationView.frame)) + offset;
    CGFloat maxY = CGRectGetMaxY(button1.frame) + offset;
    popoverView.contentSize = CGSizeMake(maxX, maxY);

    [popoverView.contentView addSubview:durationView];
    [popoverView.contentView addSubview:textView];
    [popoverView.contentView addSubview:imageView];
    [popoverView.contentView addSubview:button1];
    [popoverView.contentView addSubview:button2];
    
    return popoverView;
}

-(FWTPopoverArrowDirection)getDirectionFromRect:(CGRect)rect size:(CGSize)size
{
    const CGFloat x = CGRectGetMinX(rect);
    const CGFloat y = CGRectGetMinY(rect);
    
    CGRect newRect = CGRectMake(x- size.width*0.5, y, size.width, size.height);
    if (CGRectContainsRect(self.view.bounds, newRect))
        return FWTPopoverArrowDirectionDown;
    
    return FWTPopoverArrowDirectionUp;
}

-(void)buttonPressed:(UIButton*)sender
{
    FWTPopoverView * popoverView = (FWTPopoverView*) sender.superview.superview;
    id key = [NSString stringWithFormat:@"%p",popoverView ];
    BOOL dismiss = FALSE;
    MergeVideoViewCell *mergedCell =
    self.activeCellsDic[key];
    NSParameterAssert(mergedCell);
    
    if (sender.tag == 0)
    {
        mergedCell.MergeVideo.tapped = TRUE;
        dismiss = TRUE;
    }
    else if (sender.tag == 1)
    {
        NSIndexPath * indexPath = [self.files indexPathForCell:mergedCell];
        [self.files deselectItemAtIndexPath:indexPath animated:NO];
        dismiss = TRUE;
    }
    
    if (dismiss)
    {
        [popoverView dismissPopoverAnimated:FALSE];
    }
   
    [self.activeCellsDic removeObjectForKey:key];
    if (!self.activeCellsDic.count)
        self.activeCellsDic = nil;
}

#pragma mark - UICollectionViewDataSource

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
   MergeVideoViewCell * view = (MergeVideoViewCell*) [collectionView cellForItemAtIndexPath:indexPath];
   if (!view.MergeVideo.tapped)
   {
       FWTPopoverView *popoverView = [self constructViewFromCell:view];
       
       if (!self.activeCellsDic.count)
           self.activeCellsDic =[NSMutableDictionary dictionary];
       
       id key =[NSString stringWithFormat:@"%p",popoverView ];
       self.activeCellsDic[key] = view;
       
       CGRect rect =[collectionView convertRect:view.bounds fromView:view];
       collectionView.contentOffset = CGPointMake(0, CGRectGetMinY(view.frame));
       [popoverView presentFromRect:rect
                             inView:collectionView
            permittedArrowDirection:[self getDirectionFromRect:rect size:popoverView.contentSize]
                           animated:YES];
   }
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
        return nil;
}

- (AssetItem *)itemAtIndexPath:(NSIndexPath *)indexPath
{
    AssetItem * item = nil;
    
    if (indexPath.section == VIDEO_SECTION)
    {
        item = (AssetItem *)self.library.videoAssetItems[indexPath.row];
    }
    else if (indexPath.section == IMAGES_SECTION)
    {
        item = (AssetItem *)self.library.imageAssetItems[indexPath.row];
    }
    return item;
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString * cellName = @"MergeCell";
    MergeVideoViewCell * cell = (MergeVideoViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:cellName forIndexPath:indexPath];
    
    
    AssetItem * item = [self itemAtIndexPath:indexPath];
    
    if (!item.done)
    {
        cell.isLoading = TRUE;
        cell.MergeVideo.bulkReDraw = TRUE;
        cell.MergeVideo.tapped = FALSE;
    }
    
        cell.MergeVideo.title =  [item loadTitleWithCompletitionHandler:^{
            //MergeVideoViewCell * retCell =.MergeVideo.title = item.title;
            MergeVideoViewCell * retCell = (MergeVideoViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
            retCell.MergeVideo.title = item.title;
            
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0), ^{
                UIImage * image = [item loadThumbnailWithCompletitionHandler:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    MergeVideoViewCell * retCell = (MergeVideoViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
                    retCell.MergeVideo.firstFrame = image;
                    if (item.done)
                    {
                        retCell.isLoading = FALSE;
                        retCell.MergeVideo.bulkReDraw = FALSE;
                        
                    }
                });
            });
            
        }];
        
               
    
    
    if (item.done)
    {
        cell.MergeVideo.title = item.title;
        cell.MergeVideo.firstFrame = item.image;
        cell.isLoading = FALSE;
        cell.MergeVideo.bulkReDraw = FALSE;
  
    }
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    NSArray * array = [self.files indexPathsForVisibleItems];
    
    //NSMutableArray * videoCells = [NSMutableArray array];
    //NSMutableArray * imageCells = [NSMutableArray array];
    
    __block NSInteger minVIndex,minIIndex,maxVIndex,maxIIndex;
    
    minVIndex = NSIntegerMax;
    minIIndex = NSIntegerMax;
    maxVIndex = NSIntegerMin;
    maxIIndex = NSIntegerMin;
    
    [array enumerateObjectsUsingBlock:^(NSIndexPath* indexPath, NSUInteger idx, BOOL *stop) {
        const NSInteger rowPath = indexPath.row;
        
        if (indexPath.section == VIDEO_SECTION)
        {
            if (minVIndex > rowPath)
            {
                minVIndex = rowPath;
            }
            
            if (maxVIndex < rowPath)
            {
                maxVIndex = rowPath;
            }
        }
        else if (indexPath.section == IMAGES_SECTION)
        {
            if (minIIndex > rowPath)
            {
                minIIndex = rowPath;
            }
            
            if (maxIIndex < rowPath)
            {
                maxIIndex = rowPath;
            }

        }
    }];
    
    if (minVIndex <= maxVIndex)
    {
        for (NSUInteger i=0 ; i <minVIndex;i++)
        {
            [self.library.videoAssetItems[i] flush];
        }
    
        for (NSUInteger i=maxVIndex+1 ; i <self.library.videoAssetItems.count;i++)
        {
            [self.library.videoAssetItems[i] flush];
        }
    }
    
    
    if (minIIndex <= maxIIndex)
    {

        for (NSUInteger i=0 ; i <minIIndex;i++)
        {
            [self.library.imageAssetItems[i] flush];
        }
    
        for (NSUInteger i=maxIIndex+1 ; i <self.library.imageAssetItems.count;i++)
        {
            [self.library.imageAssetItems[i] flush];
        }
    }
}

@end
