//
//  MergingProcessorViewController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/2/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import "MergingProcessorViewController.h"
#import "AssetsLibrary.h"
#import <MediaPlayer/MediaPlayer.h>
#import "FileProcessor.h"
#import "AssetItem.h"


@interface MergingProcessorViewController ()
@property (nonatomic,strong) ALAssetsLibrary * library;
@property (nonatomic,strong) NSOperationQueue * queue;
@property (nonatomic,strong) NSURL * mergedVideo;
@property (nonatomic) NSUInteger count;
@property (nonatomic) UIBackgroundTaskIdentifier taskId;
@property (nonatomic) NSTimeInterval startTime;
@property (nonatomic) UInt32 soundID;
@property (nonatomic) NSUInteger percentage;
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
    self.taskId = UIBackgroundTaskInvalid;
    self.soundID = -1;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(enterBGMode:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(leaveBGMode:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [self disposeSystemSound:TRUE];
}

- (void)disposeSystemSound:(BOOL)dispose
{
    if (self.soundID !=-1)
    {
        if (dispose)
        {
            AudioServicesDisposeSystemSoundID(self.soundID);
            AudioServicesRemoveSystemSoundCompletion(self.soundID);
        }
        self.soundID = -1;
    }
}

- (void)enterBGMode:(NSNotification *)aNotification
{
    if (aNotification)
    {
        [UIApplication sharedApplication].applicationIconBadgeNumber = self.pvProgress.progress*100;
    }
    if (self.taskId != UIBackgroundTaskInvalid)
    {
        UIBackgroundTaskIdentifier ident = self.taskId;
        if (ident != UIBackgroundTaskInvalid)
        {
            self.taskId = UIBackgroundTaskInvalid;
         
            NSLog(@"Scheduling, begining BG task");
            self.taskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
                           {
                               NSLog(@"Expired BG time!");
                               //We shouldn't be here.....
                               //TODO: think about restoration & conservation state...
                               [self leaveBGMode];
                           }];
            NSLog(@"Leaving BG mode");
            [[UIApplication sharedApplication]endBackgroundTask:ident];
            NSLog(@"BG task has started");
            [self disposeSystemSound:YES];
            self.startTime = [UIApplication sharedApplication].backgroundTimeRemaining;
            NSLog(@"Left task");
        }
    }
    else
    {
        [self _enterBGMode];
    }
}

- (void)_enterBGMode
{
    NSParameterAssert(self.taskId == UIBackgroundTaskInvalid);
    
    
    NSLog(@"Scheduling, begining BG task");
    self.taskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
                   {
                       NSLog(@"Expired BG time!");
                       //We shouldn't be here.....
                       //TODO: think about restoration & conservation state...
                       [self leaveBGMode];
                   }];
    
    NSLog(@"BG task has started");
    self.startTime = [UIApplication sharedApplication].backgroundTimeRemaining;
}

- (void)leaveBGMode
{
    [self leaveBGMode:NULL];
}
- (void)leaveBGMode:(NSNotification *)aNotification
{
    if (aNotification)
    {
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        
        if (self.percentage)
        {
            [self notifyAboutCurrentProgress:self.percentage];
            if (self.percentage == 100)
            {
                [self displayMergedVideo];
                return;
            }
        }
    }
    UIBackgroundTaskIdentifier ident = self.taskId;
    
    if (ident != UIBackgroundTaskInvalid)
    {
        self.taskId = UIBackgroundTaskInvalid;
        [[UIApplication sharedApplication]endBackgroundTask:ident];
        NSLog(@"Leaving BG mode");
        [self disposeSystemSound:YES];
        NSLog(@"Left task");
    }
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

- (void) playSystemSound
{
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"Sound12" ofType:@"aif"];
    if (!soundPath || self.soundID != -1 ) return;
    
    SystemSoundID soundID;
    OSStatus status = AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: soundPath], &soundID);
    if (status == 0)
    {
        AudioServicesAddSystemSoundCompletion(soundID,NULL,NULL,&MyAudioServicesSystemSoundCompletionProc, (__bridge void *)(self));
        AudioServicesPlaySystemSound (soundID);
        self.soundID = soundID;
    }
}

