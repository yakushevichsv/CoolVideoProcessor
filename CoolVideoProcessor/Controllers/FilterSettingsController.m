//
//  FilterSettingsController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/28/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "FilterSettingsController.h"
#import "FilterSettingsScalarCell.h"
#import "FilterSettingsVectorCell.h"

#define NUMBER_OF_SECTIONS 1
#define DIC_SECTION 0

@interface FilterSettingsController ()<UITableViewDataSource,UITableViewDelegate,FilterSettingsScalarCellDelegate,FilterSettingsVectorCellDelegate>
@property (nonatomic,weak) IBOutlet UITableView *tableView;
@property (nonatomic,weak) IBOutlet UIImageView *imageProcessed;
@property (nonatomic,strong) NSMutableDictionary *scalarTypes;

@property (nonatomic,strong) NSMutableDictionary * vectorTypes;
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
    self.vectorTypes = [NSMutableDictionary dictionary];
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
            id scalarType = [dic objectForKey:kCIAttributeClass];
            if ([scalarType isEqualToString:@"NSNumber"])
            {
                [self.scalarTypes setObject:@{key:filterAttributes[key]} forKey:@(index)];
                 index++;
            }
            else if ([scalarType isEqualToString:@"CIVector"])
            {
                CIVector * vector = [dic objectForKey:kCIAttributeDefault];
                [self.vectorTypes setObject:@{key:filterAttributes[key],@"count":@(vector.count)} forKey:@(index)];
                index++;
            }
            else {
                NSLog(@"Current type is %@",scalarType);
            }
            [self.filter setValue:dic[kCIAttributeDefault] forKey:key];
        }
        
    }
    
    [self setImageForFilter];
    
}

-(void)setImageForFilter
{
    CIImage * ciImage = [CIImage imageWithCGImage:self.originalImage.CGImage];
    [self.filter setValue:ciImage forKey:kCIInputImageKey];
 
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
        
        if (originalImage)
        {
            [self setImageForFilter];
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
        return self.scalarTypes.count+self.vectorTypes.count;
    }
    return -1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == DIC_SECTION)
    {
        NSNumber * rowPath = @(indexPath.row);
        NSDictionary* dic = (NSDictionary*)self.scalarTypes[rowPath];
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
        else if ((dic = (NSDictionary*)self.vectorTypes[rowPath]))
        {
            static NSString * vectorCellId = @"FilterSettingsVectorCell";
            
            FilterSettingsVectorCell * cell = [tableView dequeueReusableCellWithIdentifier:vectorCellId forIndexPath:indexPath];
            
            NSInteger count = [dic[@"count"]integerValue];
            NSArray * subArray = [@[@"X",@"Y",@"Z",@"W"] subarrayWithRange:NSMakeRange(0, count)];
            
            if (!cell)
            {
                cell = [[FilterSettingsVectorCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:vectorCellId cellTitles:subArray];
            }
            cell.delegate =self;
            cell.cellTitles = subArray;
            
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
    UIImage * resImage = [UIImage imageWithCIImage:[self.filter outputImage]];
    self.imageProcessed.image = resImage;
    //[self.imageProcessed sizeToFit];
    self.imageProcessed.contentMode = UIViewContentModeScaleToFill;
    //self.imageProcessed.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)cell:(FilterSettingsScalarCell *)cell didChangeNumber:(NSNumber *)number
{
    NSIndexPath * path = [self.tableView indexPathForCell:cell];
    
    if (path.section == DIC_SECTION)
    {
        NSDictionary* dic = (NSDictionary*) self.scalarTypes[@(path.row)];
        
        if (dic)
        {
            id internalKey = dic.allKeys.lastObject;
            [self.filter setValue:number forKey:internalKey];
            [self setProcessedImage];
        }
    }
}

-(void)cell:(FilterSettingsVectorCell *)cell values:(NSArray*)values
{
    NSIndexPath * path = [self.tableView indexPathForCell:cell];
    
    if (path.section == DIC_SECTION)
    {
        NSDictionary * dic = (NSDictionary*)self.vectorTypes[@(path.row)];
        
        if (dic)
        {
            for (id key in dic.allKeys)
            {
               if (![key isEqualToString:@"count"])
               {
                   id internalKey = key;
                   
                   CIVector *vector;
                   if (values.count==1)
                   {
                       vector = [CIVector vectorWithX:[values.lastObject floatValue]];
                   }
                   else if (values.count ==2)
                   {
                                              vector = [CIVector vectorWithX:[values[0] floatValue]
                                                        Y:[values.lastObject floatValue]];
                   }
                   
                   
                   [self.filter setValue:vector forKey:internalKey];
                   [self setProcessedImage];
                   break;
               }
            }
        }
    }
    
}

@end
