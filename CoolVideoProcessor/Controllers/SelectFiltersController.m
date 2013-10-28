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
#import "FilterSettingsController.h"
#import "FilteringProcessor.h"

@interface SelectFiltersController ()
@property (nonatomic,strong) CIContext * context;
@end

static NSDictionary * g_FilterMap;

static NSString *kCellIdentifier           = @"selectFilterCell";
static NSString *kSectionHeaderIdentifier  = @"TitleHeader";
static NSString *kSectionFooterIdentifier  = @"FooterHeader";
@implementation SelectFiltersController


+(void)initialize
{
    NSArray * names =@[kCICategoryDistortionEffect,
                       kCICategoryGeometryAdjustment,
                       kCICategoryCompositeOperation,
                       kCICategoryBlur,
                       kCICategorySharpen
                       ];
    
    NSArray * visibleText = @[
                              @"Distortion effect",
                              @"Geometry adjustment",
                              @"Composite Operation",
                              @"Blur",
                              @"Sharpen"
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
                if (![set containsObject:array[j]])
                {
                    [set addObject:array[j]];
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
        UICollectionReusableView * headerView =[collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:(NSString*)kSectionHeaderIdentifier forIndexPath:indexPath];
        
      HeaderView* contentView = (HeaderView*)headerView ;
        
        NSString * title;
       title = g_FilterMap.allKeys[indexPath.section];
        
        NSMutableAttributedString * mutableString =[[NSMutableAttributedString alloc]initWithString:title];
        
        [mutableString addAttribute:NSForegroundColorAttributeName
                              value:[UIColor blackColor] range:NSMakeRange(0, title.length)];
        
        
        contentView.headerLabel.attributedText = mutableString;
        
        return headerView;
    }
    else if (kind == UICollectionElementKindSectionFooter)
    {
        UICollectionReusableView * footerView =[collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:(NSString*)kSectionFooterIdentifier forIndexPath:indexPath];
        return footerView;
        
    }else
    return nil;
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SelectFiltersCell * cell = (SelectFiltersCell*)[collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
   
    NSString * title;
    
    title =[g_FilterMap valueForKey:g_FilterMap.allKeys[indexPath.section]][indexPath.row];
    
    NSMutableAttributedString * mutableString =[[NSMutableAttributedString alloc]initWithString:title];
    
    [mutableString addAttribute:NSForegroundColorAttributeName
                          value:[UIColor blackColor] range:NSMakeRange(0, title.length)];
    
    CIImage * image = [CIImage imageWithCGImage:self.item.image.CGImage];
    CIFilter * filter = [ CIFilter filterWithName:title];
    
    NSDictionary *centerDic = (NSDictionary *)[filter.attributes objectForKey:@"inputCenter"];
    
    if (centerDic)
    {
        [filter setValue:centerDic[@"CIAttributeDefault"] forKey:@"inputCenter"];
    }
    
    NSLog(@"Attributes %@",filter.inputKeys);
    
    
    [FilteringProcessor correctFilter:&filter withInputImage:image];
    
    CIImage * result = [filter valueForKey:kCIOutputImageKey];
    UIImage * resImage = [UIImage imageWithCIImage:result];
    cell.imageView.image = resImage;
    CGSize size = [title sizeWithFont: [UIFont systemFontOfSize:[UIFont systemFontSize]]];
    CGRect cellRect = cell.frame;
    cellRect.size.width  = MAX(CGRectGetWidth(cellRect),size.width);
    cellRect.size.height = MAX(CGRectGetHeight(cellRect),size.height);
    cell.titleLabel.frame= cellRect;
    cell.titleLabel.attributedText = mutableString;
    return cell;

}



#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"selectFiltersIdentifier"])
    {
        FilterSettingsController * controller = (FilterSettingsController*)segue.destinationViewController;
        
        if ( [controller isKindOfClass:[FilterSettingsController class]])
        {
            NSString * title;
            NSIndexPath * path = [self.collectionView indexPathsForSelectedItems].lastObject;
            title =[g_FilterMap valueForKey:g_FilterMap.allKeys[path.section]][path.row];
            controller.filter = [ CIFilter filterWithName:title];
            controller.originalImage = self.item.image;            
        }
    }
}

@end