void MyAudioServicesSystemSoundCompletionProc (
                                               SystemSoundID  ssID,
                                               void           *clientData
                                               )
{
    __weak typeof(MergingProcessorViewController *) vc = (__bridge MergingProcessorViewController *)clientData;
    
    AudioServicesDisposeSystemSoundID(ssID);
    AudioServicesRemoveSystemSoundCompletion(ssID);
    
    [vc disposeSystemSound:FALSE];
    
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
    if (self.mergedVideo && self.taskId == UIBackgroundTaskInvalid)
    {
        [self performSelectorOnMainThread:@selector(displayMovieByURL:) withObject:self.mergedVideo waitUntilDone:NO];
        return TRUE;
    }
    return FALSE;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self changeStatus:@"Started exporting" percent:0.0];
    [self.queue addOperationWithBlock:^{
        if (!self.pureImages)
            [self executeTask];
        else
            [self executeTaskForPureImages];
    }];
}

-(void)changeStatus:(NSString*)title percent:(NSUInteger)percent
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.lblTitle.text = title;
        self.pvProgress.progress = percent;
    });
}

-(void)executeTaskForPureImages
{
    FileProcessor * processor = [FileProcessor new];
    [processor applyFiltersToArray:self.pureImages withCompletition:^(NSURL *url) {
        self.mergedVideo = url;
        [self displayMergedVideo];
    }];
}

- (void)start
{
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [self startInternal:0 composition:composition completition:^(AVAsset * asset)
    {
       [self readSamples:asset];
    }];
    
}

- (AVURLAsset *)getAssetAtIndex:(NSUInteger)index
{
    NSArray * items = self.dictionary[self.dictionary.allKeys[index]];
    
    AssetItem * assetItem = items[0];
    
    AVURLAsset * asset = [AVURLAsset assetWithURL:assetItem.url];
    
    return asset;
}

- (BOOL)exportComposition:(AVMutableComposition *)composition filePath:(NSString* )path block:(void(^)(void))block
{
    
    [AVAssetExportSession determineCompatibilityOfExportPreset:AVAssetExportPresetMediumQuality withAsset:composition outputFileType:AVFileTypeQuickTimeMovie completionHandler:^(BOOL compatible) {
        
        if (!compatible) return;
    
    AVAssetExportSession *exportSession = [AVAssetExportSession
                                           exportSessionWithAsset:composition
                                           presetName:AVAssetExportPresetMediumQuality];
    if (nil == exportSession) return ;
    
    // create trim time range - 20 seconds starting from 30 seconds into the asset
    CMTime startTime = kCMTimeZero;
    CMTime stopTime = composition.duration;
    CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(startTime, stopTime);

    
    // configure export session  output with all our parameters
    exportSession.outputURL = [NSURL fileURLWithPath:path]; // output path
    //.exportSession.outputFileType = AVFileTypeAppleM4A; // output file type
    exportSession.timeRange = exportTimeRange; // trim time range
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    // perform the export
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        
        if (AVAssetExportSessionStatusCompleted == exportSession.status) {
            NSLog(@"AVAssetExportSessionStatusCompleted");
            [exportSession cancelExport];
            block();
        } else if (AVAssetExportSessionStatusFailed == exportSession.status) {
            // a failure may happen because of an event out of your control
            // for example, an interruption like a phone call comming in
            // make sure and handle this case appropriately
            NSLog(@"AVAssetExportSessionStatusFailed %@",     exportSession.error);
        } else {
            NSLog(@"Export Session Status: %d", exportSession.status);
        }
    }];
    
    }];
    
    return TRUE;
}

