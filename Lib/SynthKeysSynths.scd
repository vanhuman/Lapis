(
//////////////// synths ////////////////////////////////

SynthDef.new(\bocAmpMod, {
	arg freq1, gate, cutoffBus, efxBus, pitchBus, velocity, distBus, synthGainBus;
	var sig, ampmodVal, velocityVal, cutoffVal, resVal, pitchVal, distVal;

	velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
	ampmodVal = IEnvGen.kr(~synthKeysSpec.ampmod1, velocity);
	cutoffVal = IEnvGen.kr(~synthKeysSpec.cutoff1, In.kr(cutoffBus,1));
	resVal = IEnvGen.kr(~synthKeysSpec.res, In.kr(efxBus,1));
	pitchVal = IEnvGen.kr(~synthKeysSpec.pitch, In.kr(pitchBus,1));
	distVal = IEnvGen.kr(~synthKeysSpec.dist1, In.kr(distBus,1));

	freq1 = freq1 * pitchVal;
	sig = RLPF.ar(
		Saw.ar(SinOsc.ar(2)*1.01 + (freq1 + (8.midicps(~tuningA)/128))) *
		Saw.ar(SinOsc.ar(2)*1.03 + (freq1 + (5.midicps(~tuningA)/128))) *
		Saw.ar(SinOsc.ar(2) + (freq1 - (3.midicps(~tuningA)/128))),
		cutoffVal, resVal);
	sig = RLPF.ar(sig, cutoffVal, resVal);
	// sig = Pan2.ar(sig,Rand(-0.5,0.5));
	sig = Pan2.ar(sig,LFNoise1.ar(1).range(-0.8,0.8));
	sig = sig * LFNoise1.ar(ampmodVal).range(0.5,1); // amplitude modulation
	sig = sig * distVal * velocityVal * EnvGen.kr(Env.adsr(0.1,0.1,0.5,1.0,2), gate, doneAction: 2);
	sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));

	Out.ar(~aBus.outBL, sig);
}).send(s);

SynthDef.new(\bocAmpMod2, { // similar to bocAmpMod but without the second RLPF and amplitude modulation
	arg freq1, gate, cutoffBus, efxBus, pitchBus, velocity, distBus, synthGainBus;
	var sig, cutoffVal, resVal, pitchVal, distVal, velocityVal;

	velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
	cutoffVal = IEnvGen.kr(~synthKeysSpec.cutoff1, In.kr(cutoffBus,1));
	resVal = IEnvGen.kr(~synthKeysSpec.res, In.kr(efxBus,1));
	pitchVal = IEnvGen.kr(~synthKeysSpec.pitch, In.kr(pitchBus,1));
	distVal = IEnvGen.kr(~synthKeysSpec.dist6, In.kr(distBus,1));

	freq1 = freq1 * pitchVal;
	sig = RLPF.ar(
		SinOsc.ar(SinOsc.ar(2)*1.01 + (freq1 + (8.midicps(~tuningA)/128))) *
		SinOsc.ar(SinOsc.ar(2)*1.03 + (freq1 + (5.midicps(~tuningA)/128))) *
		SinOsc.ar(SinOsc.ar(2) + (freq1 - (3.midicps(~tuningA)/128))),
		cutoffVal, resVal);
	sig = Pan2.ar(sig,Rand(-0.5,0.5));
	sig = sig * distVal * velocityVal * EnvGen.kr(Env.adsr(0.1,0,1,0.5), gate, doneAction: 2);
	sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));

	Out.ar(~aBus.outBL, sig);
}).send(s);

SynthDef.new(\bocAmpMod2b, { // similar to bocAmpMod but without the second RLPF and amplitude modulation
	arg freq1, gate, cutoffBus, efxBus, pitchBus, velocity, distBus, synthGainBus;
	var sig, cutoffVal, resVal, pitchVal, distVal, velocityVal;

	velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
	cutoffVal = IEnvGen.kr(~synthKeysSpec.cutoff1, In.kr(cutoffBus,1));
	resVal = IEnvGen.kr(~synthKeysSpec.res, In.kr(efxBus,1));
	pitchVal = IEnvGen.kr(~synthKeysSpec.pitch, In.kr(pitchBus,1));
	distVal = IEnvGen.kr(~synthKeysSpec.dist6, In.kr(distBus,1));

	freq1 = freq1 * pitchVal;
	sig = RLPF.ar(
		LFTri.ar(SinOsc.ar(2)*1.01 + (freq1 + (8.midicps(~tuningA)/128))) *
		LFTri.ar(SinOsc.ar(2)*1.03 + (freq1 + (5.midicps(~tuningA)/128))) *
		LFTri.ar(SinOsc.ar(2) + (freq1 - (3.midicps(~tuningA)/128))),
		cutoffVal, resVal);
	sig = Pan2.ar(sig,Rand(-0.2,0.2));
	sig = sig * distVal * velocityVal * EnvGen.kr(Env.adsr(0.01,0.1,0.3,0.5,2), gate, doneAction: 2);
	sig = 2 * FreeVerb2.ar(sig[0],sig[1]);
	sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));

	Out.ar(~aBus.outBL, sig);
}).send(s);

