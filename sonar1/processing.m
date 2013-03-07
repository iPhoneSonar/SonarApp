#import "processing.h"

const double SAMPLERATE = 48000.0;
const SInt32 GAIN = 30000;

@implementation processing

@synthesize isCalibrated;
@synthesize com;
@synthesize PKKF;
@synthesize KKFLen;


-(void)InitializeArrays
{
    KKFLen=999999;
    PKKF=(SInt64*)malloc(KKFLen*sizeof(SInt64));
    NetworkLatency=0;
    KKFZeroDistanceSample=0;
    [self ResetArrays];
}
-(void)ResetArrays
{
    memset(PKKF,0,KKFLen*sizeof(SInt64));
}

- (void)SetSignalDetailsRecord:(SInt32*)ARecord Play:(SInt32*)ASend RecordLen:(SInt32)RecordLen Playlen:(SInt32)PlayLen
{
    PRecord=ARecord;
    PPlay=ASend;
    RecordSigLen=RecordLen;
    PlaySigLen=PlayLen;
    NSLog(@"pointer set");
}

- (void)CalcKKF
{
    [self ResetArrays];
    SInt32 Nsamples;
    if (RecordSigLen>PlaySigLen)
    {
        Nsamples=RecordSigLen;
    } else
    {
        Nsamples=PlaySigLen;
    }
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
            PKKF[i]=PKKF[i]+(SInt16)PPlay[j]*(SInt16)PRecord[j+i-Nsamples];
         }
     }

    //zweite Hälfte, ab hier kausale Aussage möglich.
    //Berechnung um 2048 Werte später als Mitte, da das Empfangssignal um etwas mehr als 2 Frames verzögert ist
    //for (i=Nsamples+2048;i<KKFSize;i++)
    //3500 Werte entsprechen ca. 25 Meter, darum nicht mehr berechnen
    //NSLog(@"Start der KKF Berechnung");
    for (i=Nsamples;i<KKFSize;i++)
    {
        endJ=KKFSize-i;
        for(j=1;j<endJ;j++)
        {
            PKKF[i]=PKKF[i]+(SInt16)PPlay[j]*(SInt16)PRecord[j+i-Nsamples];
        }
    }
    //NSLog(@"Berechnung der KKF durchgeführt");
}

- (void)CalcKKFWithumberOfSamples:(SInt32)Nsamples
{
    [self ResetArrays];
    SInt32 KKFSize=2*Nsamples;
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
     PKKF[i]=PKKF[i]+PPlay[j]*PRecord[j+i-Nsamples];
     }
     }
     */

    //zweite Hälfte, ab hier kausale Aussage möglich.
    //Berechnung um 2048 Werte später als Mitte, da das Empfangssignal um etwas mehr als 2 Frames verzögert ist
    //for (i=Nsamples+2048;i<KKFSize;i++)
    //3500 Werte entsprechen ca. 25 Meter, darum nicht mehr berechnen
    NSLog(@"Start der KKF Berechnung");
    for (i=Nsamples+2048;i<Nsamples+2048+3500;i++)
    {
        endJ=KKFSize-i;
        for(j=1;j<endJ;j++)
        {
            PKKF[i]=PKKF[i]+(SInt16)PPlay[j]*(SInt16)PRecord[j+i-Nsamples];
        }
    }
    NSLog(@"Berechnung der KKF durchgeführt");
}

- (void)CalcRingKKF{
    NSLog(@"Start der RingKKF berechnung");
    [self ResetArrays];
    SInt32 startJ, endJ;
    SInt32 i, j;
    SInt32 TMP=PlaySigLen;
    PlaySigLen=2000;

    for(i=0; i<PlaySigLen;i++)
    {
        startJ=PlaySigLen-i;
        for(j=startJ;j<PlaySigLen;j++)
        {
            PKKF[i]=PKKF[i]+(SInt64)PPlay[j]*(SInt64)PRecord[i+j-PlaySigLen];
        }
    }
    for(i=PlaySigLen;i<RecordSigLen;i++)
    {
        for(j=0;j<PlaySigLen;j++)
        {
            PKKF[i]=PKKF[i]+(SInt64)PPlay[j]*(SInt64)PRecord[i+j-PlaySigLen];
        }
    }
    for(i=RecordSigLen;i<RecordSigLen+PlaySigLen;i++)
    {
        endJ=RecordSigLen+PlaySigLen-i;
        for(j=0;j<endJ;j++)
        {
            PKKF[i]=PKKF[i]+(SInt64)PPlay[j]*(SInt64)PRecord[i+j-PlaySigLen];
        }
    }

    for(i=0;i<PlaySigLen;i++)
    {
        PKKF[i]=PKKF[i]+PKKF[RecordSigLen-i];
        PKKF[RecordSigLen-i]=0;
    }
    PlaySigLen=TMP;
    NSLog(@"Berechnung der RingKKF durchgeführt");
}

- (SInt32)MaximumSearchAtStartValue:(UInt32)StartValue WithEndValue:(UInt32)EndValue
{
    SInt64 pmax=0;
    SInt64 nmax=0;
    int pmax_t=0;
    int nmax_t=0;

    int max_t=0;
    //get absolut highest peak of KKF between the values -13490
    for (int i=StartValue;i<EndValue;i++)
    {
        //abs(Sint64) doesn´t work, abs() is only usable for Int
        if (PKKF[i]>0)
        {
            max_t=i;
            if (pmax<PKKF[i])
            {
                pmax=PKKF[i];
                pmax_t=i;
            }
        }
        else
        {
            if (nmax>PKKF[i] || nmax==0)
            {
                nmax=PKKF[i];
                nmax_t=i;
            }
        }
    }
    max_t=pmax_t;
    //NSLog(@"start = %ld, end = %ld, max: %i, maxVal: %lli",StartValue, EndValue, max_t, pmax);
    return max_t;
}

