//
//  ShootingSequence.h
//  AirRecipe
//
//  Created by Fuji on 2015/06/17.
//  Copyright (c) 2015年 FromF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OLYCameraKit/OLYCamera.h>
#import <OLYCameraKit/OACentralConfiguration.h>

@interface ShootingSequence : NSObject

-(void)takePictureHDR:(OLYCamera *)camera;

@end