SynthDef.new(\bocAmpMod3, { // similar to bocAmpMod but without amplitude modulation and a bigger flutter
	arg freq1, gate, cutoffBus, efxBus, pitchBus, velocity, distBus, synthGainBus;
	var sig, ampmodVal, velocityVal, cutoffVal, resVal, pitchVal, distVal;

	velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
	ampmodVal = IEnvGen.kr(~synthKeysSpec.ampmod1, velocity);
	cutoffVal = IEnvGen.kr(~synthKeysSpec.cutoff5, In.kr(cutoffBus,1));
	resVal = IEnvGen.kr(~synthKeysSpec.res, In.kr(efxBus,1));
	pitchVal = IEnvGen.kr(~synthKeysSpec.pitch, In.kr(pitchBus,1));
	distVal = IEnvGen.kr(~synthKeysSpec.dist1, In.kr(distBus,1));

	freq1 = freq1 * pitchVal;
	sig = RLPF.ar(
		Saw.ar(SinOsc.ar(3)*3.01 + (freq1 + (8.midicps(~tuningA)/128))) *
		Saw.ar(SinOsc.ar(3)*3.03 + (freq1 + (5.midicps(~tuningA)/128))) *
		Saw.ar(SinOsc.ar(3)*3 + (freq1 - (3.midicps(~tuningA)/128))),
		cutoffVal, resVal);
	sig = RLPF.ar(sig, cutoffVal, resVal);
	// sig = Pan2.ar(sig,Rand(-0.5,0.5));
	sig = Pan2.ar(sig,LFNoise1.ar(1).range(-0.8,0.8));
	// sig = sig * LFNoise1.ar(ampmodVal).range(0.5,1); // amplitude modulation
	sig = sig * distVal * velocityVal * EnvGen.kr(Env.adsr(0.1,0,1,1.0), gate, doneAction: 2);
	sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));

	Out.ar(~aBus.outBL, sig);
}).send(s);

SynthDef.new(\bocAmpMod4, {
	arg freq1, gate, cutoffBus, efxBus, pitchBus, velocity, distBus, synthGainBus;
	var sig, ampmodVal, velocityVal, cutoffVal, resVal, pitchVal, distVal, flutterVal, flutterSpeed = 60/100/4, flutterMax;

	velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
	ampmodVal = IEnvGen.kr(~synthKeysSpec.ampmod1, velocity);
	cutoffVal = IEnvGen.kr(~synthKeysSpec.cutoff1, In.kr(cutoffBus,1));
	resVal = IEnvGen.kr(~synthKeysSpec.res, In.kr(efxBus,1));
	// pitchVal = IEnvGen.kr(~synthKeysSpec.pitch, In.kr(pitchBus,1));
	flutterVal = IEnvGen.kr(~synthKeysSpec.flutterBOC, In.kr(pitchBus,1));
	distVal = IEnvGen.kr(~synthKeysSpec.dist1, In.kr(distBus,1));
	flutterMax = Rand(0.2,2);
	flutterSpeed = flutterSpeed * Rand(0.96,1.05);

	// freq1 = freq1 * pitchVal;
	sig = RLPF.ar(
		Saw.ar(SinOsc.ar(2)*1.01 + (freq1 + (8.midicps(~tuningA)/128))) *
		Saw.ar(SinOsc.ar(2)*1.03 + (freq1 + (5.midicps(~tuningA)/128))) *
		Saw.ar(SinOsc.ar(2) + (freq1 - (3.midicps(~tuningA)/128))),
		cutoffVal, resVal);
	sig = RLPF.ar(sig, cutoffVal, resVal);
	sig = Pan2.ar(sig,LFNoise1.ar(1).range(-0.8,0.8));
	sig = sig * LFNoise1.ar(ampmodVal).range(0.5,1); // amplitude modulation

	sig = ( (1 - flutterVal) * sig ) +
	( flutterVal * sig * LFPulse.kr(1/flutterSpeed).range(0,flutterMax) );

	sig = sig * distVal * velocityVal * EnvGen.kr(Env.adsr(0.1,0.1,0.5,1.0,2), gate, doneAction: 2);
	sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));

	Out.ar(~aBus.outBL, sig);
}).send(s);

SynthDef.new(
	\SinAmpMod, {
		arg freq1, gate, cutoffBus, efxBus, pitchBus, velocity, distBus, synthGainBus;
		var sig, ampmodVal, velocityVal, cutoffVal, pitchVal, distVal, envRelVal;

		velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
		ampmodVal = IEnvGen.kr(~synthKeysSpec.ampmod2, In.kr(efxBus,1));
		cutoffVal = IEnvGen.kr(~synthKeysSpec.cutoff3, In.kr(cutoffBus,1));
		envRelVal = IEnvGen.kr(~synthKeysSpec.envRel, In.kr(cutoffBus,1));
		pitchVal = IEnvGen.kr(~synthKeysSpec.pitch, In.kr(pitchBus,1));
		distVal = IEnvGen.kr(~synthKeysSpec.dist5, In.kr(distBus,1));

		freq1 = freq1 * pitchVal;
		freq1 = freq1/2; // lower one octave

		sig = RLPF.ar( RLPF.ar(
			Saw.ar(SinOsc.ar(2)*1.01 + (freq1 + (8.midicps(~tuningA)/128))) *
			Saw.ar(SinOsc.ar(2)*1.03 + (freq1 + (5.midicps(~tuningA)/128))) *
			Saw.ar(SinOsc.ar(2) + (freq1 - (3.midicps(~tuningA)/128))),
			cutoffVal,1), cutoffVal,1) +
		SinOsc.ar(freq1);
		sig = sig * LFNoise0.ar(ampmodVal).range(0,1); // amplitude modulation
		sig = Pan2.ar(sig,LFNoise0.ar(ampmodVal*0.2).range(-1,1));
		sig = sig * distVal * velocityVal * EnvGen.kr(Env.adsr(0.05,0,1,envRelVal), gate, doneAction: 2);
		sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));

		Out.ar(~aBus.outBL, sig);
}).send(s);

