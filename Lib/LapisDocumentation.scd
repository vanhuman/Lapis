// TO DO:
// channel explanation 50-53, 80-81 etc
// joystick controls

~doc = (
	shortCuts: {
		"\nInOut keyboard shortcuts:".postln;
		"	esc stops sound output".postln;
		"	i posts project info".postln;
		"	n posts Node info".postln;
		"	m starts s.meter".postln;
		"	o toggles OSC monitor ON/OFF".postln;
		"	alt-r toggles recording ON/OFF".postln;
		"\nLiveSampler keyboard shortcuts:".postln;
		"	esc stops sound output".postln;
		"	L clears buffer".postln;
		"	a amplifies current zone".postln;
		"	s saves buffer to disk".postln;
		"	t loads ~testSampleList".postln;
		"	r refreshes bufferView".postln;
		"\nSynthKeys keyboard shortcuts:".postln;
		"	esc stops sound output".postln;
		"	s saves buffer to disk".postln;
		"\nControllers keyboard shortcuts:".postln;
		"	a toggles arduino data postln".postln;
		"	m toggles midi data postln".postln;
		"	x toggles joystick x data postln".postln;
		"	y toggles joystick y data postln".postln;
		"	r toggles joystick r data postln".postln;
		"	s toggles joystick s data postln".postln;
	}
);
if (~postInstrumentDetails) {
	~doc = ~doc ++ (
		generalConfig: {
			"\nThe general configuration is defined in GlobalVars.scd.".postln;
			"Inputs on the audio device are mapped to input busses 50 - 53 (fixed).".postln;
			"The main output is sent to input busses 80 and 81 for resampling (configurable in general config).".postln;
		},
		mainOutA: {
			"\nStart main output A".postln;
			"\tLV2KnobMasterVol: volume".postln;
		},
		mainOutB: {
			"\nStart main output B".postln;
			"\tArduino Analog 1: volume".postln;
		},
		mainOutBLimited: {
			"\nStart main output B Limited".postln;
			"	Arduino Analog 1: volume".postln;
		},
		zone2: {
			"\nStart Zone2: play 2 voices out of sync from buffer A".postln;
			"\t\tand 2 extra voices (low and high) if LVFader1 > 0.97".postln;
			"\tLV1Fader1: volume".postln;
			"\tLV1Fader2: start position".postln;
			"\tLV1KnobA1: length (range 60s)".postln;
			"\tLV1KnobA2: mix 3 voices; low only, all, high only".postln;
			"\tLV1CrossFader: distortion".postln;
			"\tLV1KnobMasterVol: LP filter frequency".postln;
			"\tLV1JoyX: scratch start position".postln;
			"\tLV1JoyY: pitch only one voice".postln;
			"\tLX2 RED7 keyset 2: on/off pitchshift control".postln;
		},
		efx1_1: {
			"\nStart efx deciMate".postln;
			"\tLV1Fader3: volume".postln;
			"\tLV1KnobB1: amount of decimation".postln;
			"\tLV1KnobB2: sample rate".postln;
			"\tLV1KnobB3: LP filter fequency".postln;
		},
		efx1_2: {
			"\nStart efx multiTap, reverb & freeze".postln;
			"\tLV1Fader3 & LX2 RED keyset2 ON: volume".postln;
			"\tLV1KnobB1: effect settings:".postln;
			"\t\tvalue 0-0.5: 4 multitap settings from long to short,".postln;
			"\t\tvalue 0.3-0.6: crossfade with greyhole reverb,".postln;
			"\t\tvalue >0.9: freeze, with hold when LV1Fader3 = 1".postln;
			"\tLV1KnobB2: filter frequency for greyhole and freeze".postln;
			"\tLV1KnobB3: for freeze: crossfade from pulse to freeze".postln;
		},
		efx2_1: {
			"\nStart efx tremolo, deLay & dub delay".postln;
			"\tLV1Fader4: volume".postln;
			"\tLV1KnobB1: delay time and effect settings:".postln;
			"\t\tvalue 0-0.25: tremolo,".postln;
			"\t\tvalue 0.25-0.7: delay,".postln;
			"\t\tvalue >0.7: dub delay".postln;
			"\tLV1KnobB2: tremolo speed (0 = random, 0-1 slow to fast)".postln;
			"\tLV1KnobB3: input level for delay".postln;
		},
		efx2_2: {
			"\nStart efx amplitude & pitch follower".postln;
			"\tLV1Fader4 & LX2 RED keyset2 ON: volume".postln;
			"\tLV1KnobB1: crossfade pitch to noise".postln;
		},
		zone3: {
			"\nStart Zone3: play one voice from buffer A".postln;
			"\t\twith sample pointer and amplitude modulation, ".postln;
			"\tLV1Fader5: volume".postln;
			"\tLV1Fader6: start position".postln;
			"\tLV1Fader7: sample pointer modulation speed".postln;
			"\tLV1Fader8: amplitude modulation speed".postln;
			"\tLV1KnobC1: length (range 60s)".postln;
			"\tLV1KnobC2: HP filter frequency".postln;
			"\tLV1KnobD1: pitch".postln;
			"\tLV1KnobD2: panning speed".postln;
			"\tLV1CrossFader: distortion".postln;
		},
		zone4: {
			"\nStart Zone4: play one voice from buffer A".postln;
			"\t\tforwards-backwards and LP filter modulated".postln;
			"\t\t and 2 extra voices if LV2Fader1 > 0.97".postln;
			"\tLV2Fader1: volume".postln;
			"\tLV2Fader2: start position".postln;
			"\tLV2KnobA1: length and reposition (range 60s)".postln;
			"\tLV2KnobA2: LP filter frequency modulation speed".postln;
			"\tLV2JoyX: LP max filter frequency".postln;
			"\tLV2JoyY: pitch".postln;
			"\tLV2CrossFader: distortion".postln;
		},
		zone8: {
			"\nStart Zone8: play one voice from buffer A with a dynamic pattern".postln;
			"\tLV2Fader3: volume".postln;
			"\tLV2Fader4: start position".postln;
			"\tLV2KnobB1: select pattern from 10 (patters in Data/Patterns.scd)".postln;
			"\tLV2KnobB2: length (range 60s)".postln;
			"\tLV2KnobB3: pitch if LV2KnobB1 > 0, otherwise playbackspeed".postln;
			"\tLV2CrossFader: distortion".postln;
		},
		zone16_1: {
			"\nStart Zone16-1: play one voice in irregular stuttering loop,".postln;
			"\t\tstuttering done within synthdef".postln;
			"\tLV2Fader5: volume".postln;
			"\tLV2KnobC1: panning".postln;
			"\tLV2KnobC2: LP filter frequency".postln;
			"\tLV2KnobC3: distortion".postln;
			"\tLX2 RED5: record source sample and set length with note off".postln;
		},
		zone16_2: {
			"\nStart Zone16-2: play one voice forwards-backwards,".postln;
			"\t\twith gliding pitch shifting".postln;
			"\tLV2Fader6: volume".postln;
			"\tLV2KnobD1: max pitch shift".postln;
			"\tLV2KnobD2: set curve from up-down, up, down, lisa, random".postln;
			"\tLV2KnobD3: distortion".postln;
			"\tLX2 RED6: record source sample and set length with note off".postln;
			"\tLX2 RED6 keyset 2: switch to backwards only".postln;
		},
		zone16_3: {
			"\nStart Zone16-3: play one voice forwards-backwards,".postln;
			"\t\twith gliding pitch shifting".postln;
			"\tLV2Fader7: volume".postln;
			"\tLV2KnobD1: max pitch shift".postln;
			"\tLV2KnobD2: set curve from up-down, up, down, lisa, random".postln;
			"\tLV2KnobD3: distortion".postln;
			"\tLX2 RED11: record source sample and set length with note off".postln;
			"\tLX2 RED11 keyset 2: switch to backwards only".postln;
		},
		zone16_4: {
			"\nStart Zone16-4: play one voice in irregular stuttering loop,".postln;
			"\t\tstuttering done outside synthdef by sending a bus".postln;
			"\tLV2Fader8: volume".postln;
			"\tLV2KnobC1: panning".postln;
			"\tLV2KnobC2: LP filter frequency".postln;
			"\tLV2KnobC3: distortion".postln;
			"\tLX2 RED12: record source sample and set length with note off".postln;
			"\tLX2 RED12 keyset 2: on/off SP modulation".postln;
		},
		zone17: {
			"\nStart Zone17: stretched fragments from buffer A".postln;
			"\t\tplus bassdrum and pluck".postln;
			"\tLV1Fader9: volume overall".postln;
			"\tLV1Fader10: start position".postln;
			"\tLV1KnobA1: length".postln;
			"\tLV2KnobB1: SP speed".postln;
			"\tLV1Fader11: volume bassdrum".postln;
			"\tLV1Fader12: volume pluck".postln;
			"\tLV1CrossFader: distortion sample".postln;
		},
		zone18_1: {
			"\nStart Zone18-1: sineAtmos with noise".postln;
			"\tLV1Fader13: volume".postln;
			"\tLV1Fader14: noise speed".postln;
			"\tLV1CrossFader: distortion sample".postln;
		},
		zone18_2: {
			"\nStart Zone18-2: throbbing with reverb".postln;
			"\tLV1Fader15: volume".postln;
			"\tLV1Fader16: speed".postln;
			"\tLV1KnobD1: reverb amount".postln;
			"\tLV1CrossFader: distortion sample".postln;
		},
		diskPlay: {
			"\tMPK K8: volume".postln;
			"\tMPK K7: LP filter frequency".postln;
			"\tMPK K6: pitch".postln;
			"\tMPK K5: vibrato".postln;
			"\tMPK K4: distortion".postln;
			"\tMPK K3: efx send".postln;
		},
		midiSeq: {
			"\tMPK K1: volume".postln;
			"\tMPK K2: LP filter frequency".postln;
			"\tMPK PAD5 bank B: live sample".postln;
			"\tMPK PAD2,3,4,7,8 bank B: drum samples".postln;

		},
	);
};