- (float)CalculateDistanceHeadphone
{
    SInt32 KKFSize=2*RecordSigLen;

    [self CalcKKFWithumberOfSamples:RecordSigLen];
    SInt32 Samples=[self MaximumSearchAtStartValue:RecordSigLen WithEndValue:KKFSize];
    
    float Distance;
    //Distance=((float)(Samples-24813))*343.0f/48000.0f;
    Distance=((float)(Samples-RecordSigLen-2048-243))*343.0f/48000.0f;
    if (Distance < 0)
    {
        NSLog(@"Distanz war %f (kleiner als 0), bereinigt", Distance);
        Distance=0;
    }
    NSLog(@"Distance: %f",Distance);
    return Distance;
}

- (void)CalculateNetworklatencyRecvTimeStamp:(UInt64*)RecvTimeStamp TimestampOwn:(UInt64*)TimestampOwn nTimeStamps:(SInt32)nTimeStamps
{
    //calculate Network Latency
    NetworkLatency=0;
    for (int i=0;i<nTimeStamps;i++)
    {
        NetworkLatency+=(Float64)((TimestampOwn[i]-RecvTimeStamp[i]));
    }
    NetworkLatency=NetworkLatency/((Float64)nTimeStamps);

    //Calculate Zero Distance Sample
    [self CalcKKF];
    KKFZeroDistanceSample=[self MaximumSearchAtStartValue:0 WithEndValue:KKFLen];
    //NSLog(@"NetworkLatency=%f\n Sample for Zero Distance: %li",NetworkLatency,KKFZeroDistanceSample);
    isCalibrated=true;
}

- (void)CalculateDistanceRecvTimeStamp:(UInt64*)RecvTimeStamp TimestampOwn:(UInt64*)TimestampOwn nTimeStamps:(SInt32)nTimeStamps
{
    Float64 ThisNetworkLatency=0;
    //calculate Network Latency
    for (int i=0;i<nTimeStamps;i++)
    {
        ThisNetworkLatency+=(Float64)((TimestampOwn[i]-RecvTimeStamp[i]));
    }
    ThisNetworkLatency=ThisNetworkLatency/((Float64)nTimeStamps);

    //Calculate Zero Distance Sample
    [self CalcKKF];

    SInt32 SampleDistance=[self MaximumSearchAtStartValue:0 WithEndValue:KKFLen];

    Float64 LatencyDiff=ThisNetworkLatency-NetworkLatency;
    SInt32 SampleDiff=SampleDistance-KKFZeroDistanceSample;
    Float64 SampleDiffInUs=((Float64)SampleDiff)/48.0f*1000.0f;
    Float64 LatencyDiffInSamples=LatencyDiff*48.0f/1000.0f;
    NSLog(@"\nLatencyDiff=%.2f SampleDiffInUs:%.2f \nLatencyDiffInSamples=%.0f SampleDiff=%li ",LatencyDiff,SampleDiffInUs, LatencyDiffInSamples, SampleDiff);
    Float64 SignalLaufzeitInMs=(SampleDiffInUs-LatencyDiff)/1000.0f;
    NSLog(@"SignallaufzeitInMs=%.2f",SignalLaufzeitInMs);
    Float64 Distance=SignalLaufzeitInMs/1000.0f*343;
    NSLog(@"Distance=%.2f",Distance);
    
    //NSLog(@"NetworkLatency saved=%f this Measurement=%f\n difference: %f",NetworkLatency,ThisNetworkLatency,NetworkLatency-ThisNetworkLatency);
    //NSLog(@"SampleDistance: %li, KKFZeroDistanceSample: %li, Distance in Samples: %li", SampleDistance, KKFZeroDistanceSample, SampleDistance-KKFZeroDistanceSample);
}


//creates a stero signal with one muted channel
- (SInt32) chirpGen: (SInt32*)ipBuf : (SInt32&)iBufLen : (double)dMin  : (double)dMax
{

    const SInt32 MASK = 0x0000FFFF;
    if (ipBuf == NULL)
    {
        iBufLen = -1;
        NSLog(@"error chirpGen, buffer not assigned");
        return -1;
    }

    double dDelta = dMax - dMin;
    //TODO: phase jump checking

    SInt32 *ipBufPos = ipBuf;
    SInt32 iStepMax = iBufLen/2;

    double dOmega = 0.0;
    SInt32 *ipBufPosEnd = ipBuf + iBufLen - 1; // pointer to the end for the negative gradient
    
    SInt32 iStep;
    for(iStep = 0;iStep<iStepMax;iStep++)
    {
        dOmega =  (((dDelta * (double)iStep)/ (double)iStepMax) + dMin) * (M_PI * 2.0)/ SAMPLERATE;

        *ipBufPos = MASK & (SInt32)(sin(dOmega*(double)iStep) * GAIN);
        *(ipBufPosEnd--) = -*(ipBufPos++);
    }
    
    return 0;
}

//TODO: test fast and slow chirp combination

- (SInt32) sendSigGen: (SInt32*)ipBuf : (SInt32&)iBufLen
{
    if (ipBuf == NULL)
    {
        iBufLen = -1;
        NSLog(@"error sendSigGen buffer not assigned");
        return  -1;
    }

    SInt32 iChirpLen = 30*48*2;
    SInt32 iRet =
    [self chirpGen:ipBuf :iChirpLen:1000.0 :5000.0];
    SInt32 iChirpLen2 = 30*48*2*3;
    iRet =
    [self chirpGen:ipBuf+iChirpLen :iChirpLen2:1000.0 :5000.0];

    return iRet;
}

@end
