//
//  audioController.m
//  sonar
//
//  Created by lion on 10/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#ifndef DEBUG
#define NSLog(...)
#endif

#import "audioController.h"

const Float64 SAMPLERATE = 48000.0;
const SInt16 FRAMESIZE = 1024;
const SInt16 SAMPLES_PER_PERIOD = 48;
SInt16 muteFlag = 0;
char test[1000];
int testIndex = 0;
//AudioTimeStamp timeTags[RECORDLEN];

AudioTimeStamp sendtimeTags[100000];
AudioTimeStamp receivetimeTags[100000];
SInt32 count[2];



SInt16 sin1KHz[] = {0,3916,7765,11481,15000,18263,21213,23801,
                    25981,27716,28978,29743,30000,29743,28978,27716,
                    25981,23801,21213,18263,15000,11481,7765,3916,0,
                    -3916,-7765,-11481,-15000,-18263,-21213,-23801,-25981,
                    -27716,-28978,-29743,-30000,-29743,-28978,-27716,-25981,
                    -23801,-21213,-18263,-15000,-11481,-7765,-3916};

SInt16 sin12kHz[] = {15000,15000,-15000,-15000};
SInt16 sin6kHz[] = {0,21213,30000,21213,0,-21213,-30000,-21213};
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

-(void)sineSigInit
{
    //check to avoid memory leaks
    if (sine)
    {
        if(sine->buf) free(sine->buf);
        free(sine); 
    }

    sine = (sig*)malloc(sizeof(sig));

    sine->len = (1024+48);
    sine->pos = 0;
    sine->samplesPerPeriod = 48;
    sine->shift = 32;
    
    sine->buf = (SInt32*)malloc(sine->len*sizeof(SInt32)); // SInt16 = 2 bytes

    int index = 0;
    for (int i=0; i<sine->len; i++)
    {
        sine->buf[i] = sin1KHz[index];
        index = (index+1)%48;
    }

    //very important
    //set the sig play to the sine
    play = sine;

    NSLog(@"sineSigInit");
}

-(void)PulseSigInit
{
    //check to avoid memory leaks
    if (sine)
    {
        if(sine->buf) free(sine->buf);
        free(sine);
    }
    
    sine = (sig*)malloc(sizeof(sig));
    
    sine->len = 5*(1024);
    sine->pos = 0;
    sine->samplesPerPeriod = 0;
    sine->shift = 0;
    
    sine->buf = (SInt32*)malloc(sine->len*sizeof(SInt32)); // SInt16 = 2 bytes
    for (int j=0; j<1;j++)
    {
    for (int i=0; i<4; i++)
    {
        sine->buf[j*4+i] = sin12kHz[i];
    }
    }
    
    //very important
    //set the sig play to the sine
    play = sine;
    
    NSLog(@"PulseSigInit");
}

-(void)testSweepSigInit
{
    //check to avoid memory leaks
    if (testSweep)
    {
        if(testSweep->buf) free(testSweep->buf);
        free(testSweep);
    }

    testSweep = (sig*)malloc(sizeof(sig));

    SInt32 shift = 0;
    SInt32 size = 22528;
    testSweep->buf = (SInt32*)malloc(size*sizeof(SInt32));
    
    sweepGen((testSweep->buf)+shift);
    
    testSweep->len = size;
    testSweep->pos = 0;
    testSweep->samplesPerPeriod = size;
    testSweep->shift = 0;
    NSLog(@"Sendesignal Länge: %li Samples",testSweep->len);
    play = testSweep;
}

-(void)recordBufferInitSamples
{
    //check to avoid memory leaks
    UInt32 uiExtention = 2*1024;
    if(play->len !=record.len - uiExtention)
    {
        record.len = play->len + uiExtention;
        if(record.buf)
        {
            free(record.buf);
            record.buf = NULL;
        }
        record.buf = (SInt32*)malloc(record.len*sizeof(SInt32)); //SInt16 = 2 Bytes
    }
    memset(record.buf,0,record.len*sizeof(SInt32));
    NSLog(@"Empfangssignal Länge: %li Samples",record.len);
    record.pos = 0;
}

