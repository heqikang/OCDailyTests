//
//  MYAccelerometerTool.m
//  BackgroundShakeTest
//
//  Created by LongMa on 2020/9/8.
//  Copyright © 2020 my. All rights reserved.
//

#import "MYAccelerometerTool.h"
#import <CoreMotion/CoreMotion.h>

NSString *const KNTFY_SHAKE_SUCCESS = @"KNTFY_SHAKE_SUCCESS";

@interface MYAccelerometerTool ()
@property(nonatomic, strong) CMMotionManager *gMotionMnger;


/// 时间对象，用于实现节流效果（为防止频繁回调，每次检测成功后，停止摇动1s后才继续响应下次摇一摇。）
@property(nonatomic, strong) NSDate *gDateLastShakeSuc;
@end

@implementation MYAccelerometerTool
HMSingleton_m(MYAccelerometerTool);


- (BOOL)startMonitorShake{
    if (NO == self.gMotionMnger.isAccelerometerAvailable) {
        return NO;
    }
    
    //监听中，直接返回YES
    if (self.gMotionMnger.isAccelerometerActive) {
        return YES;
    }
    
    [self.gMotionMnger startAccelerometerUpdatesToQueue:[NSOperationQueue new] withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
        
        CMAcceleration acceleration = accelerometerData.acceleration;
        
        //综合x、y两个方向的加速度（z方向速度无意义，用的话，走路上下抖手机时会误触发，系统摇一摇也不会被z轴加速度触发）
        //当综合加速度大于2.3时，就激活效果（数据越小，用户摇动的动作就越小，越容易激活）
        double accelerameter = sqrt( pow( acceleration.x , 2 ) + pow( acceleration.y , 2 ));
        
        if (accelerameter > 2.3) {
            
            //节流效果：距离上次摇一摇成功事件，间隔时间小于1s时，认为无效
            NSDate *lCrtDate = [NSDate date];
            if ([lCrtDate timeIntervalSinceDate:self.gDateLastShakeSuc] < 1) {
                self.gDateLastShakeSuc = lCrtDate;
                return ;
            }
            
            self.gDateLastShakeSuc = lCrtDate;
            [[NSNotificationCenter defaultCenter] postNotificationName:KNTFY_SHAKE_SUCCESS object:nil];
        }
    }];
    
    return YES;
}

- (void)stopMonitorShake{
    [self.gMotionMnger stopAccelerometerUpdates];
    self.gMotionMnger = nil;
    self.gDateLastShakeSuc = nil;
}

#pragma mark -  getter
- (CMMotionManager *)gMotionMnger{
    if (nil == _gMotionMnger) {
        CMMotionManager *lMnger = [[CMMotionManager alloc] init];
        lMnger.accelerometerUpdateInterval = 0.1;
        [lMnger startAccelerometerUpdates];
        _gMotionMnger = lMnger;
    }
    return _gMotionMnger;
}

- (NSDate *)gDateLastShakeSuc{
    if (nil == _gDateLastShakeSuc) {
        _gDateLastShakeSuc = [NSDate distantPast];
    }
    return _gDateLastShakeSuc;
}

@end
