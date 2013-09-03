//
//  FilterSettingsController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/28/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "FilterSettingsController.h"
#import "FilterSettingsScalarCell.h"
#import "FilterSettingsVectorCell.h"
#import "FilterSettingsImageCell.h"

#define NUMBER_OF_SECTIONS 2
#define DIC_SECTION 1
#define IMAGE_SECTION 0
#define DEFAULT_HEIGHT 52.0
#define SCALAR_H_KEY @"1"
#define VECTOR_H_KEY @"2"
#define DEFAULT_H_KEY @"3"
#define IMAGE_H_KEY @"4"

static NSDictionary * g_Height;

@interface FilterSettingsController ()<UITableViewDataSource,UITableViewDelegate,FilterSettingsScalarCellDelegate,FilterSettingsVectorCellDelegate>
@property (nonatomic,weak) IBOutlet UITableView *tableView;
@property (nonatomic,strong) NSMutableDictionary *scalarTypes;
@property (nonatomic,strong) UIBarButtonItem *doneKeyboardBarButtonItem;
@property (nonatomic,strong) UIBarButtonItem *rightBarButtonItem;
@property (nonatomic,strong) NSMutableDictionary * vectorTypes;
@property (nonatomic,strong) UITextField *activeField;
@end

@implementation FilterSettingsController

+(void)initialize
{
    g_Height =@{DEFAULT_H_KEY: @(DEFAULT_HEIGHT),VECTOR_H_KEY:@(DEFAULT_HEIGHT), SCALAR_H_KEY:@(DEFAULT_HEIGHT),IMAGE_H_KEY:@(149.0)};
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setup];
    }
    return self;
}

-(void)setup
{
    self.scalarTypes  = [NSMutableDictionary dictionary];
    self.vectorTypes = [NSMutableDictionary dictionary];
}

-(void)processSettings
{
    NSDictionary *filterAttributes = [self.filter attributes];
    NSUInteger index = 0;
    for (NSString *key in filterAttributes) {
        if ([key isEqualToString:kCIAttributeFilterCategories]) continue;
        else if ([key isEqualToString:kCIAttributeFilterDisplayName]) continue;
        else if ([key isEqualToString:@"inputImage"]) continue;
        else if ([key isEqualToString:@"outputImage"]) continue;
        id valueObj = filterAttributes[key];
        if ([valueObj isKindOfClass:[NSDictionary class]])
        {
            NSDictionary * dic = (NSDictionary *)valueObj;
            id scalarType = [dic objectForKey:kCIAttributeClass];
            if ([scalarType isEqualToString:@"NSNumber"])
            {
                [self.scalarTypes setObject:@{key:filterAttributes[key]} forKey:@(index)];
                 index++;
            }
            else if ([scalarType isEqualToString:@"CIVector"])
            {
                CIVector * vector = [dic objectForKey:kCIAttributeDefault];
                [self.vectorTypes setObject:@{key:filterAttributes[key],@"count":@(vector.count)} forKey:@(index)];
                index++;
            }
            else {
                NSLog(@"Current type is %@",scalarType);
            }
            [self.filter setValue:dic[kCIAttributeDefault] forKey:key];
        }
        
    }
    
    if (self.vectorTypes.count)
    {
        [self registerForKeyboardNotifications];
    }
    
    [self setImageForFilter];
    
}

-(void)setImageForFilter
{
    CIImage * ciImage = [CIImage imageWithCGImage:self.originalImage.CGImage];
    [self.filter setValue:ciImage forKey:kCIInputImageKey];
 
}

-(void)setFilter:(CIFilter *)filter
{
    if (![_filter isEqual:filter])
    {
        _filter = filter;
        
        if (filter) [self processSettings];
    }
}

-(void)setOriginalImage:(UIImage *)originalImage
{
    if (![_originalImage isEqual:originalImage])
    {
        _originalImage = originalImage;
        
        if (originalImage)
        {
            [self setImageForFilter];
        }
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUMBER_OF_SECTIONS;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == DIC_SECTION)
    {
        return self.scalarTypes.count+self.vectorTypes.count;
    }
    else if (section == IMAGE_SECTION)
    {
        return 1;
    }
    return -1;
}

