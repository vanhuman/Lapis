(
///////////////////////////////////////////// Synths //////////////////////////////////////

////////// Recording //////////////////////////////////////

SynthDef(\zoneRec, { // general recording zone for mono recording
	arg gate, chan1, chan2, start, len, recZone, attenuation;
	// start/stop env, input chan, start pos (frames), length (secs), unique ID for curRecZone
	var playHead;
	// update bufferView
	if(~showBufferView == 1,{
		playHead = (Phasor.ar(1,1, start, start + (len*~sRate), start)) % BufFrames.kr(~mainBufLS);
		SendReply.kr(Impulse.kr(~cfgLS.bufferViewPlayHeadFreq), "/playHead",
			[playHead/~sRate, start/~sRate, len], recZone);
		SendReply.kr(Impulse.kr(~cfgLS.bufferViewRefreshFreq),"/bufferViewRefresh", start, recZone);
	});
	RecordBuf.ar(In.ar([chan1,chan2]), ~mainBufLS, start, loop: 0, recLevel: attenuation) *
	EnvGen.kr(Env.linen(0,len,0), gate, doneAction: 2);
}).send(s);

SynthDef(\zoneRecDyn, {  // dynamic length recording zone for mono recording
	arg gate, chan1, chan2, start, len, recZone, attenuation;
	// start/stop env, input chan, start pos (frames), length (secs), unique ID for curRecZone
	var playHead;
	// update bufferView
	if(~showBufferView == 1, {
		playHead = (Phasor.ar(1,1, start, start + (len*~sRate), start)) % BufFrames.kr(~mainBufLS);
		SendReply.kr(Impulse.kr(~cfgLS.bufferViewPlayHeadFreq), "/playHead",
			[playHead/~sRate, start/~sRate, len], recZone);
		SendReply.kr(Impulse.kr(~cfgLS.bufferViewRefreshFreq),"/bufferViewRefresh", start, recZone);
	});
	RecordBuf.ar(In.ar([chan1,chan2]), ~mainBufLS, start, loop: 0, recLevel: attenuation) *
	EnvGen.kr(Env.linen(0,len,0), gate, doneAction: 2);
}).send(s);

////////// Zone 2 MIDI //////////////////////////////////////

SynthDef(\zone2play1L, { // with zone2play1R triggered by LV1 fader1, going out of phase
	arg gate, ampBus, startPosition = 0, lenBus, distBus, resetPosBus, ffBus, mixBus;
	// start/stop env, start pos (frames), busses range 0-1 for length, amplitude, distortion,
	// 		reset playhead, filter freq
	// control by: LV1 fader1, fader1, fader2, knobA1, crossfader, joyX, mastervolknob
	var sig, lenBusVal, resetTrig, resetPosBusVal, playHead, mixBusVal;

	lenBusVal = IEnvGen.kr(~specLS.len21L, In.kr(lenBus,1)); // in frames
	resetPosBusVal = In.kr(resetPosBus,1) * lenBusVal; 	// in frames
	startPosition = ~specLS.startPos21L.map(startPosition); // in frames
	resetTrig = HPZ2.kr(In.kr(resetPosBus,1)); // detect a change in the resetPosBus value
	mixBusVal = IEnvGen.kr(~specLS.mix21, In.kr(mixBus,1));

	//	Poll.kr(Impulse.kr(20), startPosition/~sRate);
	playHead = ( Phasor.ar(
		resetTrig,										// reset
		BufRateScale.kr(~mainBufLS), 			// rate
		startPosition, 								// start
		startPosition + lenBusVal,			// end
		startPosition + resetPosBusVal  	// resetPos
	) ) % BufFrames.kr(~mainBufLS);

	// update bufferView
	if(~showBufferView == 1, {SendReply.kr(Impulse.kr(~cfgLS.bufferViewPlayHeadFreq), "/playHead",
		[playHead/~sRate, startPosition/~sRate, lenBusVal/~sRate], 21)});

	sig = BufRd.ar(2, ~mainBufLS, playHead,	1, 4) * EnvGen.kr(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
	sig = IEnvGen.kr(~specLS.amp21, In.kr(ampBus,1)) * sig; // volume bus
	sig = ~specLS.dist21.map(In.kr(distBus,1)) * sig; // distortion bus
	sig = Balance2.ar(sig[0], sig[1],-1); // panning hard left
	sig = RLPF.ar(sig, ~specLS.ff21.map(In.kr(ffBus,1)), 0.5); // low pass filter
	Out.ar(~aBus.outA, sig*mixBusVal);
}).send(s);

SynthDef(\zone2play1R, { // with zone2play1L triggered by LV1 fader1, going out of phase
	arg gate, startPosition = 0, lenBus, ampBus, distBus, pitchBus, resetPosBus, ffBus, mixBus;
	// start/stop env, start pos (frames), busses range 0-1 for length, amplitude, distortion,
	// 		pitch, reset playhead, filter freq
	// control by: LV1 fader1, fader1, fader2, knobA1, crossfader, joyY, joyX, mastervolknob
	var sig, lenBusVal, resetTrig, resetPosBusVal, playHead, mixBusVal;

	lenBusVal = IEnvGen.kr(~specLS.len21R, In.kr(lenBus,1)); // in frames
	resetPosBusVal = In.kr(resetPosBus,1) * lenBusVal; // in frames
	startPosition = ~specLS.startPos21R.map(startPosition); // in frames
	resetTrig = HPZ2.kr(In.kr(resetPosBus,1)); // detect a change in the resetPosBus value
	mixBusVal = IEnvGen.kr(~specLS.mix21, In.kr(mixBus,1));

	playHead = ( Phasor.ar(
		resetTrig, // reset
		~specLS.pitch21.map(In.kr(pitchBus,1)) * BufRateScale.kr(~mainBufLS), // rate
		startPosition, // start
		startPosition + lenBusVal, // end
		startPosition + resetPosBusVal // resetPos
	) ) % BufFrames.kr(~mainBufLS);

	sig = BufRd.ar(2, ~mainBufLS, playHead, 1, 4) * EnvGen.kr(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
	sig = IEnvGen.kr(~specLS.amp21, In.kr(ampBus,1)) * sig; // volume bus
	sig = ~specLS.dist21.map(In.kr(distBus,1)) * sig; // distortion bus
	sig = Balance2.ar(sig[0], sig[1],1); // panning hard right
	sig = RLPF.ar(sig, ~specLS.ff21.map(In.kr(ffBus,1)), 0.5); // low pass filter
	Out.ar(~aBus.outA, sig*mixBusVal);
}).send(s);

SynthDef(\zone2play1hf, { // triggered by LV1 fader1 when value more than 0.97
	arg gate, startPosition = 0, lenBus, distBus, resetPosBus, mixBus;
	// start/stop env, start pos (frames), busses range 0-1 for length, distortion, reset playhead
	// control by: LV1 fader1, fader2, knobA1, crossfader, joyX
	var sig, lenBusVal, resetTrig, resetPosBusVal, playHead, mixBusVal;

	lenBusVal = IEnvGen.kr(~specLS.len21R, In.kr(lenBus,1)); // in frames
	resetPosBusVal = In.kr(resetPosBus,1) * lenBusVal; // in frames
	startPosition = ~specLS.startPos21R.map(startPosition); // in frames
	resetTrig = HPZ2.kr(In.kr(resetPosBus,1)); // detect change in the resetPosBus value
	mixBusVal = IEnvGen.kr(~specLS.mix21hf, In.kr(mixBus,1));

	playHead = ( Phasor.ar(
		resetTrig, // reset
		(2**4) * BufRateScale.kr(~mainBufLS), // rate
		startPosition, // start
		startPosition + lenBusVal, // end
		startPosition + resetPosBusVal // resetPos
	) ) % BufFrames.kr(~mainBufLS);

	sig = BufRd.ar(2, ~mainBufLS, playHead, 1, 4) * EnvGen.kr(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
	sig = ~specLS.dist21hf.map(In.kr(distBus,1)) * sig; // distortion bus
	Out.ar(~aBus.outA, sig*mixBusVal);
}).send(s);

SynthDef(\zone2play1lf, {  // triggered by LV1 fader1 when value more than 0.99
	arg gate, startPosition = 0, lenBus, distBus, resetPosBus, mixBus;
	// start/stop env, start pos (frames), busses range 0-1 for length, distortion, reset playhead
	// control by: LV1 fader1, fader2, knobA1, crossfader, joyX
	var sig, lenBusVal, resetTrig, resetPosBusVal, playHead, mixBusVal;

	lenBusVal = IEnvGen.kr(~specLS.len21R, In.kr(lenBus,1)); // in frames
	resetPosBusVal = In.kr(resetPosBus,1) * lenBusVal; // in frames
	startPosition = ~specLS.startPos21R.map(startPosition); // in frames
	resetTrig = HPZ2.kr(In.kr(resetPosBus,1));// detect change in the resetPosBus value
	mixBusVal = IEnvGen.kr(~specLS.mix21lf, In.kr(mixBus,1));

	playHead = ( Phasor.ar(
		resetTrig, // reset
		(0.5**4) * BufRateScale.kr(~mainBufLS), // rate
		startPosition, // start
		startPosition + lenBusVal, // end
		startPosition + resetPosBusVal // resetPos
	) ) % BufFrames.kr(~mainBufLS);

	sig = BufRd.ar(2, ~mainBufLS, playHead, 1, 4) * EnvGen.kr(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
	sig = ~specLS.dist21lf.map(In.kr(distBus,1)) * sig; // distortion bus
	Out.ar(~aBus.outA, sig*mixBusVal);
}).send(s);

////////// Zone 3 MIDI //////////////////////////////////////

SynthDef(\zone3play1, {
	arg gate, lenBus, startPosition = 0, ampBus, distBus, pitchBus, resetPosBus, panSpdBus, ampModSpdBus,
	ampModOnBus, ffBus;
	var sig, lenBusVal, resetTrig = 1, resetPosBusVal, ampModSpdVal, ampModBusOnVal, ffBusVal, playHead;

	lenBusVal = IEnvGen.kr(~specLS.len31, In.kr(lenBus,1));
	resetPosBusVal = In.kr(resetPosBus,1) * lenBusVal;
	startPosition = ~specLS.startPos21L.map(startPosition);
	resetTrig = HPZ2.kr(In.kr(resetPosBus,1));
	ampModSpdVal = In.kr(ampModSpdBus,1);
	ampModBusOnVal = In.kr(ampModOnBus,1);
	ffBusVal = In.kr(ffBus,1);

	playHead = ( Phasor.ar(
		resetTrig,
		~specLS.pitch21.map(In.kr(pitchBus,1)) * BufRateScale.kr(~mainBufLS),
		startPosition,
		startPosition + lenBusVal,
		startPosition + resetPosBusVal
	) ) % BufFrames.kr(~mainBufLS);
	if(~showBufferView == 1,
		{SendReply.kr(Impulse.kr(~cfgLS.bufferViewPlayHeadFreq), "/playHead",
			[playHead/~sRate, startPosition/~sRate, lenBusVal/~sRate], 31)});

	sig = BufRd.ar(2, ~mainBufLS, playHead, 1, 4 ) * EnvGen.kr(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
	sig = IEnvGen.kr(~specLS.amp21, In.kr(ampBus,1)) * sig;
	sig = ~specLS.dist21.map(In.kr(distBus,1)) * sig;
	sig = (ffBusVal.ceil * RHPF.ar(sig, IEnvGen.kr(~specLS.ff31, ffBusVal), 0.5,
		IEnvGen.kr(~specLS.mulHPF31, ffBusVal))) +
	((1 - ffBusVal.ceil) * sig); // if ffBusVal=0, don't go through filter
	sig = Balance2.ar(sig[0], sig[1], LFNoise1.ar(~specLS.panSpd31.map(In.kr(panSpdBus,1))));
	sig =
	((1 - ampModBusOnVal) * sig) +
	// on/off modulation, clicky
	//		(ampModBusOnVal * sig * LFPulse.ar(1 / ~specLS.ampModSpd31.map(ampModSpdVal)));
	// sine modulation, too smooth maybe
	//		(ampModBusOnVal * sig * SinOsc.ar(1 / ~specLS.ampModSpd31.map(ampModSpdVal)).range(0,1));
	// a mix between the above, depending on the mod speed
	(ampModBusOnVal * sig * ampModSpdVal *
		SinOsc.ar(1 / ~specLS.ampModSpd31.map(ampModSpdVal)).range(0,1)) +
	(ampModBusOnVal * sig * (1 - ampModSpdVal) *
		LFPulse.ar(1 / ~specLS.ampModSpd31.map(ampModSpdVal)));
	Out.ar(~aBus.outA, sig);
}).send(s);

////////// Zone 4 MIDI //////////////////////////////////////

SynthDef(\zone4play1, {
	arg gate, lenBus, startPosition = 0, ampBus, distBus, pitchBus, pitch2Bus, ffBus, ffSpeedBus;
	var trig, sig, lenBusVal, playHead, sign, trig2, ffSpeedVal;

	ffSpeedVal = ~specLS.ffSpeed41.map(In.kr(ffSpeedBus,1));
	lenBusVal = In.kr(lenBus,1);
	//	trig = Impulse.ar(1 / IEnvGen.kr(~specLS.len41, In.kr(lenBus,1)));
	trig = Impulse.ar(1 / lenBusVal);

	if(~showBufferView == 1, {
		trig2 = Impulse.ar(1 / (lenBusVal * 2));
		sign = LFPulse.ar(1 / (lenBusVal * 2), width: 0.5).range(-1,1);

		playHead = ( Phasor.ar(
			trig2,
			~specLS.pitch41.map(In.kr(pitchBus,1)) * BufRateScale.kr(~mainBufLS) * sign,
			~specLS.startPos21L.map(startPosition),
			~specLS.startPos21L.map(startPosition) + (lenBusVal*2*~sRate),
			~specLS.startPos21L.map(startPosition)
		) ) % BufFrames.kr(~mainBufLS);
		SendReply.kr(Impulse.kr(~cfgLS.bufferViewPlayHeadFreq), "/playHead",
			[playHead/~sRate, ~specLS.startPos21L.map(startPosition)/~sRate, lenBusVal], 41)
	});
	//	SendTrig.kr(Impulse.kr(4),1,In.kr(lenBus,1));

	sig = PlayBufAlt.ar(2, ~mainBufLS,
		~specLS.pitch41.map(In.kr(pitchBus,1)) * ~specLS.pitch412.map(In.kr(pitch2Bus,1)) * BufRateScale.kr(~mainBufLS),
		trig, ~specLS.startPos21L.map(startPosition), 1, lag: ~cfgLS.playBufLag
	) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
	sig = IEnvGen.kr(~specLS.amp21, In.kr(ampBus,1)) * sig;
	sig = ~specLS.dist21.map(In.kr(distBus,1)) * sig;
	sig = RLPF.ar(sig, ~specLS.ff41.map(In.kr(ffBus,1) + (0.2 * LFNoise1.kr(ffSpeedVal))),
		0.5 + (0.1 * LFNoise1.kr(1)));
	// sig = RLPF.ar(sig, ~specLS.ff41.map(In.kr(ffBus,1) + (0.2 * LFNoise1.kr(0.2))), 0.5 + (0.1 * LFNoise1.kr(1)));
	// sig = RLPF.ar(sig, ~specLS.ff41.map(In.kr(ffBus,1) + (0.2 * LFNoise1.kr(2))), 0.5 + (0.1 * LFNoise1.kr(1)));
	Out.ar(~aBus.outA, sig);
}).send(s);

SynthDef(\zone4play1hf, {
	arg gate, lenBus, startPosition = 0, distBus;
	var trig, sig;

	//	trig = Impulse.ar(1 / IEnvGen.kr(~specLS.len41, In.kr(lenBus,1)));
	trig = Impulse.ar((2**3) * BufRateScale.kr(~mainBufLS) / In.kr(lenBus,1));

	sig = PlayBufAlt.ar(2, ~mainBufLS, (2**3) * BufRateScale.kr(~mainBufLS), trig,
		~specLS.startPos21L.map(startPosition), 1, lag: ~cfgLS.playBufLag
	) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
	sig = ~specLS.dist21hf.map(In.kr(distBus,1)) * sig;
	Out.ar(~aBus.outA, sig);
}).send(s);

SynthDef(\zone4play1lf, {
	arg gate, lenBus, startPosition = 0, distBus;
	var trig, sig;

	trig = Impulse.ar(1 / In.kr(lenBus,1));
	sig = PlayBufAlt.ar(2, ~mainBufLS, (0.5**3) * BufRateScale.kr(~mainBufLS), trig,
		~specLS.startPos21L.map(startPosition), 1, lag: ~cfgLS.playBufLag
	) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
	sig = ~specLS.dist21lf.map(In.kr(distBus,1)) * sig;
	Out.ar(~aBus.outA, sig);
}).send(s);

////////// Zone 6 joystick //////////////////////////////////////

SynthDef(\zone6play1, { // trigger button
	arg gate, lenBus, startPosition = 0, distBus, pitchBus;
	var trig, sig, lenBusVal, playHead, pitchBusVal;

	lenBusVal = ~specLS.len61.map(In.kr(lenBus,1));
	// pitchBusVal = ~specLS.pitch61.map(In.kr(pitchBus,1));
	// pitchBusVal = IEnvGen.kr(~specLS.pitch61, In.kr(pitchBus,1));
	pitchBusVal = In.kr(pitchBus,1); // pitchBus already spec'd in OSCresponder
	trig = Impulse.ar(1 / lenBusVal);

	if(~showBufferView == 1,{
		playHead = ( Phasor.ar(
			trig,
			pitchBusVal * BufRateScale.kr(~mainBufLS),
			~specLS.startPos61.map(startPosition),
			~specLS.startPos61.map(startPosition) + ((lenBusVal*pitchBusVal)*~sRate),
			~specLS.startPos61.map(startPosition)
		) ) % BufFrames.kr(~mainBufLS);
		SendReply.kr(Impulse.kr(~cfgLS.bufferViewPlayHeadFreq), "/playHead",
			[playHead/~sRate, ~specLS.startPos61.map(startPosition)/~sRate, lenBusVal*pitchBusVal], 61)
	});

	sig = PlayBufCF.ar(2, ~mainBufLS, pitchBusVal * BufRateScale.kr(~mainBufLS), trig,
		~specLS.startPos61.map(startPosition), 1,
		lag: ~cfgLS.playBufLag
	) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
	sig = IEnvGen.kr(~specLS.dist61, In.kr(distBus,1)) * sig;
	Out.ar(~aBus.outB, sig);
}).send(s);

SynthDef(\zone6play1Plus, { // trigger button
	arg gate, lenBus, startPosition = 0, distBus, pitchBus;
	var trig1, trig2, sig1, sig2, sig;

	trig1 = Impulse.ar(1 / ~specLS.len61Plus1.map(In.kr(lenBus,1)));
	trig2 = Impulse.ar(1 / ~specLS.len61Plus2.map(In.kr(lenBus,1)));

	sig1 = PlayBufCF.ar(2, ~mainBufLS,
		// ~specLS.pitch61.map(In.kr(pitchBus,1)) * BufRateScale.kr(~mainBufLS),
		// IEnvGen.kr(~specLS.pitch61,In.kr(pitchBus,1)) * BufRateScale.kr(~mainBufLS),
		In.kr(pitchBus,1) * BufRateScale.kr(~mainBufLS), // pitchBus already spec'd in OSCresponder
		trig1, ~specLS.startPos61Plus1.map(startPosition), 1, lag: ~cfgLS.playBufLag
	) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
	sig2 = PlayBufCF.ar(2, ~mainBufLS,
		// ~specLS.pitch61.map(In.kr(pitchBus,1)) * BufRateScale.kr(~mainBufLS),
		// IEnvGen.kr(~specLS.pitch61,In.kr(pitchBus,1)) * BufRateScale.kr(~mainBufLS),
		In.kr(pitchBus,1) * BufRateScale.kr(~mainBufLS), // pitchBus already spec'd in OSCresponder
		trig2, ~specLS.startPos61Plus2.map(startPosition), 1, lag: ~cfgLS.playBufLag
	) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);

	sig1 = Balance2.ar(sig1[0], sig1[1],-0.8);
	sig2 = Balance2.ar(sig2[0], sig2[1],0.8);
	sig = sig1 + sig2;
	sig = IEnvGen.kr(~specLS.dist61, In.kr(distBus,1)) * sig;
	Out.ar(~aBus.outB, sig);
}).send(s);

SynthDef(\zone6play2, { // side button
	arg gate, lenBus, startPosition = 0, distBus, ffBus, panBus;
	var trig, sig, playHead, lenBusVal;

	lenBusVal = ~specLS.len62.map(In.kr(lenBus,1));
	trig = Impulse.ar(1 / lenBusVal);

	if(~showBufferView == 1, {
		playHead = ( Phasor.ar(
			trig,
			BufRateScale.kr(~mainBufLS),
			~specLS.startPos62.map(startPosition),
			~specLS.startPos62.map(startPosition) + (lenBusVal*~sRate),
			~specLS.startPos62.map(startPosition)
		) ) % BufFrames.kr(~mainBufLS);
		SendReply.kr(Impulse.kr(~cfgLS.bufferViewPlayHeadFreq), "/playHead",
			[playHead/~sRate, ~specLS.startPos62.map(startPosition)/~sRate, lenBusVal], 62)
	});

	sig = PlayBufCF.ar(2, ~mainBufLS, BufRateScale.kr(~mainBufLS), trig,
		~specLS.startPos62.map(startPosition), 1, lag: ~cfgLS.playBufLag
	) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
	sig = IEnvGen.kr(~specLS.dist61, In.kr(distBus,1)) * sig;
	sig = RHPF.ar(sig, ~specLS.ff62.map(In.kr(ffBus,1)), 0.5);
	sig = Balance2.ar(sig[0], sig[1],In.kr(panBus,1));
	Out.ar(~aBus.outB, sig);
}).send(s);

SynthDef(\zone6play3, { // top button
	arg gate, lenBus, startPosition = 0, distBus, ffBus, panBus;
	var trig, sig, playHead, lenBusVal;

	lenBusVal = ~specLS.len63.map(In.kr(lenBus,1));
	trig = Impulse.ar(1 / lenBusVal);

	if(~showBufferView == 1, {
		playHead = ( Phasor.ar(
			trig,
			BufRateScale.kr(~mainBufLS),
			~specLS.startPos63.map(startPosition),
			~specLS.startPos63.map(startPosition) + (lenBusVal*~sRate),
			~specLS.startPos63.map(startPosition)
		) ) % BufFrames.kr(~mainBufLS);
		SendReply.kr(Impulse.kr(~cfgLS.bufferViewPlayHeadFreq), "/playHead",
			[playHead/~sRate, ~specLS.startPos63.map(startPosition)/~sRate, lenBusVal], 63)
	});

	sig = PlayBufCF.ar(2, ~mainBufLS, BufRateScale.kr(~mainBufLS), trig,
		~specLS.startPos63.map(startPosition), 1, lag: ~cfgLS.playBufLag
	) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
	sig = IEnvGen.kr(~specLS.dist61, In.kr(distBus,1)) * sig;
	sig = RLPF.ar(sig, ~specLS.ff63.map(In.kr(ffBus,1)), 0.5);
	sig = Balance2.ar(sig[0], sig[1],In.kr(panBus,1));
	Out.ar(~aBus.outB, sig);
}).send(s);

SynthDef(\zone6play4, { // base button 1
	arg gate, lenBus, startPosition = 0, distBus, pitchBus, panBus;
	var trig, sig, playHead, lenBusVal, pitchBusVal;

	lenBusVal = IEnvGen.kr(~specLS.len64,In.kr(lenBus,1));
	pitchBusVal = ~specLS.pitch64.map(In.kr(pitchBus,1));

	trig = Impulse.ar(1 / lenBusVal);
	//	SendTrig.kr(Impulse.kr(4),1,In.kr(panBus,1));

	if(~showBufferView == 1, {
		playHead = ( Phasor.ar(
			trig,
			BufRateScale.kr(~mainBufLS),
			~specLS.startPos64.map(startPosition),
			~specLS.startPos64.map(startPosition) + (lenBusVal*pitchBusVal*~sRate),
			~specLS.startPos64.map(startPosition)
		) ) % BufFrames.kr(~mainBufLS);
		SendReply.kr(Impulse.kr(~cfgLS.bufferViewPlayHeadFreq), "/playHead",
			[playHead/~sRate, ~specLS.startPos64.map(startPosition)/~sRate, lenBusVal*pitchBusVal], 64)
	});

	sig = PlayBufCF.ar(2, ~mainBufLS, pitchBusVal * BufRateScale.kr(~mainBufLS), trig,
		~specLS.startPos64.map(startPosition), 1,
		lag: ~cfgLS.playBufLag
	) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
	sig = IEnvGen.kr(~specLS.dist61, In.kr(distBus,1)) * sig;
	sig = Balance2.ar(sig[0], sig[1],In.kr(panBus,1));
	Out.ar(~aBus.outB, sig);
}).send(s);

// SynthDef(\zone6play5, { // base button 2 --- not used
// 	arg gate, lenBus, startPosition = 0, distBus, pitchBus, panBus;
// 	var trig, sig, playHead, lenBusVal, pitchBusVal;
//
// 	lenBusVal = ~specLS.len65.at(In.kr(lenBus,1));
// 	pitchBusVal = ~specLS.pitch65.map(In.kr(pitchBus,1));
//
// 	trig = Impulse.ar(1 / lenBusVal);
//
// 	if(~showBufferView == 1,{
// 		playHead = (
// 			Phasor.ar(
// 				trig,
// 				pitchBusVal * BufRateScale.kr(~mainBufLS),
// 				~specLS.startPos64.map(startPosition),
// 				~specLS.startPos64.map(startPosition) + (lenBusVal*pitchBusVal*~sRate),
// 				~specLS.startPos64.map(startPosition)
// 			)
// 		) % BufFrames.kr(~mainBufLS);
// 		SendReply.kr(Impulse.kr(~cfgLS.bufferViewPlayHeadFreq), "/playHead",
// 		[playHead/~sRate, ~specLS.startPos64.map(startPosition)/~sRate, lenBusVal*pitchBusVal], 65)
// 	});
//
// 	sig = PlayBufCF.ar(
// 		2,
// 		~mainBufLS,
// 		pitchBusVal * BufRateScale.kr(~mainBufLS),
// 		trig,
// 		~specLS.startPos64.map(startPosition),
// 		1,
// 		lag: ~cfgLS.playBufLag
// 	) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
// // sig = ~specLS.dist61.map(In.kr(distBus,1)) * sig;
// sig = IEnvGen.kr(~specLS.dist61, In.kr(distBus,1)) * sig;
// 	sig = Balance2.ar(sig[0], sig[1],In.kr(panBus,1));
// 	Out.ar(~aBus.outB, sig);
// }).send(s);

////////// Zone 8 MIDI //////////////////////////////////////

SynthDef(\zone8play1, {
	arg gate, lenBus, startPosition = 0, ampBus, distBus, pitchPattBus, jumpBus, panBus, ampPattBus, dirBus, pitchBus, pattSelBus;
	var sig, lenBusVal, resetTrig = 1, jumpBusVal, playHead, rateOn, rate, winSize, winRanRatio, winOverlaps, pitch;

	// map params dependent on rateOn, so dependent on the pattern select knob
	rate = IEnvGen.kr(~specLS.rate81, In.kr(pitchBus,1));
	rateOn = ( In.kr(pattSelBus,1) < 0.05 );
	rate = (rateOn * rate) + (1-rateOn);
	winSize = (rateOn * 0.2) + ((1-rateOn) * 0.1);
	winRanRatio = (rateOn * 0.5) + ((1-rateOn) * 0.2);
	winOverlaps = (rateOn * 8) + ((1-rateOn) * 4);
	pitch = rateOn + ( (1-rateOn)*IEnvGen.kr(~specLS.pitch81, In.kr(pitchBus,1)) );

	lenBusVal = IEnvGen.kr(~specLS.len81, In.kr(lenBus,1)) / rate;
	jumpBusVal = In.kr(jumpBus,1) / rate;
	startPosition = ~specLS.startPos21L.map(startPosition) / rate;
	resetTrig = HPZ2.kr(jumpBusVal);

	playHead = ( Phasor.ar(
		resetTrig,
		// IEnvGen.kr(~specLS.pitch81, In.kr(pitchBus,1)) * In.kr(pitchPattBus,1) *
		// uncomment in case of using BufRd
		BufRateScale.kr(~mainBufLS) * In.kr(dirBus,1),
		startPosition,
		startPosition + lenBusVal,
		startPosition + (jumpBusVal % lenBusVal)
	) ) % BufFrames.kr(~mainBufLS);
	playHead = rate * playHead;

	// update bufferView
	if(~showBufferView == 1,
		{SendReply.kr(Impulse.kr(~cfgLS.bufferViewPlayHeadFreq), "/playHead",
			[playHead/~sRate, startPosition/~sRate*rate, lenBusVal/~sRate*rate], 81)});

	// sig = BufRd.ar(2, ~mainBufLS, playHead, 1,  4);
	sig = Warp1.ar(2, ~mainBufLS, playHead/BufFrames.kr(~mainBufLS), pitch * In.kr(pitchPattBus,1),
		winSize, -1, winOverlaps, winRanRatio, 4);
	sig = sig * EnvGen.kr(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
	sig = IEnvGen.kr(~specLS.amp81, In.kr(ampBus,1)) * sig;
	sig = ~specLS.dist21.map(In.kr(distBus,1)) * sig;
	sig = In.kr(ampPattBus,1) * sig;
	sig = Balance2.ar(sig[0], sig[1],In.kr(panBus,1));
	Out.ar(~aBus.outA, sig);
}).send(s);

////////// Zone 16 MIDI //////////////////////////////////////

SynthDef(\zone16play1_old_version, {
	arg gate, ampBus, distBus, resetPosBus, lenBus, panBus, ffBus;
	var sig, resetTrig = 1, resetPosBusVal, lenBusVal, playHead;

	lenBusVal = In.kr(lenBus,1) * ~sRate;
	resetPosBusVal = In.kr(resetPosBus,1) * lenBusVal;
	resetTrig = HPZ2.kr(In.kr(resetPosBus,1));

	playHead = ( Phasor.ar(
		resetTrig,
		BufRateScale.kr(~mainBufLS),
		~bufferLS.dyn1Start,
		~bufferLS.dyn1Start + lenBusVal,
		~bufferLS.dyn1Start + resetPosBusVal
	) ) % BufFrames.kr(~mainBufLS);

	// update bufferView
	if(~showBufferView == 1,
		{SendReply.kr(Impulse.kr(~cfgLS.bufferViewPlayHeadFreq), "/playHead",
			[playHead/~sRate, ~bufferLS.dyn1Start/~sRate, lenBusVal/~sRate], 161)});

	// sig = Warp1.ar(2, ~mainBufLS, playHead / BufFrames.kr(~mainBufLS)) * EnvGen.kr(Env.adsr(0.1,0,1,0.1),
	// 		gate, doneAction: 2);
	sig = BufRd.ar(2, ~mainBufLS, playHead, 1, 4) * EnvGen.kr(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
	sig = IEnvGen.kr(~specLS.amp21, In.kr(ampBus,1)) * sig;
	sig = ~specLS.dist21.map(In.kr(distBus,1)) * sig;
	sig = Balance2.ar(sig[0], sig[1],~specLS.pan161.map(In.kr(panBus,1)));
	sig = RLPF.ar(sig, ~specLS.ff21.map(In.kr(ffBus,1)), 0.5);
	Out.ar(~aBus.outA, sig);
}).send(s);

SynthDef(\zone16play1, {
	arg gate, ampBus, distBus, lenBus, panBus, ffBus;
	var sig, trig, env, lenFactor = 1, startFactor = 0, startPos, lenBusVal, playHead;
	var stepsOffset = [0.0, 0.1, 0.0, 0.2, 0.1, 0.3, 0.5, 0.6, 0.9]; // offset values for SP
	var modDepth = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 0.9, 0.8, 0.7, 0.6, 0.5]; // factor values for SP

	lenBusVal = In.kr(lenBus,1);
	lenFactor = LFNoise0.kr(1).range(0.3,1);
	trig = Impulse.kr( 1 / (lenFactor * min(lenBusVal,1)) );

	startFactor = Demand.kr(trig, 0, Dseq(stepsOffset, inf) * Dseq(modDepth, inf));
	startPos = ~bufferLS.dyn1Start + (startFactor * lenBusVal * ~sRate);

	// update bufferView
	if(~showBufferView == 1, {
		playHead = Phasor.ar(
			trig,
			BufRateScale.kr(~mainBufLS),
			startPos,
			startPos + (lenFactor * min(lenBusVal,1)),
			startPos
		) % BufFrames.kr(~mainBufLS);
		SendReply.kr(Impulse.kr(~cfgLS.bufferViewPlayHeadFreq), "/playHead",
			[playHead/~sRate, ~bufferLS.dyn1Start/~sRate, lenBusVal/~sRate], 161)
	});

	env = EnvGen.ar(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
	sig = PlayBufCF.ar(2,~mainBufLS, trigger: trig, lag: 0.05, n: 2, startPos: startPos);
	sig = IEnvGen.kr(~specLS.amp21, In.kr(ampBus,1)) * sig;
	sig = ~specLS.dist21.map(In.kr(distBus,1)) * sig;
	sig = Balance2.ar(sig[0], sig[1],~specLS.pan161.map(In.kr(panBus,1)));
	sig = RLPF.ar(sig, ~specLS.ff21.map(In.kr(ffBus,1)), 0.5);
	Out.ar(~aBus.outA, sig);
}).send(s);

2.do { |i|
	SynthDef("zone16play2" ++ if(i==0, {""}, {"bw"}), {
		arg gate, ampBus, lenBus, distBus, pitchRangeBus, pitchSelectBus;
		var trig, sig, pitchArray, pitchSelected, playHead, sign, trig2, lenBusVal;

		lenBusVal = In.kr(lenBus,1);
		pitchArray = [
			IEnvGen.kr(~specLS.pitch162, LFTri.ar(0.2).range(0,In.kr(pitchRangeBus,1))),
			IEnvGen.kr(~specLS.pitch162up1, LFSaw.ar(0.4).range(0,In.kr(pitchRangeBus,1))),
			IEnvGen.kr(~specLS.pitch162down1, LFSaw.ar(0.4).range(1, (1 - In.kr(pitchRangeBus,1)))),
			IEnvGen.kr(~specLS.pitch162lisa1, LFSaw.ar(0.3).range(0,In.kr(pitchRangeBus,1))),
			IEnvGen.kr(~specLS.pitch162ran, LFNoise0.ar(100).range(0,In.kr(pitchRangeBus,1)))
		];
		pitchSelected = Select.kr(
			IEnvGen.kr(~specLS.pitch16select, In.kr(pitchSelectBus,1)),
			pitchArray);
		trig = Impulse.ar(pitchSelected / (lenBusVal - ~zoneRecLS.dynOverflow));

		if(~showBufferView == 1,{
			trig2 = Impulse.ar(pitchSelected / (lenBusVal*2));
			sign = LFPulse.ar(pitchSelected / (lenBusVal*2), width: 0.5).range(-1,1);

			playHead = ( Phasor.ar(
				trig2,
				pitchSelected * BufRateScale.kr(~mainBufLS) * sign,
				~bufferLS.dyn2Start,
				~bufferLS.dyn2Start + (lenBusVal*2*~sRate),
				~bufferLS.dyn2Start
			) ) % BufFrames.kr(~mainBufLS);
			SendReply.kr(Impulse.kr(~cfgLS.bufferViewPlayHeadFreq), "/playHead",
				[playHead/~sRate, ~bufferLS.dyn2Start/~sRate, lenBusVal], 162)
		});

		if(i==0, {
			sig = PlayBufAlt.ar(2, ~mainBufLS, pitchSelected * BufRateScale.kr(~mainBufLS), trig,
				~bufferLS.dyn2Start, 1, lag: ~cfgLS.playBufLag);
		}, {
			sig = PlayBufCF.ar(2, ~mainBufLS, -1.0 * pitchSelected * BufRateScale.kr(~mainBufLS), trig,
				~bufferLS.dyn2Start + (lenBusVal*~sRate),
				1, lag: ~cfgLS.playBufLag);
		});
		sig = sig * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
		sig = IEnvGen.kr(~specLS.amp21, In.kr(ampBus,1)) * sig;
		sig = ~specLS.dist21.map(In.kr(distBus,1)) * sig;
		sig = Balance2.ar(sig[0], sig[1],-0.5);
		Out.ar(~aBus.outA, sig);
	}).send(s);
};

2.do { |i|
	SynthDef("zone16play3" ++ if(i==0, {""}, {"bw"}), {
		arg gate, ampBus, lenBus, distBus, pitchRangeBus, pitchSelectBus;
		var trig, sig, pitchArray, pitchSelected, playHead, sign, trig2, lenBusVal;

		lenBusVal = In.kr(lenBus,1);
		pitchArray = [
			IEnvGen.kr(~specLS.pitch162, LFTri.ar(0.2).range(0,In.kr(pitchRangeBus,1))),
			IEnvGen.kr(~specLS.pitch162up2, LFSaw.ar(0.4).range(0,In.kr(pitchRangeBus,1))),
			IEnvGen.kr(~specLS.pitch162down2, LFSaw.ar(0.4).range(1, (1 - In.kr(pitchRangeBus,1)))),
			IEnvGen.kr(~specLS.pitch162lisa2, LFSaw.ar(0.2).range(0,In.kr(pitchRangeBus,1))),
			IEnvGen.kr(~specLS.pitch162ran, LFNoise0.ar(100).range(0,In.kr(pitchRangeBus,1)))
		];
		pitchSelected = Select.kr(
			IEnvGen.kr(~specLS.pitch16select, In.kr(pitchSelectBus,1)),
			pitchArray);
		trig = Impulse.ar(pitchSelected / (lenBusVal - ~zoneRecLS.dynOverflow));

		if(~showBufferView == 1,{
			trig2 = Impulse.ar(pitchSelected / (lenBusVal*2));
			sign = LFPulse.ar(pitchSelected / (lenBusVal*2), width: 0.5).range(-1,1);

			playHead = ( Phasor.ar(
				trig2,
				pitchSelected * BufRateScale.kr(~mainBufLS) * sign,
				~bufferLS.dyn3Start,
				~bufferLS.dyn3Start + (lenBusVal*2*~sRate),
				~bufferLS.dyn3Start
			) ) % BufFrames.kr(~mainBufLS);
			SendReply.kr(Impulse.kr(~cfgLS.bufferViewPlayHeadFreq), "/playHead",
				[playHead/~sRate, ~bufferLS.dyn3Start/~sRate, lenBusVal], 163)
		});

		if(i==0, {
			sig = PlayBufAlt.ar(2, ~mainBufLS, pitchSelected * BufRateScale.kr(~mainBufLS), trig,
				~bufferLS.dyn3Start, 1, lag: ~cfgLS.playBufLag);
		}, {
			sig = PlayBufCF.ar(2, ~mainBufLS, -1.0 * pitchSelected * BufRateScale.kr(~mainBufLS), trig,
				~bufferLS.dyn3Start + (lenBusVal*~sRate), 1, lag: ~cfgLS.playBufLag);
		});
		sig = sig * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
		sig = IEnvGen.kr(~specLS.amp21, In.kr(ampBus,1)) * sig;
		sig = ~specLS.dist21.map(In.kr(distBus,1)) * sig;
		sig = Balance2.ar(sig[0], sig[1],0.5);
		Out.ar(~aBus.outA, sig);
	}).send(s);
};

SynthDef(\zone16play4, {
	arg gate, ampBus, distBus, resetPosBus, lenBus, panBus, ffBus;
	var sig, resetTrig = 1, resetPosBusVal, lenBusVal, playHead;

	lenBusVal = In.kr(lenBus,1) * ~sRate;
	resetPosBusVal = In.kr(resetPosBus,1) * lenBusVal;
	resetTrig = HPZ2.kr(In.kr(resetPosBus,1));

	playHead = ( Phasor.ar(
		resetTrig,
		BufRateScale.kr(~mainBufLS),
		~bufferLS.dyn4Start,
		~bufferLS.dyn4Start + lenBusVal,
		~bufferLS.dyn4Start + resetPosBusVal
	) ) % BufFrames.kr(~mainBufLS);
	// update bufferView
	if(~showBufferView == 1,
		{SendReply.kr(Impulse.kr(~cfgLS.bufferViewPlayHeadFreq), "/playHead",
			[playHead/~sRate, ~bufferLS.dyn4Start/~sRate, lenBusVal/~sRate], 164)});

	sig = BufRd.ar(2, ~mainBufLS, playHead, 1, 4) * EnvGen.kr(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
	sig = IEnvGen.kr(~specLS.amp21, In.kr(ampBus,1)) * sig;
	sig = ~specLS.dist21.map(In.kr(distBus,1)) * sig;
	sig = Balance2.ar(sig[0], sig[1],~specLS.pan164.map(In.kr(panBus,1)));
	sig = RLPF.ar(sig, ~specLS.ff21.map(In.kr(ffBus,1)), 0.5);
	Out.ar(~aBus.outA, sig);
}).send(s);

SynthDef(\diskPlay1, {
	arg buf, gate, att, rel, distBus, volBus, ffBus, rateBus, rateModBus, effectSendBus,
	lp = 1, lpfOn = 1, rate = 1, gain = 1, out;
	var sig, rateBusVal, rateModBusVal, effectSendVal = 0;

	effectSendVal = In.kr(effectSendBus,1);
	rateModBusVal = IEnvGen.kr(~specLS.diskPlayRateMod, In.kr(rateModBus,1));
	rateBusVal = IEnvGen.kr(~specLS.diskPlayRate, In.kr(rateBus,1)) +
	SinOsc.kr(LFNoise1.kr(0.3).range(2,10)).range(rateModBusVal.neg,rateModBusVal);

	sig = VDiskIn.ar(1, buf, rateBusVal*rate,lp) * EnvGen.kr(Env.adsr(att,0,1,rel), gate, doneAction: 2);
	sig = ~specLS.dist21.map(In.kr(distBus,1)) * sig * In.kr(volBus,1);
	sig = ( lpfOn * RLPF.ar(sig, ~specLS.ff21.map(In.kr(ffBus,1)), 0.5) ) + ( (1-lpfOn) * sig );
	sig = sig * gain;
	Out.ar(out, [sig,sig] * (1-effectSendVal));
	Out.ar(~aBus.outA, [sig,sig] * effectSendVal);
}).send(s);

SynthDef(\diskPlay2, {
	arg buf, gate, att, rel, distBus, volBus, ffBus, rateBus, rateModBus, effectSendBus,
	lp = 1, lpfOn = 1, rate = 1, gain = 1, out;
	var sig, rateBusVal, rateModBusVal, effectSendVal = 0;

	effectSendVal = In.kr(effectSendBus,1);
	rateModBusVal = IEnvGen.kr(~specLS.diskPlayRateMod, In.kr(rateModBus,1));
	rateBusVal = IEnvGen.kr(~specLS.diskPlayRate, In.kr(rateBus,1)) +
	SinOsc.kr(LFNoise1.kr(0.3).range(2,10)).range(rateModBusVal.neg,rateModBusVal);

	sig = VDiskIn.ar(2, buf, rateBusVal*rate,lp) * EnvGen.kr(Env.adsr(att,0,1,rel), gate, doneAction: 2);
	sig = ~specLS.dist21.map(In.kr(distBus,1)) * sig * In.kr(volBus,1);
	sig = ( lpfOn * RLPF.ar(sig, ~specLS.ff21.map(In.kr(ffBus,1)), 0.5) ) + ( (1-lpfOn) * sig );
	sig = sig * gain;
	Out.ar(out, sig * (1-effectSendVal));
	Out.ar(~aBus.outA, sig * effectSendVal);
}).send(s);

SynthDef(\stretchedFragments, {
	arg start, time = 1, stretch = 1, amp = 1, dist = 0, attack = 0.001, release = 0.05,
	ampSine = 0, ampPluck = 0, freq = 440,
	coef = 0.2, decay = 4;
	var sig, sigKick, sigPluck, kickFreq, kickFreqList;

	sig = PlayBufCF.ar(2, ~mainBufLS, rate: BufRateScale.kr(~mainBufLS)/stretch, startPos: ~specLS.startPos171.map(start));
	sig = PitchShift.ar(sig, pitchRatio: stretch, windowSize: 0.1);
	sig = sig * EnvGen.kr(Env.linen(attack, time, release), doneAction: 2);

	// sigKick = (EnvGen.kr(Env.linen(0.01,0.1,0.01)) * 0.5 * SinOsc.ar(LFNoise0.ar(1).range(50,100))).dup;
	kickFreqList = Dwrand([900,200,50,2000],[0.5,0.2,0.2,0.1],1);
	kickFreq = Demand.ar(Impulse.ar(0),0,kickFreqList);
	sigKick = Pan2.ar(LPF.ar(Ringz.ar(Impulse.ar(0), Rand(50,80), Rand(0.5,0.8)), kickFreq, mul:2),Rand(-0.5,0.5));
	// sigKick = sigKick + (0.2*DelayL.ar(sigKick,time/2,time/2));

	sigPluck = Pluck.ar(
		in: WhiteNoise.ar(0.1),
		trig: Impulse.kr(0),
		maxdelaytime: 0.1,
		delaytime: freq.reciprocal,
		decaytime: decay,
		coef: coef);
	sig = (~specLS.dist171.map(dist) * ~specLS.amp171.map(amp) * sig)
	+ DelayL.ar((ampSine*sigKick) + (ampPluck*sigPluck),0.2,0.1);
	Out.ar(~aBus.outA, sig);
}).store;

///////////////////////////////////////////// Synthesis Synths //////////////////////////////////////

SynthDef(\synth6play6,{
	arg freq1, gate, distBus, cutoffBus, resBus, ampmod, pitchBus; var sig, ampmodVal, cutoffVal, resVal, pitchVal, distVal;

	ampmodVal = IEnvGen.kr(~specLS.ampMod66, ampmod);
	cutoffVal = IEnvGen.kr(~specLS.cutoff66, In.kr(cutoffBus,1));
	resVal = IEnvGen.kr(~specLS.res66, In.kr(resBus,1));
	pitchVal = IEnvGen.kr(~specLS.pitch66, In.kr(pitchBus,1));
	distVal = IEnvGen.kr(~specLS.dist66, In.kr(distBus,1));

	freq1 = freq1 * pitchVal;

	sig = RLPF.ar(
		Saw.ar(SinOsc.ar(2)*1.01 + (freq1 + (8.midicps/128))) *
		Saw.ar(SinOsc.ar(2)*1.03 + (freq1 + (5.midicps/128))) *
		Saw.ar(SinOsc.ar(2) + (freq1 - (3.midicps/128))),
		cutoffVal, resVal, 1);
	sig = RLPF.ar(sig,cutoffVal, resVal, 1);
	sig = 0.7*sig + 0.3*SinOsc.ar(freq1);
	sig = Pan2.ar(sig,Rand(-0.5,0.5));
	sig = sig * LFNoise1.ar(ampmodVal).range(0.5,1);
	sig = sig * distVal;
	sig = sig * EnvGen.kr(Env.adsr(2,0,1,2), gate, doneAction: 2) ;
	Out.ar(~aBus.outB, sig);
}).send(s);

SynthDef(\synth6play7,{
	arg gate, freqBus, gravAmpBus, cutoffBus, ringBus;
	var freqVal, gravAmpVal, cutoffVal, ringVal, gravity, sig;

	freqVal = IEnvGen.kr(~specLS.freq67, In.kr(freqBus,1));
	gravAmpVal = IEnvGen.kr(~specLS.gravAmp67, In.kr(gravAmpBus,1));
	cutoffVal = IEnvGen.kr(~specLS.cutoff67, In.kr(cutoffBus,1));
	ringVal = IEnvGen.kr(~specLS.ring67, In.kr(ringBus,1));
	gravity = LFNoise1.kr(0.1, 3, 5) * gravAmpVal;
	sig = TBall.ar(SinOsc.ar(freqVal), gravity, 0.1, 0.0001);
	sig = Ringz.ar(sig, ringVal, 0.5);
	sig = RLPF.ar(sig, cutoffVal);
	sig = Pan2.ar(sig, LFNoise0.kr(10).range(-1,1),5);
	sig = 0.7 * sig * EnvGen.kr(Env.adsr(2,0,1,2), gate, doneAction: 2) ;
	Out.ar(~aBus.outB, sig);
}).send(s);

SynthDef(\whoosh, {
	arg gate = 1, ampScale = 1, lenScale = 1, lowBus, highBus, decBus;
	var sig, sigL, sigH, sigDec;
	var envAmpL, envAmpH, envL, envH, envDec, ampScaleL, ampScaleH;

	lenScale = lenScale * Rand(0.3,0.7);
	ampScaleL = ampScale * Rand(0.7,1.1);
	ampScaleH = ampScale * Rand(0.7,1.1);

	envAmpL = Env([0, 1, 7, 10, 0]*ampScaleL, [0.01, 3, 2, 1]*lenScale);
	envL = Env([50, 10000, 1000, 100, 50], [0.01, 1, 3, 2]*lenScale,[\lin,\exp,\exp,\lin]);

	envAmpH = Env([0, 1, 3, 6, 0]*ampScaleH, [0.01, 4, 3, 0.1]*lenScale);
	envH = Env([10000, 50, 1000, 20000, 21000], [0.01, 1, 4, 2.1]*lenScale,[\lin,\exp,\exp,\exp]);
	envDec = Env([0, 0, 5, 0]*ampScaleH, [1, 6, 1]*lenScale);

	sig = 0.8 * PinkNoise.ar();

	// sigL = RLPF.ar(sig,EnvGen.ar(envL,gate)) * EnvGen.ar(envAmpL,gate);
	sigL = MoogFF.ar(sig,EnvGen.ar(envL,gate)) * EnvGen.ar(envAmpL,gate);
	sigL = Pan2.ar(sigL,LFNoise1.ar(1));

	sigH = MoogFF.ar(sig,EnvGen.ar(envH,gate)) * EnvGen.ar(envAmpH,gate);
	// sigH = GlitchRHPF.ar(sig,EnvGen.ar(envH,gate)) * EnvGen.ar(envAmpH,gate);
	sigH = Pan2.ar(sigH,LFNoise1.ar(1));

	sigDec = ((0.2 * CrossoverDistortion.ar(sigH,amp: 0.1,smooth: 0.5))
		+ (0.8 * Disintegrator.ar(sigH,probability: 0.9)))
	* EnvGen.ar(envDec,gate, doneAction: 2);

	sig = (
		(sigL * IEnvGen.kr(~specLS.low65, (1 - In.kr(lowBus,1))))
		+
		(sigH * IEnvGen.kr(~specLS.high65, (1 - In.kr(highBus,1))))
		+
		(sigDec * IEnvGen.kr(~specLS.dec65, In.kr(decBus,1)))
	);
	// Out.ar(~aBus.outMain,sig);
	Out.ar(~aBus.outB,sig);
}).add;

SynthDef(\fftDrone, {
	arg gate = 1, distBus, pulseBus, cutoffBus;
	var gain = 15, mags, phases, chain, sig, pulseVal = 0.3, env, distVal = 1,
	cutoffVal = 3000, bufSize = 2048, bins = 350;

	distVal = IEnvGen.kr(~specLS.distFftDrone, In.kr(distBus,1));
	pulseVal = IEnvGen.kr(~specLS.pulseFftDrone, In.kr(pulseBus,1));
	cutoffVal = IEnvGen.kr(~specLS.cutoffFftDrone, In.kr(cutoffBus,1));

	env = EnvGen.kr( Env.asr, gate, doneAction: 2);
	mags = {FSinOsc.kr(ExpRand(0.1, 1)).range(0, 1)}.dup(bins);
	mags = mags  * ((1, 0.99 .. 0.01).squared);
	mags = mags * (Array.series(bins, 1, -1/bins).squared);
	mags = mags.reverse;

	mags = ( pulseVal * mags * {LFPulse.kr(2 ** IRand(-3, 5)).range(0, 1)}.dup(bins) )
	+ ( (1-pulseVal) * mags );
	phases = 0.dup(bins);
	// chain = FFTTrigger(LocalBuf(bufSize), 0.4);
	chain = FFTTrigger(LocalBuf(bufSize), Rand(0.3,0.5));
	chain = PackFFT(chain, bufSize, [mags, phases].flop.flatten, 0, bins-1, 1);
	chain = PV_RectComb(chain, 8, LFNoise1.kr(0.1, 0.4, 0.5).range(0,0.3));
	chain = PV_MagShift(chain, LFNoise1.kr(1).range(0.9,1.1), LFNoise1.kr(1).range(0,0.2));

	sig = IFFT(chain).dup;
	sig = (distVal*sig) + (distVal*3*PitchShift.ar(sig,pitchRatio:0.2));
	// sig = (pulseVal * sig * LFPulse.kr(LFNoise0.kr(2).range(1,4),0, LFNoise1.kr(3).range(0.3,0.7)))
	// + ((1-pulseVal)*sig);
	5.do { sig = AllpassC.ar(sig, 0.2, {Rand(0.01,0.05)}!2,{Rand(1.0,3)}!2) };
	sig = RLPF.ar(sig, {LFNoise1.kr(0.3).range(50,cutoffVal)}!2, 1);

	Out.ar(~aBus.outA, gain * env * sig);
}).add;

SynthDef(\sineAtmos, {
	arg gate = 1, ampBus, distBus, speedBus;
	var sig, freqs, muls, sines, brown, white, env, distVal = 1, speedVal = 1;
	speedVal = IEnvGen.kr(~specLS.speed181, In.kr(speedBus,1));
	distVal = IEnvGen.kr(~specLS.dist181, In.kr(distBus,1));
	env = EnvGen.kr(Env.asr, gate, doneAction: 2);
	freqs = [
		190,
		TWChoose.kr(Impulse.kr(0.2), [80, 95], [0.8, 0.2]),
		TWChoose.kr(Impulse.kr(0.25), [270, 525, 470], [0.5, 0.3, 0.2]),
		900,
		370,
	];
	muls = [1, 5, 1, 1, 0.5];
	sines = Splay.ar(SinOsc.ar(freqs, mul: muls)) * 0.2;
	sines = sines * LFNoise0.kr(TWChoose.kr(Impulse.kr(0.25), [2, 1, 4] * speedVal, [0.8, 0.1, 0.1]));
	brown = SinOsc.kr(10 * speedVal) * BrownNoise.ar(0.07) * SinOsc.kr(0.01, 0).range(0,1);
	white = SinOsc.kr(20 * speedVal) * WhiteNoise.ar(0.02) * SinOsc.kr(0.01, pi).range(0,1);
	sig = sines + Pan2.ar(brown, LFNoise1.kr(0.05).range(-0.3, 0.3))
	+ Pan2.ar(white, LFNoise1.kr(0.05).range(-0.3, 0.3));
	Out.ar(~aBus.outA, sig * In.kr(ampBus, 1) * env * distVal);
}).add;

SynthDef(\throb, {
	arg gate = 1, ampBus, distBus, speedBus, greyholeBus;
	var pulses, freqs, throb, env, distVal = 1, cutoffVal = 50, sines, speedVal = 5, feedbackVal, mixVal;
	cutoffVal = IEnvGen.kr(~specLS.cutoff182, In.kr(distBus,1));
	distVal = IEnvGen.kr(~specLS.dist182, In.kr(distBus,1));
	speedVal = IEnvGen.kr(~specLS.speed182, In.kr(speedBus,1));
	feedbackVal = IEnvGen.kr(~specLS.feedback182, In.kr(greyholeBus,1));
	mixVal = IEnvGen.kr(~specLS.mix182, In.kr(greyholeBus,1));
	env = EnvGen.kr(Env.asr, gate, doneAction: 2);
	pulses = [
		TWChoose.kr(Impulse.kr(0.2), [2, 2.5], [0.5, 0.5]),
		2
	];
	freqs = [
		60,
		TWChoose.kr(Impulse.kr(0.1), [70, 80], [0.5, 0.5]),
	];
	sines = SinOsc.ar(freqs) + RLPF.ar(Saw.ar(freqs), cutoffVal, mul: 0.3 * distVal);
	throb = LFPulse.ar(speedVal) * SinOsc.kr(pulses) * sines;
	throb = LPF.ar(throb, SinOsc.kr(0.05).range(300, 10000));
	throb = (mixVal * Greyhole.ar(throb, 0.2, feedback: feedbackVal)) + ((1 - mixVal) * throb);
	Out.ar(~aBus.outA, throb * In.kr(ampBus, 1) * env);
}).add;

///////////////////////////////////////////// Efx Synths //////////////////////////////////////
// efx signal is sent in outA and outB synths (InOut program) both pre-fade (~aBus.outEfxPre) and post-fade (~aBus.outEfxPost)
// output level controllers in outA and outB thus double as input controllers for post-fade efx

SynthDef(\deciMate, {// efx bank 1 fader 1
	// pre-fade so volume control only through input levels source sound and output level of the effect itself,
	// NOT through outA and outB level control
	arg gate, paramBus, ffBus, decBus, volBus, onExternalInput = 0, inChan1 = 0, inChan2 = 1;
	var sig, ampVal = 0.01, probVal = 0.3, mixDecVal, mixCrossVal, mixDisVal, decVal = 10000;

	// var chain;

	// switch between input channels and sample playback
	sig = (onExternalInput * In.ar([inChan1,inChan2])) +
	((1 - onExternalInput) * In.ar(~aBus.outEfxPre,2));  // get the signal pre-fade

	// chain = FFT(LocalBuf([2048, 2048]), sig);
	// chain = PV_BinScramble(chain, 1, 1, 1 );
	// sig = IFFT(chain);

	ampVal = IEnvGen.kr(~specLS.dmAmp, In.kr(paramBus,1));
	probVal = IEnvGen.kr(~specLS.dmProb, In.kr(paramBus,1));
	mixDecVal = IEnvGen.kr(~specLS.dmMixDec, In.kr(paramBus,1));
	mixCrossVal = IEnvGen.kr(~specLS.dmMixCross, In.kr(paramBus,1));
	mixDisVal = IEnvGen.kr(~specLS.dmMixDis, In.kr(paramBus,1));
	decVal = IEnvGen.kr(~specLS.dmDec, In.kr(decBus,1));

	// [decVal,mixDecVal,ampVal, mixCrossVal,probVal, mixDisVal, ~specLS.ff21.map(In.kr(ffBus,1))].poll;
	sig = Decimator.ar(sig,rate: decVal, bits: 8);
	sig = (mixDecVal * sig) +
	// adds feedback in silences/range amp 0.1 - 0.01 smooth 0.9 - 0.1
	(mixCrossVal * CrossoverDistortion.ar(sig,amp: ampVal,smooth: 0.5)) +
	(mixDisVal * Disintegrator.ar(sig,probability: probVal));
	//sig = SmoothDecimator.ar(sig,44100/8,smoothing: 0.5);
	//sig = SineShaper.ar(sig,0.05); // not sure what it does, not so interesting
	sig = RLPF.ar(sig, ~specLS.ff21.map(In.kr(ffBus,1)),0.5);

	sig = sig * EnvGen.kr(Env.adsr(0,0,1,0), gate, doneAction: 2);
	Out.ar(~aBus.outMain, In.kr(volBus,1) * sig);
}).send(s);

SynthDef(\deLay,  {// efx bank 1 fader 2
	arg gate, volBus, delayTimeBus, inLevelBus, tremSpeedBus, onExternalInput = 0, inChan1 = 0, inChan2 = 1;
	var sig, sigPre, sigOut, mixDelayVal, mixDubVal, inLevelVal;
	var sigDelay, sigDelayL, sigDelayR, delayTimeVal;
	var sigDub, sigDubOut, amp, local, feedVal = 0.5;
	var sigTrem, tremSpeedVal, mixTremVal, tremSpeedVariation0, tremSpeedVariation1,
	tremSpeedVariation2, tremVar0Mix, tremVar1Mix, tremVar2Mix;
	// var tremSpeedVarOff = 1;

	delayTimeVal = IEnvGen.kr(~specLS.dlTime, In.kr(delayTimeBus,1));
	mixDelayVal = IEnvGen.kr(~specLS.dlMixDelay, In.kr(delayTimeBus,1));
	mixDubVal = IEnvGen.kr(~specLS.dlMixDub, In.kr(delayTimeBus,1));
	mixTremVal = IEnvGen.kr(~specLS.dlMixTrem, In.kr(delayTimeBus,1));
	feedVal = IEnvGen.kr(~specLS.dlFeed, In.kr(delayTimeBus,1));
	inLevelVal = In.kr(inLevelBus,1);
	tremSpeedVal = In.kr(tremSpeedBus,1);

	// switch between input channels and sample playback
	sig = inLevelVal * ((onExternalInput * In.ar([inChan1,inChan2])) +
		((1 - onExternalInput) * In.ar(~aBus.outEfxPost,2)));  // get the signal post-fade
	sigPre = (onExternalInput * In.ar([inChan1,inChan2])) +
	((1 - onExternalInput) * In.ar(~aBus.outEfxPre,2));  // get the signal pre-fade
	sigDelay = sig;
	sigDub = sig;

	// Delay
	sigDelayL = AllpassC.ar(sig[0], 10, // alt: CombC
		LFNoise0.ar(LFNoise0.ar(8).range(0.5,10)).range(0.03,0.4) * delayTimeVal,
		LFNoise0.ar(0.3).range(1,12),
		add: (1 - onExternalInput) * In.ar(~aBus.outEfxPost,2) * (1.2 - delayTimeVal)
		// in case on sampleplayback add original signal, but less when delayTime is bigger
	);
	sigDelayR = AllpassC.ar(sig[1], 10, // alt: CombC
		LFNoise0.ar(LFNoise0.ar(10).range(0.5,10)).range(0.01,0.2) * delayTimeVal,
		LFNoise0.ar(0.5).range(0.5,10),
		add: (1 - onExternalInput) * In.ar(~aBus.outEfxPost,2) * (1.2 - delayTimeVal)
		// in case on sampleplayback add original signal, but less when delayTime is bigger
	);

	// Dub
	sigDub = Mix.ar(sigDub);
	amp = Amplitude.kr(sigDub);
	sigDub = sigDub * (amp > 0.02); // noise gate
	local = LocalIn.ar(2) * feedVal;
	local = OnePole.ar(local, 0.4);
	local = OnePole.ar(local, -0.08);
	local = Rotate2.ar(local[0], local[1], 0.2);
	local = DelayN.ar(local, 1, LFNoise1.kr(0.3).range(0.3,0.4));
	LocalOut.ar((local + sigDub).softclip);
	// filter out around freq 110
	sigDubOut = BRF.ar(local,110,0.5);

	// tremolo
	// tremSpeedVarOff = Select.kr(tremSpeedVal.ceil, [0,1]);
	tremVar0Mix = IEnvGen.kr(~specLS.dlTremVar0Mix, tremSpeedVal);
	tremVar1Mix = IEnvGen.kr(~specLS.dlTremVar1Mix, tremSpeedVal);
	tremVar2Mix = IEnvGen.kr(~specLS.dlTremVar2Mix, tremSpeedVal);
	tremSpeedVariation1 = LFNoise1.kr(2).range(0,0.5);
	tremSpeedVariation2 = LFNoise0.kr(10).range(0.2,3);
	tremSpeedVal = (tremVar1Mix * ~specLS.dlTremSpeed.map(tremSpeedVal) * tremSpeedVariation1) +
	(tremVar2Mix * ~specLS.dlTremSpeed.map(tremSpeedVal) * tremSpeedVariation2) +
	(tremVar0Mix * ~specLS.dlTremSpeed.map(tremSpeedVal));
	// tremSpeedVal = ((1-tremSpeedVarOff) * ~specLS.dlTremSpeed.map(tremSpeedVal) * tremSpeedVariation1) +
	// (tremSpeedVarOff * ~specLS.dlTremSpeed.map(tremSpeedVal));
	sigTrem = sigPre * EnvGen.kr(
		Env.new([0,1,1,0,0],[0.05,1,0.05,0.7]*tremSpeedVal,[\sin,\lin,\sin,\lin]).circle
	);
	// sigTrem = (sigPre * tremSpeedVal * SinOsc.ar(1 / ~specLS.dlTremSpeed.map(tremSpeedVal)).range(0,1)) +
	// (sigPre * (1 - tremSpeedVal) * LFPulse.ar(1 / ~specLS.dlTremSpeed.map(tremSpeedVal)));

	// temporary for Spill
	// [decVal,mixDecVal,ampVal, mixCrossVal,probVal, mixDisVal, ~specLS.ff21.map(In.kr(ffBus,1))].poll;
	// sigTrem = Decimator.ar(sigTrem,rate: 7030, bits: 8);
	// sigTrem = (0.5 * sigTrem) + (0.5 * CrossoverDistortion.ar(sigTrem,amp: 0.025,smooth: 0.5));
	// sigTrem = RLPF.ar(sigTrem, 3314,0.5);

	sigOut = (mixDelayVal * [sigDelayL,sigDelayR]) + (mixDubVal * sigDubOut) + (mixTremVal * sigTrem);
	sigOut = sigOut * EnvGen.kr(Env.adsr(0,0,1,5), gate, doneAction: 2);
	Out.ar(~aBus.outMain, In.kr(volBus,1) * sigOut);
}).send(s);

SynthDef(\multiTapFreeze, 	{ // efx bank 2 fader 1
	// in case of fader and knob B1 on max, only freezebuffer is playing, and since this effect goes to mainOut,
	// there's no level control via outA or outB - control level by shortly taking down fader a bit
	arg gate, decayBus, volBus, onExternalInput = 0, inChan1 = 0, inChan2 = 1, ffBus, freezeBus, distBus;
	var sig, mixFreezeVal, mixTapVal, volVal;
	var sigT, decayBusVal, sigTL, sigTR, mixVal = 1, tapVal1, tapVal2, tapVal3, tapVal4, sweepVal; // tap delay
	var in, localL, localR, sigF, sigF1, sigF2, local, envLPF, envLPF2, hold, ffVal; // freeze
	var pulseLen, pulse, pulseTrig, freezeVal;
	var deltimes, sigPlate;

	// switch between input channels and sample playback
	in = (onExternalInput * In.ar([inChan1,inChan2])) +
	((1 - onExternalInput) * In.ar(~aBus.outEfxPost,2));  // get the signal post-fade
	mixFreezeVal = IEnvGen.kr(~specLS.mtfMixFreeze, In.kr(decayBus,1));
	mixTapVal = IEnvGen.kr(~specLS.mtfMixTap, In.kr(decayBus,1));
	volVal = IEnvGen.kr(~specLS.mtfVol, In.kr(volBus,1));

	// tap delay --------------------------------
	tapVal1 = IEnvGen.kr(~specLS.mtfTap1, In.kr(decayBus,1));
	tapVal2 = IEnvGen.kr(~specLS.mtfTap2, In.kr(decayBus,1));
	tapVal3 = IEnvGen.kr(~specLS.mtfTap3, In.kr(decayBus,1));
	tapVal4 = IEnvGen.kr(~specLS.mtfTap4, In.kr(decayBus,1));

	sigT = in;
	sigTL =
	(tapVal4*MultiTap.ar([0.1, 0.15, 0.7], [1,0.7,0.3], sigT[0], bufnum: ~mtfBufLLS)) +
	(tapVal3*MultiTap.ar([0.2, 0.28, 0.6, 1.4], [1,0.8,0.9,0.7], sigT[0], bufnum: ~mtfBufLLS)) +
	(tapVal2*MultiTap.ar([0.3, 0.43, 1, 1.9], [1,0.7,0.8, 0.3], sigT[0], bufnum: ~mtfBufLLS)) +
	(tapVal1*MultiTap.ar([0.4, 0.7, 0.8, 1, 2], [1,0.7,1, 0.9, 0.6], sigT[0], bufnum: ~mtfBufLLS));
	sigTR =
	(tapVal4*MultiTap.ar([0.09, 0.21, 0.8], [0.9,0.8,0.4], sigT[1], bufnum: ~mtfBufRLS)) +
	(tapVal3*MultiTap.ar([0.22, 0.4, 0.5, 1], [0.9,0.8,1, 0.4], sigT[1], bufnum: ~mtfBufRLS)) +
	(tapVal2*MultiTap.ar([0.29, 0.5, 0.7, 1.3], [0.9,0.8,1, 0.4], sigT[1], bufnum: ~mtfBufRLS)) +
	(tapVal1*MultiTap.ar([0.32, 0.65, 0.8, 1.2, 2.1], [0.9,0.8,0.9,1,0.7], sigT[1], bufnum: ~mtfBufRLS));
	sigTL = Pan2.ar(sigTL, LFNoise1.ar(2));
	sigTR = Pan2.ar(sigTR, LFNoise1.ar(1.5));

	// Freeverb on MultiTap
	mixVal = IEnvGen.kr(~specLS.mtfMix, In.kr(decayBus,1));
	decayBusVal = IEnvGen.kr(~specLS.mtfDecay, In.kr(decayBus,1));
	sweepVal = IEnvGen.kr(~specLS.mtfSweep, In.kr(ffBus,1));
	// sigT = 0.5 * FreeVerb2.ar(sigTL, sigTR, mixVal, decayBusVal * LFNoise1.kr(0.5).range(0.8,1), 0.5);
	// mix room damping
	sigT = 0.5 * (
		( Greyhole.ar([sigTL, sigTR], 0.2, 0.5, 0.5 + (3 * decayBusVal * LFNoise1.kr(0.5).range(1 - sweepVal, 1)),
			feedback: 0.2) * mixVal )
		+ ( [sigTL, sigTR] * (1 - mixVal) )
	);

	// freeze  --------------------------------
	hold = In.kr(volBus,1);
	ffVal = IEnvGen.kr(~specLS.mtfFF, In.kr(ffBus,1));
	freezeVal = In.kr(freezeBus,1);

	// feedback
	local = LocalIn.ar(2);

	// freeze
	localL = (max(hold,0.1) * local[0]) + (in[0] * (1 - hold)); // switch input feedback loop between in and local
	localR = (max(hold,0.1) * local[1]) + (in[1] * (1 - hold));
	20.do{
		localL = AllpassC.ar(localL,0.05,Rand(0.001,0.05),Rand(1,3));
		localR = AllpassC.ar(localR,0.05,Rand(0.001,0.05),Rand(1,3));
	};

	// feedback
	LocalOut.ar([localL*hold,localR*hold]);

	// set LPF filter
	envLPF = LFNoise1.ar(0.5).range(500,ffVal);
	//	envLPF = SinOsc.ar(SinOsc.ar(0.1).range(0.05,0.2)).range(500,ffVal);
	envLPF2 = LFNoise1.ar(0.2).range(300,1000);

	// percussive pulse for freeze2
	pulseLen = SinOsc.ar(0.02).range(1.1,1.25);
	pulseTrig = Impulse.ar(pulseLen);
	pulse = EnvGen.ar(Env.linen(0.02,0,pulseLen-0.1,1,\lin).range(0.2,1), gate: pulseTrig, doneAction: 0);

	// sig processing to send out
	sigF = [localL,localR];
	sigF1 = LPF.ar(sigF, envLPF);
	sigF2 = sigF * pulse * SinOsc.ar(0.1).range(0.7,1.5); // add short term and long term pulse
	sigF2 = LPF.ar(sigF2, envLPF2);
	sigF = ((freezeVal * sigF1) + (2 * (1-freezeVal) * sigF2)) * EnvGen.kr(Env.adsr(0.01,0,1,5), gate, doneAction: 2);
	sigF = HPF.ar(sigF, 50);
	sigF = ~specLS.dist21.map(In.kr(distBus,1)) * sigF;

	// combine tap & freeze --------------------------------
	sig = (sigF * mixFreezeVal) + (sigT * mixTapVal);
	sig = sig * EnvGen.kr(Env.adsr(0,0,1,0), gate, doneAction: 2);
	Out.ar(~aBus.outMain, volVal * sig);
}).send(s);

SynthDef(\ampPitchFollow, {// efx bank 2 fader 2
	arg gate, volBus, mixBus, onExternalInput = 0, inChan1 = 0, inChan2 = 1;
	var in, sig, sigL, sigR, volVal, mixVal;
	var sigNoise, sigNoiseL, sigNoiseR, ratioL, ratioR, mixValNoise;
	var sigPitch, sigPitchL, sigPitchR, freqL, hasFreqL, ampL, freqR, hasFreqR, ampR, mixValPitch;
	var sigS, sigSlap, decayVal = 0.9, mixValSchr, delrd, deltimes, slapBuf = LocalBuf(~sRate*0.2,2).clear;

	volVal = In.kr(volBus,1);
	mixVal = In.kr(mixBus,1);
	mixValNoise = IEnvGen.kr(~specLS.apfMixNoise, mixVal);
	mixValPitch = IEnvGen.kr(~specLS.apfMixPitch, mixVal);
	mixValSchr = IEnvGen.kr(~specLS.apfMixSchr, mixVal);

	in = (onExternalInput * In.ar([inChan1,inChan2])) +
	((1 - onExternalInput) * In.ar(~aBus.outEfxPost,2));  // get the signal post-fade
	sigL = in[0]; sigR = in[1];

	// amplitude following
	ratioL = SinOsc.ar(0.15).range(0.5,1);
	ratioR = SinOsc.ar(0.1).range(0.5,1);
	sigNoiseL = ((ratioL * WhiteNoise.ar()) + ((1 - ratioL) * 3 * BrownNoise.ar())) * Amplitude.ar(sigL, 0.01, 0.01);
	sigNoiseL = Gate.ar(sigNoiseL, Amplitude.kr(sigL, 0.01, 0.01, add: -0.001));
	sigNoiseR = ((ratioR * WhiteNoise.ar()) + ((1 - ratioR) * 3 * BrownNoise.ar())) * Amplitude.ar(sigR, 0.01, 0.01);
	sigNoiseR = Gate.ar(sigNoiseR, Amplitude.kr(sigR, 0.01, 0.01, add: -0.001));
	sigNoise = RHPF.ar([sigNoiseL, sigNoiseR], IEnvGen.kr(~specLS.mtfRLPFff, mixVal), 0.5,
		IEnvGen.kr(~specLS.mftRLPFmul, mixVal));

	// pitch following
	ampL = thresh(Amplitude.kr(sigL, 0.05, 0.05), 0.01);
	# freqL, hasFreqL = Pitch.kr(sigL, ampThreshold: 0.05, median: 7, initFreq: 1000);
	ampR = thresh(Amplitude.kr(sigR, 0.05, 0.05), 0.01);
	# freqR, hasFreqR = Pitch.kr(sigR, ampThreshold: 0.05, median: 7, initFreq: 1000);
	sigPitchL = Mix.new(SinOsc.ar(freqL * [10,12,13,15,17] * LFNoise1.ar(5).range(0.8,1), mul: ampL));
	sigPitchR = Mix.new(SinOsc.ar(freqR * [9,10,11,12,14,16] * LFNoise1.ar(4).range(0.9,1.1), mul: ampR));
	sigPitch = [sigPitchL, sigPitchR];

	// Schroeder reverb
	delrd = LocalIn.ar(4);
	sigS = in + delrd[[0,1]];
	sigS = [sigS[0]+sigS[1], sigS[0]-sigS[1], delrd[2]+delrd[3], delrd[2]-delrd[3]];
	sigS = [sigS[0]+sigS[2], sigS[1]+sigS[3], sigS[0]-sigS[2], sigS[1]-sigS[3]];
	sigS = sigS * [0.4, 0.37, 0.333, 0.3] * decayVal;
	deltimes =  [101, 143, 165, 177] * 0.001 - ControlDur.ir;
	sigS = DelayC.ar(sigS, deltimes, deltimes);
	LocalOut.ar(sigS);
	sigSlap = MultiTap.ar( [0.1], [0.5], in, bufnum: slapBuf );
	sigS = [Mix.ar(sigS),Mix.ar(sigSlap)];

	sig = (sigNoise * mixValNoise) + (sigPitch * mixValPitch) + (sigS * mixValSchr);
	sig = sig * EnvGen.kr(Env.adsr(0,0,1,0), gate, doneAction: 2);
	Out.ar(~aBus.outMain, volVal * sig);
}).send(s);
)