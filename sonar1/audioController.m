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
#include <sys/time.h>

const Float64 SAMPLERATE = 48000.0;
const SInt16 FRAMESIZE = 1024;
const SInt16 SAMPLES_PER_PERIOD = 48;
const SInt16 SendAllnFrames=4;

//double recSample;
//double plaSample;
//UInt64 recHost;
//UInt64 plaHost;

UInt64 uiTimestamp[100];
UInt16 uiFramePos[100];
UInt16 uiPosX;
bool IsCalibrated2=false;
int cnt=0;

@implementation audioController

@synthesize audioUnit;
@synthesize recordingBufferList;
@synthesize com;
@synthesize proc;


// Clean up memory
- (void)dealloc
{
    NSLog(@"audiocontroller dealloc");
    [super dealloc];
}

- (audioController*)init
{
    memset(uiFramePos,0,sizeof(uiFramePos));
    memset(uiTimestamp,0,sizeof(uiTimestamp));
    uiPosX = 0;
    
    com = [[communicator alloc] init];
    proc = [processing alloc];
    
    if([self sendSigInit])
    {
        NSLog(@"error sendSigInit");
    }
    if([self zeroSigInit])
    {
         NSLog(@"error zeroSigInit");
    }
    if([self recordBufferInitSamples])
    {
         NSLog(@"error recordBufferInitSamples");;
    }
    play = sendSig;
    
    [self sessionInit]; //return values
    [self audioUnitInit]; //return values

    //if no headphone is connected we know its a server
    //[self initServer];
    NSLog(@"audiocontroller init");
    return self;
}

//create block for setting the output lable from the communicator
- (fpComReturn)fComReturn
{
    fpComReturn comReturn = ^ SInt16 (NSString* strMsg)
    {
        NSLog(@"strMsg from server:\n %@.\n",strMsg);
        LabelOutput.text = strMsg;
        return 0;
    };
    return [[comReturn copy] autorelease];
}


-(SInt16)initClient
{
    NSLog(@"initClient");
    if([com clientConnect])
    {
        return -1;
    }
    play = sendSig;
    //send chirp on gui screen click -> button event (on start button)
    //tcp transmitt timestamp -> send in playing callback
    //wait for tcp transmitted msg (distance) -> handled in communicator socketclientcallback
    //  function pointer to comRet to display msg in lable
    //returnvalue (parametertype parameter) {implementation}

    [com setFComReturn:[self fComReturn]];
    
    //show distance

    return 0;
}


//create a block to do the audioprocessing of the server from the comunicator
- (fpDoProc)fDoProc
{
    NSLog(@"fDoProc init");
    fpDoProc doProc = ^ SInt16 (void)
    {
        //
        NSLog(@"Do Proc");
        [self stop];
        //processing
        [[self proc]SetSignalDetailsRecord:self->recordBuf->buf Play:self->sendSig->buf RecordLen:self->recordBuf->len Playlen:self->sendSig->len];         //set pointers

        //if ([[ac proc]isCalibrated])
        //TODO: calc Distance
        if ([[self proc]isCalibrated] && IsCalibrated2)
        {
            int nTimeStamps=self->sendSig->len/FRAMESIZE/SendAllnFrames;
            UInt64 *TimestampRecv=self.com.uiTimestampRecv;
            UInt64 *TimestampOwn=self.com.uiTimestamp;
            [[self proc]CalculateDistanceRecvTimeStamp:TimestampRecv TimestampOwn:TimestampOwn nTimeStamps:nTimeStamps];
            NSLog(@"end of distance Measurement");
            [com setUiPos:nTimeStamps];
        }
        else
        {
            //TODO: remove double Calibration
            if ([[self proc]isCalibrated])
            {
                IsCalibrated2=true;
            }
            int nTimeStamps=self->sendSig->len/FRAMESIZE/SendAllnFrames;
            UInt64 *TimestampRecv=self.com.uiTimestampRecv;
            UInt64 *TimestampOwn=self.com.uiTimestamp;
            [[self proc]CalculateNetworklatencyRecvTimeStamp:TimestampRecv TimestampOwn:TimestampOwn nTimeStamps:nTimeStamps];
            NSLog(@"end of calibration");
            [com setUiPos:nTimeStamps];
            
        }
        return 0;
    };
    return [[doProc copy] autorelease];
}