-(void)recordBufferInit:(SInt32)len
{
    //check to avoid memory leaks
    if(len !=record.len)
    {
        record.len = len*1024;
        if(record.buf)
        {
            free(record.buf);
            record.buf = NULL;
        }
        record.buf = (SInt32*)malloc(record.len*sizeof(SInt32)); //SInt16 = 2 Bytes
    }
    memset(record.buf,0,record.len*2);

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
    mute->buf = (SInt32*)malloc(mute->len*sizeof(SInt32)); //SInt16 = 2 Bytes
    memset(mute->buf, 0,mute->len*sizeof(SInt32));
    mute->pos = 0;
    mute->shift = 0;
}

// audio render procedure, don't allocate memory, don't take any locks, don't waste time
static OSStatus playingCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
    test[testIndex] = 'p';
    testIndex ++;
    audioController* audioUnit = (audioController*)inRefCon;
    
    if (inNumberFrames > FRAMESIZE)
    {
        NSLog(@"inNumberFrames = %ld",inNumberFrames);
        AudioOutputUnitStop(audioUnit.audioUnit);
        return noErr;
    }

    
	ioData->mBuffers[0].mData = (audioUnit->play->buf + audioUnit->play->pos);

    audioUnit->play->pos += inNumberFrames;

    if (audioUnit->play->pos + inNumberFrames > audioUnit->play->len)
    {
        memcpy(&(sendtimeTags[count[0]]),inTimeStamp,sizeof(AudioTimeStamp));
        count[0]++;
        ioData->mBuffers[0].mData = audioUnit->mute->buf;
        audioUnit->play->pos -= inNumberFrames;
    }

    frameLen = inNumberFrames;
    return noErr;
}

-(OSStatus)audioUnitInit
{
    [self sessionInit];
    //bring up the communication channel
    com = [[communicator alloc] init];


    //prepare an empty frame to mute
    [self muteSigInit];
    [self recordBufferInit: 10];
    //[self sineSigInit];
    [self testSweepSigInit];
    
    int kOutputBus = 0;
    int kInputBus = 1;
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
    UInt32 uiSize = 0;
 
    memset(&audioFormat,0,sizeof(AudioStreamBasicDescription));
    audioFormat.mSampleRate = SAMPLERATE;
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mBytesPerPacket = 4;
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mBytesPerFrame = 4;
    audioFormat.mChannelsPerFrame = 2; //stereo but we fill the second buffer with zeros
    audioFormat.mBitsPerChannel = 16;

    
    //we set the output as the input is not writeable
    status = AudioUnitSetProperty(audioUnit ,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &audioFormat, sizeof(audioFormat));

    NSLog(@"audioFormat bus =%d, status=%ld",kInputBus,status);

    status = AudioUnitSetProperty(audioUnit ,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &audioFormat, sizeof(audioFormat));
    
    NSLog(@"audioFormat bus =%d, status=%ld",kOutputBus,status);

    status = AudioUnitGetProperty(audioUnit ,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &audioFormat, &uiSize);

    NSLog(@"AudioUnitGetPorperty Bus =%d", kInputBus);
    NSLog(@"mSampleRate =%f", audioFormat.mSampleRate);
    NSLog(@"mFormatID = %ld", audioFormat.mFormatID);
    NSLog(@"mFormatFlags =%ld", audioFormat.mFormatFlags);
    NSLog(@"mBytesPerPacket =%ld", audioFormat.mBytesPerPacket);
    NSLog(@"mFramesPerPacket =%ld", audioFormat.mFramesPerPacket);
    NSLog(@"mChannelsPerFrame =%ld", audioFormat.mChannelsPerFrame);
    NSLog(@"mBitsPerChannel =%ld", audioFormat.mBitsPerChannel);
    NSLog(@"mReserved =%ld", audioFormat.mReserved);


    status = AudioUnitGetProperty(audioUnit ,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kOutputBus,
                                  &audioFormat, &uiSize);


    NSLog(@"AudioUnitGetPorperty Bus =%d", kOutputBus);
    NSLog(@"mSampleRate =%f", audioFormat.mSampleRate);
    NSLog(@"mFormatID = %ld", audioFormat.mFormatID);
    NSLog(@"mFormatFlags =%ld", audioFormat.mFormatFlags);
    NSLog(@"mBytesPerPacket =%ld", audioFormat.mBytesPerPacket);
    NSLog(@"mFramesPerPacket =%ld", audioFormat.mFramesPerPacket);
    NSLog(@"mChannelsPerFrame =%ld", audioFormat.mChannelsPerFrame);
    NSLog(@"mBitsPerChannel =%ld", audioFormat.mBitsPerChannel);
    NSLog(@"mReserved =%ld", audioFormat.mReserved);
    
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
    recordingBufferList->mBuffers[0].mNumberChannels = 2;
    
    return status;
}