SynthDef.new(
	\SinAmpMod2, { // similar to SinAmpMod but without amplitude modulation
		arg freq1, gate, cutoffBus, efxBus, pitchBus, velocity, distBus, synthGainBus;
		var sig, ampmodVal, velocityVal, cutoffVal, pitchVal, distVal, envRelVal;

		velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
		ampmodVal = IEnvGen.kr(~synthKeysSpec.ampmod2, In.kr(efxBus,1));
		cutoffVal = IEnvGen.kr(~synthKeysSpec.cutoff3, In.kr(cutoffBus,1));
		envRelVal = IEnvGen.kr(~synthKeysSpec.envRel2, In.kr(cutoffBus,1));
		pitchVal = IEnvGen.kr(~synthKeysSpec.pitch, In.kr(pitchBus,1));
		distVal = IEnvGen.kr(~synthKeysSpec.dist5, In.kr(distBus,1));

		freq1 = freq1 * pitchVal;
		freq1 = freq1/2; // lower one octave
		freq1 = [freq1,freq1/2];

		sig = RLPF.ar( RLPF.ar(
			Saw.ar(SinOsc.ar(2)*1.01 + (freq1 + (8.midicps(~tuningA)/128))) *
			Saw.ar(SinOsc.ar(2)*1.03 + (freq1 + (5.midicps(~tuningA)/128))) *
			Saw.ar(SinOsc.ar(2) + (freq1 - (3.midicps(~tuningA)/128))),
			cutoffVal,1), cutoffVal,1) +
		(SinOsc.ar(freq1)*(48.midicps(~tuningA)/freq1));

		sig = Mix.ar([sig[0],sig[1]]);
		sig = Pan2.ar(sig,LFNoise1.ar(ampmodVal*0.2).range(-1,1));
		sig = sig * distVal * velocityVal * EnvGen.kr(Env.adsr(0.05,0,1,envRelVal), gate, doneAction: 2);
		sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));

		Out.ar(~aBus.outBL, sig);
}).send(s);

SynthDef.new(
	\SinAmpMod3, { // similar to SinAmpMod2 but without filterfreq modulation
		arg freq1, gate, cutoffBus, efxBus, pitchBus, velocity, distBus, synthGainBus;
		var sig, ampmodVal, velocityVal, cutoffVal, pitchDevVal, distVal, envRelVal, resVal, dustMixVal, pitchSpeedVal, dust1, dust2, octMixVal;

		velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
		ampmodVal = IEnvGen.kr(~synthKeysSpec.ampmod2, In.kr(efxBus,1));
		resVal = IEnvGen.kr(~synthKeysSpec.res2, In.kr(efxBus,1));
		cutoffVal = IEnvGen.kr(~synthKeysSpec.cutoff3, In.kr(cutoffBus,1));
		envRelVal = IEnvGen.kr(~synthKeysSpec.envRel2, In.kr(cutoffBus,1));
		dustMixVal = IEnvGen.kr(~synthKeysSpec.dustMix, In.kr(cutoffBus,1));
		// pitchVal = IEnvGen.kr(~synthKeysSpec.pitch, In.kr(pitchBus,1));
		pitchDevVal = IEnvGen.kr(~synthKeysSpec.pitchDev, In.kr(pitchBus,1));
		pitchSpeedVal = IEnvGen.kr(~synthKeysSpec.pitchSpeed, In.kr(pitchBus,1));
		distVal = IEnvGen.kr(~synthKeysSpec.dist5, In.kr(distBus,1));
		octMixVal = 1 - In.kr(distBus,1);

		// freq1 = freq1 * pitchVal;
		freq1 = freq1/2; // lower one octave
		// freq1.poll(0.01);
		freq1 = [freq1,freq1/2];
		// freq1 = Select.kr( (freq1.cpsmidi>54) * (freq1.cpsmidi<60), [ freq1, freq1/2 ]);

		sig = RLPF.ar( RLPF.ar(
			Saw.ar(SinOsc.ar(2)*1.01 + (freq1 + (8.midicps(~tuningA)/128))) *
			Saw.ar(SinOsc.ar(2)*1.03 + (freq1 + (5.midicps(~tuningA)/128))) *
			Saw.ar(SinOsc.ar(2) + (freq1 - (3.midicps(~tuningA)/128))),
			Line.kr(50,10000,1),1), Line.kr(50,10000,1), resVal) +
		(SinOsc.ar(freq1, mul:0.3)*(48.midicps(~tuningA)/freq1));
		sig = sig * SinOsc.kr(pitchSpeedVal, mul: pitchDevVal, add: 1);
		sig = Mix.ar([sig[0],octMixVal*sig[1]]);
		sig = Pan2.ar(sig,LFNoise1.ar(ampmodVal*0.2).range(-1,1));
		dust1 = FreeVerb.ar( RHPF.ar(Dust2.ar(20,dustMixVal), freq1*16, 0.01), 0.5, 1 );
		dust2 = FreeVerb.ar( RHPF.ar(Dust2.ar(40,dustMixVal), freq1*32, 0.01), 0.5, 1 );
		sig = sig + [ XLine.kr(0.01,1,1) * dust1, XLine.kr(0.01,2,1.5) * dust2 ];
		sig = sig * distVal * velocityVal * EnvGen.kr(Env.adsr(0.05,0,1,envRelVal), gate, doneAction: 2);
		sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));

		Out.ar(~aBus.outBL, sig);
}).send(s);

