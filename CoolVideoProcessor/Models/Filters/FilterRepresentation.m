//
//  FilterRepresentation.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 10/13/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "FilterRepresentation.h"

@interface FilterRepresentation()
{
    __strong id filter;
}
@end

@implementation FilterRepresentation

- (CIFilter *)ciFilter
{
    return (CIFilter *)filter;
}

- (FilterRepresentationCustomFilterPtr)customFilter
{
    return (FilterRepresentationCustomFilterPtr)filter;
}

-(BOOL)isCIFilter
{
    return [filter isKindOfClass:[CIFilter class]];
}

-(BOOL)isCustomFilter
{
    return [filter isKindOfClass:[FilterRepresentationCustomFilter class]];
}


@end
