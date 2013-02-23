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
@synthesize com;
@synthesize eKKF;

-(void)InitializeArrays
{
    count = (SInt32*)malloc(2*sizeof(SInt32));
    count[0]=0;
    count[1]=0;
    sendTimeTags = (AudioTimeStamp*)malloc(10000*sizeof(AudioTimeStamp));
    receiveTimeTags = (AudioTimeStamp*)malloc(10000*sizeof(AudioTimeStamp));
    eKKF=(SInt64*)malloc(999999*sizeof(SInt64));
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
    KKFSample=[self MaximumSearchAtStartValue:0 WithEndValue:SigLen];

    Float64 receiveTime;
    receiveTime=[self GetSampleOfKKFSample:KKFSample ofSamples:100 withTimeStamp:receiveTimeTags];
    Latency=receiveTime-SendTime;
    [self setIsCalibrated:true];
    NSLog(@"latency: %f",Latency);
}

- (float)CalculateDistanceServerWithTimestamp:(Float64)SendTime
{
    SInt32 KKFSample;
    KKFSample=[self MaximumSearchAtStartValue:0 WithEndValue:SigLen];

    Float64 receiveTime;
    receiveTime=[self GetSampleOfKKFSample:KKFSample ofSamples:4800 withTimeStamp:receiveTimeTags];
    
    SInt32 SignalTime;
    SignalTime=(SInt32)(receiveTime-SendTime-Latency);

    float Distance;
    Distance=[self GetDistance:SignalTime];
    NSLog(@"Distance: %f",Distance);
    return Distance;
}

-(float)GetDistance:(SInt32) Samples
{
    float Distance;
    Distance=((float)Samples)*343.0f/48000.0f;
    return Distance;
}

- (void)CalcKKFWithumberOfSamples:(SInt32)Nsamples;
{
    SInt32 KKFSize=2*Nsamples;
    int i=0;
    int j=0;
    int endJ=0;
    int startJ=0;
     //für erste Hälfte (nicht nötig, da keine kausale aussage möglich ist)
     for (i=0; i<Nsamples; i++)
     {
         startJ=Nsamples-i;
         for(j=startJ;j<Nsamples;j++)
         {
             eKKF[i]=eKKF[i]+PSend[j]*PRecord[j+i-Nsamples];
         }
     }

    //zweite Hälfte, ab hier kausale Aussage möglich.
    //Berechnung um 2048 Werte später als Mitte, da das Empfangssignal um etwas mehr als 2 Frames verzögert ist
    //for (i=Nsamples+2048;i<KKFSize;i++)
    //3500 Werte entsprechen ca. 25 Meter, darum nicht mehr berechnen
    NSLog(@"Start der KKF Berechnung");
    for (i=Nsamples;i<KKFSize;i++)
    {
        endJ=KKFSize-i;
        for(j=1;j<endJ;j++)
        {
            eKKF[i]=eKKF[i]+(SInt16)PSend[j]*(SInt16)PRecord[j+i-Nsamples];
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

- (SInt32)MaximumSearchAtStartValue:(UInt32)StartValue WithEndValue:(UInt32)EndValue;
{
    SInt64 pmax=0;
    SInt64 nmax=0;
    int pmax_t=0;
    int nmax_t=0;

    int max_t=0;
    //get absolut highest peak of KKF between the values
    for (int i=StartValue;i<EndValue;i++)
    {
        //abs(Sint64) doesn´t work, abs() is only usable for Int
        if (eKKF[i]>0)
        {
            max_t=i;
            if (pmax<eKKF[i])
            {
                pmax=eKKF[i];
                pmax_t=i;
            }
        }
        else
        {
            if (nmax>eKKF[i] || nmax==0)
            {
                nmax=eKKF[i];
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
    NSLog(@"start = %ld, end = %ld, max: %i",StartValue, EndValue, max_t);
    return max_t;
}

- (Float64)GetSampleOfKKFSample:(SInt32)KKFSample ofSamples:(SInt32)Samples withTimeStamp:(AudioTimeStamp*)timeTags;
{
    SInt32 Start=KKFSample-Samples;
    SInt32 Frame=Start/1024;
    Float64 Sample=timeTags[Frame].mSampleTime+(Float64)(Start%1024);
    NSLog(@"Vergleich: Empfangsframe: %f Darin Abtastwert: %li, Entspricht Sample: %f",timeTags[Frame].mSampleTime,Start%1024,Sample);
    return Sample;
}

- (float)CalculateDistanceHeadphone
{
    SInt32 KKFSize=2*SigLen;
    eKKF = (SInt64*)malloc(KKFSize*sizeof(SInt64));
    memset(eKKF,0,KKFSize*sizeof(SInt64));

    [self CalcKKFWithumberOfSamples:SigLen];
    SInt32 Samples=[self MaximumSearchAtStartValue:SigLen WithEndValue:KKFSize];
    
    float Distance;
    //Distance=((float)(Samples-24813))*343.0f/48000.0f;
    Distance=((float)(Samples-SigLen-2048-238))*343.0f/48000.0f;
    if (Distance < 0)
    {
        NSLog(@"Distanz war %f (kleiner als 0), bereinigt", Distance);
        Distance=0;
    }
    NSLog(@"Distance: %f",Distance);
    return Distance;
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