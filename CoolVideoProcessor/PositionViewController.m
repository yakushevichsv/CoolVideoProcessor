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
#import "Constants.h"
#import "PositionViewController.h"
#import "PositionCell.h"
#import "MergingProcessorViewController.h"
#import "AssetItem.h"
#import "VideoWatcherViewController.h"

@interface PositionViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
-(AssetItem*)assetItem:(NSInteger)index;
@end

@implementation PositionViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   PositionCell * cell = (PositionCell*)[tableView cellForRowAtIndexPath:indexPath];
    [self imagePressed:cell.btnImage];
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

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"mergeSegueIdentifier"])
    {
    
    NSMutableDictionary * dic=[NSMutableDictionary dictionaryWithCapacity:self.items.count];
    NSUInteger index = 0;
    NSTimeInterval start =0;
    for (AssetItem * item in self.items)
    {
        NSArray * array =[self timeRangeForIndex:index atStart:index<2 ? 0 : start];
        [dic setObject:@[item,array] forKey:item.url];
        start+=[array.lastObject doubleValue];
        index++;
    }
    
    MergingProcessorViewController * controller =
    (MergingProcessorViewController*)segue.destinationViewController;
    
        controller.dictionary = dic;
    }
    else if ([segue.identifier isEqualToString:@"playVideoSegue"])
    {
        VideoWatcherViewController * controller =
        (VideoWatcherViewController*)segue.destinationViewController;
       
        NSIndexPath * indexPath = [self.tableView indexPathForSelectedRow];
        NSInteger index = indexPath.row;
        
        if ([self assetItem:index].duration ==0 )
        {
            //TODO: provide displaying image....
            return;
        }
        else
            controller.movieURL = [self assetItem:index].url;
    }
}

#pragma mark -Table View Cell

- (IBAction)imagePressed:(UIButton *)sender
{
    UITableViewCell* cell = (UITableViewCell*)sender.superview.superview;
    NSParameterAssert([cell isKindOfClass:[UITableViewCell class]]);
    NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];
    NSInteger index = indexPath.row;
    
    if ([self assetItem:index].duration ==0 )
    {
        //TODO: provide displaying image....
        return;
    }
    
    [self performSegueWithIdentifier:@"playVideoSegue" sender:self];
    
    
}

@end
