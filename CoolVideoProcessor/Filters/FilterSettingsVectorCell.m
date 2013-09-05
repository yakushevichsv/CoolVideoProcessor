//
//  FilterSettingsVectorCell.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 8/25/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "FilterSettingsVectorCell.h"

@interface FilterSettingsVectorCell()<UITextFieldDelegate>
{
    __strong CIVector * _cellValues;
}
@property (nonatomic,strong) NSMutableDictionary * dic;
@property (nonatomic,strong) NSMutableArray * rects;
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
        if (cellTitles)
            [self constractView];
        
            [self initValuesOfTextFields];
       // NSArray *userInfo = [NSArray arrayWithObjects:@(140),@(200),nil];
        
        //[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(exec:) userInfo:userInfo repeats:NO];
    }
}


-(void)setCellValues:(CIVector *)cellValues
{
    if (![_cellValues isEqual:cellValues])
    {
        _cellValues = cellValues;
        
        
        [self initValuesOfTextFields];
        
    }
}

-(void)initValuesOfTextFields
{
    if (_cellValues && self.cellTitles.count == _cellValues.count)
    {
        
        NSUInteger count =  MIN(_cellValues.count,self.cellTitles.count);
        NSUInteger index = 0;
        for (UIView * tempView in self.contentView.subviews)
        {
            for (UITextField * textView in tempView.subviews)
            if ([textView isKindOfClass:[UITextField class]])
            {
                textView.text = [NSString stringWithFormat:@"%.2f", [_cellValues valueAtIndex:index]];
                index++;
                
                if (index == count)
                    return;
            }
        }
    }
}

-(CIVector*)getValues
{
    CGFloat *floatPtr =(CGFloat*)malloc(sizeof(CGFloat)*self.cellTitles.count);
    CGFloat *initFloatPtr=floatPtr;
    for (UIView * tempView in self.contentView.subviews)
    {
        for (UITextField * textView in tempView.subviews)
        if ([textView isKindOfClass:[UITextField class]])
        {
            CGFloat floatVal = [textView.text floatValue];
            *floatPtr = floatVal;
            floatPtr++;
        }
    }
    CIVector * vector = [CIVector vectorWithValues:initFloatPtr count:sizeof(floatPtr)/sizeof(floatPtr[0])];
    _cellValues = vector;
    free(initFloatPtr);
    
    return vector;
}

- (UIView *)columnWithTitle:(NSString*)title
{
    return [self columnWithTitle:title atPoint:CGPointZero];
}

- (UIView *)columnWithTitle:(NSString*)title atPoint:(CGPoint)point
{
    CGSize size = [title sizeWithFont:[UIFont systemFontOfSize:18]];
    
    UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(point.x, point.y, size.width, size.height)];
    label.text = title;
    
    CGFloat xNext = CGRectGetMaxX(label.frame) + 5;
    CGRect frame =  {.origin =CGPointMake(xNext, point.y),.size ={80,MIN(size.height*1.5,CGRectGetHeight(self.frame))}};
    
    UITextField * field =[[UITextField alloc]initWithFrame:frame];
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.returnKeyType = UIReturnKeyDone;
    field.keyboardType = UIKeyboardTypeDecimalPad;
    field.font = [UIFont systemFontOfSize:18];
    field.delegate = self;
    
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
    self.rects = [NSMutableArray arrayWithCapacity:self.cellTitles.count];
    for (NSString * title in self.cellTitles)
    {
        UIView * view = [self columnWithTitle:title atPoint:point];
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
        
        for (UITextField * field in view.subviews)
        {
            if ([field isKindOfClass:[UITextField class]])
            {
                CGRect curFrame = [self.contentView convertRect:field.frame fromView:view];
                [self.rects addObject:@[NSStringFromCGRect(curFrame),field]];
            }
        }
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    for (NSArray *arr in self.rects)
    {
        UITextField *field = arr.lastObject;
        NSString *str = arr[0];
        CGRect rect = CGRectFromString(str);
        
        if (CGRectContainsPoint(rect, point))
        {
            [field becomeFirstResponder];
            return TRUE;
        }
    }
    return FALSE;
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

    [self.delegate cell:self withVector:[self getValues]];
}

@end
