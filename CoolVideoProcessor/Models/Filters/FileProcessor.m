//
//  FileProcessor.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 9/14/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "FileProcessor.h"
#import "ALAssetItem.h"
#import "UIImage+Scale.h"

@implementation ProcessingImageInfo
@end

@interface FileProcessor()
{
    dispatch_queue_t queue;
    void (^terminateBlock)(NSURL* url);
    __strong NSArray *inputArray;
}

@property (nonatomic,strong) NSMutableArray *fullImages;
@end

@implementation FileProcessor

- (void)dealloc
{
    queue = nil;
}

-(id)init
{
    if (self =[super init])
    {
        queue = dispatch_queue_create("coolvideoprocessor.fileprocessor.queue", nil);
        self.fullImages = [NSMutableArray array];
    }
    return self;
}
- (NSURL *)pathForTemproraryMovie
{
    return [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"mov"]]];
}


- (CGSize)findMaxSizeInArray:(NSArray *)array
{
    CGSize retSize = CGSizeZero;
    for (ProcessingImageInfo *info in array)
    {
        if (CGSizeEqualToSize(retSize, CGSizeZero))
        {
           retSize = info.item.image.size;
        }
        
        if (info.item.image.size.width > retSize.width)
            retSize.width = info.item.image.size.width;
        
        if (info.item.image.size.height > retSize.height)
            retSize.height = info.item.image.size.height;
    }
    return retSize;
}

- (CVPixelBufferRef) pixelBufferFromImage: (UIImage *)inImage  size:(CGSize)size {
    
    CGImageRef image = inImage.CGImage;
    
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
    
    CGFloat x = 0*MAX((CGImageGetWidth(image)-size.width)*0.5,0);
    CGFloat y = 0*MAX((CGImageGetHeight(image)-size.height)*0.5,0);
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(x, y, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

-(void)loadFullResolutionImages
{
    for (ProcessingImageInfo * info in inputArray)
    {
        AssetItem * assetItem = info.item;
        if (assetItem.mediaType ==AssetItemMediaTypeImage)
        {
            if (assetItem.type == AssetItemTypeAL )
            {
                ALAssetItem *al = (ALAssetItem*)assetItem;
        
                [al loadImageWithCompletitionHandler:^(UIImage *image) {
                    if (image)
                    {
                        [self.fullImages addObject:image];
                        
                        if (self.fullImages.count == inputArray.count)
                        {
                            [self applyFiltersInternal];
                        }
                    }
                }];
            }
        }
    }
}

-(void)applyFiltersInternal
{
    CGSize screenSize = CGSizeMake(400, 200);//[self findMaxSizeInArray:array];
    
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
                                   [NSNumber numberWithInt:screenSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:screenSize.height], AVVideoHeightKey,
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
    //__block CMTime prevTime = kCMTimeZero;
    NSUInteger fps =30;
    //CMTime fpsTime = CMTimeMakeWithSeconds(1.0/fps, 1);
    
    
    [adaptor.assetWriterInput requestMediaDataWhenReadyOnQueue:queue usingBlock:^{
        while ([adaptor.assetWriterInput isReadyForMoreMediaData])
        {
            ProcessingImageInfo * imageInfo =  index < inputArray.count ?
            inputArray[index] : nil;
            
            
            if (imageInfo)
            {
                
                UIImage *resImage = [self applyFitlerOnInfo:imageInfo withImage:self.fullImages[index]];
                //CGFloat x1,y1;
                //x1 = screenSize.height;
                //y1 = screenSize.width;
                CGSize screenSize1 = CGSizeMake(400,200);//(y1, x1);
                resImage = [resImage scaleToSizeWithAspectRatio:screenSize1];
                
                CVPixelBufferRef nextSampleBuffer = [self pixelBufferFromImage:resImage size:screenSize1];
                
                //Float64 seconds = CMTimeGetSeconds(imageInfo.timeRange);
                //CMTime frameDuration = CMTimeMultiplyByFloat64(fpsTime, seconds);
                //CMTime frameTime = CMTimeAdd(prevTime, frameDuration);
                
                CMTime frameTime = CMTimeMake(index*fps*CMTimeGetSeconds(imageInfo.timeRange),(int32_t) fps);
                
                [adaptor appendPixelBuffer:nextSampleBuffer withPresentationTime:frameTime];
                CFRelease(nextSampleBuffer);
                //prevTime = frameTime;
                index++;
            }
            else
            {
                [adaptor.assetWriterInput markAsFinished];
                [videoWriter finishWritingWithCompletionHandler:^{
                    terminateBlock(videoOutputPath);
                }];
                break;
            }
        }
    }];
}

- (void)applyFiltersToArray:(NSArray *)array withCompletition:(void (^)(NSURL* url))completitionBlock
{
     if (!array.count)
         return ;
    
    
    inputArray = array;
    terminateBlock = completitionBlock;
    
    [self loadFullResolutionImages];
    
    
    
}

-(UIImage *)applyFitlerOnInfo:(ProcessingImageInfo *)info withImage:(UIImage*)image
{
    return [self applyFilter:image ?: info.item.image withFilter:info.filter];
}

-(UIImage *)applyFilter:(UIImage *)beginImage withFilter:(CIFilter *)filter
{
    
#warning Returning without filtration
    
    return beginImage;
    
    CIImage * tempImage = [CIImage imageWithCGImage:beginImage.CGImage];
    
    [filter setValue:tempImage forKey:kCIInputImageKey];
    
    CIImage *outputImage = filter.outputImage;
    UIImage * newImg = [UIImage imageWithCIImage:outputImage];
    return newImg;
}


@end
