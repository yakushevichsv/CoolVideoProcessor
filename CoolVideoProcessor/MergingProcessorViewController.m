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
#import "FileProcessor.h"
#import "AssetItem.h"

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

static AVPlayer * g_player = nil;

- (void)start
{
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [self startInternal:0 composition:composition completition:^
    {
        [self readSamples:composition];
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

- (void)readSamples:(AVMutableComposition *)composition
{
    NSArray * tracks = [composition tracksWithMediaType:AVMediaTypeVideo];
    
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings =
    [NSDictionary dictionaryWithObject:value forKey:key];
 
    NSMutableDictionary* audioSettings = [NSMutableDictionary dictionary];
    [audioSettings setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM]
                         forKey:AVFormatIDKey];
    
    AVAssetReaderVideoCompositionOutput *videoOutput = [[AVAssetReaderVideoCompositionOutput alloc]initWithVideoTracks:tracks  videoSettings:nil];
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:composition];
    videoOutput.videoComposition = videoComposition;
    
    NSError *error = nil;
    NSURL * url = [[self class]pathForResultVideo];
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:url
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    CGSize  size =  composition.naturalSize;
    
    if (error)
        NSLog(@"Error %@",error);
    
    NSParameterAssert(videoWriter);
    
    videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   @(size.width), AVVideoWidthKey,
                                   @(size.height), AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeVideo
                                            outputSettings:videoSettings];
    
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                     sourcePixelBufferAttributes:nil];
    
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    [videoWriter addInput:videoWriterInput];
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    
    
    AVAssetReader * reader = [[AVAssetReader alloc]initWithAsset:composition error:nil];
    
    if ([reader canAddOutput:videoOutput])
        [reader addOutput:videoOutput];
    
    /*if ([reader canAddOutput:audioOutput])
        [reader addOutput:audioOutput];*/
    
    reader.timeRange = CMTimeRangeMake(kCMTimeZero, composition.duration);
    
    BOOL status = [reader startReading];
    
    if (!status)
        NSLog(@" Status %d",reader.status);
    
        dispatch_queue_t queue = dispatch_queue_create("coolvideoprocessor.processvideo.queue", nil);
    
    [adaptor.assetWriterInput requestMediaDataWhenReadyOnQueue:queue usingBlock:^
    {
        while (adaptor.assetWriterInput.readyForMoreMediaData)
        {
            //CMTime presentTime = nextPTS;
            //nextPTS = CMTimeAdd(frameDuration, nextPTS);
            
            CMSampleBufferRef sampleBuffer = [videoOutput copyNextSampleBuffer];
            
            if (sampleBuffer)
            {
                CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                
                CVPixelBufferRef buffer = [self applyFilter:sampleBuffer poolRef:adaptor.pixelBufferPool];
                
                CMTimeShow(presentationTime);
                
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
                if (reader.status == AVAssetReaderStatusCompleted)
                {
                    //[reader cancelReading];
                    [adaptor.assetWriterInput markAsFinished];
                    
                    [videoWriter finishWritingWithCompletionHandler:^
                     {
                         if (videoWriter.status != AVAssetWriterStatusCompleted)
                         {
                             NSLog(@"Error %@",videoWriter.error);
                         }
                         
                         NSURL * url = videoWriter.outputURL;
                         AVURLAsset * asset2 = [[AVURLAsset alloc]initWithURL:url  options:nil];
                         
                         static NSString * tracks = @"tracks";
                         [asset2 loadValuesAsynchronouslyForKeys:@[tracks] completionHandler:^
                         {
                            NSError *error = nil;
                             if ([asset2 statusOfValueForKey:tracks error:&error] == AVKeyValueStatusLoaded)
                             {
                                 
                                 AVMutableCompositionTrack *videoTrack = [composition tracksWithMediaType:AVMediaTypeVideo].lastObject;
                                 
                                 [composition removeTrack:videoTrack];
                                 
                                 videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
                                 
                                 if (![videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset2.duration) ofTrack:[[asset2 tracksWithMediaType:AVMediaTypeVideo]lastObject] atTime:kCMTimeZero error:&error])
                                 {
                                     NSLog(@"Error %@",error);
                                 }
                                 NSURL * url2 = [[self class]pathForResultVideo];
                                 [self exportComposition:composition filePath:url2.path block:^
                                 {
                                     [self displayMovieByURL:url2];
                                     [[NSFileManager defaultManager]removeItemAtURL:url error:nil];
                                 }];
                             }
                         }];
                     }];
                }
                break;
            }
            
            
            
        }
    }];
    
    //[self exportComposition:composition filePath:[[[self class]pathForResultVideo]path]];
    
}


- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image poolRef:(CVPixelBufferPoolRef)poolRef
{
    /*NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
     [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
     nil];*/
    CVPixelBufferRef pxbuffer = NULL;
    
    if (CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, poolRef, &pxbuffer)!=kCVReturnSuccess)
    {
        return NULL;
    }
    
    
    
    CVPixelBufferGetWidth(pxbuffer);
    /*
     CVPixelBufferCreate(kCFAllocatorDefault, CGImageGetWidth(image),
     CGImageGetHeight(image), kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
     &pxbuffer);*/
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, CVPixelBufferGetWidth(pxbuffer),
                                                 CVPixelBufferGetHeight(pxbuffer), 8, 4*CVPixelBufferGetWidth(pxbuffer), rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    
    CGAffineTransform flipVertical = CGAffineTransformMake(
                                                           1, 0, 0, -1, 0, CVPixelBufferGetWidth(pxbuffer)
                                                           );
    CGContextConcatCTM(context, flipVertical);
    
    CGAffineTransform flipHorizontal = CGAffineTransformMake(
                                                             -1.0, 0.0, 0.0, 1.0, CVPixelBufferGetHeight(pxbuffer), 0.0
                                                             );
    
    CGContextConcatCTM(context, flipHorizontal);
    CGSize size = CGSizeMake(MIN(CVPixelBufferGetWidth(pxbuffer),CGImageGetWidth(image)), MIN(CVPixelBufferGetHeight(pxbuffer),CGImageGetHeight(image)));
    CGContextDrawImage(context, CGRectMake(0, 0, size.width,
                                           size.height), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}


- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image size:(CGSize)size
{
    
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                                 [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                                 nil];
        CVPixelBufferRef pxbuffer = NULL;
        
        CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                              size.width,
                                              size.height,
                                              kCVPixelFormatType_32ARGB,
                                              (__bridge CFDictionaryRef) options,
                                              &pxbuffer);
        if (status != kCVReturnSuccess){
            NSLog(@"Failed to create pixel buffer");
        }
        
        CVPixelBufferLockBaseAddress(pxbuffer, 0);
        void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
        
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                     size.height, 8, 4*size.width, rgbColorSpace,
                                                     kCGImageAlphaPremultipliedFirst);
        //kCGImageAlphaNoneSkipFirst);
        CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
        CGContextDrawImage(context, CGRectMake(0, 0, size.width,
                                               size.height), image);
        CGColorSpaceRelease(rgbColorSpace);
        CGContextRelease(context);
        
        CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
        
        return pxbuffer;
}


- (void)startInternal:(NSUInteger)index composition:(AVMutableComposition *)composition completition:(void (^)(void))completition
{
    AVURLAsset *asset = [self getAssetAtIndex:index];
    
    [self appendTracksFromAsset:asset toComposition:composition completition:^
    {
        if (index+1 == self.dictionary.count)
        {
            if (completition)
                completition();
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

- (BOOL)appendAudioTrackAfterLoadingFromAsset:(AVAsset *)asset toCompositionTrack:(AVMutableCompositionTrack *)compositionTrack
{
    AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio]lastObject];
    
    if (audioTrack)
    {
        return [self appendTrack:audioTrack toCompositionTrack:compositionTrack];
    }
    return TRUE;
}

- (BOOL)appendTracksAfterLoadingFromAsset:(AVAsset *)asset toComposition:(AVMutableComposition *)composition
{
    AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio]lastObject];
    AVMutableCompositionTrack * compositionTrack = [[composition tracksWithMediaType:AVMediaTypeAudio] lastObject];
    
    if (audioTrack)
    {
        if(![self appendTrack:audioTrack toCompositionTrack:compositionTrack])
            return NO;
    }
    
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]lastObject];
    compositionTrack = [[composition tracksWithMediaType:AVMediaTypeVideo] lastObject];
    
    if (videoTrack)
    {
        if(![self appendTrack:videoTrack toCompositionTrack:compositionTrack])
            return NO;
    }
    
    return TRUE;
}

- (BOOL)appendTrack:(AVAssetTrack * )track toCompositionTrack:(AVMutableCompositionTrack *)compositionTrack
{
    NSError *error = nil;
    CMTimeRange range = compositionTrack.timeRange;
    CMTime endTime = CMTimeAdd(range.start, range.duration);
    
    BOOL result = [compositionTrack insertTimeRange:track.timeRange ofTrack:track atTime:endTime error:&error];
    if (!result) {
        if (error)
            NSLog(@"Error %@",error);
    }
    
    return result;
}


- (void)appendAudioTrackFromAsset:(AVAsset *)asset toCompositionTrack:(AVMutableCompositionTrack *)compositionTrack completition:(void (^)(void))completition
{
    NSArray *keys = @[@"tracks",@"duration"];
    
    NSUInteger subIndex = [self allKeysAreLoadedForAsset:asset keys:keys];
    
    if (subIndex == keys.count)
    {
        if ([self appendAudioTrackAfterLoadingFromAsset:asset toCompositionTrack:compositionTrack])
        {
            if (completition)
                completition();
        }
    }
    
    NSArray *subKeys = [keys subarrayWithRange:NSMakeRange(subIndex, keys.count - subIndex)];
    
    [asset loadValuesAsynchronouslyForKeys:subKeys  completionHandler:^{
        
        NSUInteger subIndex = [self allKeysAreLoadedForAsset:asset keys:keys];
        
        if (subIndex == keys.count) {
            
            BOOL result = [self appendAudioTrackAfterLoadingFromAsset:asset toCompositionTrack:compositionTrack];
            
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
    NSArray *keys = @[@"tracks",@"duration"];
    
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
