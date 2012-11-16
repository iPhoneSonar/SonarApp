#import <Foundation/Foundation.h>
#define NSAMPLE 2880
#define KKFSIZE 5760
#define FSAMPLE 48000

void CreateSendSignal(float ASend[NSAMPLE]);
void KKF(float ARecord[NSAMPLE], float Asend[NSAMPLE], float AKkf[KKFSIZE]);
void MaximumSuche(float AKkf[KKFSIZE]);