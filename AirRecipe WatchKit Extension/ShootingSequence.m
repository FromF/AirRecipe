//
//  ShootingSequence.m
//  AirRecipe
//
//  Created by Fuji on 2015/06/17.
//  Copyright (c) 2015年 FromF. All rights reserved.
//

#import "ShootingSequence.h"

@implementation ShootingSequence

-(void)takePictureHDR:(OLYCamera *)camera
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [camera lockAutoExposure:nil];
    [camera lockAutoFocus:^(NSDictionary *info) {
        NSLog(@"lockAutoFocus comp");
        dispatch_semaphore_signal(semaphore);
    } errorHandler:^(NSError *error) {
        NSLog(@"lockAutoFocus err");
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    [camera setCameraPropertyValue:@"EXPREV" value:@"<EXPREV/+2.0>" error:nil];
    [camera takePicture:nil progressHandler:^(OLYCameraTakingProgress progress, NSDictionary *info) {
        NSLog(@"takePicture progress");
    } completionHandler:^(NSDictionary *info) {
        NSLog(@"takePicture comp");
        dispatch_semaphore_signal(semaphore);
    } errorHandler:^(NSError *error) {
        NSLog(@"takePicture err");
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    while (camera.mediaBusy) {
        NSLog(@"media busy");
        [NSThread sleepForTimeInterval:0.5f];
    }
    [camera setCameraPropertyValue:@"EXPREV" value:@"<EXPREV/0.0>" error:nil];
    [camera takePicture:nil progressHandler:^(OLYCameraTakingProgress progress, NSDictionary *info) {
        NSLog(@"takePicture progress");
    } completionHandler:^(NSDictionary *info) {
        NSLog(@"takePicture comp");
        dispatch_semaphore_signal(semaphore);
    } errorHandler:^(NSError *error) {
        NSLog(@"takePicture err");
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    while (camera.mediaBusy) {
        NSLog(@"media busy");
        [NSThread sleepForTimeInterval:0.5f];
    }
    [camera setCameraPropertyValue:@"EXPREV" value:@"<EXPREV/-2.0>" error:nil];
    [camera takePicture:nil progressHandler:^(OLYCameraTakingProgress progress, NSDictionary *info) {
        NSLog(@"takePicture progress");
    } completionHandler:^(NSDictionary *info) {
        NSLog(@"takePicture comp");
        dispatch_semaphore_signal(semaphore);
    } errorHandler:^(NSError *error) {
        NSLog(@"takePicture err");
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    while (camera.mediaBusy) {
        NSLog(@"media busy");
        [NSThread sleepForTimeInterval:0.5f];
    }
    [camera setCameraPropertyValue:@"EXPREV" value:@"<EXPREV/0.0>" error:nil];
    [camera unlockAutoFocus:nil];
    [camera unlockAutoExposure:nil];
}

-(void)takePictureSingle:(OLYCamera *)camera
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [camera takePicture:nil progressHandler:^(OLYCameraTakingProgress progress, NSDictionary *info) {
        NSLog(@"takePicture progress");
    } completionHandler:^(NSDictionary *info) {
        NSLog(@"takePicture comp");
        dispatch_semaphore_signal(semaphore);
    } errorHandler:^(NSError *error) {
        NSLog(@"takePicture err");
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

-(void)takePictureContinue:(OLYCamera *)camera
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [camera startTakingPicture:nil progressHandler:^(OLYCameraTakingProgress progress, NSDictionary *info) {
        NSLog(@"takePicture progress");
    } completionHandler:^(NSDictionary *info) {
        NSLog(@"takePicture comp");
    } errorHandler:^(NSError *error) {
        NSLog(@"takePicture err");
    }];
    [NSThread sleepForTimeInterval:1.0f];
    [camera stopTakingPicture:^(OLYCameraTakingProgress progress, NSDictionary *info) {
        NSLog(@"takePicture progress");
    } completionHandler:^(NSDictionary *info) {
        NSLog(@"takePicture comp");
        dispatch_semaphore_signal(semaphore);
    } errorHandler:^(NSError *error) {
        NSLog(@"takePicture err");
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}


@end
