//
//  FilterSettingsBackImageCell.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 9/29/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "FilterSettingsBackImageCell.h"

NSString *const kCameraTitle  = @"Camera";
NSString *const kPictureAlbum = @"Pictures album";
NSString *const kSavedAlbum   = @"Saved album";
NSString *const kUseSelfAlbum = @"The same image";

@interface FilterSettingsBackImageCell()<UIImagePickerControllerDelegate,UIActionSheetDelegate,UINavigationControllerDelegate,UIPopoverControllerDelegate>
{
    id _pivotalObject;
    UIImagePickerControllerSourceType _pickerSourceType;
}

@property (nonatomic,readonly) UIActionSheet * currentActionSheet;
@end

@implementation FilterSettingsBackImageCell

- (UIActionSheet*)currentActionSheet
{
    UIActionSheet * actionSheet = (UIActionSheet *)_pivotalObject;
    
    if ([actionSheet isKindOfClass:[UIActionSheet class]])
    {
        return actionSheet;
    }
    return nil;
}

- (IBAction)takePicture:(id)sender
{
    NSParameterAssert(self.takePicture == sender);
    
    //UIImagePickerController * controller =
    UIActionSheet * sheet = [UIActionSheet new];
    _pivotalObject =sheet;
    sheet.title = NSLocalizedString(@"Select image taking mode", "Image taking mode!");
    
    [sheet addButtonWithTitle:kCameraTitle];
    
    //[_indexMap setObject:@"Camera" forKey:@(index)];
    
    [sheet addButtonWithTitle:kPictureAlbum];
    
    [sheet addButtonWithTitle:kSavedAlbum];
    
    [sheet setCancelButtonIndex:[sheet addButtonWithTitle:kUseSelfAlbum]];
    
    sheet.delegate = self;
    [sheet showInView: self.delegate.view];
}

#pragma mark - UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    _pivotalObject = nil;
    NSString * buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:kCameraTitle] )
    {
        _pickerSourceType = UIImagePickerControllerSourceTypeCamera;
    }
    else if ([buttonTitle isEqualToString:kPictureAlbum])
    {
        _pickerSourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    }
    else if ([buttonTitle isEqualToString:kSavedAlbum])
    {
        _pickerSourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    [self performImagePicking];
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
    _pivotalObject = nil;
    _pickerSourceType = NSIntegerMax;
    [self.delegate filterSettingsBackImageCell:self didSelectImage:nil  useTheSameImage:YES];
}

- (void)performImagePicking
{
    BOOL available = [UIImagePickerController isSourceTypeAvailable:_pickerSourceType];
    
    if (!available)
        return ;
    
    UIImagePickerController *imagePickerController = [UIImagePickerController new];
    
    imagePickerController.delegate      = self;
    imagePickerController.sourceType    = _pickerSourceType;
    imagePickerController.allowsEditing = NO;
    
    
    if (_pickerSourceType == UIImagePickerControllerSourceTypeCamera)
    {
        imagePickerController.cameraCaptureMode     = UIImagePickerControllerCameraCaptureModePhoto;
        imagePickerController.navigationBarHidden   = NO;
        imagePickerController.toolbarHidden         = YES;
        imagePickerController.wantsFullScreenLayout = YES;
        
        [self.delegate presentViewController:imagePickerController animated:YES completion:nil];
        return;
    }
    
    if (_pickerSourceType == UIImagePickerControllerSourceTypePhotoLibrary || _pickerSourceType == UIImagePickerControllerSourceTypeSavedPhotosAlbum)
    {

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            CGRect rect = _takePicture.frame;
            
            rect = [self.delegate.view convertRect:rect fromView:self];
            
           UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:imagePickerController];
            
            [popover setDelegate:self];
            [popover presentPopoverFromRect:rect inView:self.delegate.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            _pivotalObject = popover;
        }
        else
            [self.delegate presentViewController:imagePickerController animated:YES completion:nil];
        
        return;
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    _pivotalObject = nil;
    [self.delegate filterSettingsBackImageCell:self didSelectImage:nil  useTheSameImage:NO];
}

#pragma mark UIImagePickerControllerDelegate<NSObject>

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    if (!image)
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    [self imagePickerControllerDidFinishPicking:picker];
    [self.delegate filterSettingsBackImageCell:self didSelectImage:image useTheSameImage:NO];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self imagePickerControllerDidFinishPicking:picker];
}
- (void)imagePickerControllerDidFinishPicking:(UIImagePickerController *)picker
{
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
        [self.delegate dismissViewControllerAnimated:YES completion:nil];
    else if (_pivotalObject)
        [((UIPopoverController*)_pivotalObject) dismissPopoverAnimated:YES];
    else
        [self.delegate dismissViewControllerAnimated:YES completion:nil];
}


@end
