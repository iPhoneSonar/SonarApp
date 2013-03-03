#ifndef processingH
#define processingH
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "communicator.h"


@interface processing : NSObject
{
    SInt32 RecordSigLen;
    SInt32 PlaySigLen;
    SInt32 *PRecord;
    SInt32 *PPlay;
    Float64 TimeDifference;
    bool isCalibrated;
    communicator *com;
    SInt64 *PKKF;
    SInt32 KKFLen;
}
@property(nonatomic,retain) communicator *com;
@property(nonatomic) bool isCalibrated;
@property(nonatomic) SInt64 *PKKF;
@property(nonatomic) SInt32 KKFLen;

- (void)InitializeArrays;
- (void)SetTimeDifference:(Float64)PlayStopTime RecordStopTime:(Float64)ReceiveTime AtBufPos:(SInt32)RecordStopBufferPosition; //call by server
- (void)SetSignalDetailsRecord:(SInt32*)ARecord Play:(SInt32*)ASend RecordLen:(SInt32)RecordLen Playlen:(SInt32)PlayLen;
- (float)CalculateDistanceServerWithTimestamp:(Float64)SendTime; //call by server
<<<<<<< HEAD
- (float)CalculateDistanceHeadphone;
=======
- (void)CalcKKF:(SInt64*)AKkf WithRecordSig:(SInt32*)ARecord AndSendSig:(SInt32*)ASend AndNumberOfSamples:(SInt32)Nsamples;
- (void)RingKKF:(SInt64*)AKkf ofRecord:(SInt32*)ARecord AndSend:(SInt32*)ASend RecSamples:(SInt32)NRecordSamples SendSamples:(SInt32)NSendSamples;
- (SInt32)sendSigGen:(SInt32*)ipBuf :(SInt32&)iBufLen;

@end
>>>>>>> x51

@end
enum ProcessingEnums{
    play = 0,
    record = 1
    };
SInt32 sendSigGen(SInt32 *Tptr);
#endif