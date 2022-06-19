// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIEvent.h>

@class NSTimer;

@interface UIMotionEventProxy : UIEvent
{
  @public
  id _motionAccelerometer;
  int _subtype;
  int _shakeState;
  int _stateMachineState;
  double _shakeStartTime;
  double _lastMovementTime;
  double _highLevelTime;
  double _lowEndTimeout;
  NSTimer *_idleTimer;
  BOOL _sentMotionBegan;
  float _lowPassState[10];
  unsigned int _lowPassStateIndex;
  unsigned int _highPassStateIndex;
  float _highPassState[2];
}

- (id)_init;
- (void)dealloc;
- (int)type;
- (int)subtype;
- (void)_setSubtype:(int)fp8;
- (id)description;
- (void)_willResume;
- (void)_willSuspend;
- (void)_accelerometerDidDetectMovementWithTimestamp:(double)fp8;
- (void)_idleTimerFired;
- (void)accelerometer:(id)fp8 didAccelerateWithTimeStamp:(double)fp12 x:(float)fp20 y:(float)fp24 z:(float)fp28 eventType:(int)fp32;
- (int)_feedStateMachine:(float)fp8 currentState:(int)fp12 timestamp:(double)fp16;
- (float)_highPass:(float)fp8;
- (void)_resetLowPassState;
- (float)_lowPass:(float)fp8;
- (float)_determineShakeLevelX:(float)fp8 y:(float)fp12 currentState:(int)fp16;
- (int)_shakeState;
- (int)shakeState;
- (void)setShakeState:(int)fp8;

@end
