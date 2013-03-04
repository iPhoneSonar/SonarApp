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
    TimeDifference=0;
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
}

- (void)CalcKKFWithumberOfSamples:(SInt32)Nsamples;
{
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

- (SInt32)MaximumSearchAtStartValue:(UInt32)StartValue WithEndValue:(UInt32)EndValue;
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
    NSLog(@"start = %ld, end = %ld, max: %i, maxVal: %lli",StartValue, EndValue, max_t, pmax);
    return max_t;
}

- (void)SetTimeDifference:(Float64)PlayStopTime RecordStopTime:(Float64)RecordStopTime AtBufPos:(SInt32)RecordStopBufferPosition
{
    [self CalcRingKKF];
    //get position of maximum KKF Value
    SInt32 KKFMaxPos;
    KKFMaxPos=[self MaximumSearchAtStartValue:0 WithEndValue:KKFLen];

    SInt32 StartOfRecordedSignal=KKFMaxPos;
    SInt32 EndOfRecordedSignal=StartOfRecordedSignal+PlaySigLen;
    Float64 Latency=PlayStopTime-(Float64)(EndOfRecordedSignal)/48.f*1000.f-RecordStopTime;
    NSLog(@"Latenz= %f",Latency);

    Float64 TimeOfFirstSample=RecordStopTime-(((Float64)RecordStopBufferPosition)/48.0f*1000.0f);
    
    Float64 TimeOfRecordedSignalEnd=TimeOfFirstSample+(((Float64)EndOfRecordedSignal)/48.0f*1000.0f);
    
    TimeDifference=RecordStopTime-TimeOfRecordedSignalEnd;

    [self setIsCalibrated:true];
    NSLog(@"TimeDifference: %f us",TimeDifference);
}

- (float)CalculateDistanceServerWithTimestamp:(Float64)SendTime
{
    [self CalcRingKKF];
    SInt32 KKFSample;
    KKFSample=[self MaximumSearchAtStartValue:0 WithEndValue:RecordSigLen];   
    

    //Float64 receiveTime;
    //receiveTime=[self GetSampleOfKKFSample:KKFSample ofSamples:4800 withTimeStamp:recordTimeTags];
    
    //SInt32 SignalTime;
    //SignalTime=(SInt32)(receiveTime-SendTime-TimeDifference);

    float Distance=0;
    //Distance=[self GetDistance:SignalTime];
    //NSLog(@"Distance: %f",Distance);
    return Distance;
}

- (float)CalculateDistanceHeadphone
{
    SInt32 KKFSize=2*RecordSigLen;
    [self ResetArrays];

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
