//
//  PositionViewController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 6/28/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "PositionViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "Constants.h"
#import "PositionCell.h"
#import "MergingProcessorViewController.h"
#import "PlayerViewController.h"

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

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    //self.navigationItem.rightBarButtonItem = [self editButtonItem];
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

-(UIImage*)dataFromAsset:(AVURLAsset*)asset size:(CGSize)size durationPtr:(NSTimeInterval*)durationPtr
{
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]
                                             initWithAsset:asset];
    imageGenerator.maximumSize = size;
    NSTimeInterval durationSeconds = (NSTimeInterval)CMTimeGetSeconds([asset duration]);
    *durationPtr=durationSeconds;
    CMTime midpoint = CMTimeMakeWithSeconds(0, 600);
    NSError *error;
    CMTime actualTime;
    CGImageRef image = [imageGenerator copyCGImageAtTime:midpoint
                                                     actualTime:&actualTime error:&error];
    if (image != NULL) {
        
        UIImage * retImage = [UIImage imageWithCGImage:image];
        // Do something interesting with the image.
        CGImageRelease(image);
        return retImage;
    }
    return nil;
}

-(NSString*)titleForAsset:(AVURLAsset*)asset
{
    
    NSError *error = nil;
    AVKeyValueStatus tracksStatus = [asset statusOfValueForKey:@"commonMetadata"
                                                         error:&error];
    
    if (tracksStatus != AVKeyValueStatusLoaded)
        return nil;
    
    NSArray *titles = [AVMetadataItem metadataItemsFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyDescription keySpace:AVMetadataKeySpaceCommon];
    if ([titles count] > 0)
    {
        // If there is only one title, then use it
        if ([titles count] == 1)
        {
            AVMetadataItem *titleItem = [titles objectAtIndex:0];
            return [titleItem stringValue];
        }
        else
        {
            // If there are more than one, search for the proper locale
            NSArray *preferredLanguages = [NSLocale preferredLanguages];
            for (NSString *currentLanguage in preferredLanguages)
            {
                NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:currentLanguage];
                NSArray *titlesForLocale = [AVMetadataItem metadataItemsFromArray:titles withLocale:locale];
                if ([titlesForLocale count] > 0)
                {
                   return [[titlesForLocale objectAtIndex:0] stringValue];
                }
            }
        }
    }
    return nil;
}

-(NSNumber*)durationForAsset:(AVURLAsset*)asset cell:(PositionCell*)cell imagePtr:(UIImage**)imagePtr
{
    NSError *error = nil;
    AVKeyValueStatus tracksStatus = [asset statusOfValueForKey:@"duration"
                                                         error:&error];
    NSTimeInterval durationTime =0;
    
    switch (tracksStatus) {
        case AVKeyValueStatusLoaded:
        {
            UIImage * image =[self dataFromAsset:asset size:CGSizeMake(29, 43) durationPtr:&durationTime];
            *imagePtr = image;
            break;
        }
        case AVKeyValueStatusFailed:
            NSLog(@"Error :%@",[error description]);
            
            break;
        case AVKeyValueStatusCancelled:
            // Do whatever is appropriate for cancelation.
            break;
    }
    return @(durationTime);
}

-(void)fillCell:(PositionCell*)cell indexPath:(NSIndexPath*)path force:(BOOL)force
{
    AVURLAsset * asset =[[AVURLAsset alloc]initWithURL:self.urls[path.row] options:nil];
    cell.hidden = TRUE;
    NSArray * keys= @[@"duration",@"commonMetadata"];
    NSInteger row = path.row;
    [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        UIImage * image = nil;
        NSNumber * duration = [self durationForAsset:asset cell:cell imagePtr:&image];
        self.durations[row]=duration;
        NSString * title = [self titleForAsset:asset];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.imageView.image = image;
            cell.textLabel.text = title ? title :@"No name";
            NSTimeInterval durationTime = [duration doubleValue];
            if (durationTime)
            {
                cell.detailTextLabel.text= [[self class] formatDuration:durationTime];
            }
            else
            {
                cell.detailTextLabel.text = @"";
            }
            cell.hidden = FALSE;
            [cell setNeedsDisplay];
        });
    }];
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
		[self.urls removeObjectAtIndex:indexPath.row];
        [self.durations removeObjectAtIndex:indexPath.row];
        
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
    [self swapInArray:self.urls sourceIndex:sourceIndex destIndex:destIndex];
    [self swapInArray:self.durations sourceIndex:sourceIndex destIndex:destIndex];
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSTimeInterval totalTime =[self.durations[indexPath.row] doubleValue];
    if (totalTime)
    {
        [self performSegueWithIdentifier:@"viewItemSeque" sender:self];
    }
    else
    {
        UIAlertView * view = [UIAlertView new];
        view.title=@"Attention";
        view.alertViewStyle= UIAlertViewStyleDefault;
        view.message =@"Content is not a video!";
        [view show];    }
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
    NSTimeInterval totalTime =[self.durations[index] doubleValue];
    
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
    
    NSMutableDictionary * dic=[NSMutableDictionary dictionaryWithCapacity:self.urls.count];
    NSUInteger index = 0;
    NSTimeInterval start =0;
    for (NSURL * url in self.urls)
    {
        NSArray * array =[self timeRangeForIndex:index atStart:index<2 ? 0 : start];
        [dic setObject:array forKey:url];
        start+=[array.lastObject doubleValue];
        index++;
    }
    
    MergingProcessorViewController * controller =
    (MergingProcessorViewController*)segue.destinationViewController;
    
        controller.dictionary = dic;
    }
    else if ([segue.identifier isEqualToString:@"viewItemSeque"])
    {
       PlayerViewController * controller =
        (PlayerViewController*)segue.destinationViewController;
        NSInteger row = [self.tableView indexPathForSelectedRow].row;
        [controller setUrl:self.urls[row]];
    }
}

@end