SynthDef.new(
	\bocReverb, {
		arg freq1, gate, cutoffBus, efxBus, pitchBus, velocity, distBus, synthGainBus;
		var sig, cutoffVal, resVal, pitchVal, distVal, velocityVal;

		//	~synthKeysSpec.dist3 = Env.new([1.3,0.26],[1],[\exp]); // for GVerb
		velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
		cutoffVal = IEnvGen.kr(~synthKeysSpec.cutoff1, In.kr(cutoffBus,1));
		resVal = IEnvGen.kr(~synthKeysSpec.res, In.kr(efxBus,1));
		pitchVal = IEnvGen.kr(~synthKeysSpec.pitch, In.kr(pitchBus,1));
		distVal = IEnvGen.kr(~synthKeysSpec.dist3, In.kr(distBus,1));

		freq1 = freq1 * pitchVal;

		sig = RLPF.ar(
			Saw.ar(SinOsc.ar(2)*1.01 + (freq1 + (8.midicps(~tuningA)/128))) *
			Saw.ar(SinOsc.ar(2)*1.03 + (freq1 + (5.midicps(~tuningA)/128))) *
			Saw.ar(SinOsc.ar(2) + (freq1 - (3.midicps(~tuningA)/128))),
			cutoffVal, resVal);
		sig = RLPF.ar(sig, cutoffVal, resVal);
		sig = Pan2.ar(sig,Rand(-0.5,0.5));
		//	sig = GVerb.ar(sig, 80, 4.85, 0.41, 0.19, 12, -3, -3, -3);
		sig = FreeVerb.ar(sig, 0.9, 1, 0.5);
		sig = sig * distVal * velocityVal * EnvGen.kr(Env.adsr(0.1,0,1,3), gate, doneAction: 2);
		sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));

		Out.ar(~aBus.outBL, sig);
}).send(s);

SynthDef.new(
	\moogSynth,
	{
		arg freq1, gate, cutoffBus, efxBus, pitchBus, velocity, distBus, synthGainBus;
		var sig, cutoffVal, bandwidthVal, pitchVal, distVal, velocityVal, freq2;

		velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
		cutoffVal = IEnvGen.kr(~synthKeysSpec.cutoff4, In.kr(cutoffBus,1));
		bandwidthVal = IEnvGen.kr(~synthKeysSpec.bandwidth, In.kr(efxBus,1));
		pitchVal = IEnvGen.kr(~synthKeysSpec.pitch2, In.kr(pitchBus,1));
		distVal = IEnvGen.kr(~synthKeysSpec.dist8, In.kr(distBus,1));

		freq1 = freq1/2; // octave lower
		freq2 = freq1;
		freq1 = freq1 * pitchVal; // only detune one of the freqs

		sig = BMoog.ar(
			LFSaw.ar([freq1 * 0.99, freq2 * 1.01], 0, 0.1) ! 2,
			SinOsc.kr(SinOsc.kr(0.1),1.5pi,1550,1800),
			bandwidthVal,
			0);	// filter mode - lowpass
		sig = Decimator.ar(sig,rate: 10000, bits: 8);
		sig = RLPF.ar(sig, cutoffVal,0.5);
		sig = sig * velocityVal * distVal * EnvGen.kr(Env.adsr(0.1,0.1,0.8,0.5), gate, doneAction: 2);
		sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));

		Out.ar(~aBus.outB, sig);
}).send(s);

SynthDef.new(\FilterBank, {
	arg freq1, gate, cutoffBus, efxBus, pitchBus, velocity, distBus, synthGainBus;
	var sig, filtfreqs, cutoffVal, wobbleVal, distVal, pitchVal;

	cutoffVal = IEnvGen.kr(~synthKeysSpec.cutoff2, In.kr(efxBus,1));
	wobbleVal = IEnvGen.kr(~synthKeysSpec.wobble, In.kr(cutoffBus,1));
	distVal = IEnvGen.kr(~synthKeysSpec.dist7, In.kr(distBus,1));
	pitchVal = IEnvGen.kr(~synthKeysSpec.pitch, In.kr(pitchBus,1));

	freq1 = freq1 * pitchVal;
	filtfreqs = freq1 * [0.3, 0.5, 1, 2.7565, 5.40392, 8.93295, 13.3443, 18.6379]
	* {LFNoise1.kr(Rand(0.5,100)).range(2-wobbleVal,wobbleVal)}.dup(8);
	sig = BPF.ar(Crackle.ar(1) * [3,3,1,1,1,1,1,1],filtfreqs, 1/80) ;
	sig = LPF.ar(sig,LFNoise1.kr(1).range(50,cutoffVal));
	sig = distVal * sig * EnvGen.kr(Env.adsr(0.1,0,1,0.2), gate, doneAction: 2);
	sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));

	Out.ar(~aBus.outB, Mix.ar([[sig[0],sig[1]],[sig[3],sig[2]],[sig[4],sig[5]],[sig[7],sig[6]]]));
}).send(s);

SynthDef.new(\FilterNoise, {
	arg freq1, gate, cutoffBus, efxBus, pitchBus, velocity, distBus, synthGainBus;
	var sig, filtfreqs, cutoffVal, distVal, mixVal, envRelVal, envAttVal, envSusVal, envPkVal, velocityVal;
	var rqVal, brfFreq = Array.newClear(2);

	velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
	cutoffVal = IEnvGen.kr(~synthKeysSpec.cutoffFN, In.kr(cutoffBus,1));
	distVal = IEnvGen.kr(~synthKeysSpec.dist7, In.kr(distBus,1));
	mixVal = In.kr(pitchBus,1);
	envRelVal = IEnvGen.kr(~synthKeysSpec.envRel3, In.kr(efxBus,1));
	envAttVal = IEnvGen.kr(~synthKeysSpec.envAtt3, In.kr(efxBus,1));
	envSusVal = IEnvGen.kr(~synthKeysSpec.envSus3, In.kr(efxBus,1));
	envPkVal = IEnvGen.kr(~synthKeysSpec.envPk3, In.kr(efxBus,1));
	// freq1 = freq1/4;
	freq1 = max(freq1,10);
	rqVal = { LFNoise1.kr(0.3).range(0.1,0.5) }!2;  // rqVal = bandwidth / freq
	// brfFreq = { ( { (Rand(0.2,40) * freq1)%20000 }!6 ) ++ ( { (Rand(40,200) * freq1)%20000 }!4 ) }!2;
	// brfFreq.poll(0.01);
	// [envAttVal,0.1,envSusVal,envRelVal,envPkVal].poll(0.01);

	sig = BPF.ar(WhiteNoise.ar(0.1), [freq1,freq1*0.9], rqVal, mul: (72 / (freq1.cpsmidi)) * (0.1/rqVal) ) ;
	// brfFreq[0].size.do { |i|
	// 	sig[0] = BRF.ar(sig[0], brfFreq[0][i], LFNoise1.kr( LFNoise0.kr(0.3).range(0.1,0.4) ).range(0.05,0.9));
	// 	sig[1] = BRF.ar(sig[1], brfFreq[1][i], LFNoise1.kr( LFNoise0.kr(0.2).range(0.1,0.4) ).range(0.05,0.9));
	// };
	sig[0] = LPF.ar(sig[0], LFNoise1.kr(0.1).range(100,cutoffVal));
	sig[1] = LPF.ar(sig[1], LFNoise1.kr(0.12).range(100,cutoffVal));
	sig = ( (1-mixVal) * sig ) + ( mixVal * PitchShift.ar(sig, windowSize: 0.1, pitchRatio: 0.5, mul:2) );

	sig = velocityVal * distVal * sig * EnvGen.kr(Env.adsr(envAttVal,0.1,envSusVal,envRelVal,envPkVal), gate, doneAction: 2);
	sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));

	Out.ar(~aBus.outB, sig);
}).send(s);

