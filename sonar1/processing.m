#import "processing.h"

void KKF(SInt16 ARecord[NSAMPLE], SInt16 ASend[NSAMPLE], SInt64 AKkf[KKFSIZE])
{
    int i=0;
    int j=0;
    //Nullen aller AKkf Werte
    memset(AKkf,0,KKFSIZE*sizeof(SInt64));
    
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
    NSLog(@"KKF Durchgeführt");
}

SInt16 MaximumSuche(SInt64 AKkf[KKFSIZE])
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
    NSLog(@"Maximum bei KKF Punkt: %i mit dem Wert: %f ",max_t,max);
    return max_t;
}

SInt32 sweepGen(SInt16 *Tptr)
{
    SInt16 *T = NULL;
    T = Tptr;
    const int imax = 48 * 50; //48khz * 30ms = 1440 number of samples
    SInt32 len = imax *2;  

    double fs = 48000.0;
    double fmin = 2000.0;
    double fmax = 3000.0;
    double f = 0.0;
    double fm = 0.0; //momentary frequency
    double omega = 0.0;
    SInt16 *pT = T + 2*imax-1; // pointer to the end for the negative gradient

    SInt32 x;
    for(x = 0;x<imax;x++)
    {
        fm = ((fmax - fmin)/(double)imax)*x + fmin;
        f = fm/fs;
        omega = M_PI * 2.0 * f;
        T[x] = sin(omega*(double)x) * 30000;
        *(pT--) = -T[x];
    }

    SInt32 shift = len + 1024;
    fs = 48000.0;
    fmin = 3000.0;
    fmax = 4000.0;
    f = 0.0;
    fm = 0.0; //momentary frequency
    omega = 0.0;
    pT = T + 2*imax-1 + shift; // pointer to the end for the negative gradient

    for(x = 0;x<imax;x++)
    {
        fm = ((fmax - fmin)/(double)imax)*x + fmin;
        f = fm/fs;
        omega = M_PI * 2.0 * f;
        T[x+shift] = sin(omega*(double)x) * 30000;
        *(pT--) = -T[x+shift];
    }


    shift = (len + 1024) * 2;
    fs = 48000.0;
    fmin = 4000.0;
    fmax = 5000.0;
    f = 0.0;
    fm = 0.0; //momentary frequency
    omega = 0.0;
    pT = T + 2*imax-1 + shift; // pointer to the end for the negative gradient

    for(x = 0;x<imax;x++)
    {
        fm = ((fmax - fmin)/(double)imax)*x + fmin;
        f = fm/fs;
        omega = M_PI * 2.0 * f;
        T[x+shift] = sin(omega*(double)x) * 30000;
        *(pT--) = -T[x+shift];
    }

    shift = (len + 1024) * 3;
    fs = 48000.0;
    fmin = 5000.0;
    fmax = 6000.0;
    f = 0.0;
    fm = 0.0; //momentary frequency
    omega = 0.0;
    pT = T + 2*imax-1 + shift; // pointer to the end for the negative gradient

    for(x = 0;x<imax;x++)
    {
        fm = ((fmax - fmin)/(double)imax)*x + fmin;
        f = fm/fs;
        omega = M_PI * 2.0 * f;
        T[x+shift] = sin(omega*(double)x) * 30000;
        *(pT--) = -T[x+shift];
    }
    
    //memcpy(T+len+1024, T, len*2);
    return 1; //it was meant to allocate the memory in the function an return the size
}
