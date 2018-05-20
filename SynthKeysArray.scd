// SynthKeysProduction by Robert van Heumen 2016.
// Synth setup to be triggered by Sibelius, realtime control with MPK and joystick

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

(
s.waitForBoot({

	//////////////// variables ////////////////////////////////

	var pID = 2;
	var synthListMain = [
		"adcirc",
		"bocAmpMod2",
		"bocAmpMod2b",
		"bocAmpMod3",
		"bocAmpMod4",
		"darkHorns0",
		"darkHorns1",
		"drumSetSample0",
		"drumSetSample1",
		"drumSetSynth",
		"FilterNoise",
		"harmsWay",
		"moogSynth",
		"pitchShifter",
		"Prime",
		"SampleKeys",
		"SinAmpMod3",
		"SampleKeysNoPitch"
	];
	var project = (
		synthList: [
			[7,2,2,3,4,5,6,7,8,9,10,11,12,13,14,15],
			[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15],
			[15,15,15,15,4,5,6,7,8,9,10,11,12,0,15,15],
			[17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17]
		],
		semiShiftList: [
			0.dup(16),
			0.dup(16),
			[12,-12,-4] ++ 0.dup(13),
			0.dup(16)
		],
		sampleList: [
			[
				nil, nil, nil,nil,
				nil, nil, nil,nil,
				nil, nil, nil,nil,
				nil, nil,
				"SynthKeys/kistorgel10.aif",
				nil
			],
			[
				"SynthKeys/kistorgel10.aif",
				"SynthKeys/kistorgel13.aif",
				"SynthKeys/kistorgel9.aif",
				"SynthKeys/kistorgel8.aif",
				nil, nil, nil,nil,
				nil, nil, nil,nil,
				nil, nil, nil,nil
			],
			[
				"SynthKeys/TBD/bassen48.wav",
				"SynthKeys/TBD/bourdon60.wav",
				"SynthKeys/TBD/bassdrum.wav",
				"SynthKeys/kistorgel8.aif",
				nil, nil, nil,nil,
				nil, nil, nil,nil,
				nil, nil, nil,nil
			],
			nil!16
		]
	);
	var cfg = (
		version: "SynthArray",
		synthList: project.synthList[pID],
		semiShiftList: project.semiShiftList[pID],
		sampleList: project.sampleList[pID],
		synthMidiSeq: [0,0,0,0, 0,0,0,0, 0,2,2,2, 1,0,2,2], // 0=don't respond to chan 16, 1=respond to all, 2=don't respond to chan 1-15
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
		// drumList0: [
		// 	"6/plankje1.wav", "6/plankje2.wav",
		// 	"6/plankje3.wav", "6/plankje4.wav",
		// 	"6/plankje5.wav", "6/plankje6.wav",
		// 	"6/plankje7.wav", "6/plankje8.wav"
		// ],
		// drumList0: [
		// 	"2/FK_Kick2.aif B0.aif", "2/FK_KickFK.aif",
		// 	"2/FK_closedHHV F#1.aif", "2/FK_HiHatDry3 F#0.aif",
		// 	"1/TH-SD01.aif", "1/TH-SD02.aif",
		// 	"1/TH-HHO-01a.aif", "1/TH-HHO-02a.aif"
		// ],
		// drumList0: [
		// 	"3/FK_FloorTV D5 -15.wav","3/FK_FloorTV D5 -15.wav",
		// 	"3/FK_Ride1.aif D#2.aif","3/FK_Ride1.aif D#2.aif",
		// 	"3/FK_Snare6.aif C#0.aif","3/FK_Snare6.aif C#0.aif",
		// 	"3/FK_Crash1.aif C4.aif", "3/FK_Crash1.aif C4.aif"
		// ],
		// drumList1: [
		// 	"1/TH-BD01.aif", "1/TH-BD02-b.aif",
		// 	"2/FK_closedHHV F#1.aif", "2/FK_HiHatDry3 F#0.aif",
		// 	"1/TH-SD01.aif", "1/TH-SD02.aif",
		// 	"1/TH-HHO-01a.aif", "1/TH-HHO-02a.aif"
		// ],
		// drumList1: [
		// 	"5/BassDist1.wav", "5/BassDist2.wav",
		// 	"5/ClapDist1.wav", "5/ClapDist2.wav",
		// 	"5/HihatDist1.wav", "5/HihatDist2.wav",
		// 	"5/SnareDist1.wav", "5/SnareDist2.wav"
		// ],
		midiFilterPitch: [\IAC2, (0..15),\LPK, (0..15)], // MIDI filter for note msgs; format [source, [midichannels]]
		recLen: 6, // recording length for SampleKeys
		dataDir: Document.dir++"/Lapis/Data/",
	);

	var localAddr = NetAddr("127.0.0.1", 57120);

	// GUI
	var screenHeight = Window.screenBounds.height, screenWidth = Window.screenBounds.width, tHeader;
	var dispPlay = Array.newClear(16), countPlay = 0.dup(16), bTest = Array.newClear(16);
	var loadFileSK = Array.newClear(16), pSynthList = Array.newClear(16), tMidiChan = Array.newClear(16);
	var bControl = Array.newClear(16), controlList = 0.dup(16);
	var fontLabel = Font("Helvetica",12), fontButton = Font("Helvetica",12), colorOff = Color.white;

	// logic
	var fInitOutput, fBufferRead, fGetInChan, midiSrcIndex;
	var cutoffBus = {Bus.control(s,1).set(0.5)}.dup(16), efxBus = {Bus.control(s,1).set(0.5)}.dup(16);
	var pitchBus = {Bus.control(s,1).set(0.5)}.dup(16), distBus = {Bus.control(s,1).set(1)}.dup(16);
	var drumVolBus = {Bus.control(s,1).set(0.5)}.dup(16), drumFilterBus = {Bus.control(s,1).set(1)}.dup(16);
	var notesArray = Array.newClear(16), notesPrev = Array.newClear(16), sampleKeysFile = Array.newClear(16);
	var synthGainBus = {Bus.control(s,1).set(0)}.dup(16), selectedSynthList = cfg.synthList;

	// load global variables
	"GlobalVars.scd".loadRelative();

	~tuningA = 440; // BoC: 430
	~bufferSK = { Buffer.alloc(s, (cfg.recLen)*~sRate, 2) } ! 16;
	~bufferDrumSK = Array.newClear(cfg.drumList.size);
	cfg.drumList.size.do { |count|
		~bufferDrumSK[count] = Array.newClear(8);
		8.do { |i|
			~bufferDrumSK[count][i] = Buffer.read(s, cfg.dataDir ++ "SynthKeys/Drum/" ++ cfg.drumList[count][i]);
		};
	};

	// SynthKeys Specs
	~recLen = cfg.recLen;
	"Lib/SynthKeysSpecs.scd".loadRelative();

	// initialize notes array
	16.do({ arg i;
		notesArray[i] = Array.newClear(128);  // array has one slot per possible MIDI note
	});

	// load synths
	"Lib/SynthKeysSynths.scd".loadRelative();

	//////////////// functions ////////////////////////////////

	// generic buffer reading function
	fBufferRead = {
		arg sampleFile, absolutePath = false, channel = 0;
		f = SoundFile.new;
		sampleFile = if(absolutePath.not, {cfg.dataDir ++ sampleFile}, {sampleFile});
		if(f.openRead(sampleFile), {
			// prepare for loading mono samples
			if( f.numChannels == 1, {m = 0;}, {m = 1;});

			// the actual read of the buffer
			~bufferSK[channel].readChannel(sampleFile, channels: [0,m]);

			// done
			("\nSample read on channel" + channel ++ ":" + sampleFile).postln;
			loadFileSK[channel].string = sampleFile.subStr(sampleFile.findBackwards("/")+1);
			f.close;
		}, {
			("Soundfile" + sampleFile + "not found.").postln;
			loadFileSK[channel].string_("Soundfile not found!").stringColor_(Color.red);
	});
	};

	// stop all notes and restart output synths
	fInitOutput = {
		arg mode, kill = 0; // if kill=1 then also stop the Synth, otherwise assume this is being handled by InOut
		if(mode == 0,
			{ // stop actions
				16.do({ arg chan;
					notesArray[chan].size.do({arg n;
						if(notesArray[chan][n].notNil, {
							if(kill == 1, {notesArray[chan][n].set(\gate,0)});
							notesArray[chan][n] = nil;
						});
					});
					countPlay[chan] = 0;
					dispPlay[chan].states_([["0"]]);
				}); // 16.do
			},
			{ // start actions
		});
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


	//////////////// MIDI ////////////////////////////////

	OSCdef(\skNON, { |msg|
		var chan, note, vel, src;
		chan = msg[1];
		note = msg[2];
		vel = msg[3];
		src = msg[4];
		// [chan,note,vel,src].postln;

		// filter to trigger pitch material
		midiSrcIndex = cfg.midiFilterPitch.indexOf(src); // get the index of this MIDI src
		if(midiSrcIndex.notNil, { // check midi source
			if(cfg.midiFilterPitch[midiSrcIndex+1].indexOf(chan).notNil,
				{ // if midi chan is allowed
					if(notesPrev[chan].isNil, {notesPrev[chan] = note}); // glide support
					// start synth
					if( notesArray[chan][note].isNil, {
						notesArray[chan][note] = Synth(synthListMain[selectedSynthList[chan]], [
							\freq1, (note+cfg.semiShiftList[chan]).midicps(~tuningA), \gate, 1, \cutoffBus, cutoffBus[chan].index,
							\efxBus, efxBus[chan].index, \pitchBus, pitchBus[chan].index, \distBus, distBus[chan].index, \velocity, vel,
							\inChan1, fGetInChan.value()[0], \inChan2, fGetInChan.value()[1],
							\prevFreq, notesPrev[chan].midicps(~tuningA), \synthGainBus, synthGainBus[chan].index,
							\drumFilterBus, drumFilterBus[chan].index, \drumVolBus, drumVolBus[chan].index, \buffer, ~bufferSK[chan]
						], target: ~aBus.synthGroup);
						// count notes
						{ 	countPlay[chan] = countPlay[chan] + 1;
							dispPlay[chan].states_([[countPlay[chan].asString]]);
						}.defer();
					});
					notesPrev[chan] = note; // save this note for glide support
			});
		}); // filter to trigger pitch material

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
		midiSrcIndex = cfg.midiFilterPitch.indexOf(src); // get the index of this MIDI src
		if(midiSrcIndex.notNil, { // check midi source
			if(cfg.midiFilterPitch[midiSrcIndex+1].indexOf(chan).notNil, { // check if midi chan is allowed

				// switch off notes
				if( notesArray[chan][note].notNil, {
					notesArray[chan][note].set(\gate,0);
					notesArray[chan][note] = nil;
					// count note
					countPlay[chan] = max(0, countPlay[chan] - 1);
					{
						dispPlay[chan].states_([[countPlay[chan].asString]]);
					}.defer();
				});

			});
		}); // filter to trigger pitch material
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
		midiSrcIndex = cfg.midiFilterPitch.indexOf(src); // get the index of this MIDI src
		if(midiSrcIndex.notNil,{ // check midi source
			if(cfg.midiFilterPitch[midiSrcIndex+1].indexOf(chan).notNil, { // check whether midi chan is allowed

				16.do { |chan|
					if(controlList[chan]==1, {
						// ("Control channel" + chan + "ON, updating busses").postln;
						if( num==4, { drumVolBus[chan].set(val) }); // volume/distortion drumsets
						if( num==5, { drumFilterBus[chan].set(val) }); // filter drumsets
					});
				}

			});
		}); // filter to control pitch material
	},
	"/midi/control"
	).fix;

	//////////////// HID ////////////////////////////////

	OSCdef(\skEx3d, { |msg|
		var cookie = msg[1];
		var val = msg[2];
		// ("SynthKeys OSC RCV Ex3d: " ++ msg).postln;

		16.do { |chan|
			if(controlList[chan]==1, {
				// ("Control channel" + chan + "ON, updating busses").postln;
				case
				{ cookie == 16 }		// X-axis
				{ cutoffBus[chan].set(val/1024) }
				{ cookie == 17 } 		// Y-axis
				{ pitchBus[chan].set(val/1024) }
				{ cookie == 19 } 		// Rotation
				{ efxBus[chan].set(val/255) }
				{ cookie == 20 } 		// Slider
				{ distBus[chan].set(val/255) }
				;
			});
		}
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


	//////////////// GUI ////////////////////////////////

	~wSynthKeysArray = Window("SynthKeys" + cfg.version, Rect(30, (screenHeight - 660), 650, 600),false);
	~wSynthKeysArrayAvail = 1;

	tHeader = (StaticText(~wSynthKeysArray, Rect(20,15,600,50))
		.string_("MIDI Controlled SynthKeys")
		.canFocus_(false)
		.align_(\center)
		.font_(Font("Courier",37))
	);

	16.do { |chan|
		// labels
		tMidiChan[chan] = (StaticText(~wSynthKeysArray, Rect(20,81 + (chan*30),55,21))
			.string_(" Chan"+(chan+1)).font_(fontLabel).background_(Color.white.alpha_(0.7))
		);
		// drag destination for sample load into buffer
		loadFileSK[chan] = (DragSink(~wSynthKeysArray, Rect(270,80 + (chan*30),170,23))
			.canFocus_(false)
			.visible_(false)
			.string_("Drag file to load in buffer"+(chan+1))
			.font_(fontLabel)
			.align_(\center)
			.background_(Color.white)
			.stringColor_(Color.black)
			.receiveDragHandler_({ |dragsink|
				var dragTemp = View.currentDrag;
				if(dragTemp.isString, {dragTemp = dragTemp.split(nl)}); // if only one file is dragged, make it into an array with this trick
				dragTemp.postln;
				sampleKeysFile[chan] = dragTemp[0];
				fBufferRead.value(dragTemp[0], channel: chan, absolutePath: true);
			});
		);
		// dropdown for Synth select per MIDI channel
		pSynthList[chan] = (PopUpMenu(~wSynthKeysArray, Rect(90,80 + (chan*30),170,23))
			.font_(fontLabel).background_(Color.white).canFocus_(true)
			.items_(synthListMain)
			.action_({ |p|
				if( (p.item == "SampleKeys") || (p.item == "SampleKeysNoPitch") , { loadFileSK[chan].visible = true }, { loadFileSK[chan].visible = false });
				selectedSynthList[chan] = p.value;
			})
		);
		pSynthList[chan].valueAction_(selectedSynthList[chan]);

		dispPlay[chan] = (SmoothButton(~wSynthKeysArray, Rect(450,79 + (chan*30),50,23))
			.border_(1)
			.radius_(3)
			.canFocus_(false)
			.font_(fontButton)
			.background_(Color.white)
			.stringColor_(Color.blue)
			.states_([["0"]])
		);

		bTest[chan] = (SmoothButton(~wSynthKeysArray, Rect(510,79 + (chan*30),50,23))
			.border_(1)
			.radius_(3)
			.canFocus_(false)
			.font_(fontButton)
			.background_(Color.white)
			.stringColor_(Color.blue)
			.states_([["Play", Color.black, Color.white],["Stop", Color.white, Color.blue]])
			.action_({ |b|
				if(b.value == 1, {
					notesArray[chan][60] = Synth(synthListMain[selectedSynthList[chan]], [
						\freq1, 60.midicps(~tuningA), \gate, 1, \cutoffBus, cutoffBus[chan].index, \efxBus, efxBus[chan].index,
						\pitchBus, pitchBus[chan].index, \distBus, distBus[chan].index, \velocity, 127,
						\inChan1, fGetInChan.value()[0], \inChan2, fGetInChan.value()[1],
						\synthGainBus, synthGainBus[chan].index,
						\buffer, ~bufferSK[chan]
					], target: ~aBus.synthGroup);
				},{
					notesArray[chan][60].set(\gate,0);
					notesArray[chan][60] = nil;
				})
			})
		);

		bControl[chan] = (SmoothButton(~wSynthKeysArray, Rect(570,79 + (chan*30),50,23))
			.border_(1)
			.radius_(3)
			.canFocus_(false)
			.font_(fontButton)
			.background_(Color.white)
			.stringColor_(Color.blue)
			.states_([["CtrOFF", Color.black, Color.white],["CtrON", Color.white, Color.blue]])
			.action_({ |b| controlList[chan] = b.value })
		);

	};


	~wSynthKeysArray.view.keyDownAction_({
		arg view, char, modifiers, unicode, keycode;
		if(keycode == 53, { // esc
			localAddr.sendMsg("/panic");
		});
	});

	//~wSynthKeysArray.alwaysOnTop_(true);
	w = Window("dummy").front; w.close;

	// load InOut
	// if(~wControllers.isNil, {"Controllers.scd".loadRelative});
	// if(~wInOutAvail.isNil, {"InOut.scd".loadRelative});

	~wSynthKeysArray.background = Color.white;
	~wSynthKeysArray.front;

	~wSynthKeysArray.onClose_({
		OSCdef(\skNON).free; OSCdef(\skNOF).free; OSCdef(\skCC).free;
		OSCdef(\skEx3d).free; OSCdef(\skPanic).free; OSCdef(\skExtMidi).free;
		~wSynthKeysArrayAvail = nil;
		~bufferSK.do { |buffer| buffer.free} ;
		~bufferDrumSK0.do { |buffer| buffer.free; };
		~bufferDrumSK1.do { |buffer| buffer.free };
	});

	// initialize
	fInitOutput.value(1);

	// load samples
	16.do { |chan|
		if(cfg.sampleList[chan].notNil, {
			fBufferRead.value(cfg.sampleList[chan], channel: chan, absolutePath: false);
		});
	};

}); // wait for boot
)




