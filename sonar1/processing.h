#import <Foundation/Foundation.h>
//For sampling rate 44.1Khz and maximum distance 10.29m (60ms signal propagation delay)
//#define NSAMPLE 2646
//#define KKFSIZE 5292

void KKF(SInt32 *ARecord, SInt32 *ASend, SInt64 *AKkf,SInt32 Nsamples);
SInt32 MaximumSuche(SInt64 *AKkf,UInt32 StartValue, UInt32 EndValue);
SInt32 sweepGen(SInt32 *Tptr);