//create a block to start the audio session
- (fpStart)fStart
{
    NSLog(@"fStart");
    fpStart start = ^ SInt16 (void)
    {
        NSLog(@"start");
        [self start];
        return 0;
    };
    return [[start copy] autorelease];
}


-(SInt16)initServer
{
    /* it was just for testing the needed time between two getTimestamp calls
     the result is <5 usec on the iphone 3
    UInt64 uiTimestampUsec[100];
    for (int x=0; x<20;x++)
        uiTimestampUsec[x] = [com getTimestampUsec];
    for (int x=0; x<20;x++)
        NSLog(@"uiTimestamp: %lld.\n",uiTimestampUsec[x]);

    //debug
    return 0;
    */
    [com setFDoProc: [self fDoProc]];
    [com setFStart: [self fStart]];
    [com setUiPos: sendSig->len/FRAMESIZE/SendAllnFrames];
    NSLog(@"com uiPos %d",com.uiPos);
    NSLog(@"initServer");
    if([com serverStart])
    {
        return -1;
    }

    play = zeroSig;
    
    //playingcallback mute <- done by decition in playingCallback
    //init ringbuffer <- returning pointer on overflow in recordingCallback
    //wait for timestamp <- done in acceptcallback
    //if no headphone is connected calibration follows (measurement  view
    //display waiting for calibration
    LabelOutput.text = @"waiting for calibration";
    //the audiounid is started once a client sends the first timestamp!
    //when started next steps are handled from recording callback

    //  process signal
    //  response calibration successful ???
    // (1) wait again for signal (display waiting for measurement //next/ distance, waiting for newe
    //      measurement)
    //  process
    //  response and display distance
    //  back to (1) 
    return 0;
}


-(SInt16)sendSigInit
{
    //check to avoid memory leaks
    if (sendSig)
    {
        if(sendSig->buf)
        {
            free(sendSig->buf);
        }
        free(sendSig);
    }
    
    sendSig = (sig*)malloc(sizeof(sig));
    if (sendSig == NULL)
    {
        NSLog(@"error sendSigInit");
        return -1;
    }
    memset(sendSig,0,sizeof(struct sig));

    SInt32 len = (30*48*2*4)*2; //~240ms

    sendSig->buf = (SInt32*)malloc((len)*sizeof(SInt32));
    if (sendSig == NULL)
    {
        NSLog(@"error sendSigInit");
        return -1;
    }
    memset(sendSig->buf,0,(len)*sizeof(SInt32));

    [proc sendSigGen:sendSig->buf: len];
    
    sendSig->len = len;
    sendSig->pos = 0;

    NSLog(@"Sendesignal Länge: %li Samples",sendSig->len);
    return 0;
}

-(SInt16)zeroSigInit
{
    if (zeroSig)
    {
        if(zeroSig->buf)
        {
            free(zeroSig->buf);
        }
        free(zeroSig);
    }

    zeroSig = (sig*)malloc(sizeof(sig));
    memset(zeroSig,0,sizeof(sig));

    SInt32 len = 1024;

    zeroSig->buf = (SInt32*)malloc(len*sizeof(SInt32));
    if (zeroSig->buf == NULL)
    {
        NSLog(@"error zeroSigInit");
        return -1;
    }
    memset(zeroSig->buf,0,len*sizeof(SInt32));
    zeroSig->len = len;
    
    return 0;
}

