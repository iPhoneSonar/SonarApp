#import "processing.h"

@implementation processing

@synthesize sendTimeTags;
@synthesize receiveTimeTags;
@synthesize count;
@synthesize PRecord;
@synthesize PSend;
@synthesize Latency;
@synthesize SigLen;
@synthesize isCalibrated;

-(void)InitializeArrays
{
    count = (SInt32*)malloc(2*sizeof(SInt32));
    count[0]=0;
    count[1]=0;
    sendTimeTags = (AudioTimeStamp*)malloc(10000*sizeof(AudioTimeStamp));
    receiveTimeTags = (AudioTimeStamp*)malloc(10000*sizeof(AudioTimeStamp));
}

- (int)IncreaseCount:(NSString*)Type
{
    int retval;
    if ([Type isEqualToString:@"receive"])
    {
        count[1]++;
        retval=0;
    }
    else
    {
        if([Type isEqualToString:@"send"])
        {
            count[0]++;
            retval =0;
        }
        else
        {
            retval=-1;
            NSLog(@"error at IncreaseCount");
        }
    }
    return retval;
}

- (SInt32)GetCount:(NSString*)Type;
{
    SInt32 retval;
    if ([Type isEqualToString:@"receive"])
    {
        retval=count[1];
    }
    else
    {
        if([Type isEqualToString:@"send"])
        {
            retval=count[0];
        }
        else
        {
            retval=-1;
            NSLog(@"error at GetCount");
        }
    }
    return retval;
}

- (int)SetTimeTag:(NSString*)Type To:(AudioTimeStamp)TimeStamp;
{
    int retval;
    if ([Type isEqualToString:@"receive"])
    {
        receiveTimeTags[count[1]]=TimeStamp;
        retval=[self IncreaseCount:Type];
    }
    else
    {
        if([Type isEqualToString:@"send"])
        {
            sendTimeTags[count[0]]=TimeStamp;
            retval=[self IncreaseCount:Type];
        }
        else
        {
            retval=-1;
            NSLog(@"error at setTimeTags");
        }
    }
    return retval;
}

- (Float64)GetTimeTag:(NSString*)Type at:(SInt32)Frame
{
    Float64 retval;
    if ([Type isEqualToString:@"receive"])
    {
        retval=receiveTimeTags[Frame].mSampleTime;
    }
    else
    {
        if([Type isEqualToString:@"send"])
        {
            retval=sendTimeTags[Frame].mSampleTime;
        }
        else
        {
            retval=-1;
            NSLog(@"error at GetTimeTag");
        }
    }
    return retval;
}

- (void)GetPointerReceive:(SInt32*)ARecord Send:(SInt32*)ASend Len:(SInt32)Len;
{
    PRecord=ARecord;
    PSend=ASend;
    SigLen=Len;
}

- (void)SetLatency:(Float64)SendTime
{
    SInt64 AKkf[SigLen+2*100];
    [self RingKKF:AKkf ofRecord:PRecord AndSend:PSend RecSamples:SigLen SendSamples:100];

    SInt32 KKFSample;
    KKFSample=[self MaximumSearchInKKF:AKkf atStartValue:0 withEndValue:SigLen];

    Float64 receiveTime;
    receiveTime=[self GetSampleOfKKFSample:KKFSample ofSamples:100 withTimeStamp:receiveTimeTags];
    Latency=receiveTime-SendTime;
    NSLog(@"latency: %f",Latency);
}

-(Float64)GetLatencyOfSendStart:(Float64)SendStart atReceiveStart:(Float64)ReceiveStart;
{
    Float64 LocalLatency=ReceiveStart-SendStart;
    return LocalLatency;
}

- (void)CalculateDistance:(Float64)SendTime
{
    SInt32 KKFSize=SigLen+2*4800;
    SInt64 AKKf[KKFSize];

    SInt32 KKFSample;
    KKFSample=[self MaximumSearchInKKF:AKKf atStartValue:0 withEndValue:SigLen];

    Float64 receiveTime;
    receiveTime=[self GetSampleOfKKFSample:KKFSample ofSamples:4800 withTimeStamp:receiveTimeTags];
    
    SInt32 SignalTime;
    SignalTime=(SInt32)(receiveTime-SendTime-Latency);

    float Distance;
    Distance=[self GetDistance:SignalTime];
    NSLog(@"Distance: %f",Distance);
}

-(float)GetDistance:(SInt32) Samples
{
    float Distance;
    Distance=((float)Samples)*343.0f/48000.0f;
    return Distance;
}

- (void)CalcKKF:(SInt64*)AKkf WithRecordSig:(SInt32*)ARecord AndSendSig:(SInt32*)ASend AndNumberOfSamples:(SInt32)Nsamples;
{
    SInt32 KKFSize=2*Nsamples;
    //Nullen aller AKkf Werte
    memset(AKkf,0,KKFSize*sizeof(SInt64));
    int i=0;
    int j=0;
    int endJ=0;
    /*int startJ=0;
     //für erste Hälfte (nicht nötig, da keine kausale aussage möglich ist)
     for (i=0; i<Nsamples; i++)
     {
     startJ=Nsamples-i;
     for(j=startJ;j<Nsamples;j++)
     {
     AKkf[i]=AKkf[i]+ASend[j]*ARecord[j+i-Nsamples];
     }
     }*/

    //zweite Hälfte, ab hier kausale Aussage möglich.
    //Berechnung um 2048 Werte später als Mitte, da das Empfangssignal um etwas mehr als 2 Frames verzögert ist
    //for (i=Nsamples+2048;i<KKFSize;i++)
    //3500 Werte entsprechen ca. 25 Meter, darum nicht mehr berechnen
    NSLog(@"Start der KKF Berechnung");
    for (i=Nsamples+2048;i<Nsamples+3500+2048;i++)
    {
        endJ=KKFSize-i;
        for(j=1;j<endJ;j++)
        {
            //add 2048 (2*Framesize), because record is 2 Samples longer than send.
            AKkf[i]=AKkf[i]+(SInt16)ASend[j]*(SInt16)ARecord[j+i-Nsamples];
        }
    }
    NSLog(@"Berechnung der KKF durchgeführt");
}

