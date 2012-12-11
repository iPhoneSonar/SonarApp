//
//  audioController.m
//  sonar
//
//  Created by lion on 10/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "audioController.h"

// Native iphone sample rate of 44.1kHz, same as a CD.
//const Float64 SAMPLERATE = 44100.0;
const Float64 SAMPLERATE = 48000.0;
const SInt16 FRAMESIZE = 1024;
const SInt16 SAMPLES_PER_PERIOD = 48;


//AudioTimeStamp timeTags[RECORDLEN];


SInt16 kHzSin[] = {0,3916,7765,11481,15000,18263,21213,23801,
                    25981,27716,28978,29743,30000,29743,28978,27716,
                    25981,23801,21213,18263,15000,11481,7765,3916,0,
                    -3916,-7765,-11481,-15000,-18263,-21213,-23801,-25981,
                    -27716,-28978,-29743,-30000,-29743,-28978,-27716,-25981,
                    -23801,-21213,-18263,-15000,-11481,-7765,-3916};


SInt16 frameLen = 0;

@implementation audioController


@synthesize frequency;
@synthesize audioUnit;
@synthesize recordingBufferList;
@synthesize com;


// Clean up memory
- (void)dealloc {
    
    [super dealloc];
}


- (void)setFrequency:(int) value
{
    frequency = value;
}

- (void)getFrequency:(int*) value
{
    *value = frequency;
}

-(void)testSweepSigInit
{

    //check to avoid memory leaks
    if (testSweep)
    {
        if(testSweep->buf) free(testSweep->buf);
        free(testSweep);
    }
    double fstart=1000;
    double fstop=10000;
    double fsteps=2000;
    const int steps=(int)((fstop-fstart)/fsteps)+1;
    NSLog(@"Startfrequenz: %f, Stopfrequenz: %f, Frequenzschritt: %f, Anzahl Frequenzschritte: %i", fstart, fstop, fsteps, steps);
    double *fm=(double*)malloc(sizeof(double)*steps);
    SInt32 NValues=480*(steps);
    NSLog(@"Signallänge: %li Werte, Entspricht %li Frames, Entspricht %f Sekunden",NValues,NValues/1024, NValues/SAMPLERATE);
    int j=0;
    for (int i=fstart;i<=fstop;i=i+fsteps)
    {
        fm[j]=i;
        j++;
    }
    
    
    testSweep = (sig*)malloc(sizeof(sig));
    testSweep->len = NValues;
    int size = 2*(((testSweep->len)/1024)+1)*1024;
    testSweep->buf = (SInt16*)malloc(size);
    memset(testSweep->buf,0,size);
    testSweep->pos = 0;
    testSweep->samplesPerPeriod = testSweep->len;
    testSweep->shift = 0;
    for (SInt32 i=0; i<steps; i++)
    {
        for (SInt32 j=0; j<480; j++)
        {
            testSweep->buf[i*480+j]=(SInt32)(32000*sin(2*M_PI*(double)(fm[i])*(double)j/SAMPLERATE));
        }
    }
    NSLog(@"TestChirp created %i",testSweep->buf[1]);
    
    play = testSweep;
}

-(void)recordBufferInit:(SInt32)len
{
    //check to avoid memory leaks
    if(record.buf && (len !=record.len)) free(record.buf);
        
    record.len = len*1024;

    record.buf = (SInt16*)malloc(record.len*2); //SInt16 = 2 Bytes
    record.pos = 0;
}

-(void)muteSigInit
{
    //check to avoid memory leaks
    if(mute)
    {
        if(mute->buf) free(mute->buf);
        free(mute);
    }
    mute= (sig*)malloc(sizeof(sig));

    mute->len = mute->samplesPerPeriod = 1024;
    mute->buf = (SInt16*)malloc(mute->len*2); //SInt16 = 2 Bytes
    memset(mute->buf, 0,mute->len*2);
    mute->pos = 0;
    mute->shift = 0;
}


