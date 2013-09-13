//
//  VideoProcessor.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 8/11/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import "VideoProcessor.h"
#import "FilterInfo.h"
#import "AssetItem.h"

 NSString * kVideoProcessorFilterAppliedNotification =@"coolvideoprocessor.filterapplied";

@interface VideoProcessor()
{
    FilterInfo * _info;
    dispatch_queue_t _queue;
}
@end

@implementation VideoProcessor

-(id)init
{
    if (self = [super init])
    {
     _queue = dispatch_queue_create("coolvideoprocessor.processvideo.queue", nil);
    }
    return self;
}

-(NSURL*)pathForVideo
{
return [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"mov"]]];
}
-(void)applyFilter:(FilterInfo *)filterInfo withCompletition:(void (^)(NSURL *))completitionBlock
{
    AVURLAsset * asset = [[AVURLAsset alloc]initWithURL:    filterInfo.item.url options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)}];
    
    NSArray *assetKeysToLoadAndTest = @[@"composable", @"tracks", @"duration",@"readable"];
    
    
    _info = filterInfo;
    
    AVKeyValueStatus status = AVKeyValueStatusUnknown;
    
    for (NSString * key in assetKeysToLoadAndTest)
    {
        status =[asset statusOfValueForKey:key error:nil];
        
        if (status != AVKeyValueStatusLoaded)
            break;
    }
    
    if (status != AVKeyValueStatusLoaded)
    {
        [asset loadValuesAsynchronouslyForKeys:assetKeysToLoadAndTest completionHandler:^{
            
            if (![asset isReadable])
            {
                NSLog(@"Asset is not readable");
                return;
            }
            NSArray * tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            
            NSParameterAssert(tracks.count == 1);
            
            
            AVAssetTrack * videoTrack = (AVAssetTrack*)[tracks lastObject];
            NSError * error = nil;
            
            AVAssetReader * reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
            
            reader.timeRange = filterInfo.range;
            
            
            if (error)
            {
                NSLog(@"Error %@",error.localizedDescription);
                completitionBlock(nil);
                return;
            }
            
            
            
            NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
            NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
            NSDictionary* videoSettings =
            [NSDictionary dictionaryWithObject:value forKey:key];
            
            AVAssetReaderTrackOutput * trackOutput =
            [AVAssetReaderTrackOutput
             assetReaderTrackOutputWithTrack:videoTrack
             outputSettings:videoSettings];
            
            if ([reader canAddOutput:trackOutput])
                [reader addOutput:trackOutput];
            else{
                NSLog(@"Error adding track output!");
            }
            
            
            /*AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            // Decompression settings for Linear PCM
            NSDictionary *decompressionAudioSettings =nil;
            // Create the output with the audio track and decompression settings.
            AVAssetReaderOutput *audioTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:decompressionAudioSettings];
            // Add the output to the reader if possible.
            if ([reader canAddOutput:audioTrackOutput])
                [reader addOutput:audioTrackOutput];*/
            
            if (![reader startReading])
                return;
            
            [self filterBufferForReader:reader completitionBlock:^(NSURL *url,AVAsset*asset) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                AVURLAsset * resAsset = [AVURLAsset assetWithURL:url];
                
                if ([resAsset statusOfValueForKey:@"tracks" error:nil] != AVKeyValueStatusLoaded)
                [resAsset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
                    
                    
                    NSError * error = nil;
                    AVMutableComposition *mixComposition = [AVMutableComposition composition];
                    AVMutableCompositionTrack *videoCompositionTrack;
                    AVMutableCompositionTrack *audioCompositionTrack;
                   
                    NSArray * tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
                    AVAssetTrack * videoTrack = (AVAssetTrack*)[tracks lastObject];
                    
                    videoCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
                    
                    audioCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                    
                    CMTime tempTime = mixComposition.duration;
                    
                    AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
                    
                    [audioCompositionTrack insertTimeRange:filterInfo.range ofTrack:audioTrack atTime:tempTime error:&error];
                    if(error)
                    {
                        NSLog(@"Ups. Something went wrong! %@", [error debugDescription]);
                    }
                    
                    [videoCompositionTrack insertTimeRange:filterInfo.range ofTrack:videoTrack atTime:tempTime error:&error];
                    if(error)
                    {
                        NSLog(@"Ups. Something went wrong! %@", [error debugDescription]);
                    }
                    
                    NSArray * presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:mixComposition];
                    
                    
                    AVAssetExportSession* exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:presets[0]];
                    
                    //exportSession.audioMix = self.mutableAudioMix;
                    exportSession.outputURL = [self pathForVideo];
                    exportSession.outputFileType=AVFileTypeQuickTimeMovie;
                    
                    [exportSession exportAsynchronouslyWithCompletionHandler:^(void){
                        switch (exportSession.status) {
                            case AVAssetExportSessionStatusCompleted:
                                completitionBlock(exportSession.outputURL);
                                [[NSNotificationCenter defaultCenter]
                                 postNotificationName:kVideoProcessorFilterAppliedNotification
                                 object:exportSession.outputURL];
                                
                                [exportSession cancelExport];
                                //TODO: place code here...
                                break;
                            case AVAssetExportSessionStatusFailed:
                                NSLog(@"Failed:%@",exportSession.error);
                                break;
                            case AVAssetExportSessionStatusCancelled:
                                NSLog(@"Canceled:%@",exportSession.error);
                                break;
                            default:
                                break;
                        }
                    }];
                }];
                });
            }];
            
        
            
        }];
                               
    }
    
}

