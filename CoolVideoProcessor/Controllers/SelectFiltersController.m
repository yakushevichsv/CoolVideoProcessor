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

static NSDictionary * g_NameMap;

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
    
    for (NSUInteger i=0;i<visibleText.count;i++)
    {
        dic[names[i]] = visibleText[i];
    }
    g_NameMap  = dic;
    
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

- (void)viewDidLoad
{
    [super viewDidLoad];
	CIImage * image = [CIImage imageWithCGImage:self.item.image.CGImage];
    CIFilter * filter = [ CIFilter filterWithName:@"CISepiaTone"];
    [filter setValue:image forKey:kCIInputImageKey];
    [filter setValue:@(0.8f) forKey:@"inputIntensity"];
    CIImage * result = [filter valueForKey:kCIOutputImageKey];
    CGImageRef cgImage =[self.context createCGImage:result fromRect:[result extent]];
    UIImage * resImage = [UIImage imageWithCGImage:cgImage];
    UIImageView * imageView = [[UIImageView alloc] initWithImage:resImage];
    imageView.bounds =CGRectMake(0,0,resImage.size.width,resImage.size.height);
    imageView.center =self.view.center;
    [imageView sizeToFit];
    [self.view addSubview:imageView];
}

#pragma mark - UICollectionViewDelegate & Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return g_NameMap.allKeys.count;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSArray * array =[CIFilter filterNamesInCategory:g_NameMap.allKeys[section]];
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
       title = [g_NameMap valueForKey:g_NameMap.allKeys[indexPath.section]];
        
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
    
    title =[CIFilter filterNamesInCategory:g_NameMap.allKeys[indexPath.section]][indexPath.row];
    
    NSMutableAttributedString * mutableString =[[NSMutableAttributedString alloc]initWithString:title];
    
    [mutableString addAttribute:NSForegroundColorAttributeName
                          value:[UIColor blackColor] range:NSMakeRange(0, title.length)];
    
    cell.titleLabel.frame= cell.frame;
    cell.titleLabel.attributedText = mutableString;
    return cell;

}


@end
