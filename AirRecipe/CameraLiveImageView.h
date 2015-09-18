//
//  CameraLiveImageView.h
//  ImageCaptureSample
//
//  Copyright (c) Olympus Imaging Corporation. All rights reserved.
//  Olympus Imaging Corp. licenses this software to you under EULA_OlympusCameraKit_ForDevelopers.pdf.
//

#import <UIKit/UIKit.h>

enum CameraFocusFrameStatus
{
	CameraFocusFrameStatusRunning,
	CameraFocusFrameStatusFocused,
	CameraFocusFrameStatusFailed,
};
typedef enum CameraFocusFrameStatus CameraFocusFrameStatus;

@interface CameraLiveImageView : UIImageView

@property (assign, nonatomic) BOOL showingFocusFrame;                   //Modifty
@property (assign, nonatomic) CameraFocusFrameStatus focusFrameStatus;  //Modifty
@property (assign, nonatomic) CGRect focusFrameRect;                    //Modifty

- (CGPoint)pointWithGestureRecognizer:(UIGestureRecognizer *)gesture;
- (BOOL)containsPoint:(CGPoint)point;
- (void)hideFocusFrame;
- (void)showFocusFrame:(CGRect)rect status:(CameraFocusFrameStatus)status;
- (void)showFocusFrame:(CGRect)rect status:(CameraFocusFrameStatus)status duration:(NSTimeInterval)duration;

@end