-(SInt16)recordBufferInitSamples
{
    //check to avoid memory leaks
    if (recordBuf)
    {
        if(recordBuf->buf)
        {
            free(recordBuf->buf);
        }
        free(recordBuf);
    }

    recordBuf = (sig*)malloc(sizeof(sig));
    memset(recordBuf,0,sizeof(sig));

    UInt32 uiExtention = 4*1024;
    if(sendSig == NULL)
    {
        NSLog(@"error sendSig undefined");
        return -1;
    }

    SInt32 len = sendSig->len + uiExtention;

    recordBuf->buf = (SInt32*)malloc(len*sizeof(SInt32)); //SInt16 = 2 Bytes
    if (recordBuf->buf == NULL)
    {
        NSLog(@"error recordBufferInitSamples");
        return -1;
    }
    memset(recordBuf->buf,0,len*sizeof(SInt32));
    recordBuf->len = len;
    //NSLog(@"Empfangssignal Länge: %li Samples",recordBuf->len);

    //make the connections between our buffer and the buffer representaion of the callback function
    recordingBufferList = (AudioBufferList*)malloc(sizeof(AudioBufferList)) ;
    recordingBufferList->mNumberBuffers = 1;
    recordingBufferList->mBuffers[0].mData = recordBuf->buf;
    recordingBufferList->mBuffers[0].mNumberChannels = 2;

    return 0;
}

// audio render procedure, don't allocate memory, don't take any locks, don't waste time
static OSStatus playingCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{

    //NSLog(@"playing timestamp:%0.f host: %lld\n",inTimeStamp->mSampleTime - plaSample, inTimeStamp->mHostTime - plaHost);
    //UInt64 plaHost = inTimeStamp->mHostTime;
    //plaSample = inTimeStamp->mSampleTime;
    //duration of a frame is about 0.02133 seconds
    //needs to be the first thing we do to avoid latencies
    struct timeval TimeStamp;
    gettimeofday(&TimeStamp, NULL);
    uiTimestamp[uiPosX] = ((UInt64)TimeStamp.tv_sec*1000*1000) + TimeStamp.tv_usec;
    //NSLog(@"ts=%15lld,mh=%15lld",uiTimestamp[uiPos],plaHost);

    audioController* ac = (audioController*)inRefCon; //about 6 usec on the iphone 3

    
    if (uiPosX >= 100)
    {
        NSLog(@"uiPos");
        [ac stop];
        uiPosX = 0;
    }
    
    if (inNumberFrames > FRAMESIZE)
    {
        NSLog(@"inNumberFrames = %ld",inNumberFrames);
        AudioOutputUnitStop(ac.audioUnit);
        return noErr;
    }

	ioData->mBuffers[0].mData = (ac->play->buf + ac->play->pos);

    //server does no play back
    if([[ac com]connectionState] == CS_SERVER)
    {
        return  noErr;
    }
    //client plays the buffer content once
    else if([[ac com]connectionState] == CS_ClIENT)
    {
        //send the TimeStamp with each frame
        if (cnt%SendAllnFrames==(SendAllnFrames-1))
        {
        uiFramePos[uiPosX] = inTimeStamp->mSampleTime;
        char sTimeStamp[50];
        sprintf(sTimeStamp,"%lld %0.f",uiTimestamp[uiPosX++],inTimeStamp->mSampleTime);
        NSLog(@"sTimestamp %s",sTimeStamp);
        [[ac com] sendNew:sTimeStamp];
        }
        cnt++;
        ac->play->pos += inNumberFrames;
        //if all frames are send the client work is completed
        if (ac->play->pos + inNumberFrames > ac->play->len)
        {
            [ac stop];
            NSLog(@"ac stoped");
        }
    }
    //assume that without network one device with headphones is used
    //playing and recording
    else if([[ac com]connectionState] == CS_DISCONNECTED)
    {
        ac->play->pos += inNumberFrames;
        //if all frames are send the client work is completed
        if (ac->play->pos + inNumberFrames > ac->play->len)
        {
            //nothing more to send, but audio unit need to run for recording
            ioData->mBuffers[0].mData = ac->zeroSig->buf;
            ac->play->pos -= inNumberFrames; //to prevent an overflow
        }
    }
    return noErr;
}

