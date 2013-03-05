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
    SInt32 KKFZeroDistanceSample;
}
@property(nonatomic,retain) communicator *com;
@property(nonatomic) bool isCalibrated;
@property(nonatomic) SInt64 *PKKF;
@property(nonatomic) SInt32 KKFLen;

- (void)InitializeArrays;
- (void)SetSignalDetailsRecord:(SInt32*)ARecord Play:(SInt32*)ASend RecordLen:(SInt32)RecordLen Playlen:(SInt32)PlayLen;
- (float)CalculateDistanceHeadphone;
- (SInt32)sendSigGen:(SInt32*)ipBuf :(SInt32&)iBufLen;
- (void)CalculateNetworklatencyComTimeStamp:(UInt64*)comTimeStamp acTimeStamp:(UInt64*)acTimeStamp nTimeStamps:(SInt32)nTimeStamps;

@end


enum ProcessingEnums{
    play = 0,
    record = 1
    };

#endif