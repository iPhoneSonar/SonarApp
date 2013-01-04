#import <Foundation/Foundation.h>
//For sampling rate 44.1Khz and maximum distance 10.29m (60ms signal propagation delay)
#define NSAMPLE 2646
#define KKFSIZE 5292

void CreateSendSignal(float ASend[NSAMPLE]);
void KKF(SInt16 ARecord[NSAMPLE], SInt16 ASend[NSAMPLE], SInt64 AKkf[KKFSIZE]);
SInt16 MaximumSuche(SInt64 AKkf[KKFSIZE]);
SInt32 sweepGen(SInt16 *Tptr);