- (void)sessionInit
{
    OSStatus status;
    UInt32 uiDataSize;
    count[0]=0;
    count[1]=0;
    
    status = AudioSessionInitialize(NULL, NULL, NULL, self);
    NSLog(@"session init = %ld",status);
 
    UInt32 uiSessionCategory = kAudioSessionCategory_PlayAndRecord;
    status = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                                     sizeof(UInt32),
                                     &uiSessionCategory);

    NSLog(@"set category = %ld",status);
     
    UInt32 uiSessionMode = kAudioSessionMode_Measurement;
    //UInt32 uiSessionMode = kAudioSessionMode_Default;
    //UInt32 uiSessionMode = kAudioSessionMode_VoiceChat;
    status = AudioSessionSetProperty(kAudioSessionProperty_Mode,
                                     sizeof(UInt32),
                                     &uiSessionMode);
    
    NSLog(@"set mode = %ld",status);


    UInt32 uiDefaultSpeaker = kAudioSessionOverrideAudioRoute_Speaker;
    status = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker,
                                     sizeof(UInt32),
                                     &uiDefaultSpeaker);

    NSLog(@"set mode = %ld",status);
    


/*
    //does not work on iphone
    CFNumberRef cfnOutData;
    uiDataSize = sizeof(CFNumberRef);
    status = AudioSessionGetProperty(kAudioSessionProperty_OutputDestination, &uiDataSize, &cfnOutData);
    NSLog(@"destination get status = %ld = %4.4s\n DataSize = %ld",status,(char*)&status,uiDataSize);

    SInt32 siDest;
    status = CFNumberGetValue(cfnOutData, kCFNumberSInt32Type, &siDest);
    if (status == noErr)
    {
        NSLog(@"destination = %ld",siDest);
    }
  */

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
                //possible values
                //kAudioSessionOutputRoute_LineOut
                //kAudioSessionOutputRoute_Headphones
                //kAudioSessionOutputRoute_BluetoothHFP
                //kAudioSessionOutputRoute_BluetoothA2DP
                //kAudioSessionOutputRoute_BuiltInReceiver
                //kAudioSessionOutputRoute_BuiltInSpeaker
                //kAudioSessionOutputRoute_USBAudio
                //kAudioSessionOutputRoute_HDMI
                //kAudioSessionOutputRoute_AirPlay
                
                //UInt32 cfsRouteOverwrite = kAudioSessionOverrideAudioRoute_Speaker;
                UInt32 cfsRouteOverwrite = kAudioSessionOverrideAudioRoute_None;
                
                uiDataSize = sizeof(UInt32);
                status = AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,
                                                 uiDataSize,
                                                 &cfsRouteOverwrite);
                
                NSLog(@"route overwrite = %ld",status);


                //kAudioSessionProperty_InputSource
                
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
    NSLog(@"perferred samplerate = %f, status = %ld = %4.4s\n",dData, status,(char*)&status);

