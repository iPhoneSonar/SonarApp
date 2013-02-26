#ifndef processingH
#define processingH
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "communicator.h"


@interface processing : NSObject
{
    AudioTimeStamp *playTimeTags;
    AudioTimeStamp *recordTimeTags;
    SInt32 *count;
    SInt32 SigLen;
    SInt32 *PRecord;
    SInt32 *PSend;
    Float64 TimeDifference;
    bool isCalibrated;
    communicator *com;
    SInt64 *eKKF;
}
@property(nonatomic,retain) communicator *com;
@property(nonatomic) AudioTimeStamp *playTimeTags;
@property(nonatomic) AudioTimeStamp *recordTimeTags;
@property(nonatomic) SInt32 *count;
@property(nonatomic) SInt32 *PRecord;
@property(nonatomic) SInt32 *PSend;
@property(nonatomic) SInt32 SigLen;
@property(nonatomic) bool isCalibrated;
@property(nonatomic) SInt64 *eKKF;

- (void)InitializeArrays;
- (int)IncreaseCount:(NSString*)Type;
- (SInt32)GetCount:(NSString*)Type;
//- (int)SetTimeTag:(NSString*)Type To:(AudioTimeStamp)TimeStamp;
//- (Float64)GetTimeTag:(NSString*)Type at:(SInt32)Frame;
- (void)SetTimeDifference:(Float64)SendTime ReciveTimestamp:(Float64)ReceiveTime; //call by server
- (void)GetPointerReceive:(SInt32*)ARecord Send:(SInt32*)ASend Len:(SInt32)Len;
- (float)CalculateDistanceServerWithTimestamp:(Float64)SendTime; //call by server
- (void)RingKKF:(SInt64*)AKkf ofRecord:(SInt32*)ARecord AndSend:(SInt32*)ASend RecSamples:(SInt32)NRecordSamples SendSamples:(SInt32)NSendSamples;
- (float)CalculateDistanceHeadphone;
- (void)resetTimeTags;

@end

SInt32 sendSigGen(SInt32 *Tptr);
#endif