SynthDef.new(\Prime, {
	arg freq1, gate, cutoffBus, efxBus, pitchBus, velocity, distBus, prevFreq, synthGainBus;
	var sig, sig2, detune, amps, freqs = List.new(), freqs2, glideVal = 0.4, distVal, velocityVal;

	velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
	glideVal = IEnvGen.kr(~synthKeysSpec.glide, In.kr(efxBus,1));
	distVal = IEnvGen.kr(~synthKeysSpec.dist2, In.kr(distBus,1));
	freq1 = XLine.kr(prevFreq,freq1, glideVal); // glide - 0.8 for Portishead theremin effect, possibly control by joystick? range 0.1-0.4-0.8
	freq1 = freq1 * 4;

	amps = Array.fill(20, {arg i; 1  / ( i+1)});
	detune = Array.fill(20, { LFNoise2.kr(1, 0.01 ,1) });
	20.do { |i| freqs.add(1/i.nthPrime*100) };
	freqs = freqs.reverse.asArray;
	// freqs2 = 20.fib(1,1); freqs2 = 1/freqs2*100;
	// freqs2 = freqs2.reverse.asArray;

	sig = Splay.ar(SinOsc.ar( (freq1 + freqs - freqs[0]) * detune, mul: amps).tanh.scramble);
	// sig2 = Splay.ar(SinOsc.ar( (freq1 + freqs2 - freqs2[0]) * detune, mul: amps).tanh.scramble);
	// sig = sig + sig2;
	sig = SinOsc.kr(4.5) * sig;
	sig = velocityVal * distVal * sig * EnvGen.kr(Env.asr(), gate, doneAction: 2);
	sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));

	Out.ar(~aBus.outB, sig);
}).send(s);

SynthDef.new(
	\SampleKeys, {
		arg freq1, gate, cutoffBus, efxBus, velocity, pitchBus, distBus, synthGainBus, buffer = ~bufferSK;
		var sig, cutoffVal, lenVal, pitchVal, distVal, trig, freq1hz, flutterVal, velocityVal, flutSpdVal;

		velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
		cutoffVal = IEnvGen.kr(~synthKeysSpec.cutoff3, In.kr(cutoffBus,1));
		flutterVal = IEnvGen.kr(~synthKeysSpec.flutter, In.kr(cutoffBus,1));
		lenVal = IEnvGen.kr(~synthKeysSpec.len, In.kr(efxBus,1));
		flutSpdVal = IEnvGen.kr(~synthKeysSpec.flutspd, In.kr(efxBus,1));
		pitchVal = IEnvGen.kr(~synthKeysSpec.pitch, In.kr(pitchBus,1));
		distVal = IEnvGen.kr(~synthKeysSpec.dist4, In.kr(distBus,1));

		freq1 = (freq1 / 60.midicps(~tuningA)) * pitchVal;
		freq1hz = freq1 * 60.midicps(~tuningA);

		trig = Impulse.ar(1 / (lenVal / (~sRate * (freq1hz/60.midicps(~tuningA))) ));
		sig = PlayBufCF.ar(
			2,
			buffer,
			BufRateScale.kr(buffer) * freq1 *
			SinOsc.ar(LFNoise1.ar(1).range(0.5+flutSpdVal,1.2+flutSpdVal)).range(1,flutterVal),
			trig,
			0,
			1
		) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
		sig = sig * distVal * velocityVal;
		sig = RLPF.ar(sig, cutoffVal, 0.5);
		sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));

		Out.ar(~aBus.outBL, sig);
}).send(s);

SynthDef.new(
	\SampleKeysNoPitch, {
		arg freq1, gate, cutoffBus, efxBus, velocity, pitchBus, distBus, synthGainBus, buffer = ~bufferSK;
		var sig, cutoffVal, lenVal, pitchVal, distVal, trig, freq1hz, flutterVal, velocityVal, flutSpdVal;

		velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
		cutoffVal = IEnvGen.kr(~synthKeysSpec.cutoff3, In.kr(cutoffBus,1));
		flutterVal = IEnvGen.kr(~synthKeysSpec.flutter, In.kr(cutoffBus,1));
		lenVal = IEnvGen.kr(~synthKeysSpec.len, In.kr(efxBus,1));
		flutSpdVal = IEnvGen.kr(~synthKeysSpec.flutspd, In.kr(efxBus,1));
		pitchVal = IEnvGen.kr(~synthKeysSpec.pitch, In.kr(pitchBus,1));
		distVal = IEnvGen.kr(~synthKeysSpec.dist4, In.kr(distBus,1));

		sig = PlayBufCF.ar(2, buffer, BufRateScale.kr(buffer), 1, 0, 1) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
		sig = sig * distVal * velocityVal;
		sig = RLPF.ar(sig, cutoffVal, 0.5);
		sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));

		Out.ar(~aBus.outBL, sig);
}).send(s);