-(OSStatus)audioUnitInit
{
    //bring up the communication channel
    proc = [[processing alloc] init];
    [proc InitializeArrays];

    //prepare an empty frame to mute
    
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

    //NSLog(@"output enable io status=%ld",status);
    
    //enable recording io
    flag = 1;
    status = AudioUnitSetProperty(audioUnit ,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &flag, sizeof(flag));
    
    //NSLog(@"input enable io status=%ld",status);
    
    
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

    //NSLog(@"audioFormat bus =%d, status=%ld",kInputBus,status);

    status = AudioUnitSetProperty(audioUnit ,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &audioFormat, sizeof(audioFormat));
    
    //NSLog(@"audioFormat bus =%d, status=%ld",kOutputBus,status);

    status = AudioUnitGetProperty(audioUnit ,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &audioFormat, &uiSize);

    //NSLog(@"AudioUnitGetPorperty Bus =%d", kInputBus);
    //NSLog(@"mSampleRate =%f", audioFormat.mSampleRate);
    //NSLog(@"mFormatID = %ld", audioFormat.mFormatID);
    //NSLog(@"mFormatFlags =%ld", audioFormat.mFormatFlags);
    //NSLog(@"mBytesPerPacket =%ld", audioFormat.mBytesPerPacket);
    //NSLog(@"mFramesPerPacket =%ld", audioFormat.mFramesPerPacket);
    //NSLog(@"mChannelsPerFrame =%ld", audioFormat.mChannelsPerFrame);
    //NSLog(@"mBitsPerChannel =%ld", audioFormat.mBitsPerChannel);
    //NSLog(@"mReserved =%ld", audioFormat.mReserved);


    status = AudioUnitGetProperty(audioUnit ,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kOutputBus,
                                  &audioFormat, &uiSize);


    //NSLog(@"AudioUnitGetPorperty Bus =%d", kOutputBus);
    //NSLog(@"mSampleRate =%f", audioFormat.mSampleRate);
    //NSLog(@"mFormatID = %ld", audioFormat.mFormatID);
    //NSLog(@"mFormatFlags =%ld", audioFormat.mFormatFlags);
    //NSLog(@"mBytesPerPacket =%ld", audioFormat.mBytesPerPacket);
    //NSLog(@"mFramesPerPacket =%ld", audioFormat.mFramesPerPacket);
    //NSLog(@"mChannelsPerFrame =%ld", audioFormat.mChannelsPerFrame);
    //NSLog(@"mBitsPerChannel =%ld", audioFormat.mBitsPerChannel);
    //NSLog(@"mReserved =%ld", audioFormat.mReserved);
    
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = &recordingCallback;
    callbackStruct.inputProcRefCon = self;
    
    status = AudioUnitSetProperty(audioUnit ,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &callbackStruct, sizeof(callbackStruct));

    //NSLog(@"set recordingCallback status=%ld",status);

    
    callbackStruct.inputProc = &playingCallback;
    callbackStruct.inputProcRefCon = self;
    
    status = AudioUnitSetProperty(audioUnit ,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &callbackStruct, sizeof(callbackStruct));
   
    //NSLog(@"set playingCallback status=%ld",status);


    flag = 0;
    status = AudioUnitSetProperty(audioUnit ,
                                  kAudioUnitProperty_ShouldAllocateBuffer,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &flag, sizeof(flag));
    
    //NSLog(@"set no allocate status=%ld",status);

    return status;
}

