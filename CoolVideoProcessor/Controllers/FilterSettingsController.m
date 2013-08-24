//
//  FilterSettingsController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/28/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "FilterSettingsController.h"
#import "FilterSettingsScalarCell.h"
#define NUMBER_OF_SECTIONS 1
#define DIC_SECTION 0

@interface FilterSettingsController ()<UITableViewDataSource,UITableViewDelegate,FilterSettingsScalarCellDelegate>
@property (nonatomic,weak) IBOutlet UITableView *tableView;
@property (nonatomic,weak) IBOutlet UIImageView *imageProcessed;
@property (nonatomic,strong) NSMutableDictionary *scalarTypes;

@end

@implementation FilterSettingsController

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
    self.scalarTypes  = [NSMutableDictionary dictionary];
}

-(void)processSettings
{
    NSDictionary *filterAttributes = [self.filter attributes];
    NSUInteger index = 0;
    for (NSString *key in filterAttributes) {
        if ([key isEqualToString:kCIAttributeFilterCategories]) continue;
        else if ([key isEqualToString:kCIAttributeFilterDisplayName]) continue;
        else if ([key isEqualToString:@"inputImage"]) continue;
        else if ([key isEqualToString:@"outputImage"]) continue;
        id valueObj = filterAttributes[key];
        if ([valueObj isKindOfClass:[NSDictionary class]])
        {
            NSDictionary * dic = (NSDictionary *)valueObj;
            id scalarType = [dic objectForKey:kCIAttributeType];
            if ([scalarType isEqualToString:kCIAttributeTypeScalar] ||
                [scalarType isEqualToString:kCIAttributeTypeDistance])
            {
                [self.scalarTypes setObject:@{key:filterAttributes[key]} forKey:@(index)];
                 index++;
            }
        }
    }
}

-(void)setFilter:(CIFilter *)filter
{
    if (![_filter isEqual:filter])
    {
        _filter = filter;
        
        if (filter) [self processSettings];
    }
}

-(void)setOriginalImage:(UIImage *)originalImage
{
    if (![_originalImage isEqual:originalImage])
    {
        _originalImage = originalImage;
        
        if (_originalImage && _filter)
        {
            [_filter setValue:originalImage forKey:kCIInputImageKey];
        }
    }
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUMBER_OF_SECTIONS;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == DIC_SECTION)
    {
        return self.scalarTypes.count;
    }
    return -1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == DIC_SECTION)
    {
        NSDictionary* dic = (NSDictionary*)self.scalarTypes[@(indexPath.row)];
        if (dic)
        {
            static NSString * scalarCellId = @"FilterSettingsScalarCell";
            
            FilterSettingsScalarCell * cell = [tableView dequeueReusableCellWithIdentifier:scalarCellId forIndexPath:indexPath];
            
            if (!cell)
            {
                cell = [[FilterSettingsScalarCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:scalarCellId];
            }
            
            id key = dic.allKeys.lastObject;
            
            if ([[key substringWithRange:NSMakeRange(0, @"input".length)] isEqualToString:@"input"])
            {
                cell.cellTitle.text = [key substringFromIndex:@"input".length];
            }
            
            NSDictionary* newDic = (NSDictionary*)dic[key];
            
            
            cell.slider.minimumValue = [newDic[kCIAttributeSliderMin] floatValue];
            cell.slider.maximumValue = [newDic[kCIAttributeSliderMax] floatValue];
            cell.slider.value = [newDic[kCIAttributeDefault] floatValue];
            cell.delegate =self;
            [self setProcessedImage];
            return cell;
        }
    }
    return nil;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == DIC_SECTION)
    {
        return @"Numeric parameters";
    }
    return nil;
}

- (void)setProcessedImage
{
     self.imageProcessed.image = [UIImage imageWithCGImage: (__bridge CGImageRef)([self.filter outputImage])];
}

-(void)cell:(FilterSettingsScalarCell *)cell didChangeNumber:(NSNumber *)number
{
    NSIndexPath * path = [self.tableView indexPathForCell:cell];
    
    if (path.section == DIC_SECTION)
    {
        id key = nil;//self.dicParamIndexes[path.row];
        [self.filter setValue:number forKey:key];
        [self setProcessedImage];
    }
}

@end