SynthDef.new(
	\bocAmpModSub, {
		arg freq1, gate, cutoffBus, efxBus, velocity, pitchBus, distBus, synthGainBus;
		var sig, ampmodVal, velocityVal, cutoffVal, resVal, pitchVal, distVal;

		velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
		ampmodVal = IEnvGen.kr(~synthKeysSpec.ampmod1, velocity);
		cutoffVal = IEnvGen.kr(~synthKeysSpec.cutoff1, In.kr(cutoffBus,1));
		resVal = IEnvGen.kr(~synthKeysSpec.res, In.kr(efxBus,1));
		pitchVal = IEnvGen.kr(~synthKeysSpec.pitch, In.kr(pitchBus,1));
		distVal = IEnvGen.kr(~synthKeysSpec.dist2, In.kr(distBus,1));

		freq1 = freq1 * pitchVal;

		sig = RLPF.ar(
			Saw.ar(SinOsc.ar(2)*1.01 + (freq1 + (8.midicps(~tuningA)/128))) *
			Saw.ar(SinOsc.ar(2)*1.03 + (freq1 + (5.midicps(~tuningA)/128))) *
			Saw.ar(SinOsc.ar(2) + (freq1 - (3.midicps(~tuningA)/128))),
			cutoffVal, resVal);
		sig = RLPF.ar(sig, cutoffVal, resVal);
		sig = 0.7*sig + 0.3*SinOsc.ar(freq1);
		sig = Pan2.ar(sig,Rand(-0.5,0.5));
		sig = sig * LFNoise1.ar(ampmodVal).range(0.5,1);
		sig = sig * distVal * EnvGen.kr(Env.adsr(0.1,0,1,2.0), gate, doneAction: 2);
		sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));

		Out.ar(~aBus.outBL, sig);
}).send(s);

SynthDef(\zoneRecSK, {
	arg chan1, chan2, buf, len, attenuation = 1;
	RecordBuf.ar(In.ar([chan1,chan2]), buf, loop: 0, recLevel: attenuation) *
	EnvGen.kr(Env.linen(0,len,0), doneAction: 2)
}).send(s);

SynthDef.new(\pitchShifter, {
	arg freq1, gate, cutoffBus, efxBus, velocity, pitchBus, distBus, inChan1 = 0, inChan2 = 0, synthGainBus;
	var in, sig, env, ampmodVal, velocityVal, timeDispVal, pitchDispVal, pitchVal, distVal, cutoffVal, amp, variableVibrato = 1, vibratoSpeed, vibratoDepth;

	in = In.ar([inChan1,inChan2]);

	velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
	vibratoDepth = IEnvGen.kr(~synthKeysSpec.vibDepth, In.kr(efxBus,1));
	timeDispVal = IEnvGen.kr(~synthKeysSpec.timeDisp, In.kr(efxBus,1));
	pitchDispVal = IEnvGen.kr(~synthKeysSpec.pitchDisp, In.kr(cutoffBus,1));
	pitchVal = IEnvGen.kr(~synthKeysSpec.pitch, In.kr(pitchBus,1));
	distVal = IEnvGen.kr(~synthKeysSpec.dist4, In.kr(distBus,1));
	cutoffVal = IEnvGen.kr(~synthKeysSpec.cutoff3, In.kr(cutoffBus,1));

	vibratoSpeed = ( (1-variableVibrato) * 10 ) + ( variableVibrato * LFNoise1.kr(2).range(5,25) ) * (Amplitude.kr(in).linexp(0,1,1,10));

	freq1 = (freq1 / 60.midicps(~tuningA)) * pitchVal * 2;
	env = EnvGen.kr(Env.asr(), gate, doneAction: 2);
	sig = PitchShift.ar(in, windowSize: 0.2, pitchRatio: freq1, pitchDispersion: pitchDispVal, timeDispersion: timeDispVal);
	sig = Vibrato.ar(sig, vibratoSpeed, vibratoDepth);
	sig = RLPF.ar(sig, cutoffVal, 0.5);

	Out.ar(~aBus.outBL, sig * env * distVal);
}).send(s);

SynthDef(\harmsWay, {
	arg gate, freq1, cutoffBus, efxBus, velocity, pitchBus, distBus, synthGainBus;
	var velocityVal, pitchVal, distVal, harmaVal, bandwidthVal;
	var num, spread, attack, harm, harma, detune, source, generator, sig, env;

	velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
	harmaVal = IEnvGen.kr(~synthKeysSpec.harmaHW, In.kr(cutoffBus,1));
	bandwidthVal = IEnvGen.kr(~synthKeysSpec.bandHW, In.kr(efxBus,1));
	pitchVal = IEnvGen.kr(~synthKeysSpec.pitchHW, In.kr(pitchBus,1));
	distVal = IEnvGen.kr(~synthKeysSpec.distHW, In.kr(distBus,1));
	freq1 = ( (freq1.cpsmidi) - 12).midicps;
	freq1 = (freq1.cpsmidi.linlin(0,65,0,65)).midicps; // upper limit midi note 65, above that it distorts

	num = 16; spread = Rand(0.4,0.8); attack = Rand(0.05, 0.3);
	harm = Array.geom(num, 1, 1.8);
	harma = Array.geom(num, 0.5, harmaVal);
	detune = Array.fill(num, { LFNoise2.kr(1, pitchVal ,1) });
	source = PinkNoise.ar;
	generator =
	( 0.3 * SinOsc.ar(freq1*harm*detune, mul:harma*0.3).scramble ) +
	( 0.6 * Resonz.ar(source, freq1*harm*detune, bandwidthVal, mul:harma).scramble * 50 );
	sig = Splay.ar(generator,spread);
	env = EnvGen.kr(Env.asr(attack,1,2), gate, doneAction:2);
	sig = sig + GVerb.ar(sig, 220, 12, mul:1);
	sig = (sig * 0.2) + GVerb.ar(sig, 220, 12, mul:0.6);
	// sig = (sig*0.2) + GVerb.ar(sig, 220, 12, mul:0.6);
	// sig = (sig*0.2) + GVerb.ar(sig, 220, 12, mul:0.6);
	// sig = Limiter.ar(LeakDC.ar(sig));
	sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));
	Out.ar(~aBus.outBL,sig * env * velocityVal * distVal);
}).add;

