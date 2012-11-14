#import <Foundation/Foundation.h>
#define NSAMPLE 2880
#define FSAMPLE 48000

void SendesignalErzeugung(float ASend[NSAMPLE]);
void KKF(float ARecord[NSAMPLE], float Asend[NSAMPLE], float AKkf[2*NSAMPLE]);
void MaximumSuche(float AKkf[2*NSAMPLE]);