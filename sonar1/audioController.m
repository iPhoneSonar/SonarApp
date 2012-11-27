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

// Native iphone sample rate of 44.1kHz, same as a CD.
const Float64 SAMPLERATE = 44100.0;
//setting the framerate to 48k increases the frame size to 1114
SInt16 record[4096];
int frameCount = 0;

SInt16 kHzSin[] = {0,3916,7765,11481,15000,18263,21213,23801,
                    25981,27716,28978,29743,30000,29743,28978,27716,
                    25981,23801,21213,18263,15000,11481,7765,3916,0,
                    -3916,-7765,-11481,-15000,-18263,-21213,-23801,-25981,
                    -27716,-28978,-29743,-30000,-29743,-28978,-27716,-25981,
                    -23801,-21213,-18263,-15000,-11481,-7765,-3916};

const SInt16 frameSize = 1024;
SInt16 frame[frameSize+48];
SInt16 frameMute[frameSize+48];
SInt16 *framePtr;
SInt16 pos = 0;

@implementation audioController

@synthesize mGraph;
@synthesize mMixer;
@synthesize outputCASBD;
@synthesize sinPhase;
@synthesize frequency;
@synthesize audioUnit;
@synthesize recordingBufferList;
@synthesize chirpBufferList;
@synthesize testSin;
@synthesize com;

// Clean up memory
- (void)dealloc {
    
    DisposeAUGraph(mGraph);
    [super dealloc];
}


// starts render
- (void)startAUGraph
{
	// Start the AUGraph
	OSStatus result = AUGraphStart(mGraph);
	// Print the result
	if (result) { printf("AUGraphStart result %d %08X %4.4s\n", (int)result, (int)result, (char*)&result); return; }
}

// stops render
- (void)stopAUGraph
{
    Boolean isRunning = false;
    
    // Check to see if the graph is running.
    OSStatus result = AUGraphIsRunning(mGraph, &isRunning);
    // If the graph is running, stop it.
    if (isRunning) {
        result = AUGraphStop(mGraph);
    }
}

- (void)setFrequency:(int) value
{
    frequency = value;
}

- (void)getFrequency:(int*) value
{
    *value = frequency;
}

//
// audio render procedure, don't allocate memory, don't take any locks, don't waste time
static OSStatus playingCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
    
	// Get a reference to the object that was passed with the callback
	// In this case, the AudioController passed itself so
	// that you can access its data.
	audioController *THIS = (audioController*)inRefCon;
    
	// Get a pointer to the dataBuffer of the AudioBufferList
	AudioSampleType *outA = (AudioSampleType *)ioData->mBuffers[0].mData;
    
    
    float freq = THIS->frequency;
	// Calculations to produce a 600 Hz sinewave
	// A constant frequency value, you can pass in a reference vary this.
	// The amount the phase changes in  single sample
	double phaseIncrement = M_PI * freq / SAMPLERATE;
	// Pass in a reference to the phase value, you have to keep track of this
	// so that the sin resumes right where the last call left off
	float phase = THIS->sinPhase;
    
	float sinSignal;
	// Loop through the callback buffer, generating samples
	for (UInt32 i = 0; i < inNumberFrames; ++i) { 		
        
        // calculate the next sample
        sinSignal = sin(phase);
        // Put the sample into the buffer
        // Scale the -1 to 1 values float to
        // -32767 to 32767 and then cast to an integer
        outA[i] = (SInt16)(sinSignal * 32767.0f);
        // calculate the phase for the next sample
        phase = phase + phaseIncrement;
    }
    // Reset the phase value to prevent the float from overflowing
    if (phase >=  M_PI * freq) {
		phase = phase - M_PI * freq;
	}
	// Store the phase for the next callback.
	THIS->sinPhase = phase;
    
    //test
    
    //ioData->mBuffers[0].mData = (frame+pos);
    //SInt16 shift = inNumberFrames-(inNumberFrames/48)*48;
    //pos = (pos+shift)%48;
    
	return noErr;
}