- (void)sessionInit
{
    OSStatus status;
    UInt32 uiDataSize;
    //timeTagIndex[0]=0;
    //timeTagIndex[1]=0;
    
    status = AudioSessionInitialize(NULL, NULL, NULL, self);
    //NSLog(@"session init = %ld",status);
 
    UInt32 uiSessionCategory = kAudioSessionCategory_PlayAndRecord;
    status = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                                     sizeof(UInt32),
                                     &uiSessionCategory);

    //NSLog(@"set category = %ld",status);
     
    UInt32 uiSessionMode = kAudioSessionMode_Measurement;
    //UInt32 uiSessionMode = kAudioSessionMode_Default;
    //UInt32 uiSessionMode = kAudioSessionMode_VoiceChat;
    status = AudioSessionSetProperty(kAudioSessionProperty_Mode,
                                     sizeof(UInt32),
                                     &uiSessionMode);
    
    //NSLog(@"set mode = %ld",status);


    UInt32 uiDefaultSpeaker = kAudioSessionOverrideAudioRoute_Speaker;
    status = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker,
                                     sizeof(UInt32),
                                     &uiDefaultSpeaker);

    //NSLog(@"set mode = %ld",status);
    


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
    //NSLog(@"route desc = %ld",status);
    //returns an output and an input array containing dictionarys with route infos
    //if (CFIndex n = CFDictionaryGetCount(cfdRouteDesc))
    if (CFDictionaryGetCount(cfdRouteDesc))
    {
        CFArrayRef cfaOutputs = (CFArrayRef)CFDictionaryGetValue(cfdRouteDesc, kAudioSession_AudioRouteKey_Outputs);

        for(CFIndex i = 0, c = CFArrayGetCount(cfaOutputs); i < c; i++)
        {
            CFDictionaryRef cfdItem = (CFDictionaryRef)CFArrayGetValueAtIndex(cfaOutputs, i);
            CFStringRef cfsDevice = (CFStringRef)CFDictionaryGetValue(cfdItem, kAudioSession_AudioRouteKey_Type);
            
            //NSLog(@"output device: %@",(NSString*)cfsDevice);
            
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
                
                UInt32 cfsRouteOverwrite = kAudioSessionOverrideAudioRoute_Speaker;
                //UInt32 cfsRouteOverwrite = kAudioSessionOverrideAudioRoute_None;
                
                uiDataSize = sizeof(UInt32);
                status = AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,
                                                 uiDataSize,
                                                 &cfsRouteOverwrite);
                
                //NSLog(@"route overwrite = %ld",status);


                //kAudioSessionProperty_InputSource
                
            }
        }
        //CFArrayRef cfaInputs = (CFArrayRef)CFDictionaryGetValue(cfdRouteDesc, kAudioSession_AudioRouteKey_Inputs);
        
        //for(CFIndex i = 0, c = CFArrayGetCount(cfaInputs); i < c; i++)
        //{
        //  CFDictionaryRef cfdItem = (CFDictionaryRef)CFArrayGetValueAtIndex(cfaInputs, i);
        //    CFStringRef cfsDevice = (CFStringRef)CFDictionaryGetValue(cfdItem, kAudioSession_AudioRouteKey_Type);
            
            //NSLog(@"input device: %@",(NSString*)cfsDevice);
        //}
    }
    
    CFArrayRef cfaOutputData;
    uiDataSize = sizeof(CFArrayRef);
    status = AudioSessionGetProperty(kAudioSessionProperty_OutputDestinations, &uiDataSize, &cfaOutputData);
   
    //NSLog(@"destinations get status = %ld = %4.4s",status,(char*)&status);

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
                //NSLog(@"%ld, routeId = %ld",i,siRouteId);
            }
            
            //CFStringRef cfsRouteDescription = (CFStringRef) CFDictionaryGetValue(cfdAudioOutput, kAudioSession_OutputDestinationKey_Description);
            
            //NSLog(@"%ld, description = %@",i,(NSString*)cfsRouteDescription);
        }
        
    
    }
    Float32 fData;
    double dData;

    
    dData = SAMPLERATE;
    uiDataSize = sizeof(double);
    status = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareSampleRate, uiDataSize, &dData);
    //NSLog(@"set perferred samplerate = %f, status = %ld = %4.4s\n",dData, status,(char*)&status);
    
    
    dData = 0;
    uiDataSize = sizeof(double);
    status = AudioSessionGetProperty(kAudioSessionProperty_PreferredHardwareSampleRate, &uiDataSize, &dData);
    //NSLog(@"perferred samplerate = %f, status = %ld = %4.4s\n",dData, status,(char*)&status);