/*
    fData = 0.022f;
    uiDataSize = sizeof(Float32);
    status = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, uiDataSize, &fData);
    NSLog(@"set perferred buffer duration = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);
  */  

    fData = 0;
    uiDataSize = sizeof(Float32);
    status = AudioSessionGetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, &uiDataSize, &fData);
    NSLog(@"perferred buffer duration = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);
    
    dData = 0;
    uiDataSize = sizeof(double);
    status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &uiDataSize, &dData);
    NSLog(@"current hwd samplerate = %f, status = %ld = %4.4s\n",dData, status,(char*)&status);

    fData = 0;
    uiDataSize = sizeof(Float32);
    status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareIOBufferDuration, &uiDataSize, &fData);
    NSLog(@"current hwd buffer duration = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);
   
    fData = 0;
    uiDataSize = sizeof(Float32);
    status = AudioSessionGetProperty(kAudioSessionProperty_InputGainScalar, &uiDataSize, &fData);
    NSLog(@"input gain scalar = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);

    fData = 0;
    uiDataSize = sizeof(Float32);
    status = AudioSessionSetProperty(kAudioSessionProperty_InputGainScalar, uiDataSize, &fData);
    NSLog(@"input gain scalar = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);

    UInt32 uiData = 0;
    uiDataSize = sizeof(UInt32);
    status = AudioSessionGetProperty(kAudioSessionProperty_InputGainAvailable, &uiDataSize, &uiData);
    NSLog(@"input gain available = %ld, status = %ld = %4.4s\n",uiData, status,(char*)&status);
    
    
    /*
     kAudioSessionProperty_PreferredHardwareSampleRate           = 'hwsr',   // Float64          (get/set)
     kAudioSessionProperty_PreferredHardwareIOBufferDuration     = 'iobd',   // Float32          (get/set)
     kAudioSessionProperty_AudioCategory                         = 'acat',   // UInt32           (get/set)
     kAudioSessionProperty_AudioRouteChange                      = 'roch',   // CFDictionaryRef  (property listener)
     kAudioSessionProperty_CurrentHardwareSampleRate             = 'chsr',   // Float64          (get only)
     kAudioSessionProperty_CurrentHardwareInputNumberChannels    = 'chic',   // UInt32           (get only)
     kAudioSessionProperty_CurrentHardwareOutputNumberChannels   = 'choc',   // UInt32           (get only)
     kAudioSessionProperty_CurrentHardwareOutputVolume           = 'chov',   // Float32          (get only/property listener)
     kAudioSessionProperty_CurrentHardwareInputLatency           = 'cilt',   // Float32          (get only)
     kAudioSessionProperty_CurrentHardwareOutputLatency          = 'colt',   // Float32          (get only)
     kAudioSessionProperty_CurrentHardwareIOBufferDuration       = 'chbd',   // Float32          (get only)
     kAudioSessionProperty_OtherAudioIsPlaying                   = 'othr',   // UInt32           (get only)
     kAudioSessionProperty_OverrideAudioRoute                    = 'ovrd',   // UInt32           (set only)
     kAudioSessionProperty_AudioInputAvailable                   = 'aiav',   // UInt32           (get only/property listener)
     kAudioSessionProperty_ServerDied                            = 'died',   // UInt32           (property listener)
     kAudioSessionProperty_OtherMixableAudioShouldDuck           = 'duck',   // UInt32           (get/set)
     kAudioSessionProperty_OverrideCategoryMixWithOthers         = 'cmix',   // UInt32           (get, some set)
     kAudioSessionProperty_OverrideCategoryDefaultToSpeaker      = 'cspk',   // UInt32           (get, some set)
     kAudioSessionProperty_OverrideCategoryEnableBluetoothInput  = 'cblu',   // UInt32           (get, some set)
     kAudioSessionProperty_InterruptionType                      = 'type',   // UInt32           (get only)
     kAudioSessionProperty_Mode                                  = 'mode',   // UInt32           (get/set)
     kAudioSessionProperty_InputSources                          = 'srcs',   // CFArrayRef       (get only/property listener)
     kAudioSessionProperty_OutputDestinations                    = 'dsts',   // CFArrayRef       (get only/property listener)
     kAudioSessionProperty_InputSource                           = 'isrc',   // CFNumberRef      (get/set)
     kAudioSessionProperty_OutputDestination                     = 'odst',   // CFNumberRef      (get/set)
     kAudioSessionProperty_InputGainAvailable                    = 'igav',   // UInt32           (get only/property listener)
     kAudioSessionProperty_InputGainScalar                       = 'igsc',   // Float32          (get/set/property listener)
     kAudioSessionProperty_AudioRouteDescription                 = 'crar',   // CFDictionaryRef  (get 
     */
     
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
    test[testIndex] = 'r';
    testIndex ++;
    
    UInt32 inBusNumberX = inBusNumber;
    UInt32 inNumberFramesX = inNumberFrames;


    int dataSize = inNumberFrames * sizeof(SInt32); // 16bit twice
    //NSLog(@"recordingCallback");

    OSStatus status;

    audioController* ru = (audioController*)inRefCon;
    
    AudioBufferList *bufferList = ru.recordingBufferList;
    bufferList->mBuffers[0].mDataByteSize = dataSize;

    if (inNumberFrames > FRAMESIZE)
    {
        NSLog(@"inNumberFrames = %ld",inNumberFrames);
        AudioOutputUnitStop(ru.audioUnit);
        return noErr;
    }

    if (ru->record.pos+inNumberFrames <= ru->record.len)
    {
        memcpy(&(receivetimeTags[count[1]]),inTimeStamp,sizeof(AudioTimeStamp));
        count[1]++;
        bufferList->mBuffers[0].mData = ru->record.buf+ru->record.pos;
        //AudioUnitRenderActionFlags ioActionFlags;
        status = AudioUnitRender(ru.audioUnit,
                                 ioActionFlags,
                                 inTimeStamp,
                                 inBusNumber,
                                 inNumberFrames,
                                 bufferList);
        ru->record.pos += inNumberFrames;
    
        if (ru->record.pos+inNumberFrames > ru->record.len)
        {
            NSLog(@"recording stoped");
            NSLog(@"AudioUnitRender status = %ld",status);
            NSLog(@"frame index = %ld",ru->record.pos);
            NSLog(@"mDataByteSize = %ld",bufferList->mBuffers[0].mDataByteSize);
            NSLog(@"mNumberChannels = %ld",bufferList->mBuffers[0].mNumberChannels);
            NSLog(@"inNumberFramesX = %ld", inNumberFramesX);
            NSLog(@"inBusNumberX = %ld", inBusNumberX);
            NSLog(@"ioActionFlags = %ld",*ioActionFlags);
        }
    }
    frameLen = inNumberFrames;
    return noErr;
}

//mainly used for debugging, outputs the recorded data by sending to the python server
-(void)testOutput
{
    NSLog(@"testOutput started");
    SInt32 KKFSize=2*play->len;
    SInt64* AKkf;
    AKkf = (SInt64*)malloc(KKFSize*sizeof(SInt64));
    KKF(record.buf, play->buf, AKkf, play->len);

    UInt32 FirstPeak=MaximumSuche(AKkf, 0, KKFSize);
    NSLog(@"erster Peak bei %li, entspricht NRL bei 1 Geräte System",FirstPeak);
    UInt32 Offset=40;
    UInt32 SecondPeak=MaximumSuche(AKkf,FirstPeak+Offset,KKFSize);
    NSLog(@"zweiter Peak bei %li, entspricht Ziel bei 1 Geräte System (offset für Mindestentfernung %li Samples)",SecondPeak,Offset);

    float Distance=(float)(SecondPeak-FirstPeak);
    float DistanceM=Distance/SAMPLERATE*343;
    
    NSString *outStr = [[NSString alloc] init];
    NSLog(@"0end mSampleTime: %f, receive mSampleTime: %f , div: %f",sendtimeTags[0].mSampleTime,receivetimeTags[0].mSampleTime,receivetimeTags[0].mSampleTime-sendtimeTags[0].mSampleTime);
    NSLog(@"1send mSampleTime: %f, receive mSampleTime: %f , div: %f",sendtimeTags[1].mSampleTime,receivetimeTags[1].mSampleTime,receivetimeTags[1].mSampleTime-sendtimeTags[1].mSampleTime);
    NSLog(@"2send mSampleTime: %f, receive mSampleTime: %f , div: %f",sendtimeTags[2].mSampleTime,receivetimeTags[2].mSampleTime,receivetimeTags[2].mSampleTime-sendtimeTags[2].mSampleTime);
    NSLog(@"3send mSampleTime: %f, receive mSampleTime: %f , div: %f",sendtimeTags[3].mSampleTime,sendtimeTags[4].mSampleTime,sendtimeTags[4].mSampleTime-sendtimeTags[3].mSampleTime);
    
    [com open];
    [com send:@"fileName:record_2k_6k_6k_10k_.txt\n"];
    char *sOut = (char*)malloc(2000);
    char *sOutPtr = sOut;
    int len = 0;
    for (int i=0; i< record.len; i++)
    {
        SInt16 TMP;
        TMP = ((SInt16*)record.buf)[2*i+1];
        sprintf(sOutPtr,"%i,",TMP);
        len += strlen(sOutPtr);
        sOutPtr = sOut + len;
        // to package the frame data check the  size of the outStr
        if (len > 1990)
        {
            if (com.host) //short test assumes that the network is initialized
            {
                sOutPtr[len] = 0;
                outStr = [NSString stringWithFormat:@"%s\n",sOut];
                [com send:outStr];
                sOutPtr = sOut;
                len = 0;
                memset(sOut,0,2000);
            }
        }
    }
    //send the rest of the content if there is
    if (len > 0)
    {
        if (com.host) //short test assumes that the network is initialized
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
    
    [com send:@"fileName:play_2k_6k_6k_10k_.txt\n"];
    len = 0;
    memset(sOut,0,2000);
    sOutPtr=sOut;
    for (int i=0; i< play->len; i++)
    {
        SInt16 TMP;
        TMP = ((SInt16*)play->buf)[2*i];
        sprintf(sOutPtr,"%i,",TMP);
        len += strlen(sOutPtr);
        sOutPtr = sOut + len;
        // to package the frame data check the  size of the outStr
        if (len > 1990)
        {
            if (com.host) //short test assumes that the network is initialized
            {
                sOutPtr[len] = 0;
                outStr = [NSString stringWithFormat:@"%s\n",sOut];
                [com send:outStr];
                sOutPtr = sOut;
                len = 0;
                memset(sOut,0,2000);
            }
        }
    }
    //send the rest of the content if there is
    if (len > 0)
    {
        if (com.host) //short test assumes that the network is initialized
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
    
    
    [com send:@"fileName:KKF_2k_6k_6k_10k_.txt\n"];
    len = 0;
    memset(sOut,0,2000);
    sOutPtr=sOut;
    for (int i=0; i< KKFSize; i++)
    {
        sprintf(sOutPtr,"%lli,",AKkf[i]);
        len += strlen(sOutPtr);
        sOutPtr = sOut + len;
        // to package the frame data check the  size of the outStr
        if (len > 1990)
        {
            if (com.host) //short test assumes that the network is initialized
            {
                sOutPtr[len] = 0;
                outStr = [NSString stringWithFormat:@"%s\n",sOut];
                [com send:outStr];
                sOutPtr = sOut;
                len = 0;
                memset(sOut,0,2000);
            }
        }
    }
    //send the rest of the content if there is
    if (len > 0)
    {
        if (com.host) //short test assumes that the network is initialized
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

    //NSLog(@"reihenfolge %s",test);

    
    NSLog(@"erster Peak bei %li, entspricht NRL bei 1 Geräte System",FirstPeak);
    NSLog(@"zweiter Peak bei %li, entspricht Ziel bei 1 Geräte System (offset für Mindestentfernung %li Samples)",SecondPeak,Offset);
    NSLog(@"Entfernung für ein Geräte System: %f Samples, entspricht %f Meter",Distance, DistanceM);

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
        NSLog(@"audioUnit started status = %ld", status);
        status = AudioOutputUnitStart(audioUnit);
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
