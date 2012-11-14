#import "processing.h"

//void KKF(float* ARecord, float* ASend, float* AKkf)
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
    
    //Durchfürhung KKF (noch Matlab implementierung, also auf auch "negative" Zeiten werden berechnet, beginn sollte später bei NSAMPLE sein)
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

void MaximumSuche(float AKkf[KKFSIZE])
{
    float max=0;
    int max_t=0;
    
    //Bestimmung der Entfernung (Beginn muss angepasst werden wenn größe der KKF verändert wird)
    for (int i=NSAMPLE+20;i<KKFSIZE;i++)
    {
        if (max<abs( (int)AKkf[i]) )
        {
            max=abs( (int)AKkf[i]);
            max_t=i;
        }
    }
    NSLog(@"Maximum bei KKF Punkt: %i",max_t);
}

void SendesignalErzeugung(float ASend[NSAMPLE])
{
    //Erzeugung eines Sendesignales für KKF
    float fm, fmax, fmin;
    fmin=1000;
    fmax=10000;
    for (int i=0;i<NSAMPLE/2;i++)
    {
        fm=((fmax-fmin)/(NSAMPLE/2))*i+fmin;
        ASend[i]=sin(2*M_PI*fm/FSAMPLE*i);
        ASend[NSAMPLE-i]=-ASend[i];                 //Achtung, muss noch geändert werden wenn SampleFrequen geändert wird.
    }
    NSLog(@"Sendesignal erzeugt");
}