/*
    fData = 0.022f;
    uiDataSize = sizeof(Float32);
    status = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, uiDataSize, &fData);
    //NSLog(@"set perferred buffer duration = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);
  */  

    fData = 0;
    uiDataSize = sizeof(Float32);
    status = AudioSessionGetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, &uiDataSize, &fData);
    //NSLog(@"perferred buffer duration = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);
    
    dData = 0;
    uiDataSize = sizeof(double);
    status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &uiDataSize, &dData);
    //NSLog(@"current hwd samplerate = %f, status = %ld = %4.4s\n",dData, status,(char*)&status);

    fData = 0;
    uiDataSize = sizeof(Float32);
    status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareIOBufferDuration, &uiDataSize, &fData);
    //NSLog(@"current hwd buffer duration = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);
   
    fData = 0;
    uiDataSize = sizeof(Float32);
    status = AudioSessionGetProperty(kAudioSessionProperty_InputGainScalar, &uiDataSize, &fData);
    //NSLog(@"input gain scalar = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);

    fData = 0;
    uiDataSize = sizeof(Float32);
    status = AudioSessionSetProperty(kAudioSessionProperty_InputGainScalar, uiDataSize, &fData);
    //NSLog(@"input gain scalar = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);

    UInt32 uiData = 0;
    uiDataSize = sizeof(UInt32);
    status = AudioSessionGetProperty(kAudioSessionProperty_InputGainAvailable, &uiDataSize, &uiData);
    //NSLog(@"input gain available = %ld, status = %ld = %4.4s\n",uiData, status,(char*)&status);
    
    
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
    //NSLog(@"category get status = %4.4s, data = %4.4s",(char*)&status,(char*)&uiData);

    fData = 0;
    uiDataSize = sizeof(fData);
    status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareOutputLatency, &uiDataSize, &fData);
    //NSLog(@"hwd output latency status = %4.4s, data = %f",(char*)&status,fData);

    fData = 0;
    uiDataSize = sizeof(fData);
    status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareInputLatency, &uiDataSize, &fData);
    //NSLog(@"hwd input latency status = %4.4s, data = %f",(char*)&status,fData);
    
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
    //NSLog(@"recordi timestamp:%0.f host: %lld\n",inTimeStamp->mSampleTime - recSample, inTimeStamp->mHostTime - recHost);
    //recHost = inTimeStamp->mHostTime;
    //recSample = inTimeStamp->mSampleTime;

    struct timeval TimeStamp;
    gettimeofday(&TimeStamp, NULL);

    audioController* ac = (audioController*)inRefCon;

    //CS_CLIENT does no recording
    if ([[ac com]connectionState] == CS_ClIENT)
    {
        return noErr;
    }

    int dataSize = inNumberFrames * sizeof(SInt32); // 16bit twice

    OSStatus status;

    AudioBufferList *bufferList = ac.recordingBufferList;
    bufferList->mBuffers[0].mDataByteSize = dataSize;

    if (inNumberFrames > FRAMESIZE)
    {
        NSLog(@"error inNumberFrames = %ld",inNumberFrames);
        AudioOutputUnitStop(ac.audioUnit);
        return -1;
    }
    //the server is ready if it got the timestamp from the client,
    //till that it records in cyles into the buffer
    if ([[ac com]connectionState] == CS_SERVER)
    {
        if (ac->recordBuf->pos+inNumberFrames > ac->recordBuf->len)
        {
            ac->recordBuf->pos = 0; //ringbuffer
        }

        bufferList->mBuffers[0].mData = ac->recordBuf->buf+ac->recordBuf->pos;
        status = AudioUnitRender(ac.audioUnit,
                                 ioActionFlags,
                                 inTimeStamp,
                                 inBusNumber,
                                 inNumberFrames,
                                 bufferList);
        ac->recordBuf->pos += inNumberFrames;
    }

    //assume that without network one device with headphones is used
    //playing and recording
    //once the buffer is full, we are done
    else if ([[ac com]connectionState] == CS_DISCONNECTED)
    {
        bufferList->mBuffers[0].mData = ac->recordBuf->buf+ac->recordBuf->pos;
        //AudioUnitRenderActionFlags ioActionFlags;
        status = AudioUnitRender(ac.audioUnit,
                                 ioActionFlags,
                                 inTimeStamp,
                                 inBusNumber,
                                 inNumberFrames,
                                 bufferList);
        ac->recordBuf->pos += inNumberFrames;

        if (ac->recordBuf->pos+inNumberFrames > ac->recordBuf->len)
        {            
            [ac stop];
            NSLog(@"recording stoped");
            [[ac proc]SetSignalDetailsRecord:ac->recordBuf->buf Play:ac->play->buf RecordLen:ac->recordBuf->len Playlen:ac->play->len];         //set pointers
            NSLog(@"Pointer bekommen");

            //calc distance

            float Distance=[[ac proc]CalculateDistanceHeadphone];
            //display
            NSString *Output=[[NSString alloc]initWithFormat:@"Distance: %.2f meters\nwaiting for new measurement",Distance];
            NSLog(@"%@",Output);
            ac->LabelOutput.text=Output;
        }
    }
    return noErr;
}