-(void)sinGen
{
    memset(frameMute, 0, sizeof(frameMute));
    
    //testSin = (AudioBufferList*)malloc(sizeof(AudioBufferList)) ;
    //testSin->mNumberBuffers = 1;
    //testSin->mBuffers[0].mData = frame;
    //testSin->mBuffers[0].mNumberChannels = 1;
    //testSin->mBuffers[0].mDataByteSize = 2048;
    
    //NSString *outStr = [[NSString alloc] init];
    
    int index = 0;
    for (int i=0;i<(1024+48);i++)
    {
        frame[i] = kHzSin[index];
        index = (index+1)%48;
        //outStr = [outStr stringByAppendingFormat: @"%d,", frame[i]];
    }
    framePtr = frame;
    //remove the last ','
    //outStr = [outStr substringToIndex:[outStr length] -1];
    
    //fileOps* recordFile = [[fileOps alloc] init];
    //[recordFile setFileName:@"sin.txt"];
    //[recordFile writeToStringfile:[NSMutableString stringWithString: outputStr]];
    NSLog(@"sinGen");
}

// audio render procedure, don't allocate memory, don't take any locks, don't waste time
static OSStatus playingCallbackTest(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
	ioData->mBuffers[0].mData = (framePtr+pos);
    
    SInt16 shift = inNumberFrames-(inNumberFrames/48)*48;
    pos = (pos+shift)%48;
    return noErr;
}


//init
- (void)initializeAUGraph
{
    
	//************************************************************
	//*** Setup the AUGraph, add AUNodes, and make connections ***
	//************************************************************
	// Error checking result
	OSStatus result = noErr;
    
	// create a new AUGraph
	result = NewAUGraph(&mGraph);
    
    //preset the frequnecy
    frequency = 600;
    
    // AUNodes represent AudioUnits on the AUGraph and provide an
	// easy means for connecting audioUnits together.
    AUNode outputNode;
	AUNode mixerNode;

    // Create AudioComponentDescriptions for the AUs we want in the graph
    // mixer component
	AudioComponentDescription mixer_desc;
    mixer_desc.componentType = kAudioUnitType_Mixer;
	mixer_desc.componentSubType = kAudioUnitSubType_MultiChannelMixer;
	mixer_desc.componentFlags = 0;
	mixer_desc.componentFlagsMask = 0;
	mixer_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
	//  output component
	AudioComponentDescription output_desc;
	output_desc.componentType = kAudioUnitType_Output;
	output_desc.componentSubType = kAudioUnitSubType_RemoteIO;
	output_desc.componentFlags = 0;
	output_desc.componentFlagsMask = 0;
	output_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Add nodes to the graph to hold our AudioUnits,
	// You pass in a reference to the  AudioComponentDescription
	// and get back an  AudioUnit
	result = AUGraphAddNode(mGraph, &output_desc, &outputNode);
	result = AUGraphAddNode(mGraph, &mixer_desc, &mixerNode );
    
	// Now we can manage connections using nodes in the graph.
    // Connect the mixer node's output to the output node's input
	result = AUGraphConnectNodeInput(mGraph, mixerNode, 0, outputNode, 0);
    
    // open the graph AudioUnits are open but not initialized (no resource allocation occurs here)
	result = AUGraphOpen(mGraph);
    
	// Get a link to the mixer AU so we can talk to it later
	result = AUGraphNodeInfo(mGraph, mixerNode, NULL, &mMixer);
    
	//************************************************************
	//*** Make connections to the mixer unit's inputs ***
	//************************************************************
    // Set the number of input busses on the Mixer Unit
	// Right now we are only doing a single bus.
	UInt32 numbuses = 1;
	UInt32 size = sizeof(numbuses);
    result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &numbuses, size);
    
	CAStreamBasicDescription desc;
    
	// Loop through and setup a callback for each source you want to send to the mixer.
	// Right now we are only doing a single bus so we could do without the loop.
	for (int i = 0; i < numbuses; ++i) {
        
		// Setup render callback struct
		// This struct describes the function that will be called
		// to provide a buffer of audio samples for the mixer unit.
		AURenderCallbackStruct renderCallbackStruct;
		renderCallbackStruct.inputProc = &playingCallbackTest;
		renderCallbackStruct.inputProcRefCon = self;
        
        // Set a callback for the specified node's specified input
        result = AUGraphSetNodeInputCallback(mGraph, mixerNode, i, &renderCallbackStruct);
        
		// Get a CAStreamBasicDescription from the mixer bus.
        size = sizeof(desc);
		result = AudioUnitGetProperty(  mMixer,
                                      kAudioUnitProperty_StreamFormat,
                                      kAudioUnitScope_Input,
                                      i,
                                      &desc,
                                      &size);
        //NSLog(@"%d")
		// Initializes the structure to 0 to ensure there are no spurious values.
		memset (&desc, 0, sizeof (desc));        						
        
		// Make modifications to the CAStreamBasicDescription
		// We're going to use 16 bit Signed Ints because they're easier to deal with
		// The Mixer unit will accept either 16 bit signed integers or
		// 32 bit 8.24 fixed point integers.
		desc.mSampleRate = SAMPLERATE; // set sample rate
		desc.mFormatID = kAudioFormatLinearPCM;
		desc.mFormatFlags      = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
		desc.mBitsPerChannel = sizeof(AudioSampleType) * 8; // AudioSampleType == 16 bit signed ints
		desc.mChannelsPerFrame = 1;
		desc.mFramesPerPacket = 1;
		desc.mBytesPerFrame = ( desc.mBitsPerChannel / 8 ) * desc.mChannelsPerFrame;
		desc.mBytesPerPacket = desc.mBytesPerFrame * desc.mFramesPerPacket;
        
		printf("Mixer file format: "); desc.Print();
		// Apply the modified CAStreamBasicDescription to the mixer input bus
		result = AudioUnitSetProperty(  mMixer,
                                      kAudioUnitProperty_StreamFormat,
                                      kAudioUnitScope_Input,
                                      i,
                                      &desc,
                                      sizeof(desc));
	}
	// Apply the CAStreamBasicDescription to the mixer output bus
	result = AudioUnitSetProperty(	 mMixer,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  0,
                                  &desc,
                                  sizeof(desc));
    
	//************************************************************
	//*** Setup the audio output stream ***
	//************************************************************
    
	// Get a CAStreamBasicDescription from the output Audio Unit
    result = AudioUnitGetProperty(  mMixer,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  0,
                                  &desc,
                                  &size);
    
	// Initializes the structure to 0 to ensure there are no spurious values.
	memset (&desc, 0, sizeof (desc));
    
	// Make modifications to the CAStreamBasicDescription
	// AUCanonical on the iPhone is the 8.24 integer format that is native to the iPhone.
	// The Mixer unit does the format shifting for you.
	desc.SetAUCanonical(1, true);
	desc.mSampleRate = SAMPLERATE;
    
    // Apply the modified CAStreamBasicDescription to the output Audio Unit
	result = AudioUnitSetProperty(  mMixer,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  0,
                                  &desc,
                                  sizeof(desc));
    
    // Once everything is set up call initialize to validate connections
    
    
    
 	result = AUGraphInitialize(mGraph);
}