- (AVAssetWriterInput *)appendAudioInputForWriter:(AVAssetWriter *)writer
{
    NSDictionary *audioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                [ NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                [ NSNumber numberWithFloat: 44100], AVSampleRateKey,
                [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                nil];
    
   /* NSMutableDictionary* audioSettings = [NSMutableDictionary dictionary];
    [audioSettings setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM]
                     forKey:AVFormatIDKey];*/
    
    AVAssetWriterInput * audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
    audioInput.expectsMediaDataInRealTime = YES;
    BOOL res = [writer canAddInput:audioInput];
    if (res)
    {
        [writer addInput:audioInput];
        
        return audioInput;
    }
    else
        return NULL;
}


- (void)prolongBGTask
{
    if (self.taskId != UIBackgroundTaskInvalid && [UIApplication sharedApplication].backgroundTimeRemaining < MAX(30, 0.02*self.startTime))
    {
        NSLog(@"Need to extend task!");
        [self enterBGMode:NULL];
    }
}

- (void)readSamples:(AVAsset *)composition
{
    NSArray * tracks = [composition tracksWithMediaType:AVMediaTypeVideo];
    
    NSError *error = nil;
    AVAssetReader * reader = [[AVAssetReader alloc]initWithAsset:composition error:&error];
    
    if (error)
        NSLog(@"Error %@",error);
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor    = nil;
    AVAssetReaderVideoCompositionOutput *videoOutput = nil;
    
    NSURL * url = [[self class]pathForResultVideo];
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:url
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    if (error)
        NSLog(@"Error %@",error);
    
    if (tracks)
    {
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings =
    [NSDictionary dictionaryWithObject:value forKey:key];
 
    
        videoOutput = [[AVAssetReaderVideoCompositionOutput alloc]initWithVideoTracks:tracks  videoSettings:videoSettings];
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:composition];
    videoOutput.videoComposition = videoComposition;
    
    
    
    
    CGSize  size =  [tracks.lastObject naturalSize];
    
    
    NSParameterAssert(videoWriter);
    
    videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   @(size.width), AVVideoWidthKey,
                                   @(size.height), AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeVideo
                                            outputSettings:videoSettings];
    
    NSDictionary *pixelBufferAttributes = @{
                                            (NSString*)kCVPixelBufferCGImageCompatibilityKey : [NSNumber numberWithBool:YES],
                                            (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey : [NSNumber numberWithBool:YES],
                                            (NSString*)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                            };
    adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:pixelBufferAttributes];
    
    videoWriterInput.transform = [tracks.lastObject preferredTransform];
    
    
        AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        passThroughInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [composition duration]);
        
        AVAssetTrack *videoTrack = [composition tracksWithMediaType:AVMediaTypeVideo][0];
        AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        passThroughInstruction.layerInstructions = @[passThroughLayer];
        videoComposition.instructions = @[passThroughInstruction];
        
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    [videoWriter addInput:videoWriterInput];
    
    
    if ([reader canAddOutput:videoOutput])
        [reader addOutput:videoOutput];
    }
    
    NSArray * audioTracks = [composition tracksWithMediaType:AVMediaTypeAudio];
    
    AVAssetReaderAudioMixOutput * audioOutput = nil;
    AVAssetWriterInput * audioWriterInput = nil;
    
    if (audioTracks)
    {
        audioWriterInput =[self appendAudioInputForWriter:videoWriter];
        
        audioOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:audioTracks audioSettings:nil];
    
        if ([reader canAddOutput:audioOutput])
            [reader addOutput:audioOutput];
    }
    
    CMTime duration = composition.duration;//CMTimeMakeWithSeconds(1.5, 1);//composition.duration;
    
    reader.timeRange = CMTimeRangeMake(kCMTimeZero, duration);
    
    
    dispatch_queue_t queue = dispatch_queue_create("coolvideoprocessor.processvideo.queue", nil);
    
    dispatch_queue_t audioQueue =  dispatch_queue_create("coolvideoprocessor.processaudio.queue", nil);
    
    BOOL status = [reader startReading];
    
    if (!status)
        NSLog(@" Status %d",reader.status);
    
    status = [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    if (!status)
        NSLog(@" Status %d",videoWriter.status);

    
    void (^terminationBlock)(AVAssetWriterInput*)  = ^(AVAssetWriterInput * writerInput)
    {
        if (reader.status == AVAssetReaderStatusCompleted)
        {
            [writerInput markAsFinished];
            
            @synchronized(self)
            {
                self.count+=1;
                
                if (self.count == 2)
                {
                    [self prolongBGTask];
                    
                    [videoWriter finishWritingWithCompletionHandler:^
                     {
                         if (videoWriter.status != AVAssetWriterStatusCompleted)
                         {
                             NSLog(@"Error %@",videoWriter.error);
                         }
                         
                         NSURL * url = videoWriter.outputURL;
                         
                         self.mergedVideo = url;
                         
                         [self leaveBGMode];
                         if ([[UIApplication sharedApplication] applicationState ] == UIApplicationStateActive)
                         {
                             [[NSNotificationCenter defaultCenter]removeObserver:self];
                             [self displayMergedVideo];
                         }
                     }];
                }
            }
        }
    };
    
    
    __block CGFloat audioPercent,videoPercent;
    
    if (!audioWriterInput)
    {
        audioPercent = 100;
    }
    
    if (!adaptor)
    {
        videoPercent = 100;
    }
    
    CGFloat totalTimeFloat = (CGFloat)duration.value/duration.timescale;
    
    [audioWriterInput requestMediaDataWhenReadyOnQueue:audioQueue usingBlock:^
    {
        [self prolongBGTask];
        while (audioWriterInput.readyForMoreMediaData)
        {
            CMSampleBufferRef sampleBuffer = [audioOutput copyNextSampleBuffer];
            
            if (sampleBuffer)
            {
#if DEBUG
                CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                CMTimeShow(presentationTime);
                
#endif
                
                CGFloat presentationTimeFloat = (CGFloat)presentationTime.value/presentationTime.timescale;
                audioPercent = presentationTimeFloat/totalTimeFloat;
                
                [self notifyAboutCurrentProgress:MIN(audioPercent,videoPercent)*100];
                
                BOOL result = [audioWriterInput appendSampleBuffer:sampleBuffer];
                
                if (result == NO) //failes on 3GS, but works on iphone 4
                {
                    NSLog(@"failed to append buffer");
                    NSLog(@"The error is %@", [videoWriter error]);
                }
            }
            else
            {
                terminationBlock(audioWriterInput);
                audioPercent = 1;
                [self notifyAboutCurrentProgress:MIN(audioPercent,videoPercent)*100];
                break;
            }
        }
    }];

    
    [adaptor.assetWriterInput requestMediaDataWhenReadyOnQueue:queue usingBlock:^
    {
        [self prolongBGTask];
        while (adaptor.assetWriterInput.readyForMoreMediaData)
        {
            //CMTime presentTime = nextPTS;
            //nextPTS = CMTimeAdd(frameDuration, nextPTS);
            
            CMSampleBufferRef sampleBuffer = [videoOutput copyNextSampleBuffer];
            
            if (sampleBuffer)
            {
                CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                [self prolongBGTask];
                CVPixelBufferRef buffer = [self applyFilter:sampleBuffer poolRef:adaptor.pixelBufferPool];
                
                CMTimeShow(presentationTime);
                
                [self prolongBGTask];
                
                CGFloat presentationTimeFloat = (CGFloat)presentationTime.value/presentationTime.timescale;
                
                videoPercent = presentationTimeFloat/totalTimeFloat;
                
                
                [self notifyAboutCurrentProgress:MIN(audioPercent,videoPercent)*100];
                
                BOOL result = buffer && [adaptor appendPixelBuffer:buffer withPresentationTime:presentationTime];
                
                CVPixelBufferRelease(buffer);
                
                if (result == NO) //failes on 3GS, but works on iphone 4
                {
                    NSLog(@"failed to append buffer");
                    NSLog(@"The error is %@", [videoWriter error]);
                }
            }
            else
            {
                terminationBlock(adaptor.assetWriterInput);
                videoPercent = 1;
                [self notifyAboutCurrentProgress:MIN(audioPercent,videoPercent)*100];
                break;
            }
        }
    }];
    
}

