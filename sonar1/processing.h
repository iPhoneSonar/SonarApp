#ifndef processingH
#define processingH
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>


@interface processing : NSObject
{
    AudioTimeStamp *sendTimeTags;
    AudioTimeStamp *receiveTimeTags;
    SInt32 *count;
    SInt32 SigLen;
    SInt32 *PRecord;
    SInt32 *PSend;
    Float64 Latency;
}

@property(nonatomic) AudioTimeStamp *sendTimeTags;
@property(nonatomic) AudioTimeStamp *receiveTimeTags;
@property(nonatomic) SInt32 *count;
@property(nonatomic) SInt32 *PRecord;
@property(nonatomic) SInt32 *PSend;
@property(nonatomic) Float64 Latency;
@property(nonatomic) SInt32 SigLen;

- (void)InitializeArrays;
- (int)IncreaseCount:(NSString*)Type;
- (SInt32)GetCount:(NSString*)Type;
- (int)SetTimeTag:(NSString*)Type To:(AudioTimeStamp)TimeStamp;
- (Float64)GetTimeTag:(NSString*)Type at:(SInt32)Frame;
- (void)SetLatency:(Float64)SendTime; //call by server
- (Float64)GetLatencyOfSendStart:(Float64)SendStart atReceiveStart:(Float64) ReceiveStart;
- (void)GetPointerReceive:(SInt32*)ARecord Send:(SInt32*)ASend Len:(SInt32)Len;
- (void)CalculateDistance:(Float64)SendTime; //call by server
- (float)GetDistance:(SInt32)Samples;
- (void)CalcKKF:(SInt64*)AKkf WithRecordSig:(SInt32*)ARecord AndSendSig:(SInt32*)ASend AndNumberOfSamples:(SInt32)Nsamples;
- (void)RingKKF:(SInt64*)AKkf ofRecord:(SInt32*)ARecord AndSend:(SInt32*)ASend RecSamples:(SInt32)NRecordSamples SendSamples:(SInt32)NSendSamples;
- (SInt32)MaximumSearchInKKF:(SInt64*)AKkf atStartValue:(UInt32)StartValue withEndValue:(UInt32)EndValue;
- (Float64) GetSampleOfKKFSample:(SInt32)KKFSample ofSamples:(SInt32)Samples withTimeStamp:(AudioTimeStamp*)timeTags;
@end

SInt32 sendSigGen(SInt32 *Tptr);
#endif