//implementation for recording
-(OSStatus)audioUnitInit
{
    //bring up the communication channel
    com = [[communicator alloc] init];
    //its not realy the right play but for debugging it fits
    [self sinGen];
    
    [self sessionInit];
    
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

    NSLog(@"input enable io status=%ld",status);
    
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

    
    callbackStruct.inputProc = &playingCallbackTest;
    callbackStruct.inputProcRefCon = self;
    
    status = AudioUnitSetProperty(audioUnit ,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &callbackStruct, sizeof(callbackStruct));
   
    NSLog(@"set playingCallback status=%ld",status);

    /*
    flag = 0;
    status = AudioUnitSetProperty(audioUnit ,
                                  kAudioUnitProperty_ShouldAllocateBuffer,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &flag, sizeof(flag));
    
    NSLog(@"set no allocate status=%ld",status);
    */
 
    //use the defined record[] as buffer
    memset(record, 0, 4096);
    recordingBufferList = (AudioBufferList*)malloc(sizeof(AudioBufferList)) ;
    recordingBufferList->mNumberBuffers = 1;
    recordingBufferList->mBuffers[0].mData = record;
    recordingBufferList->mBuffers[0].mNumberChannels = 1;

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
    
    double dData = 0;
    uiDataSize = sizeof(double);
    status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &uiDataSize, &dData);
    NSLog(@"curren hwd samplerate = %f, status = %ld = %4.4s\n",dData, status,(char*)&status);

    Float32 fData = 0;
    uiDataSize = sizeof(Float32);
    status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareIOBufferDuration, &uiDataSize, &fData);
    NSLog(@"current hwd buffer duration = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);

    dData = 0;
    uiDataSize = sizeof(double);
    status = AudioSessionGetProperty(kAudioSessionProperty_PreferredHardwareSampleRate, &uiDataSize, &dData);
    NSLog(@"curren perfered samplerate = %f, status = %ld = %4.4s\n",dData, status,(char*)&status);
    
    fData = 0;
    uiDataSize = sizeof(Float32);
    status = AudioSessionGetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, &uiDataSize, &fData);
    NSLog(@"current perfered buffer duration = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);
   
    fData = 0;
    uiDataSize = sizeof(Float32);
    status = AudioSessionGetProperty(kAudioSessionProperty_InputGainScalar, &uiDataSize, &fData);
    NSLog(@"current perfered buffer duration = %f, status = %ld = %4.4s\n",fData, status,(char*)&status);
    
    UInt32 uiData = 0;
    uiDataSize = sizeof(UInt32);
    status = AudioSessionGetProperty(kAudioSessionProperty_InputGainAvailable, &uiDataSize, &uiData);
    NSLog(@"current perfered buffer duration = %ld, status = %ld = %4.4s\n",uiData, status,(char*)&status);
    
    
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
    
    NSLog(@"hardware latency get status = %4.4s, data = %f",(char*)&status,fData);
    
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
    
    
    audioController* recordingUnit = (audioController*)inRefCon;
    
    AudioBufferList *bufferList = recordingUnit.recordingBufferList;
    bufferList->mBuffers[0].mDataByteSize = dataSize;
   
    //AudioSampleType *tempA = (AudioSampleType *)ioData->mBuffers[0].mData;
    //for (int i=0; i<10;i++)
    //    NSLog(@"val %d=%d",i,tempA[i] );
    if (inNumberFrames > 1024)
    {
        NSLog(@"inNumberFrames = %ld",inNumberFrames);
        AudioOutputUnitStop(recordingUnit.audioUnit);
        return noErr;
    }
    
    status = AudioUnitRender(recordingUnit.audioUnit,
                             ioActionFlags,
                             inTimeStamp,
                             inBusNumber,
                             inNumberFrames,
                             bufferList);
   
    
    //NSLog(@"frames=%ld\n AudioUnitRender status = %ld",inNumberFrames,status);

    frameCount += 1;
    if (frameCount == 4)
    {
        NSLog(@"audioUnit stoped");
        bufferList->mBuffers[0].mData = record;
    }
    else if (frameCount > 4)
    {
        
    }
    else
    {
        bufferList->mBuffers[0].mData = record+frameCount*1024; 
    }

    return noErr;

}

