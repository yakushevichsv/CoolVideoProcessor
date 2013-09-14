//
//  FileProcessor.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 9/14/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "FileProcessor.h"

@interface FileProcessor()
{
    dispatch_queue_t queue;
}
@end

@implementation FileProcessor

-(id)init
{
    if (self =[super init])
    {
        queue = dispatch_queue_create("coolvideoprocessor.fileprocessor.queue", nil);
    }
    return self;
}
- (NSURL *)pathForTemproraryMovie
{
    return [NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"mov"]]];
}

- (CGSize)findMinSizeInArray:(NSArray *)array
{
    CGSize retSize = CGSizeZero;
    for (ProcessingImageInfo *info in array)
    {
        if (CGSizeEqualToSize(retSize, CGSizeZero))
        {
           retSize = info.image.size;
        }
        
        if (info.image.size.width < retSize.width)
            retSize.width = info.image.size.width;
        
        if (info.image.size.height < retSize.height)
            retSize.height = info.image.size.height;
    }
    return retSize;
}

- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image  size:(CGSize)size {
    
    
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

- (void)applyFiltersToArray:(NSArray *)aray withCompletition:(void (^)(NSURL* url))completitionBlock
{
     if (!aray.count)
         return ;
    
    CGSize minSize = [self findMinSizeInArray:aray];
    
    NSError *error;
    NSURL * videoOutputPath = [self pathForTemproraryMovie];
    
    NSLog(@"Start building video from defined frames.");
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                  videoOutputPath
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:minSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:minSize.height], AVVideoHeightKey,
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

    __block NSUInteger index = 0;
    __block CMTime prevTime = kCMTimeZero;
    NSUInteger fps =30;
    CMTime fpsTime = CMTimeMakeWithSeconds(1.0/fps, 1);
    
    [adaptor.assetWriterInput requestMediaDataWhenReadyOnQueue:queue usingBlock:^{
        while ([adaptor.assetWriterInput isReadyForMoreMediaData])
        {
            ProcessingImageInfo * imageInfo =  index < aray.count ?
            aray[index] : nil;
            
            
            CVPixelBufferRef nextSampleBuffer = [self pixelBufferFromCGImage:[imageInfo.image CGImage] size:imageInfo.image.size];
            
            if (nextSampleBuffer)
            {
                index++;
                Float64 seconds = CMTimeGetSeconds(imageInfo.timeRange);
                CMTime frameDuration = CMTimeMultiplyByFloat64(fpsTime, seconds);
                CMTime frameTime = CMTimeAdd(prevTime, frameDuration);
                
                [adaptor appendPixelBuffer:nextSampleBuffer withPresentationTime:frameTime];
                CFRelease(nextSampleBuffer);
                prevTime = frameTime;
            }
            else
            {
                [adaptor.assetWriterInput markAsFinished];
                [videoWriter finishWritingWithCompletionHandler:^{
                    completitionBlock(videoOutputPath);
                }];
                break;
            }
        }
    }];
    
    
    
}

@end
