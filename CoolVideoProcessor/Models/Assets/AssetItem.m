//
//  AssetItem.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/7/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "AssetItem.h"

@implementation AssetItem

-(id)initWithURL:(NSURL *)url
{
    if (self=[super init])
    {
        _url = url;
    }
    return self;
}

-(NSString*)title
{
    return self.url.pathComponents.lastObject;
}

- (NSString *)loadTitleWithCompletitionHandler:(completitionBlock)completionHandler
{
    return self.title;
}

- (UIImage *)loadThumbnailWithCompletitionHandler:(completitionBlock)completionHandler
{
    return nil;
}

-(void)flush
{
    
}

@end
