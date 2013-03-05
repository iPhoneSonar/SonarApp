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
    bool isCalibrated;
    communicator *com;
    SInt64 *PKKF;
    SInt32 KKFLen;
    Float64 NetworkLatency;
    SInt32 KKFZeroDistancePos;
}
@property(nonatomic,retain) communicator *com;
@property(nonatomic) bool isCalibrated;
@property(nonatomic) SInt64 *PKKF;
@property(nonatomic) SInt32 KKFLen;
@property(nonatomic) Float64 NetworkLatency;
@property(nonatomic) SInt32 KKFZeroDistancePos;

- (void)InitializeArrays;
- (void)SetSignalDetailsRecord:(SInt32*)ARecord Play:(SInt32*)ASend RecordLen:(SInt32)RecordLen Playlen:(SInt32)PlayLen;
- (float)CalculateDistanceHeadphone;
- (void)RingKKF:(SInt64*)AKkf ofRecord:(SInt32*)ARecord AndSend:(SInt32*)ASend RecSamples:(SInt32)NRecordSamples SendSamples:(SInt32)NSendSamples;
- (SInt32)sendSigGen:(SInt32*)ipBuf :(SInt32&)iBufLen;
- (void)CalculateLatencyComTimeStamp:(UInt64*)comTimeStamp acTimeStamp:(UInt64*)acTimeStamp nTimeStamps:(SInt32)nTimeStamps;


- (void)CalcKKFWithumberOfSamples:(SInt32)Nsamples;
- (SInt32)MaximumSearchAtStartValue:(UInt32)StartValue WithEndValue:(UInt32)EndValue;

@end


enum ProcessingEnums{
    play = 0,
    record = 1
    };

#endif