-(void)filterBufferForReader:(AVAssetReader *)reader completitionBlock:(void (^)(NSURL *url,AVAsset * asset))completitionBlock
{
    AVAssetReaderOutput *output = nil;
    
    for (AVAssetReaderOutput * curOutput in reader.outputs)
    {
        if ([curOutput.mediaType isEqualToString:AVMediaTypeVideo])
        {
            output = curOutput;
        }
    }
    
    const NSUInteger frameRate = roundf(((AVAssetReaderTrackOutput *)output).track.nominalFrameRate);
    const CGSize frameSize = /*CGSizeMake(400, 200);*/((AVAssetReaderTrackOutput *)output).track.naturalSize;
    
         NSURL * url = [self pathForVideo];
            
            NSError *error = nil;
            AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
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
            
           AVAssetWriterInput* writerInput = [AVAssetWriterInput
                           assetWriterInputWithMediaType:AVMediaTypeVideo
                           outputSettings:videoSettings];
            
            NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
            [attributes setObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
            [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.width] forKey:(NSString*)kCVPixelBufferWidthKey];
            [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.height] forKey:(NSString*)kCVPixelBufferHeightKey];
            AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                       assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                       sourcePixelBufferAttributes:attributes];
            
            if ([videoWriter canAddInput:writerInput])
               [videoWriter addInput:writerInput];
            
            // fixes all errors
            writerInput.expectsMediaDataInRealTime = YES;
            
            //Start a session:
            BOOL start = [videoWriter startWriting];
            
            if (start){
                [videoWriter startSessionAtSourceTime:kCMTimeZero];
            }
            NSLog(@"Session started? %d", start);
    


    __block NSUInteger frameCount  =0;
    //CMTime frameDuration = CMTimeMakeWithSeconds(1/frameRate, 1);
    //__block CMTime nextPTS = kCMTimeZero;
            [adaptor.assetWriterInput requestMediaDataWhenReadyOnQueue:_queue usingBlock:^{
               
                while (adaptor.assetWriterInput.readyForMoreMediaData)
                {
                    //CMTime presentTime = nextPTS;
                    //nextPTS = CMTimeAdd(frameDuration, nextPTS);
                    
                    CMTime presentTime = CMTimeMake(frameCount, frameRate);//CMTimeMake(frameCount*frameDuration,frameRate);
                    
                    NSLog(@"Current presentation time ");
                    CMTimeShow(presentTime);
                    
                    frameCount++;
                    CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
                    
                    if (sampleBuffer)
                    {
                        UIImage *newImg = [self filteredImageFromSampleBuffer:sampleBuffer];
                        
                        CVPixelBufferRef buffer = /*[self pixelBufferFromCGImage:newImg.CGImage poolRef:adaptor.pixelBufferPool]*/
                        [self pixelBufferFromCGImage:newImg.CGImage size:frameSize];
                        ;
                        newImg = nil;
                        BOOL result = buffer && [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
                        
                        CVPixelBufferRelease(buffer);
                        
                        if (result == NO) //failes on 3GS, but works on iphone 4
                        {
                            NSLog(@"failed to append buffer");
                            NSLog(@"The error is %@", [videoWriter error]);
                        }
                    }
                    else {
                        if (reader.status == AVAssetReaderStatusCompleted)
                        {
                            [adaptor.assetWriterInput markAsFinished];
                            CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
                            [videoWriter finishWritingWithCompletionHandler:^{
                                completitionBlock(url,reader.asset);
                        
                            }];
                        }
                        break;
                    }
                        
                    
                    
                }
            }];
}

