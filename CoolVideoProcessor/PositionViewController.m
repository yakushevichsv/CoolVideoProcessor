//
//  PositionViewController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 6/28/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CoreMedia/CoreMedia.h>
#import  <CoreImage/CoreImage.h>
#import "Constants.h"
#import "PositionViewController.h"
#import "PositionCell.h"
#import "MergingProcessorViewController.h"
#import "AssetItem.h"
#import "SelectFiltersController.h"
#import "ALAssetItem.h"
#import "VideoProcessor.h"
#import "FilterInfo.h"
#import "FileProcessor.h"
#import "FilterSettingsController.h"
#import "CIFilter+SYExtensions.h"
#import "FilteringPlayerViewController.h"

@interface PositionViewController ()<UITableViewDataSource,UITableViewDelegate,SelectFiltersDelegate>
{
    NSMutableDictionary * _filters;
    NSIndexPath *_selectedItem;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
-(AssetItem*)assetItem:(NSInteger)index;
@end

@implementation PositionViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        _filters = [NSMutableDictionary dictionary];
    }
    return self;
}

-(AssetItem*)assetItem:(NSInteger)index
{
    return (AssetItem*)self.items[index];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
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
    AssetItem * item = [self assetItem:path.row];
    UIImage * image =[item loadThumbnailWithCompletitionHandler:^{
        [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
    }];
    [cell.btnImage setImage:image forState:UIControlStateNormal];
    [cell.btnImage sizeToFit];
    
    NSString * title = [item loadTitleWithCompletitionHandler:^{
        [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
    }];
    cell.lblTitle.text  =title ? title :@"No name";
    
    NSTimeInterval durationTime =[item loadDurationWithCompletitionHandler:^{
        [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
    }];
    
    if (durationTime)
    {
        cell.lblSubTitle.text = [[self class] formatDuration:durationTime];
    }
    else
    {
        cell.lblSubTitle.text = @"";
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

// When editing is finished, either delete or insert new metadata items
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
	
	// Delete metadata from the assetItem and the table view
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		[self.items removeObjectAtIndex:indexPath.row];
        [[self tableView] deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	}
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSUInteger sourceIndex = sourceIndexPath.row;
    NSUInteger destIndex = destinationIndexPath.row;
    [self swapInArray:self.items sourceIndex:sourceIndex destIndex:destIndex];
}

-(void)swapInArray:(NSMutableArray*)array sourceIndex:(NSUInteger)sIndex
 destIndex:(NSUInteger)dIndex
{
    id temp = array[sIndex];
    array[sIndex] = array[dIndex];
    array[dIndex] = temp;
}

-(NSArray*)timeRangeForIndex:(NSUInteger)index atStart:(NSTimeInterval)start
{
    NSTimeInterval totalTime =((AssetItem*)self.items[index]).duration;
    
    NSTimeInterval duration,startIn;
    if (!arc4random()/2.0)
    {
        duration = totalTime/3;
        startIn = 2*duration;
    }
    else
    {
        duration = totalTime/4;
        startIn = 3*duration;
    }
    
    if (!duration)
    {
        duration =10;
    }
    
    return @[@(start),@(startIn),@(duration)];
}

-(CIFilter *)createFilterForItemAtIndex:(NSUInteger)index
{
    CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"
                                  keysAndValues:
                        @"inputIntensity", [NSNumber numberWithFloat:0.4], nil];
    return filter;
}

- (NSArray *)createProcessingImageArray
{
    NSMutableArray * array = [NSMutableArray arrayWithCapacity:self.items.count];
    for (AssetItem * item in self.items)
    {
        ProcessingImageInfo * info = [ProcessingImageInfo new];
        info.item = item;
        info.timeRange = CMTimeMakeWithSeconds(6, 1);
        info.filter = [self createFilterForItemAtIndex:NSUIntegerMax];
        [array addObject:info];
    }
    return array;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //TODO: figure out what to do here.....
    if ([segue.identifier isEqualToString:@"mergeSegueIdentifier"])
    {
    
    NSMutableDictionary * dic=[NSMutableDictionary dictionaryWithCapacity:self.items.count];
    NSUInteger index = 0;
    NSTimeInterval start =0;
    BOOL pureImages = YES;
    for (AssetItem * item in self.items)
    {
        NSArray * array =[self timeRangeForIndex:index atStart:index<2 ? 0 : start];
        [dic setObject:@[item,array] forKey:item.url];
        start+=[array.lastObject doubleValue];
        index++;
        
        if (pureImages && item.duration)
        {
            pureImages = NO;
        }
    }
        
        
        
            MergingProcessorViewController * controller =
            (MergingProcessorViewController*)segue.destinationViewController;
    
            controller.dictionary = dic;
        
        if (pureImages)
        {
            controller.dictionary = nil;
            
            NSArray *array = [self createProcessingImageArray];
            
            controller.pureImages = array;
        }
        
    }
    else if ([segue.identifier isEqualToString:@"applyFiltersSegue"])
    {
        SelectFiltersController * controller =
        (SelectFiltersController*)segue.destinationViewController;
        NSIndexPath * path = [self.tableView indexPathForSelectedRow];
        _selectedItem = path;
        controller.item = (AssetItem*)self.items[path.row];
        controller.delegate =self;
        [self.tableView deselectRowAtIndexPath:path animated:YES];
    }
    else if ([segue.identifier isEqualToString:@"videoViewSegue"])
    {
        FilteringPlayerViewController * controller = (FilteringPlayerViewController *) segue.destinationViewController;
     
        NSIndexPath * path = [self.tableView indexPathForSelectedRow];
        controller.url = ((AssetItem*)self.items[path.row]).url;
        [self.tableView deselectRowAtIndexPath:path animated:YES];
    }
}

#pragma mark -Table View Cell

- (IBAction)imagePressed:(UIButton *)sender
{
    UITableViewCell* cell = (UITableViewCell*)sender.superview.superview.superview;
    NSParameterAssert([cell isKindOfClass:[UITableViewCell class]]);
    NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];
    NSInteger index = indexPath.row;
    AssetItem * assetItem = [self assetItem:index];
    if (assetItem.mediaType ==AssetItemMediaTypeImage)
    {
        if ([self assetItem:index].type == AssetItemTypeAL )
        {
            ALAssetItem *al = (ALAssetItem*)[self assetItem:index];
            
            [al loadImageWithCompletitionHandler:^(UIImage *image) {
                if (image)
                {
                    [self displayImage:image];
                }
            }];
        }
    }
    else if (assetItem.mediaType == AssetItemMediaTypeVideo)
    {
        [self performSegueWithIdentifier:@"videoViewSegue" sender:sender];
    }
       // [self displayMovieByURL:[self assetItem:index].url ];
    
}

-(UIImage *)applyFilter:(CGImageRef)beginImage
{
    CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"
                                  keysAndValues: kCIInputImageKey, beginImage,
                        @"inputIntensity", [NSNumber numberWithFloat:0.4], nil];
    
    CGImageRelease(beginImage);
    
    
    CIImage *outputImage = [filter outputImage];
    
    return [UIImage imageWithCIImage:outputImage];
}

#pragma mark - SelectFiltesDelegate protocol

-(void)selectFiltersController:(SelectFiltersController *)controller didSelectFiltersChain:(NSArray *)filters info:(NSDictionary *)filtersInfo
{
    //TODO: add code here...
}

#pragma mark - Unwind action

- (IBAction)unwindDoneWithFilterSettings:(UIStoryboardSegue *)sender
{
   FilterSettingsController * settingsController = sender.sourceViewController;
   NSMutableArray *array = [NSMutableArray arrayWithArray:[settingsController.filter inputKeys]];
    [array removeObject:kCIInputImageKey];
   id inputImage = [settingsController.filter valueForKey:kCIInputImageKey];
    CIFilter * filter = [CIFilter filterWithName:[settingsController.filter name]];
    for (NSString *key in array)
   {
       NSInteger index = key.length - @"Image".length;
      if ([[key substringFromIndex:index] isEqualToString:@"Image"])
      {
          if (inputImage == [settingsController.filter valueForKey:key])
          {
              [filter addImageParameter:key];
          }
          else
          {
              [filter setValue:[settingsController.filter valueForKey:key] forKey:key];
          }
      }
      else{
          [filter setValue:[settingsController.filter valueForKey:key] forKey:key];
      }
   }
    NSParameterAssert(_selectedItem);
   [_filters setObject:filter forKey:[NSString stringWithFormat:@"%d,%d",_selectedItem.section,_selectedItem.row]];
}

@end