- (void)notifyAboutCurrentProgress:(NSUInteger)percentage
{
    NSLog(@"Current percentage %d",percentage);
    self.percentage = percentage;
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive)
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            self.pvProgress.progress = percentage/100.0;
        });
    }
    else
    {
        [UIApplication sharedApplication].applicationIconBadgeNumber = percentage;
        if (percentage && (percentage %10 == 0 || percentage == 100))
        {
            [self playSystemSound];
        }
    }
}

- (void)startInternal:(NSUInteger)index composition:(AVMutableComposition *)composition completition:(void (^)(AVAsset *))completition
{
    AVURLAsset *asset = [self getAssetAtIndex:index];
    
    [self appendTracksFromAsset:asset toComposition:composition completition:^
    {
        if (index+1 == self.dictionary.count)
        {
            if (completition)
                completition(composition);
        }
        else
            [self startInternal:index+1 composition:composition completition:completition];
    }];
    
}


- (NSUInteger)allKeysAreLoadedForAsset:(AVAsset *)asset keys:(NSArray *)keys
{
    NSUInteger subIndex = 0;
    
    for (NSString *key in keys)
    {
        NSError *error = nil;
        
        AVKeyValueStatus status = [asset statusOfValueForKey:key error:&error];
    
        if (status != AVKeyValueStatusLoaded)
        {
            if (error)
                NSLog(@"Error loading key (%@) : %@",key,error);
            break;
        }
        subIndex++;
    }
    
    return subIndex;
}

