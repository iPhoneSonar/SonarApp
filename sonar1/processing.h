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
- (void)SetLatency:(Float64)SendTime;
- (void)GetPointerReceive:(SInt32*)ARecord Send:(SInt32*)ASend Len:(SInt32)Len;
- (void)CalculateDistance:(Float64)SendTime;

@end

void KKF(SInt32 *ARecord, SInt32 *ASend, SInt64 *AKkf,SInt32 Nsamples);
void RingKKF(SInt32 *ARecord,SInt32 *ASend,SInt64 *AKkf,SInt32 NRecordSamples, SInt32 NSendSamples);
SInt32 MaximumSuche(SInt64 *AKkf,UInt32 StartValue, UInt32 EndValue);
SInt32 sweepGen(SInt32 *Tptr);
Float64 GetSample(SInt32 KKFSample, SInt32 Samples, AudioTimeStamp *timeTags);
Float64 GetLatency(Float64 SendStart, Float64 ReceiveStart);
float GetDistance(SInt32 Samples);
#endif