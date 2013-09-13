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
                        
                        UIImage * newImg = [self applyFilter:beginImage];
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

-(UIImage*)applyFilter:(CGImageRef)beginImage
{
    CIImage * inputImage = [CIImage imageWithCGImage:beginImage options:nil];
    CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"
                                  keysAndValues: kCIInputImageKey,  inputImage,
                        @"inputIntensity", [NSNumber numberWithFloat:0.4], nil];
    
    CGImageRelease(beginImage);
    
    
    CIImage *outputImage = [filter outputImage];
    
    return [UIImage imageWithCIImage:outputImage];
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