//mainly used for debugging, outputs the recorded data by sending to the python server
-(void)testOutput
{
    NSLog(@"testOutput started");
    [com initNetworkCom];
       
    NSString *outStr = [[NSString alloc] init];
    
    [com open];
    NSLog(@"opened");
    [com send:@"fileName:record_2k_6k_6k_10k_.txt\n"];
    char *sOut = (char*)malloc(2000);
    char *sOutPtr = sOut;
    int len = 0;
    for (int i=0; i< recordBuf->len; i++)
    {
        SInt16 TMP;
        TMP = ((SInt16*)recordBuf->buf)[2*i+1];
        sprintf(sOutPtr,"%i,",TMP);
        len += strlen(sOutPtr);
        sOutPtr = sOut + len;
        // to package the frame data check the  size of the outStr
        if (len > 1990)
        {
                sOutPtr[len] = 0;
                outStr = [NSString stringWithFormat:@"%s\n",sOut];
                [com send:outStr];
                sOutPtr = sOut;
                len = 0;
                memset(sOut,0,2000);
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
                sOutPtr[len] = 0;
                outStr = [NSString stringWithFormat:@"%s\n",sOut];
                [com send:outStr];
                sOutPtr = sOut;
                len = 0;
                memset(sOut,0,2000);
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
    for (int i=0; i< proc.KKFLen; i++)
    {
        sprintf(sOutPtr,"%lli,",proc.PKKF[i]);
        len += strlen(sOutPtr);
        sOutPtr = sOut + len;
        // to package the frame data check the  size of the outStr
        if (len > 1990)
        {
                sOutPtr[len] = 0;
                outStr = [NSString stringWithFormat:@"%s\n",sOut];
                [com send:outStr];
                sOutPtr = sOut;
                len = 0;
                memset(sOut,0,2000);
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
    memset(recordBuf->buf,0,recordBuf->len*sizeof(SInt32));

}


-(OSStatus)start
{
    play->pos = 0;
    OSStatus status = 0;
    recordBuf->pos = 0;
    cnt=0;
    status = AudioOutputUnitStart(audioUnit);
    NSLog(@"audioUnit started status = %ld", status);    
    return status;
}

-(OSStatus)stop
{
    cnt=0;
    OSStatus status;
    status = AudioOutputUnitStop(audioUnit);
    NSLog(@"audioUnit stoped status = %ld", status);
    return status;
}

- (SInt16)setOutput:(UITextField**)tf
{
    tfOutput = *tf;
    return 0;
}

- (SInt16)setOutputLabel:(UILabel**)Label
{
    LabelOutput = *Label;
    return 0;
}


@end
