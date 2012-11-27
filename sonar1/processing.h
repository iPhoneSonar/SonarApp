#import <Foundation/Foundation.h>
//For sampling rate 44.1Khz and maximum distance 10.29m (60ms signal propagation delay)
#define NSAMPLE 2646
#define KKFSIZE 5292

void CreateSendSignal(float ASend[NSAMPLE]);
void KKF(float ARecord[NSAMPLE], float Asend[NSAMPLE], float AKkf[KKFSIZE]);
void MaximumSuche(float AKkf[KKFSIZE]);
void sweepGen(SInt16 *T);