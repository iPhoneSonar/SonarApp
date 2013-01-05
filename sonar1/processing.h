#import <Foundation/Foundation.h>
//For sampling rate 44.1Khz and maximum distance 10.29m (60ms signal propagation delay)
//#define NSAMPLE 2646
//#define KKFSIZE 5292

void KKF(SInt16 *ARecord, SInt16 *ASend, SInt64 *AKkf,SInt32 Nsamples);
SInt16 MaximumSuche(SInt64 *AKkf,SInt32 KKFSize);
SInt32 sweepGen(SInt16 *Tptr);