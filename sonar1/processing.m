#import "processing.h"

void KKF(float ARecord[NSAMPLE], float ASend[NSAMPLE], float AKkf[KKFSIZE])
{
    int i=0;
    int j=0;
    //Nullen aller AKkf Werte
    for (i=0;i<NSAMPLE;i++)
    {
        AKkf[i*2]=0;
        AKkf[i*2+1]=0;
    }
    
    //Durchfürhung KKF (noch Matlab implementierung, also auf auch "negative" Zeiten werden berechnet, Beginn sollte später bei NSAMPLE sein)
    for (i=0;i<KKFSIZE;i++)
    {
        for (j=0;j<NSAMPLE;j++)
        {
            if (j+i>NSAMPLE)
            {
                if (j+i<=KKFSIZE)
                {
                    AKkf[i]=AKkf[i]+ASend[j]*ARecord[j+i-NSAMPLE];
                }
            }
        }
    }
#ifndef NODEBUG
    NSLog(@"KKF Durchgeführt");
#endif
}

void MaximumSuche(float AKkf[KKFSIZE])
{
    float max=0;
    int max_t=0;
    
    //Bestimmung der Entfernung (offset eventuell dynamisch aus Hardwarevorgabe berechnen, offset eventuell größer für reale signale)
    for (int i=NSAMPLE+20;i<KKFSIZE;i++)
    {
        if (max<abs( (int)AKkf[i]) )
        {
            max=abs( (int)AKkf[i]);
            max_t=i;
        }
    }
#ifndef NODEBUG
    NSLog(@"Maximum bei KKF Punkt: %i",max_t);
#endif
}

void CreateSendSignal(float ASend[NSAMPLE])
{
    float fm, fmax, fmin;
    fmin=1000;
    fmax=10000;
    for (int i=0;i<NSAMPLE/2;i++)
    {
        fm=((fmax-fmin)/(NSAMPLE/2))*i+fmin;
        ASend[i]=sin(2*M_PI*fm/44100*i);
        ASend[NSAMPLE-i]=-ASend[i];
    }
#ifndef NODEBUG
    NSLog(@"Sendesignal erzeugt");
#endif
}

//this function will 
void sweepGen(SInt16 *T)
{
    const int imax = 48 * 50; //48khz * 30ms = 1440 number of samples
    const double fs = 48000.0;
    const double fmax = 10000.0;
    const double fmin = 1000.0;
    double f = 0.0;
    double fm = 0.0; //momentary frequency
    double omega = 0.0;
    SInt16 *pT = T + 2*imax-1; // pointer to the end for the negative gradient

    SInt16 x;
    for(x = 0;x<imax;x++){
        fm = ((fmax - fmin)/(double)imax)*x + fmin;
        f = fm/fs;
        omega = M_PI * 2.0 * f;
        T[x] = sin(omega*(double)x) * 3000;
        *(pT--) = T[x];
    }
}