- (BOOL)appendAudioTrackAfterLoadingFromAsset:(AVAsset *)asset toComposition:(AVMutableComposition *)composition
{
    return [self appendTrack:asset toComposition:composition mediaType:AVMediaTypeAudio];
}

- (BOOL)appendTracksAfterLoadingFromAsset:(AVAsset *)asset toComposition:(AVMutableComposition *)composition
{
    if(![self appendTrack:asset toComposition:composition mediaType:AVMediaTypeAudio])
        return NO;
    
    
    if(![self appendTrack:asset toComposition:composition mediaType:AVMediaTypeVideo])
        return NO;
    
    NSLog(@"Composition duration ");
    CMTimeShow(composition.duration);
    
    return TRUE;
}

- (BOOL)appendTrack:(AVAsset *)asset toComposition:(AVMutableComposition *)composition mediaType:(NSString *const)type
{
    NSError *error = nil;
    AVAssetTrack *track = [[asset tracksWithMediaType:type]lastObject];
    AVMutableCompositionTrack * compositionTrack = [[composition tracksWithMediaType:type] lastObject];
    
    BOOL result = [compositionTrack insertTimeRange:track.timeRange ofTrack:track atTime:CMTimeAdd(compositionTrack.timeRange.start, compositionTrack.timeRange.duration) error:&error];
    
    if (!result)
    {
        if (error)
            NSLog(@"Error %@",error);
    }
    
    return result;
}


