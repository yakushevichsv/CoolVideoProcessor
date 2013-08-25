//
//  FilterSettingsVectorCell.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 8/25/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "FilterSettingsVectorCell.h"

@implementation FilterSettingsVectorCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier cellTitles:(NSArray *)cellTitles
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.cellTitles = cellTitles;
    }
    return self;
}

-(void)setCellTitles:(NSArray *)cellTitles
{
    if (![_cellTitles isEqualToArray:cellTitles])
    {
        _cellTitles = cellTitles;
        [self constractView];
        
        
        NSArray *userInfo = [NSArray arrayWithObjects:@(140),@(200),nil];
        
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(exec:) userInfo:userInfo repeats:NO];
    }
}

-(void)exec:(NSNotification*)notification
{
    NSArray *array = (NSArray*)notification.userInfo;
    
    [self.delegate cell:self values:array];
}

+(UIView*)columnWithTitle:(NSString*)title
{
    return [self columnWithTitle:title atPoint:CGPointZero];
}

+(UIView*)columnWithTitle:(NSString*)title atPoint:(CGPoint)point
{
    CGRect frame =  {.origin =point,.size ={30,50}};
    UITextField * field =[[UITextField alloc]initWithFrame:frame];
    CGFloat xNext = CGRectGetMaxX(field.frame) + 5;
    
    CGSize size = [title sizeWithFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];
    
    UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(xNext, point.y, size.width, size.height)];
    label.text = title;
    
    frame = (CGRect){.origin = point, .size = {CGRectGetMaxX(label.frame)-point.x,CGRectGetHeight(label.frame)}};
    UIView * view = [[UIView alloc]initWithFrame:frame];
    [view addSubview:field];
    [view addSubview:label];
    return view;
}

- (CGSize)generateSizeForTitles:(NSArray *)titles
{
    CGFloat w = CGRectGetWidth(self.frame);
    
    return [[self class]generateSizeForTitles:titles andWidth:w];
}

static CGSize marginSize={10.0,10.0};

+(CGSize)generateSizeForTitles:(NSArray *)titles andWidth:(CGFloat)width
{
    UIView * view = [self columnWithTitle:titles[0]];
    CGFloat xSize,ySize;
    
    const CGFloat yAdd =  CGRectGetHeight(view.frame) + marginSize.height;
    const CGFloat xAdd =  CGRectGetWidth(view.frame)  + marginSize.width;
    
    NSUInteger n = width/(xAdd - 1);
    
    xSize = xAdd;
    ySize = yAdd;
    
    for (NSUInteger i=1;i<titles.count;i++)
    {
        if (i == n)
        {
            ySize  +=yAdd;
        }
        if (i <=n)
        {
            xSize +=xAdd;
        }
    }
    
    return CGSizeMake(xSize, ySize);
}

- (void)constractView
{
    const CGSize size = [self generateSizeForTitles:self.cellTitles];
    
    if (size.height > CGRectGetHeight(self.frame))
    {
        CGRect rect = self.frame;
        rect.size.height  = size.height;
        self.frame = rect;
    }
    
    CGPoint point = CGPointZero;
    
    for (NSString * title in self.cellTitles)
    {
        UIView * view = [[self class]columnWithTitle:title atPoint:point];
        
        if (CGRectGetMaxX(view.frame)+marginSize.width >size.width)
        {
            point.x = 0;
            point.y +=size.height*0.5;
        }
        else
        {
            point.x+=CGRectGetMaxX(view.frame)+marginSize.width;
        }
        [self.contentView addSubview:view];
    }
}

@end
