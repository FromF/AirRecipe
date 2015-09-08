//
//  PostInstagram.h
//  AirRecipe
//
//  Created by Fuji on 2015/09/08.
//  Copyright (c) 2015年 FromF. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PostInstagram : UIViewController <UIDocumentInteractionControllerDelegate>
{
    UIDocumentInteractionController *interactionCotroller;
}

+ (BOOL)canInstagramOpen;
- (void)setImage:(UIImage *)image;
- (void)setImageData:(NSData *)imageData;

@property (nonatomic,retain) UIDocumentInteractionController *interactionController;

@end
