//
//  FilteringProcessor.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 10/13/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "FilteringProcessor.h"
#import <AVFoundation/AVFoundation.h>



@interface FilteringProcessor()
{
    filteringProcessorCompletitionBlock _completitionBlock;
}

@end

@implementation FilteringProcessor


+ (void)correctFilter:(CIFilter **)filterPtr withInputImage:(CIImage *)image
{
    CIFilter *filter = *filterPtr;
    
    for (NSString *attribute in filter.attributes)
    {
        NSDictionary *params = (NSDictionary *)filter.attributes[attribute];
        if ([params isKindOfClass:[NSDictionary class]] &&  [params[@"CIAttributeClass"] isEqualToString:@"CIImage"])
        {
            [filter setValue:image forKey:attribute];
        }
    }
}

- (void)processAssetWithCompletitionBlock:(filteringProcessorCompletitionBlock)completitionBlock
{
    CMTimeRange range =  CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(self.filtration.asset.duration, 1));
    [self processAssetWithTimeRange:range completitionBlock:completitionBlock];
}

- (void)processAssetWithTimeRange:(CMTimeRange)range completitionBlock:(filteringProcessorCompletitionBlock)completitionBlock
{
    _completitionBlock =completitionBlock;
    AVURLAsset * asset = [[AVURLAsset alloc]initWithURL:self.filtration.asset.url options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)}];
    
    NSArray *assetKeysToLoadAndTest = @[@"composable", @"tracks", @"duration",@"readable"];
    
    
   
    
    AVKeyValueStatus status = AVKeyValueStatusUnknown;
    
    for (NSString * key in assetKeysToLoadAndTest)
    {
        status =[asset statusOfValueForKey:key error:nil];
        
        if (status != AVKeyValueStatusLoaded)
            break;
    }
    __weak FilteringProcessor * weakSelf = self;
    if (status != AVKeyValueStatusLoaded)
    {
        [asset loadValuesAsynchronouslyForKeys:assetKeysToLoadAndTest completionHandler:^{
    
            [weakSelf performActionOnAsset:asset withTimeRange:range];
                
        }];
    }
    else
        [weakSelf performActionOnAsset:asset withTimeRange:range];
}

- (void)performActionOnAsset:(AVURLAsset *)asset withTimeRange:(CMTimeRange)range
{
   if (![asset isReadable])
   {
       NSLog(@"Asset is not readable");
       return;
   }

    NSError *error = nil;
    AVAssetReader *reader = [[AVAssetReader alloc]initWithAsset:asset error:&error];
    
    reader.timeRange = range;
    
    if (error)
    {
        NSLog(@"Error %@",error.localizedDescription);
        return;
    }
    
    //dispatch_queue_t audioCaptureQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
	//[audioOut setSampleBufferDelegate:self queue:audioCaptureQueue];

    AVMutableComposition *composition = [AVMutableComposition composition];
    
    [composition insertTimeRange:range ofAsset:asset atTime:kCMTimeZero error:nil];
    
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    NSParameterAssert(videoTracks.count==1);
    AVAssetTrack *videoTrack = (AVAssetTrack *)videoTracks.lastObject;

    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings =
    [NSDictionary dictionaryWithObject:value forKey:key];
    
    AVAssetReaderTrackOutput *trackOutput=[AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:videoSettings];
    
    
    if ([reader canAddOutput:trackOutput])
        [reader addOutput:trackOutput];
    else
        NSLog(@"Error adding track output!");
    
    NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    NSParameterAssert(audioTracks.count ==1 );
    AVAssetTrack *audioTrack = (AVAssetTrack *)audioTracks.lastObject;

    NSMutableDictionary* audioReadSettings = [NSMutableDictionary dictionary];
    [audioReadSettings setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM]
                         forKey:AVFormatIDKey];
    
    AVAssetReaderTrackOutput* audioTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:audioReadSettings];

    
    // Add the output to the reader if possible.
    if ([reader canAddOutput:audioTrackOutput])
         [reader addOutput:audioTrackOutput];
    else
        NSLog(@"Error adding audio output!");
    
    if (![reader startReading])
    {
        NSLog(@"Can not start reading! %@, %d",reader.error,reader.status);
        return;
    }
    
    //const float frameRate = videoTrack.nominalFrameRate;
    //const CGSize frameSize = videoTrack.naturalSize;
    
    
    
    CMSampleBufferRef audioBuffer = nil;
    AVAudioPlayer * player = nil;
    while ((audioBuffer =  [audioTrackOutput copyNextSampleBuffer]))
    {
        NSData * data = [self convertAudioBuffer:audioBuffer];
        
        if (!data) continue;
        
        NSError *error = nil;
        
        if (player.isPlaying)
            [player stop];
        
        player = [[AVAudioPlayer alloc]initWithData:data error:&error];
        
        if (error)
            NSLog(@"Error %@",error.description);
        if ([player prepareToPlay])
            [player play];
        else
            NSLog(@"Error preparing for play !");
    }
    
    if([reader status]==AVAssetReaderStatusCompleted && _completitionBlock)
        _completitionBlock();
}

- (NSData *)convertAudioBuffer:(CMSampleBufferRef)ref
{
    AudioBufferList audioBufferList;
    NSMutableData *data=[[NSMutableData alloc] init];
    CMBlockBufferRef blockBuffer;
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(ref, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);
    // NSLog(@"%@",blockBuffer);
    
    
    if(blockBuffer==NULL)
    {
        
        return nil;
    }
    if(&audioBufferList==NULL)
    {
        return nil;
    }
    
    
    for( int y=0; y<audioBufferList.mNumberBuffers; y++ )
    {
        AudioBuffer audioBuffer = audioBufferList.mBuffers[y];
        Float32 *frame = (Float32*)audioBuffer.mData;
        
        
        [data appendBytes:frame length:audioBuffer.mDataByteSize];
        
        
        
    }
    
    
    CFRelease(blockBuffer);
    CFRelease(ref);
    ref=NULL;
    blockBuffer=NULL;
    return data;
}

@end