- (void)appendAudioTrackFromAsset:(AVAsset *)asset toCompositionTrack:(AVMutableComposition *)composition completition:(void (^)(void))completition
{
    NSArray *keys = @[@"tracks",@"duration",@"composable"];
    
    NSUInteger subIndex = [self allKeysAreLoadedForAsset:asset keys:keys];
    
    if (subIndex == keys.count)
    {
        if ([self appendAudioTrackAfterLoadingFromAsset:asset toComposition:composition])
        {
            if (completition)
                completition();
        }
    }
    
    NSArray *subKeys = [keys subarrayWithRange:NSMakeRange(subIndex, keys.count - subIndex)];
    
    [asset loadValuesAsynchronouslyForKeys:subKeys  completionHandler:^{
        
        NSParameterAssert(asset.isComposable);
        

        NSUInteger subIndex = [self allKeysAreLoadedForAsset:asset keys:keys];
        
        if (subIndex == keys.count) {
            
            BOOL result = [self appendAudioTrackAfterLoadingFromAsset:asset toComposition:composition];
            
            if (result) {
                
                if (completition)
                    completition();
            }
        }
        
    }];
}


- (void)appendTracksFromAsset:(AVAsset *)asset
                toComposition:(AVMutableComposition *)composition
                 completition:(void (^)(void))completition
{
    NSArray *keys = @[@"tracks",@"duration",@"composable"];
    
    NSUInteger subIndex = [self allKeysAreLoadedForAsset:asset keys:keys];
    
    if (subIndex == keys.count)
    {
        if ([self appendTracksAfterLoadingFromAsset:asset toComposition:composition])
        {
            if (completition)
                completition();
        }
    }
    
    NSArray *subKeys = [keys subarrayWithRange:NSMakeRange(subIndex, keys.count - subIndex)];
    
    [asset loadValuesAsynchronouslyForKeys:subKeys  completionHandler:^
    {
        NSUInteger subIndex = [self allKeysAreLoadedForAsset:asset keys:keys];
        
        if (subIndex == keys.count)
        {
            BOOL result = [self appendTracksAfterLoadingFromAsset:asset toComposition:composition];
            
            if (result)
            {
                
                if (completition)
                    completition();
            }
        }
        
    }];
}

-(void)executeTask
{
    //HACK:
    [self start];
    return;
    
    if ([self displayMergedVideo]) return;
    
    AVMutableComposition * composition = [AVMutableComposition composition];
    BOOL isError = FALSE;
    NSUInteger count =self.dictionary.count;
    NSUInteger index = 0;
    NSUInteger percent =0;
    for (id key in self.dictionary)
    {
        [self changeStatus:[NSString stringWithFormat:@"Processing %d video out of %d",index+1,count] percent:percent];
        
        {
            NSURL * url = (NSURL*)key;
            AVURLAsset * asset = [[AVURLAsset alloc]initWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)}];
            
            if ([self xyz:asset index:0])
            {
                return;
            }
        }
        //if (![self appendToComposition:composition key:key])
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

static NSUInteger g_index = 0;

static AVAssetReader* g_movieReader = nil;

