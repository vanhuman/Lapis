///////////////////////////////////////////// Global vars //////////////////////////////////////

// dependencies with MOTU:
//	if outResampling=1 then outResamplingChan should also be set as return channel in MOTU Audio Setup to
//      resample the signal from input 10/11
//	if outAnalogEfx=1 there should be busses in CueMix to send the analog efx input to
//      outResamplingChan / outMainChan / outMonitorChan

// 	mapping 	outputs								inputs
//					0+1 = Main Out 1+2			0+1 = Analog In 1+2
//					2+3 = Analog Out 1+2		2+3 = Analog In 3+4
//					4+5 = Analog Out 3+4		4+5 = Analog In 5+6
//					6+7 = Analog Out 5+6		6+7 = Analog In 7+8
//					8+9 = Analog Out 7+8		8+9 = digital in
//												10+11 = return

if((~aBus.isNil || ~projectList.isNil), {

	~projectID = \mw; // specifies which sample list in Data/SampleLists/ to use
	~projectList = (sh: "Shackle", ab: "ABATTOIR", sp: "Spoon3b", kid: "Kids", cr: "Crack", dg: "DetuningGuitar",
		sp2: "SpoonDuo", dr: "Drone", mw: "MoneyForYourWhaleII", eu: "Eurapco", sn: "SacredNoise",
		sm: "SoundOfTheMachine2019", pot: "ParishOfTama", lcm: "LCMball", th: "TackHead", sh2: "Shackle2",
		p2019: "2019", peem: "Peem"
	);
	~projectNotes = (cr: "/Crack/Crack Notes.rtf");

	~lapisStatus = 0; // whether to start LapisStatus with LiveSampler
	~showBufferView = 0; // set to 1 to show bufferview window
	~noArduino = 0;	// set to 1 if Arduino not available
	~distortionMax = 50; // set the maximum value for distortion controllers, nil if should be disregarded
	~postInstrumentDetails = true; // whether to postln details of each fader's action
	~font = "Courier";
	~showResampleMeters = true;	// whether to show the two resample channels in the server meter

	~project = ~projectList.at(~projectID); // set current project from list above
	~aBus = ( // audio busses

		// ---- Output ---------
		outMainChan: 0, // main output channel
		outMainStereo: 1, // 0=mono 1=stereo
		outMainAtt: -6.dbamp, // main attenuation factor: 1=no change
		outMainLimiter: 0, // 1=enable 0=disable
		outMainSubFilter: 1, // 1=enable 0=disable
		outMonitor: 0, // 0=off 1=on
		outMonitorChan: 2, // monitor output channel, stereo or mono
		outMonitorStereo: 1, // 0=mono 1=stereo
		outMonitorAtt: -6.dbamp, // monitor attenuation factor: 1=no change
		outMonitorCompressed: 0, // add compression to monitor output
		outAnalogEfx: 0, // output to analog effects, 0=off 1=on
		outAnalogEfxChan: 6, // analog efx output channel, mono
		outAnalogEfxAtt: -6.dbamp, // analog efx attenuation factor: 1=no change
		outResamplingAtt: 0.dbamp, // resampling attenuation factor: 1=no change
		inResamplingAtt: 0.dbamp, // input attenuation factor
		outAltChan: 2, // alternative output channel for incidental usage

		// ---- Input ---------
		inChan1: 50, // input channel 1
					 // original channel plus 10 for direct (skipping 10 output busses),
					 // or use gained chans as specified below
		inChan2: 51, // input channel 2
		inChan1alt: 50, // alternative input channel for input 1
		inChan2alt: 51, // alternative input channel for input 2
		gainedChans: [0,1,2,3], // channels to be gained, always 4, mapped to 50, 51, 52, 53
		// gainedChans: [0,1,14,15], // setting when using aggregate device of MOTU+Edirol
		inBusGain: [6.dbamp,6.dbamp,6.dbamp,6.dbamp], // gain for gained channels in amp
		inputThru: 0, // 1=send gained channels thru (for example for recording), 0=don't send thru
		inputThruChan: 2, // first channel to send mic inputs thru
		recChannels: 2, // number of channels to record (set to 6 when input mics should also be
						// recorded in combi with inputThru=1)
		inputPeakChans: 0, // number of input channels to monitor in LapisStatus
		inputPeakStartChan: 0, // start channel to monitor

		// ---- General vars, no need to change ---------
		resamplingChan: 80, // output / input channel for resampling, in stereo, so adding +1 for the second channel
		inAlt: 0, // flag whether input is switched to alternative
		inInt: 0, // flag whether input is switched to internal
		outAsynth: nil, outBsynth: nil, outBLsynth: nil, outMainSynth: nil,
		efx1Synth: nil, efx2Synth: nil, inBusSynth: nil,
		outA: 100, outB: 102, outMain: 104, outEfxPost: 106, outBL: 108, outEfxPre: 110,
		mainGroup: nil,
		outputGroup: nil,
		efxGroup: nil,
		synthGroup: nil,
		inGroup: nil,
		resampleGroup: nil,

		// old way of doing resampling
		// outResamplingChan: 8,
		//// output chan for resampling, stereo, this channel should be set in MOTU CueMix as return channel
		// inChan1int: 10+Server.local.options.numOutputBusChannels,
		//// (only MOTU) output from computer send back in, chan 11 (left)
		// inChan2int: 11+Server.local.options.numOutputBusChannels,
		//// (only MOTU) output from computer send back in, chan 12 (right)
		//// plus Server.local.options.numOutputBusChannels to skip output busses (because using In and not SoundIn)
	);

	~aBus.put(\inChan1org, ~aBus.inChan1); // original input channel 1
	~aBus.put(\inChan2org, ~aBus.inChan2); // original input channel 2

	~colorOn = Color.green(0.9);
	~colorOn2 = Color.yellow;

	~alwaysOnTop = 0; 	// Controller and In/Outputs windows on top or not
	~midiOutInit = 1; 	//  set to 1 to initialize MIDI out
	~midiOutDevice = "IAC1";  // device to send MIDI out to if enabled: MUL, EXT, IAC1
	~sRate = s.sampleRate;
});