// audio render procedure, don't allocate memory, don't take any locks, don't waste time
static OSStatus playingCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
    audioController* audioUnit = (audioController*)inRefCon;
    
    if (inNumberFrames > FRAMESIZE)
    {
        NSLog(@"inNumberFrames = %ld",inNumberFrames);
        AudioOutputUnitStop(audioUnit.audioUnit);
        return noErr;
    }
	ioData->mBuffers[0].mData = (audioUnit->play->buf + audioUnit->play->pos);
    

    //the calculation of the shift is signal specific so these values should be set in the
    //signal generating functions
    audioUnit->play->pos += inNumberFrames;
    audioUnit->play->pos = (audioUnit->play->pos+audioUnit->play->shift)%audioUnit->play->samplesPerPeriod;

    frameLen = inNumberFrames;
    return noErr;
}

-(OSStatus)audioUnitInit
{
    //prepare an empty frame to mute
    [self muteSigInit];
    [self testSweepSigInit];
    //bring up the communication channel
    com = [[communicator alloc] init];
  
    [self sessionInit];
    //memset(timeTags,0,sizeof(AudioTimeStamp)*RECORDLEN);

    int kInputBus = 1;
    int kOutputBus = 0;
    OSStatus status;
        
    //audio component description
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    //get component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    //get audio units
    status = AudioComponentInstanceNew(inputComponent,  &audioUnit);
    
    //enable output
    UInt32 flag = 1;
    status = AudioUnitSetProperty(audioUnit ,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  kOutputBus,
                                  &flag, sizeof(flag));

    NSLog(@"output enable io status=%ld",status);
    
    //enable recording io
    flag = 1;
    status = AudioUnitSetProperty(audioUnit ,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &flag, sizeof(flag));
    
    NSLog(@"input enable io status=%ld",status);
    
    
    AudioStreamBasicDescription audioFormat;
    
    audioFormat.mSampleRate = SAMPLERATE;
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger; //float should be possible to
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mChannelsPerFrame = 1;
    audioFormat.mBitsPerChannel = 16;
    audioFormat.mBytesPerPacket = 2;
    audioFormat.mBytesPerFrame = 2;
    
    //we set the output as the input is not writeable
    status = AudioUnitSetProperty(audioUnit ,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &audioFormat, sizeof(audioFormat));

    NSLog(@"audioFormat status=%ld",status);

    status = AudioUnitSetProperty(audioUnit ,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &audioFormat, sizeof(audioFormat));
    
    NSLog(@"audioFormat status=%ld",status);

    
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = &recordingCallback;
    callbackStruct.inputProcRefCon = self;
    
    status = AudioUnitSetProperty(audioUnit ,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &callbackStruct, sizeof(callbackStruct));

    NSLog(@"set recordingCallback status=%ld",status);

    
    callbackStruct.inputProc = &playingCallback;
    callbackStruct.inputProcRefCon = self;
    
    status = AudioUnitSetProperty(audioUnit ,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &callbackStruct, sizeof(callbackStruct));
   
    NSLog(@"set playingCallback status=%ld",status);


    flag = 0;
    status = AudioUnitSetProperty(audioUnit ,
                                  kAudioUnitProperty_ShouldAllocateBuffer,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &flag, sizeof(flag));
    
    NSLog(@"set no allocate status=%ld",status);

 
    //use the defined record[] as buffer

    recordingBufferList = (AudioBufferList*)malloc(sizeof(AudioBufferList)) ;
    recordingBufferList->mNumberBuffers = 1;
    recordingBufferList->mBuffers[0].mData = record.buf;
    recordingBufferList->mBuffers[0].mNumberChannels = 1;


    double dData = 0;
    UInt32 uiDataSize = sizeof(double);
    status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &uiDataSize, &dData);
    NSLog(@"check current hwd samplerate = %f, status = %ld = %4.4s\n",dData, status,(char*)&status);

    float fData = 0;
    uiDataSize = sizeof(Float32);
    status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareIOBufferDuration, &uiDataSize, &fData);
    NSLog(@"check current hwd buffer duration = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);
   
    return status;
}