-(FilterSettingsScalarCell*)scalarCellAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString * scalarCellId = @"FilterSettingsScalarCell";
    
    FilterSettingsScalarCell * cell = [self.tableView dequeueReusableCellWithIdentifier:scalarCellId forIndexPath:indexPath];
    
    if (!cell)
    {
        cell = [[FilterSettingsScalarCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:scalarCellId];
    }
    return cell;
}

- (FilterSettingsVectorCell*)vectorCellAtIndexPath:(NSIndexPath*)
indexPath withAmount:(NSDictionary*)dic array:(NSArray**)arrayPtr
{
    static NSString * vectorCellId = @"FilterSettingsVectorCell";
    
    FilterSettingsVectorCell * cell = [self.tableView dequeueReusableCellWithIdentifier:vectorCellId forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    NSInteger count = [dic[@"count"]integerValue];
    NSArray * subArray = [@[@"X",@"Y",@"Z",@"W"] subarrayWithRange:NSMakeRange(0, count)];
    (*arrayPtr) = subArray;
    if (!cell)
    {
        cell = [[FilterSettingsVectorCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:vectorCellId cellTitles:subArray];
    }
    return cell;
}

-(FilterSettingsImageCell*)imageCellAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString * imageCellId = @"FilterSettingsImageCell";
    
    FilterSettingsImageCell * cell = [self.tableView dequeueReusableCellWithIdentifier:imageCellId forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (!cell)
    {
        cell = [[FilterSettingsImageCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageCellId];
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber * rowPath = @(indexPath.row);
    id key;
    if (indexPath.section == DIC_SECTION)
    {
        NSDictionary* dic = (NSDictionary*)self.scalarTypes[rowPath];
        if (dic)
        {
            key = SCALAR_H_KEY;
        }
        else if ((dic = (NSDictionary*)self.vectorTypes[rowPath]))
        {
            key = VECTOR_H_KEY;
        }
        else
            key = DEFAULT_H_KEY;
    }
    else if (indexPath.section == IMAGE_SECTION)
    {
        key = IMAGE_H_KEY;
    }
    else
    {
        key =DEFAULT_H_KEY;
    }
    return [g_Height[key] floatValue];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == DIC_SECTION)
    {
        NSNumber * rowPath = @(indexPath.row);
        NSDictionary* dic = (NSDictionary*)self.scalarTypes[rowPath];
        if (dic)
        {
            FilterSettingsScalarCell * cell =[self scalarCellAtIndexPath:indexPath];
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            id key = dic.allKeys.lastObject;
            
            if ([[key substringWithRange:NSMakeRange(0, @"input".length)] isEqualToString:@"input"])
            {
                cell.cellTitle.text = [key substringFromIndex:@"input".length];
            }
            
            NSDictionary* newDic = (NSDictionary*)dic[key];
            
            
            cell.slider.minimumValue = [newDic[kCIAttributeSliderMin] floatValue];
            cell.slider.maximumValue = [newDic[kCIAttributeSliderMax] floatValue];
            cell.slider.value = [newDic[kCIAttributeDefault] floatValue];
            cell.delegate =self;
            [self setProcessedImage];
            return cell;
        }
        else if ((dic = (NSDictionary*)self.vectorTypes[rowPath]))
        {
            NSArray * subArray = nil;
            FilterSettingsVectorCell * cell = [self vectorCellAtIndexPath:indexPath withAmount:dic array:&subArray];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            id key = [self firstNotCountKeyFromDic:dic];
            if (key)
            {
                NSDictionary* newDic = (NSDictionary*)dic[key];
               [cell setCellValues:newDic[kCIAttributeDefault]];
            }
            cell.delegate =self;
            cell.cellTitles = subArray;
            
            return cell;
        }
            
    }
    else if (indexPath.section==IMAGE_SECTION)
    {
        FilterSettingsImageCell * cell = [self imageCellAtIndexPath:indexPath];
        return cell;
    }
    return nil;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == DIC_SECTION)
    {
        return @"Numeric parameters";
    }
    else if (section == IMAGE_SECTION)
    {
        return @"Results of filtering";
    }
    else
        return @"";
}

- (void)setProcessedImage
{
    UIImage * resImage = [UIImage imageWithCIImage:[self.filter outputImage]];
     NSUInteger rowsNumber = [self.tableView numberOfRowsInSection:IMAGE_SECTION];
    NSUInteger values[] = {IMAGE_SECTION, rowsNumber-1 };
    NSIndexPath * path = [[NSIndexPath alloc]initWithIndexes:values length:sizeof(values)/sizeof(values[0])];
    FilterSettingsImageCell * imageCell = [self imageCellAtIndexPath:path];
    imageCell.imageView.frame=imageCell.bounds;
    imageCell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageCell.imageView.image = resImage;
}

#pragma mark - FilterSettingsVectorCellDelegate<NSObject>

-(void)cell:(FilterSettingsVectorCell *)cell didActivateTextField:(UITextField *)field
{
    _activeField = field;
}

-(void)cell:(FilterSettingsVectorCell *)cell willDeactivateTextField:(UITextField *)field
{
    _activeField = nil;
}

-(void)cell:(FilterSettingsScalarCell *)cell didChangeNumber:(NSNumber *)number
{
    NSIndexPath * path = [self.tableView indexPathForCell:cell];
    
    if (path.section == DIC_SECTION)
    {
        NSDictionary* dic = (NSDictionary*) self.scalarTypes[@(path.row)];
        
        id internalKey;
        if ((internalKey =[self firstNotCountKeyFromDic:dic]))
        {
            [self.filter setValue:number forKey:internalKey];
            [self setProcessedImage];
        }
    }
}

-(void)cell:(FilterSettingsVectorCell *)cell withVector:(CIVector *)vector
{
    NSIndexPath * path = [self.tableView indexPathForCell:cell];
    
    if (path.section == DIC_SECTION)
    {
        NSDictionary * dic = (NSDictionary*)self.vectorTypes[@(path.row)];
        id internalKey;
        if ((internalKey =[self firstNotCountKeyFromDic:dic]))
        {
            [self.filter setValue:vector forKey:internalKey];
            [self setProcessedImage];
        }
    }
    
}

-(id)firstNotCountKeyFromDic:(NSDictionary*)dic
{
    if (dic)
    {
        for (id key in dic.allKeys)
        {
            if (![key isEqualToString:@"count"])
            {
                
                return key;
            }
        }
    }
    return nil;
}

#pragma mark Keyboard code

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    
}

#pragma mark - Keyboard Notifications

-(void)initDoneButtonOnNeed
{
    if (!self.doneKeyboardBarButtonItem)
    {
        self.doneKeyboardBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneWithKeyboard)];
        self.doneKeyboardBarButtonItem.enabled = TRUE;
    }
}

-(void)doneWithKeyboard
{
    [self.view endEditing:YES];
}


- (void)keyboardWillShow:(NSNotification*)aNotification
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        self.navigationItem.rightBarButtonItem.enabled = FALSE;
        //self.tableView.contentOffset = _activeField.superview
        [self initDoneButtonOnNeed];
        _rightBarButtonItem = self.navigationItem.rightBarButtonItem;
        self.navigationItem.rightBarButtonItem = self.doneKeyboardBarButtonItem;
        self.doneKeyboardBarButtonItem.enabled = TRUE;
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
   if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
   {
    self.navigationItem.rightBarButtonItem.enabled = FALSE;
    
    self.navigationItem.rightBarButtonItem = _rightBarButtonItem;
    _rightBarButtonItem.enabled = TRUE;
       
       UIEdgeInsets contentInsets = UIEdgeInsetsZero;
       self.tableView.contentInset = contentInsets;
       self.tableView.scrollIndicatorInsets = contentInsets;
   }
}

-(void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    CGRect aRect = self.tableView.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, _activeField.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, _activeField.frame.origin.y-kbSize.height);
        [self.tableView setContentOffset:scrollPoint animated:YES];
    }
}

@end
