//
//  ViewController.m
//  imgnow-ios
//
//  Created by Henry Ehly on 2015/09/21.
//  Copyright © 2015年 Henry Ehly. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@end

@implementation ViewController

@synthesize stillImageOutput;
@synthesize captureSession;
@synthesize alertActionHtmlOk;
@synthesize alertController;
@synthesize alertActionSendEmail;
@synthesize alertActionEmailOk;
@synthesize captureDevise;


- (void)viewDidLoad {
    [super viewDidLoad];
    _torchIsOn = NO;
    _facingFront = NO;
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults valueForKey:@"user_email"]) {
        
        NSString *msg = [NSString stringWithFormat:@"Welcome, %@", [defaults valueForKey:@"user_email"]];
        
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Logged in successfully" message:msg preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:nil];
        
        [ac addAction:ok];
        
        [self presentViewController:ac animated:YES completion:nil];
        
    }
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self turnTorchOn:NO];
    
    [self changeWindowState:@"pretake"];
    
    captureSession = [[AVCaptureSession alloc] init];
    captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    
    NSError *error = nil;
    captureDevise = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *captureDeviseInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevise error:&error];
    
    if ([captureSession canAddInput:captureDeviseInput]) {
        [captureSession addInput:captureDeviseInput];
    }
    
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    CGRect bounds = self.view.layer.bounds;
    previewLayer.bounds = bounds;
    previewLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    
    [self.view.layer insertSublayer:previewLayer atIndex:0];
    
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *stillImageOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    stillImageOutput.outputSettings = stillImageOutputSettings;
    
    if ([captureSession canAddOutput:stillImageOutput]) {
        [captureSession addOutput:stillImageOutput];
    }
    
    [captureSession startRunning];
    
}

- (IBAction)switchCamera:(id)sender
{
    //Change camera source
    if(captureSession) {
        //Indicate that some changes will be made to the session
        [captureSession beginConfiguration];
        
        //Remove existing input
        AVCaptureInput *currentCameraInput = [captureSession.inputs objectAtIndex:0];
        [captureSession removeInput:currentCameraInput];
        
        //Get new input
        AVCaptureDevice *newCamera = nil;
        if(((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionBack) {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
            self.imageView.transform = CGAffineTransformMakeScale(-1, 1);
            _facingFront = YES;
            self.btnToggleFlash.hidden  = YES;
        } else {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
            self.imageView.transform = CGAffineTransformMakeScale(1, 1);
            self.btnToggleFlash.hidden  = NO;
            _facingFront = NO;
        }
        
        //Add input to session
        NSError *err = nil;
        AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:&err];
        if(!newVideoInput || err) {
            NSLog(@"Error creating capture device input: %@", err.localizedDescription);
        } else {
            [captureSession addInput:newVideoInput];
        }
        
        //Commit all the configuration changes at once
        [captureSession commitConfiguration];
    }
}

// Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position) return device;
    }
    return nil;
}

- (IBAction)takePhoto:(id)sender {
    
    AVCaptureConnection *videoConnection = nil;
    
    for (AVCaptureConnection *connection in stillImageOutput.connections) {
        for (AVCaptureInputPort *port in connection.inputPorts) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {

        if (imageDataSampleBuffer != NULL) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [UIImage imageWithData:imageData];
            self.imageView.image = image;
            [self changeWindowState:@"posttake"];

        }
    }];
    
}

- (IBAction)cancel:(id)sender {
    [self changeWindowState:@"pretake"];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    NSLog(@"foo");
}

- (IBAction)toggleFlash:(id)sender {
    if (!_torchIsOn) {
        [self turnTorchOn:YES];
        [_btnToggleFlash setImage:[UIImage imageNamed:@"Flash-On-50-white.png"] forState:UIControlStateNormal];
    } else {
        [self turnTorchOn:NO];
        [_btnToggleFlash setImage:[UIImage imageNamed:@"Flash Off-50 (1).png"] forState:UIControlStateNormal];
    }
}

- (void) turnTorchOn: (bool) on {
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            
            [device lockForConfiguration:nil];
            if (on) {
//                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
                _torchIsOn = YES;
            } else {
//                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
                _torchIsOn = NO;
            }
            [device unlockForConfiguration];
        }
    }
}

- (IBAction)upload:(id)sender {
    
    self.uploadActivityIndicator.hidden = NO;
    [self.uploadActivityIndicator startAnimating];
    
    // perform the actual upload
    [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(uploadAlertResult) userInfo:nil repeats:NO];
    
}

-(void)uploadAlertResult {
    
    NSString *title   = @"Plug this into your HTML";
    NSString *message = @"<img src=\"http://placeholdnow.com/4j8d92je.jpeg\">";
    NSString *titleOk = @"OK";
    NSString *titleEmail = @"Email it to me";
    
    alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    alertActionHtmlOk = [UIAlertAction actionWithTitle:titleOk style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // do nothing
    }];
    
    alertActionSendEmail = [UIAlertAction actionWithTitle:titleEmail style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // send email
        [self sendEmail];
    }];
    
    [alertController addAction:alertActionHtmlOk];
    [alertController addAction:alertActionSendEmail];
    
    [self presentViewController:alertController animated:YES completion:nil];

    [self changeWindowState:@"pretake"];
    
}

- (void)sendEmail {
    
    NSString *title   = @"Sent you an email at:";
    NSString *message = @"foobar@email.com";

    alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    alertActionEmailOk = [UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // pressed ok
    }];
    [alertController addAction:alertActionEmailOk];
    [self presentViewController:alertController animated:YES completion:^{
        // showed email sent alert
    }];
    
}


- (void)changeWindowState:(NSString *)state {
    
    if ([state isEqualToString:@"pretake"]) {
        self.btnCancel.hidden               = YES;
        self.imageView.hidden               = YES;
        self.btnUpload.hidden               = YES;
        self.uploadActivityIndicator.hidden = YES;
        self.btnTakePhoto.hidden            = NO;
        self.btnSwitchCamera.hidden         = NO;
        self.btnMenu.hidden                 = NO;
        self.btnToggleFlash.hidden = _facingFront ? YES : NO;
    } else if ([state isEqualToString:@"posttake"]) {
        self.btnCancel.hidden       = NO;
        self.imageView.hidden       = NO;
        self.btnUpload.hidden       = NO;
        self.btnTakePhoto.hidden    = YES;
        self.btnSwitchCamera.hidden = YES;
        self.btnMenu.hidden         = YES;
        self.btnToggleFlash.hidden = _facingFront ? YES : NO;
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