- (void)sessionInit
{
    OSStatus status;
    UInt32 uiDataSize;
    status = AudioSessionInitialize(NULL, NULL, NULL, self);
    NSLog(@"session init = %ld",status);
 
    UInt32 uiSessionCategory = kAudioSessionCategory_PlayAndRecord;
    status = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                                     sizeof(UInt32),
                                     &uiSessionCategory);

    NSLog(@"set category = %ld",status);
     
    UInt32 uiSessionMode = kAudioSessionMode_Measurement;
    status = AudioSessionSetProperty(kAudioSessionProperty_Mode,
                                     sizeof(UInt32),
                                     &uiSessionMode);
    
    NSLog(@"set mode = %ld",status);
    
    //as playand record sends audio output by default to the builtinreceifer,
    //first check the state and overwrite it to the speaker
    CFDictionaryRef cfdRouteDesc;
    uiDataSize = sizeof(CFDictionaryRef);
    status = AudioSessionGetProperty(kAudioSessionProperty_AudioRouteDescription, &uiDataSize, &cfdRouteDesc);
    NSLog(@"route desc = %ld",status);
    //returns an output and an input array containing dictionarys with route infos
    //if (CFIndex n = CFDictionaryGetCount(cfdRouteDesc))
    if (CFDictionaryGetCount(cfdRouteDesc))
    {
        CFArrayRef cfaOutputs = (CFArrayRef)CFDictionaryGetValue(cfdRouteDesc, kAudioSession_AudioRouteKey_Outputs);

        for(CFIndex i = 0, c = CFArrayGetCount(cfaOutputs); i < c; i++)
        {
            CFDictionaryRef cfdItem = (CFDictionaryRef)CFArrayGetValueAtIndex(cfaOutputs, i);
            CFStringRef cfsDevice = (CFStringRef)CFDictionaryGetValue(cfdItem, kAudioSession_AudioRouteKey_Type);
            
            NSLog(@"output device: %@",(NSString*)cfsDevice);
            
            if(!CFStringCompare(cfsDevice, kAudioSessionOutputRoute_BuiltInReceiver, kCFCompareCaseInsensitive))
            {
                UInt32 cfsRouteOverwrite = kAudioSessionOverrideAudioRoute_Speaker;
                uiDataSize = sizeof(UInt32);
                status = AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,
                                                 uiDataSize,
                                                 &cfsRouteOverwrite);
                
                NSLog(@"route overwrite = %ld",status);
            }
        }
        CFArrayRef cfaInputs = (CFArrayRef)CFDictionaryGetValue(cfdRouteDesc, kAudioSession_AudioRouteKey_Inputs);
        
        for(CFIndex i = 0, c = CFArrayGetCount(cfaInputs); i < c; i++)
        {
            CFDictionaryRef cfdItem = (CFDictionaryRef)CFArrayGetValueAtIndex(cfaInputs, i);
            CFStringRef cfsDevice = (CFStringRef)CFDictionaryGetValue(cfdItem, kAudioSession_AudioRouteKey_Type);
            
            NSLog(@"input device: %@",(NSString*)cfsDevice);
        }
    }
    
    CFArrayRef cfaOutputData;
    uiDataSize = sizeof(CFArrayRef);
    status = AudioSessionGetProperty(kAudioSessionProperty_OutputDestinations, &uiDataSize, &cfaOutputData);
   
    NSLog(@"destinations get status = %ld = %4.4s",status,(char*)&status);

    if (status == noErr)
    {
        CFDictionaryRef cfdAudioOutput;
        
        for (CFIndex i=0, c = CFArrayGetCount(cfaOutputData);i<c; i++)
        {
            cfdAudioOutput = (CFDictionaryRef) CFArrayGetValueAtIndex(cfaOutputData, i);
            CFNumberRef cfnRouteId = (CFNumberRef) CFDictionaryGetValue(cfdAudioOutput, kAudioSession_OutputDestinationKey_ID);
           
            SInt32 siRouteId;
            status = CFNumberGetValue(cfnRouteId, kCFNumberSInt32Type, &siRouteId);
            if (status == noErr)
            {
                NSLog(@"%ld, routeId = %ld",i,siRouteId);
            }
            
            CFStringRef cfsRouteDescription = (CFStringRef) CFDictionaryGetValue(cfdAudioOutput, kAudioSession_OutputDestinationKey_Description);
            
            NSLog(@"%ld, description = %@",i,(NSString*)cfsRouteDescription);
        }
        
    
    }
    Float32 fData;
    double dData;
    
    dData = SAMPLERATE;
    uiDataSize = sizeof(double);
    status = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareSampleRate, uiDataSize, &dData);
    NSLog(@"set perferred samplerate = %f, status = %ld = %4.4s\n",dData, status,(char*)&status);
    
    
    dData = 0;
    uiDataSize = sizeof(double);
    status = AudioSessionGetProperty(kAudioSessionProperty_PreferredHardwareSampleRate, &uiDataSize, &dData);
    NSLog(@"get perferred samplerate = %f, status = %ld = %4.4s\n",dData, status,(char*)&status);
    
    dData = 0;
    uiDataSize = sizeof(double);
    status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &uiDataSize, &dData);
    NSLog(@"get current hwd samplerate = %f, status = %ld = %4.4s\n",dData, status,(char*)&status);
    
    fData = 0;
    uiDataSize = sizeof(Float32);
    status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareIOBufferDuration, &uiDataSize, &fData);
    NSLog(@"current hwd buffer duration = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);
    
    uiDataSize = sizeof(Float32);
    status = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, uiDataSize, &fData);
    NSLog(@"set perferred buffer duration = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);    

    fData = 0;
    uiDataSize = sizeof(Float32);
    status = AudioSessionGetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, &uiDataSize, &fData);
    NSLog(@"get perferred buffer duration = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);
        
    UInt32 uiData = 0;
    uiDataSize = sizeof(UInt32);
    status = AudioSessionGetProperty(kAudioSessionProperty_InputGainAvailable, &uiDataSize, &uiData);
    
    if (status!=0)
    {
        NSLog(@"input gain available = %ld, status = %ld = %4.4s\n",uiData, status,(char*)&status);
        fData = 0.0;
        uiDataSize = sizeof(Float32);
        status = AudioSessionSetProperty(kAudioSessionProperty_InputGainScalar, uiDataSize, &fData);
        NSLog(@"set input gain scalar = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);
        
        fData = 0;
        uiDataSize = sizeof(Float32);
        status = AudioSessionGetProperty(kAudioSessionProperty_InputGainScalar, &uiDataSize, &fData);
        NSLog(@"get input gain scalar = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);
    } else
    {
        NSLog(@"input gain not available");
    }
    
    //these are only to check if all was set up the right way
    uiData = 0;
    uiDataSize = sizeof(uiData);
    status = AudioSessionGetProperty(kAudioSessionProperty_AudioCategory, &uiDataSize, &uiData);
    NSLog(@"category get status = %4.4s, data = %4.4s",(char*)&status,(char*)&uiData);

    fData = 0;
    uiDataSize = sizeof(fData);
    status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareOutputLatency, &uiDataSize, &fData);
    NSLog(@"hwd output latency status = %4.4s, data = %f",(char*)&status,fData);

    fData = 0;
    uiDataSize = sizeof(fData);
    status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareInputLatency, &uiDataSize, &fData);
    NSLog(@"hwd input latency status = %4.4s, data = %f",(char*)&status,fData);
    
    status = AudioSessionSetActive(true);
    NSLog(@"set active = %ld",status);
}