-(BOOL)xyz:(AVURLAsset *)asset index:(NSUInteger)index
{
    BOOL postpone = FALSE;
    
    AVKeyValueStatus status = [asset statusOfValueForKey:@"tracks" error:nil];
    
    if (status != AVKeyValueStatusLoaded)
    {
        
        [asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
            NSArray * tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            
            NSParameterAssert(tracks.count == 1);
            
            
            AVAssetTrack * videoTrack = (AVAssetTrack*)[tracks lastObject];
            NSError * error = nil;
            
            [g_movieReader cancelReading];
            
            g_movieReader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
            if (error)
                NSLog(@"Error %@",error.localizedDescription);
            //AVAssetReaderOutput * readerOutput = [AVAssetReaderOutput new];
            NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
            NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
            NSDictionary* videoSettings =
            [NSDictionary dictionaryWithObject:value forKey:key];
            
            [g_movieReader addOutput:[AVAssetReaderTrackOutput
                                     assetReaderTrackOutputWithTrack:videoTrack
                                     outputSettings:videoSettings]];
            
            if (![g_movieReader startReading])
            {
                NSLog(@"Status %d, error %@",g_movieReader.status,g_movieReader.error);
            }
            else
            {
                if (g_movieReader.status == AVAssetReaderStatusReading)
                {
                    AVAssetReaderTrackOutput * output = g_movieReader.outputs.lastObject;
                    
                    NSParameterAssert(g_movieReader.outputs.count ==1);
                    //reading....
                    
                    BOOL first = FALSE;
                    
                    //creating writer...
                    CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
                    AVAssetWriterInputPixelBufferAdaptor *adaptor;
                    AVAssetWriter *videoWriter;
                    AVAssetWriterInput* writerInput;
                    NSUInteger index = 0;
                    NSURL * url = [[self class]pathForResultVideo];
                    while (sampleBuffer)
                    {
                        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                        
                        // Lock the image buffer
                        CVPixelBufferLockBaseAddress(imageBuffer,0);
                        
                        // Get information of the image
                        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
                        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
                        size_t width = CVPixelBufferGetWidth(imageBuffer);
                        size_t height = CVPixelBufferGetHeight(imageBuffer);
                        
                        //*Create a CGImageRef from the CVImageBufferRef*/
                        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
                        CGImageRef beginImage = CGBitmapContextCreateImage(newContext);
                        
                        /*We release some components*/
                        CGContextRelease(newContext); 
                        CGColorSpaceRelease(colorSpace);
                        
                        
                        //
                        //  Here's where you can process the buffer!
                        //  (your code goes here)
                        //
                        //  Finish processing the buffer!
                        //
                        
                        {
                            UIImage * inImage = [UIImage imageWithCGImage:beginImage];
                            NSLog(@"Image %@",inImage);
                        }
                        
                        UIImage * newImg = nil;//[self applyFilter:beginImage];
                        // Unlock the image buffer
                        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
                        //CMSampleBufferInvalidate(sampleBuffer);
                        CFRelease(sampleBuffer);
                        
                        
                    
                        
                        CVPixelBufferRef buffer = NULL;
                        
                        if (!first)
                        {
                            
                            
                            CGSize frameSize = newImg.size;
                            
                            NSError *error = nil;
                            videoWriter = [[AVAssetWriter alloc] initWithURL:
                                                          url fileType:AVFileTypeQuickTimeMovie
                                                                                      error:&error];
                            
                            if(error) {
                                NSLog(@"error creating AssetWriter: %@",[error description]);
                            }
                            NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           AVVideoCodecH264, AVVideoCodecKey,
                                                           [NSNumber numberWithInt:frameSize.width], AVVideoWidthKey,
                                                           [NSNumber numberWithInt:frameSize.height], AVVideoHeightKey,
                                                           nil];
                            
                            writerInput = [AVAssetWriterInput
                                                                assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                outputSettings:videoSettings];
                            
                            NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
                            [attributes setObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
                            [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.width] forKey:(NSString*)kCVPixelBufferWidthKey];
                            [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.height] forKey:(NSString*)kCVPixelBufferHeightKey];
                            
                            adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                                             assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                                             sourcePixelBufferAttributes:attributes];
                            
                            [videoWriter addInput:writerInput];
                            
                            // fixes all errors
                            writerInput.expectsMediaDataInRealTime = YES;
                            
                            //Start a session:
                            BOOL start = [videoWriter startWriting];
                            
                            if (start){
                                [videoWriter startSessionAtSourceTime:kCMTimeZero];
                                    
                                first = TRUE;
                            }
                            NSLog(@"Session started? %d", start);
                        }
                        
                                                
                       // int reverseSort = NO;
                       // NSArray *newArray = [array sortedArrayUsingFunction:sort context:&reverseSort];
                        
                        //CGFloat delta = 0.0;//1.0/[newArray count];
                        
                       //(int)fpsSlider.value;
                        
                        //int i = 0;
                       
                            if (adaptor.assetWriterInput.readyForMoreMediaData)
                            {
                                 int fps = 30;
                                
                                
                                CMTime frameTime = CMTimeMake(1, fps);
                                CMTime lastTime=CMTimeMake(index++, fps);
                                CMTime presentTime=CMTimeAdd(lastTime, frameTime);
                                
                                buffer = [self pixelBufferFromCGImage:[newImg CGImage]];
                                BOOL result = [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
                                
                                if (result == NO) //failes on 3GS, but works on iphone 4
                                {
                                    NSLog(@"failed to append buffer");
                                    NSLog(@"The error is %@", [videoWriter error]);
                                }
                                if(buffer)
                                    CVBufferRelease(buffer);
                                //[NSThread sleepForTimeInterval:0.05];
                            }
                            else
                            {
                                NSLog(@"error");
                                index--;
                            }
                            //[NSThread sleepForTimeInterval:0.02];
                        
                    
                        sampleBuffer = [output copyNextSampleBuffer];
                    }
                    //Finish the session:
                    [writerInput markAsFinished];
                    [videoWriter finishWritingWithCompletionHandler:^{
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self displayMovieByURL:url];
                        });
                    }];
                    CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
                }
                
                        
            }
             
            g_index = index+1;
        }];
        postpone = TRUE;
        
    }
    return postpone;
}

