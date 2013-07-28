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
@property (nonatomic,strong) NSMutableArray *dicParamIndexes;

@property (nonatomic,weak) IBOutlet UITableView* tableView;
@property (nonatomic,weak) IBOutlet UIImageView *imageProcessed;

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
    self.dicParamIndexes = [NSMutableArray array];
}

-(void)processSettings
{
    NSArray * keys = [self.filter inputKeys];
    
    for (NSString *key in keys)
    {
        if ([key isEqualToString:kCIAttributeFilterCategories] || [key isEqualToString:kCIAttributeFilterDisplayName]|| [key isEqualToString:kCIAttributeFilterName]|| [key isEqualToString:@"inputImage"]
            || [key isEqualToString:@"outputImage"])
            continue;
        
        id valObj = self.filter.attributes[key];
        
        if ([valObj isKindOfClass:[NSDictionary class]])
        {
            NSDictionary * dic = (NSDictionary*)valObj;
            
            if ([dic[kCIAttributeType] isEqualToString:kCIAttributeTypeScalar] && [dic[kCIAttributeClass] isEqual:[NSNumber class]])
            {
                [self.dicParamIndexes addObject:key];
            }
        }
        else {
            NSLog(@"Unknown parameter");
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
        return self.dicParamIndexes.count;
    }
    return -1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == DIC_SECTION)
    {
        static NSString * scalarCellId = @"FilterSettingsScalarCell";
        
        FilterSettingsScalarCell * cell = [tableView dequeueReusableCellWithIdentifier:scalarCellId forIndexPath:indexPath];
        
        if (!cell)
        {
            cell = [[FilterSettingsScalarCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:scalarCellId];
        }
        
        id key =self.dicParamIndexes[indexPath.row];
        
        NSDictionary* dic = (NSDictionary*) self.filter.attributes[key];
        
        if ([key length]>@"input".length)
        {
            NSString * subStr = [key substringFromIndex:@"input".length];
            cell.cellTitle.text = subStr;
        }
        
        cell.slider.minimumValue = [dic[kCIAttributeSliderMin] floatValue];
        cell.slider.maximumValue = [dic[kCIAttributeSliderMax] floatValue];
        cell.delegate =self;
        return cell;
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

-(void)cell:(FilterSettingsScalarCell *)cell didChangeNumber:(NSNumber *)number
{
    NSIndexPath * path = [self.tableView indexPathForCell:cell];
    
    if (path.section == DIC_SECTION)
    {
        id key = self.dicParamIndexes[path.row];
        
        [self.filter setValue:number forKey:key];
       self.imageProcessed.image = [UIImage imageWithCGImage: (__bridge CGImageRef)([self.filter outputImage])];
    }
}

@end