-(void)testOutput
{
    //find the min and max amplitude values to get an idea of the range
    //output all the
    
    SInt16 maxVal = 0;
    SInt16 minVal = 0;
    
    NSString *outStr = [[NSString alloc] init];
    
    for (int i=0; i<sizeof(record)/2; i++) //because sizeof returns in size of bytes
    {
        outStr = [outStr stringByAppendingFormat: @"%d,", record[i]];
        //NSLog(@"val[%d]= %d",i,record[i]);
        if (record[i]>maxVal)
            maxVal = record[i];
        else if (record[i]<minVal)
            minVal = record[i];
    }
    NSLog(@"min=%d, max=%d",minVal,maxVal);
    if (com.host) //short test assumes that the network is also initialized
    {
        //remove the last ','
        outStr = [outStr substringToIndex:[outStr length] -1];
        [com send:outStr :@"record.txt"];
        NSLog(@"record.txt send");
    }
    

}

-(void)mute:(UInt32)flag
{
    if (flag == 0)
    {
        framePtr = frameMute;
    }
    else
    {
        framePtr = frame;
    }
    NSLog(@"flag = %ld",flag);
}

-(OSStatus)recordingStart
{
    OSStatus status;
    //not the right place but needs to be checked
    if (recordingBufferList)
    {
        status = AudioOutputUnitStart(audioUnit);
        NSLog(@"audioUnit started status = %ld", status);
    }
    else
    {
        NSLog(@"audioUnit start error = %ld", status);
    }
    return status;
}

-(OSStatus)recordingStop
{
    frameCount = 0;
    OSStatus status;
    status = AudioOutputUnitStop(audioUnit);
    NSLog(@"audioUnit stoped status = %ld", status);
    return status;
}

@end