2.do { |count|
	SynthDef("darkHorns"++count, {
		arg freq1, gate, cutoffBus, efxBus, velocity, pitchBus, distBus, synthGainBus;
		var sig, local, env, feedback = 0.95;
		var velocityVal, pitchVal, distVal = 1, cutoffVal, efxVal, phaseMulVal = 3;

		velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
		cutoffVal = IEnvGen.kr(~synthKeysSpec.cutoffDH, In.kr(cutoffBus,1));
		efxVal = IEnvGen.kr( if(count==0, {~synthKeysSpec.efxDH0},{~synthKeysSpec.efxDH1}) , In.kr(efxBus,1)); // different mapping in darkHorns1 and 0
		pitchVal = IEnvGen.kr(~synthKeysSpec.pitch, In.kr(pitchBus,1));
		distVal = IEnvGen.kr(~synthKeysSpec.distHW, In.kr(distBus,1));
		if(count==1, {phaseMulVal = IEnvGen.kr(~synthKeysSpec.phaseMul, In.kr(distBus,1)) }); // only include in darkHorns1
		freq1 = freq1 * pitchVal;

		local = feedback * LocalIn.ar(2);
		sig = SinOsc.ar(
			freq1, // freq
			local * LFNoise1.ar(0.1,phaseMulVal), // phase
			LFNoise1.ar(3,6) // mul
		).tanh;

		9.do { |count|
			sig = Select.ar(efxVal>(count+1), [sig, AllpassL.ar( sig, 0.3, {Rand(0,0.2)+0.1}!2, 5)]);
		};
		// 9.do {
		// 	sig = AllpassL.ar( sig, 0.3, {Rand(0,0.2)+0.1}!2, 5);
		// };
		sig = sig.tanh;
		env = EnvGen.kr(Env.asr(releaseTime: 5), gate, doneAction:2);
		LocalOut.ar(sig);
		sig = RLPF.ar(sig, cutoffVal, 0.5);
		sig = sig * efxVal.linlin(1,11,0.4,1);
		sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));
		Out.ar(~aBus.outBL, 0.6 * sig * env * velocityVal * distVal);
	}).add;
};

SynthDef(\adcirc, {
	arg freq1, gate, cutoffBus, efxBus, velocity, pitchBus, distBus, synthGainBus;
	var sig1, sig2, sig, env, control1, control2, freq2;
	var velocityVal, distVal, cutoffVal, pitchVal, flutterVal, speedVal;

	velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
	cutoffVal = IEnvGen.kr(~synthKeysSpec.cutoffDH, In.kr(cutoffBus,1));
	flutterVal = IEnvGen.kr(~synthKeysSpec.flutterAC, In.kr(cutoffBus,1));
	pitchVal = IEnvGen.kr(~synthKeysSpec.pitchAC, In.kr(pitchBus,1));
	speedVal = IEnvGen.kr(~synthKeysSpec.speedAC, In.kr(efxBus,1));
	distVal = IEnvGen.kr(~synthKeysSpec.distHW, In.kr(distBus,1));

	freq2 = [freq1,freq1*1.002] * pitchVal;
	env = EnvGen.kr(Env.asr(0.5,1,1), gate, doneAction:2);

	control1 = LFNoise1.kr(4).range(0.5,1);
	sig1 =
	SinOscFB.ar( 1.01*SinOsc.ar(2/speedVal) + freq2, control1, 0.5) *
	SinOscFB.ar(1.02*SinOsc.ar(2/speedVal) + freq2, control1, 0.5) *
	SinOscFB.ar(SinOsc.ar(1.03/speedVal) + freq2, control1, 0.5);
	sig1 = RLPF.ar(sig1, LFNoise1.kr(3/speedVal).range(100,5000), LFNoise0.kr(5/speedVal).range(0.1, 0.9));

	control2 = LFNoise1.kr(5.5/speedVal).range(500,10000);
	sig2 =
	Saw.ar( 1.01*SinOsc.ar(2/speedVal) + freq2 ) *
	Saw.ar( 1.02*SinOsc.ar(2/speedVal) + freq2) *
	Saw.ar( SinOsc.ar(1.03/speedVal) + freq2);
	sig2 = RLPF.ar(sig2, control2);
	sig2 = RLPF.ar(sig2, control2);
	sig = Splay.ar(sig1 + sig2);
	sig = LPF.ar(sig, cutoffVal);
	sig = ( flutterVal * sig * SinOsc.kr(LFNoise1.kr(2).range(6,8)) ) + ( (1-flutterVal) * sig );
	sig = sig * IEnvGen.kr(~synthKeysSpec.synthGain, In.kr(synthGainBus,1));
	Out.ar(~aBus.outB, sig * env * velocityVal * distVal);
}).add;

