// SynthKeys by Robert van Heumen 2013.
// For note input (LPK) and control (Extreme 3dPro).
// Tested with SC 3.6.6.

// Dependencies:
//	GlobalVars.scd for global variable definitions
//	cfg.libraryBase/SampleLists/~project.scd for sample load mapping
//	InOut_xx.scd for audio routing
//	Controllers_x.x.scd for controller OSC data

// Synth output can be send to any of these busses:
//	~aBus.outA 		volume controlled by Faderfox LV2 Mastervolume
//	~aBus.outB		volume controlled by volume pedal
//	~aBus.outBL		limited and volume controlled by volume pedal
//	~aBus.outMain		bypassing volume control, not recommended

// Configuration switches on LX
//	Input for SK prg4 is
//		stereo if internal is selected (RED4=on)
//		mono otherwise, if RED1=off this is recChan1, if RED1=on this is recChan2

// Regarding external midi control: If the OSC message midiReceiveEnable is received, midiFilterPitch will be switched to
//	midiFilterPitchExtMidi and the joystick X will be disabled.

(
s.waitForBoot({

	//////////////// variables ////////////////////////////////

	var
	remote = NetAddrMon("169.254.0.1", 57121), // to Anne
	local = NetAddrMon("127.0.0.1", 57120), // to localhost for SC
	oscMsgAddr = "/bpm";

	var cfg = (
		synthList: [
			"SampleKeys","pitchShifter","","--reserved for sustain--",
			"","","","",
			"", "", "", "",
			"", "","",""
			// "bocAmpMod4","bocAmpMod3","adcirc","--reserved for sustain--",
			// "SinAmpMod3","darkHorns1","darkHorns0","Prime",
			// "SinAmpMod2", "drumSetSample3", "drumSetSample2", "drumSetSynth",
			// "SampleKeys", "pitchShifter","drumSetSample1","drumSetSample0"
			// other: moogSynth, FilterNoise
			// other: harmsWay, FilterBank, bocReverb, bocAmpModSub, SinAmpMod, bocAmpMod, bocAmpMod2
		],
		synthMidiSeq: [0,0,0,0, 0,0,0,0, 0,2,2,2, 1,0,2,2], // 0=don't respond to chan 16, 1=respond to all, 2=don't respond to chan 1-15
		// synthMidiSeq: [0,0,0,0, 0,0,0,0, 0,1,0,1, 1,0,1,1], // 0=don't respond to chan 16, 1=respond to all, 2=don't respond to chan 1-15
		drumList: [
			[
				// "1/TH-BD01.aif", "1/TH-BD02-b.aif",
				"2/FK_Kick2.aif B0.aif", "2/FK_KickFK.aif",
				"2/FK_closedHHV F#1.aif", "2/FK_HiHatDry3 F#0.aif",
				"1/TH-SD01.aif", "1/TH-SD02.aif",
				"1/TH-HHO-01a.aif", "1/TH-HHO-02a.aif"
			],
			[
				"5/BassDist1.wav", "5/BassDist2.wav",
				"5/ClapDist1.wav", "5/ClapDist2.wav",
				"5/HihatDist1.wav", "5/HihatDist2.wav",
				"5/SnareDist1.wav", "5/SnareDist2.wav"
			],
			[
				"3/FK_FloorTV D5 -15.wav","3/FK_FloorTV D5 -15.wav",
				"3/FK_Ride1.aif D#2.aif","3/FK_Ride1.aif D#2.aif",
				"3/FK_Snare6.aif C#0.aif","3/FK_Snare6.aif C#0.aif",
				"3/FK_Crash1.aif C4.aif", "3/FK_Crash1.aif C4.aif"
			],
			[
				"7/nin-ten-bass1.wav", "7/nin-ten-bass2.wav",
				"7/nin-ten-snare1.wav", "7/nin-ten-snare2.wav",
				"7/nin-ten-snare3.wav", "7/nin-ten-bekken1.wav",
				"7/nin-ten-bekken1.wav", "7/nin-ten-bekken1.wav"
			]
		],
		midiFilterPitch: [\LPK,(0..15)], // MIDI filter for note msgs; format [source, [midichannels]]
		// midiFilterPitch: [\LPK,(0..15), \IAC1, [0,1,2,3,15]], // MIDI filter for note msgs; format [source, [midichannels]]
		midiFilterPitchExtMidi: [\EXT,[0,1,2,3,12]], // MIDI filter for note msgs in case external MIDI is enabled
		midiFilterConfig: [\MUL, [0,2]], // MIDI filter for configuration msgs (currently RED1,RED4,BLACK5)
		recLen: 6, // recording length for SampleKeys
		dataDir: Document.dir++"/Lapis/Data/",
		copySamples: 0, // set to 1 to activate sample copy on load - make sure the folder /Data/Samples/~project exists
		midiWrite: false, // whether to write the generated midi for drums to disk
		midiJoySpeedControl: false, // whether joystick controls speed of midi beats
		midiRandomWait: false, // whether to add a random factor to the wait time
		midiDefer: 0.05, // when > 0, adds a random delay to midi notes, with this max
		midiRestartSpeed: false, // when true, resets the speed on every new midi sequence
		sampleLoadBack: nil, // array of paths to sample files to load on hatswitch-back
		sampleLoadLeft: nil, // array of paths to sample files to load on hatswitch-left
		sampleLoadRight: nil // array of paths to sample files to load on hatswitch-right
	);

	var midiFilterPitchLocal = cfg.midiFilterPitch; // set filter for MIDI notes
	var ex3dEnabled = 1; // enable/disable joystick control
	// uncomment below to enable external MIDI control without the ShackleSystem / this will be done automatically by SauerControl.scd
	// var midiFilterPitchLocal = cfg.midiFilterPitchExtMidi;
	// var ex3dEnabled = 0;

	var localAddr = NetAddr("127.0.0.1", 57120);
	var touchOSCAddr = NetAddr("10.0.0.4", 57120);

	// GUI
	var dispPlay, countPlay = 0, susStatus, sustain = 0;
	// var synth1select, synth1label, synth2select, synth2label, synth3select, synth3label, synth4select, synth4label, fSetSynth, shiftStatus,shift = 0;
	var loadFileSK, screenHeight = Window.screenBounds.height, screenWidth = Window.screenBounds.width, pSynthList;
	var fontLabel = Font(~font,10), fontButton = Font(~font,12);
	var colorOff = Color.white;

	// logic
	var fInitOutput, fBufferRead, fSustain, fSendLapisStatus, fGetInChan, fRoundMidiSpeed, fSendMsg;
	var respNON, respNOF, respCTR, respHidEx3d, respPanic, respExtMidi;
	var cutoffBus = Bus.control(s,1), efxBus = Bus.control(s,1), pitchBus = Bus.control(s,1), distBus = Bus.control(s,1);
	var drumVolBus = Bus.control(s,1).set(0.5), drumFilterBus = Bus.control(s,1).set(1);
	var recChan1, recChan2, midiSrcIndex, numPressed = 1, sampleFile;
	var notesArray = Array.newClear(16), zoneRec, notesPrev, activeSynths = 0.dup(16);
	var prevVal, hsBackCount = -1, hsRightCount = -1, hsLeftCount = -1, hsStart, hsGap = 0.15;
	var synthGainBus = {Bus.control(s,1).set(0)}.dup(16);
	var fMidiSeq, tMidiSeq, midiSeqAct = 0, midiSeqChange = 0, midiSeqSpeedInit = 0.9, midiSeqSpeed = 1, midiSeqLenFact = 0.5;
	var midiSeqMode, midiFile, midiStart, midiBPM, midiPath, midiRecording = false, midiSeqSwing = 0.15, maxBpm = 240;

	// load global variables
	"GlobalVars.scd".loadRelative();

	~tuningA = 440; // BoC: 430
	~synthKeysBuf = Buffer.alloc(s, (cfg.recLen)*~sRate, 2);
	~synthKeysDrumBuf = Array.newClear(cfg.drumList.size);
	cfg.drumList.size.do { |count|
		~synthKeysDrumBuf[count] = Array.newClear(8);
		8.do { |i|
			~synthKeysDrumBuf[count][i] = Buffer.read(s, cfg.dataDir ++ "SynthKeys/Drum/" ++ cfg.drumList[count][i]);
		};
	};

	// SynthKeys Specs
	~recLen = cfg.recLen;
	"SynthKeysSpecs.scd".loadRelative();

	// initialize notes array
	16.do({ arg i;
		notesArray[i] = Array.newClear(128);  // array has one slot per possible MIDI note
	});

	// samples to load for sampleplayback on hatswitch
	sampleFile = ("Data/SampleLists/"++~project++".scd").loadRelative[0];
	if(sampleFile.size > 4, {
		cfg.sampleLoadBack = sampleFile[4].back;
		cfg.sampleLoadLeft = sampleFile[4].left;
		cfg.sampleLoadRight = sampleFile[4].right;
	});

	// accomodate in case Arduino is not available
	if(~noArduino == 1, {
		"\nSynthKeys: Remapping dist specs because no Arduino availabe".postln;
		~synthKeysSpec.dist1 = Env.new([20,4,4],[0.5,0.5],[\exp,\lin]);
		~synthKeysSpec.dist2 = Env.new([7.5,1.5,1.5],[0.5,0.5],[\exp,\lin]);
		~synthKeysSpec.dist3 = Env.new([15,8,8],[0.5,0.5],[\exp,\lin]);
		~synthKeysSpec.dist4 = Env.new([4,0.8,0.8],[0.5,0.5],[\exp,\lin]);
		~synthKeysSpec.dist5 = Env.new([5,0.8,0.8],[0.5,0.5],[\exp,\lin]);
		~synthKeysSpec.dist6 = Env.new([5,0.3,0.3],[0.5,0.5],[\exp,\lin]);
		~synthKeysSpec.dist7 = Env.new([300,100,100],[0.5,0.5],[\exp,\lin]);
		~synthKeysSpec.dist8 = Env.new([50,1,1],[0.5,0.5],[\exp,\lin]);
		~synthKeysSpec.distHW = Env.new([20,1,1],[0.5,0.5],[\exp,\lin]);
	});

	// load synths
	"SynthKeysSynths.scd".loadRelative();

	//////////////// functions ////////////////////////////////

	// generic buffer reading function
	fBufferRead = {
		arg samplePath, counter = 0, position = "", absolutePath = 0;
		var soundFile = SoundFile.new;
		samplePath = if(absolutePath == 0, {cfg.dataDir ++ samplePath}, {samplePath});
		if(soundFile.openRead(samplePath), {
			// prepare for loading mono samples
			if( soundFile.numChannels == 1, {m = 0;}, {m = 1;});

			// the actual read of the buffer
			~synthKeysBuf.readChannel(samplePath, channels: [0,m]);

			// done
			("\nSample read:" + counter + position + "--" + samplePath).postln;
			soundFile.close;

			// to save sample files to backup location
			if(cfg.copySamples == 1, {
				("cp '" ++ samplePath ++ "' " ++
					cfg.dataDir ++ "Samples/" ++ ~project ++ "/").postln;
				("cp '" ++ samplePath ++ "' " ++
					cfg.dataDir ++ "Samples/" ++ ~project ++ "/").unixCmd;
			});
		}, {
			("Soundfile" + samplePath + "not found.").postln;
		});
	};

	// stop all notes and restart output synths
	fInitOutput = {
		arg mode, kill = 0; // if kill=1 then also stop the Synth, otherwise assume this is being handled by InOut
		if(mode == 0,
			{ // stop actions
				countPlay = 0;
				dispPlay.states_([[countPlay.asString]]);

				fSendLapisStatus.value("countPlaySK",countPlay);
				sustain = 0;
				fSendLapisStatus.value("sustain",sustain);
				susStatus.background_(colorOff);
				4.do({ arg i;
					notesArray[i].size.do({arg n;
						if(notesArray[i][n].notNil, {
							if(kill == 1, {notesArray[i][n].set(\gate,0)});
							notesArray[i][n] = nil;
						});
					});
				}); // 4.do
			},
			{ // start actions
				fSendLapisStatus.value("countPlaySK",0);
				fSendLapisStatus.value("sustain",0);
		});
	};

	// handle sustain
	fSustain = {
		sustain = (sustain + 1).mod(2);
		{	if(sustain == 1, {susStatus.background_(~colorOn)}, {susStatus.background_(colorOff)});
			fSendLapisStatus.value("sustain",sustain);
		}.defer();

		// switch off all notes
		if(sustain == 0, {
			activeSynths.size.do({ |synth|
				notesArray[synth].size.do({|note|
					if(notesArray[synth][note].notNil, {
						notesArray[synth][note].set(\gate,0);
						notesArray[synth][note] = nil;
					});
				});
			});
			countPlay = 0;
			{
				dispPlay.states_([[countPlay.asString]]);
				fSendLapisStatus.value("countPlaySK",countPlay);
			}.defer();
		});
	};

	// sending LapisStatus OSC to local or touchOSC
	fSendLapisStatus = { arg type, value;
		if((~lapisStatusDestination == "touchOSC") || (~lapisStatusDestination == "both"),
			{touchOSCAddr.sendMsg("/lapistatus/"++type,value)});
		if((~lapisStatusDestination == "local") || (~lapisStatusDestination == "both"),
			{localAddr.sendMsg("/lapistatus",type,value)});
	};

	// returning input channels for effects, depending on ~aBus.inInt and ~aBus.inAlt settings
	fGetInChan = {
		var inChan1, inChan2;
		if(~aBus.inInt == 1, { // if input is internal, it's always stereo
			inChan1 = ~aBus.inChan1;
			inChan2 = ~aBus.inChan2;
		},{ // if input is external, it's always mono
			// if chan1&2 set to alternative, take 2x chan2, otherwise 2x chan1
			inChan1 = if(~aBus.inAlt == 0, {~aBus.inChan1},{~aBus.inChan2});
			inChan2 = inChan1;
		});
		[inChan1,inChan2]
	};

	//////////////// MIDI sequence ////////////////////////////////

	fRoundMidiSpeed = {
		arg speed;
		var bpm;
		// convert to BPM, round and convert back
		bpm = speed.reciprocal*120;
		bpm = bpm.round(1);
		speed = bpm.reciprocal*120;
		[bpm, speed]
	};

	OSCdef(\synthKeysBpm, {
		arg msg;
		var bpm = msg[1];
		("synthKeysBpm:" + msg).postln;
		try {
			bpm = bpm.asInteger;
			if(bpm > 0, {
				bpm = min(maxBpm, bpm);
				bpm = max(10, bpm);
				// while { bpm > maxBpm } { bpm = bpm / 2 };
				// while { bpm < 10 } { bpm = bpm * 2 };
				midiSeqSpeed = bpm.reciprocal*120;
				("OSC: MIDI sequence speed set to" + bpm).postln;
				fSendLapisStatus.value("midiBPM", bpm);
			}, { ("OSC:" + msg[1] + "could not be converted to an integer").postln });
		} { ("Could not convert" + msg[1] + "to integer").error };
	}, "/bpm").fix;

	// sending OSC to a NetAddr
	fSendMsg = {
		arg label, value;
		var netaddr = if(~shackleRemoteClientsOnline == 1, { remote }, { local });
		try
		{ netaddr.sendMsg(label, value) }
		{ ("\nNetAddr Error with"+label+value).postln; }
	};

	fMidiSeq = {
		var count = if(~theBusyDrone==1, { rrand(5,10) }, { rrand(3,8) });
		var seqNotes, seqLen = {[0.25,0.5].wchoose([0.8,0.2])}!count;
		var note, len, factor = 1, factor2 = 1, vel = 127, changeCount = 0, totalTime = 0, midiChan = 15;
		var midiDefer = 0, midiDur = 1, bpm;

		bpm = fRoundMidiSpeed.value(midiSeqSpeed)[0];
		case
		{midiSeqMode == \random} {
			seqNotes = {rrand(40,80)}!count;
			maxBpm = 240;
			bpm = min(maxBpm, bpm);
		}
		{midiSeqMode == \downbeat} {
			seqNotes = [rrand(40,53)] ++ ( [rrand(40,53)] ++ ({rrand(50,80)}!(count-2)) ).scramble;
			maxBpm = 240;
			bpm = min(maxBpm, bpm);
			midiSeqSpeed = bpm.reciprocal*120;
		}
		{midiSeqMode == \downbeatSwing} {
			seqNotes = [rrand(40,53)] ++ ( [rrand(40,53)] ++ ({rrand(50,80)}!(count-2)) ).scramble;
			maxBpm = 350;
			bpm = min(maxBpm, bpm);
			midiSeqSpeed = bpm.reciprocal*120;
		};
		fSendLapisStatus.value("midiBPM", bpm);
		midiSeqSpeed = bpm.reciprocal*120;
		if(cfg.midiRestartSpeed, { midiSeqSpeed = midiSeqSpeedInit });

		// seqNotes =  [ 50, 67, 63, 46, 54, 66 ]; // nummer 1
		// seqLen =  [ 0.5, 0.25, 0.5, 0.25, 0.5, 0.25 ];
		// seqNotes =  [ 45, 66, 50, 76, 78 ]; // nee
		// seqLen =  [ 0.25, 0.5, 0.25, 0.5, 0.25 ];
		// seqNotes =  [ 43, 62, 64, 79, 43, 75 ]; // nummer 2
		// seqLen =  [ 0.5, 0.5, 0.25, 0.5, 0.25, 0.25 ];
		// seqNotes =  [ 46, 41, 65, 50 ]; // nummer 3
		// seqLen =  [ 0.25, 0.25, 0.5, 0.25 ];
		// count = seqNotes.size;

		// scootermen
		// f = 0;
		// while( {f==0} , {
		// 	seqLen = {[0.25,0.5].wchoose([0.8,0.2])}!count;
		// 	if(seqLen.sum.floor == seqLen.sum, {f=1});
		// });
		// seqLen = 1.3 * seqLen;

		if(~theBusyDrone==1, {
			"## The Busy Drone Mode!".postln;
			midiChan = 0;
			seqNotes =  [(3..14).choose] ++ [(33..55).choose] ++ [(3..14).choose] ++
									({ ((3..14)++(18..29)++(33..55)++(59..78)).choose }!(count-3));
		});

		midiBPM = fRoundMidiSpeed.value(midiSeqSpeed)[0];
		midiSeqSpeed = fRoundMidiSpeed.value(midiSeqSpeed)[1];

		("MIDI seq:" + midiSeqMode + "/" + count + "notes @" + midiBPM + "BPM" ).warn;
		("Notes: " + seqNotes).postln;
		("Lengths: " + seqLen).postln;

		// initialize MIDI file for write / note: BPM is not updated when changed in realtime!
		if(cfg.midiWrite, {
			midiPath = cfg.dataDir ++ "MIDI/" ++ Date.getDate.format("%y%m%d_%H%M%S") ++ ".mid";
			("Writing MIDI file to" + midiPath).postln;
			midiFile = SimpleMIDIFile( midiPath );
			midiFile.init1( 1, midiBPM, "4/4" );
			midiFile.timeMode = \seconds;
			midiStart = SystemClock.seconds;
			midiRecording = true;
		});

		if(~midiOutInit == 1, {
			var swing = 0;
			inf.do { |i|
				var beat = i%count;
				swing = 0;
				note = seqNotes[beat];
				// ("Triggering MIDI note" + note).postln;
				// if( ( (beat == 0) || (beat == 2)) && (factor*factor2 == 1), {
				if( (beat%2 == 0) && (factor*factor2 == 1), {
					if(beat == 0 || beat == 2, {
						vel = rrand(110,127);
					});
				}, {
					if(midiSeqMode == \downbeatSwing, {
						swing = midiSeqSwing;
					});
					vel = [rrand(50,100),0].wchoose([0.9,0.1]);
				});

				// below is code for bassline on odd beats
				// if( totalTime%2 == 0, {
				// 	~midiOut.noteOn(5,46,rrand(80,120));
				// 	{ ~midiOut.noteOff(5,46,127) }.defer(0.5*midiSeqSpeed);
				// });

				(1/(factor*factor2)).do {
					// set note duration
					midiDur = factor*factor2*midiSeqSpeed*seqLen[beat];
					// set note duration factor with joystick
					if(cfg.midiJoySpeedControl, {
						midiDur = midiDur * midiSeqLenFact;
					});
					// possible random delay of note ON
					if(cfg.midiDefer > 0 and: { 0.1.coin }, { midiDefer = rrand(0, cfg.midiDefer) }, { midiDefer = 0 });
					// add swing
					if(swing > 0, {
						midiDefer = midiDefer + (swing * midiDur);
					});
					// trigger note ON
					{ ~midiOut.noteOn(midiChan,note,vel) }.defer(midiDefer);
					// schedule note OFF
					{~midiOut.noteOff(midiChan,note,127); }.defer(midiDur * 0.9);
					// save to MIDI file
					if(cfg.midiWrite, { midiFile.addNote(note, 127, SystemClock.seconds - midiStart, midiDur) });
					// wait
					if(cfg.midiRandomWait, { midiDur = midiDur * rrand(0.95, 1.05) });
					midiDur.wait;
				};

				if( (midiSeqChange == 1) || (i%50 == 49), {
					if(changeCount < 10, { // change just one note
						"MIDIseq change one".postln;
						if(~theBusyDrone==1, {
							seqNotes[rrand(3,count-1)] = ((3..14)++(18..29)++(33..55)++(59..78)).choose;
						}, {
							seqNotes[rrand(1,count-1)] = rrand(40,80);
						});
						// seqLen[rand(count)] = [0.25,0.5].wchoose([0.8,0.2]);
						("Notes: " + seqNotes).postln;
						changeCount = changeCount + 1;
					},{ // change all notes
						"MIDIseq change all".postln;
						case
						{midiSeqMode == \random} {
							seqNotes = {rrand(40,80)}!count;
						}
						{midiSeqMode == \downbeat} {
							seqNotes = [rrand(40,53)] ++ ( [rrand(40,53)] ++ ({rrand(50,80)}!(count-2)) ).scramble;
						}
						{midiSeqMode == \downbeatSwing} {
							seqNotes = [rrand(40,53)] ++ ( [rrand(40,53)] ++ ({rrand(50,80)}!(count-2)) ).scramble;
						};
						if(~theBusyDrone==1, {
							"## The Busy Drone Mode!".postln;
							seqNotes =  [(3..14).choose] ++ [(33..55).choose] ++ [(3..14).choose] ++
												({ ((3..14)++(18..29)++(33..55)++(59..78)).choose }!(count-3));
						});
						("Notes: " + seqNotes).postln;
						changeCount = 0;
					});
					midiSeqChange = 0;
				});
				if(midiSeqMode != \downbeatSwing, {
					if(i%15 == 3, { factor = 0.5 });
					if(i%15 == 7, { factor = 1 });
					if( (i%25 == 4) && (i>4), { factor2 = 0.5 });
					if( (i%25 == 8) && (i>8), { factor2 = 1 });
				});
				totalTime = totalTime + seqLen[beat];
			};
		});
	};

	//////////////// MIDI ////////////////////////////////

	cutoffBus.set(0.5);
	efxBus.set(0.5);
	pitchBus.set(0.5);
	distBus.set(1);

	OSCdef(\skNON, { |msg|
		var chan, note, vel, src;
		chan = msg[1];
		note = msg[2];
		vel = msg[3];
		src = msg[4];
		// [chan,note,vel,src].postln;

		// filter to trigger pitch material
		midiSrcIndex = midiFilterPitchLocal.indexOf(src); // get the index of this MIDI src
		if(midiSrcIndex.notNil, { // check midi source
			if(midiFilterPitchLocal[midiSrcIndex+1].indexOf(chan).notNil, { // check midi chan
				if(notesPrev.isNil, {notesPrev = note}); // glide support
				// start synth
				activeSynths.size.do { |synth|
					if( (activeSynths[synth] == 1) && notesArray[synth][note].isNil // only for active synths and note not started yet
						&& ( (chan<15) || (cfg.synthMidiSeq[synth] > 0) )  // if MIDI chan is 16 then only if synthMidiSeq = 1 or 2
						&& ( (chan==15) || (cfg.synthMidiSeq[synth] < 2) ), {  // if MIDI chan is 1-15 then only if synthMidiSeq = 0 or 1
						notesArray[synth][note] = Synth(cfg.synthList[synth], [
							\freq1, note.midicps(~tuningA), \gate, 1, \cutoffBus, cutoffBus.index, \efxBus, efxBus.index,
							\pitchBus, pitchBus.index, \distBus, distBus.index, \velocity, vel,
							\inChan1, fGetInChan.value()[0], \inChan2, fGetInChan.value()[1],
							\prevFreq, notesPrev.midicps(~tuningA), \synthGainBus, synthGainBus[synth].index,
							\drumFilterBus, drumFilterBus.index, \drumVolBus, drumVolBus.index, \buffer, ~synthKeysBuf
						], target: ~aBus.synthGroup);
						// count notes
						{ 	countPlay = countPlay + 1;
							dispPlay.states_([[countPlay.asString]]);
							fSendLapisStatus.value("countPlaySK",countPlay);
								// fSendLapisStatus.value("prgSK",synth);
						}.defer();
					});
				};
				notesPrev = note; // save this note for glide support
			});
		}); // filter to trigger pitch material

		// filter to trigger config material
		midiSrcIndex = cfg.midiFilterConfig.indexOf(src); // get the index of this MIDI src
		if(midiSrcIndex.notNil, { // check midi source
			if(cfg.midiFilterConfig[midiSrcIndex+1].indexOf(chan).notNil, { // check if midi chan is allowed

				if((chan == 2) && (note==19), { // save sample buffer
					// "SynthKeys: save samplebuffer".postln;
					// ~synthKeysBuf.write(thisProcess.platform.recordingsDir++"/SynthKeys"++Date.getDate.format("_%y%m%d_%H%M%S")++".aif");
				});
				if((chan == 2) && (note==13), { // MIDI sequence 1
					if(midiSeqAct == 0, {
						// start MIDI sequence
						midiSeqAct = 1;
						midiSeqMode = \downbeatSwing;
						tMidiSeq = Task(fMidiSeq).start;
					}, {
						// stop MIDI sequence
						tMidiSeq.stop; if(cfg.midiWrite and: { midiRecording }, { midiFile.write; midiRecording = false; });
						"MIDI sequence stopped".postln;
						midiSeqAct = 0;
					});
				});
				if((chan == 2) && (note==15), { // MIDI sequence 2
					if(midiSeqAct == 0, {
						// start MIDI sequence
						midiSeqAct = 1;
						midiSeqMode = \downbeat;
						tMidiSeq = Task(fMidiSeq).start;
					}, {
						// stop MIDI sequence
						tMidiSeq.stop; if(cfg.midiWrite and: { midiRecording }, { midiFile.write; midiRecording = false; });
						"MIDI sequence stopped".postln;
						midiSeqAct = 0;
					});
				});
				if((chan == 2) && (note==18), { // MIDI sequence change
					if(midiSeqAct == 1, { midiSeqChange = 1 })
				});
				if((chan == 2) && (note==20), { // MIDI sequence speed decrease
					midiSeqSpeed = midiSeqSpeed / 0.9;
					("New speed is" + (midiSeqSpeed.reciprocal*60*2).round(1) + "BPM (" + midiSeqSpeed + ")").postln;
					fSendMsg.value(oscMsgAddr, fRoundMidiSpeed.value(midiSeqSpeed)[0]);
					fSendLapisStatus.value("midiBPM", fRoundMidiSpeed.value(midiSeqSpeed)[0]);
				});
				if((chan == 2) && (note==22), { // MIDI sequence speed increase
					midiSeqSpeed = midiSeqSpeed * 0.9;
					("New speed is" + (midiSeqSpeed.reciprocal*60*2).round(1) + "BPM ("+ midiSeqSpeed + ")").postln;
					fSendMsg.value(oscMsgAddr, fRoundMidiSpeed.value(midiSeqSpeed)[0]);
					fSendLapisStatus.value("midiBPM", fRoundMidiSpeed.value(midiSeqSpeed)[0]);
				});

			});
		}); // filter to trigger config material
	},
	"/midi/noteOn"
	).fix;

	OSCdef(\skNOF, { |msg|
		var chan, note, vel, src;
		chan = msg[1];
		note = msg[2];
		vel = msg[3];
		src = msg[4];
		//	[chan,note,vel].postln;

		// filter to trigger pitch material
		midiSrcIndex = midiFilterPitchLocal.indexOf(src); // get the index of this MIDI src
		if(midiSrcIndex.notNil, { // check midi source
			if(midiFilterPitchLocal[midiSrcIndex+1].indexOf(chan).notNil, { // check if midi chan is allowed

				if( (sustain == 0) || (chan==15), { // when chan=15 then midiSeq so no sustain
					// switch off notes
					activeSynths.size.do { |synth|
						if( (activeSynths[synth] == 1) && notesArray[synth][note].notNil
							&& ( (chan<15) || (cfg.synthMidiSeq[synth] > 0) )  // if MIDI chan is 16 then only if synthMidiSeq = 1 or 2
							&& ( (chan==15) || (cfg.synthMidiSeq[synth] < 2) ), {  // if MIDI chan is 1-15 then only if synthMidiSeq = 0 or 1
							notesArray[synth][note].set(\gate,0);
							notesArray[synth][note] = nil;
							// count note
							countPlay = max(0, countPlay - 1);
							{
								dispPlay.states_([[countPlay.asString]]);
								fSendLapisStatus.value("countPlaySK",countPlay);
							}.defer();
						});
					};
				});

			});
		}); // filter to trigger pitch material

		// filter to trigger config material
		midiSrcIndex = cfg.midiFilterConfig.indexOf(src); // get the index of this MIDI src
		if(midiSrcIndex.notNil, { // check midi source
			if(cfg.midiFilterConfig[midiSrcIndex+1].indexOf(chan).notNil, { // check if midi chan is allowed

				// input channels switching
				if((chan==0) && (~wLiveSamplerAvail.isNil), { // only do if LiveSampler not running,
					case
					{(note == 0) && (~aBus.inAlt == 1)} // switching input 1 & 2 back to original
					{
						("SynthKeys: Switch inputs 1 & 2 from" + ~aBus.inChan1 + "&" + ~aBus.inChan2 +
							"to" + ~aBus.inChan1org + "&" + ~aBus.inChan2org).postln;
						~aBus.inChan1 = ~aBus.inChan1org;
						~aBus.inChan2 = ~aBus.inChan2org;
						~aBus.inAlt = 0;
					}
					{(note == 3) && (~aBus.inInt == 1)} // switching inputs 1&2 to back to what they were
					{
						("SynthKeys: Switch inputs 1 & 2 from" + ~aBus.inChan1 + "&" + ~aBus.inChan2 + "to" +
							if(~aBus.inAlt == 0, {~aBus.inChan1org}, {~aBus.inChan1alt})  + "&" +
							if(~aBus.inAlt == 0, {~aBus.inChan2org}, {~aBus.inChan2alt})).postln;
						~aBus.inChan1 = if(~aBus.inAlt == 0, {~aBus.inChan1org}, {~aBus.inChan1alt});
						~aBus.inChan2 = if(~aBus.inAlt == 0, {~aBus.inChan2org}, {~aBus.inChan2alt});
						~aBus.inInt = 0;
					};
				});

			});
		}); // filter to trigger config material
	},
	"/midi/noteOff"
	).fix;

	OSCdef(\skCC, { |msg|
		var chan, num, val, src;
		chan = msg[1];
		num = msg[2];
		val = msg[3];
		src = msg[4];
		// [src, chan,num,val].postln;

		// filter to control pitch material
		midiSrcIndex = midiFilterPitchLocal.indexOf(src); // get the index of this MIDI src
		if(midiSrcIndex.notNil,{ // check midi source
			if(midiFilterPitchLocal[midiSrcIndex+1].indexOf(chan).notNil, { // check whether midi chan is allowed
				// sustain
				if( (num==64) && (val==1), {fSustain.value()}); // regular
				if( (num==23) , {fSustain.value()}); // pad 4 on MPK
				// set active synths (pads 1-8 in 2 banks on MPK / pad 4 for sustain)
				if( (num>=20) && (num<=35) && (num!=23), {
					var synth = num-20;
					activeSynths[synth] = val.ceil;
					// stop all notes if synth is de-activated
					if(activeSynths[synth]==0, {
						notesArray[synth].size.do { |note|
							if(notesArray[synth][note].notNil, {
								notesArray[synth][note].set(\gate,0);
								notesArray[synth][note] = nil;
								countPlay = max(0, countPlay - 1);
								{ 	dispPlay.states_([[countPlay.asString]]);
									fSendLapisStatus.value("countPlaySK",countPlay);
								}.defer();
							});
						};
					});
					("Synth"+(synth)+cfg.synthList[synth]+if(val==0,{"de-activated"},{"activated"})).postln;
					// activeSynths.postln;
				});
				if( num==4, { drumVolBus.set(val) }); // volume/distortion drumsets
				if( num==5, { drumFilterBus.set(val) }); // filter drumsets
				if( num==6, {
					midiSeqSwing = val.linlin(0,1,0,0.8);
					// ("Swing" + midiSeqSwing).postln;
				}); // midi seq swing
				// code below used to be to control gain from active synths
				// if( (chan<=1) && (num>=0) && (num <=7), {
				// 	if(num!=3, {
				// 		synthGainBus[num+(chan*8)].set(val);
				// 		// ("synthGainBus"+(num+(chan*8))+"set to"+val).postln;
				// 		}, {
				// 			~aBus.outMainsynth.set(\resampAtt, ~synthKeysSpec.resampleAtt.at(val));
				// 			// ("initial resampleAtt value is" + ~aBus.outResamplingAtt).postln;
				// 			("resampleAtt set to"+ ~synthKeysSpec.resampleAtt.at(val)).postln;
				// 	});
				// });
			});

		}); // filter to control pitch material
	},
	"/midi/control"
	).fix;

	//////////////// HID ////////////////////////////////

	OSCdef(\skEx3d, { |msg|
		var cookie = msg[1];
		var val = msg[2];
		var fromMidi = msg[3]; // extra parameter: if 1 then this data is actually originating from a MIDI controller
		if(fromMidi.isNil, {fromMidi = 0});
		// ("SynthKeys OSC RCV Ex3d: " ++ msg).postln;

		if(~oscSrc == "jx", {
			cookie = cookie * 127; 			// back to the MIDI range; this might be f.e. 2 or 2.0001 or 1.9999
			cookie = (cookie + 0.1).floor; 	// make up for rounding errors then make into integer
			// ("Cookie:" + cookie + "Value:" + val).postln;
		});

		if(	((ex3dEnabled == 1) && (fromMidi == 0)) || 	// joystick enabled
			((ex3dEnabled == 0) && (fromMidi == 1)),  	// joystick disabled, take data from midi
			{
				case
				{cookie == 16}		// X-axis
				{
					if(~oscSrc == "jx", {val = (1-val) * 1024}); // junXion repair
					midiSeqSpeedInit = ~synthKeysSpec.midiSeqSpeed.at(val/1024);
					cutoffBus.set(val/1024)
				};
		});

		if(fromMidi == 0, { // always control from joystick, never from external MIDI
			case
			{cookie == 17} 		// Y-axis
			{
				if(~oscSrc == "jx", {val = (1-val) * 1024}); // junXion repair
				if(cfg.midiJoySpeedControl, { midiSeqLenFact = val.linlin(0,1024,0.1,0.9) });
				pitchBus.set(val/1024)
			}
			{cookie == 19} 		// Rotation
			{
				if(~oscSrc == "jx", {val = (1-val) * 255}); // junXion repair
				efxBus.set(val/255)
			}
			{cookie == 20} 		// Slider
			{
				if(~oscSrc == "jx", {val = (1-val) * 255}); // junXion repair
				distBus.set(val/255)
			}
			;
		});

		case
		{cookie == 18} 		// Hatswitch
		{
			if(~oscSrc == "jx", { // junXion repair
				val = (1-val) * 7;
				val = val.ceil;
				if(val==0, {val = -1});
			});
			if(val != -1, { // anything but the middle position of the hatswitch
				prevVal = val;
				hsStart = SystemClock.seconds; // start measuring time
			},
			{ // on return to middle position process action set by prevVal
				case
				{prevVal == 7} // start recording
				{
					"Start recording into ~synthKeysBuf...".postln;

					// // set input channels
					// if(~aBus.inInt == 1, { // if input is internal, it's always stereo
					// 	recChan1 = ~aBus.inChan1;
					// 	recChan2 = ~aBus.inChan2;
					// 	}, { // if input is external, it's always mono
					// 		// if chan1&2 set to alternative, take 2x chan2, otherwise 2x chan1
					// 		recChan1 = if(~aBus.inAlt == 0, {~aBus.inChan1},{~aBus.inChan2});
					// 		recChan2 = recChan1;
					// });

					// start synth
					zoneRec = Synth(\zoneRecSK, [\chan1, fGetInChan.value()[0], \chan2, fGetInChan.value()[1],
						\buf, ~synthKeysBuf, \len, cfg.recLen
					], target: ~aBus.synthGroup);
				}
				{prevVal == 5}  // load default sample for hatswitch right
				{
					if(SystemClock.seconds - hsStart >= hsGap,
						{hsRightCount = 0;}, // reset counter
						{hsRightCount = (hsRightCount + 1)%cfg.sampleLoadRight.size;}); // next counter value
					// load sample
					fBufferRead.value(cfg.sampleLoadRight[hsRightCount], hsRightCount, "Right");
				}
				{prevVal == 3} // load default sample for hatswitch back
				{
					if(SystemClock.seconds - hsStart >= hsGap,
						{hsBackCount = 0;}, // reset counter
						{hsBackCount = (hsBackCount + 1)%cfg.sampleLoadBack.size;}); // next counter value
					// load sample
					fBufferRead.value(cfg.sampleLoadBack[hsBackCount], hsBackCount, "Back");
				}
				{prevVal == 1} // load default sample for hatswitch left
				{
					if(SystemClock.seconds - hsStart >= hsGap,
						{hsLeftCount = 0;}, // reset counter
						{hsLeftCount = (hsLeftCount + 1)%cfg.sampleLoadLeft.size;}); // next counter value
					// load sample
					fBufferRead.value(cfg.sampleLoadLeft[hsLeftCount], hsLeftCount, "Left");
				}
				;
			});
		}
		;
	},
	"/hid/ex3d"
	).fix;

	//////////////// OSC responders ////////////////////////////////

	// responder to stop everything
	OSCdef(\skPanic, { |msg|
		"Panic SynthKeys".postln;
		{fInitOutput.value(0)}.defer();	// stop
		{fInitOutput.value(1)}.defer(0.1);	// restart
	},
	"/panic"
	).fix;

	OSCdef(\skExtMidi, { |msg|
		// stop SK
		{fInitOutput.value(0, kill:1)}.defer();

		// switch to extMidi src/chan
		if(msg[1] == 1, {
			midiFilterPitchLocal = cfg.midiFilterPitchExtMidi;
			ex3dEnabled = 0;
		}, {
			midiFilterPitchLocal = cfg.midiFilterPitch;
			ex3dEnabled = 1;
		});

		// reset SK
		{fInitOutput.value(1)}.defer(0.1);

		//	("Synthkeys: extMidi is" + if(msg[1] == 1, "ON", "OFF")).postln;
	},
	"/midiReceiveEnable"
	).fix;

	//////////////// GUI ////////////////////////////////

	~wSynthKeys = Window("SynthKeys", Rect(360, (screenHeight - 160), 280, 100),false);
	~wSynthKeysAvail = 1;

	pSynthList = (PopUpMenu(~wSynthKeys, Rect(25,10,170,23))
		.font_(fontLabel).background_(Color.white).canFocus_(false)
		.items_(cfg.synthList.collect({ |item, index| (index+1)+item  }))
	);

	// drag destination for sample load into buffer
	loadFileSK = DragSink(~wSynthKeys, Rect(25,67,170,23))
	.canFocus_(false);
	loadFileSK.string = "Drag file to load";
	loadFileSK.font = fontLabel;
	loadFileSK.align_(\center);
	loadFileSK.background_(Color.white);
	loadFileSK.stringColor_(Color.black);
	loadFileSK.receiveDragHandler = {
		var dragTemp = View.currentDrag;
		if(dragTemp.isString, {dragTemp = dragTemp.split(nl)}); // if only one file is dragged, make it into an array with this trick
		dragTemp.postln;
		fBufferRead.value(dragTemp[0], absolutePath: 1);
	};

	dispPlay = SmoothButton(~wSynthKeys, Rect(205,9,50,23))
	.border_(1)
	.radius_(3)
	.canFocus_(false)
	.font_(fontButton)
	.background_(Color.white)
	.stringColor_(Color.blue)
	.states_([["0"]]);

	susStatus = SmoothButton(~wSynthKeys, Rect(205,38,50,23))
	.border_(1)
	.radius_(3)
	.canFocus_(false)
	.font_(fontButton)
	.background_(Color.white)
	.states_([["Sus"]]);

	~wSynthKeys.view.keyDownAction_({
		arg view, char, modifiers, unicode, keycode;
		// [modifiers,keycode].postln;

		if(keycode == 53, { // esc
			localAddr.sendMsg("/panic");
		});
		// L clears buffer
		if((keycode == 37),
			{~synthKeysBuf.zero; "SynthKeys Buffer cleared.".postln;});
		// S saves buffer to disk
		if((keycode ==1),{
			~synthKeysBuf.write(thisProcess.platform.recordingsDir++"/SynthKeys"++Date.getDate.format("_%y%m%d_%H%M%S")++".aif");
			"SynthKeys: save samplebuffer".postln;
		});
	});

	//~wSynthKeys.alwaysOnTop_(true);
	w = Window("dummy").front; w.close;
	~wSynthKeys.front;
	if(~wInOutAvail == 1, {localAddr.sendMsg("/imageRefresh")});

	~wSynthKeys.onClose_({
		OSCdef(\skNON).free; OSCdef(\skNOF).free; OSCdef(\skCC).free;
		OSCdef(\skEx3d).free; OSCdef(\skPanic).free; OSCdef(\skExtMidi).free;
		OSCdef(\synthKeysBpm).free;
		~wSynthKeysAvail = nil;
		~synthKeysBuf.free;
		3.do { |count|
			~synthKeysDrumBuf[count].do { |buffer| buffer.free; };
		};
		tMidiSeq.stop; if(cfg.midiWrite and: { midiRecording }, { midiFile.write; midiRecording = false; });
	});

	// initialize
	fInitOutput.value(1);
	fBufferRead.value(cfg.sampleLoadBack[0],0,"Back"); hsBackCount = 0;
	// fSetSynth.value();

}); // wait for boot
)




