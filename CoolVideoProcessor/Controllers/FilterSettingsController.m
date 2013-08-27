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

#define NUMBER_OF_SECTIONS 1
#define DIC_SECTION 0

@interface FilterSettingsController ()<UITableViewDataSource,UITableViewDelegate,FilterSettingsScalarCellDelegate,FilterSettingsVectorCellDelegate>
@property (nonatomic,weak) IBOutlet UITableView *tableView;
@property (nonatomic,weak) IBOutlet UIImageView *imageProcessed;
@property (nonatomic,strong) NSMutableDictionary *scalarTypes;
@property (nonatomic,strong) UIBarButtonItem *doneKeyboardBarButtonItem;
@property (nonatomic,strong) UIBarButtonItem *rightBarButtonItem;
@property (nonatomic,strong) NSMutableDictionary * vectorTypes;
@property (nonatomic,strong) UITextField *activeField;
@end

@implementation FilterSettingsController

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

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    
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
    return -1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == DIC_SECTION)
    {
        NSNumber * rowPath = @(indexPath.row);
        NSDictionary* dic = (NSDictionary*)self.scalarTypes[rowPath];
        if (dic)
        {
            static NSString * scalarCellId = @"FilterSettingsScalarCell";
            
            FilterSettingsScalarCell * cell = [tableView dequeueReusableCellWithIdentifier:scalarCellId forIndexPath:indexPath];
            
            if (!cell)
            {
                cell = [[FilterSettingsScalarCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:scalarCellId];
            }
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
            static NSString * vectorCellId = @"FilterSettingsVectorCell";
            
            FilterSettingsVectorCell * cell = [tableView dequeueReusableCellWithIdentifier:vectorCellId forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            NSInteger count = [dic[@"count"]integerValue];
            NSArray * subArray = [@[@"X",@"Y",@"Z",@"W"] subarrayWithRange:NSMakeRange(0, count)];
            
            if (!cell)
            {
                cell = [[FilterSettingsVectorCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:vectorCellId cellTitles:subArray];
            }
            cell.delegate =self;
            cell.cellTitles = subArray;
            
            return cell;
        }
            
    }
    return nil;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == DIC_SECTION)
    {
        return @"Numeric parameters";
    }
    return nil;
}

- (void)setProcessedImage
{
    UIImage * resImage = [UIImage imageWithCIImage:[self.filter outputImage]];
    self.imageProcessed.image = resImage;
    //[self.imageProcessed sizeToFit];
    self.imageProcessed.contentMode = UIViewContentModeScaleToFill;
    //self.imageProcessed.contentMode = UIViewContentModeScaleAspectFill;
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
        
        if (dic)
        {
            id internalKey = dic.allKeys.lastObject;
            [self.filter setValue:number forKey:internalKey];
            [self setProcessedImage];
        }
    }
}

-(void)cell:(FilterSettingsVectorCell *)cell values:(NSArray*)values
{
    NSIndexPath * path = [self.tableView indexPathForCell:cell];
    
    if (path.section == DIC_SECTION)
    {
        NSDictionary * dic = (NSDictionary*)self.vectorTypes[@(path.row)];
        
        if (dic)
        {
            for (id key in dic.allKeys)
            {
               if (![key isEqualToString:@"count"])
               {
                   id internalKey = key;
                   
                   CIVector *vector;
                   if (values.count==1)
                   {
                       vector = [CIVector vectorWithX:[values.lastObject floatValue]];
                   }
                   else if (values.count ==2)
                   {
                                              vector = [CIVector vectorWithX:[values[0] floatValue]
                                                        Y:[values.lastObject floatValue]];
                   }
                   
                   
                   [self.filter setValue:vector forKey:internalKey];
                   [self setProcessedImage];
                   break;
               }
            }
        }
    }
    
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
