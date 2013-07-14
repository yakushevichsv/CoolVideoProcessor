//
//  MergingProcessorViewController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/2/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreMedia/CoreMedia.h>
#import "MergingProcessorViewController.h"
#import "AssetsLibrary.h"
#import <MediaPlayer/MediaPlayer.h>

@interface MergingProcessorViewController ()
@property (nonatomic,strong) ALAssetsLibrary * library;
@property (nonatomic,strong) NSOperationQueue * queue;
@property (nonatomic,strong) NSURL * mergedVideo;
@end

@implementation MergingProcessorViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setup];
    }
    return self;
}

+(NSURL*)pathForResultVideo
{
   return [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"mov"]]];
}

-(void)setup
{
    self.library = [ALAssetsLibrary new];
    self.queue = [NSOperationQueue new];
}

-(NSTimeInterval)startTime:(id)key
{
   return (NSTimeInterval)[[[self.dictionary[key] lastObject] objectAtIndex:0]doubleValue];
}

-(void)setDictionary:(NSMutableDictionary *)dictionary
{
    if (![dictionary isEqualToDictionary:_dictionary])
    {
        _dictionary = dictionary;
        if (dictionary)
            [self processDictionary];
    }
}

-(void)processDictionary
{
    [self.queue addOperationWithBlock:^{
        NSArray * sortedKeys = [self.dictionary.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSTimeInterval start1 =[self startTime:obj1];
            NSTimeInterval start2 =[self startTime:obj2];
            if (start1<start2)
            {
                return NSOrderedAscending;
            }
            else if (start1>start2)
            {
                return NSOrderedDescending;
            }
            else
            {
                return NSOrderedSame;
            }
        }];
        NSMutableDictionary * newDic =[NSMutableDictionary dictionaryWithCapacity:sortedKeys.count];
        for (id key in sortedKeys)
        {
            [newDic setObject:self.dictionary[key] forKey:key];
        }
        self.dictionary =nil;
        _dictionary = newDic;
    }];
}

-(BOOL)displayMergedVideo
{
    if (self.mergedVideo)
    {
        [self performSelectorOnMainThread:@selector(displayByURL:) withObject:self.mergedVideo waitUntilDone:NO];
        return TRUE;
    }
    return FALSE;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self changeStatus:@"Started exporting" percent:0.0];
    [self.queue addOperationWithBlock:^{
        [self executeTask];
    }];
}

-(void)changeStatus:(NSString*)title percent:(NSUInteger)percent
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.lblTitle.text = title;
        self.pvProgress.progress = percent;
    });
}

-(void)executeTask
{
    if ([self displayMergedVideo]) return;
    
    AVMutableComposition * composition = [AVMutableComposition composition];
    BOOL isError = FALSE;
    NSUInteger count =self.dictionary.count;
    NSUInteger index = 0;
    NSUInteger percent =0;
    for (id key in self.dictionary)
    {
        [self changeStatus:[NSString stringWithFormat:@"Processing %d video out of %d",index+1,count] percent:percent];
        if (![self appendToComposition:composition key:key])
        {
            isError = TRUE;
            break;
        }
        index++;
        percent= ((double)index*100)/count;
        [self changeStatus:[NSString stringWithFormat:@"Completed %d",percent] percent:percent];
    }
    
    if (!isError)
    {
        NSURL * url = [[self class]pathForResultVideo];
        
        [AssetsLibrary exportComposition:composition aURL:url competition:^(NSError *error) {
            
            if (error) {
                NSLog(@"Error %@",error);
            }
            else {
                self.mergedVideo = url;
                [self changeStatus:@"Finished" percent:100];
                (void)[self displayMergedVideo];
            }
        }];
    }
    else
    {
        [self changeStatus:[NSString stringWithFormat:@"Error. Status: %d",percent] percent:percent];
    }
}

-(void)displayByURL:(NSURL*)url
{
    MPMoviePlayerViewController * controller= [[MPMoviePlayerViewController alloc]initWithContentURL:url];
    controller.moviePlayer.shouldAutoplay = YES;
    
    [[NSNotificationCenter defaultCenter]removeObserver:controller name:MPMoviePlayerPlaybackDidFinishNotification object:controller.moviePlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:controller.moviePlayer];
    controller.moviePlayer.controlStyle = MPMovieControlStyleFullscreen;
    [controller.moviePlayer prepareToPlay];
    
    [self presentMoviePlayerViewControllerAnimated:controller];
}

#pragma mark - MPMoviePlayer Delegate

-(void)playerPlaybackDidFinish:(NSNotification*)notification
{
    if ([notification.userInfo[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue]==MPMovieFinishReasonUserExited)
    {
        [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:notification.object];
        
        MPMoviePlayerController * controller = ( MPMoviePlayerController * )notification.object;
        
        [controller pause];
        controller.initialPlaybackTime =-1;
        [controller stop];
        controller.initialPlaybackTime = -1;
        
        [self dismissMoviePlayerViewControllerAnimated];
        
    }
    
}


-(BOOL)appendToComposition:(AVMutableComposition*)composition key:(id)key
{
    NSURL * url = (NSURL*)key;
    AVURLAsset * asset = [[AVURLAsset alloc]initWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)}];
    
    // calculate time
    
    NSArray * valueObj = [self.dictionary[key]lastObject];
    NSTimeInterval startTime =(NSTimeInterval)[valueObj[1] doubleValue];
    NSTimeInterval durationTime =(NSTimeInterval)[valueObj.lastObject doubleValue];
    CMTime start = CMTimeMakeWithSeconds(startTime, 1);
    CMTime duration = CMTimeMakeWithSeconds(durationTime, 1);
    
    CMTimeRange range = CMTimeRangeMake(start,duration);
    NSError * error = nil;
    BOOL result = [composition insertTimeRange:range ofAsset:asset atTime:composition.duration error:&error];
    
    if (error) NSLog(@"ERROR: %@",error);
    return result;
}

@end