SynthDef(\drumSetSynth, {
	arg freq1, gate, cutoffBus, efxBus, velocity, pitchBus, distBus, synthGainBus, drumFilterBus, drumVolBus;
	var sig, env, distVal, velocityVal, cutoffVal, resVal;
	var sigKick = Array.newClear(2), sigHihat, sigSnare, sigClap, kickFreqList, kickFreq, kickIndex;
	// variation: no env but doneAction in kick, then more cpu but nice overlaps

	distVal = IEnvGen.kr(~synthKeysSpec.drumVol, In.kr(drumVolBus,1));
	velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
	cutoffVal = IEnvGen.kr(~synthKeysSpec.drumFilter, In.kr(drumFilterBus,1));
	resVal = IEnvGen.kr(~synthKeysSpec.res3, In.kr(efxBus,1));
	env = EnvGen.kr(Env.adsr(0.01,0,1,0.2), gate, doneAction: 2);

	sigKick[0] = SinOsc.ar( XLine.kr(800,50,0.02) * LFNoise1.kr(30).range(0.97,1.03) );
	kickIndex = TWindex.kr(Impulse.kr(1), [0.5,0.2,0.2,0.1]);
	kickFreq = Select.kr(kickIndex,[900,200,50,2000]);
	sigKick[1] = LPF.ar(Ringz.ar(Impulse.ar(0), Rand(50,80), Rand(0.5,0.8)), kickFreq, mul:2);
	sigKick = sigKick * EnvGen.kr(Env.new([0,1,0],[0.01, 1]),gate);

	sigHihat = RHPF.ar( WhiteNoise.ar( XLine.kr(1,0.001,1) ), 12000*LFNoise1.kr(1).range(0.9,1.1), 0.1);

	sigSnare = BPF.ar(WhiteNoise.ar, ((EnvGen.kr(Env.new([0,1,0],[0.0002,0.3],[0,-5]))+1)*1000), 11)
		* EnvGen.kr(Env.new([0,1,0],[0.0002,0.3],[0,-5]));

	// sigClap = LFNoise1.ar(3).range(0,0.5) * WhiteNoise.ar(XLine.kr(1,0.01,1))
	// * Dust.kr(Line.kr(1000,2,1,doneAction:2)).range(0.005,1);

	freq1 = freq1.cpsmidi.linlin(40,80,0,4.5);
	sig = SelectXFocus.ar( freq1, [
		Pan2.ar(Select.ar(IRand(0,1),sigKick),Rand(-0.5,0.5)),
		Pan2.ar(Select.ar(IRand(0,1),sigKick),Rand(-0.5,0.5)),
		Pan2.ar(sigHihat,Rand(-1,-0.2)),
		Pan2.ar(sigSnare,Rand(-0.5,0.5)),
		// Pan2.ar(sigClap, Rand(0.2,1))
	], focus: 1);
	sig = RLPF.ar(sig, cutoffVal, resVal);
	sig = FreeVerb2.ar(sig[0],sig[1]);
	Out.ar(~aBus.outB, sig * velocityVal * distVal * env);
}).add;

~bufferDrumSK.size.do { |count|
	SynthDef("drumSetSample"++count, {
		arg freq1, gate, cutoffBus, efxBus, velocity, pitchBus, distBus, synthGainBus, drumFilterBus, drumVolBus;
		var sig, distVal, velocityVal, cutoffVal, resVal, env;
		var sigKick = Array.newClear(2), sigHihat = Array.newClear(2), sigSnare = Array.newClear(2), sigClap = Array.newClear(2);
		var drumBuf = Array.newClear(8);

		// if(count==0, {drumBuf = ~bufferDrumSK0}, {drumBuf = ~bufferDrumSK1});
		drumBuf = ~bufferDrumSK[count];
		distVal = IEnvGen.kr(~synthKeysSpec.drumVol, In.kr(drumVolBus,1));
		velocityVal = IEnvGen.kr(~synthKeysSpec.velocity, velocity);
		cutoffVal = IEnvGen.kr(~synthKeysSpec.drumFilter, In.kr(drumFilterBus,1));
		resVal = IEnvGen.kr(~synthKeysSpec.res3, In.kr(efxBus,1));

		2.do { |i|
			sigKick[i] = PlayBuf.ar(2, drumBuf[i], rate: XLine.kr(1,0.5,0.5) );
			sigHihat[i] = PlayBuf.ar(2, drumBuf[2+i], rate: Rand(0.9,1));
			sigSnare[i] = PlayBuf.ar(2, drumBuf[4+i], rate: Rand(0.85,0.9));
			sigClap[i] = PlayBuf.ar(2, drumBuf[6+i], rate: Rand(0.9,1.1));
		};

		freq1 = freq1.cpsmidi.linlin(40,80,0,4.5);
		sig = SelectXFocus.ar( freq1, [
			Pan2.ar(Select.ar(IRand(0,1),sigKick),Rand(-0.5,0.5)),
			Pan2.ar(Select.ar(IRand(0,1),sigKick),Rand(-0.5,0.5)),
			Pan2.ar(Select.ar(IRand(0,1),sigHihat),Rand(-1,-0.2)),
			Pan2.ar(Select.ar(IRand(0,1),sigSnare),Rand(-0.5,0.5)),
			Pan2.ar(Select.ar(IRand(0,1),sigClap), Rand(0.2,1)) * TWindex.kr(Impulse.kr(0), [0.7,0.3])
		], focus: 1);
		sig = RLPF.ar(sig, cutoffVal, resVal);
		sig = FreeVerb2.ar(sig[0],sig[1]);
		env = EnvGen.kr( Env.asr(0.01,1,0.5), gate, doneAction: 2);
		Out.ar(~aBus.outB, sig * velocityVal * distVal * env);
	}).add;
};

)