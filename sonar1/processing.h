#import <Foundation/Foundation.h>
#ifndef AudioToolbox
#import <AudioToolbox/AudioToolbox.h>
#define AudioToolbox
#endif

void KKF(SInt32 *ARecord, SInt32 *ASend, SInt64 *AKkf,SInt32 Nsamples);
SInt32 MaximumSuche(SInt64 *AKkf,UInt32 StartValue, UInt32 EndValue);
SInt32 sweepGen(SInt32 *Tptr);
Float64 GetSample(SInt32 KKFSample, SInt32 Samples, AudioTimeStamp *timeTags);
Float64 GetLatency(Float64 SendStart, Float64 ReceiveStart);
float GetDistance(SInt32 Samples);