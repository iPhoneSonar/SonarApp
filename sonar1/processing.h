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
- (float)CalculateDistanceHeadphone;

@end
enum ProcessingEnums{
    play = 0,
    record = 1
    };
SInt32 sendSigGen(SInt32 *Tptr);
#endif