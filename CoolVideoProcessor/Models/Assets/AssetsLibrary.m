//
//  AssetsLibrary.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/7/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "AssetsLibrary.h"

@implementation AssetsLibrary

#pragma mark - Static methods

+(void)exportComposition:(AVMutableComposition*)composition aURL:(NSURL*)url competition:(alCompletitionBlock)competition
{
    
    NSArray * exportPresets = @[AVAssetExportPresetHighestQuality,AVAssetExportPresetMediumQuality,AVAssetExportPresetLowQuality];
    
    
    
    NSArray * presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:composition];
    
    AVAssetExportSession *exportSession;
    
    for (NSString * curPreset in exportPresets)
    {
        if ([presets containsObject:curPreset])
        {
            exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:curPreset];
            
    
            exportSession.outputURL = url;
            exportSession.outputFileType = @"com.apple.quicktime-movie"; //TODO: figure out if it is movie asset, or audio..
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch (exportSession.status) {
            case AVAssetExportSessionStatusFailed:{
                NSLog (@"FAIL");
                
                NSError * error =  exportSession.error;
                dispatch_async(dispatch_get_main_queue(), ^{
                    competition(error);
                });
                break;
            }
            case AVAssetExportSessionStatusCompleted: {
                NSLog (@"SUCCESS");
                dispatch_async(dispatch_get_main_queue(), ^{
                    competition(nil);
                });
                break;
            }
        };
    }];
            return;
        }
    }
    NSLog(@"Preset is not supported!");
}

+(void)exportComposition:(AVMutableComposition*)composition atPath:(NSString*)path competition:(alCompletitionBlock)competition
{
    [self exportComposition:composition aURL:[NSURL URLWithString:path] competition:competition];
}

@end
