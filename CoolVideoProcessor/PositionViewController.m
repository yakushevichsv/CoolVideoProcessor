//
//  PositionViewController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 6/28/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "PositionViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "Constants.h"
#import "PositionCell.h"

@interface PositionViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) ALAssetsLibrary * library;
@property (nonatomic,strong) NSMutableArray * urls;
@property (nonatomic,strong) NSMutableArray * durations;
@property (nonatomic) NSTimeInterval duration;
@end

@implementation PositionViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setup];
    }
    return self;
}


-(void)dealloc{
    self.library = nil;
    self.urls = nil;
    self.durations = nil;
}

-(void)setup
{
    self.library = [ALAssetsLibrary new];
}

-(void)setURLUsingDictionary:(NSDictionary *)dataDictionary
{
    NSMutableArray * array = [NSMutableArray array];
    {
        NSArray * array1 = (NSArray*)dataDictionary[IMAGES_KEY];
        NSArray * array2 = (NSArray*)dataDictionary[VIDEOS_KEY];
    
        [array addObjectsFromArray:array1];
        [array addObjectsFromArray:array2];
    }
    if (![_urls isEqualToArray:array])
    {
        _urls =array;
        self.durations = [NSMutableArray arrayWithCapacity:_urls.count];
        self.duration =0;
        
        for (NSUInteger i =0 ;i<self.durations.count;i++)
        {
            self.durations[i] =@(NSUIntegerMax);
        }
        [self.tableView reloadData];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.urls.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellIdentifier = @"positionCell";
   
    PositionCell *
    cell =[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (!cell)
    {
        [tableView registerClass:[PositionCell class] forCellReuseIdentifier:cellIdentifier];
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    }
    
    [self fillCell:cell indexPath:indexPath force:FALSE];
    
    return cell;
}

+(NSString*)formatDuration:(double)duration 
{
    double multiplier = 60;
    NSUInteger seconds,minutes,hours;
    
    double part = ((NSUInteger)(duration/multiplier))*multiplier;
    
    seconds =  ceil(duration - part);
    
    duration = part;
    
    part = ((NSUInteger)(duration/multiplier))*multiplier;
    
    minutes = duration - part;
    
    if (minutes)
    {
        duration = part;
        part = ((NSUInteger)(duration/multiplier))*multiplier;
        hours = duration - part;
        if (!hours)
        {
            hours = (NSUInteger)(duration/multiplier);
        }
    }
    else
    {
        minutes =(NSUInteger)(duration/multiplier);
        hours =0;
    }
    
    
    return [NSString stringWithFormat:@"%d:%d:%d",hours,minutes,seconds];
}

-(void)fillCell:(PositionCell*)cell indexPath:(NSIndexPath*)path force:(BOOL)force
{
    [self.library assetForURL:self.urls[path.row] resultBlock:^(ALAsset *asset) {
        UIImage * image = [[UIImage alloc]initWithCGImage:asset.aspectRatioThumbnail];
        if (!cell.isHidden || force)
        {
            cell.imageView.image = image;
            cell.textLabel.text = asset.defaultRepresentation.filename;
            [cell.imageView sizeToFit];
            
            id durationObj =[asset valueForProperty:ALAssetPropertyDuration] ;
            NSString * result;
            double durationTime;
            if ([durationObj isKindOfClass:[NSNumber class]])
            {
                durationTime =[durationObj doubleValue];
                result =[[self class] formatDuration:durationTime];
            }
            else
            {
                durationTime = 0;
                result = @"Image. No duration";
            }
            self.durations[path.row] = @(durationTime);
            cell.detailTextLabel.text
            =result;
            
        }
    } failureBlock:nil];
}

@end
