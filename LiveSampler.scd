// LiveSampler by Robert van Heumen 2011-2018.
// Based upon a setup in STEIM's LiSa combined with junXion.
// Tested with SC 3.8.0

// Dependencies:
//	GlobalVars.scd for global variable definitions
//	cfg.libDir/Patterns.scd for patterns definitions
//	cfg.libDir/SampleLists/~project.scd for sample load mapping
//	InOut.scd for audio routing
//	Controllers.scd for controller OSC data
//	LapisStatus.scd for status display (when enabled)

// Synth output can be send to any of these busses:
//	~aBus.outA 		volume controlled by Faderfox LV2 Mastervolume
//	~aBus.outB		volume controlled by volume pedal
//	~aBus.outBL		limited and volume controlled by volume pedal
//	~aBus.outMain		bypassing volume control, not recommended

// Configuration switches on LX
// 	RED2 switches between effects banks 1 and 2
//	RED3 switches the source of the effects between sample playback and input channels

(
s.waitForBoot({

	/////////////////////////////////////////////  variables //////////////////////////////////////

	// configuration settings
	var cfg = (
		zonePlayRelease: 0.02, // crossfade time when modulating zone start position
		playBufLag: 0.05, // lag in PlayBufCF & PlayBufAlt
		ampCurZoneFactor: 1.5, // amplification factor for current zone
		distortionMax: if(~distortionMax.notNil, {~distortionMax},{50}), // upper level for amplitude multiplication
		deBug: 0, // when set to 1 some debugging message will be postlined
		midiSrc: "MUL,EXT", // filtering allowed midi sources; comma-separated list with possibly:
							// MUL = Motu Ultralite, IAC1, IAC2, IAC3, LPK
		quantize:  0, // if value = 1 then loops of zone4 and zone3 will be quantized to cfg.bmp
		bpm: 120, // BPM in quantize case
		copySamples: 0, // set to 1 to activate sample copy on load - make sure the folder /Data/Samples/~project exists
		bufferViewPlayHeadFreq: 20, // freqency of playhead refresh in bufferView
		bufferViewRefreshFreq: 0.5, // frequency of bufferView refresh while recording
		bufferViewBlocksize: 512, // block size for reading soundfile in bufferview
		bufferViewDeferRead: 1, // defer of reading file in buffer after ~bufferLS.write
		sampleDir: "/Users/Robert/---data---/audio/samples/", // location of samples
		docDir: Document.dir++"/Lapis/", // current location
		libDir: "Data/", // library files location
		localAddr: NetAddr("127.0.0.1", 57120), // to send OSC to other SC programs
		dragEmptyBeforeLoad: 0, // 1: when dragging, empty buffer before load
	);

	// general
	var curZone = "0", curRecZone = "0", curZoneStart = 0, curZoneLen = 0, tCurZone;
	var fAmpCurZone, fBufferRead, fQuantize, fInitOutput, fInitLapisStatus, fSendLapisStatus, fGetInChanEfx;
	var fGetInChanSampling, fSetCurZone, fOctavesPitchshift, fGetInAttenuation, fGetInGroup;
	var onExternalInput = 0; // 0=effects on sample playback, 1=effects on input channels - switchable with red3 button on LX
	var sampleFile, sampleListLV1, sampleListLV2, sampleListLX;

	// remote control
	var button1disable = 0, button2disable = 0, localControl = 1;

	// GUI
	var dispPlay, dispRec, fCountZones, countRec = 0, countPlay = 0, dispEfx, countEfx = 0, loadFileA, loadFileB;
	var screenHeight = Window.screenBounds.height, screenWidth = Window.screenBounds.width;
	var dispBaseBtn, dispBaseBtn2, dispDisablePitch, dispDisableStartPos;
	var colorOff = Color.white;
	var fontLabel = Font(~font,10), fontButton = Font(~font,12), fontBufferView = Font("Helvetica", 10);

	// bufferView
	var bufferView = Array.newClear(6), curPlayHead = 0, curRecHead = 0, fileBufferView = SoundFile.new().dup(6);
	var bufferViewFolder = Archive.archiveDir ++ "/bufferViewTemp/", fDisplayBufferView, fRefreshBufferview;
	var bufferViewLab = Array.newClear(3);
	var bufferViewColors = [Color.white, Color.grey, Color.green(0.3), Color.black, Color.blue(1,0.3), Color.red];
	// background, grid, waveforms, playbackhead, selection, selection recording

	// zones
	var zone2 = (
		play1L: nil, play1R: nil, play1Act: 0, startPos1: 0,
		play1hf: nil, play1hfAct: 0, play1lf: nil, play1lfAct: 0,
		pitch: true
	);
	var zone3 = (
		play1: nil, play1Act: 0, startPos1: 0,
		stepsOffset1: Array.new(24), stepsOffset1tmp: Array.new(24),
		spModSpd1: 127, tModSP1: nil
	);
	var fModSP31;
	var zone4 = (play1: nil, play1Act: 0, startPos1: 0, play1hf: nil, play1hfAct: 0, play1lf: nil, play1lfAct: 0);
	var zone6 = (
		play1: Array.new(50), play1Act: 0, startPos1: 0, play1St: 0, play1Nbr: 0, play1Add: 0.2,
		disablePitch: 0, disableStartPos: 0, octavesPitchshift: 0,
		play2: nil, play2Act: 0, startPos2: 0, play3: nil, play3Act: 0, startPos3: 0,
		play4: nil, play4Act: 0, startPos4: 0, play5: nil, play5Act: 0, startPos5: 0, len5: 1,
		play6: nil, play6Act: 0, play6Pitch: 0, play7: nil, play7Act: 0, play8: nil, play8Act: 0
	);
	var zone8 = (play1: nil, play1Act: 0, startPos1: 0, tPatt1: nil, patt1: nil, patt1Def: 0, patt1Nbr: 0, sign1: 0);
	var f81jump, f81;
	var zone16 = (
		play1: nil, play1Act: 0,
		// tModSP1: nil, spMod1Spd: nil, spModOn1: 1,
		play2: nil, play2Act: 0, mode2: "",
		play3: nil, play3Act: 0, mode3: "",
		play4: nil, play4Act: 0, tModSP4: nil, spMod4Spd: nil, spModOn4: 1, stepsOffset1: Array.new(9),
	);
	var fModSP161, fModSP164;
	var zone17 = (
		play1: nil, play1Act: 0, patt1:nil, startPos1: 0, len1: 0.5, ampSine1: 0, ampPluck1: 0, dist1: 0, amp1: 0,
		tempoClock1: TempoClock.new(8);
	);
	var zone18 = (
		play1: nil, play1Act: 0, play2: nil, play2Act: 0,
	);
	var zoneRec = (
		ch1A: nil, ch1B: nil, ch2A: nil, ch2B: nil, dynOverflow: 0.05, dynLenMax: 30, dynLenMaxFrames: 30*~sRate,
		dyn1: nil, dyn1St: nil, dyn2: nil, dyn2St: nil, dyn3: nil, dyn3St:nil, dyn4: nil, dyn4St: nil, len1: 5,
		dyn1SavedLen: 5, dyn2SavedLen: 5, dyn3SavedLen: 5, dyn4SavedLen: 5
	);

	// just playing samples from green buttons keysets 2 & 3
	var dpIndex, diskPlay = (), diskPlayFile;

	// effects
	var efx1Act = 0, efxBank = 1, efx2Act = 0;

	/////////////////////////////////////////////  initialize variables //////////////////////////////////////

	// buffers
	~bufferLS = (
		// when changing these values: test thoroughly as some values might be interdependent, also connected with zoneRec
		mainLen: ~sRate * 400, processLen: ~sRate * 30,
		aStart: ~sRate * 0, aLen: ~sRate * 65, aTail: ~sRate * 5, bStart: ~sRate * 65, bLen: ~sRate * 85, bTail: ~sRate * 20,
		dyn1Start: ~sRate * 150, dyn1Len: ~sRate * 5, dyn2Start: ~sRate * 180, dyn2Len: ~sRate * 5,
		dyn3Start: ~sRate * 210,  dyn3Len: ~sRate * 5, dyn4Start: ~sRate * 240,  dyn4Len: ~sRate * 5
	);
	~mainBufLS = Buffer.alloc(s, ~bufferLS.mainLen, 2);
	~mtfBufLLS = Buffer.alloc(s, ~sRate*3,1);
	~mtfBufRLS = Buffer.alloc(s, ~sRate*3,1);

	// load specs and bus definitions
	~cfgLS = cfg;
	"Lib/LiveSamplerDefinitions.scd".loadRelative();

	// load global variables
	"GlobalVars.scd".loadRelative();

	// project specific
	if(~projectID == \lcm, { (Document.dir++"Loop-Copy-Mutate/LoadRecordings.scd").load() });
	// if(~projectID == \sh, { (Document.dir++"Shackle/Curves.scd").load() });

	zone8.patt1Def = 0; // default pattern
	zone8.patt1 = (cfg.libDir++"Patterns.scd").loadRelative[0][0]; // load pattern definitions
	~specLS.patt81 = Array.iota(zone8.patt1.size);
	~specLS.patt81 = ~specLS.patt81.resize(128, \step);

	// accomodate in case Arduino is not available
	if(~noArduino == 1, {
		"\nLiveSampler: Remapping dist61 because no Arduino availabe".postln;
		~specLS.dist61 = Env.new([cfg.distortionMax,1,1],[0.5,0.5], [\exp,\lin]);
	});

	// SP offset tables
	//zone3.stepsOffset1 = [0.11, 0.1, 0.5, 0.1, 0.11, 0.6, 0.5, 0.9, 0.91, 0.1, 0.9, 0.91, 0.1];
	zone3.stepsOffset1 = [0.11, 0.1, 0.11, 0.1, 0.11, 0.1, 0.11, 0.1];
	zone3.stepsOffset1tmp = zone3.stepsOffset1;
	zone16.stepsOffset1 = [0.0, 0.1, 0.0, 0.2, 0.1, 0.3, 0.5, 0.6, 0.9];

	// sample lists
	sampleFile = (cfg.libDir++"SampleLists/"++~project++".scd").loadRelative[0];
	sampleListLV1 = sampleFile[0];
	sampleListLV2 = sampleFile[1];
	sampleListLX = sampleFile[2]; // blue keysets 1, 2 & 3 and green keysets 1 & 2
	if(sampleFile.size > 3, { // sample list settings for diskPlay synth triggered by green keysets 2 & 3
		diskPlay.put('sampleList', sampleFile[3].sampleList);
		if(sampleFile[3].att.size >= diskPlay.sampleList.size,
			{diskPlay.put('att', sampleFile[3].att)},
			{diskPlay.put('att', 0.1.dup(diskPlay.sampleList.size))}); // defaults to 0.1 if not provided
		if(sampleFile[3].rel.size >= diskPlay.sampleList.size,
			{diskPlay.put('rel', sampleFile[3].rel)},
			{diskPlay.put('rel', 0.1.dup(diskPlay.sampleList.size))}); // defaults to 0.1 if not provided
		if(sampleFile[3].out.size >= diskPlay.sampleList.size,
			{diskPlay.put('out', sampleFile[3].out)},
			{diskPlay.put('out', ~aBus.outMain.dup(diskPlay.sampleList.size))}); // defaults to ~aBus.outMain if not provided
		if(sampleFile[3].lp.size >= diskPlay.sampleList.size,
			{diskPlay.put('lp', sampleFile[3].lp)},
			{diskPlay.put('lp', 1.dup(diskPlay.sampleList.size))}); // defaults to 1 if not provided
		if(sampleFile[3].lpfOn.size >= diskPlay.sampleList.size,
			{diskPlay.put('lpfOn', sampleFile[3].lpfOn)},
			{diskPlay.put('lpfOn', 1.dup(diskPlay.sampleList.size))}); // defaults to 1 if not provided
		if(sampleFile[3].rate.size >= diskPlay.sampleList.size,
			{diskPlay.put('rate', sampleFile[3].rate)},
			{diskPlay.put('rate', 1.dup(diskPlay.sampleList.size))}); // defaults to 1 if not provided
		if(sampleFile[3].start.size >= diskPlay.sampleList.size,
			{diskPlay.put('start', sampleFile[3].start)},
			{diskPlay.put('start', 0.dup(diskPlay.sampleList.size))}); // defaults to 0 if not provided
		if(sampleFile[3].gain.size >= diskPlay.sampleList.size,
			{diskPlay.put('gain', sampleFile[3].gain)},
			{diskPlay.put('gain', 1.dup(diskPlay.sampleList.size))}); // defaults to 1 if not provided
		diskPlay.put(\synthVar, Array.newClear(diskPlay.sampleList.size));
		diskPlay.put(\playing, Array.series(diskPlay.sampleList.size,0,0));
		diskPlay.put('buf', Array.newClear(diskPlay.sampleList.size));
		diskPlay.put('len', Array.newClear(diskPlay.sampleList.size));
		diskPlay.put('numChan', Array.newClear(diskPlay.sampleList.size));
		diskPlay.sampleList.size.do({ arg i;
			diskPlayFile = SoundFile.new;
			if(diskPlayFile.openRead(cfg.sampleDir ++ diskPlay.sampleList[i]), { // if file found
				diskPlay.numChan[i] = diskPlayFile.numChannels;
				diskPlay.buf[i] = Buffer.alloc(s, 32768,diskPlayFile.numChannels);
				diskPlay.len[i] = round(diskPlayFile.numFrames / ~sRate,0.01);
				diskPlayFile.close;
			},{ // file not found
				("diskPlay file:" + cfg.sampleDir ++ diskPlay.sampleList[i] + "not found.").postln;
			});
		});

	}, {diskPlay.put('sampleList', [])});

	// load synths
	~zoneRecLS = zoneRec;
	"Lib/LiveSamplerSynths.scd".loadRelative();
	s.sync;

	///////////////////////////////////////////// HID data acquisition //////////////////////////////////////

	OSCdef(\lisaEx3d, {|msg|
		var cookie = msg[1];
		var val = msg[2];

		// X-axis: control start position, panning, filter freq and restart zones
		if(cookie==16, {
			// update busses
			~cBusLS.ex3dProBusX62.set(~specLS.pan62.at(val)); // panning
			~cBusLS.ex3dProBusX63.set(~specLS.pan63.at(val));
			~cBusLS.ex3dProBusX64.set(~specLS.pan64.at(val));
			~cBusLS.ex3dProBusX65.set(val);
			~cBusLS.ex3dProBusX66.set(val/1024); // filter frequency synth6play6
			~cBusLS.ex3dProBusX67.set(val/1024); // freq TBall synth6play7

			// re-trigger zones
			if(zone6.disableStartPos == 0, {
				// trigger button 1, main action
				if(zone6.play1Act == 1,  {
					// set start position
					zone6.startPos1 = 1 - (val / 1023);
					if(cfg.deBug == 1, { ["61 reg",
						(~specLS.startPos61.map(zone6.startPos1)/~sRate),
						(~specLS.startPos61Plus1.map(zone6.startPos1 + 0.03)/~sRate),
						(~specLS.startPos61Plus2.map(zone6.startPos1 + 0.03)/~sRate),
						(~specLS.startPos61Plus1.map(zone6.startPos1 + 0.06)/~sRate),
						(~specLS.startPos61Plus2.map(zone6.startPos1 + 0.06)/~sRate)
					].postln});

					// update curZoneStart
					if(curZone == "61", {fSetCurZone.value("61", ~specLS.startPos61.map(zone6.startPos1), nil);});

					// release and play
					zone6.play1.size.do({arg i;
						zone6.play1[i].release(cfg.zonePlayRelease);
						if(i == 0, {
							zone6.play1[i] =
							Synth(\zone6play1, [
								\gate, 1,
								\lenBus, ~cBusLS.ex3dProR.index,
								\startPosition, zone6.startPos1,
								\distBus, ~cBusLS.ex3dProS.index,
								\pitchBus, ~cBusLS.ex3dProYpitch.index
							], target: ~aBus.synthGroup);
						},{
							zone6.play1[i] =
							Synth(\zone6play1Plus, [
								\gate, 1,
								\lenBus, ~cBusLS.ex3dProR.index,
								\startPosition, zone6.startPos1 + (0.03 * i),
								\distBus, ~cBusLS.ex3dProS.index,
								\pitchBus, ~cBusLS.ex3dProYpitch.index
							], target: ~aBus.synthGroup);
						});
					});
				});

				// side button 2, HPF
				if(zone6.play2Act == 1, {
					// set start position
					zone6.startPos2 = 1 - (val / 1023);
					if(cfg.deBug == 1, {["62 hpf", (~specLS.startPos62.map(zone6.startPos2)/~sRate)].postln});

					// update curZoneStart
					if(curZone == "62", {fSetCurZone.value("62", ~specLS.startPos62.map(zone6.startPos2), nil)});

					// release and play
					zone6.play2.release(cfg.zonePlayRelease);
					zone6.play2 =
					Synth(\zone6play2, [
						\gate, 1,
						\lenBus, ~cBusLS.ex3dProR.index,
						\startPosition, zone6.startPos2,
						\distBus, ~cBusLS.ex3dProS.index,
						\ffBus, ~cBusLS.ex3dProY.index,
						\panBus, ~cBusLS.ex3dProBusX62.index
					], target: ~aBus.synthGroup);
				});

				// top button 5, LPF
				if(zone6.play3Act == 1, {
					// set start position
					zone6.startPos3 = 1 - (val / 1023);
					if(cfg.deBug == 1, {["63 lpf", (~specLS.startPos63.map(zone6.startPos3)/~sRate)].postln});

					// update curZoneStart
					if(curZone == "63", {fSetCurZone.value("63", ~specLS.startPos63.map(zone6.startPos3), nil)});

					// release and play
					zone6.play3.release(cfg.zonePlayRelease);
					zone6.play3 =
					Synth(\zone6play3, [
						\gate, 1,
						\lenBus, ~cBusLS.ex3dProR.index,
						\startPosition, zone6.startPos3,
						\distBus, ~cBusLS.ex3dProS.index,
						\ffBus, ~cBusLS.ex3dProY.index,
						\panBus, ~cBusLS.ex3dProBusX63.index
					], target: ~aBus.synthGroup);
				});

				// base button 9 (BB)
				if(zone6.play4Act == 1, {
					// set start position
					zone6.startPos4 = 1 - (val / 1023);
					if(cfg.deBug == 1, {["64 ultrashort", (~specLS.startPos64.map(zone6.startPos4)/~sRate)].postln});

					// update curZoneStart
					if(curZone == "64", {fSetCurZone.value("64", ~specLS.startPos64.map(zone6.startPos4), nil)});

					// release and play
					zone6.play4.release(cfg.zonePlayRelease);
					zone6.play4 =
					Synth(\zone6play4, [
						\gate, 1,
						\lenBus, ~cBusLS.ex3dProR.index,
						\startPosition, zone6.startPos4,
						\distBus, ~cBusLS.ex3dProS.index,
						\pitchBus, ~cBusLS.ex3dProY.index,
						\panBus, ~cBusLS.ex3dProBusX64.index
					], target: ~aBus.synthGroup);
				});
			});
		});

		// Y-axis: control pitch, filter freq and gravity for TBall
		if(cookie==17, {

			// Y axis for extreme pitch
			if(((zone6.disablePitch == 0) && (localControl == 1)), { // only if not disabled with joystick button 12 or via remote control
				~cBusLS.ex3dProYpitch.set(~specLS.pitch61.at(1 - (val/1023)));
			});
			// Y axis for other control
			~cBusLS.ex3dProY.set(1 - (val/1023));
			// set pitch factor for synth6.play6
			zone6.play6Pitch = -5 + ((1 - (val/1023)) * 10);
		});

		// Rotation: control length, filter resonance and freq
		if(cookie==19, {

			~cBusLS.ex3dProR.set(val / 255);

			// length for whoosh
			zone6.len5 = ~specLS.len65.at(val / 255);

			// update curZoneLen
			if(curZone == "61", {fSetCurZone.value("61", nil, ~specLS.len61.map(val / 255) * ~sRate)});
			if(curZone == "62", {fSetCurZone.value("62", nil, ~specLS.len62.map(val / 255) * ~sRate)});
			if(curZone == "63", {fSetCurZone.value("63", nil, ~specLS.len63.map(val / 255) * ~sRate)});
			if(curZone == "64", {fSetCurZone.value("64", nil, ~specLS.len64.at(val / 255) * ~sRate)});
		});

		// Slider: control distortion and TBall ring
		if(cookie==20, {

			~cBusLS.ex3dProS.set(val / 255);
			zone6.amp5 = 0.4*(1-(val/255));
		});

		// trigger button 1
		if(cookie==4, {
			if(val==0, {
				if(button1disable == 0, { // only if not disabled by OSC (f.e. when controlling other players' setups)
					// update curZoneStart & curZoneLen
					~cBusLS.ex3dProR.get({arg val;
						fSetCurZone.value(
							"61",								// id current zone
							~specLS.startPos61.map(zone6.startPos1),	// start current zone
							~specLS.len61.map(val) * ~sRate);			// length current zone
					});

					// store trigger start
					zone6.play1St = SystemClock.seconds;

					// start and reset multiple-voices-variables
					if(zone6.play1Act == 0, {
						zone6.play1Act = 1;
						zone6.play1Nbr = 0;
						zone6.play1 = zone6.play1.add(nil);
						zone6.play1[0] =
						Synth(\zone6play1, [
							\gate, 1,
							\lenBus, ~cBusLS.ex3dProR.index,
							\startPosition, zone6.startPos1,
							\distBus, ~cBusLS.ex3dProS.index,
							\pitchBus, ~cBusLS.ex3dProYpitch.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+");
					});
				});
			},
			{ // if clicked really short, start more zone6.play1's on the note off event
				if((SystemClock.seconds - zone6.play1St <= zone6.play1Add), { // start an extra voice
					'zone6play1 voice added'.postln;
					zone6.play1Nbr = zone6.play1Nbr + 1;
					zone6.play1 = zone6.play1.add(nil);
					zone6.play1[zone6.play1Nbr] =
					Synth(\zone6play1Plus, [
						\gate, 1,
						\lenBus, ~cBusLS.ex3dProR.index,
						\startPosition, zone6.startPos1 + (0.03 * zone6.play1Nbr),
						\distBus, ~cBusLS.ex3dProS.index,
						\pitchBus, ~cBusLS.ex3dProYpitch.index
					], target: ~aBus.synthGroup);
					fCountZones.value("P+");
				},{ // release all voices
					zone6.play1.size.do({arg i;
						("zone6play1 release voice" + i.asString).postln;
						zone6.play1[i].release(cfg.zonePlayRelease);
						fCountZones.value("P-");
					});
					zone6.play1Act = 0;
					zone6.play1 = Array.new(50);
				});
			});
		});

		// side button 2, HPF
		if(cookie==5, {
			if(val==0, {
				if(button2disable == 0, {// only if not disabled by OSC (f.e. when controlling other players' setups)
					// update curZoneStart & curZoneLen
					~cBusLS.ex3dProR.get({arg val;
						fSetCurZone.value(
							"62",								// id current zone
							~specLS.startPos62.map(zone6.startPos2),	// start current zone
							~specLS.len62.map(val) * ~sRate);			// length current zone
					});
					// start zone
					zone6.play2Act = 1;
					zone6.play2 =
					Synth(\zone6play2, [
						\gate, 1,
						\lenBus, ~cBusLS.ex3dProR.index,
						\startPosition, zone6.startPos2,
						\distBus, ~cBusLS.ex3dProS.index,
						\ffBus, ~cBusLS.ex3dProY.index,
						\panBus, ~cBusLS.ex3dProBusX62.index
					], target: ~aBus.synthGroup);
					fCountZones.value("P+");
				});
			},{
				zone6.play2.release(cfg.zonePlayRelease);
				zone6.play2Act = 0;
				fCountZones.value("P-");
			});
		});

		// top button 5, LPF
		if(cookie==8, {
			if(val==0, {
				// update curZoneStart & curZoneLen
				~cBusLS.ex3dProR.get({arg val;
					fSetCurZone.value(
						"63",								// id current zone
						~specLS.startPos63.map(zone6.startPos3),	// start current zone
						~specLS.len63.map(val) * ~sRate);			// length current zone
				});

				// start zone
				zone6.play3Act = 1;
				zone6.play3 =
				Synth(\zone6play3, [
					\gate, 1,
					\lenBus, ~cBusLS.ex3dProR.index,
					\startPosition, zone6.startPos3,
					\distBus, ~cBusLS.ex3dProS.index,
					\ffBus, ~cBusLS.ex3dProY.index,
					\panBus, ~cBusLS.ex3dProBusX63.index
				], target: ~aBus.synthGroup);
				fCountZones.value("P+");
			},{
				zone6.play3.release(cfg.zonePlayRelease);
				zone6.play3Act = 0;
				fCountZones.value("P-");
			});
		});

		// base button 9 ultrashort
		if(cookie==12, {
			if(val==0, {
				// update curZoneStart & curZoneLen
				~cBusLS.ex3dProR.get({arg val;
					fSetCurZone.value(
						"64",								// id current zone
						~specLS.startPos64.map(zone6.startPos4),	// start current zone
						~specLS.len64.at(val) * ~sRate);			// length current zone
				});

				if(zone6.play4Act==0, { // start zone
					zone6.play4Act = 1;
					zone6.play4 =
					Synth(\zone6play4, [
						\gate, 1,
						\lenBus, ~cBusLS.ex3dProR.index,
						\startPosition, zone6.startPos4,
						\distBus, ~cBusLS.ex3dProS.index,
						\pitchBus, ~cBusLS.ex3dProY.index,
						\panBus, ~cBusLS.ex3dProBusX64.index
					], target: ~aBus.synthGroup);
					fCountZones.value("P+");
					{dispBaseBtn.background_(~colorOn); fSendLapisStatus.value("BB",1)}.defer();
				},{ // stop zone
					zone6.play4.release(cfg.zonePlayRelease);
					zone6.play4Act = 0;
					fCountZones.value("P-");
					{dispBaseBtn.background_(colorOff); fSendLapisStatus.value("BB",0)}.defer();
				});
			});
		});

		// base button 7 whoosh
		// if(cookie==10, {
		// 	if(val==0, {
		// 		// // update curZoneStart & curZoneLen
		// 		// ~cBusLS.ex3dProR.get({arg val;
		// 		// 	fSetCurZone.value(
		// 		// 		"65",								// id current zone
		// 		// 		~specLS.startPos64.map(zone6.startPos5),	// start current zone
		// 		// 	~specLS.len65.at(val) * ~sRate);			// length current zone
		// 		// });
		//
		// 		zone6.play5 = Synth(\whoosh, [\ampScale,1,\lenScale,zone6.len5, \lowBus, ~cBusLS.ex3dProY.index,
		// 			\highBus, ~cBusLS.ex3dProY.index,\decBus, ~cBusLS.ex3dProBusX65.index
		// 		], target: ~aBus.synthGroup);
		// 		fCountZones.value("P+");
		// 		// {dispBaseBtn2.background_(~colorOn); fSendLapisStatus.value("BB2",1)}.defer();
		// 		{
		// 			fCountZones.value("P-");
		// 			// dispBaseBtn2.background_(colorOff); fSendLapisStatus.value("BB2",0)
		// 		}.defer(0.1);
		// 	});
		// });

		// base button 7 fftDrone
		if(cookie==10, {
			if(val==0, {
				if(zone6.play8Act==0, { // start zone
					zone6.play8Act = 1;
					zone6.play8 =
					Synth(\fftDrone, [
						\distBus, ~cBusLS.ex3dProS.index,
						\gate, 1,
						\cutoffBus, ~cBusLS.ex3dProBusX67.index,
						\pulseBus, ~cBusLS.ex3dProR.index
					], target: ~aBus.synthGroup);
					fCountZones.value("P+");
				},{ // stop zone
					zone6.play8.set(\gate,0);
					zone6.play8Act = 0;
					fCountZones.value("P-");
				});
			});
		});

		// top button 3 synth
		if(cookie==6, {
			if(val==0, {
				if(zone6.play6Act==0, { // start zone
					("Zone6play6 pitch:" + (36 + zone6.play6Pitch)).postln;
					zone6.play6Act = 1;
					zone6.play6 =
					Synth(\synth6play6, [
						\freq1, (36 + zone6.play6Pitch).midicps,
						\distBus, ~cBusLS.ex3dProS.index,
						\gate, 1,
						\cutoffBus, ~cBusLS.ex3dProBusX66.index,
						\resBus, ~cBusLS.ex3dProR.index,
						\pitchBus, ~cBusLS.ex3dProY.index,
						\ampmod, 0.7
					], target: ~aBus.synthGroup);
					fCountZones.value("P+");
				},{ // stop zone
					zone6.play6.set(\gate,0);
					zone6.play6Act = 0;
					fCountZones.value("P-");
				});
			});
		});

		// top button 4 synth
		if(cookie==7, {
			if(val==0, {
				if(zone6.play7Act==0, { // start zone
					zone6.play7Act = 1;
					zone6.play7 =
					Synth(\synth6play7, [
						\gate, 1,
						\freqBus, ~cBusLS.ex3dProBusX67.index,
						\gravAmpBus, ~cBusLS.ex3dProY.index,
						\cutoffBus, ~cBusLS.ex3dProR.index,
						\ringBus, ~cBusLS.ex3dProS.index
					], target: ~aBus.synthGroup);
					fCountZones.value("P+");
				},{ // stop zone
					zone6.play7.set(\gate,0);
					zone6.play7Act = 0;
					fCountZones.value("P-");
				});
			});
		});

		// button 6: amplify current zone
		if(cookie==9, {
			if(val==0, {{
				fAmpCurZone.value(~mainBufLS, curZoneStart, curZoneLen, cfg.ampCurZoneFactor);
				"\nAmplifying current zone...".postln;
			}.defer();});
		});

		// disable startPos modulatie
		if(cookie==14, {
			if(val==0, {
				if(zone6.disableStartPos == 1,  {
					zone6.disableStartPos = 0;
					{dispDisableStartPos.background_(colorOff); fSendLapisStatus.value("SP",0)}.defer();
				},{
					zone6.disableStartPos = 1;
					{dispDisableStartPos.background_(~colorOn); fSendLapisStatus.value("SP",1)}.defer();
				});
			});
		});

		// disable pitch modulatie
		if(cookie==15, {
			if(val==0, {
				if(zone6.disablePitch == 1,  {
					zone6.disablePitch = 0;
					{dispDisablePitch.background_(colorOff); fSendLapisStatus.value("PT",0)}.defer();
				},{
					zone6.disablePitch = 1;
					{dispDisablePitch.background_(~colorOn); fSendLapisStatus.value("PT",1)}.defer();
				});
			});
		});

		// base buton 10 - switch resolution extreme pitchshift
		if(cookie==13, {
			if(val==0, {
				if(zone6.octavesPitchshift == 1,  {
					zone6.octavesPitchshift = 0;
					{dispBaseBtn2.background_(colorOff); fSendLapisStatus.value("OS",0)}.defer();
				},{
					zone6.octavesPitchshift = 1;
					{dispBaseBtn2.background_(~colorOn); fSendLapisStatus.value("OS",1)}.defer();
				});
				// initialize pitchshift range
				fOctavesPitchshift.value();
			});
		});

		// panic button
		if((cookie == 11) && (val==0),{cfg.localAddr.sendMsg("/panic")});
	},
	"/hid/ex3d"
	).fix;


	///////////////////////////////////////////// MIDI data acquisition //////////////////////////////////////

	OSCdef(\lisaNON, { |msg|
		var chan, note, vel, src;
		chan = msg[1];
		note = msg[2];
		vel = msg[3];
		src = msg[4].asString;
		// [chan,note,vel, src].postln;

		// only process midi if coming from the right source
		if(cfg.midiSrc.find(src).notNil, {
			// rec/load triggers //////////////////////////////////////////////////////////////////////////

			// MIDI Channel 1: LX red buttons keyset 1 & 2 Record & Config
			if((chan==0 && (note <= 23)), {
				case
				{note == 1} // switching to efx bank 2
				{
					efxBank = 2;
					"LiveSampler: Switch to efx bank 2 (multiTapFreeze & ampPitchFollower)".postln;
				}
				{note == 2} // switching efx source to input channels
				{
					onExternalInput = 1;
					"LiveSampler: Switch efx source to input channels".postln;
				}
				{note == 6} // record from inChan1 in A
				{
					zoneRec.ch1A = Synth(\zoneRec,
						[\gate, 1, \chan1, fGetInChanSampling.value(~aBus.inChan1)[0], \chan2, fGetInChanSampling.value(~aBus.inChan1)[1],
							\start, ~bufferLS.aStart, \len, ~bufferLS.aLen / ~sRate, \recZone, 1, \attenuation, fGetInAttenuation.value()], target: fGetInGroup.value());
					fSetCurZone.value("1", mode: "REC");
					fCountZones.value("R+");
					"LiveSampler: Record from inChan1 in A".postln;
				}
				{note == 7}  // record from inChan1 in B
				{
					zoneRec.ch1B = Synth(\zoneRec,
						[\gate, 1, \chan1, fGetInChanSampling.value(~aBus.inChan1)[0], \chan2, fGetInChanSampling.value(~aBus.inChan1)[1],
							\start, ~bufferLS.bStart, \len, ~bufferLS.bLen / ~sRate, \recZone, 2, \attenuation, fGetInAttenuation.value()], target: fGetInGroup.value());
					fSetCurZone.value("2", mode: "REC");
					fCountZones.value("R+");
					"LiveSampler: Record from inChan1 in B".postln;
				}
				{note == 8}  // record from inChan2 in A
				{
					zoneRec.ch2A = Synth(\zoneRec,
						[\gate, 1, \chan1, fGetInChanSampling.value(~aBus.inChan2)[0], \chan2, fGetInChanSampling.value(~aBus.inChan2)[1],
							\start, ~bufferLS.aStart, \len, ~bufferLS.aLen / ~sRate, \recZone, 3, \attenuation, fGetInAttenuation.value()], target: fGetInGroup.value());
					fSetCurZone.value("3", mode: "REC");
					fCountZones.value("R+");
					"LiveSampler: Record from inChan2 in A".postln;
				}
				{note == 9}  // record from inChan2 in B
				{
					zoneRec.ch2B = Synth(\zoneRec,
						[\gate, 1,  \chan1, fGetInChanSampling.value(~aBus.inChan2)[0], \chan2, fGetInChanSampling.value(~aBus.inChan2)[1],
							\start, ~bufferLS.bStart, \len, ~bufferLS.bLen / ~sRate, \recZone, 4, \attenuation, fGetInAttenuation.value()], target: fGetInGroup.value());
					fSetCurZone.value("4", mode: "REC");
					fCountZones.value("R+");
					"LiveSampler: Record from inChan2 in B".postln;
				}
				{note == 4} // dynamic length recording from inChan1
				{
					zoneRec.dyn1 = Synth(\zoneRecDyn,
						[\gate, 1, \chan1, fGetInChanSampling.value(~aBus.inChan1)[0], \chan2, fGetInChanSampling.value(~aBus.inChan1)[1],
							\start, ~bufferLS.dyn1Start, \len, zoneRec.dynLenMax, \recZone, 5, \attenuation, fGetInAttenuation.value()],
						target: fGetInGroup.value());
					fSetCurZone.value("5", mode: "REC");
					fCountZones.value("R+");
					zoneRec.dyn1St = SystemClock.seconds; // save start time to on NOF lenght can be determined
					"LiveSampler: DynRec from inChan1".postln;
				}
				{note == 5} // dynamic length recording from inChan2
				{
					zoneRec.dyn2 = Synth(\zoneRecDyn,
						[\gate, 1, \chan1, fGetInChanSampling.value(~aBus.inChan2)[0], \chan2, fGetInChanSampling.value(~aBus.inChan2)[1],
							\start, ~bufferLS.dyn2Start, \len, zoneRec.dynLenMax, \recZone, 6, \attenuation, fGetInAttenuation.value()],
						target: fGetInGroup.value());
					fSetCurZone.value("6", mode: "REC");
					fCountZones.value("R+");
					zoneRec.dyn2St = SystemClock.seconds; // save start time to on NOF lenght can be determined
					"LiveSampler: DynRec from inChan2".postln;
				}
				{note == 10} // dynamic length recording from inChan1
				{
					zoneRec.dyn3 = Synth(\zoneRecDyn,
						[\gate, 1, \chan1, fGetInChanSampling.value(~aBus.inChan1)[0], \chan2, fGetInChanSampling.value(~aBus.inChan1)[1],
							\start, ~bufferLS.dyn3Start, \len, zoneRec.dynLenMax, \recZone, 7, \attenuation, fGetInAttenuation.value()],
						target: fGetInGroup.value());
					fSetCurZone.value("7", mode: "REC");
					fCountZones.value("R+");
					zoneRec.dyn3St = SystemClock.seconds; // save start time to on NOF lenght can be determined
					"LiveSampler: DynRec from inChan1".postln;
				}
				{note == 11} // dynamic length recording from inChan2
				{
					zoneRec.dyn4 = Synth(\zoneRecDyn,
						[\gate, 1, \chan1, fGetInChanSampling.value(~aBus.inChan2)[0], \chan2, fGetInChanSampling.value(~aBus.inChan2)[1],
							\start, ~bufferLS.dyn4Start, \len, zoneRec.dynLenMax, \recZone, 8, \attenuation, fGetInAttenuation.value()],
						target: fGetInGroup.value());
					fSetCurZone.value("8", mode: "REC");
					fCountZones.value("R+");
					zoneRec.dyn4St = SystemClock.seconds; // save start time to on NOF lenght can be determined
					"LiveSampler: DynRec from inChan2".postln;
				}
				{note == 16} // dynamic length 1 SP modulation off
				{
					// zone16.spModOn1 = 0;
					// "Dynamic length mod zone16play1 OFF".postln;
				}
				{note == 17} // switch to backwards play
				{
					zone16.mode2 = "bw";
					"LiveSampler: Playback mode zone16play2 set to 'backwards'".postln;
				}
				{note == 22} // switch to backwards play
				{
					zone16.mode3 = "bw";
					"LiveSampler: Playback mode zone16play3 set to 'backwards'".postln;
				}
				{note == 23} // dynamic length 4 SP modulation off
				{
					zone16.spModOn4 = 0;
					"LiveSampler: Length modulation zone16play4 set to 'OFF'".postln;
				}
				{note == 18} // pitch zone2 off
				{
					zone2.pitch = false;
					"LiveSampler: Pitch change zone2 set to 'OFF'".postln;
				}
				; // case
			});

			// MIDI Channel 1: LX blue buttons Load
			if((chan==0 && (note >= 24) && (note <= 59) && sampleListLX.at(note).notNil), {
				if(sampleListLX.at((note.asString++'out').asSymbol).notNil, {
					if(sampleListLX.at((note.asString++'out').asSymbol) == "A", {
						fBufferRead.value(sampleListLX.at(note), ~bufferLS.aLen, ~bufferLS.aStart)
					}, {
						fBufferRead.value(sampleListLX.at(note), ~bufferLS.bLen, ~bufferLS.bStart)
					});
				}, {
					fBufferRead.value(sampleListLX.at(note), ~bufferLS.aLen, ~bufferLS.aStart);
				});
			});

			// MIDI Channel 1: LX green buttons Load
			if((chan==0 && (note >= 60) && (note <= 71) && sampleListLX.at(note).notNil), {
				fBufferRead.value(sampleListLX.at(note), ~bufferLS.bLen, ~bufferLS.bStart);
			});

			// MIDI Channel 1: LX green keyset 2 & 3 diskPlay synth to play sample loops
			if((chan==0 && (note >= 72) && (note <= 95)), {
				dpIndex = note - 72; // diskPlay array index
				if(diskPlay.buf[dpIndex].notNil, { // a sample is defined for this index and file is found
					if(diskPlay.playing[dpIndex] == 0, { // if not playing, start the synth
						("\nStart diskPlay"++diskPlay.numChan[dpIndex]++":" + diskPlay.sampleList[dpIndex] + "\n\t\tfrom" +
							diskPlay.start[dpIndex] + "to" + diskPlay.len[dpIndex] + "secs" ).postln;
						~doc.diskPlay;

						// cue soundfile into a buffer
						diskPlay.buf[dpIndex].close;
						diskPlay.buf[dpIndex].cueSoundFile(cfg.sampleDir++diskPlay.sampleList[dpIndex], diskPlay.start[dpIndex] * ~sRate);

						// to save sample files to backup location
						if(cfg.copySamples == 1, {
							("cp '" ++ cfg.sampleDir++diskPlay.sampleList[dpIndex] ++ "' " ++
								cfg.docDir ++ "/" ++ cfg.libDir ++ "Samples/" ++ ~project ++ "/").postln;
							("cp '" ++ cfg.sampleDir++diskPlay.sampleList[dpIndex] ++ "' " ++
								cfg.docDir ++ "/" ++ cfg.libDir ++ "Samples/" ++ ~project ++ "/").unixCmd;
						});

						// start playback, passing the buffer
						diskPlay.synthVar[dpIndex] = Synth("diskPlay"++diskPlay.numChan[dpIndex], [
							\gate, 1, \buf, diskPlay.buf[dpIndex],
							\att, diskPlay.att[dpIndex], \rel, diskPlay.rel[dpIndex], \lp, diskPlay.lp[dpIndex],
							\distBus, ~cBusLS.midiLV2Fader12.index, \volBus, ~cBusLS.midiLV2Fader16.index,
							\ffBus, ~cBusLS.midiLV2Fader15.index, \rateBus, ~cBusLS.midiLV2Fader14.index,
							\rateModBus, ~cBusLS.midiLV2Fader13.index, \lpfOn, diskPlay.lpfOn[dpIndex], \rate, diskPlay.rate[dpIndex],
							\effectSendBus, ~cBusLS.midiLV2Fader11.index, \gain, diskPlay.gain[dpIndex], \out, diskPlay.out[dpIndex]
						], target: ~aBus.synthGroup);
						diskPlay.playing[dpIndex] = 1;
						fCountZones.value("P+", 1);
						diskPlayFile.close;
					});
				});
			});

			// MIDI Channel 3: LX bottom row Copy Buffer (darkgreen 1-4 and black 1-4)
			if((chan==2), {
				case
				// bottom row
				{note==12}
				{
					("LiveSampler: Copy processbuffer into samplebuffer: "
						++(~bufferLS.aStart/~sRate)++"-"++((~bufferLS.aStart + ~bufferLS.processLen)/~sRate)++"s").postln;
					~processBuf.copyData(~mainBufLS, ~bufferLS.aStart);
					if(~showBufferView == 1, {fDisplayBufferView.value("A")});
				}
				{note==14}
				{
					("LiveSampler: Copy processbuffer into samplebuffer: "++((~bufferLS.aStart + ~bufferLS.processLen)/~sRate)++"-"
						++((~bufferLS.aStart + (2*~bufferLS.processLen))/~sRate)++"s").postln;
					~processBuf.copyData(~mainBufLS, ~bufferLS.aStart + ~bufferLS.processLen);
					if(~showBufferView == 1, {fDisplayBufferView.value("A")});
				}
				{note==16}
				{
					("LiveSampler: Copy processbuffer into samplebuffer: "
						++(~bufferLS.bStart/~sRate)++"-"++((~bufferLS.bStart + ~bufferLS.processLen)/~sRate)++"s").postln;
					~processBuf.copyData(~mainBufLS, ~bufferLS.bStart);
					if(~showBufferView == 1, {fDisplayBufferView.value("B")});
				}
				{note==17}
				{
					("LiveSampler: Copy processbuffer into samplebuffer: "++((~bufferLS.bStart + ~bufferLS.processLen)/~sRate)++"-"
						++((~bufferLS.bStart + (2*~bufferLS.processLen))/~sRate)++"s").postln;
					~processBuf.copyData(~mainBufLS, ~bufferLS.bStart + ~bufferLS.processLen);
					if(~showBufferView == 1, {fDisplayBufferView.value("B")});
				}
				{note==19} // save dynrec1&3 buffer
				{
					"LiveSampler: Save dynrec1&3 buffer".postln;
					~mainBufLS.write(thisProcess.platform.recordingsDir++"/LiveSamplerDynRec1.aif",
						startFrame: ~sRate*150, numFrames: ~sRate*30);
					~cBusLS.lenBus161.get({arg val; zoneRec.dyn1SavedLen = val});
					~mainBufLS.write(thisProcess.platform.recordingsDir++"/LiveSamplerDynRec3.aif",
						startFrame: ~sRate*210, numFrames: ~sRate*30);
					~cBusLS.lenBus163.get({arg val; zoneRec.dyn3SavedLen = val});
				}
				{note==21} // save dynrec2&4 buffer
				{
					"LiveSampler: Save dynrec2&4 buffer".postln;
					~mainBufLS.write(thisProcess.platform.recordingsDir++"/LiveSamplerDynRec2.aif",
						startFrame: ~sRate*180, numFrames: ~sRate*30);
					~cBusLS.lenBus162.get({arg val; zoneRec.dyn2SavedLen = val});
					~mainBufLS.write(thisProcess.platform.recordingsDir++"/LiveSamplerDynRec4.aif",
						startFrame: ~sRate*240, numFrames: ~sRate*30);
					~cBusLS.lenBus164.get({arg val; zoneRec.dyn4SavedLen = val});
				}
				{note==23} // recall dynrec1&3 buffer
				{
					// arg sampleList, bufferLen, bufferStart, relativePath = 1, tempFile;
					"LiveSampler: Recall dynrec1&3 buffer".postln;
					fBufferRead.value([thisProcess.platform.recordingsDir++"/LiveSamplerDynRec1.aif"], ~sRate*30, ~sRate*150, 0);
					~cBusLS.lenBus161.set(zoneRec.dyn1SavedLen);
					fBufferRead.value([thisProcess.platform.recordingsDir++"/LiveSamplerDynRec3.aif"], ~sRate*30, ~sRate*210, 0);
					~cBusLS.lenBus163.set(zoneRec.dyn3SavedLen);
				}
				{note==24} // recall dynrec2&4 buffer
				{
					"LiveSampler: Recall dynrec2&4 buffer".postln;
					fBufferRead.value([thisProcess.platform.recordingsDir++"/LiveSamplerDynRec2.aif"], ~sRate*30, ~sRate*180, 0);
					~cBusLS.lenBus162.set(zoneRec.dyn2SavedLen);
					fBufferRead.value([thisProcess.platform.recordingsDir++"/LiveSamplerDynRec4.aif"], ~sRate*30, ~sRate*240, 0);
					~cBusLS.lenBus164.set(zoneRec.dyn4SavedLen);
				}
				; // case
			});

			// MIDI Channel 10: LV2 Load
			if((chan==9 && sampleListLV2.at(note).notNil), {
				fBufferRead.value(sampleListLV2.at(note), ~bufferLS.bLen, ~bufferLS.bStart);
			});

			// MIDI Channel 13: LV1 Load
			if((chan==12 && sampleListLV1.at(note).notNil), {
				fBufferRead.value(sampleListLV1.at(note), ~bufferLS.aLen, ~bufferLS.aStart);
			});
		}); // only process midi if coming from the right source
	},
	"/midi/noteOn"
	).fix;

	OSCdef(\lisaNOF, { |msg|
		var chan, note, vel, src;
		chan = msg[1];
		note = msg[2];
		vel = msg[3];
		src = msg[4].asString;
		//	[chan,note,vel, src].postln;

		// only process midi if coming from the right source
		if(cfg.midiSrc.find(src).notNil, {
			// rec/load triggers //////////////////////////////////////////////////////////////////////////
			// MIDI Channel 1: LX red buttons keyset 1 Record & Config
			if((chan==0 && (note <= 23)), {
				case
				{note == 1} // switching to efx bank 1
				{
					efxBank = 1;
					"LiveSampler: Switch to efx bank 1 (deciMate & deLay)".postln;
				}
				{note == 2} // switching delay to sample playback
				{
					onExternalInput = 0;
					"LiveSampler: Switch efx source to sample playback".postln;
				}
				{(note == 6)}
				{
					zoneRec.ch1A.free;
					if(~showBufferView == 1, {fDisplayBufferView.value("A")});
					fCountZones.value("R-");
				}
				{(note == 7)}
				{
					zoneRec.ch1B.free;
					if(~showBufferView == 1, {fDisplayBufferView.value("B")});
					fCountZones.value("R-");
				}
				{(note == 8)}
				{
					zoneRec.ch2A.free;
					if(~showBufferView == 1, {fDisplayBufferView.value("A")});
					fCountZones.value("R-");
				}
				{(note == 9)}
				{
					zoneRec.ch2B.free;
					if(~showBufferView == 1, {fDisplayBufferView.value("B")});
					fCountZones.value("R-");
				}
				{(note == 4)}
				{
					~cBusLS.lenBus161.set(SystemClock.seconds - zoneRec.dyn1St);
					["Lenght DynRec1",(SystemClock.seconds - zoneRec.dyn1St)].postln;

					zoneRec.len1 = (SystemClock.seconds - zoneRec.dyn1St) * ~sRate;
					case
					{ zoneRec.len1 < ( (~bufferLS.dyn2Start - ~bufferLS.dyn1Start) / 4 ) }
					{
						~mainBufLS.copyData(~mainBufLS, ~bufferLS.dyn1Start + zoneRec.len1, ~bufferLS.dyn1Start, zoneRec.len1);
						~mainBufLS.copyData(~mainBufLS, ~bufferLS.dyn1Start + (2*zoneRec.len1), ~bufferLS.dyn1Start, zoneRec.len1);
						~mainBufLS.copyData(~mainBufLS, ~bufferLS.dyn1Start + (3*zoneRec.len1), ~bufferLS.dyn1Start, zoneRec.len1);
					}
					{ zoneRec.len1 < ( (~bufferLS.dyn2Start - ~bufferLS.dyn1Start) / 2 ) }
					{ ~mainBufLS.copyData(~mainBufLS, ~bufferLS.dyn1Start + zoneRec.len1 - 5, ~bufferLS.dyn1Start, zoneRec.len1) }
					;

					zoneRec.dyn1.free;
					if(~showBufferView == 1, {fDisplayBufferView.value("C1")});
					fCountZones.value("R-");

					// update  curZoneLen
					if(curZone == "161", {~cBusLS.lenBus161.get({arg val; curZoneLen = val * ~sRate})});
				}
				{(note == 5)}
				{
					~cBusLS.lenBus162.set(SystemClock.seconds - zoneRec.dyn2St);
					["Lenght DynRec2",(SystemClock.seconds - zoneRec.dyn2St)].postln;
					zoneRec.dyn2.free;
					if(~showBufferView == 1, {fDisplayBufferView.value("C2")});
					fCountZones.value("R-");

					// update curZoneLen
					if(curZone == "162", {~cBusLS.lenBus162.get({arg val; curZoneLen = val * ~sRate})});

					if(zone16.play2Act == 1, {
						zone16.play2.release;
						zone16.play2 =
						Synth("zone16play2"++zone16.mode2, [
							\gate, 1,
							\ampBus, ~cBusLS.midiLV2Fader6.index,
							\distBus, ~cBusLS.midiLV1CrossFader.index,
							\lenBus, ~cBusLS.lenBus162.index,
							\pitchRangeBus, ~cBusLS.midiLV2KnobD1.index,
							\pitchSelectBus, ~cBusLS.midiLV2KnobD2.index
						], target: ~aBus.synthGroup);
					});
				}
				{(note == 10)}
				{
					~cBusLS.lenBus163.set(SystemClock.seconds - zoneRec.dyn3St);
					["Lenght DynRec3",(SystemClock.seconds - zoneRec.dyn3St)].postln;
					zoneRec.dyn3.free;
					if(~showBufferView == 1, {fDisplayBufferView.value("C3")});
					fCountZones.value("R-");

					// update curZoneLen
					if(curZone == "163", {~cBusLS.lenBus163.get({arg val; curZoneLen = val * ~sRate})});

					if(zone16.play3Act == 1, {
						zone16.play3.release;
						zone16.play3 =
						Synth("zone16play3"++zone16.mode3, [
							\gate, 1,
							\ampBus, ~cBusLS.midiLV2Fader7.index,
							\distBus, ~cBusLS.midiLV1CrossFader.index,
							\lenBus, ~cBusLS.lenBus163.index,
							\pitchRangeBus, ~cBusLS.midiLV2KnobD1.index,
							\pitchSelectBus, ~cBusLS.midiLV2KnobD2.index
						], target: ~aBus.synthGroup);
					});
				}
				{(note == 11)}
				{
					~cBusLS.lenBus164.set(SystemClock.seconds - zoneRec.dyn4St);
					["Lenght DynRec4",(SystemClock.seconds - zoneRec.dyn4St)].postln;
					zoneRec.dyn4.free;
					if(~showBufferView == 1, {fDisplayBufferView.value("C4")});
					fCountZones.value("R-");

					// update curZoneLen
					if(curZone == "164", {~cBusLS.lenBus164.get({arg val; curZoneLen = val * ~sRate})});
				}
				{note == 16} // dynamic length 1 SP modulation on
				{
					// zone16.spModOn1 = 1;
					// "Dynamic length mod zone16play1 ON".postln;
				}
				{note == 17} // switch to forwards-backwards play
				{
					zone16.mode2 = "";
					"LiveSampler: Playback mode zone16play2 set to 'forwards-backwards'".postln;
				}
				{note == 22} // switch to forwards-backwards play
				{
					zone16.mode3 = "";
					"LiveSampler: Playback mode zone16play3 set to 'forwards-backwards'".postln;
				}
				{note == 23} // dynamic length 4 SP modulation on
				{
					zone16.spModOn4 = 1;
					"LiveSampler: Length modulation zone16play4 set to 'ON'".postln;
				}
				{note == 18} // pitch zone2 on
				{
					zone2.pitch = true;
					"LiveSampler: Pitch change zone2 set to 'ON'".postln;
				}
				; // case
			});

			// MIDI Channel 1: LX green keyset 2 & 3: diskPlay synth to play sample loops
			if((chan==0 && (note >= 72) && (note <= 95)), {
				dpIndex = note - 72;
				if(diskPlay.playing[dpIndex].notNil, { // a sample is defined for this index
					if(diskPlay.playing[dpIndex] == 1, {
						diskPlay.playing[dpIndex] = 0;
						diskPlay.synthVar[dpIndex].set(\gate, 0);
						fCountZones.value("P-", 1);
					});
				});
			});
		}); // only process midi if coming from the right source
	},
	"/midi/noteOff"
	).fix;

	OSCdef(\lisaCCLPK, { |msg|
		var chan, num, value, src;
		chan = msg[1];
		num = msg[2];
		value = msg[3];
		src = msg[4].asString;

		// only process midi if coming from the right source
		if(src == "LPK", {
			// ["OSC: lisaCCLPK",chan,num,value, src].postln;
			// diskPlay controls //////////////////////////////////////////////////////////////////////////
			// volume
			if((chan==0 && num==3), {
				~cBusLS.midiLV2Fader16.set(value);
			});
			// filter frequency
			if((chan==0 && num==2), {
				~cBusLS.midiLV2Fader15.set(value);
			});
			// rate
			if((chan==0 && num==1), {
				~cBusLS.midiLV2Fader14.set(value);
			});
			// rate modulation depth
			if((chan==0 && num==0), {
				~cBusLS.midiLV2Fader13.set(value);
			});
			// distortion
			if((chan==0 && num==7), {
				~cBusLS.midiLV2Fader12.set(value);
			});
			// effect level
			if((chan==0 && num==6), {
				~cBusLS.midiLV2Fader11.set(value);
			});
		});
	},
	"/midi/control"
	).fix;


	OSCdef(\lisaCC, { |msg|
		var chan, num, value, src;
		chan = msg[1];
		num = msg[2];
		value = msg[3];
		src = msg[4].asString;

		// only process midi if coming from the right source
		if(cfg.midiSrc.find(src).notNil, {
			// ["OSC: lisaCC",chan,num,value, src].postln;
			// main volume control //////////////////////////////////////////////////////////////////////////
			if((chan==11 && num==17), {
				~cBusLS.midiLV2KnobMasterVol.set(value);
			});
			// diskPlay controls //////////////////////////////////////////////////////////////////////////
			// volume
			if((chan==11 && num==15), {
				~cBusLS.midiLV2Fader16.set(value);
			});
			// filter frequency
			if((chan==11 && num==14), {
				~cBusLS.midiLV2Fader15.set(value);
			});
			// rate
			if((chan==11 && num==13), {
				~cBusLS.midiLV2Fader14.set(value);
			});
			// rate modulation depth
			if((chan==11 && num==12), {
				~cBusLS.midiLV2Fader13.set(value);
			});
			// distortion
			if((chan==11 && num==11), {
				~cBusLS.midiLV2Fader12.set(value);
			});
			// effect level
			if((chan==11 && num==10), {
				~cBusLS.midiLV2Fader11.set(value);
			});

			// efx volume control //////////////////////////////////////////////////////////////////////////
			// volume and trigger efx1: deciMate or multiTapFreeze
			if((chan==14 && num==2), {
				// set volume bus
				~cBusLS.midiLV1Fader3.set(~specLS.efxVol.at(value));

				if(value >= 0.01, { // activate efx1
					if(efx1Act == 0, {
						if(efxBank == 1,
							{
								~doc.efx1_1;
								~aBus.efx1Synth = Synth(\deciMate, [\gate,1,
									\paramBus, ~cBusLS.midiLV1KnobB1.index,
									\decBus, ~cBusLS.midiLV1KnobB2.index,
									\ffBus, ~cBusLS.midiLV1KnobB3.index,
									\volBus, ~cBusLS.midiLV1Fader3.index,
									\onExternalInput, onExternalInput,
									\inChan1, fGetInChanEfx.value()[0],
									\inChan2, fGetInChanEfx.value()[1]
								], target: ~aBus.efxGroup);
							},
							{
								~doc.efx1_2;
								~aBus.efx1Synth = Synth(\multiTapFreeze, [\gate,1,
									\decayBus, ~cBusLS.midiLV1KnobB1.index,
									\volBus, ~cBusLS.midiLV1Fader3.index,
									\ffBus, ~cBusLS.midiLV1KnobB2.index,
									\freezeBus, ~cBusLS.midiLV1KnobB3.index,
									\distBus, ~cBusLS.midiLV1CrossFader.index,
									\onExternalInput, onExternalInput,
									\inChan1, fGetInChanEfx.value()[0],
									\inChan2, fGetInChanEfx.value()[1]
								], target: ~aBus.efxGroup);
						});
						efx1Act = 1;
						fCountZones.value("E+");
					});
				},{ // deactivate efx1
					if(efx1Act == 1,  {
						~aBus.efx1Synth.set(\gate,0);
						efx1Act = 0;
						fCountZones.value("E-");
					});
				});
			});
			// volume and trigger efx2: deLay or ampPitchFollow
			if((chan==14 && num==3), {
				// set volume bus
				~cBusLS.midiLV1Fader4.set(~specLS.efxVol.at(value));

				if(value >= 0.01, { // activate efx2
					if(efx2Act == 0, {
						if(efxBank == 1,
							{
								~doc.efx2_1;
								~aBus.efx2Synth = Synth(\deLay, [\gate, 1,
									\volBus, ~cBusLS.midiLV1Fader4.index,
									\delayTimeBus, ~cBusLS.midiLV1KnobB1.index,
									\inLevelBus, ~cBusLS.midiLV1KnobB3.index,
									\tremSpeedBus, ~cBusLS.midiLV1KnobB2.index,
									\onExternalInput, onExternalInput,
									\inChan1, fGetInChanEfx.value()[0],
									\inChan2, fGetInChanEfx.value()[1]
								],
								target: ~aBus.efxGroup);
							},
							{
								~doc.efx2_2;
								~aBus.efx2Synth = Synth(\ampPitchFollow, [\gate, 1,
									\volBus, ~cBusLS.midiLV1Fader4.index,
									\onExternalInput, onExternalInput,
									\mixBus, ~cBusLS.midiLV1KnobB1.index,
									\inChan1, fGetInChanEfx.value()[0],
									\inChan2, fGetInChanEfx.value()[1]
								],
								target: ~aBus.efxGroup);

						});
						efx2Act = 1;
						fCountZones.value("E+");
					});
				},{ // deactivate efx2
					if(efx2Act == 1,{
						~aBus.efx2Synth.set(\gate,0);
						efx2Act = 0;
						fCountZones.value("E-");
					});
				});
			});
			// parameter control efx1 & efx2
			if((chan==12 && num==60), {
				~cBusLS.midiLV1KnobB1.set(value);
				zone17.tempoClock1.tempo = ~specLS.tempo171.map(value);
			});
			if((chan==12 && num==77), {
				~cBusLS.midiLV1KnobB2.set(value);
			});
			if((chan==12 && num==78), {
				~cBusLS.midiLV1KnobB3.set(value);
			});

			// Zone 2 controls //////////////////////////////////////////////////////////////////////////
			// volume and trigger
			if((chan==14 && num==0), {
				// set volume bus
				~cBusLS.midiLV1Fader1.set(value);

				// trigger zone
				if(value >= 0.01,{ // start zone
					if(zone2.play1Act == 0, {
						~doc.zone2;
						zone2.play1Act = 1;
						zone2.play1L =
						Synth(\zone2play1L, [
							\gate, 1,
							\lenBus, ~cBusLS.midiLV1KnobA1.index,
							\startPosition, zone2.startPos1,
							\ampBus, ~cBusLS.midiLV1Fader1.index,
							\distBus, ~cBusLS.midiLV1CrossFader.index,
							\ffBus, ~cBusLS.midiLV1KnobMasterVol.index,
							\resetPosBus, ~cBusLS.midiLV1JoyX.index,
							\mixBus, ~cBusLS.midiLV1KnobA2.index
						], target: ~aBus.synthGroup);
						zone2.play1R =
						Synth(\zone2play1R, [
							\gate, 1,
							\lenBus, ~cBusLS.midiLV1KnobA1.index,
							\startPosition, zone2.startPos1,
							\ampBus, ~cBusLS.midiLV1Fader1.index,
							\distBus, ~cBusLS.midiLV1CrossFader.index,
							\pitchBus, ~cBusLS.midiLV1JoyY.index,
							\ffBus, ~cBusLS.midiLV1KnobMasterVol.index,
							\resetPosBus, ~cBusLS.midiLV1JoyX.index,
							\mixBus, ~cBusLS.midiLV1KnobA2.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+", 2);

						// update curZoneStart & curZoneLen
						~cBusLS.midiLV1KnobA1.get({arg val;
							fSetCurZone.value(
								"21",								// id current zone
								~specLS.startPos21L.map(zone2.startPos1),	// start current zone
								~specLS.len21L.at(val));					// length current zone
						});
					});
				},{ // stop zone
					if(zone2.play1Act == 1, {
						zone2.play1L.release;
						zone2.play1R.release;
						zone2.play1Act = 0;
						fCountZones.value("P-", 2);
					});
				});
				// trigger zone hf
				if(value >= 0.97, { // start zone
					if(zone2.play1hfAct == 0, {
						zone2.play1hfAct = 1;
						zone2.play1hf =
						Synth(\zone2play1hf, [
							\gate, 1,
							\lenBus, ~cBusLS.midiLV1KnobA1.index,
							\startPosition, zone2.startPos1,
							\distBus, ~cBusLS.midiLV1CrossFader.index,
							\resetPosBus, ~cBusLS.midiLV1JoyX.index,
							\mixBus, ~cBusLS.midiLV1KnobA2.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+", 1);
					});
				},{ // stop zone
					if(zone2.play1hfAct == 1, {
						zone2.play1hf.release;
						zone2.play1hfAct = 0;
						fCountZones.value("P-", 1);
					});
				});
				// trigger zone lf
				if(value >= 0.99, { // start zone
					if(zone2.play1lfAct == 0, {
						zone2.play1lfAct = 1;
						zone2.play1Lf =
						Synth(\zone2play1lf, [
							\gate, 1,
							\lenBus, ~cBusLS.midiLV1KnobA1.index,
							\startPosition, zone2.startPos1,
							\distBus, ~cBusLS.midiLV1CrossFader.index,
							\resetPosBus, ~cBusLS.midiLV1JoyX.index,
							\mixBus, ~cBusLS.midiLV1KnobA2.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+", 1);
					});
				},{ // stop zone
					if(zone2.play1lfAct == 1,{
						zone2.play1Lf.release;
						zone2.play1lfAct = 0;
						fCountZones.value("P-", 1);
					});
				});
			});
			// length
			if((chan==12 && num==40), {
				~cBusLS.midiLV1KnobA1.set(value);
				zone17.len1 = value;

				// update curZoneLen
				if(curZone == "21", {fSetCurZone.value("21", nil, ~specLS.len21L.at(value))});
			});
			// mix
			if((chan==12 && num==57), {
				~cBusLS.midiLV1KnobA2.set(value);
			});
			// absolute regstart
			if((chan==14 && num==1), {
				// set start position
				zone2.startPos1 = value;

				if(zone2.play1Act == 1, { // re-trigger zone
					zone2.play1L.release(cfg.zonePlayRelease);
					zone2.play1R.release(cfg.zonePlayRelease);
					zone2.play1L =
					Synth(\zone2play1L, [
						\gate, 1,
						\lenBus, ~cBusLS.midiLV1KnobA1.index,
						\startPosition, zone2.startPos1,
						\ampBus, ~cBusLS.midiLV1Fader1.index,
						\distBus, ~cBusLS.midiLV1CrossFader.index,
						\ffBus, ~cBusLS.midiLV1KnobMasterVol.index,
						\resetPosBus, ~cBusLS.midiLV1JoyX.index,
						\mixBus, ~cBusLS.midiLV1KnobA2.index
					], target: ~aBus.synthGroup);
					zone2.play1R =
					Synth(\zone2play1R, [
						\gate, 1,
						\lenBus, ~cBusLS.midiLV1KnobA1.index,
						\startPosition, zone2.startPos1,
						\ampBus, ~cBusLS.midiLV1Fader1.index,
						\distBus, ~cBusLS.midiLV1CrossFader.index,
						\pitchBus, ~cBusLS.midiLV1JoyY.index,
						\ffBus, ~cBusLS.midiLV1KnobMasterVol.index,
						\resetPosBus, ~cBusLS.midiLV1JoyX.index,
						\mixBus, ~cBusLS.midiLV1KnobA2.index
					], target: ~aBus.synthGroup);

					// update curZoneStart
					if(curZone == "21", {fSetCurZone.value("21", ~specLS.startPos21L.map(zone2.startPos1), nil)});
				});
				if(zone2.play1hfAct == 1, { // re-trigger zone
					zone2.play1hf.release(cfg.zonePlayRelease);
					zone2.play1hf =
					Synth(\zone2play1hf, [
						\gate, 1,
						\lenBus, ~cBusLS.midiLV1KnobA1.index,
						\startPosition, zone2.startPos1,
						\distBus, ~cBusLS.midiLV1CrossFader.index,
						\resetPosBus, ~cBusLS.midiLV1JoyX.index,
						\mixBus, ~cBusLS.midiLV1KnobA2.index
					], target: ~aBus.synthGroup);
				});
				if(zone2.play1lfAct == 1, { // re-trigger zone
					zone2.play1Lf.release(cfg.zonePlayRelease);
					zone2.play1Lf =
					Synth(\zone2play1lf, [
						\gate, 1,
						\lenBus, ~cBusLS.midiLV1KnobA1.index,
						\startPosition, zone2.startPos1,
						\distBus, ~cBusLS.midiLV1CrossFader.index,
						\resetPosBus, ~cBusLS.midiLV1JoyX.index,
						\mixBus, ~cBusLS.midiLV1KnobA2.index
					], target: ~aBus.synthGroup);
				});
			});
			// distortion
			if((chan==14 && num==19), {
				~cBusLS.midiLV1CrossFader.set(value);
				zone17.dist1 = value;
			});
			// pitch
			if((chan==12 && num==0 && zone2.pitch), {
				~cBusLS.midiLV1JoyY.set(value);
			});
			// SP offset
			if((chan==12 && num==20), {
				~cBusLS.midiLV1JoyX.set(value);
			});
			// filterfreq
			if((chan==14 && num==17), {
				~cBusLS.midiLV1KnobMasterVol.set(value);
			});

			// Zone 3 controls //////////////////////////////////////////////////////////////////////////
			// volume and trigger
			if((chan==14 && num==4), {
				// set volume bus
				~cBusLS.midiLV1Fader5.set(value);
				// trigger zone
				if(value >= 0.01, { // start zone
					if(zone3.play1Act == 0, {
						~doc.zone3;
						zone3.play1Act = 1;
						zone3.play1 =
						Synth(\zone3play1, [
							\gate, 1,
							\lenBus, ~cBusLS.midiLV1KnobC1.index,
							\startPosition, zone3.startPos1,
							\ampBus, ~cBusLS.midiLV1Fader5.index,
							\distBus, ~cBusLS.midiLV1CrossFader.index,
							\pitchBus, ~cBusLS.midiLV1KnobD1.index,
							\panSpdBus, ~cBusLS.midiLV1KnobD2.index,
							\resetPosBus, ~cBusLS.spModBus31.index,
							\ffBus, ~cBusLS.midiLV1KnobC2.index,
							\ampModSpdBus, ~cBusLS.midiLV1Fader8.index,
							\ampModOnBus, ~cBusLS.ampModOnBus31.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+");

						// start sample pointer modulation
						zone3.tModSP1 = Task(fModSP31).play;

						// update curZoneStart & curZoneLen
						~cBusLS.midiLV1KnobC1.get({arg val;
							fSetCurZone.value(
								"31",								// id current zone
								~specLS.startPos21L.map(zone3.startPos1),	// start current zone
								~specLS.len31.at(val));					// length current zone
						});
					});
				},{ // stop zone
					if(zone3.play1Act == 1, {
						zone3.play1.release;
						fCountZones.value("P-");
						zone3.tModSP1.stop;
						zone3.play1Act = 0;
					});
				});
			});
			// abs regstart
			if((chan==14 && num==5), {
				// set start position
				zone3.startPos1 = value;
				if(zone3.play1Act == 1, { // re-trigger zone
					zone3.play1.release(cfg.zonePlayRelease);
					zone3.play1 =
					Synth(\zone3play1, [
						\gate, 1,
						\lenBus, ~cBusLS.midiLV1KnobC1.index,
						\startPosition, zone3.startPos1,
						\ampBus, ~cBusLS.midiLV1Fader5.index,
						\distBus, ~cBusLS.midiLV1CrossFader.index,
						\pitchBus, ~cBusLS.midiLV1KnobD1.index,
						\panSpdBus, ~cBusLS.midiLV1KnobD2.index,
						\resetPosBus, ~cBusLS.spModBus31.index,
						\ffBus, ~cBusLS.midiLV1KnobC2.index,
						\ampModSpdBus, ~cBusLS.midiLV1Fader8.index,
						\ampModOnBus, ~cBusLS.ampModOnBus31.index
					], target: ~aBus.synthGroup);
					// update curZoneStart
					if(curZone == "31", {fSetCurZone.value("31", ~specLS.startPos21L.map(zone3.startPos1), nil)});
				});
			});
			// length
			if((chan==12 && num==80), {
				~cBusLS.midiLV1KnobC1.set(value);
				// update curZoneLen
				if(curZone == "31", {
					fSetCurZone.value("31", nil, ~specLS.len31.at(value))
				});
			});
			// speed SP offset modulation
			if((chan==14 && num==6), {
				zone3.spModSpd1 = 127 - (value*127);
				if(cfg.deBug == 1, {
					("zone3play wait in sec:"+~specLS.spModSpd31.at(zone3.spModSpd1)).postln;
					("zone3play BPM:"+ (60 / ~specLS.spModSpd31.at(zone3.spModSpd1))).postln;
				});
				// restart zone3 sample pointer modulation task
				if(zone3.play1Act == 1, {zone3.tModSP1.stop; zone3.tModSP1 = Task(fModSP31).play;});
			});
			// speed pan
			if((chan==12 && num==117), {
				~cBusLS.midiLV1KnobD2.set(value);
			});
			// filter freq
			if((chan==12 && num==97), {
				~cBusLS.midiLV1KnobC2.set(value);
			});
			// pitch
			if((chan==12 && num==100), {
				~cBusLS.midiLV1KnobD1.set(value);
			});
			// speed amp mod
			if((chan==14 && num==7), {
				if(value < 0.95,
					{~cBusLS.ampModOnBus31.set(1); ~cBusLS.midiLV1Fader8.set(value);}, // switch on amp modulation and send value
					{~cBusLS.ampModOnBus31.set(0);}); // switch off amp modulation
			});

			// Zone 4 controls //////////////////////////////////////////////////////////////////////////
			// volume and trigger
			if((chan==11 && num==0), {
				// set volume bus
				~cBusLS.midiLV2Fader1.set(value);
				// trigger zone
				if(value >= 0.01, { // start zone
					if(zone4.play1Act == 0, {
						~doc.zone4;
						zone4.play1Act = 1;
						zone4.play1 =
						Synth(\zone4play1, [
							\gate, 1,
							\lenBus, ~cBusLS.midiLV2KnobA1.index,
							\startPosition, zone4.startPos1,
							\ampBus, ~cBusLS.midiLV2Fader1.index,
							\distBus, ~cBusLS.midiLV2CrossFader.index,
							\pitchBus, ~cBusLS.midiLV2JoyY.index,
							\pitch2Bus, ~cBusLS.midiLV2JoyY2.index,
							\ffBus, ~cBusLS.midiLV2JoyX.index,
							\ffSpeedBus, ~cBusLS.midiLV2KnobA2.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+", 1);
						// update curZoneStart & curZoneLen
						~cBusLS.midiLV2KnobA1.get({arg val;
							fSetCurZone.value(
								"41",								// id current zone
								~specLS.startPos21L.map(zone4.startPos1),	// start current zone
								val * ~sRate);						// length current zone
						});
					});
				},{ // stop zone
					if(zone4.play1Act == 1, {
						zone4.play1.release;
						zone4.play1Act = 0;
						fCountZones.value("P-", 1);
					});
				});
				// trigger zone hf
				if(value >= 0.97, { // start zone
					if(zone4.play1hfAct == 0, {
						zone4.play1hfAct = 1;
						zone4.play1hf =
						Synth(\zone4play1hf, [
							\gate, 1,
							\lenBus, ~cBusLS.midiLV2KnobA1.index,
							\startPosition, zone4.startPos1,
							\distBus, ~cBusLS.midiLV2CrossFader.index,
						], target: ~aBus.synthGroup);
						fCountZones.value("P+", 1);
					});
				},{ // stop zone
					if(zone4.play1hfAct == 1, {
						zone4.play1hf.release;
						zone4.play1hfAct = 0;
						fCountZones.value("P-", 1);
					});
				});
				// trigger zone lf
				if(value >= 0.99, { // start zone
					if(zone4.play1lfAct == 0, {
						zone4.play1lfAct = 1;
						zone4.play1lf =
						Synth(\zone4play1lf, [
							\gate, 1,
							\lenBus, ~cBusLS.midiLV2KnobA1.index,
							\startPosition, zone4.startPos1,
							\distBus, ~cBusLS.midiLV2CrossFader.index,
						], target: ~aBus.synthGroup);
						fCountZones.value("P+", 1);
					});
				},{ // stop zone
					if(zone4.play1lfAct == 1, {
						zone4.play1lf.release;
						zone4.play1lfAct = 0;
						fCountZones.value("P-", 1);
					});
				});
			});
			// length
			if((chan==9 && num==40), {
				// set bus
				~cBusLS.midiLV2KnobA1.set(~specLS.len41.at(value*127));
				// zone17.len1 = value;

				if(cfg.deBug == 1, {("zone4 speed" + ((~specLS.len41.at(value*127) / 60) * cfg.bpm)).postln;});
				if(zone4.play1Act == 1, { // re-trigger zone
					zone4.play1.release(cfg.zonePlayRelease);
					zone4.play1 =
					Synth(\zone4play1, [
						\gate, 1,
						\lenBus, ~cBusLS.midiLV2KnobA1.index,
						\startPosition, zone4.startPos1,
						\ampBus, ~cBusLS.midiLV2Fader1.index,
						\distBus, ~cBusLS.midiLV2CrossFader.index,
						\pitchBus, ~cBusLS.midiLV2JoyY.index,
						\pitch2Bus, ~cBusLS.midiLV2JoyY2.index,
						\ffBus, ~cBusLS.midiLV2JoyX.index,
						\ffSpeedBus, ~cBusLS.midiLV2KnobA2.index
					], target: ~aBus.synthGroup);
					// update curZoneLen
					if(curZone == "41", {fSetCurZone.value("41", nil, ~specLS.len41.at(value*127) * ~sRate)});
				});
				if(zone4.play1hfAct == 1, { // re-trigger zone
					zone4.play1hf.release(cfg.zonePlayRelease);
					zone4.play1hf =
					Synth(\zone4play1hf, [
						\gate, 1,
						\lenBus, ~cBusLS.midiLV2KnobA1.index,
						\startPosition, zone4.startPos1,
						\distBus, ~cBusLS.midiLV2CrossFader.index,
					], target: ~aBus.synthGroup);
				});
				if(zone4.play1lfAct == 1, { // re-trigger zone
					zone4.play1lf.release(cfg.zonePlayRelease);
					zone4.play1lf =
					Synth(\zone4play1lf, [
						\gate, 1,
						\lenBus, ~cBusLS.midiLV2KnobA1.index,
						\startPosition, zone4.startPos1,
						\distBus, ~cBusLS.midiLV2CrossFader.index,
					], target: ~aBus.synthGroup);
				});
			});
			if((chan==9 && num==57), {
				// set bus
				~cBusLS.midiLV2KnobA2.set(value);
			});
			// absolute regstart
			if((chan==11 && num==1), {
				// set start position
				zone4.startPos1 = value;
				if(zone4.play1Act == 1, { // re-trigger zone
					zone4.play1.release(cfg.zonePlayRelease);
					zone4.play1 =
					Synth(\zone4play1, [
						\gate, 1,
						\lenBus, ~cBusLS.midiLV2KnobA1.index,
						\startPosition, zone4.startPos1,
						\ampBus, ~cBusLS.midiLV2Fader1.index,
						\distBus, ~cBusLS.midiLV2CrossFader.index,
						\pitchBus, ~cBusLS.midiLV2JoyY.index,
						\pitch2Bus, ~cBusLS.midiLV2JoyY2.index,
						\ffBus, ~cBusLS.midiLV2JoyX.index,
						\ffSpeedBus, ~cBusLS.midiLV2KnobA2.index
					], target: ~aBus.synthGroup);
					// update curZoneStart
					if(curZone == "41", {
						fSetCurZone.value("41", ~specLS.startPos21L.map(zone4.startPos1), nil);
					});
				});
				if(zone4.play1hfAct == 1, { // re-trigger zone
					zone4.play1hf.release(cfg.zonePlayRelease);
					zone4.play1hf =
					Synth(\zone4play1hf, [
						\gate, 1,
						\lenBus, ~cBusLS.midiLV2KnobA1.index,
						\startPosition, zone4.startPos1,
						\distBus, ~cBusLS.midiLV2CrossFader.index,
					], target: ~aBus.synthGroup);
				});
				if(zone4.play1lfAct == 1, { // re-trigger zone
					zone4.play1lf.release(cfg.zonePlayRelease);
					zone4.play1lf =
					Synth(\zone4play1lf, [
						\gate, 1,
						\lenBus, ~cBusLS.midiLV2KnobA1.index,
						\startPosition, zone4.startPos1,
						\distBus, ~cBusLS.midiLV2CrossFader.index,
					], target: ~aBus.synthGroup);
				});
			});
			// distortion
			if((chan==11 && num==19), {
				~cBusLS.midiLV2CrossFader.set(value);
				// zone17.dist1 = value;
			});
			// pitch
			if((chan==9 && num==0), {
				~cBusLS.midiLV2JoyY.set(value);
			});
			if((chan==9 && num==17), {
				~cBusLS.midiLV2JoyY2.set(value);
			});
			// filter freq
			if((chan==9 && num==20), {
				~cBusLS.midiLV2JoyX.set(value);
			});
			if((chan==9 && num==37), {
				~cBusLS.midiLV2JoyX.set(value);
			});

			// Zone 8 controls //////////////////////////////////////////////////////////////////////////
			// volume and trigger
			if((chan==11 && num==2), {
				// set volume bus
				~cBusLS.midiLV2Fader3.set(value);
				// trigger zone
				if(value >= 0.01, { // start zone
					if(zone8.play1Act == 0, {
						~doc.zone8;
						zone8.play1Act = 1;
						zone8.play1 =
						Synth(\zone8play1, [
							\gate, 1,
							\lenBus, ~cBusLS.midiLV2KnobB2.index,
							\startPosition, zone8.startPos1,
							\ampBus, ~cBusLS.midiLV2Fader3.index,
							\distBus, ~cBusLS.midiLV2CrossFader.index,
							\pitchBus, ~cBusLS.midiLV2KnobB3.index,
							\pitchPattBus, ~cBusLS.pitchBus81.index,
							\jumpBus, ~cBusLS.jumpBus81.index,
							\ampPattBus, ~cBusLS.ampPattBus81.index,
							\panBus, ~cBusLS.panBus81.index,
							\dirBus, ~cBusLS.dirBus81.index,
							\pattSelBus, ~cBusLS.midiLV2KnobB1.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+");
						// start pattern modulation task
						zone8.tPatt1 = Task(f81).play;
						// update curZoneStart & curZoneLen
						~cBusLS.midiLV2KnobB2.get({arg val;
							fSetCurZone.value(
								"81",								// id current zone
								~specLS.startPos21L.map(zone8.startPos1),	// start current zone
								~specLS.len81.at(val));					// length current zone
						});
					});
				},{ // stop zone
					if(zone8.play1Act == 1, {
						zone8.play1.release;
						fCountZones.value("P-");
						zone8.tPatt1.stop;
						zone8.play1Act = 0;
					});
				});
			});
			// abs regstart
			if((chan==11 && num==3), {
				// set start position
				zone8.startPos1 = value;
				if(zone8.play1Act == 1, { // re-trigger zone
					zone8.play1.release(cfg.zonePlayRelease);
					zone8.play1 =
					Synth(\zone8play1, [
						\gate, 1,
						\lenBus, ~cBusLS.midiLV2KnobB2.index,
						\startPosition, zone8.startPos1,
						\ampBus, ~cBusLS.midiLV2Fader3.index,
						\distBus, ~cBusLS.midiLV2CrossFader.index,
						\pitchBus, ~cBusLS.midiLV2KnobB3.index,
						\pitchPattBus, ~cBusLS.pitchBus81.index,
						\ampPattBus, ~cBusLS.ampPattBus81.index,
						\jumpBus, ~cBusLS.jumpBus81.index,
						\panBus, ~cBusLS.panBus81.index,
						\dirBus, ~cBusLS.dirBus81.index,
						\pattSelBus, ~cBusLS.midiLV2KnobB1.index
					], target: ~aBus.synthGroup);
					// restart pattern modulation task
					zone8.tPatt1.stop; zone8.tPatt1 = Task(f81).play;
					// update curZoneStart
					if(curZone == "81", {fSetCurZone.value("81", ~specLS.startPos21L.map(zone8.startPos1), nil)});
				});
			});
			// length
			if((chan==9 && num==77), {
				~cBusLS.midiLV2KnobB2.set(value);
				// update curZoneLen
				if(curZone == "81", {
					fSetCurZone.value("81", nil, ~specLS.len81.at(value))
				});
			});
			// pitch
			if((chan==9 && num==78), {
				~cBusLS.midiLV2KnobB3.set(value);
			});
			// pattern select
			if((chan==9 && num==60), {
				zone8.patt1Nbr = ~specLS.patt81.at(value*127);
				~cBusLS.midiLV2KnobB1.set(value);
				// zone17.tempoClock1.tempo = ~specLS.tempo171.map(value);
				fSendLapisStatus.value("zone8pattNbr",zone8.patt1Nbr);
			});

			// Zone 16 controls //////////////////////////////////////////////////////////////////////////
			// 1: volume and trigger
			if((chan==11 && num==4), {
				// set volume bus
				~cBusLS.midiLV2Fader5.set(value);
				// trigger zone
				if(value >= 0.01, { // start zone
					if(zone16.play1Act == 0, {
						~doc.zone16_1;
						zone16.play1Act = 1;
						zone16.play1 =
						Synth(\zone16play1, [
							\gate, 1,
							\ampBus, ~cBusLS.midiLV2Fader5.index,
							\distBus, ~cBusLS.midiLV2KnobC3.index,
							// \resetPosBus, ~cBusLS.spModBus161.index, // moved to synthdef
							\lenBus, ~cBusLS.lenBus161.index,
							\panBus, ~cBusLS.midiLV2KnobC1.index,
							\ffBus, ~cBusLS.midiLV2KnobC2.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+");
						// start sample pointer modulation - this is moved to the synthdef
						// if(zone16.spModOn1 == 1, {zone16.tModSP1 = Task(fModSP161).play});
						// update curZoneStart & curZoneLen
						~cBusLS.lenBus161.get({arg val;
							fSetCurZone.value(
								"161",				// id current zone
								~bufferLS.dyn1Start,		// start current zone
								val * ~sRate);			// length current zone
						});
					});
				},{ // stop zone
					if(zone16.play1Act == 1, {
						zone16.play1.release;
						fCountZones.value("P-");
						// zone16.tModSP1.stop;
						zone16.play1Act = 0;
					});
				});
			});
			// 2: volume and trigger
			if((chan==11 && num==5), {
				// set volume bus
				~cBusLS.midiLV2Fader6.set(value);
				// trigger zone
				if(value >= 0.01, { // start zone
					if(zone16.play2Act == 0, {
						~doc.zone16_2;
						zone16.play2Act = 1;
						zone16.play2 =
						Synth("zone16play2"++zone16.mode2, [
							\gate, 1,
							\ampBus, ~cBusLS.midiLV2Fader6.index,
							\distBus, ~cBusLS.midiLV2KnobD3.index,
							\lenBus, ~cBusLS.lenBus162.index,
							\pitchRangeBus, ~cBusLS.midiLV2KnobD1.index,
							\pitchSelectBus, ~cBusLS.midiLV2KnobD2.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+");
						// update curZoneStart & curZoneLen
						~cBusLS.lenBus162.get({arg val;
							fSetCurZone.value(
								"162",				// id current zone
								~bufferLS.dyn2Start,		// start current zone
								val * ~sRate);			// length current zone
						});
					});
				},{ // stop zone
					if(zone16.play2Act == 1, {
						zone16.play2.release;
						fCountZones.value("P-");
						zone16.play2Act = 0;
					});
				});
			});
			// 3: volume and trigger
			if((chan==11 && num==6), {
				// set volume bus
				~cBusLS.midiLV2Fader7.set(value);
				// trigger zone
				if(value >= 0.01, { // start zone
					if(zone16.play3Act == 0, {
						~doc.zone16_3;
						zone16.play3Act = 1;
						zone16.play3 =
						Synth("zone16play3"++zone16.mode3, [
							\gate, 1,
							\ampBus, ~cBusLS.midiLV2Fader7.index,
							\distBus, ~cBusLS.midiLV2KnobD3.index,
							\lenBus, ~cBusLS.lenBus163.index,
							\pitchRangeBus, ~cBusLS.midiLV2KnobD1.index,
							\pitchSelectBus, ~cBusLS.midiLV2KnobD2.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+");
						// update curZoneStart & curZoneLen
						~cBusLS.lenBus163.get({arg val;
							fSetCurZone.value(
								"163",				// id current zone
								~bufferLS.dyn3Start,		// start current zone
								val * ~sRate);			// length current zone
						});
					});
				},{ // stop zone
					if(zone16.play3Act == 1, {
						zone16.play3.release;
						fCountZones.value("P-");
						zone16.play3Act = 0;
					});
				});
			});
			// 4: volume and trigger
			if((chan==11 && num==7), {
				// set volume bus
				~cBusLS.midiLV2Fader8.set(value);
				// trigger zone
				if(value >= 0.01, { // start zone
					if(zone16.play4Act == 0, {
						~doc.zone16_4;
						zone16.play4Act = 1;
						zone16.play4 =
						Synth(\zone16play4, [
							\gate, 1,
							\ampBus, ~cBusLS.midiLV2Fader8.index,
							\distBus, ~cBusLS.midiLV2KnobC3.index,
							\resetPosBus, ~cBusLS.spModBus164.index,
							\lenBus, ~cBusLS.lenBus164.index,
							\panBus, ~cBusLS.midiLV2KnobC1.index,
							\ffBus, ~cBusLS.midiLV2KnobC2.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+");
						// start sample pointer modulation
						if(zone16.spModOn4 == 1, {zone16.tModSP4 = Task(fModSP164).play});
						// update curZoneStart & curZoneLen
						~cBusLS.lenBus164.get({arg val;
							fSetCurZone.value(
								"164",				// id current zone
								~bufferLS.dyn4Start,		// start current zone
								val * ~sRate);			// length current zone
						});
					});
				},{ // stop zone
					if(zone16.play4Act == 1, {
						zone16.play4.release;
						fCountZones.value("P-");
						zone16.tModSP4.stop;
						zone16.play4Act = 0;
					});
				});
			});
			// pan
			if((chan==9 && num==80), {
				~cBusLS.midiLV2KnobC1.set(value);
			});
			// filter frequency
			if((chan==9 && num==97), {
				~cBusLS.midiLV2KnobC2.set(value);
			});
			// pitch mod depth
			if((chan==9 && num==100), {
				~cBusLS.midiLV2KnobD1.set(value);
			});
			// pitch mod type
			if((chan==9 && num==117), {
				~cBusLS.midiLV2KnobD2.set(value);
			});
			// distortion 1 & 4
			if((chan==9 && num==98), {
				~cBusLS.midiLV2KnobC3.set(value);
			});
			// distortion 2 & 3
			if((chan==9 && num==118), {
				~cBusLS.midiLV2KnobD3.set(value);
			});

			// Zone17 beatPlay controls //////////////////////////////////////////////////////////////////////////
			// trigger & volume
			if((chan==14 && num==8), {
				zone17.amp1 = value;

				// trigger zone
				if(value >= 0.01,{ // start zone
					if(zone17.play1Act == 0, {
						~doc.zone17;
						zone17.play1Act = 1;
						zone17.patt1 = Pwrand([
							Pbind(
								\instrument, \stretchedFragments,
								\target, ~aBus.synthGroup,
								\start, Pwhite(Pfunc{zone17.startPos1}, Pfunc{min(1,zone17.startPos1+zone17.len1)}, 32),
								\release, Pexprand(0.1, 0.3),
								\delta, 1,
								\time, Pkey(\delta) / Pfunc { zone17.tempoClock1.tempo },
								\stretch, Pexprand(2.0, 4.0),
								\amp, Pfunc{ zone17.amp1 },
								\dist, Pfunc{ zone17.dist1 },
								\ampSine, Pfunc{zone17.ampSine1},
								\ampPluck, Pfunc{zone17.ampPluck1},
								\freq, Pwhite(50,200),
								\coef, Pwhite(-0.9,0.9),
								\decay, Pwhite(4,8)
							),
							Pbind(
								\instrument, \stretchedFragments,
								\target, ~aBus.synthGroup,
								\start, Pwhite(Pfunc{zone17.startPos1}, Pfunc{min(1,zone17.startPos1+zone17.len1)}, 8),
								\release, Pexprand(0.2, 0.6),
								\delta, 2,
								\time, Pkey(\delta) / Pfunc { zone17.tempoClock1.tempo },
								\stretch, Pexprand(2.0, 4.0),
								\amp, Pfunc{ zone17.amp1 },
								\dist, Pfunc{ zone17.dist1 },
								\ampSine, Pfunc{zone17.ampSine1},
								\ampPluck, Pfunc{zone17.ampPluck1},
								\freq, Pwhite(20,50),
								\coef, Pwhite(0.01,0.5),
								\decay, Pwhite(4,8)
							),
							Pbind(
								\instrument, \stretchedFragments,
								\target, ~aBus.synthGroup,
								\start, Pwhite(Pfunc{zone17.startPos1}, Pfunc{min(1,zone17.startPos1+zone17.len1)}, 1),
								\release, Pexprand(1.0, 2.0),
								\delta, 8,
								\time, Pkey(\delta) / Pfunc { zone17.tempoClock1.tempo },
								\stretch, Pexprand(2.0, 4.0),
								\amp, Pfunc{ zone17.amp1 },
								\dist, Pfunc{ zone17.dist1 },
								\ampSine, Pfunc{zone17.ampSine1},
								\ampPluck, Pfunc{zone17.ampPluck1},
								\freq, Pwhite(10,20),
								\coef, Pwhite(0.01,0.5),
								\decay, Pwhite(4,8)
							)
						], [1,0,0], inf).play(zone17.tempoClock1);
						// ], [0.6,0.2,0.2], inf).play(zone17.tempoClock1);
						fCountZones.value("P+",1);

						// update curZoneStart & curZoneLen
						~cBusLS.midiLV2KnobA1.get({arg val;
							fSetCurZone.value(
								"171",															// id current zone
								~specLS.startPos21L.map(zone17.startPos1),	// start current zone
								~specLS.len21L.at(val));									// length current zone
						});
					});
				},{ // stop zone
					if(zone17.play1Act == 1, {
						zone17.play1Act = 0;
						zone17.patt1.stop;
						fCountZones.value("P-", 1);
					});
				});
			});
			if((chan==14 && num==9), {
				zone17.startPos1 = value;
			});
			if((chan==14 && num==10), {
				zone17.ampSine1 = value;
			});
			if((chan==14 && num==11), {
				zone17.ampPluck1 = value;
			});
			// sineAtmos trigger & volume
			if((chan==14 && num==12), {
				~cBusLS.midiLV1Fader12.set(value);
				if(value >= 0.01,{ // start zone
					if(zone18.play1Act == 0, {
						~doc.zone18_1;
						zone18.play1Act = 1;
						zone18.play1 = Synth(\sineAtmos, [
							\gate, 1,
							\ampBus, ~cBusLS.midiLV1Fader12.index,
							\distBus, ~cBusLS.midiLV1CrossFader.index,
							\speedBus, ~cBusLS.midiLV1Fader13.index,
					], target: ~aBus.synthGroup);
						fCountZones.value("P+", 1);
					});
				},{ // stop zone
					if(zone18.play1Act == 1, {
						zone18.play1Act = 0;
						zone18.play1.release;
						fCountZones.value("P-", 1);
					});
				});
			});
			if((chan==14 && num==13), {
				~cBusLS.midiLV1Fader13.set(value);
			});
			// throb trigger & volume
			if((chan==14 && num==14), {
				~cBusLS.midiLV1Fader14.set(value);
				if(value >= 0.01,{ // start zone
					if(zone18.play2Act == 0, {
						~doc.zone18_2;
						zone18.play2Act = 1;
						zone18.play2 = Synth(\throb, [
							\gate, 1,
							\ampBus, ~cBusLS.midiLV1Fader14.index,
							\distBus, ~cBusLS.midiLV1CrossFader.index,
							\speedBus, ~cBusLS.midiLV1Fader15.index,
							\greyholeBus, ~cBusLS.midiLV1KnobD1.index,
						], target: ~aBus.synthGroup);
						fCountZones.value("P+", 1);
					});
				},{ // stop zone
					if(zone18.play2Act == 1, {
						zone18.play2Act = 0;
						zone18.play2.release;
						fCountZones.value("P-", 1);
					});
				});
			});
			if((chan==14 && num==15), {
				~cBusLS.midiLV1Fader15.set(value);
			});
		}); // only process midi if coming from the right source
	},
	"/midi/control"
	).fix;

	///////////////////////////////////////////// Arduino data acquisition //////////////////////////////////////

	// responder for analog sensors
	OSCdef(\lisaArdAna, { |msg|
		//	("OSC RCV ArdAna: " ++ msg).postln;
		case
		{msg[1] == 1} {}
		{msg[1] == 2} {~cBusLS.ardAna1Bus.set(msg[2]);}
		;
	},
	"/ard/ana"
	).fix;

	// responder for digital sensors
	OSCdef(\lisaArdDig, { |msg|
		//	("OSC RCV ArdDig: " ++ msg).postln;
		case
		{msg[1] == 1} {}
		{msg[1] == 2} {}
		;
	},
	"/ard/dig"
	).fix;

	///////////////////////////////////////////// other OSC responders //////////////////////////////////////

	// responder to handle SendTrig from the server
	OSCdef(\lisaSendTrig, { |msg| msg.postln},
		"/tr"
	).fix;

	// responder to handle playhead, startpos and len messages from the server
	OSCdef(\lisaPlayHead, { |msg|
		if((msg[2] == curZone.asInt) && (~showBufferView == 1),	{
			curPlayHead = msg[3];
			{ // update bufferViews
				bufferView[0].timeCursorPosition = curPlayHead*~sRate;
				bufferView[0].setSelectionStart(0, msg[4].asFloat*~sRate);
				bufferView[0].setSelectionSize(0, msg[5].asFloat*~sRate);
				bufferView[1].timeCursorPosition = curPlayHead*~sRate - ~bufferLS.bStart;
				bufferView[1].setSelectionStart(0, msg[4].asFloat*~sRate - ~bufferLS.bStart);
				bufferView[1].setSelectionSize(0, msg[5].asFloat*~sRate);
				bufferView[2].timeCursorPosition = curPlayHead*~sRate - ~bufferLS.dyn1Start;
				bufferView[2].setSelectionStart(0, msg[4].asFloat*~sRate - ~bufferLS.dyn1Start);
				bufferView[2].setSelectionSize(0, msg[5].asFloat*~sRate);
				bufferView[3].timeCursorPosition = curPlayHead*~sRate - ~bufferLS.dyn2Start;
				bufferView[3].setSelectionStart(0, msg[4].asFloat*~sRate - ~bufferLS.dyn2Start);
				bufferView[3].setSelectionSize(0, msg[5].asFloat*~sRate);
				bufferView[4].timeCursorPosition = curPlayHead*~sRate - ~bufferLS.dyn3Start;
				bufferView[4].setSelectionStart(0, msg[4].asFloat*~sRate - ~bufferLS.dyn3Start);
				bufferView[4].setSelectionSize(0, msg[5].asFloat*~sRate);
				bufferView[5].timeCursorPosition = curPlayHead*~sRate - ~bufferLS.dyn4Start;
				bufferView[5].setSelectionStart(0, msg[4].asFloat*~sRate - ~bufferLS.dyn4Start);
				bufferView[5].setSelectionSize(0, msg[5].asFloat*~sRate);
			}.defer();
		});
		if((msg[2] == curRecZone.asInt) && (~showBufferView == 1), {  // recording zones
			curRecHead = msg[3];
			{ // update bufferViews
				bufferView[0].setSelectionStart(1, curRecHead*~sRate);
				bufferView[0].setSelectionSize(1, 0.5*~sRate);
				bufferView[1].setSelectionStart(1, curRecHead*~sRate - ~bufferLS.bStart);
				bufferView[1].setSelectionSize(1, 0.5*~sRate);
				bufferView[2].setSelectionStart(1, curRecHead*~sRate - ~bufferLS.dyn1Start);
				bufferView[2].setSelectionSize(1, 0.5*~sRate);
				bufferView[3].setSelectionStart(1, curRecHead*~sRate - ~bufferLS.dyn2Start);
				bufferView[3].setSelectionSize(1, 0.5*~sRate);
				bufferView[4].setSelectionStart(1, curRecHead*~sRate - ~bufferLS.dyn3Start);
				bufferView[4].setSelectionSize(1, 0.5*~sRate);
				bufferView[5].setSelectionStart(1, curRecHead*~sRate - ~bufferLS.dyn4Start);
				bufferView[5].setSelectionSize(1, 0.5*~sRate);
			}.defer();
		});
	},
	'playHead'
	).fix;

	// responder to trigger bufferload from the server
	OSCdef(\lisaBufferViewRefresh, { |msg|
		if(~showBufferView == 1, {
			case
			{msg[3] == 0}
			{fDisplayBufferView.value("A")}
			{msg[3] == ~bufferLS.bStart}
			{fDisplayBufferView.value("B")}
			{msg[3] == ~bufferLS.dyn1Start}
			{fDisplayBufferView.value("C1")}
			{msg[3] == ~bufferLS.dyn2Start}
			{fDisplayBufferView.value("C2")}
			{msg[3] == ~bufferLS.dyn3Start}
			{fDisplayBufferView.value("C3")}
			{msg[3] == ~bufferLS.dyn4Start}
			{fDisplayBufferView.value("C4")}
		});
	},
	'bufferViewRefresh'
	).fix;

	// responder to disable button1
	OSCdef(\lisaBut1dis, { |msg|
		//	("OSC RCV LS: " ++ msg).postln;
		button1disable = msg[1];
	},
	"/button1disable"
	).fix;

	// responder to disable button2
	OSCdef(\lisaBut2dis, { |msg|
		//	("OSC RCV LS: " ++ msg).postln;
		button2disable = msg[1];
	},
	"/button2disable"
	).fix;

	// responder to receive ctr msg from the other player
	OSCdef(\lisaExtCtr, { |msg|
		//	("OSC RCV LS: " ++ msg).postln;
		~cBusLS.ex3dProYpitch.set(~specLS.pitch61.at(msg[1]));
	},
	"/externalController"
	).fix;

	// responder to receive switch msg from the other player
	OSCdef(\lisaExtSw, { |msg|
		//	("OSC RCV LS: " ++ msg).postln;
		localControl = (1 - msg[1]); // disable local control of Y axis
	},
	"/externalSwitch"
	).fix;

	// responder to trigger sample load
	OSCdef(\lisaSampleLoad, { |msg|
		var sampleColl, sampleArray, norm, bufPart, relPath;
		sampleColl = msg[1].asString; // comma-separated list of samples to load, if empty then clear buffer
		sampleArray = sampleColl.split($,);
		norm = msg[2]; // whether the buffer should be normalized after read
		bufPart = msg[3].asString; // A or B
		relPath = msg[4]; // whether the paths in sampleColl are relative or absolute
		if(sampleColl=="",
			{{~mainBufLS.zero; "Buffer cleared.".postln;}.defer()},{
				if(bufPart == "A",
					{fBufferRead.value(sampleArray, ~bufferLS.aLen, ~bufferLS.aStart, relativePath: relPath);},
					{fBufferRead.value(sampleArray, ~bufferLS.bLen, ~bufferLS.bStart, relativePath: relPath);}
				);
				if(norm != 0, {~mainBufLS.normalize(norm); ("Buffer normalized to" + norm).postln;});
		});
	},
	"/sampleload"
	).fix;

	// responder to set quantize settings remotely
	OSCdef(\lisaQuant, { |msg|
		cfg.quantize = msg[1];
		cfg.bpm = msg[2];
		cfg.deBug = msg[3];
		["Quantize", cfg.quantize, "bpm", cfg.bpm, "deBug", cfg.deBug].postln;
		// quantized spec conversions
		fQuantize.value();
	},
	"/quantize"
	).fix;

	// responder to stop everything
	OSCdef(\lisaPanic, { |msg|
		"Panic LiveSampler".postln;
		{fInitOutput.value(0)}.defer(); 	// stop output synths
		{fInitOutput.value(1)}.defer(0.1); 	// start output synths
	},
	"/panic"
	).fix;

	///////////////////////////////////////////// functions //////////////////////////////////////
	// modulate sample pointer offset for zone3play1
	fModSP31 = {
		inf.do({
			// repeat for number of elements in the array with offset values
			zone3.stepsOffset1tmp.size.do({arg i;
				// set resetPos bus with new start  position
				~cBusLS.spModBus31.set(zone3.stepsOffset1tmp.at(i));

				if(cfg.deBug == 1, {
					if(i == 0, {"".postln});
					~cBusLS.midiLV1KnobC1.get({arg val;
						("zone3play1 step" + i ++ ":" + (
							~specLS.startPos21L.map(zone3.startPos1) +
							(zone3.stepsOffset1tmp.at(i) * ~specLS.len31.at(val)) / ~sRate
						).round(0.1)).postln;
					});
				});
				// wait
				~specLS.spModSpd31.at(zone3.spModSpd1).wait;
			});
			// change the array with offset values
			if((2.rand == 0), {zone3.stepsOffset1tmp[zone3.stepsOffset1tmp.size.rand] = 1.0.rand;
				"zone3play randomize 2".postln});
			if((5.rand == 0), {zone3.stepsOffset1tmp[zone3.stepsOffset1tmp.size.rand] = 0.5.rand;
				"zone3play randomize 5".postln});
			if((8.rand == 0), {zone3.stepsOffset1tmp = zone3.stepsOffset1[0..zone3.stepsOffset1.size];
				"zone3play randomize 8 (reset)".postln});
		});
	};

	// modulate sample pointer offset for zone16play1
	// fModSP161 = {
	// 	var modDepth, waitTime;
	// 	inf.do({
	// 		zone16.stepsOffset1.size.do({arg i;
	// 			modDepth = zone16.spMod1ModDepth.next;
	// 			waitTime = zone16.spMod1Spd.next;
	// 			// ("offset:"+zone16.stepsOffset1.at(i)+"depth:"+modDepth+"wait:"+waitTime).postln;
	// 			// [zone16.stepsOffset1.at(i) * modDepth].postln;
	// 			~cBusLS.spModBus161.set(zone16.stepsOffset1.at(i) * modDepth);
	// 			waitTime.wait;
	// 		});
	// 	});
	// };
	// zone16.spMod1ModDepth = Routine.new({
	// 	inf.do{ [0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 0.9, 0.8, 0.7, 0.6, 0.5].do({arg val; val.yield;}) }
	// });
	// zone16.spMod1Spd = Routine.new({
	// 	inf.do{ (0.2,0.3..1).do({arg val; val.yield;}); (0.9,0.8..0.3).do({arg val; val.yield;}); }
	// 	//	inf.do{ [0.2,1,0.3].resize(17, \linear).do({arg val; val.yield;}); } // wslib interpolate functionality
	// });

	// modulate sample pointer offset for zone16play4
	fModSP164 = {
		inf.do({
			zone16.stepsOffset1.size.do({arg i;
				~cBusLS.spModBus164.set(zone16.stepsOffset1.at(i) * zone16.spMod4ModDepth.next);
				zone16.spMod4Spd.next.wait;
			});
		});
	};
	zone16.spMod4ModDepth = Routine.new({
		inf.do{ [0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 0.9, 0.8, 0.7, 0.6, 0.5].do({arg val; val.yield;}) }
	});
	zone16.spMod4Spd = Routine.new({
		inf.do{ (0.2,0.3..1).do({arg val; val.yield;}); (0.9,0.8..0.3).do({arg val; val.yield;}); }
	});

	// pattern play for zone8play1
	f81 = {
		var jumpTot = 0, elemNbr = 0, patt1NbrTmp, patt1NbrPrev = zone8.patt1Nbr;
		fSendLapisStatus.value("zone8pattAct",zone8.patt1Nbr);
		inf.do({  // offset, length, repeats, pitch (-1..1), vol (0..1), pan (-1..1), dir (-1/1)
			// initialize, check whether pattNbr changed since last loop
			if(patt1NbrPrev != zone8.patt1Nbr,
				{ // reset
					patt1NbrPrev = zone8.patt1Nbr;
					elemNbr = 0;
					["zone8.play1 pattern",zone8.patt1Nbr].postln;
					fSendLapisStatus.value("zone8pattAct",zone8.patt1Nbr);
			});
			patt1NbrTmp = zone8.patt1Nbr; // in case zone8.patt1Nbr changes halfway and breaks things
			// process offset
			if(zone8.patt1[patt1NbrTmp][elemNbr][0] != 0, // only when offset not 0
				{
					jumpTot = jumpTot + zone8.patt1[patt1NbrTmp][elemNbr][0]; // offset
					f81jump.value(jumpTot);
			});
			//	~cBusLS.midiLV2KnobB2.get({arg val; ["na offset", (jumpTot % (~specLS.len81.at(val)/~sRate))].postln;});
			if(cfg.deBug == 1, {["zone8.play1: jumpTot na offset", jumpTot].postln;});
			// set parameters
			~cBusLS.pitchBus81.set(zone8.patt1[patt1NbrTmp][elemNbr][3]);
			~cBusLS.ampPattBus81.set(zone8.patt1[patt1NbrTmp][elemNbr][4]);
			~cBusLS.panBus81.set(zone8.patt1[patt1NbrTmp][elemNbr][5]);
			~cBusLS.dirBus81.set(zone8.patt1[patt1NbrTmp][elemNbr][6]);
			// repeats
			zone8.patt1[patt1NbrTmp][elemNbr][2].do({
				zone8.patt1[patt1NbrTmp][elemNbr][1].wait;
				f81jump.value(jumpTot);
			});
			zone8.patt1[patt1NbrTmp][elemNbr][1].wait;
			jumpTot = jumpTot + zone8.patt1[patt1NbrTmp][elemNbr][1];
			//	~cBusLS.midiLV2KnobB2.get({arg val; ["na length", (jumpTot % (~specLS.len81.at(val)/~sRate))].postln;});
			if(cfg.deBug == 1, {["zone8.play1: jumpTot na length", jumpTot].postln;});
			elemNbr = (elemNbr + 1) % zone8.patt1[patt1NbrTmp].size;
		}); // inf.do
	};
	f81jump = {
		arg jump;
		zone8.sign1 = (zone8.sign1 + 1) %2;
		~cBusLS.jumpBus81.set((jump * ~sRate) + zone8.sign1); // add 0 or 1 frame to make sure the jump happens
	};

	// generic buffer reading function
	fBufferRead = {
		arg sampleList, bufferLen, bufferStart, relativePath = 1, tempFile;
		var numFramesSubTotal = 0, i = 0, numFramesToLoad, sampleDirLocal;

		("\nReading sample(s) into buffer starting at" + (bufferStart/~sRate)).postln;
		// if relative add sampleDir
		sampleDirLocal = if(relativePath==1, {cfg.sampleDir}, {""});
		// loop through samplelist
		while ({i < sampleList.size},{
			tempFile = SoundFile.new;
			if(tempFile.openRead(sampleDirLocal ++ sampleList[i]),{
				// only load a part of the sample if it doesn't fit anymore
				if( (numFramesSubTotal + tempFile.numFrames) > bufferLen,
					{numFramesToLoad = bufferLen - numFramesSubTotal;},
					{numFramesToLoad = tempFile.numFrames;}
				);
				// prepare for loading mono samples
				if( tempFile.numChannels == 1, {m = 0;}, {m = 1;});
				// the actual read of the buffer
				~mainBufLS.readChannel(sampleDirLocal ++ sampleList[i],
					0, // load from the beginning of the soundfile
					numFramesToLoad,
					bufferStart + numFramesSubTotal, // where in the buffer to read
					false, // close buffer after read
					[0,m] // channels to read from
				);
				// to save sample files to backup location
				if(cfg.copySamples == 1, {
					("cp '" ++ sampleDirLocal ++ sampleList[i] ++ "' " ++
						cfg.docDir ++ "/" ++ cfg.libDir ++ "Samples/" ++ ~project ++ "/").postln;
					("cp '" ++ sampleDirLocal ++ sampleList[i] ++ "' " ++
						cfg.docDir ++ "/" ++ cfg.libDir ++ "Samples/" ++ ~project ++ "/").unixCmd;
				});
				// some administration
				numFramesSubTotal = numFramesSubTotal + tempFile.numFrames;
				("Sample read:" + sampleList[i]).postln;
				i = i + 1;
				tempFile.close;
			},{
				("Soundfile" + sampleDirLocal ++ sampleList[i] + "not found.").postln;
				i = sampleList.size;
			});
		}); // while
		// display buffer in bufferView
		if(~showBufferView == 1, {
			case
			{bufferStart < ~bufferLS.bStart}
			{fDisplayBufferView.value("A")}
			{(bufferStart >= ~bufferLS.bStart) && (bufferStart < ~bufferLS.dyn1Start)}
			{fDisplayBufferView.value("B")}
			{(bufferStart >= ~bufferLS.dyn1Start) && (bufferStart < ~bufferLS.dyn2Start)}
			{fDisplayBufferView.value("C1")}
			{(bufferStart >= ~bufferLS.dyn2Start) && (bufferStart < ~bufferLS.dyn3Start)}
			{fDisplayBufferView.value("C2")}
			{(bufferStart >= ~bufferLS.dyn3Start) && (bufferStart < ~bufferLS.dyn4Start)}
			{fDisplayBufferView.value("C3")}
			{bufferStart >= ~bufferLS.dyn4Start}
			{fDisplayBufferView.value("C4")}
			;
		});
	};

	fDisplayBufferView = {
		arg section = "A";
		case
		{section == "A"}
		{
			~mainBufLS.write(bufferViewFolder++"A.wav","WAV","int16", ~bufferLS.aLen, ~bufferLS.aStart);
			{
				fileBufferView[0].openRead(bufferViewFolder++"A.wav");
				bufferView[0].soundfile = fileBufferView[0];
				bufferView[0].read(0, ~bufferLS.aLen, cfg.bufferViewBlocksize).refresh;
			}.defer(cfg.bufferViewDeferRead);
		}
		{section == "B"}
		{
			~mainBufLS.write(bufferViewFolder++"B.wav","WAV","int16", ~bufferLS.bLen, ~bufferLS.bStart);
			{
				fileBufferView[1].openRead(bufferViewFolder++"B.wav");
				bufferView[1].soundfile = fileBufferView[1];
				bufferView[1].read(0, ~bufferLS.bLen, cfg.bufferViewBlocksize).refresh;
			}.defer(cfg.bufferViewDeferRead);
		}
		{section == "C1"}
		{
			~mainBufLS.write(bufferViewFolder++"C1.wav","WAV","int16",  zoneRec.dynLenMaxFrames, ~bufferLS.dyn1Start);
			{
				fileBufferView[2].openRead(bufferViewFolder++"C1.wav");
				bufferView[2].soundfile = fileBufferView[2];
				bufferView[2].read(0, zoneRec.dynLenMaxFrames, cfg.bufferViewBlocksize).refresh;
			}.defer(cfg.bufferViewDeferRead);
		}
		{section == "C2"}
		{
			~mainBufLS.write(bufferViewFolder++"C2.wav","WAV","int16", zoneRec.dynLenMaxFrames, ~bufferLS.dyn2Start);
			{
				fileBufferView[3].openRead(bufferViewFolder++"C2.wav");
				bufferView[3].soundfile = fileBufferView[3];
				bufferView[3].read(0, zoneRec.dynLenMaxFrames, cfg.bufferViewBlocksize).refresh;
			}.defer(cfg.bufferViewDeferRead);
		}
		{section == "C3"}
		{
			~mainBufLS.write(bufferViewFolder++"C3.wav","WAV","int16", zoneRec.dynLenMaxFrames, ~bufferLS.dyn3Start);
			{
				fileBufferView[4].openRead(bufferViewFolder++"C3.wav");
				bufferView[4].soundfile = fileBufferView[4];
				bufferView[4].read(0, zoneRec.dynLenMaxFrames, cfg.bufferViewBlocksize).refresh;
			}.defer(cfg.bufferViewDeferRead);
		}
		{section == "C4"}
		{
			~mainBufLS.write(bufferViewFolder++"C4.wav","WAV","int16", 2*zoneRec.dynLenMaxFrames, ~bufferLS.dyn4Start);
			{
				fileBufferView[5].openRead(bufferViewFolder++"C4.wav");
				bufferView[5].soundfile = fileBufferView[5];
				bufferView[5].read(0, 2*zoneRec.dynLenMaxFrames, cfg.bufferViewBlocksize).refresh;
			}.defer(cfg.bufferViewDeferRead);
		}
		;
	};

	fRefreshBufferview = {
		fDisplayBufferView.value("A");
		{fDisplayBufferView.value("B")}.defer(0.3);
		{fDisplayBufferView.value("C1")}.defer(0.6);
		{fDisplayBufferView.value("C2")}.defer(0.7);
		{fDisplayBufferView.value("C3")}.defer(0,8);
		{fDisplayBufferView.value("C4")}.defer(0.9);
	};

	// function keeping track and display of zones by Rec/Play
	fCountZones = {
		arg type, count = 1;
		{ // defer
			case
			{type == "R+"} 	{countRec = countRec + count; dispRec.states_([[countRec.asString]]);
				fSendLapisStatus.value("countRec",countRec);}
			{type == "R-"} 	{countRec = max(0,countRec - count); dispRec.states_([[countRec.asString]]);
				fSendLapisStatus.value("countRec",countRec);}
			{type == "P+"} 	{countPlay = countPlay + count; dispPlay.states_([[countPlay.asString]]);
				fSendLapisStatus.value("countPlay",countPlay);}
			{type == "P-"} 	{countPlay = max(0,countPlay - count); dispPlay.states_([[countPlay.asString]]);
				fSendLapisStatus.value("countPlay",countPlay);}
			{type == "E+"} 	{countEfx = countEfx + count; dispEfx.states_([[countEfx.asString]]);
				fSendLapisStatus.value("countEfx",countEfx);}
			{type == "E-"} 	{countEfx = max(0,countEfx - count); dispEfx.states_([[countEfx.asString]]);
				fSendLapisStatus.value("countEfx",countEfx);};
		}.defer();
	};

	fAmpCurZone = {
		arg buffer, start = 0, num = 100, mul = 1;
		~mainBufLS.loadToFloatArray(start, num, {
			arg arr, buf;
			"LoadToFloat executed.".postln;
			buf.loadCollection(arr.collect{|x| x*mul}, start, {arg arr, buf;  "Amplify current zone finished.".postln});
		});
	};

	fQuantize = {
		// quantized conversions
		if(cfg.quantize == 1, {
			"\nQuantizing mapping envelopes.".postln;
			~specLS.len41 = Env.new(
				[60/16, 60/8, 60/4, 60/2, 60/1, 60/0.5] / cfg.bpm,
				[25.6, 25.6, 25.6, 25.6, 25.6],[\step, \step, \step, \step, \step]);
			~specLS.spModSpd31 = Env.new(
				[60/8, 60/4, 60/2, 60/1, 60/0.5, 60/0.25] / cfg.bpm,
				[25.6, 25.6, 25.6, 25.6, 25.6],[\step, \step, \step, \step, \step]);
		},{
			"\nLiveSampler: De-Quantizing mapping envelopes.".postln;
			~specLS.len41 = Env.xyc([[0, 0.2,\exp],[64, 30, \lin],[127, 60]]);
			~specLS.spModSpd31 = Env.new([0.02,10],[127],[\exp]);
		});
		~cBusLS.midiLV2KnobA1.set(~specLS.len41.at(64));
	};

	// quantized conversions
	fQuantize.value();

	// stop all notes and restart output synths
	fInitOutput = {
		arg mode;
		if(mode == 0, { // stop actions
			// set counters to 0
			countRec = 0;
			dispRec.states_([[countRec.asString]]);
			countPlay = 0;
			dispPlay.states_([[countPlay.asString]]);
			countEfx = 0;
			dispEfx.states_([[countEfx.asString]]);
			// set colors to off
			dispBaseBtn.background_(colorOff);
			dispBaseBtn2.background_(colorOff);
			// reset some variables
			zone6.play4Act = 0;
			zone6.play5Act = 0;
			zone6.play1Nbr = 0;
			zone6.play1 = Array.new(50);
			zone6.play1Act = 0;
			// update LapisStatus window
			fInitLapisStatus.value("playback");
		},
		{ // start actions
		});
	};

	// initialize lapistatus window
	fInitLapisStatus = {
		arg mode = "all";

		// reset lapisstatus
		if((mode == "all") || (mode == "playback"),{
			fSendLapisStatus.value("countPlay",0);
			fSendLapisStatus.value("countRec",0);
			fSendLapisStatus.value("countEfx",0);
			fSendLapisStatus.value("BB",0);
			fSendLapisStatus.value("BB2",0);
		});
		if((mode == "all") || (mode == "control"),{
			fSendLapisStatus.value("SP",0);
			fSendLapisStatus.value("PT",0);
		});
	};

	// sending LapisStatus OSC to local
	fSendLapisStatus = {
		arg type, value;
		cfg.localAddr.sendMsg("/lapistatus",type,value);
	};

	// returning input channels for effects, depending on ~aBus.inInt and ~aBus.inAlt settings
	fGetInChanEfx = {
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

	// returning input channels for sampling, depending on ~aBus.inInt settings
	fGetInChanSampling = {
		arg monoInput = 0;
		var inChan1, inChan2;
		if(~aBus.inInt == 1,
			{ // if input is internal, it's always stereo
				inChan1 = ~aBus.inChan1;
				inChan2 = ~aBus.inChan2;
			},
			{ // if input is external, it's always mono
				inChan1 = monoInput;
				inChan2 = inChan1;
		});
		[inChan1,inChan2]
	};

	// returning input attenuation for sampling, depending on ~aBus.inInt settings
	fGetInAttenuation = {
		var attenuation;
		if(~aBus.inInt == 1,
			{ attenuation = ~aBus.inResamplingAtt },
			{ attenuation = 1 });
		attenuation
	};

	// returning Group for sampling, depending on ~aBus.inInt settings
	fGetInGroup = {
		var group;
		if(~aBus.inInt == 1,
			{ group = ~aBus.resampleGroup },
			{ group = ~aBus.synthGroup });
		group
	};

	// set current zone and do other things that need to be done
	fSetCurZone = {
		arg zone, start, len, mode = "PLAY";
		case
		{mode == "PLAY"}
		{
			curZone = zone;
			if(start.notNil, {curZoneStart = start});
			if(len.notNil, {curZoneLen = len});
		}
		{mode == "REC"}
		{
			curRecZone = zone;
		};
	};

	// pitch shift only in octaves or free
	fOctavesPitchshift = {
		if(zone6.octavesPitchshift == 1, {
			"\nLiveSampler: Remapping pitch61 because pitchshift only in octaves".postln;
			~specLS.pitch61 = Env([0.25,0.25,0.5,1,2],[0.1,0.2,0.5,0.2],\step);
		}, {
			"\nLiveSampler: Remapping pitch61 because pitchshift is free (not only in octaves)".postln;
			~specLS.pitch61 = Env.new([0.1,12],[1],[\exp]);
		});
	};

	///////////////////////////////////////////// Tasks //////////////////////////////////////

	// task to postln current zone info for debugging
	tCurZone = Task({
		inf.do({
			['curZone', curZone, curZoneStart / ~sRate, curZoneLen / ~sRate].postln;
			1.wait;
		});
	});

	///////////////////////////////////////////// GUI //////////////////////////////////////

	~wLiveSampler = Window("LiveSampler", Rect(20, (screenHeight - 160), 330, 100), false);
	~wLiveSamplerAvail = 1;

	// display status of zone6.play4
	dispBaseBtn = SmoothButton(~wLiveSampler, Rect(25,10,50,23)).border_(1).radius_(3).canFocus_(false)
	.font_(fontButton).background_(Color.white).states_([["BB"]]);

	// display status of zone6.play5
	dispBaseBtn2 = SmoothButton(~wLiveSampler, Rect(80,10,50,23)).border_(1).radius_(3).canFocus_(false)
	.font_(fontButton).background_(Color.white).states_([["OS"]]);

	// display status of disabled/enabled start position
	dispDisableStartPos = SmoothButton(~wLiveSampler, Rect(135,10,50,23)).border_(1).radius_(3).canFocus_(false)
	.font_(fontButton).background_(Color.white).states_([["SP"]]);

	// display status of disabled/enabled pitch control
	dispDisablePitch = SmoothButton(~wLiveSampler, Rect(190,10,50,23)).border_(1).radius_(3).canFocus_(false)
	.font_(fontButton).background_(Color.white).states_([["PT"]]);

	// display number of playback zones
	dispPlay = SmoothButton(~wLiveSampler, Rect(255,10,50,23)).border_(1).radius_(3).canFocus_(false)
	.font_(fontButton).background_(Color.white).stringColor_(Color.blue).states_([["0"]]);

	// display number of recording zones
	dispRec = SmoothButton(~wLiveSampler, Rect(255,38,50,23)).border_(1).radius_(3).canFocus_(false)
	.font_(fontButton).background_(Color.white).stringColor_(Color.red).states_([["0"]]);

	// display number of effect zones
	dispEfx = SmoothButton(~wLiveSampler, Rect(255,66,50,23)).border_(1).radius_(3).canFocus_(false)
	.font_(fontButton).background_(Color.white).states_([["0"]]);

	// drag destination for sample load into A
	loadFileA = DragSink(~wLiveSampler, Rect(25,39,215,21)).string_("Drag file(s) to load in A").canFocus_(false)
	.font_(fontLabel).align_(\center).background_(Color.white).stringColor_(Color.black)
	.receiveDragHandler_({
		var dragTemp = View.currentDrag;
		// if only one file is dragged, make it into an array with this trick
		if(dragTemp.isString, {dragTemp = dragTemp.split(nl)});
		// dragTemp.postln;
		if(cfg.dragEmptyBeforeLoad == 1, {~mainBufLS.zero; "Buffer cleared.".postln;});
		fBufferRead.value(dragTemp, ~mainBufLS.numFrames, ~bufferLS.aStart, 0);
		if(~showBufferView == 1, {fDisplayBufferView.value("A")});
	});

	// drag destination for sample load into B
	loadFileB = DragSink(~wLiveSampler, Rect(25,67,215,21)).canFocus_(false).string_("Drag file(s) to load in B")
	.font_(fontLabel).align_(\center).background_(Color.white).stringColor_(Color.black)
	.receiveDragHandler_({
		var dragTemp = View.currentDrag;
		// if only one file is dragged, make it into an array with this trick
		if(dragTemp.isString, {dragTemp = dragTemp.split(nl)});
		// dragTemp.postln;
		if(cfg.dragEmptyBeforeLoad == 1, {~mainBufLS.zero; "Buffer cleared.".postln;});
		fBufferRead.value(dragTemp, ~bufferLS.bLen, ~bufferLS.bStart, 0);
		if(~showBufferView == 1, {fDisplayBufferView.value("B")});
	});

	// keyboard tracking
	~wLiveSampler.view.keyDownAction_({
		arg view, char, modifiers, unicode, keycode;
		// [modifiers,keycode].postln;

		// Esc stops sound output
		if((keycode == 53), {cfg.localAddr.sendMsg("/panic");});
		// L clears buffer
		if((keycode == 37), {
			~mainBufLS.zero;
			"Buffer cleared.".postln;
			if(~showBufferView == 1, {
				fDisplayBufferView.value("A");
				{fDisplayBufferView.value("B")}.defer(0.5);
				{fDisplayBufferView.value("C1")}.defer(1);
				{fDisplayBufferView.value("C2")}.defer(1.1);
				{fDisplayBufferView.value("C3")}.defer(1.2);
				{fDisplayBufferView.value("C4")}.defer(1.3);
			});
		});
		// A amplifies current zone
		if((keycode == 0) && (modifiers == 0), {
			fAmpCurZone.value(~mainBufLS, curZoneStart, curZoneLen, cfg.ampCurZoneFactor);
			"\nAmplifying current zone...".postln;
		});
		// S saves buffer to disk
		if((keycode ==1), {
			~mainBufLS.write(thisProcess.platform.recordingsDir++"/LiveSampler"++Date.getDate.format("_%y%m%d_%H%M%S")++".aif");
			"LiveSampler: save samplebuffer".postln;
		});
		// T loads testSampleList
		if((keycode == 17), {
			fBufferRead.value(~testSampleList, ~bufferLS.aLen, ~bufferLS.aStart);
			fBufferRead.value(~testSampleList, ~bufferLS.bLen, ~bufferLS.bStart);
			fBufferRead.value(~testSampleList, ~bufferLS.dyn1Len, ~bufferLS.dyn1Start);
			fBufferRead.value(~testSampleList, ~bufferLS.dyn2Len, ~bufferLS.dyn2Start);
			fBufferRead.value(~testSampleList, ~bufferLS.dyn3Len, ~bufferLS.dyn3Start);
			fBufferRead.value(~testSampleList, ~bufferLS.dyn4Len, ~bufferLS.dyn4Start);
		});
		// R refreshes bufferView
		if((keycode == 15), {
			if(~showBufferView == 1, {
				"BufferView refreshed.".postln;
				fRefreshBufferview.value();
			});
		});
	});

	// display window
	w = Window("dummy").front; w.close;
	~wLiveSampler.front;
	if(~wInOutAvail == 1, {cfg.localAddr.sendMsg("/imageRefresh")}); // request image refresh

	// display bufferview
	if(~showBufferView == 1, {
		~wBufferView = Window.new("LAPIS BufferView", Rect(50, (screenHeight - 710), 1140, 500)).background_(Color.grey(0.9));
		~wBufferViewAvail = 1;
		// A -----------------------
		bufferView[0] = SoundFileView.new(~wBufferView, Rect(20, 30, 477, 200))
		.gridOn_(true)
		.gridResolution_(10)
		.gridColor_(bufferViewColors[1])
		.timeCursorOn_(true)
		.timeCursorColor_(bufferViewColors[3])
		.waveColors_([bufferViewColors[2], bufferViewColors[2]])
		.background_(bufferViewColors[0])
		.canFocus_(false)
		.setSelectionColor(0, bufferViewColors[4])
		.setSelectionColor(1, bufferViewColors[5]);
		// B -----------------------
		bufferView[1] = SoundFileView.new(~wBufferView, Rect(477 + 20, 30, 623, 200))
		.gridOn_(true)
		.gridResolution_(10)
		.gridOffset_(5)
		.gridColor_(bufferViewColors[1])
		.timeCursorOn_(true)
		.timeCursorColor_(bufferViewColors[3])
		.waveColors_([bufferViewColors[2], bufferViewColors[2]])
		.background_(bufferViewColors[0])
		.canFocus_(false)
		.setSelectionColor(0, bufferViewColors[4])
		.setSelectionColor(1, bufferViewColors[5]);
		// C1-4 -----------------------
		4.do({ arg i;
			bufferView[i+2] = SoundFileView.new(~wBufferView, Rect(20 + (i*220), 260, (if(i<3,{220},{440})), 200))
			.gridOn_(true)
			.gridResolution_(10)
			.gridColor_(bufferViewColors[1])
			.timeCursorOn_(true)
			.timeCursorColor_(bufferViewColors[3])
			.waveColors_([bufferViewColors[2], bufferViewColors[2]])
			.background_(bufferViewColors[0])
			.canFocus_(false)
			.setSelectionColor(0, bufferViewColors[4])
			.setSelectionColor(1, bufferViewColors[5]);
		});
		bufferViewLab[0] = StaticText(~wBufferView, Rect(20,10,500,15)).font_(fontBufferView)
		.string_("A                      10                       20                       30                      40                       50                      60");
		bufferViewLab[1] = StaticText(~wBufferView, Rect(475 + 20,10,700,15)).font_(fontBufferView)
		.string_("B          70                      80                       90                     100                     110                    120                    130                     140                     150");
		bufferViewLab[2] = StaticText(~wBufferView, Rect(20,240,1120,15)).font_(fontBufferView)
		.string_("C                     160                     170                    180                     190                    200                    210                     220                    230                     240                    250                     260                    270                     280                     290                    300");

		// keyboard tracking
		~wBufferView.view.keyDownAction_({
			arg view, char, modifiers, unicode, keycode;
			// L clears buffer
			if((keycode == 37), {
				~mainBufLS.zero;
				"Buffer cleared.".postln;
				fRefreshBufferview.value();
			});
			// R refreshes bufferView
			if((keycode == 15), {
				"BufferView refreshed.".postln;
				fRefreshBufferview.value();
			});
		});
		~wBufferView.onClose_({~wBufferViewAvail = nil});
		~wBufferView.front;

		// initialize
		fRefreshBufferview.value();
	}); // display bufferview

	// postln curZone St & Len
	// tCurZone.start;

	// display LapisStatus window
	if(~lapisStatus == 1, {
		LapisStatus.new(inputPeakChans: ~aBus.inputPeakChans, inputPeakStartChan: ~aBus.inputPeakStartChan, font: ~font)
	});

	// initialize local output
	fInitOutput.value(1);

	// initialize lapistatus
	fInitLapisStatus.value();

	// initialize pitchshift range
	fOctavesPitchshift.value();

	// collect garbage
	~wLiveSampler.onClose_({
		OSCdef(\lisaEx3d).free; OSCdef(\lisaArdAna).free; OSCdef(\lisaArdDig).free;
		OSCdef(\lisaNON).free; OSCdef(\lisaNOF).free; OSCdef(\lisaCC).free; OSCdef(\lisaCCLPK).free;
		OSCdef(\lisaSendTrig).free; OSCdef(\lisaPlayHead).free; OSCdef(\lisaBufferViewRefresh).free;
		OSCdef(\lisaExtCtr).free; OSCdef(\lisaExtSw).free; OSCdef(\lisaBut1dis).free; OSCdef(\lisaBut2dis).free;
		OSCdef(\lisaSampleLoad).free; OSCdef(\lisaQuant).free; OSCdef(\lisaPanic).free;
		~mainBufLS.free;
		diskPlay.sampleList.size.do({ arg i;
			if(diskPlay.buf[i].notNil, {diskPlay.buf[i].free});
		});
		~mtfBufLLS.free;
		~mtfBufRLS.free;
		tCurZone.stop;
		zone3.tModSP1.stop;
		// zone16.tModSP1.stop;
		zone16.tModSP4.stop;
		zone8.tPatt1.stop;
		//	if(~wControllersAvail.notNil, {~wControllers.close});
		//	if(~wInOutAvail.notNil, {~wInOut.close});
		//	if(~wSynthKeysAvail.notNil, {~wSynthKeys.close});
		if(~wLapis.notNil, {~wLapis.close});
		if(~wLoadRecordings.notNil, { ~wLoadRecordings.close });
		if(~wCurves.notNil, {~wCurves.close});
		~wLiveSamplerAvail = nil;
		if(~wBufferView.notNil, {~wBufferView.close});
	});

	~testSampleList = ["noisepan.aiff"];

}); // wait for boot

)