static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData)
{
    int dataSize = inNumberFrames * sizeof(Byte) * 2; // 16bit
    //NSLog(@"recordingCallback");
        
    OSStatus status;
   
    audioController* ru = (audioController*)inRefCon;
    
    AudioBufferList *bufferList = ru.recordingBufferList;
    bufferList->mBuffers[0].mDataByteSize = dataSize;
   
    //AudioSampleType *tempA = (AudioSampleType *)ioData->mBuffers[0].mData;
    //for (int i=0; i<10;i++)
    //    NSLog(@"val %d=%d",i,tempA[i] );
    if (inNumberFrames > FRAMESIZE)
    {
        NSLog(@"inNumberFrames = %ld",inNumberFrames);
        AudioOutputUnitStop(ru.audioUnit);
        return noErr;
    }
    
    //NSLog(@"frames=%ld\n AudioUnitRender status = %ld",inNumberFrames,status);

    if (ru->record.pos+inNumberFrames <= ru->record.len)
    {
        //memcpy(&(timeTags[frameIndex]),inTimeStamp,sizeof(AudioTimeStamp));
        bufferList->mBuffers[0].mData = ru->record.buf+ru->record.pos;
        
        status = AudioUnitRender(ru.audioUnit,
                                 ioActionFlags,
                                 inTimeStamp,
                                 inBusNumber,
                                 inNumberFrames,
                                 bufferList);
        
        ru->record.pos += inNumberFrames;
    
        if (ru->record.pos+inNumberFrames > ru->record.len)
        {
            NSLog(@"recording stoped, frame index = %ld",ru->record.pos);
        }
    }

    frameLen = inNumberFrames;
    return noErr;

}

