//
//  FilterSettingsVectorCell.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 8/25/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "FilterSettingsVectorCell.h"

@interface FilterSettingsVectorCell()<UITextFieldDelegate>
@property (nonatomic,strong) NSMutableDictionary * dic;
@end

@implementation FilterSettingsVectorCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier cellTitles:(NSArray *)cellTitles
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.cellTitles = cellTitles;
        self.dic = [NSMutableDictionary dictionary];
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

-(UIView*)columnWithTitle:(NSString*)title
{
    return [self columnWithTitle:title atPoint:CGPointZero];
}

static NSUInteger g_count = 0;

-(UIView*)columnWithTitle:(NSString*)title atPoint:(CGPoint)point
{
    CGSize size = [title sizeWithFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];
    
    UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(point.x, point.y, size.width, size.height)];
    label.text = title;
    
    CGFloat xNext = CGRectGetMaxX(label.frame) + 5;
    CGRect frame =  {.origin =CGPointMake(xNext, point.y),.size ={100,MAX(size.height,20)}};
    
    UITextField * field =[[UITextField alloc]initWithFrame:frame];
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.returnKeyType = UIReturnKeyDone;
    field.keyboardType = UIKeyboardTypeDecimalPad;

    field.delegate = self;
    field.tag = g_count;
    frame = (CGRect){.origin = point, .size = {CGRectGetMaxX(field.frame)-point.x,CGRectGetHeight(label.frame)}};
    UIView * view = [[UIView alloc]initWithFrame:frame];
    [view addSubview:field];
    [view addSubview:label];
    return view;
}

- (CGSize)generateSizeForTitles:(NSArray *)titles
{
    CGFloat w = CGRectGetWidth(self.frame);
    
    return [self generateSizeForTitles:titles andWidth:w];
}

static CGSize marginSize={10.0,10.0};

-(CGSize)generateSizeForTitles:(NSArray *)titles andWidth:(CGFloat)width
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
    g_count = 0;
    for (NSString * title in self.cellTitles)
    {
        UIView * view = [self columnWithTitle:title atPoint:point];
        g_count++;
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

#pragma mark -UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField;  
{
    [textField resignFirstResponder];
    return YES;
}


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [self.delegate cell:self didActivateTextField:textField];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self.delegate cell:self willDeactivateTextField:textField];
    
    NSUInteger countBefore = textField.tag -1;
    NSMutableArray * array = [NSMutableArray arrayWithCapacity:g_count];
    
    for (NSUInteger i=0;i<=countBefore;i++)
    {
        UITextField * curTextField =(UITextField *)[textField viewWithTag:@(i)];
        [array addObject:curTextField.text];
    }
    [array addObject:textField.text];
    for (NSUInteger i=countBefore+1;i<g_count;i++)
    {
        UITextField * curTextField =(UITextField *)[textField viewWithTag:@(i)];
        [array addObject:curTextField.text];
    }
    
    [self.delegate cell:self values:array];
}

@end
