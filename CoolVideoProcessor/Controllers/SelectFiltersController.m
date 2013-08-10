//
//  SelectFiltersController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/23/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "SelectFiltersController.h"
#import "SelectFiltersCell.h"
#import "AssetItem.h"
#import "HeaderView.h"

@interface SelectFiltersController ()
@property (nonatomic,strong) CIContext * context;
@property (weak, nonatomic) IBOutlet UICollectionView *cvFilters;
@end

/*
 CORE_IMAGE_EXPORT NSString *kCICategoryDistortionEffect;
 CORE_IMAGE_EXPORT NSString *kCICategoryGeometryAdjustment;
 CORE_IMAGE_EXPORT NSString *kCICategoryCompositeOperation;
 CORE_IMAGE_EXPORT NSString *kCICategoryHalftoneEffect;
 CORE_IMAGE_EXPORT NSString *kCICategoryColorAdjustment;
 CORE_IMAGE_EXPORT NSString *kCICategoryColorEffect;
 CORE_IMAGE_EXPORT NSString *kCICategoryTransition;
 CORE_IMAGE_EXPORT NSString *kCICategoryTileEffect;
 CORE_IMAGE_EXPORT NSString *kCICategoryGenerator;
 CORE_IMAGE_EXPORT NSString *kCICategoryReduction __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_5_0);
 CORE_IMAGE_EXPORT NSString *kCICategoryGradient;
 CORE_IMAGE_EXPORT NSString *kCICategoryStylize;
 CORE_IMAGE_EXPORT NSString *kCICategorySharpen;
 CORE_IMAGE_EXPORT NSString *kCICategoryBlur;
 
 CORE_IMAGE_EXPORT NSString *kCICategoryVideo;
 CORE_IMAGE_EXPORT NSString *kCICategoryStillImage;
 CORE_IMAGE_EXPORT NSString *kCICategoryInterlaced;
 CORE_IMAGE_EXPORT NSString *kCICategoryNonSquarePixels;
 CORE_IMAGE_EXPORT NSString *kCICategoryHighDynamicRange;
 */

static NSDictionary * g_FilterMap;

static NSString * kCellIdentifier =@"selectFilterCell";
static NSString  * kSectionHeaderIdentifier=@"TitleHeader";
@implementation SelectFiltersController


+(void)initialize
{
    NSArray * names =@[kCICategoryDistortionEffect,
                       kCICategoryGeometryAdjustment,
                       kCICategoryCompositeOperation
                       ];
    
    NSArray * visibleText = @[
                              @"Distortion effect",
                              @"Geometry adjustment",
                              @"Composite Operation"
                              ];
    
    NSParameterAssert(visibleText.count == names.count);
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithCapacity:names.count];
    
    NSMutableSet * set = nil;
    
    for (NSUInteger i=0;i<visibleText.count;i++)
    {
        NSMutableArray * array =  [NSMutableArray arrayWithArray:[CIFilter filterNamesInCategory:names[i]]];
        NSLog(@"In category : %@. Array %@",array,names[i]);
        if (!set)
        {
            set =[NSMutableSet setWithArray:array];
        }
        else
        {
            NSMutableIndexSet * indexSet= [NSMutableIndexSet new];
            for (NSUInteger j=0;j<array.count;j++)
            {
                if (![set containsObject:array[i]])
                {
                    [set addObject:array[i]];
                }
                else
                {
                    [indexSet addIndex:j];
                }
            }
            [array removeObjectsAtIndexes:indexSet];
        }
        dic[visibleText[i]]=array;
    }
    g_FilterMap  = dic;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setup];
    }
    return self;
}

-(void)setup
{
    self.context = [CIContext contextWithOptions:nil];
}

#pragma mark - UICollectionViewDelegate & Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return g_FilterMap.allKeys.count;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSArray * array =[g_FilterMap valueForKey:g_FilterMap.allKeys[section]];
    return array.count;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (kind == UICollectionElementKindSectionHeader)
    {
        UICollectionReusableView * headerView =[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:(NSString*)kSectionHeaderIdentifier forIndexPath:indexPath];
        
      HeaderView* contentView = (HeaderView*)  [headerView viewWithTag:2];
        
        NSString * title;
        contentView.frame = headerView.frame;
       title = g_FilterMap.allKeys[indexPath.section];
        
        NSMutableAttributedString * mutableString =[[NSMutableAttributedString alloc]initWithString:title];
        
        [mutableString addAttribute:NSForegroundColorAttributeName
                              value:[UIColor blackColor] range:NSMakeRange(0, title.length)];
        
        
        contentView.headerLabel.attributedText = mutableString;
        
        return headerView;
    }
    else
        return nil;
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SelectFiltersCell * cell;
    if (!(cell = (SelectFiltersCell*)[collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath]))
    {
        cell = [SelectFiltersCell new];
    }
    NSString * title;
    
    title =[g_FilterMap valueForKey:g_FilterMap.allKeys[indexPath.section]][indexPath.row];
    
    NSMutableAttributedString * mutableString =[[NSMutableAttributedString alloc]initWithString:title];
    
    [mutableString addAttribute:NSForegroundColorAttributeName
                          value:[UIColor blackColor] range:NSMakeRange(0, title.length)];
    
    CIImage * image = [CIImage imageWithCGImage:self.item.image.CGImage];
    CIFilter * filter = [ CIFilter filterWithName:title];
    [filter setValue:image forKey:kCIInputImageKey];
    CIImage * result = [filter valueForKey:kCIOutputImageKey];
    CGImageRef cgImage =[self.context createCGImage:result fromRect:[result extent]];
    UIImage * resImage = [UIImage imageWithCGImage:cgImage];
    cell.imageView.image = resImage;
    cell.titleLabel.frame= cell.frame;
    cell.titleLabel.attributedText = mutableString;
    return cell;

}


@end