- (void)RingKKF:(SInt64*)AKkf ofRecord:(SInt32*)ARecord AndSend:(SInt32*)ASend RecSamples:(SInt32)NRecordSamples SendSamples:(SInt32)NSendSamples
{
    NSLog(@"Start der RingKKF berechnung");
    SInt32 startJ, endJ;
    SInt32 i, j;

    for(i=0; i<NSendSamples;i++)
    {
        startJ=NSendSamples-i;
        for(j=startJ;j<NSendSamples;j++)
        {
            AKkf[i]=AKkf[i]+(SInt16)ASend[j]*(SInt16)ARecord[i+j-NSendSamples];
        }
    }
    for(i=NSendSamples;i<NRecordSamples;i++)
    {
        for(j=0;j<NSendSamples;j++)
        {
            AKkf[i]=AKkf[i]+(SInt16)ASend[j]*(SInt16)ARecord[i+j-NSendSamples];
        }
    }
    for(i=NRecordSamples;i<NRecordSamples+NSendSamples;i++)
    {
        endJ=NRecordSamples+NSendSamples-i;
        for(j=0;j<endJ;j++)
        {
            AKkf[i]=AKkf[i]+(SInt16)ASend[j]*(SInt16)ARecord[i+j-NSendSamples];
        }
    }

    for(i=0;i<NSendSamples;i++)
    {
        AKkf[i]=AKkf[i]+AKkf[NRecordSamples-i];
        AKkf[NRecordSamples-i]=0;
    }
    NSLog(@"Berechnung der RingKKF durchgeführt");
}

- (SInt32)MaximumSearchInKKF:(SInt64*)AKkf atStartValue:(UInt32)StartValue withEndValue:(UInt32)EndValue;
{
    UInt64 max=0;
    SInt64 pmax=0;
    SInt64 nmax=0;
    int pmax_t=0;
    int nmax_t=0;

    int max_t=0;
    //get absolut highest peak of KKF between the values
    for (int i=StartValue;i<EndValue;i++)
    {
        //abs(Sint64) doesn´t work, abs() is only usable for Int
        if (AKkf[i]>0)
        {
            max=abs(AKkf[i]);
            max_t=i;
            if (pmax<AKkf[i])
            {
                pmax=AKkf[i];
                pmax_t=i;
            }
        }
        else
        {
            if (nmax>AKkf[i] || nmax==0)
            {
                nmax=AKkf[i];
                nmax_t=i;
            }
        }
    }
    if (nmax+pmax>=0)
    {
        max_t=pmax_t;
    }
    else
    {
        max_t=nmax_t;
    }
    NSLog(@"start = %ld, end = %ld, max = %lld",StartValue, EndValue, max);
    return max_t;
}

- (Float64) GetSampleOfKKFSample:(SInt32)KKFSample ofSamples:(SInt32)Samples withTimeStamp:(AudioTimeStamp*)timeTags;
{
    SInt32 Start=KKFSample-Samples;
    SInt32 Frame=Start/1024;
    Float64 Sample=timeTags[Frame].mSampleTime+(Float64)(Start%1024);
    NSLog(@"Vergleich: Empfangsframe: %f Darin Abtastwert: %li, Entspricht Sample: %f",timeTags[Frame].mSampleTime,Start%1024,Sample);
    return Sample;
}

@end

SInt32 sendSigGen(SInt32 *Tptr)
{
    SInt32 *T = NULL;
    T = Tptr;
    const int imax = 48 * 50; //48khz * 30ms = 1440 number of samples
    SInt32 len = imax *2;
    SInt32 mask = 0x0000FFFF;

    double fs = 48000.0;
    double fmin = 2000.0;
    double fmax = 3000.0;
    double f = 0.0;
    double fm = 0.0; //momentary frequency
    double omega = 0.0;
    SInt32 *pT = T + 2*imax-1; // pointer to the end for the negative gradient

    SInt32 x;
    for(x = 0;x<imax;x++)
    {
        fm = ((fmax - fmin)/(double)imax)*x + fmin;
        f = fm/fs;
        omega = M_PI * 2.0 * f;
        T[x] = mask & (SInt32)(sin(omega*(double)x) * 30000);
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
        T[x+shift] = mask & (SInt32)(sin(omega*(double)x) * 30000);
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
        T[x+shift] = mask & (SInt32)(sin(omega*(double)x) * 30000);
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
        T[x+shift] = mask & (SInt32)(sin(omega*(double)x) * 30000);
        *(pT--) = -T[x+shift];
    }
    return 1; //it was meant to allocate the memory in the function an return the size
}