//mainly used for debugging, outputs the recorded data by sending to the python server
-(void)testOutput
{
     NSString *outStr = [[NSString alloc] init];
     [com open];
     [com send:@"fileName:record.txt\n"];
     char *sOut = (char*)malloc(2000);
     char *sOutPtr = sOut;
     int len = 0;
     for (int i=0; i< record.len; i++)
     {
     //outStr = [outStr stringByAppendingFormat: @"%d,", record.buf[i]];
     sprintf(sOutPtr,"%d,",record.buf[i]);
     len += strlen(sOutPtr);
     sOutPtr = sOut + len;
     // to package the frame data check the  size of the outStr
     if (len > 1990)
     {
     if (com.host) //short test assumes that the network is also initialized
     {
     sOutPtr[len] = 0;
     outStr = [NSString stringWithFormat:@"%s\n",sOut];
     [com send:outStr];
     //NSLog(@"com part send");
     sOutPtr = sOut;
     len = 0;
     memset(sOut,0,2000);
     }
     }
     
     }
     //send the rest of the content if there is
     if (len > 0)
     {
     if (com.host) //short test assumes that the network is also initialized
     {
     //remove the last ','
     sOut[len] = 0;
     outStr = [NSString stringWithFormat:@"%s\n",sOut];
     [com send:outStr];
     NSLog(@"com send");
     }
     }
     [com send:@"fileEnd\n"];
     NSLog(@"com fileEnd send");
     [com close];
/*
    NSString *outStr = [[NSString alloc] init];
    [com open];
    [com send:@"fileName:record.txt\n"];
    char *sOut = (char*)malloc(2000);
    char *sOutPtr = sOut;
    int len = 0;
    int i=0;
    for (i=0; i< testSweep->len; i++)
    {
        //outStr = [outStr stringByAppendingFormat: @"%d,", record.buf[i]];
        sprintf(sOutPtr,"%d,",testSweep->buf[i]);
        len += strlen(sOutPtr);
        sOutPtr = sOut + len;
        // to package the frame data check the  size of the outStr
        if (len > 1990)
        {
            if (com.host) //short test assumes that the network is also initialized
            {
                sOutPtr[len] = 0;
                outStr = [NSString stringWithFormat:@"%s\n",sOut];
                [com send:outStr];
                //NSLog(@"com part send");
                sOutPtr = sOut;
                len = 0;
                memset(sOut,0,2000);
            }           
        }


    }
    //send the rest of the content if there is
    if (len > 0)
    {
        if (com.host) //short test assumes that the network is also initialized
        {
            //remove the last ','
            sOut[len] = 0;
            outStr = [NSString stringWithFormat:@"%s\n",sOut];
            [com send:outStr];
            NSLog(@"com send");
        }
    }
    [com send:@"fileEnd\n"];
    NSLog(@"com fileEnd send i:%i testSweep->len: %li",i,testSweep->len);
    [com close];
 */
}


-(void)mute:(UInt32)flag
{
    if (flag == 0)
    {
        play = mute;
    }
    else
    {
        play = testSweep;
    }
    NSLog(@"flag = %ld",flag);
}

-(OSStatus)start
{
    play->pos = 0;
    OSStatus status;
    if (recordingBufferList)
    {
        record.pos = 0;
        recordingBufferList->mBuffers[0].mData = record.buf;
        status = AudioOutputUnitStart(audioUnit);
        NSLog(@"audioUnit started status = %ld", status);
    }
    else
    {
        NSLog(@"audioUnit start error = %ld", status);
    }
    return status;
}

-(OSStatus)stop
{
    OSStatus status;
    status = AudioOutputUnitStop(audioUnit);
    NSLog(@"audioUnit stoped status = %ld", status);
    NSLog(@"frameLen = %d",frameLen);

    /*
    UInt64 div = 0;
    for (int i=0; i<RECORDLEN;i++)
    {
        div = timeTags[i].mHostTime - div;
        NSLog(@"div = %lld", div);
        div = timeTags[i].mHostTime;
        NSLog(@"timestamp =  %lld",timeTags[i].mHostTime);
    }
     */
    return status;
}

@end