static CIContext *g_Context = nil;

- (CVPixelBufferRef)applyFilter:(CMSampleBufferRef)beginImage poolRef:(CVPixelBufferPoolRef)poolRef
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(beginImage);
    CIImage * inputImage = [CIImage imageWithCVPixelBuffer:imageBuffer];//[CIImage imageWithCGImage:beginImage options:nil];
    CFRelease(beginImage);
    CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"
                                  keysAndValues: kCIInputImageKey,  inputImage,
                        @"inputIntensity", @(0.9), nil];
    
    
    CIImage *outputImage = [filter outputImage];
    filter = nil;
    
    if (!g_Context)
        g_Context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
    
    //CIContext * context = [CIContext contextWithOptions:nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    if (CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, poolRef, &pxbuffer)!=kCVReturnSuccess)
    {
        return NULL;
    }
    
    
    [g_Context render:outputImage toCVPixelBuffer:pxbuffer];
    
    return pxbuffer;
}

-(BOOL)appendToComposition:(AVMutableComposition*)composition key:(id)key
{
    NSURL * url = (NSURL*)key;
    AVURLAsset * asset = [[AVURLAsset alloc]initWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)}];
    
    
    // calculate time
    
    NSArray * valueObj = [self.dictionary[key]lastObject];
    NSTimeInterval startTime =(NSTimeInterval)[valueObj[1] doubleValue];
    NSTimeInterval durationTime =(NSTimeInterval)[valueObj.lastObject doubleValue];
    CMTime start = CMTimeMake(startTime, 1);
    CMTime duration = CMTimeMake(durationTime, 1);
    
    CMTimeRange range = CMTimeRangeMake(start,duration);
    NSError * error = nil;
    BOOL result = [composition insertTimeRange:range ofAsset:asset atTime:composition.duration error:&error];
    
    if (error) NSLog(@"ERROR: %@",error);
    return result;
}

- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVPixelBufferCreate(kCFAllocatorDefault, CGImageGetWidth(image),
                        CGImageGetHeight(image), kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                        &pxbuffer);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, CGImageGetWidth(image),
                                                 CGImageGetHeight(image), 8, 4*CGImageGetWidth(image), rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    
    CGAffineTransform flipVertical = CGAffineTransformMake(
                                                           1, 0, 0, -1, 0, CGImageGetHeight(image)
                                                           );
    CGContextConcatCTM(context, flipVertical);
    
    CGAffineTransform flipHorizontal = CGAffineTransformMake(
                                                             -1.0, 0.0, 0.0, 1.0, CGImageGetWidth(image), 0.0
                                                             );
    
    CGContextConcatCTM(context, flipHorizontal);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

@end