-(UIImage *)filteredImageFromSampleBuffer:(CMSampleBufferRef)buffer
{
    CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(buffer);
    
    CIImage * tempImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    ;
    UIImage *newImg = [UIImage imageWithCIImage:tempImage];
   //__block UIImage *newImg = nil;
    /*dispatch_sync(dispatch_get_main_queue(), ^{
            newImg = [self applyFilter:imageBuffer];
    });*/

    CVPixelBufferRelease(imageBuffer);
    return newImg;
}

-(UIImage *)applyFilter:(CVPixelBufferRef)beginImage
{
    CIImage * tempImage = [CIImage imageWithCVPixelBuffer:beginImage];
    
    CVPixelBufferRelease(beginImage);
    
    CIFilter * filter = _info.filter;
    [filter setValue:tempImage forKey:kCIInputImageKey];
    
    CIImage *outputImage = filter.outputImage;
    UIImage * newImg = [UIImage imageWithCIImage:outputImage];
    return newImg;
}

/*
- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image
{
    return [self pixelBufferFromCGImage:image size:[UIScreen mainScreen].bounds.size];
}*/

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
    
    /*
    CVPixelBufferCreate(kCFAllocatorDefault, CGImageGetWidth(image),
                        CGImageGetHeight(image), kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                        &pxbuffer);*/
    
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


- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image size:(CGSize)size{
    
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
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}
/*
 -(void)applyFilter:(FilterInfo *)filterInfo withCompletition:(void (^)(NSURL *))completitionBlock
 {
 AVMutableComposition *mixComposition = [AVMutableComposition composition];
 AVMutableCompositionTrack *videoCompositionTrack =[[AVMutableCompositionTrack alloc]init];
 AVMutableCompositionTrack *audioCompositionTrack =[[AVMutableCompositionTrack alloc]init];
 
 
 NSError * error;
 for(int i=0;i<moviePieces.count;i++)
 {
 NSFileManager * fm = [NSFileManager defaultManager];
 NSString * movieFilePath;
 NSString * audioFilePath;
 movieFilePath = [moviePieces objectAtIndex:i];
 audioFilePath = [audioPieces objectAtIndex:i];
 
 
 if(![fm fileExistsAtPath:movieFilePath]){
 NSLog(@"Movie doesn't exist %@ ",movieFilePath);
 }
 else{
 NSLog(@"Movie exist %@ ",movieFilePath);
 }
 
 if(![fm fileExistsAtPath:audioFilePath]){
 NSLog(@"Audio doesn't exist %@ ",audioFilePath);
 }
 else{
 NSLog(@"Audio exists %@ ",audioFilePath);
 }
 
 
 NSURL *videoUrl = [NSURL fileURLWithPath:movieFilePath];
 NSURL *audioUrl = [NSURL fileURLWithPath:audioFilePath];
 
 
 AVURLAsset *videoasset = [[AVURLAsset alloc]initWithURL:videoUrl options:nil];
 AVAssetTrack *videoAssetTrack= [[videoasset tracksWithMediaType:AVMediaTypeVideo] lastObject];
 
 AVURLAsset *audioasset = [[AVURLAsset alloc]initWithURL:audioUrl options:nil];
 AVAssetTrack *audioAssetTrack= [[audioasset tracksWithMediaType:AVMediaTypeAudio] lastObject];
 
 videoCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
 
 audioCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
 
 CMTime tempTime = mixComposition.duration;
 
 [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioasset.duration) ofTrack:audioAssetTrack atTime:tempTime error:&error];
 
 [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoasset.duration) ofTrack:videoAssetTrack atTime:tempTime error:&error];
 
 if(error)
 {
 NSLog(@"Ups. Something went wrong! %@", [error debugDescription]);
 }
 }
 
 }

 */

@end
