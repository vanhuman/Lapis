// LiveSampler by Robert van Heumen 2011-2015.
// Based upon a setup in STEIM's LiSa combined with junXion.
// Tested with SC 3.7.

// Dependencies:
//	GlobalVars.scd for global variable definitions
//	cfg.libraryBase/Patterns.scd for patterns definitions
//	cfg.libraryBase/SampleLists/~project.scd for sample load mapping
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
		midiSrc: "MUL,EXT", // filtering allowed midi sources; comma-separated list with possibly: MUL = Motu Ultralite, IAC1, IAC2, IAC3, LPK
		quantize:  0, // if value = 1 then loops of zone4 and zone3 will be quantized to cfg.bmp
		bpm: 120, // BPM in quantize case
		copySamples: 1, // set to 1 to activate sample copy on load - make sure the folder /Data/Samples/~project exists
		crashMode: 1, // set to 0 to disable patterns on zone8play1
		bufferViewPlayHeadFreq: 20, // freqency of playhead refresh in bufferView
		bufferViewRefreshFreq: 0.5, // frequency of bufferView refresh while recording
		bufferViewBlocksize: 512, // block size for reading soundfile in bufferview
		bufferViewDeferRead: 1, // defer of reading file in buffer after buffer.write
		sampleDir: "/Users/Robert/---data---/audio/samples/", // location of samples
		docDir: Document.current.dir, // current location
		libDir: "Data/", // library files location
		localAddr: NetAddr("127.0.0.1", 57120), // to send OSC to other SC programs
		touchOSCAddr: NetAddr("169.254.0.3", 57120), // to send OSC to an iPod running TouchOSC
		dragEmptyBeforeLoad: 1, // 1: when dragging, empty buffer before load
	);

	// buffers
	var sRate = s.sampleRate;
	var buffer = ( // when changing these values: test thoroughly as some values might be interdependent, also connected with zoneRec
		mainLen: sRate * 400, processLen: sRate * 30,
		aStart: sRate * 0, aLen: sRate * 65, aTail: sRate * 5, bStart: sRate * 65, bLen: sRate * 85, bTail: sRate * 20,
		dyn1Start: sRate * 150, dyn1Len: sRate * 5, dyn2Start: sRate * 180, dyn2Len: sRate * 5,
		dyn3Start: sRate * 210,  dyn3Len: sRate * 5, dyn4Start: sRate * 240,  dyn4Len: sRate * 5
	);

	// specs
	var spec = (
		// effects dm=deciMate dl=deLay apf=ampPitchFollow mtf=multiTapFreeze
		efxVol: Env.xyc([[0.0, 0.0, \lin], [0.01, 0.001,\exp],[0.3, 0.3, \lin],[1, 1.0]]),
		dmAmp: Env.new([0.01,0.01,0.1,0.1], [0.4,0.6], [\lin]),
		dmProb: Env.new([0.1,0.1,0.9], [0.8,0.2], [\lin]),
		dmMixDec: Env.new([1,1,0,0], [0.2,0.4,0.4], [\lin]),
		dmMixCross: Env.new([0,0,1,1,0], [0.2,0.2,0.2,0.4], [\lin]),
		dmMixDis: Env.new([0,0,1,1], [0.6,0.2,0.2], [\lin]),
		dmDec: Env.new([100,10000], [1], [\lin]),
		dlTime: Env.new([0.2,0.2,1,1],[0.1,0.6,0.3],[\lin]),
		dlMixTrem: Env.new([1,1,0,0],[0.1,0.05,0.85], [\lin]),
		dlMixDelay: Env.new([0,0,1,1,0,0],[0.1,0.05,0.5, 0.05, 0.3],[\lin]),
		dlMixDub: Env.new([0,0,1,1],[0.65, 0.05, 0.3],[\lin]),
		dlFeed: Env.new([0.5,0.5,1.1],[0.7, 0.3],[\lin]),
		dlTremSpeed: ControlSpec.new(0.3,0.01,\exp),
		// dlTremSpeed: ControlSpec.new(1,0.05,\exp),
		dlTremVar0Mix: Env.new([0,0,1,1,0,0],[0.1,0.01,0.78,0.01,0.1],[\lin]),
		dlTremVar1Mix: Env.new([1,1,0,0],[0.1,0.01,0.89],[\lin]),
		dlTremVar2Mix: Env.new([0,0,1,1],[0.89,0.01,0.1],[\lin]),
		apfMixNoise: Env.new([0,0,1,1],[0.15,0.35,0.5], [\lin]),
		apfMixPitch: Env.new([0,0,1,1,0,0],[0.05,0.05,0.15,0.5,0.25], [\lin]),
		apfMixSchr: Env.new([1,1,0,0],[0.05,0.05,0.9], [\lin]),
		mtfVol: Env.new([0,1,1], [0.9,0.1], [\lin]),
		mtfDecay: Env.new([0,0,1,1], [0.5,0.4,0.1], [\lin]),
		mtfMix: Env.new([0,0,1,1], [0.5,0.25,0.25], [\lin]), // mix FreeVerb
		mtfMixTap: Env.new([1,1,0,0], [0.9,0.08,0.02], [\lin]),  // mix Tab
		mtfMixFreeze: Env.new([0,0,1,1], [0.9,0.08,0.02], [\lin]),  // mix Freeze
		mtfFF: Env.new([500,10000], [1], [\lin]),
		// mtfTap: Env.new([3,3,2,1,0,0],[0.125,0.125,0.125,0.125,0.5],[\step]),
		mtfTap1: Env.new([1,1,0,0],[0.1,0.05,0.85],[\lin]),
		mtfTap2: Env.new([0,0,1,1,0,0],[0.1,0.05,0.15,0.05,0.65],[\lin]),
		mtfTap3: Env.new([0,0,1,1,0,0],[0.3,0.05,0.15,0.05,0.45],[\lin]),
		mtfTap4: Env.new([0,0,1,1],[0.5,0.05,0.45],[\lin]),
		mtfRLPFff: Env.new([10000,10000,10],[0.75,0.25],[\lin,\exp]),
		mftRLPFmul: Env.new([10,10,1],[0.5,0.5], [\lin]),
		// zones
		amp21: Env.xyc([[0.0, 0.0, \lin], [0.001, 0.001,\exp],[0.2, 0.2, \lin],[1, 1.0]]),
		dist21: ControlSpec.new(1,cfg.distortionMax,\exp),
		dist21hf: ControlSpec.new(1,cfg.distortionMax,\exp),
		dist21lf: ControlSpec.new(2,cfg.distortionMax,\exp),
		pitch21: ControlSpec.new(0.8,1.2,\lin),
		len21L: Env.xyc([[0, 0.1 * sRate,\exp],[0.5, 30 * sRate, \lin],[1, 60 * sRate]]), // van 0.1 naar 60 sec
		len21R: Env.xyc([[0, 0.1 * sRate,\exp],[0.5, 29.8 * sRate, \lin],[1, 59.6 * sRate]]), // van 0.1 naar 59.6 sec
		startPos21L: ControlSpec.new(buffer.aStart, buffer.aStart + buffer.aLen + buffer.bLen - buffer.bTail, \lin),
		startPos21R: ControlSpec.new(buffer.aStart, buffer.aStart + buffer.aLen + buffer.bLen - buffer.bTail - (0.3*sRate), \lin),
		ff21: ControlSpec.new(50,20000,\exp),
		mix21: Env.new([0,0,1,1,0,0],[0.1,0.05,0.7,0.05,0.1],[\lin]),
		mix21lf: Env.new([1,1,0,0],[0.65,0.05,0.3],[\lin]),
		mix21hf: Env.new([0,0,1,1],[0.3,0.05,0.65],[\lin]),
		spModSpd31: Env.new([0.02,10],[127],[\exp]),
		panSpd31: ControlSpec.new(1,50,\lin),
		ampModSpd31: ControlSpec.new(1,0.01,\exp),
		len31: Env.xyc([[0, 0.1 * sRate,\exp],[0.5, 30 * sRate, \lin],[1, 60 * sRate]]), // van 0.1 naar 60 sec
		ff31: Env.new([10,1000,10000,15000],[0.3,0.5,0.2],[\exp,\lin,\exp]),
		mulHPF31: Env.new([1,1,20,50],[0.3,0.5,0.2],[\lin, \lin, \lin]),
		pitch41: ControlSpec.new(0.8,1.2,\lin),
		pitch412: ControlSpec.new(0.1,1.9,\lin),
		len41: Env.xyc([[0, 0.2,\exp],[64, 30, \lin],[127, 60]]), // van 0.1 naar 60 sec
		ff41: ControlSpec.new(200,20000,\exp),
		len61: ControlSpec.new(10, 0.03,\exp), // van 10 sec naar 0,03 sec
		startPos61: ControlSpec.new(buffer.bStart, buffer.bStart + buffer.bLen - buffer.bTail, \lin, 0.02 * (buffer.bLen - buffer.bTail)),
		pitch61: Env.new([0.1,12],[1],[\exp]),
		// pitch61: ControlSpec.new(0.1,12,\exp),
		dist61: Env.new([cfg.distortionMax,1],[1], [\exp]),
		// dist61: ControlSpec.new(cfg.distortionMax,1,\exp),
		amp61: ControlSpec.new(0.0,1.0,\lin),
		len61Plus1: ControlSpec.new(2, 0.025,\exp), // van 2 sec naar 0,025 sec
		startPos61Plus1: ControlSpec.new(buffer.bStart + (2 * sRate),
			buffer.bStart + buffer.bLen - buffer.bTail + (2 * sRate), \lin, 0.02 * (buffer.bLen - buffer.bTail + (2 * sRate))),
		len61Plus2: ControlSpec.new(6, 0.02,\exp), // van 6 sec naar 0,02 sec
		startPos61Plus2: ControlSpec.new(buffer.bStart + (4 * sRate),
			buffer.bStart + buffer.bLen - buffer.bTail + (4 * sRate), \lin, 0.02 * (buffer.bLen - buffer.bTail + (4 * sRate))),
		len62: ControlSpec.new(1, 0.01,\exp), // van 10 sec naar 0,01 sec
		startPos62: ControlSpec.new(buffer.bStart, buffer.bStart + buffer.bLen - buffer.bTail, \lin, 0.01 * (buffer.bLen - buffer.bTail)),
		ff62: ControlSpec.new(50,5000,\exp),
		pan62: [-1,1,-1,1,-1,1,-1,1,-1].resize(1024, \linear),
		len63: ControlSpec.new(2, 0.015, \exp), // van 2 sec naar 0,02 sec
		startPos63: ControlSpec.new(buffer.bStart, buffer.bStart + buffer.bLen - buffer.bTail, \lin, 0.01 * (buffer.bLen - buffer.bTail)),
		ff63: ControlSpec.new(50,20000,\exp),
		pan63: [1,-1,1].resize(1024, \linear),
		len64: Env.new([2,1,0.005],[0.5,0.5],[\lin,\exp]), // van 2 sec naar 0,005 sec
		startPos64: ControlSpec.new(buffer.aStart, buffer.aStart + buffer.aLen - buffer.aTail, \lin, 0.01 * (buffer.bLen - buffer.bTail)),
		pitch64: ControlSpec.new(0.8,1.2,\exp),
		pan64: [1,-0.5,0].resize(1024, \linear),
		len65: Env.new([3,0.5,0.2],[0.5,0.5]),
		low65: Env.new([0,1,2],[0.5,0.5]),
		high65: Env.new([2,1,0],[0.5,0.5]),
		dec65: Env.new([0,0,0.1,2],[0.2,0.3,0.5]),
		pitch65: ControlSpec.new(0.6,1.4,\exp),
		pan65: [0.5,-0.5,0].resize(1024, \linear),
		ampMod66: Env.new([2,20],[1],[\lin]),
		cutoff66: Env.new([5000,800,50],[0.5,0.5],[\lin]),
		res66: Env.new([0.2,1,2],[0.5,0.5],[\lin]),
		pitch66: Env.new([0.9,1.1],[1],[\lin]),
		dist66: Env.new([10,2],[1],[\lin]),
		freq67: Env.new([1,1000],[1],[\lin]),
		gravAmp67: Env.new([0.01,1],[1],[\lin]),
		cutoff67: Env.new([10000,10],[1],[\lin]),
		ring67: Env.new([100,-10],[1],[\lin]),
		distFftDrone: Env.new([10,1],[1]),
		cutoffFftDrone: Env.new([10000,1000,500],[0.5,0.5],[\lin]),
		pulseFftDrone: Env.new([1,0.3,1],[0.5,0.5]),
		amp21: Env.xyc([[0.0, 0.0, \lin], [0.001, 0.001,\exp],[0.2, 0.2, \lin],[1, 1.0]]),
		amp81: Env.new([0,0.001,0.2,0.7],[0.001, 0.2, 0.8],[\lin,\exp,\lin]),
		len81: Env.xyc([[0, 0.1 * sRate,\exp],[0.5, 30 * sRate, \lin],[1, 60 * sRate]]), // van 0.1 naar 60 sec
		pitch81: Env.xyc([[0, 0.2,\lin],[0.5, 1, \lin],[1, 2]]),
		patt81: nil,
		rate81: Env.new([0.4,1,2],[0.5,0.5]),
		pitch16select: Env.new([0,0,1,2,3,4],[0.1,0.25,0.3,0.25,0.1],[\step]),
		pitch162: Env.new([1,3],[1],[\exp]),
		pitch162up1: Env.new([1,6],[1],[\exp]),
		pitch162up2: Env.new([1,8],[1],[\exp]),
		pitch162down1: Env.new([0.5,1],[1],[\exp]),
		pitch162down2: Env.new([0.1,0.6],[1],[\exp]),
		pitch162lisa1: Env.new(
			[1, 0.6, 2,     1, 1.1,   3,  4,    1, 1.2,  7, 9,  0.5, 1,    9, 10,   1.2, 1.5, 1, 0.3, 0.3,   1,  1,   0.2, 0.1, 0.9, 0.8, 0.05, 0.01,  0.8, 0.3, 5,  1],
			[ 15, 10, 0.01, 3, 0.01, 2, 0.01, 2, 0.01, 9, 0.01, 2, 0.01, 9, 0.01, 6,  20,  1,   2,  0.01, 2, 0.01, 2, 0.01,  2,  0.01,   10,  0.01,   5,  0.1, 5]/115,
			[\exponential]
		),
		pitch162lisa2: Env.new(
			[0.5,  1,     8,   10,    1,   1.2,  6, 7, 0.3, 0.2,  6,   7,     1.5,  0.2,  5,   7,  0.2,  0.01,  1,  2,    0.1,  0.05,    2,  1,  8,  11,   0.4,  0.5],
			[     30, 0.01,  15, 0.01, 35, 0.01,5,10, 25,   40, 20, 0.01,   25,    1,  25, 15,   15,   10, 30, 0.01,  15,   0.01, 5,  3,   20,  0.01,  3] / 355,
			[\exponential]
		),
		pitch162ran: Env.new([1,0.5,5],[0.1, 0.9],[\exp]),
		pan161: ControlSpec.new(-1.0, 1.0, \lin),
		pan164: ControlSpec.new(1.0, -1.0, \lin),
		startPos171: ControlSpec.new(buffer.aStart, buffer.bStart + buffer.bLen - buffer.bTail, \lin,
			0.01 * (buffer.bStart + buffer.bLen - buffer.bTail)),
		amp171: ControlSpec.new(0, 1, \lin),
		dist171: ControlSpec.new(1, 10, \lin),
		tempo171: ControlSpec.new(1,8),
		diskPlayRate: Env.new([33/45,1],[1],[\lin]),
		diskPlayRateMod: Env.new([0,0.05],[1],[\lin])
	);

	// control busses
	var cBus = (
		// joystick
		ex3dProBusX62: Bus.control(s,1).set(0), ex3dProBusX63: Bus.control(s,1).set(0), ex3dProBusX64: Bus.control(s,1).set(0),
		ex3dProBusX65: Bus.control(s,1).set(0), ex3dProBusX66: Bus.control(s,1).set(0), ex3dProBusX67: Bus.control(s,1).set(0),
		ex3dProY: Bus.control(s,1).set(0.5), ex3dProYpitch: Bus.control(s,1).set(spec.pitch61.at(0.5)),
		ex3dProR: Bus.control(s,1).set(0.5), ex3dProS: Bus.control(s,1).set(1),
		// Faderfox LV1, LV2
		midiLV1Fader1: Bus.control(s,1).set(0), midiLV1Fader2: Bus.control(s,1).set(0), midiLV1Fader3: Bus.control(s,1).set(0),
		midiLV1Fader4: Bus.control(s,1).set(0), midiLV1Fader5: Bus.control(s,1).set(0), midiLV1Fader8: Bus.control(s,1).set(0),
		midiLV1KnobA1: Bus.control(s,1).set(0.5), midiLV1KnobA2: Bus.control(s,1).set(0.5), midiLV1KnobB1: Bus.control(s,1).set(0.5),
		midiLV1KnobB2: Bus.control(s,1).set(0.7), midiLV1KnobB3: Bus.control(s,1).set(0.7), midiLV1KnobC1: Bus.control(s,1).set(0.5),
		midiLV1KnobC2: Bus.control(s,1).set(0), midiLV1KnobD1: Bus.control(s,1).set(0.5), midiLV1KnobD2: Bus.control(s,1).set(0),
		midiLV1JoyX: Bus.control(s,1).set(0), midiLV1JoyY: Bus.control(s,1).set(0.5), midiLV1CrossFader: Bus.control(s,1).set(0),
		midiLV1KnobMasterVol: Bus.control(s,1).set(1),
		midiLV2Fader1: Bus.control(s,1).set(0), midiLV2Fader3: Bus.control(s,1).set(0), midiLV2Fader4: Bus.control(s,1).set(0),
		midiLV2Fader5: Bus.control(s,1).set(0), midiLV2Fader6: Bus.control(s,1).set(0), midiLV2Fader7: Bus.control(s,1).set(0),
		midiLV2Fader8: Bus.control(s,1).set(0), midiLV2Fader9: Bus.control(s,1).set(0), midiLV2Fader10: Bus.control(s,1).set(0),
		midiLV2Fader11: Bus.control(s,1).set(0), midiLV2Fader12: Bus.control(s,1).set(0), midiLV2Fader13: Bus.control(s,1).set(0),
		midiLV2Fader14: Bus.control(s,1).set(1),
		midiLV2Fader15: Bus.control(s,1).set(1), midiLV2Fader16: Bus.control(s,1).set(0.7),
		midiLV2KnobA1: Bus.control(s,1).set(spec.len41.at(64)),
		midiLV2KnobB1: Bus.control(s,1).set(0), midiLV2KnobB2: Bus.control(s,1).set(0.5), midiLV2KnobB3: Bus.control(s,1).set(0.5),
		midiLV2KnobC1: Bus.control(s,1).set(0), midiLV2KnobC2: Bus.control(s,1).set(1), midiLV2KnobC3: Bus.control(s,1).set(0),
		midiLV2KnobD1: Bus.control(s,1).set(0), midiLV2KnobD2: Bus.control(s,1).set(0), midiLV2KnobD3: Bus.control(s,1).set(0),
		midiLV2JoyX: Bus.control(s,1).set(1), midiLV2JoyY: Bus.control(s,1).set(0.5), midiLV2JoyY2: Bus.control(s,1).set(0.5),
		midiLV2CrossFader: Bus.control(s,1).set(0), midiLV2KnobMasterVol: Bus.control(s,1).set(1),
		// Arduino
		ardAna1Bus: Bus.control(s,1).set(1),
		// other
		spModBus31: Bus.control(s,1).set(0), ampModOnBus31: Bus.control(s,1).set(0),
		jumpBus81: Bus.control(s,1).set(0), panBus81: Bus.control(s,1).set(0), pitchBus81: Bus.control(s,1).set(0.95),
		ampPattBus81: Bus.control(s,1).set(1), dirBus81: Bus.control(s,1).set(1),
		spModBus161: Bus.control(s,1).set(0), spModBus164: Bus.control(s,1).set(0),
		lenBus161: Bus.control(s,1).set(buffer.dyn1Len / sRate), lenBus162: Bus.control(s,1).set(buffer.dyn2Len / sRate),
		lenBus163: Bus.control(s,1).set(buffer.dyn3Len / sRate), lenBus164: Bus.control(s,1).set(buffer.dyn4Len / sRate),
		// pulseVolBus: Bus.control(s,1).set(0), pulseSpeedBus: Bus.control(s,1).set(0), pulseWidthBus: Bus.control(s,1).set(0)
	);

	// general
	var curZone = "0", curRecZone = "0", curZoneStart = 0, curZoneLen = 0, tCurZone;
	var fAmpCurZone, fBufferRead, fQuantize, fInitOutput, fInitLapisStatus, fSendLapisStatus, fGetInChanEfx;
	var fGetInChanSampling, fSetCurZone, fOctavesPitchshift;
	var onExternalInput = 0; // 0=effects on sample playback, 1=effects on input channels - switchable with red3 button on LX
	var sampleFile, sampleListLV1, sampleListLV2, sampleListLX;

	// remote control
	var button1disable = 0, button2disable = 0, localControl = 1;

	// GUI
	var dispPlay, dispRec, fCountZones, countRec = 0, countPlay = 0, dispEfx, countEfx = 0, loadFileA, loadFileB;
	var screenHeight = Window.screenBounds.height, screenWidth = Window.screenBounds.width;
	var dispBaseBtn, dispBaseBtn2, dispDisablePitch, dispDisableStartPos;
	var colorOff = Color.white;
	var fontLabel = Font("Helvetica",12), fontButton = Font("Helvetica",12);

	// bufferView
	var bufferView = Array.newClear(6), curPlayHead = 0, curRecHead = 0, fileBufferView = SoundFile.new().dup(6);
	var bufferViewFolder = Archive.archiveDir ++ "/bufferViewTemp/", fDisplayBufferView, fRefreshBufferview;
	var bufferViewLab = Array.newClear(3);
	var bufferViewColors = [Color.white, Color.grey, Color.green(0.3), Color.black, Color.blue(1,0.3), Color.red];
	// background, grid, waveforms, playbackhead, selection, selection recording
	// zones
	var zone2 = (play1L: nil, play1R: nil, play1Act: 0, startPos1: 0, play1hf: nil, play1hfAct: 0, play1lf: nil, play1lfAct: 0);
	var zone3 = (
		play1: nil, play1Act: 0, startPos1: 0,
		stepsOffset1: Array.new(24), stepsOffset1tmp: Array.new(24),
		spModSpd1: 127, tModSP1: nil
	);
	var fModSP31;
	var zone4 = (play1: nil, play1Act: 0, startPos1: 0, play1hf: nil, play1hfAct: 0, play1lf: nil, play1lfAct: 0);
	var zone6 = (
		play1: Array.new(50), play1Act: 0, startPos1: 0, play1St: 0, play1Nbr: 0, play1Add: 0.2,
		disablePitch: 0, disableStartPos: 0, disableXhid: 0, octavesPitchshift: 0,
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

	// zoneRec
	var zoneRec = (
		ch1A: nil, ch1B: nil, ch2A: nil, ch2B: nil, dynOverflow: 0.05, dynLenMax: 30, dynLenMaxFrames: 30*sRate,
		dyn1: nil, dyn1St: nil, dyn2: nil, dyn2St: nil, dyn3: nil, dyn3St:nil, dyn4: nil, dyn4St: nil, len1: 5,
		dyn1SavedLen: 5, dyn2SavedLen: 5, dyn3SavedLen: 5, dyn4SavedLen: 5
	);

	// just playing samples from green buttons keysets 2 & 3
	var dpIndex, diskPlay = (), diskPlayFile;

	// effects
	var efx1Act = 0, efxBank = 1, efx2Act = 0;

	// Vanoli Pulse
	// var zonePulse = ( play1: nil, play1Act: 0 );

	/////////////////////////////////////////////  initialize variables //////////////////////////////////////

	var mainBuf = Buffer.alloc(s, buffer.mainLen, 2);
	var mtfBufL = Buffer.alloc(s, sRate*3,1), mtfBufR = Buffer.alloc(s, sRate*3,1); // buffers for effect multiTapFreeze

	// load global variables
	"GlobalVars.scd".loadRelative();

	zone8.patt1Def = 0; // default pattern
	zone8.patt1 = (cfg.libDir++"Patterns.scd").loadRelative[0][0]; // load pattern definitions
	spec.patt81 = Array.iota(zone8.patt1.size);
	spec.patt81 = spec.patt81.resize(128, \step);

	// accomodate in case Arduino is not available
	if(~noArduino == 1, {
		"\nLiveSampler: Remapping dist61 because no Arduino availabe".postln;
		spec.dist61 = Env.new([cfg.distortionMax,1,1],[0.5,0.5], [\exp,\lin]);
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
	sampleListLX = sampleFile[2]; // blue keysets 1, 2 & 3 & green keyset 1
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

	///////////////////////////////////////////// Synths //////////////////////////////////////

	////////// Recording //////////////////////////////////////

	SynthDef(\zoneRec, { // general recording zone for mono recording
		arg gate, chan1, chan2, start, len, recZone; // start/stop env, input chan, start pos (frames), length (secs), unique ID for curRecZone
		var playHead;
		// update bufferView
		if(~showBufferView == 1,{
			playHead = (Phasor.ar(1,1, start, start + (len*sRate), start)) % BufFrames.kr(mainBuf);
			SendReply.kr(Impulse.kr(cfg.bufferViewPlayHeadFreq), "/playHead", [playHead/sRate, start/sRate, len], recZone);
			SendReply.kr(Impulse.kr(cfg.bufferViewRefreshFreq),"/bufferViewRefresh", start, recZone);
		});
		RecordBuf.ar(In.ar([chan1,chan2]), mainBuf, start, loop: 0) *
		EnvGen.kr(Env.linen(0,len,0), gate, doneAction: 2);
	}).send(s);

	SynthDef(\zoneRecDyn, {  // dynamic length recording zone for mono recording
		arg gate, chan1, chan2, start, len, recZone;  // start/stop env, input chan, start pos (frames), length (secs), unique ID for curRecZone
		var playHead;
		// update bufferView
		if(~showBufferView == 1, {
			playHead = (Phasor.ar(1,1, start, start + (len*sRate), start)) % BufFrames.kr(mainBuf);
			SendReply.kr(Impulse.kr(cfg.bufferViewPlayHeadFreq), "/playHead", [playHead/sRate, start/sRate, len], recZone);
			SendReply.kr(Impulse.kr(cfg.bufferViewRefreshFreq),"/bufferViewRefresh", start, recZone);
		});
		RecordBuf.ar(In.ar([chan1,chan2]), mainBuf, start, loop: 0) *
		EnvGen.kr(Env.linen(0,len,0), gate, doneAction: 2);
	}).send(s);

	////////// Zone 2 MIDI //////////////////////////////////////

	SynthDef(\zone2play1L, { // with zone2play1R triggered by LV1 fader1, going out of phase
		arg gate, ampBus, startPosition = 0, lenBus, distBus, resetPosBus, ffBus, mixBus;
		// start/stop env, start pos (frames), busses range 0-1 for length, amplitude, distortion, reset playhead, filter freq
		// control by: LV1 fader1, fader1, fader2, knobA1, crossfader, joyX, mastervolknob
		var sig, lenBusVal, resetTrig, resetPosBusVal, playHead, mixBusVal;

		lenBusVal = IEnvGen.kr(spec.len21L, In.kr(lenBus,1)); 	// in frames
		resetPosBusVal = In.kr(resetPosBus,1) * lenBusVal; 		// in frames
		startPosition = spec.startPos21L.map(startPosition); 	// in frames
		resetTrig = HPZ2.kr(In.kr(resetPosBus,1)); 					// detect a change in the resetPosBus value
		mixBusVal = IEnvGen.kr(spec.mix21, In.kr(mixBus,1));

		//	Poll.kr(Impulse.kr(20), startPosition/sRate);
		playHead = ( Phasor.ar(
			resetTrig,										// reset
			BufRateScale.kr(mainBuf), 			// rate
			startPosition, 								// start
			startPosition + lenBusVal,			// end
			startPosition + resetPosBusVal  	// resetPos
		) ) % BufFrames.kr(mainBuf);

		// update bufferView
		if(~showBufferView == 1, {SendReply.kr(Impulse.kr(cfg.bufferViewPlayHeadFreq), "/playHead",
			[playHead/sRate, startPosition/sRate, lenBusVal/sRate], 21)});

		sig = BufRd.ar(2, mainBuf, playHead,	1, 4) * EnvGen.kr(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
		sig = IEnvGen.kr(spec.amp21, In.kr(ampBus,1)) * sig; 		// volume bus
		sig = spec.dist21.map(In.kr(distBus,1)) * sig;						// distortion bus
		sig = Balance2.ar(sig[0], sig[1],-1);										// panning hard left
		sig = RLPF.ar(sig, spec.ff21.map(In.kr(ffBus,1)), 0.5);		// low pass filter
		Out.ar(~aBus.outA, sig*mixBusVal);
	}).send(s);

	SynthDef(\zone2play1R, { // with zone2play1L triggered by LV1 fader1, going out of phase
		arg gate, startPosition = 0, lenBus, ampBus, distBus, pitchBus, resetPosBus, ffBus, mixBus;
		// start/stop env, start pos (frames), busses range 0-1 for length, amplitude, distortion, pitch, reset playhead, filter freq
		// control by: LV1 fader1, fader1, fader2, knobA1, crossfader, joyY, joyX, mastervolknob
		var sig, lenBusVal, resetTrig, resetPosBusVal, playHead, mixBusVal;

		lenBusVal = IEnvGen.kr(spec.len21R, In.kr(lenBus,1)); 	// in frames
		resetPosBusVal = In.kr(resetPosBus,1) * lenBusVal; 		// in frames
		startPosition = spec.startPos21R.map(startPosition); 	// in frames
		resetTrig = HPZ2.kr(In.kr(resetPosBus,1)); 					// detect a change in the resetPosBus value
		mixBusVal = IEnvGen.kr(spec.mix21, In.kr(mixBus,1));

		playHead = ( Phasor.ar(
			resetTrig,																							// reset
			spec.pitch21.map(In.kr(pitchBus,1)) * BufRateScale.kr(mainBuf), // rate
			startPosition, 																					// start
			startPosition + lenBusVal,																// end
			startPosition + resetPosBusVal														// resetPos
		) ) % BufFrames.kr(mainBuf);

		sig = BufRd.ar(2, mainBuf, playHead, 1, 4) * EnvGen.kr(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
		sig = IEnvGen.kr(spec.amp21, In.kr(ampBus,1)) * sig;		// volume bus
		sig = spec.dist21.map(In.kr(distBus,1)) * sig;						// distortion bus
		sig = Balance2.ar(sig[0], sig[1],1);										// panning hard right
		sig = RLPF.ar(sig, spec.ff21.map(In.kr(ffBus,1)), 0.5);		// low pass filter
		Out.ar(~aBus.outA, sig*mixBusVal);
	}).send(s);

	SynthDef(\zone2play1hf, { // triggered by LV1 fader1 when value more than 0.97
		arg gate, startPosition = 0, lenBus, distBus, resetPosBus, mixBus;
		// start/stop env, start pos (frames), busses range 0-1 for length, distortion, reset playhead
		// control by: LV1 fader1, fader2, knobA1, crossfader, joyX
		var sig, lenBusVal, resetTrig, resetPosBusVal, playHead, mixBusVal;

		lenBusVal = IEnvGen.kr(spec.len21R, In.kr(lenBus,1)); 	// in frames
		resetPosBusVal = In.kr(resetPosBus,1) * lenBusVal;		// in frames
		startPosition = spec.startPos21R.map(startPosition);		// in frames
		resetTrig = HPZ2.kr(In.kr(resetPosBus,1));						// detect change in the resetPosBus value
		mixBusVal = IEnvGen.kr(spec.mix21hf, In.kr(mixBus,1));

		playHead = ( Phasor.ar(
			resetTrig,												// reset
			(2**4) * BufRateScale.kr(mainBuf), 	// rate
			startPosition, 										// start
			startPosition + lenBusVal,					// end
			startPosition + resetPosBusVal			// resetPos
		) ) % BufFrames.kr(mainBuf);

		sig = BufRd.ar(2, mainBuf, playHead, 1, 4) * EnvGen.kr(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
		sig = spec.dist21hf.map(In.kr(distBus,1)) * sig; // distortion bus
		Out.ar(~aBus.outA, sig*mixBusVal);
	}).send(s);

	SynthDef(\zone2play1lf, {  // triggered by LV1 fader1 when value more than 0.99
		arg gate, startPosition = 0, lenBus, distBus, resetPosBus, mixBus;
		// start/stop env, start pos (frames), busses range 0-1 for length, distortion, reset playhead
		// control by: LV1 fader1, fader2, knobA1, crossfader, joyX
		var sig, lenBusVal, resetTrig, resetPosBusVal, playHead, mixBusVal;

		lenBusVal = IEnvGen.kr(spec.len21R, In.kr(lenBus,1));		// in frames
		resetPosBusVal = In.kr(resetPosBus,1) * lenBusVal;			// in frames
		startPosition = spec.startPos21R.map(startPosition);			// in frames
		resetTrig = HPZ2.kr(In.kr(resetPosBus,1));							// detect change in the resetPosBus value
		mixBusVal = IEnvGen.kr(spec.mix21lf, In.kr(mixBus,1));

		playHead = ( Phasor.ar(
			resetTrig,												// reset
			(0.5**4) * BufRateScale.kr(mainBuf), 	// rate
			startPosition, 										// start
			startPosition + lenBusVal,					// end
			startPosition + resetPosBusVal			// resetPos
		) ) % BufFrames.kr(mainBuf);

		sig = BufRd.ar(2, mainBuf, playHead, 1, 4) * EnvGen.kr(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
		sig = spec.dist21lf.map(In.kr(distBus,1)) * sig; // distortion bus
		Out.ar(~aBus.outA, sig*mixBusVal);
	}).send(s);

	////////// Zone 3 MIDI //////////////////////////////////////

	SynthDef(\zone3play1, {
		arg gate, lenBus, startPosition = 0, ampBus, distBus, pitchBus, resetPosBus, panSpdBus, ampModSpdBus, ampModOnBus, ffBus;
		var sig, lenBusVal, resetTrig = 1, resetPosBusVal, ampModSpdVal, ampModBusOnVal, ffBusVal, playHead;

		lenBusVal = IEnvGen.kr(spec.len31, In.kr(lenBus,1));
		resetPosBusVal = In.kr(resetPosBus,1) * lenBusVal;
		startPosition = spec.startPos21L.map(startPosition);
		resetTrig = HPZ2.kr(In.kr(resetPosBus,1));
		ampModSpdVal = In.kr(ampModSpdBus,1);
		ampModBusOnVal = In.kr(ampModOnBus,1);
		ffBusVal = In.kr(ffBus,1);

		playHead = ( Phasor.ar(
			resetTrig,
			spec.pitch21.map(In.kr(pitchBus,1)) * BufRateScale.kr(mainBuf),
			startPosition,
			startPosition + lenBusVal,
			startPosition + resetPosBusVal
		) ) % BufFrames.kr(mainBuf);
		if(~showBufferView == 1,
			{SendReply.kr(Impulse.kr(cfg.bufferViewPlayHeadFreq), "/playHead", [playHead/sRate, startPosition/sRate, lenBusVal/sRate], 31)});

		sig = BufRd.ar(2, mainBuf, playHead, 1, 4 ) * EnvGen.kr(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
		sig = IEnvGen.kr(spec.amp21, In.kr(ampBus,1)) * sig;
		sig = spec.dist21.map(In.kr(distBus,1)) * sig;
		sig = (ffBusVal.ceil * RHPF.ar(sig, IEnvGen.kr(spec.ff31, ffBusVal), 0.5, IEnvGen.kr(spec.mulHPF31, ffBusVal))) +
		((1 - ffBusVal.ceil) * sig); // if ffBusVal=0, don't go through filter
		sig = Balance2.ar(sig[0], sig[1], LFNoise1.ar(spec.panSpd31.map(In.kr(panSpdBus,1))));
		sig =
		((1 - ampModBusOnVal) * sig) +
		// on/off modulation, clicky
		//		(ampModBusOnVal * sig * LFPulse.ar(1 / spec.ampModSpd31.map(ampModSpdVal)));
		// sine modulation, too smooth maybe
		//		(ampModBusOnVal * sig * SinOsc.ar(1 / spec.ampModSpd31.map(ampModSpdVal)).range(0,1));
		// a mix between the above, depending on the mod speed
		(ampModBusOnVal * sig * ampModSpdVal *
			SinOsc.ar(1 / spec.ampModSpd31.map(ampModSpdVal)).range(0,1)) +
		(ampModBusOnVal * sig * (1 - ampModSpdVal) *
			LFPulse.ar(1 / spec.ampModSpd31.map(ampModSpdVal)));
		Out.ar(~aBus.outA, sig);
	}).send(s);

	////////// Zone 4 MIDI //////////////////////////////////////

	SynthDef(\zone4play1, {
		arg gate, lenBus, startPosition = 0, ampBus, distBus, pitchBus, pitch2Bus, ffBus;
		var trig, sig, lenBusVal, playHead, sign, trig2;

		lenBusVal = In.kr(lenBus,1);
		//	trig = Impulse.ar(1 / IEnvGen.kr(spec.len41, In.kr(lenBus,1)));
		trig = Impulse.ar(1 / lenBusVal);

		if(~showBufferView == 1, {
			trig2 = Impulse.ar(1 / (lenBusVal * 2));
			sign = LFPulse.ar(1 / (lenBusVal * 2), width: 0.5).range(-1,1);

			playHead = ( Phasor.ar(
				trig2,
				spec.pitch41.map(In.kr(pitchBus,1)) * BufRateScale.kr(mainBuf) * sign,
				spec.startPos21L.map(startPosition),
				spec.startPos21L.map(startPosition) + (lenBusVal*2*sRate),
				spec.startPos21L.map(startPosition)
			) ) % BufFrames.kr(mainBuf);
			SendReply.kr(Impulse.kr(cfg.bufferViewPlayHeadFreq), "/playHead",
				[playHead/sRate, spec.startPos21L.map(startPosition)/sRate, lenBusVal], 41)
		});
		//	SendTrig.kr(Impulse.kr(4),1,In.kr(lenBus,1));

		sig = PlayBufAlt.ar(2, mainBuf,
			spec.pitch41.map(In.kr(pitchBus,1)) * spec.pitch412.map(In.kr(pitch2Bus,1)) * BufRateScale.kr(mainBuf),
			trig, spec.startPos21L.map(startPosition), 1, lag: cfg.playBufLag
		) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
		sig = IEnvGen.kr(spec.amp21, In.kr(ampBus,1)) * sig;
		sig = spec.dist21.map(In.kr(distBus,1)) * sig;
		sig = RLPF.ar(sig, spec.ff41.map(In.kr(ffBus,1) + (0.2 * LFNoise1.kr(2))), 0.5 + (0.1 * LFNoise1.kr(1)));
		Out.ar(~aBus.outA, sig);
	}).send(s);

	SynthDef(\zone4play1hf, {
		arg gate, lenBus, startPosition = 0, distBus;
		var trig, sig;

		//	trig = Impulse.ar(1 / IEnvGen.kr(spec.len41, In.kr(lenBus,1)));
		trig = Impulse.ar((2**3) * BufRateScale.kr(mainBuf) / In.kr(lenBus,1));

		sig = PlayBufAlt.ar(2, mainBuf, (2**3) * BufRateScale.kr(mainBuf), trig, spec.startPos21L.map(startPosition), 1, lag: cfg.playBufLag
		) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
		sig = spec.dist21hf.map(In.kr(distBus,1)) * sig;
		Out.ar(~aBus.outA, sig);
	}).send(s);

	SynthDef(\zone4play1lf, {
		arg gate, lenBus, startPosition = 0, distBus;
		var trig, sig;

		trig = Impulse.ar(1 / In.kr(lenBus,1));
		sig = PlayBufAlt.ar(2, mainBuf, (0.5**3) * BufRateScale.kr(mainBuf), trig, spec.startPos21L.map(startPosition), 1, lag: cfg.playBufLag
		) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
		sig = spec.dist21lf.map(In.kr(distBus,1)) * sig;
		Out.ar(~aBus.outA, sig);
	}).send(s);

	////////// Zone 6 joystick //////////////////////////////////////

	SynthDef(\zone6play1, { // trigger button
		arg gate, lenBus, startPosition = 0, distBus, pitchBus;
		var trig, sig, lenBusVal, playHead, pitchBusVal;

		lenBusVal = spec.len61.map(In.kr(lenBus,1));
		// pitchBusVal = spec.pitch61.map(In.kr(pitchBus,1));
		// pitchBusVal = IEnvGen.kr(spec.pitch61, In.kr(pitchBus,1));
		pitchBusVal = In.kr(pitchBus,1); // pitchBus already spec'd in OSCresponder
		trig = Impulse.ar(1 / lenBusVal);

		if(~showBufferView == 1,{
			playHead = ( Phasor.ar(
				trig,
				pitchBusVal * BufRateScale.kr(mainBuf),
				spec.startPos61.map(startPosition),
				spec.startPos61.map(startPosition) + ((lenBusVal*pitchBusVal)*sRate),
				spec.startPos61.map(startPosition)
			) ) % BufFrames.kr(mainBuf);
			SendReply.kr(Impulse.kr(cfg.bufferViewPlayHeadFreq), "/playHead",
				[playHead/sRate, spec.startPos61.map(startPosition)/sRate, lenBusVal*pitchBusVal], 61)
		});

		sig = PlayBufCF.ar(2, mainBuf, pitchBusVal * BufRateScale.kr(mainBuf), trig, spec.startPos61.map(startPosition), 1,
			lag: cfg.playBufLag
		) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
		sig = IEnvGen.kr(spec.dist61, In.kr(distBus,1)) * sig;
		Out.ar(~aBus.outB, sig);
	}).send(s);

	SynthDef(\zone6play1Plus, { // trigger button
		arg gate, lenBus, startPosition = 0, distBus, pitchBus;
		var trig1, trig2, sig1, sig2, sig;

		trig1 = Impulse.ar(1 / spec.len61Plus1.map(In.kr(lenBus,1)));
		trig2 = Impulse.ar(1 / spec.len61Plus2.map(In.kr(lenBus,1)));

		sig1 = PlayBufCF.ar(2, mainBuf,
			// spec.pitch61.map(In.kr(pitchBus,1)) * BufRateScale.kr(mainBuf),
			// IEnvGen.kr(spec.pitch61,In.kr(pitchBus,1)) * BufRateScale.kr(mainBuf),
			In.kr(pitchBus,1) * BufRateScale.kr(mainBuf), // pitchBus already spec'd in OSCresponder
			trig1, spec.startPos61Plus1.map(startPosition), 1, lag: cfg.playBufLag
		) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
		sig2 = PlayBufCF.ar(2, mainBuf,
			// spec.pitch61.map(In.kr(pitchBus,1)) * BufRateScale.kr(mainBuf),
			// IEnvGen.kr(spec.pitch61,In.kr(pitchBus,1)) * BufRateScale.kr(mainBuf),
			In.kr(pitchBus,1) * BufRateScale.kr(mainBuf), // pitchBus already spec'd in OSCresponder
			trig2, spec.startPos61Plus2.map(startPosition), 1, lag: cfg.playBufLag
		) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);

		sig1 = Balance2.ar(sig1[0], sig1[1],-0.8);
		sig2 = Balance2.ar(sig2[0], sig2[1],0.8);
		sig = sig1 + sig2;
		sig = IEnvGen.kr(spec.dist61, In.kr(distBus,1)) * sig;
		Out.ar(~aBus.outB, sig);
	}).send(s);

	SynthDef(\zone6play2, { // side button
		arg gate, lenBus, startPosition = 0, distBus, ffBus, panBus;
		var trig, sig, playHead, lenBusVal;

		lenBusVal = spec.len62.map(In.kr(lenBus,1));
		trig = Impulse.ar(1 / lenBusVal);

		if(~showBufferView == 1, {
			playHead = ( Phasor.ar(
				trig,
				BufRateScale.kr(mainBuf),
				spec.startPos62.map(startPosition),
				spec.startPos62.map(startPosition) + (lenBusVal*sRate),
				spec.startPos62.map(startPosition)
			) ) % BufFrames.kr(mainBuf);
			SendReply.kr(Impulse.kr(cfg.bufferViewPlayHeadFreq), "/playHead",
				[playHead/sRate, spec.startPos62.map(startPosition)/sRate, lenBusVal], 62)
		});

		sig = PlayBufCF.ar(2, mainBuf, BufRateScale.kr(mainBuf), trig, spec.startPos62.map(startPosition), 1, lag: cfg.playBufLag
		) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
		sig = IEnvGen.kr(spec.dist61, In.kr(distBus,1)) * sig;
		sig = RHPF.ar(sig, spec.ff62.map(In.kr(ffBus,1)), 0.5);
		sig = Balance2.ar(sig[0], sig[1],In.kr(panBus,1));
		Out.ar(~aBus.outB, sig);
	}).send(s);

	SynthDef(\zone6play3, { // top button
		arg gate, lenBus, startPosition = 0, distBus, ffBus, panBus;
		var trig, sig, playHead, lenBusVal;

		lenBusVal = spec.len63.map(In.kr(lenBus,1));
		trig = Impulse.ar(1 / lenBusVal);

		if(~showBufferView == 1, {
			playHead = ( Phasor.ar(
				trig,
				BufRateScale.kr(mainBuf),
				spec.startPos63.map(startPosition),
				spec.startPos63.map(startPosition) + (lenBusVal*sRate),
				spec.startPos63.map(startPosition)
			) ) % BufFrames.kr(mainBuf);
			SendReply.kr(Impulse.kr(cfg.bufferViewPlayHeadFreq), "/playHead",
				[playHead/sRate, spec.startPos63.map(startPosition)/sRate, lenBusVal], 63)
		});

		sig = PlayBufCF.ar(2, mainBuf, BufRateScale.kr(mainBuf), trig, spec.startPos63.map(startPosition), 1, lag: cfg.playBufLag
		) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
		sig = IEnvGen.kr(spec.dist61, In.kr(distBus,1)) * sig;
		sig = RLPF.ar(sig, spec.ff63.map(In.kr(ffBus,1)), 0.5);
		sig = Balance2.ar(sig[0], sig[1],In.kr(panBus,1));
		Out.ar(~aBus.outB, sig);
	}).send(s);

	SynthDef(\zone6play4, { // base button 1
		arg gate, lenBus, startPosition = 0, distBus, pitchBus, panBus;
		var trig, sig, playHead, lenBusVal, pitchBusVal;

		lenBusVal = IEnvGen.kr(spec.len64,In.kr(lenBus,1));
		pitchBusVal = spec.pitch64.map(In.kr(pitchBus,1));

		trig = Impulse.ar(1 / lenBusVal);
		//	SendTrig.kr(Impulse.kr(4),1,In.kr(panBus,1));

		if(~showBufferView == 1, {
			playHead = ( Phasor.ar(
				trig,
				BufRateScale.kr(mainBuf),
				spec.startPos64.map(startPosition),
				spec.startPos64.map(startPosition) + (lenBusVal*pitchBusVal*sRate),
				spec.startPos64.map(startPosition)
			) ) % BufFrames.kr(mainBuf);
			SendReply.kr(Impulse.kr(cfg.bufferViewPlayHeadFreq), "/playHead",
				[playHead/sRate, spec.startPos64.map(startPosition)/sRate, lenBusVal*pitchBusVal], 64)
		});

		sig = PlayBufCF.ar(2, mainBuf, pitchBusVal * BufRateScale.kr(mainBuf), trig, spec.startPos64.map(startPosition), 1,
			lag: cfg.playBufLag
		) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
		sig = IEnvGen.kr(spec.dist61, In.kr(distBus,1)) * sig;
		sig = Balance2.ar(sig[0], sig[1],In.kr(panBus,1));
		Out.ar(~aBus.outB, sig);
	}).send(s);

	// SynthDef(\zone6play5, { // base button 2 --- not used
	// 	arg gate, lenBus, startPosition = 0, distBus, pitchBus, panBus;
	// 	var trig, sig, playHead, lenBusVal, pitchBusVal;
	//
	// 	lenBusVal = spec.len65.at(In.kr(lenBus,1));
	// 	pitchBusVal = spec.pitch65.map(In.kr(pitchBus,1));
	//
	// 	trig = Impulse.ar(1 / lenBusVal);
	//
	// 	if(~showBufferView == 1,{
	// 		playHead = (
	// 			Phasor.ar(
	// 				trig,
	// 				pitchBusVal * BufRateScale.kr(mainBuf),
	// 				spec.startPos64.map(startPosition),
	// 				spec.startPos64.map(startPosition) + (lenBusVal*pitchBusVal*sRate),
	// 				spec.startPos64.map(startPosition)
	// 			)
	// 		) % BufFrames.kr(mainBuf);
	// 		SendReply.kr(Impulse.kr(cfg.bufferViewPlayHeadFreq), "/playHead",
	// 		[playHead/sRate, spec.startPos64.map(startPosition)/sRate, lenBusVal*pitchBusVal], 65)
	// 	});
	//
	// 	sig = PlayBufCF.ar(
	// 		2,
	// 		mainBuf,
	// 		pitchBusVal * BufRateScale.kr(mainBuf),
	// 		trig,
	// 		spec.startPos64.map(startPosition),
	// 		1,
	// 		lag: cfg.playBufLag
	// 	) * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
	// // sig = spec.dist61.map(In.kr(distBus,1)) * sig;
	// sig = IEnvGen.kr(spec.dist61, In.kr(distBus,1)) * sig;
	// 	sig = Balance2.ar(sig[0], sig[1],In.kr(panBus,1));
	// 	Out.ar(~aBus.outB, sig);
	// }).send(s);

	////////// Zone 8 MIDI //////////////////////////////////////

	SynthDef(\zone8play1, {
		arg gate, lenBus, startPosition = 0, ampBus, distBus, pitchPattBus, jumpBus, panBus, ampPattBus, dirBus, pitchBus, pattSelBus;
		var sig, lenBusVal, resetTrig = 1, jumpBusVal, playHead, rateOn, rate, winSize, winRanRatio, winOverlaps, pitch;

		// map params dependent on rateOn, so dependent on the pattern select knob
		rate = IEnvGen.kr(spec.rate81, In.kr(pitchBus,1));
		rateOn = ( In.kr(pattSelBus,1) < 0.05 );
		rate = (rateOn * rate) + (1-rateOn);
		winSize = (rateOn * 0.2) + ((1-rateOn) * 0.1);
		winRanRatio = (rateOn * 0.5) + ((1-rateOn) * 0.2);
		winOverlaps = (rateOn * 8) + ((1-rateOn) * 4);
		pitch = rateOn + ( (1-rateOn)*IEnvGen.kr(spec.pitch81, In.kr(pitchBus,1)) );

		lenBusVal = IEnvGen.kr(spec.len81, In.kr(lenBus,1)) / rate;
		jumpBusVal = In.kr(jumpBus,1) / rate;
		startPosition = spec.startPos21L.map(startPosition) / rate;
		resetTrig = HPZ2.kr(jumpBusVal);

		playHead = ( Phasor.ar(
			resetTrig,
			// IEnvGen.kr(spec.pitch81, In.kr(pitchBus,1)) * In.kr(pitchPattBus,1) *  // uncomment in case of using BufRd
			BufRateScale.kr(mainBuf) * In.kr(dirBus,1),
			startPosition,
			startPosition + lenBusVal,
			startPosition + (jumpBusVal % lenBusVal)
		) ) % BufFrames.kr(mainBuf);
		playHead = rate * playHead;

		// update bufferView
		if(~showBufferView == 1,
			{SendReply.kr(Impulse.kr(cfg.bufferViewPlayHeadFreq), "/playHead",
				[playHead/sRate, startPosition/sRate*rate, lenBusVal/sRate*rate], 81)});

		// sig = BufRd.ar(2, mainBuf, playHead, 1,  4);
		sig = Warp1.ar(2, mainBuf, playHead/BufFrames.kr(mainBuf), pitch * In.kr(pitchPattBus,1),
			winSize, -1, winOverlaps, winRanRatio, 4);
		sig = sig * EnvGen.kr(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
		sig = IEnvGen.kr(spec.amp81, In.kr(ampBus,1)) * sig;
		sig = spec.dist21.map(In.kr(distBus,1)) * sig;
		sig = In.kr(ampPattBus,1) * sig;
		sig = Balance2.ar(sig[0], sig[1],In.kr(panBus,1));
		Out.ar(~aBus.outA, sig);
	}).send(s);

	////////// Zone 16 MIDI //////////////////////////////////////

	SynthDef(\zone16play1_old_version, {
		arg gate, ampBus, distBus, resetPosBus, lenBus, panBus, ffBus;
		var sig, resetTrig = 1, resetPosBusVal, lenBusVal, playHead;

		lenBusVal = In.kr(lenBus,1) * sRate;
		resetPosBusVal = In.kr(resetPosBus,1) * lenBusVal;
		resetTrig = HPZ2.kr(In.kr(resetPosBus,1));

		playHead = ( Phasor.ar(
			resetTrig,
			BufRateScale.kr(mainBuf),
			buffer.dyn1Start,
			buffer.dyn1Start + lenBusVal,
			buffer.dyn1Start + resetPosBusVal
		) ) % BufFrames.kr(mainBuf);

		// update bufferView
		if(~showBufferView == 1,
			{SendReply.kr(Impulse.kr(cfg.bufferViewPlayHeadFreq), "/playHead",
				[playHead/sRate, buffer.dyn1Start/sRate, lenBusVal/sRate], 161)});

		// sig = Warp1.ar(2, mainBuf, playHead / BufFrames.kr(mainBuf)) * EnvGen.kr(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
		sig = BufRd.ar(2, mainBuf, playHead, 1, 4) * EnvGen.kr(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
		sig = IEnvGen.kr(spec.amp21, In.kr(ampBus,1)) * sig;
		sig = spec.dist21.map(In.kr(distBus,1)) * sig;
		sig = Balance2.ar(sig[0], sig[1],spec.pan161.map(In.kr(panBus,1)));
		sig = RLPF.ar(sig, spec.ff21.map(In.kr(ffBus,1)), 0.5);
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
		startPos = buffer.dyn1Start + (startFactor * lenBusVal * sRate);

		// update bufferView
		if(~showBufferView == 1, {
			playHead = Phasor.ar(
				trig,
				BufRateScale.kr(mainBuf),
				startPos,
				startPos + (lenFactor * min(lenBusVal,1)),
				startPos
			) % BufFrames.kr(mainBuf);
			SendReply.kr(Impulse.kr(cfg.bufferViewPlayHeadFreq), "/playHead",
				[playHead/sRate, buffer.dyn1Start/sRate, lenBusVal/sRate], 161)
		});

		env = EnvGen.ar(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
		sig = PlayBufCF.ar(2,mainBuf, trigger: trig, lag: 0.05, n: 2, startPos: startPos);
		sig = IEnvGen.kr(spec.amp21, In.kr(ampBus,1)) * sig;
		sig = spec.dist21.map(In.kr(distBus,1)) * sig;
		sig = Balance2.ar(sig[0], sig[1],spec.pan161.map(In.kr(panBus,1)));
		sig = RLPF.ar(sig, spec.ff21.map(In.kr(ffBus,1)), 0.5);
		Out.ar(~aBus.outA, sig);
	}).send(s);

	2.do { |i|
		SynthDef("zone16play2" ++ if(i==0, {""}, {"bw"}), {
			arg gate, ampBus, lenBus, distBus, pitchRangeBus, pitchSelectBus;
			var trig, sig, pitchArray, pitchSelected, playHead, sign, trig2, lenBusVal;

			lenBusVal = In.kr(lenBus,1);
			pitchArray = [
				IEnvGen.kr(spec.pitch162, LFTri.ar(0.2).range(0,In.kr(pitchRangeBus,1))),
				IEnvGen.kr(spec.pitch162up1, LFSaw.ar(0.4).range(0,In.kr(pitchRangeBus,1))),
				IEnvGen.kr(spec.pitch162down1, LFSaw.ar(0.4).range(1, (1 - In.kr(pitchRangeBus,1)))),
				IEnvGen.kr(spec.pitch162lisa1, LFSaw.ar(0.3).range(0,In.kr(pitchRangeBus,1))),
				IEnvGen.kr(spec.pitch162ran, LFNoise0.ar(100).range(0,In.kr(pitchRangeBus,1)))
			];
			pitchSelected = Select.kr(
				IEnvGen.kr(spec.pitch16select, In.kr(pitchSelectBus,1)),
				pitchArray);
			trig = Impulse.ar(pitchSelected / (lenBusVal - zoneRec.dynOverflow));

			if(~showBufferView == 1,{
				trig2 = Impulse.ar(pitchSelected / (lenBusVal*2));
				sign = LFPulse.ar(pitchSelected / (lenBusVal*2), width: 0.5).range(-1,1);

				playHead = ( Phasor.ar(
					trig2,
					pitchSelected * BufRateScale.kr(mainBuf) * sign,
					buffer.dyn2Start,
					buffer.dyn2Start + (lenBusVal*2*sRate),
					buffer.dyn2Start
				) ) % BufFrames.kr(mainBuf);
				SendReply.kr(Impulse.kr(cfg.bufferViewPlayHeadFreq), "/playHead", [playHead/sRate, buffer.dyn2Start/sRate, lenBusVal], 162)
			});

			if(i==0, {
				sig = PlayBufAlt.ar(2, mainBuf, pitchSelected * BufRateScale.kr(mainBuf), trig, buffer.dyn2Start, 1, lag: cfg.playBufLag);
			}, {
				sig = PlayBufCF.ar(2, mainBuf, -1.0 * pitchSelected * BufRateScale.kr(mainBuf), trig, buffer.dyn2Start + (lenBusVal*sRate),
					1, lag: cfg.playBufLag);
			});
			sig = sig * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
			sig = IEnvGen.kr(spec.amp21, In.kr(ampBus,1)) * sig;
			sig = spec.dist21.map(In.kr(distBus,1)) * sig;
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
				IEnvGen.kr(spec.pitch162, LFTri.ar(0.2).range(0,In.kr(pitchRangeBus,1))),
				IEnvGen.kr(spec.pitch162up2, LFSaw.ar(0.4).range(0,In.kr(pitchRangeBus,1))),
				IEnvGen.kr(spec.pitch162down2, LFSaw.ar(0.4).range(1, (1 - In.kr(pitchRangeBus,1)))),
				IEnvGen.kr(spec.pitch162lisa2, LFSaw.ar(0.2).range(0,In.kr(pitchRangeBus,1))),
				IEnvGen.kr(spec.pitch162ran, LFNoise0.ar(100).range(0,In.kr(pitchRangeBus,1)))
			];
			pitchSelected = Select.kr(
				IEnvGen.kr(spec.pitch16select, In.kr(pitchSelectBus,1)),
				pitchArray);
			trig = Impulse.ar(pitchSelected / (lenBusVal - zoneRec.dynOverflow));

			if(~showBufferView == 1,{
				trig2 = Impulse.ar(pitchSelected / (lenBusVal*2));
				sign = LFPulse.ar(pitchSelected / (lenBusVal*2), width: 0.5).range(-1,1);

				playHead = ( Phasor.ar(
					trig2,
					pitchSelected * BufRateScale.kr(mainBuf) * sign,
					buffer.dyn3Start,
					buffer.dyn3Start + (lenBusVal*2*sRate),
					buffer.dyn3Start
				) ) % BufFrames.kr(mainBuf);
				SendReply.kr(Impulse.kr(cfg.bufferViewPlayHeadFreq), "/playHead", [playHead/sRate, buffer.dyn3Start/sRate, lenBusVal], 163)
			});

			if(i==0, {
				sig = PlayBufAlt.ar(2, mainBuf, pitchSelected * BufRateScale.kr(mainBuf), trig, buffer.dyn3Start, 1, lag: cfg.playBufLag);
			}, {
				sig = PlayBufCF.ar(2, mainBuf, -1.0 * pitchSelected * BufRateScale.kr(mainBuf), trig, buffer.dyn3Start + (lenBusVal*sRate), 1, lag: cfg.playBufLag);
			});
			sig = sig * EnvGen.kr(Env.adsr(0.05,0,1,0.05), gate, doneAction: 2);
			sig = IEnvGen.kr(spec.amp21, In.kr(ampBus,1)) * sig;
			sig = spec.dist21.map(In.kr(distBus,1)) * sig;
			sig = Balance2.ar(sig[0], sig[1],0.5);
			Out.ar(~aBus.outA, sig);
		}).send(s);
	};

	SynthDef(\zone16play4, {
		arg gate, ampBus, distBus, resetPosBus, lenBus, panBus, ffBus;
		var sig, resetTrig = 1, resetPosBusVal, lenBusVal, playHead;

		lenBusVal = In.kr(lenBus,1) * sRate;
		resetPosBusVal = In.kr(resetPosBus,1) * lenBusVal;
		resetTrig = HPZ2.kr(In.kr(resetPosBus,1));

		playHead = ( Phasor.ar(
			resetTrig,
			BufRateScale.kr(mainBuf),
			buffer.dyn4Start,
			buffer.dyn4Start + lenBusVal,
			buffer.dyn4Start + resetPosBusVal
		) ) % BufFrames.kr(mainBuf);
		// update bufferView
		if(~showBufferView == 1,
			{SendReply.kr(Impulse.kr(cfg.bufferViewPlayHeadFreq), "/playHead",
				[playHead/sRate, buffer.dyn4Start/sRate, lenBusVal/sRate], 164)});

		sig = BufRd.ar(2, mainBuf, playHead, 1, 4) * EnvGen.kr(Env.adsr(0.1,0,1,0.1), gate, doneAction: 2);
		sig = IEnvGen.kr(spec.amp21, In.kr(ampBus,1)) * sig;
		sig = spec.dist21.map(In.kr(distBus,1)) * sig;
		sig = Balance2.ar(sig[0], sig[1],spec.pan164.map(In.kr(panBus,1)));
		sig = RLPF.ar(sig, spec.ff21.map(In.kr(ffBus,1)), 0.5);
		Out.ar(~aBus.outA, sig);
	}).send(s);

	SynthDef(\diskPlay1, {
		arg buf, gate, att, rel, distBus, volBus, ffBus, rateBus, rateModBus, effectSendBus, lp = 1, lpfOn = 1, rate = 1, gain = 1, out;
		var sig, rateBusVal, rateModBusVal, effectSendVal = 0;

		effectSendVal = In.kr(effectSendBus,1);
		rateModBusVal = IEnvGen.kr(spec.diskPlayRateMod, In.kr(rateModBus,1));
		rateBusVal = IEnvGen.kr(spec.diskPlayRate, In.kr(rateBus,1)) +
		SinOsc.kr(LFNoise1.kr(0.3).range(2,10)).range(rateModBusVal.neg,rateModBusVal);

		sig = VDiskIn.ar(1, buf, rateBusVal*rate,lp) * EnvGen.kr(Env.adsr(att,0,1,rel), gate, doneAction: 2);
		sig = spec.dist21.map(In.kr(distBus,1)) * sig * In.kr(volBus,1);
		sig = ( lpfOn * RLPF.ar(sig, spec.ff21.map(In.kr(ffBus,1)), 0.5) ) + ( (1-lpfOn) * sig );
		sig = sig * gain;
		Out.ar(out, [sig,sig] * (1-effectSendVal));
		Out.ar(~aBus.outA, [sig,sig] * effectSendVal);
	}).send(s);

	SynthDef(\diskPlay2, {
		arg buf, gate, att, rel, distBus, volBus, ffBus, rateBus, rateModBus, effectSendBus, lp = 1, lpfOn = 1, rate = 1, gain = 1, out;
		var sig, rateBusVal, rateModBusVal, effectSendVal = 0;

		effectSendVal = In.kr(effectSendBus,1);
		rateModBusVal = IEnvGen.kr(spec.diskPlayRateMod, In.kr(rateModBus,1));
		rateBusVal = IEnvGen.kr(spec.diskPlayRate, In.kr(rateBus,1)) +
		SinOsc.kr(LFNoise1.kr(0.3).range(2,10)).range(rateModBusVal.neg,rateModBusVal);

		sig = VDiskIn.ar(2, buf, rateBusVal*rate,lp) * EnvGen.kr(Env.adsr(att,0,1,rel), gate, doneAction: 2);
		sig = spec.dist21.map(In.kr(distBus,1)) * sig * In.kr(volBus,1);
		sig = ( lpfOn * RLPF.ar(sig, spec.ff21.map(In.kr(ffBus,1)), 0.5) ) + ( (1-lpfOn) * sig );
		sig = sig * gain;
		Out.ar(out, sig * (1-effectSendVal));
		Out.ar(~aBus.outA, sig * effectSendVal);
	}).send(s);

	SynthDef(\stretchedFragments, {
		arg start, time = 1, stretch = 1, amp = 1, dist = 0, attack = 0.001, release = 0.05, ampSine = 0, ampPluck = 0, freq = 440,
		coef = 0.2, decay = 4;
		var sig, sigKick, sigPluck, kickFreq, kickFreqList;

		sig = PlayBufCF.ar(2, mainBuf, rate: BufRateScale.kr(mainBuf)/stretch, startPos: spec.startPos171.map(start));
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
		sig = (spec.dist171.map(dist) * spec.amp171.map(amp) * sig) + DelayL.ar((ampSine*sigKick) + (ampPluck*sigPluck),0.2,0.1);
		Out.ar(~aBus.outA, sig);
	}).store;

	///////////////////////////////////////////// Synthesis Synths //////////////////////////////////////

	SynthDef(\synth6play6,{
		arg freq1, gate, distBus, cutoffBus, resBus, ampmod, pitchBus; var sig, ampmodVal, cutoffVal, resVal, pitchVal, distVal;

		ampmodVal = IEnvGen.kr(spec.ampMod66, ampmod);
		cutoffVal = IEnvGen.kr(spec.cutoff66, In.kr(cutoffBus,1));
		resVal = IEnvGen.kr(spec.res66, In.kr(resBus,1));
		pitchVal = IEnvGen.kr(spec.pitch66, In.kr(pitchBus,1));
		distVal = IEnvGen.kr(spec.dist66, In.kr(distBus,1));

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

		freqVal = IEnvGen.kr(spec.freq67, In.kr(freqBus,1));
		gravAmpVal = IEnvGen.kr(spec.gravAmp67, In.kr(gravAmpBus,1));
		cutoffVal = IEnvGen.kr(spec.cutoff67, In.kr(cutoffBus,1));
		ringVal = IEnvGen.kr(spec.ring67, In.kr(ringBus,1));
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

		sigDec = ((0.2 * CrossoverDistortion.ar(sigH,amp: 0.1,smooth: 0.5)) + (0.8 * Disintegrator.ar(sigH,probability: 0.9)))
		* EnvGen.ar(envDec,gate, doneAction: 2);

		sig = (
			(sigL * IEnvGen.kr(spec.low65, (1 - In.kr(lowBus,1))))
			+
			(sigH * IEnvGen.kr(spec.high65, (1 - In.kr(highBus,1))))
			+
			(sigDec * IEnvGen.kr(spec.dec65, In.kr(decBus,1)))
		);
		// Out.ar(~aBus.outMain,sig);
		Out.ar(~aBus.outB,sig);
	}).add;

	SynthDef(\fftDrone, {
		arg gate = 1, distBus, pulseBus, cutoffBus;
		var gain = 15, mags, phases, chain, sig, pulseVal = 0.3, env, distVal = 1, cutoffVal = 1000, bufSize = 2048, bins = 150;

		distVal = IEnvGen.kr(spec.distFftDrone, In.kr(distBus,1));
		pulseVal = IEnvGen.kr(spec.pulseFftDrone, In.kr(pulseBus,1));
		cutoffVal = IEnvGen.kr(spec.cutoffFftDrone, In.kr(cutoffBus,1));

		env = EnvGen.kr( Env.asr, gate, doneAction: 2);
		mags = {FSinOsc.kr(ExpRand(0.1, 1)).range(0, 1)}.dup(bins);
		// mags = mags  * ((1, 0.99 .. 0.01).squared);
		// mags = mags * (Array.series(bins, 1, -1/bins).squared);
		// mags = mags.reverse;

		mags = ( pulseVal * mags * {LFPulse.kr(2 ** IRand(-3, 5)).range(0, 1)}.dup(bins) ) + ( (1-pulseVal) * mags );
		phases = 0.dup(100);
		// chain = FFTTrigger(LocalBuf(bufSize), 0.4);
		chain = FFTTrigger(LocalBuf(bufSize), Rand(0.3,0.5));
		chain = PackFFT(chain, bufSize, [mags, phases].flop.flatten, 0, bins-1, 1);
		chain = PV_RectComb(chain, 8, LFNoise1.kr(0.1, 0.4, 0.5).range(0,0.3));
		chain = PV_MagShift(chain, LFNoise1.kr(1).range(0.9,1.1), LFNoise1.kr(1).range(0,0.2));

		sig = IFFT(chain).dup;
		sig = (distVal*sig) + (distVal*3*PitchShift.ar(sig,pitchRatio:0.2));
		// sig = (pulseVal * sig * LFPulse.kr(LFNoise0.kr(2).range(1,4),0, LFNoise1.kr(3).range(0.3,0.7))) + ((1-pulseVal)*sig);
		5.do { sig = AllpassC.ar(sig, 0.2, {Rand(0.01,0.05)}!2,{Rand(1.0,3)}!2) };
		sig = RLPF.ar(sig, {LFNoise1.kr(0.3).range(50,cutoffVal)}!2, 1);

		Out.ar(~aBus.outA, gain * env * sig);
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

		ampVal = IEnvGen.kr(spec.dmAmp, In.kr(paramBus,1));
		probVal = IEnvGen.kr(spec.dmProb, In.kr(paramBus,1));
		mixDecVal = IEnvGen.kr(spec.dmMixDec, In.kr(paramBus,1));
		mixCrossVal = IEnvGen.kr(spec.dmMixCross, In.kr(paramBus,1));
		mixDisVal = IEnvGen.kr(spec.dmMixDis, In.kr(paramBus,1));
		decVal = IEnvGen.kr(spec.dmDec, In.kr(decBus,1));

		// [decVal,mixDecVal,ampVal, mixCrossVal,probVal, mixDisVal, spec.ff21.map(In.kr(ffBus,1))].poll;
		sig = Decimator.ar(sig,rate: decVal, bits: 8);
		sig = (mixDecVal * sig) +
		// adds feedback in silences/range amp 0.1 - 0.01 smooth 0.9 - 0.1
		(mixCrossVal * CrossoverDistortion.ar(sig,amp: ampVal,smooth: 0.5)) +
		(mixDisVal * Disintegrator.ar(sig,probability: probVal));
		//sig = SmoothDecimator.ar(sig,44100/8,smoothing: 0.5);
		//sig = SineShaper.ar(sig,0.05); // not sure what it does, not so interesting
		sig = RLPF.ar(sig, spec.ff21.map(In.kr(ffBus,1)),0.5);

		sig = sig * EnvGen.kr(Env.adsr(0,0,1,0), gate, doneAction: 2);
		Out.ar(~aBus.outMain, In.kr(volBus,1) * sig);
	}).send(s);

	SynthDef(\deLay,  {// efx bank 1 fader 2
		arg gate, volBus, delayTimeBus, inLevelBus, tremSpeedBus, onExternalInput = 0, inChan1 = 0, inChan2 = 1;
		var sig, sigPre, sigOut, mixDelayVal, mixDubVal, inLevelVal;
		var sigDelay, sigDelayL, sigDelayR, delayTimeVal;
		var sigDub, sigDubOut, amp, local, feedVal = 0.5;
		var sigTrem, tremSpeedVal, mixTremVal, tremSpeedVariation0, tremSpeedVariation1, tremSpeedVariation2, tremVar0Mix, tremVar1Mix, tremVar2Mix;
		// var tremSpeedVarOff = 1;

		delayTimeVal = IEnvGen.kr(spec.dlTime, In.kr(delayTimeBus,1));
		mixDelayVal = IEnvGen.kr(spec.dlMixDelay, In.kr(delayTimeBus,1));
		mixDubVal = IEnvGen.kr(spec.dlMixDub, In.kr(delayTimeBus,1));
		mixTremVal = IEnvGen.kr(spec.dlMixTrem, In.kr(delayTimeBus,1));
		feedVal = IEnvGen.kr(spec.dlFeed, In.kr(delayTimeBus,1));
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
		tremVar0Mix = IEnvGen.kr(spec.dlTremVar0Mix, tremSpeedVal);
		tremVar1Mix = IEnvGen.kr(spec.dlTremVar1Mix, tremSpeedVal);
		tremVar2Mix = IEnvGen.kr(spec.dlTremVar2Mix, tremSpeedVal);
		tremSpeedVariation1 = LFNoise1.kr(2).range(0,0.5);
		tremSpeedVariation2 = LFNoise0.kr(10).range(0.2,3);
		tremSpeedVal = (tremVar1Mix * spec.dlTremSpeed.map(tremSpeedVal) * tremSpeedVariation1) +
		(tremVar2Mix * spec.dlTremSpeed.map(tremSpeedVal) * tremSpeedVariation2) +
		(tremVar0Mix * spec.dlTremSpeed.map(tremSpeedVal));
		// tremSpeedVal = ((1-tremSpeedVarOff) * spec.dlTremSpeed.map(tremSpeedVal) * tremSpeedVariation1) +
		// (tremSpeedVarOff * spec.dlTremSpeed.map(tremSpeedVal));
		sigTrem = sigPre * EnvGen.kr(
			Env.new([0,1,1,0,0],[0.05,1,0.05,0.7]*tremSpeedVal,[\sin,\lin,\sin,\lin]).circle
		);
		// sigTrem = (sigPre * tremSpeedVal * SinOsc.ar(1 / spec.dlTremSpeed.map(tremSpeedVal)).range(0,1)) +
		// (sigPre * (1 - tremSpeedVal) * LFPulse.ar(1 / spec.dlTremSpeed.map(tremSpeedVal)));

		// temporary for Spill
		// [decVal,mixDecVal,ampVal, mixCrossVal,probVal, mixDisVal, spec.ff21.map(In.kr(ffBus,1))].poll;
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
		var sigT, decayBusVal, sigTL, sigTR, mixVal = 1, tapVal1, tapVal2, tapVal3, tapVal4; // tap delay
		var in, localL, localR, sigF, sigF1, sigF2, local, envLPF, envLPF2, hold, ffVal; // freeze
		var pulseLen, pulse, pulseTrig, freezeVal;
		var deltimes, sigPlate;
		// var mtfBufL = LocalBuf(~sRate*3,1).clear, mtfBufR = LocalBuf(~sRate*3,1).clear;

		// switch between input channels and sample playback
		in = (onExternalInput * In.ar([inChan1,inChan2])) +
		((1 - onExternalInput) * In.ar(~aBus.outEfxPost,2));  // get the signal post-fade
		mixFreezeVal = IEnvGen.kr(spec.mtfMixFreeze, In.kr(decayBus,1));
		mixTapVal = IEnvGen.kr(spec.mtfMixTap, In.kr(decayBus,1));
		volVal = IEnvGen.kr(spec.mtfVol, In.kr(volBus,1));

		// tap delay --------------------------------
		decayBusVal = IEnvGen.kr(spec.mtfDecay, In.kr(decayBus,1));
		mixVal = IEnvGen.kr(spec.mtfMix, In.kr(decayBus,1));
		tapVal1 = IEnvGen.kr(spec.mtfTap1, In.kr(decayBus,1));
		tapVal2 = IEnvGen.kr(spec.mtfTap2, In.kr(decayBus,1));
		tapVal3 = IEnvGen.kr(spec.mtfTap3, In.kr(decayBus,1));
		tapVal4 = IEnvGen.kr(spec.mtfTap4, In.kr(decayBus,1));
		sigT = in;
		sigTL =
		(tapVal4*MultiTap.ar([0.1, 0.15, 0.7], [1,0.7,0.3], sigT[0], bufnum: mtfBufL)) +
		(tapVal3*MultiTap.ar([0.2, 0.28, 0.6, 1.4], [1,0.8,0.9,0.7], sigT[0], bufnum: mtfBufL)) +
		(tapVal2*MultiTap.ar([0.3, 0.43, 1, 1.9], [1,0.7,0.8, 0.3], sigT[0], bufnum: mtfBufL)) +
		(tapVal1*MultiTap.ar([0.4, 0.7, 0.8, 1, 2], [1,0.7,1, 0.9, 0.6], sigT[0], bufnum: mtfBufL));
		sigTR =
		(tapVal4*MultiTap.ar([0.09, 0.21, 0.8], [0.9,0.8,0.4], sigT[1], bufnum: mtfBufR)) +
		(tapVal3*MultiTap.ar([0.22, 0.4, 0.5, 1], [0.9,0.8,1, 0.4], sigT[1], bufnum: mtfBufR)) +
		(tapVal2*MultiTap.ar([0.29, 0.5, 0.7, 1.3], [0.9,0.8,1, 0.4], sigT[1], bufnum: mtfBufR)) +
		(tapVal1*MultiTap.ar([0.32, 0.65, 0.8, 1.2, 2.1], [0.9,0.8,0.9,1,0.7], sigT[1], bufnum: mtfBufR));
		sigTL = Pan2.ar(sigTL, LFNoise1.ar(2));
		sigTR = Pan2.ar(sigTR, LFNoise1.ar(1.5));

		// Freeverb on MultiTap
		sigT = 0.5 * FreeVerb2.ar(sigTL, sigTR, mixVal, decayBusVal * LFNoise1.kr(0.5).range(0.8,1), 0.5); // mix room damping
		// sigT = GVerb.ar(Mix.ar([sigTL, sigTR]), 10*decayBusVal, 3, 0.5, 1, 15, 0, 3, 2, 300, mul: mixVal);

		// freeze  --------------------------------
		hold = In.kr(volBus,1);
		ffVal = IEnvGen.kr(spec.mtfFF, In.kr(ffBus,1));
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
		sigF = spec.dist21.map(In.kr(distBus,1)) * sigF;

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
		mixValNoise = IEnvGen.kr(spec.apfMixNoise, mixVal);
		mixValPitch = IEnvGen.kr(spec.apfMixPitch, mixVal);
		mixValSchr = IEnvGen.kr(spec.apfMixSchr, mixVal);

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
		sigNoise = RHPF.ar([sigNoiseL, sigNoiseR], IEnvGen.kr(spec.mtfRLPFff, mixVal), 0.5, IEnvGen.kr(spec.mftRLPFmul, mixVal));

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
		// sig = (sigNoise * mixValNoise) + (sigPitch * mixValPitch);
		sig = sig * EnvGen.kr(Env.adsr(0,0,1,0), gate, doneAction: 2);
		Out.ar(~aBus.outMain, volVal * sig);
	}).send(s);

	// sending Pulse to Raphael Vanoli
	// SynthDef(\pulse, {
	// 	arg volBus, speedBus, widthBus, gate = 1;
	// 	var sig, volVal, speedVal, widthVal, widthVal2, env;
	// 	volVal = In.kr(volBus,1);
	// 	speedVal = IEnvGen.kr(Env.new([0.4,5],[1]), In.kr(speedBus,1));
	// 	env = EnvGen.kr(Env.adsr, gate, doneAction:2);
	// 	widthVal = IEnvGen.kr(Env.new([0.1,0.9],[1]), In.kr(widthBus,1));
	// 	widthVal2 = IEnvGen.kr(Env.new([0.9,0.1],[1]), In.kr(widthBus,1));
	//
	// 	// code when 1=no compression 0=max compression
	// 	// sig = LFPulse.ar(speedVal, width: widthVal2).range(1 - volVal, 1);
	// 	// sig = SinOsc.ar(speedVal).range(1 - volVal,1);
	// 	// sig = DC.ar(1) * (1 - (volVal * EnvGen.kr( Env.new([0,1,0,0],[widthVal,widthVal,0.1/widthVal]*(1/speedVal),[\sin,\sin,\lin]).circle )));
	//
	// 	// code when 0=no compression 1=max compression
	// 	sig = LFPulse.ar(speedVal, width: widthVal).range(0,volVal);
	// 	// sig = SinOsc.ar(speedVal).range(0,volVal);
	// 	// sig = DC.ar(1) * volVal * EnvGen.kr( Env.new([0,1,0,0],[widthVal,widthVal,0.1/widthVal]*(1/speedVal),[\sin,\sin,\lin]).circle );
	//
	// 	// sig.round(0.01).poll(10);
	// 	Out.ar(~aBus.outAltChan, sig * env);
	// }).add;

	s.sync;

	///////////////////////////////////////////// HID data acquisition //////////////////////////////////////

	OSCdef(\lisaEx3d, {|msg|
		var cookie = msg[1];
		var val = msg[2];
		if(~oscSrc == "jx", {
			cookie = cookie * 127; 			// back to the MIDI range; this might be f.e. 2 or 2.0001 or 1.9999
			cookie = (cookie + 0.1).floor; 	// make up for rounding errors then make into integer
			// ("Cookie:" + cookie + "Value:" + val).postln;
		});

		// X-axis: control start position, panning, filter freq and restart zones
		if(cookie==16, {
			// junXion repair
			if(~oscSrc == "jx", {val = (1-val) * 1024});
			// update busses
			cBus.ex3dProBusX62.set(spec.pan62.at(val)); // panning
			cBus.ex3dProBusX63.set(spec.pan63.at(val));
			cBus.ex3dProBusX64.set(spec.pan64.at(val));
			cBus.ex3dProBusX65.set(val);
			cBus.ex3dProBusX66.set(val/1024); // filter frequency synth6play6
			cBus.ex3dProBusX67.set(val/1024); // freq TBall synth6play7

			// re-trigger zones
			if((zone6.disableStartPos == 0) && (zone6.disableXhid == 0), {
				// trigger button 1, main action
				if(zone6.play1Act == 1,  {
					// set start position
					zone6.startPos1 = 1 - (val / 1023);
					if(cfg.deBug == 1, { ["61 reg",
						(spec.startPos61.map(zone6.startPos1)/sRate),
						(spec.startPos61Plus1.map(zone6.startPos1 + 0.03)/sRate),
						(spec.startPos61Plus2.map(zone6.startPos1 + 0.03)/sRate),
						(spec.startPos61Plus1.map(zone6.startPos1 + 0.06)/sRate),
						(spec.startPos61Plus2.map(zone6.startPos1 + 0.06)/sRate)
					].postln});

					// update curZoneStart
					if(curZone == "61", {fSetCurZone.value("61", spec.startPos61.map(zone6.startPos1), nil);});

					// release and play
					zone6.play1.size.do({arg i;
						zone6.play1[i].release(cfg.zonePlayRelease);
						if(i == 0, {
							zone6.play1[i] =
							Synth(\zone6play1, [
								\gate, 1,
								\lenBus, cBus.ex3dProR.index,
								\startPosition, zone6.startPos1,
								\distBus, cBus.ex3dProS.index,
								\pitchBus, cBus.ex3dProYpitch.index
							], target: ~aBus.synthGroup);
						},{
							zone6.play1[i] =
							Synth(\zone6play1Plus, [
								\gate, 1,
								\lenBus, cBus.ex3dProR.index,
								\startPosition, zone6.startPos1 + (0.03 * i),
								\distBus, cBus.ex3dProS.index,
								\pitchBus, cBus.ex3dProYpitch.index
							], target: ~aBus.synthGroup);
						});
					});
				});

				// side button 2, HPF
				if(zone6.play2Act == 1, {
					// set start position
					zone6.startPos2 = 1 - (val / 1023);
					if(cfg.deBug == 1, {["62 hpf", (spec.startPos62.map(zone6.startPos2)/sRate)].postln});

					// update curZoneStart
					if(curZone == "62", {fSetCurZone.value("62", spec.startPos62.map(zone6.startPos2), nil)});

					// release and play
					zone6.play2.release(cfg.zonePlayRelease);
					zone6.play2 =
					Synth(\zone6play2, [
						\gate, 1,
						\lenBus, cBus.ex3dProR.index,
						\startPosition, zone6.startPos2,
						\distBus, cBus.ex3dProS.index,
						\ffBus, cBus.ex3dProY.index,
						\panBus, cBus.ex3dProBusX62.index
					], target: ~aBus.synthGroup);
				});

				// top button 5, LPF
				if(zone6.play3Act == 1, {
					// set start position
					zone6.startPos3 = 1 - (val / 1023);
					if(cfg.deBug == 1, {["63 lpf", (spec.startPos63.map(zone6.startPos3)/sRate)].postln});

					// update curZoneStart
					if(curZone == "63", {fSetCurZone.value("63", spec.startPos63.map(zone6.startPos3), nil)});

					// release and play
					zone6.play3.release(cfg.zonePlayRelease);
					zone6.play3 =
					Synth(\zone6play3, [
						\gate, 1,
						\lenBus, cBus.ex3dProR.index,
						\startPosition, zone6.startPos3,
						\distBus, cBus.ex3dProS.index,
						\ffBus, cBus.ex3dProY.index,
						\panBus, cBus.ex3dProBusX63.index
					], target: ~aBus.synthGroup);
				});

				// base button 9 (BB)
				if(zone6.play4Act == 1, {
					// set start position
					zone6.startPos4 = 1 - (val / 1023);
					if(cfg.deBug == 1, {["64 ultrashort", (spec.startPos64.map(zone6.startPos4)/sRate)].postln});

					// update curZoneStart
					if(curZone == "64", {fSetCurZone.value("64", spec.startPos64.map(zone6.startPos4), nil)});

					// release and play
					zone6.play4.release(cfg.zonePlayRelease);
					zone6.play4 =
					Synth(\zone6play4, [
						\gate, 1,
						\lenBus, cBus.ex3dProR.index,
						\startPosition, zone6.startPos4,
						\distBus, cBus.ex3dProS.index,
						\pitchBus, cBus.ex3dProY.index,
						\panBus, cBus.ex3dProBusX64.index
					], target: ~aBus.synthGroup);
				});
			});
		});

		// Y-axis: control pitch, filter freq and gravity for TBall
		if(cookie==17, {
			// junXion repair
			if(~oscSrc == "jx", {val = (1-val) * 1024});

			// Y axis for extreme pitch
			if(((zone6.disablePitch == 0) && (localControl == 1)), { // only if not disabled with joystick button 12 or via remote control
				cBus.ex3dProYpitch.set(spec.pitch61.at(1 - (val/1023)));
			});
			// Y axis for other control
			cBus.ex3dProY.set(1 - (val/1023));
			// set pitch factor for synth6.play6
			zone6.play6Pitch = -5 + ((1 - (val/1023)) * 10);
		});

		// Rotation: control length, filter resonance and freq
		if(cookie==19, {
			// junXion repair
			if(~oscSrc == "jx", {val = (1-val) * 255});

			cBus.ex3dProR.set(val / 255);

			// length for whoosh
			zone6.len5 = spec.len65.at(val / 255);

			// update curZoneLen
			if(curZone == "61", {fSetCurZone.value("61", nil, spec.len61.map(val / 255) * sRate)});
			if(curZone == "62", {fSetCurZone.value("62", nil, spec.len62.map(val / 255) * sRate)});
			if(curZone == "63", {fSetCurZone.value("63", nil, spec.len63.map(val / 255) * sRate)});
			if(curZone == "64", {fSetCurZone.value("64", nil, spec.len64.at(val / 255) * sRate)});
		});

		// Slider: control distortion and TBall ring
		if(cookie==20, {
			// junXion repair
			if(~oscSrc == "jx", {val = (1-val) * 255});

			cBus.ex3dProS.set(val / 255);
			zone6.amp5 = 0.4*(1-(val/255));
		});

		if(~oscSrc == "jx", {val = 1-val}); // junXion repair

		// trigger button 1
		if(cookie==4, {
			if(val==0, {
				if(button1disable == 0, { // only if not disabled by OSC (f.e. when controlling other players' setups)
					// update curZoneStart & curZoneLen
					cBus.ex3dProR.get({arg val;
						fSetCurZone.value(
							"61",								// id current zone
							spec.startPos61.map(zone6.startPos1),	// start current zone
							spec.len61.map(val) * sRate);			// length current zone
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
							\lenBus, cBus.ex3dProR.index,
							\startPosition, zone6.startPos1,
							\distBus, cBus.ex3dProS.index,
							\pitchBus, cBus.ex3dProYpitch.index
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
						\lenBus, cBus.ex3dProR.index,
						\startPosition, zone6.startPos1 + (0.03 * zone6.play1Nbr),
						\distBus, cBus.ex3dProS.index,
						\pitchBus, cBus.ex3dProYpitch.index
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
					cBus.ex3dProR.get({arg val;
						fSetCurZone.value(
							"62",								// id current zone
							spec.startPos62.map(zone6.startPos2),	// start current zone
							spec.len62.map(val) * sRate);			// length current zone
					});
					// start zone
					zone6.play2Act = 1;
					zone6.play2 =
					Synth(\zone6play2, [
						\gate, 1,
						\lenBus, cBus.ex3dProR.index,
						\startPosition, zone6.startPos2,
						\distBus, cBus.ex3dProS.index,
						\ffBus, cBus.ex3dProY.index,
						\panBus, cBus.ex3dProBusX62.index
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
				cBus.ex3dProR.get({arg val;
					fSetCurZone.value(
						"63",								// id current zone
						spec.startPos63.map(zone6.startPos3),	// start current zone
						spec.len63.map(val) * sRate);			// length current zone
				});

				// start zone
				zone6.play3Act = 1;
				zone6.play3 =
				Synth(\zone6play3, [
					\gate, 1,
					\lenBus, cBus.ex3dProR.index,
					\startPosition, zone6.startPos3,
					\distBus, cBus.ex3dProS.index,
					\ffBus, cBus.ex3dProY.index,
					\panBus, cBus.ex3dProBusX63.index
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
				cBus.ex3dProR.get({arg val;
					fSetCurZone.value(
						"64",								// id current zone
						spec.startPos64.map(zone6.startPos4),	// start current zone
						spec.len64.at(val) * sRate);			// length current zone
				});

				if(zone6.play4Act==0, { // start zone
					zone6.play4Act = 1;
					zone6.play4 =
					Synth(\zone6play4, [
						\gate, 1,
						\lenBus, cBus.ex3dProR.index,
						\startPosition, zone6.startPos4,
						\distBus, cBus.ex3dProS.index,
						\pitchBus, cBus.ex3dProY.index,
						\panBus, cBus.ex3dProBusX64.index
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
		// 		// cBus.ex3dProR.get({arg val;
		// 		// 	fSetCurZone.value(
		// 		// 		"65",								// id current zone
		// 		// 		spec.startPos64.map(zone6.startPos5),	// start current zone
		// 		// 	spec.len65.at(val) * sRate);			// length current zone
		// 		// });
		//
		// 		zone6.play5 = Synth(\whoosh, [\ampScale,1,\lenScale,zone6.len5, \lowBus, cBus.ex3dProY.index,
		// 			\highBus, cBus.ex3dProY.index,\decBus, cBus.ex3dProBusX65.index
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
						\distBus, cBus.ex3dProS.index,
						\gate, 1,
						\cutoffBus, cBus.ex3dProBusX67.index,
						\pulseBus, cBus.ex3dProR.index
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
						\distBus, cBus.ex3dProS.index,
						\gate, 1,
						\cutoffBus, cBus.ex3dProBusX66.index,
						\resBus, cBus.ex3dProR.index,
						\pitchBus, cBus.ex3dProY.index,
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
						\freqBus, cBus.ex3dProBusX67.index,
						\gravAmpBus, cBus.ex3dProY.index,
						\cutoffBus, cBus.ex3dProR.index,
						\ringBus, cBus.ex3dProS.index
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
				fAmpCurZone.value(mainBuf, curZoneStart, curZoneLen, cfg.ampCurZoneFactor);
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
							\start, buffer.aStart, \len, buffer.aLen / sRate, \recZone, 1], target: ~aBus.synthGroup);
					fSetCurZone.value("1", mode: "REC");
					fCountZones.value("R+");
					"LiveSampler: Record from inChan1 in A".postln;
				}
				{note == 7}  // record from inChan1 in B
				{
					zoneRec.ch1B = Synth(\zoneRec,
						[\gate, 1, \chan1, fGetInChanSampling.value(~aBus.inChan1)[0], \chan2, fGetInChanSampling.value(~aBus.inChan1)[1],
							\start, buffer.bStart, \len, buffer.bLen / sRate, \recZone, 2], target: ~aBus.synthGroup);
					fSetCurZone.value("2", mode: "REC");
					fCountZones.value("R+");
					"LiveSampler: Record from inChan1 in B".postln;
				}
				{note == 8}  // record from inChan2 in A
				{
					zoneRec.ch2A = Synth(\zoneRec,
						[\gate, 1, \chan1, fGetInChanSampling.value(~aBus.inChan2)[0], \chan2, fGetInChanSampling.value(~aBus.inChan2)[1],
							\start, buffer.aStart, \len, buffer.aLen / sRate, \recZone, 3], target: ~aBus.synthGroup);
					fSetCurZone.value("3", mode: "REC");
					fCountZones.value("R+");
					"LiveSampler: Record from inChan2 in A".postln;
				}
				{note == 9}  // record from inChan2 in B
				{
					zoneRec.ch2B = Synth(\zoneRec,
						[\gate, 1,  \chan1, fGetInChanSampling.value(~aBus.inChan2)[0], \chan2, fGetInChanSampling.value(~aBus.inChan2)[1],
							\start, buffer.bStart, \len, buffer.bLen / sRate, \recZone, 4], target: ~aBus.synthGroup);
					fSetCurZone.value("4", mode: "REC");
					fCountZones.value("R+");
					"LiveSampler: Record from inChan2 in B".postln;
				}
				{note == 4} // dynamic length recording from inChan1
				{
					zoneRec.dyn1 = Synth(\zoneRecDyn,
						[\gate, 1, \chan1, fGetInChanSampling.value(~aBus.inChan1)[0], \chan2, fGetInChanSampling.value(~aBus.inChan1)[1],
							\start, buffer.dyn1Start, \len, zoneRec.dynLenMax, \recZone, 5],
						target: ~aBus.synthGroup);
					fSetCurZone.value("5", mode: "REC");
					fCountZones.value("R+");
					zoneRec.dyn1St = SystemClock.seconds; // save start time to on NOF lenght can be determined
					"LiveSampler: DynRec from inChan1".postln;
				}
				{note == 5} // dynamic length recording from inChan2
				{
					zoneRec.dyn2 = Synth(\zoneRecDyn,
						[\gate, 1, \chan1, fGetInChanSampling.value(~aBus.inChan2)[0], \chan2, fGetInChanSampling.value(~aBus.inChan2)[1],
							\start, buffer.dyn2Start, \len, zoneRec.dynLenMax, \recZone, 6],
						target: ~aBus.synthGroup);
					fSetCurZone.value("6", mode: "REC");
					fCountZones.value("R+");
					zoneRec.dyn2St = SystemClock.seconds; // save start time to on NOF lenght can be determined
					"LiveSampler: DynRec from inChan2".postln;
				}
				{note == 10} // dynamic length recording from inChan1
				{
					zoneRec.dyn3 = Synth(\zoneRecDyn,
						[\gate, 1, \chan1, fGetInChanSampling.value(~aBus.inChan1)[0], \chan2, fGetInChanSampling.value(~aBus.inChan1)[1],
							\start, buffer.dyn3Start, \len, zoneRec.dynLenMax, \recZone, 7],
						target: ~aBus.synthGroup);
					fSetCurZone.value("7", mode: "REC");
					fCountZones.value("R+");
					zoneRec.dyn3St = SystemClock.seconds; // save start time to on NOF lenght can be determined
					"LiveSampler: DynRec from inChan1".postln;
				}
				{note == 11} // dynamic length recording from inChan2
				{
					zoneRec.dyn4 = Synth(\zoneRecDyn,
						[\gate, 1, \chan1, fGetInChanSampling.value(~aBus.inChan2)[0], \chan2, fGetInChanSampling.value(~aBus.inChan2)[1],
							\start, buffer.dyn4Start, \len, zoneRec.dynLenMax, \recZone, 8],
						target: ~aBus.synthGroup);
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
				; // case
			});

			// MIDI Channel 1: LX blue buttons Load
			if((chan==0 && (note >= 24) && (note <= 59) && sampleListLX.at(note).notNil), {
				if(sampleListLX.at((note.asString++'out').asSymbol).notNil, {
					if(sampleListLX.at((note.asString++'out').asSymbol) == "A", {
						fBufferRead.value(sampleListLX.at(note), buffer.aLen, buffer.aStart)
					}, {
						fBufferRead.value(sampleListLX.at(note), buffer.bLen, buffer.bStart)
					});
				}, {
					fBufferRead.value(sampleListLX.at(note), buffer.aLen, buffer.aStart);
				});
			});

			// MIDI Channel 1: LX green buttons Load
			if((chan==0 && (note >= 60) && (note <= 71) && sampleListLX.at(note).notNil), {
				fBufferRead.value(sampleListLX.at(note), buffer.bLen, buffer.bStart);
			});

			// MIDI Channel 1: LX green keyset 2 & 3 diskPlay synth to play sample loops
			if((chan==0 && (note >= 72) && (note <= 95)), {
				dpIndex = note - 72; // diskPlay array index
				if(diskPlay.buf[dpIndex].notNil, { // a sample is defined for this index and file is found
					if(diskPlay.playing[dpIndex] == 0, { // if not playing, start the synth
						("diskPlay"++diskPlay.numChan[dpIndex]++":" + diskPlay.sampleList[dpIndex] + "from" + diskPlay.start[dpIndex] + "to" + diskPlay.len[dpIndex] + "secs" ).postln;

						// cue soundfile into a buffer
						diskPlay.buf[dpIndex].close;
						diskPlay.buf[dpIndex].cueSoundFile(cfg.sampleDir++diskPlay.sampleList[dpIndex], diskPlay.start[dpIndex] * sRate);

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
							\distBus, cBus.midiLV2Fader12.index, \volBus, cBus.midiLV2Fader16.index,
							\ffBus, cBus.midiLV2Fader15.index, \rateBus, cBus.midiLV2Fader14.index,
							\rateModBus, cBus.midiLV2Fader13.index, \lpfOn, diskPlay.lpfOn[dpIndex], \rate, diskPlay.rate[dpIndex],
							\effectSendBus, cBus.midiLV2Fader11.index, \gain, diskPlay.gain[dpIndex], \out, diskPlay.out[dpIndex]
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
						++(buffer.aStart/sRate)++"-"++((buffer.aStart + buffer.processLen)/sRate)++"s").postln;
					~processBuf.copyData(mainBuf, buffer.aStart);
					if(~showBufferView == 1, {fDisplayBufferView.value("A")});
				}
				{note==14}
				{
					("LiveSampler: Copy processbuffer into samplebuffer: "++((buffer.aStart + buffer.processLen)/sRate)++"-"
						++((buffer.aStart + (2*buffer.processLen))/sRate)++"s").postln;
					~processBuf.copyData(mainBuf, buffer.aStart + buffer.processLen);
					if(~showBufferView == 1, {fDisplayBufferView.value("A")});
				}
				{note==16}
				{
					("LiveSampler: Copy processbuffer into samplebuffer: "
						++(buffer.bStart/sRate)++"-"++((buffer.bStart + buffer.processLen)/sRate)++"s").postln;
					~processBuf.copyData(mainBuf, buffer.bStart);
					if(~showBufferView == 1, {fDisplayBufferView.value("B")});
				}
				{note==17}
				{
					("LiveSampler: Copy processbuffer into samplebuffer: "++((buffer.bStart + buffer.processLen)/sRate)++"-"
						++((buffer.bStart + (2*buffer.processLen))/sRate)++"s").postln;
					~processBuf.copyData(mainBuf, buffer.bStart + buffer.processLen);
					if(~showBufferView == 1, {fDisplayBufferView.value("B")});
				}
				{note==19} // save dynrec1&3 buffer
				{
					"LiveSampler: Save dynrec1&3 buffer".postln;
					mainBuf.write(thisProcess.platform.recordingsDir++"/LiveSamplerDynRec1.aif",
						startFrame: sRate*150, numFrames: sRate*30);
					cBus.lenBus161.get({arg val; zoneRec.dyn1SavedLen = val});
					mainBuf.write(thisProcess.platform.recordingsDir++"/LiveSamplerDynRec3.aif",
						startFrame: sRate*210, numFrames: sRate*30);
					cBus.lenBus163.get({arg val; zoneRec.dyn3SavedLen = val});
				}
				{note==21} // save dynrec2&4 buffer
				{
					"LiveSampler: Save dynrec2&4 buffer".postln;
					mainBuf.write(thisProcess.platform.recordingsDir++"/LiveSamplerDynRec2.aif",
						startFrame: sRate*180, numFrames: sRate*30);
					cBus.lenBus162.get({arg val; zoneRec.dyn2SavedLen = val});
					mainBuf.write(thisProcess.platform.recordingsDir++"/LiveSamplerDynRec4.aif",
						startFrame: sRate*240, numFrames: sRate*30);
					cBus.lenBus164.get({arg val; zoneRec.dyn4SavedLen = val});
				}
				{note==23} // recall dynrec1&3 buffer
				{
					// arg sampleList, bufferLen, bufferStart, relativePath = 1, tempFile;
					"LiveSampler: Recall dynrec1&3 buffer".postln;
					fBufferRead.value([thisProcess.platform.recordingsDir++"/LiveSamplerDynRec1.aif"], sRate*30, sRate*150, 0);
					cBus.lenBus161.set(zoneRec.dyn1SavedLen);
					fBufferRead.value([thisProcess.platform.recordingsDir++"/LiveSamplerDynRec3.aif"], sRate*30, sRate*210, 0);
					cBus.lenBus163.set(zoneRec.dyn3SavedLen);
				}
				{note==24} // recall dynrec2&4 buffer
				{
					"LiveSampler: Recall dynrec2&4 buffer".postln;
					fBufferRead.value([thisProcess.platform.recordingsDir++"/LiveSamplerDynRec2.aif"], sRate*30, sRate*180, 0);
					cBus.lenBus162.set(zoneRec.dyn2SavedLen);
					fBufferRead.value([thisProcess.platform.recordingsDir++"/LiveSamplerDynRec4.aif"], sRate*30, sRate*240, 0);
					cBus.lenBus164.set(zoneRec.dyn4SavedLen);
				}
				; // case
			});

			// MIDI Channel 10: LV2 Load
			if((chan==9 && sampleListLV2.at(note).notNil), {
				fBufferRead.value(sampleListLV2.at(note), buffer.bLen, buffer.bStart);
			});

			// MIDI Channel 13: LV1 Load
			if((chan==12 && sampleListLV1.at(note).notNil), {
				fBufferRead.value(sampleListLV1.at(note), buffer.aLen, buffer.aStart);
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
					cBus.lenBus161.set(SystemClock.seconds - zoneRec.dyn1St);
					["Lenght DynRec1",(SystemClock.seconds - zoneRec.dyn1St)].postln;

					zoneRec.len1 = (SystemClock.seconds - zoneRec.dyn1St) * sRate;
					case
					{ zoneRec.len1 < ( (buffer.dyn2Start - buffer.dyn1Start) / 4 ) }
					{
						mainBuf.copyData(mainBuf, buffer.dyn1Start + zoneRec.len1, buffer.dyn1Start, zoneRec.len1);
						mainBuf.copyData(mainBuf, buffer.dyn1Start + (2*zoneRec.len1), buffer.dyn1Start, zoneRec.len1);
						mainBuf.copyData(mainBuf, buffer.dyn1Start + (3*zoneRec.len1), buffer.dyn1Start, zoneRec.len1);
					}
					{ zoneRec.len1 < ( (buffer.dyn2Start - buffer.dyn1Start) / 2 ) }
					{ mainBuf.copyData(mainBuf, buffer.dyn1Start + zoneRec.len1 - 5, buffer.dyn1Start, zoneRec.len1) }
					;

					zoneRec.dyn1.free;
					if(~showBufferView == 1, {fDisplayBufferView.value("C1")});
					fCountZones.value("R-");

					// update  curZoneLen
					if(curZone == "161", {cBus.lenBus161.get({arg val; curZoneLen = val * sRate})});
				}
				{(note == 5)}
				{
					cBus.lenBus162.set(SystemClock.seconds - zoneRec.dyn2St);
					["Lenght DynRec2",(SystemClock.seconds - zoneRec.dyn2St)].postln;
					zoneRec.dyn2.free;
					if(~showBufferView == 1, {fDisplayBufferView.value("C2")});
					fCountZones.value("R-");

					// update curZoneLen
					if(curZone == "162", {cBus.lenBus162.get({arg val; curZoneLen = val * sRate})});

					if(zone16.play2Act == 1, {
						zone16.play2.release;
						zone16.play2 =
						Synth("zone16play2"++zone16.mode2, [
							\gate, 1,
							\ampBus, cBus.midiLV2Fader6.index,
							\distBus, cBus.midiLV1CrossFader.index,
							\lenBus, cBus.lenBus162.index,
							\pitchRangeBus, cBus.midiLV2KnobD1.index,
							\pitchSelectBus, cBus.midiLV2KnobD2.index
						], target: ~aBus.synthGroup);
					});
				}
				{(note == 10)}
				{
					cBus.lenBus163.set(SystemClock.seconds - zoneRec.dyn3St);
					["Lenght DynRec3",(SystemClock.seconds - zoneRec.dyn3St)].postln;
					zoneRec.dyn3.free;
					if(~showBufferView == 1, {fDisplayBufferView.value("C3")});
					fCountZones.value("R-");

					// update curZoneLen
					if(curZone == "163", {cBus.lenBus163.get({arg val; curZoneLen = val * sRate})});

					if(zone16.play3Act == 1, {
						zone16.play3.release;
						zone16.play3 =
						Synth("zone16play3"++zone16.mode3, [
							\gate, 1,
							\ampBus, cBus.midiLV2Fader7.index,
							\distBus, cBus.midiLV1CrossFader.index,
							\lenBus, cBus.lenBus163.index,
							\pitchRangeBus, cBus.midiLV2KnobD1.index,
							\pitchSelectBus, cBus.midiLV2KnobD2.index
						], target: ~aBus.synthGroup);
					});
				}
				{(note == 11)}
				{
					cBus.lenBus164.set(SystemClock.seconds - zoneRec.dyn4St);
					["Lenght DynRec4",(SystemClock.seconds - zoneRec.dyn4St)].postln;
					zoneRec.dyn4.free;
					if(~showBufferView == 1, {fDisplayBufferView.value("C4")});
					fCountZones.value("R-");

					// update curZoneLen
					if(curZone == "164", {cBus.lenBus164.get({arg val; curZoneLen = val * sRate})});
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
				cBus.midiLV2Fader16.set(value);
			});
			// filter frequency
			if((chan==0 && num==2), {
				cBus.midiLV2Fader15.set(value);
			});
			// rate
			if((chan==0 && num==1), {
				cBus.midiLV2Fader14.set(value);
			});
			// rate modulation depth
			if((chan==0 && num==0), {
				cBus.midiLV2Fader13.set(value);
			});
			// distortion
			if((chan==0 && num==7), {
				cBus.midiLV2Fader12.set(value);
			});
			// effect level
			if((chan==0 && num==6), {
				cBus.midiLV2Fader11.set(value);
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
				cBus.midiLV2KnobMasterVol.set(value);
			});
			// diskPlay controls //////////////////////////////////////////////////////////////////////////
			// volume
			if((chan==11 && num==15), {
				cBus.midiLV2Fader16.set(value);
			});
			// filter frequency
			if((chan==11 && num==14), {
				cBus.midiLV2Fader15.set(value);
			});
			// rate
			if((chan==11 && num==13), {
				cBus.midiLV2Fader14.set(value);
			});
			// rate modulation depth
			if((chan==11 && num==12), {
				cBus.midiLV2Fader13.set(value);
			});
			// distortion
			if((chan==11 && num==11), {
				cBus.midiLV2Fader12.set(value);
			});
			// effect level
			if((chan==11 && num==10), {
				cBus.midiLV2Fader11.set(value);
			});

			// efx volume control //////////////////////////////////////////////////////////////////////////
			// volume and trigger efx1: deciMate or multiTapFreeze
			if((chan==14 && num==2), {
				// set volume bus
				cBus.midiLV1Fader3.set(spec.efxVol.at(value));

				if(value >= 0.01, { // activate efx1
					if(efx1Act == 0, {
						if(efxBank == 1,
							{~aBus.efx1Synth = Synth(\deciMate, [\gate,1,
								\paramBus, cBus.midiLV1KnobB1.index,
								\decBus, cBus.midiLV1KnobB2.index,
								\ffBus, cBus.midiLV1KnobB3.index,
								\volBus, cBus.midiLV1Fader3.index,
								\onExternalInput, onExternalInput,
								\inChan1, fGetInChanEfx.value()[0],
								\inChan2, fGetInChanEfx.value()[1]
							], target: ~aBus.efxGroup);},
							{~aBus.efx1Synth = Synth(\multiTapFreeze, [\gate,1,
								\decayBus, cBus.midiLV1KnobB1.index,
								\volBus, cBus.midiLV1Fader3.index,
								\ffBus, cBus.midiLV1KnobB2.index,
								\freezeBus, cBus.midiLV1KnobB3.index,
								\distBus, cBus.midiLV1CrossFader.index,
								\onExternalInput, onExternalInput,
								\inChan1, fGetInChanEfx.value()[0],
								\inChan2, fGetInChanEfx.value()[1]
						], target: ~aBus.efxGroup);});
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
				cBus.midiLV1Fader4.set(spec.efxVol.at(value));

				if(value >= 0.01, { // activate efx2
					if(efx2Act == 0, {
						if(efxBank == 1,
							{~aBus.efx2Synth = Synth(\deLay, [\gate, 1,
								\volBus, cBus.midiLV1Fader4.index,
								\delayTimeBus, cBus.midiLV1KnobB1.index,
								\inLevelBus, cBus.midiLV1KnobB3.index,
								\tremSpeedBus, cBus.midiLV1KnobB2.index,
								\onExternalInput, onExternalInput,
								\inChan1, fGetInChanEfx.value()[0],
								\inChan2, fGetInChanEfx.value()[1]
							],
							target: ~aBus.efxGroup);},
							{~aBus.efx2Synth = Synth(\ampPitchFollow, [\gate, 1,
								\volBus, cBus.midiLV1Fader4.index,
								\onExternalInput, onExternalInput,
								\mixBus, cBus.midiLV1KnobB1.index,
								\inChan1, fGetInChanEfx.value()[0],
								\inChan2, fGetInChanEfx.value()[1]
							],
							target: ~aBus.efxGroup);});
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
				cBus.midiLV1KnobB1.set(value);
				zone17.tempoClock1.tempo = spec.tempo171.map(value);
			});
			if((chan==12 && num==77), {
				cBus.midiLV1KnobB2.set(value);
			});
			if((chan==12 && num==78), {
				cBus.midiLV1KnobB3.set(value);
			});

			// Zone 2 controls //////////////////////////////////////////////////////////////////////////
			// volume and trigger
			if((chan==14 && num==0), {
				// set volume bus
				cBus.midiLV1Fader1.set(value);

				// trigger zone
				if(value >= 0.01,{ // start zone
					if(zone2.play1Act == 0, {
						zone2.play1Act = 1;
						zone2.play1L =
						Synth(\zone2play1L, [
							\gate, 1,
							\lenBus, cBus.midiLV1KnobA1.index,
							\startPosition, zone2.startPos1,
							\ampBus, cBus.midiLV1Fader1.index,
							\distBus, cBus.midiLV1CrossFader.index,
							\ffBus, cBus.midiLV1KnobMasterVol.index,
							\resetPosBus, cBus.midiLV1JoyX.index,
							\mixBus, cBus.midiLV1KnobA2.index
						], target: ~aBus.synthGroup);
						zone2.play1R =
						Synth(\zone2play1R, [
							\gate, 1,
							\lenBus, cBus.midiLV1KnobA1.index,
							\startPosition, zone2.startPos1,
							\ampBus, cBus.midiLV1Fader1.index,
							\distBus, cBus.midiLV1CrossFader.index,
							\pitchBus, cBus.midiLV1JoyY.index,
							\ffBus, cBus.midiLV1KnobMasterVol.index,
							\resetPosBus, cBus.midiLV1JoyX.index,
							\mixBus, cBus.midiLV1KnobA2.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+", 2);

						// update curZoneStart & curZoneLen
						cBus.midiLV1KnobA1.get({arg val;
							fSetCurZone.value(
								"21",								// id current zone
								spec.startPos21L.map(zone2.startPos1),	// start current zone
								spec.len21L.at(val));					// length current zone
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
							\lenBus, cBus.midiLV1KnobA1.index,
							\startPosition, zone2.startPos1,
							\distBus, cBus.midiLV1CrossFader.index,
							\resetPosBus, cBus.midiLV1JoyX.index,
							\mixBus, cBus.midiLV1KnobA2.index
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
							\lenBus, cBus.midiLV1KnobA1.index,
							\startPosition, zone2.startPos1,
							\distBus, cBus.midiLV1CrossFader.index,
							\resetPosBus, cBus.midiLV1JoyX.index,
							\mixBus, cBus.midiLV1KnobA2.index
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
				cBus.midiLV1KnobA1.set(value);
				zone17.len1 = value;

				// update curZoneLen
				if(curZone == "21", {fSetCurZone.value("21", nil, spec.len21L.at(value))});
			});
			// mix
			if((chan==12 && num==57), {
				cBus.midiLV1KnobA2.set(value);
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
						\lenBus, cBus.midiLV1KnobA1.index,
						\startPosition, zone2.startPos1,
						\ampBus, cBus.midiLV1Fader1.index,
						\distBus, cBus.midiLV1CrossFader.index,
						\ffBus, cBus.midiLV1KnobMasterVol.index,
						\resetPosBus, cBus.midiLV1JoyX.index,
						\mixBus, cBus.midiLV1KnobA2.index
					], target: ~aBus.synthGroup);
					zone2.play1R =
					Synth(\zone2play1R, [
						\gate, 1,
						\lenBus, cBus.midiLV1KnobA1.index,
						\startPosition, zone2.startPos1,
						\ampBus, cBus.midiLV1Fader1.index,
						\distBus, cBus.midiLV1CrossFader.index,
						\pitchBus, cBus.midiLV1JoyY.index,
						\ffBus, cBus.midiLV1KnobMasterVol.index,
						\resetPosBus, cBus.midiLV1JoyX.index,
						\mixBus, cBus.midiLV1KnobA2.index
					], target: ~aBus.synthGroup);

					// update curZoneStart
					if(curZone == "21", {fSetCurZone.value("21", spec.startPos21L.map(zone2.startPos1), nil)});
				});
				if(zone2.play1hfAct == 1, { // re-trigger zone
					zone2.play1hf.release(cfg.zonePlayRelease);
					zone2.play1hf =
					Synth(\zone2play1hf, [
						\gate, 1,
						\lenBus, cBus.midiLV1KnobA1.index,
						\startPosition, zone2.startPos1,
						\distBus, cBus.midiLV1CrossFader.index,
						\resetPosBus, cBus.midiLV1JoyX.index,
						\mixBus, cBus.midiLV1KnobA2.index
					], target: ~aBus.synthGroup);
				});
				if(zone2.play1lfAct == 1, { // re-trigger zone
					zone2.play1Lf.release(cfg.zonePlayRelease);
					zone2.play1Lf =
					Synth(\zone2play1lf, [
						\gate, 1,
						\lenBus, cBus.midiLV1KnobA1.index,
						\startPosition, zone2.startPos1,
						\distBus, cBus.midiLV1CrossFader.index,
						\resetPosBus, cBus.midiLV1JoyX.index,
						\mixBus, cBus.midiLV1KnobA2.index
					], target: ~aBus.synthGroup);
				});
			});
			// distortion
			if((chan==14 && num==19), {
				cBus.midiLV1CrossFader.set(value);
				zone17.dist1 = value;
			});
			// pitch
			if((chan==12 && num==0), {
				cBus.midiLV1JoyY.set(value);
			});
			// SP offset
			if((chan==12 && num==20), {
				cBus.midiLV1JoyX.set(value);
			});
			// filterfreq
			if((chan==14 && num==17), {
				cBus.midiLV1KnobMasterVol.set(value);
			});

			// Zone 3 controls //////////////////////////////////////////////////////////////////////////
			// volume and trigger
			if((chan==14 && num==4), {
				// set volume bus
				cBus.midiLV1Fader5.set(value);
				// trigger zone
				if(value >= 0.01, { // start zone
					if(zone3.play1Act == 0, {
						zone3.play1Act = 1;
						zone3.play1 =
						Synth(\zone3play1, [
							\gate, 1,
							\lenBus, cBus.midiLV1KnobC1.index,
							\startPosition, zone3.startPos1,
							\ampBus, cBus.midiLV1Fader5.index,
							\distBus, cBus.midiLV1CrossFader.index,
							\pitchBus, cBus.midiLV1KnobD1.index,
							\panSpdBus, cBus.midiLV1KnobD2.index,
							\resetPosBus, cBus.spModBus31.index,
							\ffBus, cBus.midiLV1KnobC2.index,
							\ampModSpdBus, cBus.midiLV1Fader8.index,
							\ampModOnBus, cBus.ampModOnBus31.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+");

						// start sample pointer modulation
						zone3.tModSP1 = Task(fModSP31).play;

						// update curZoneStart & curZoneLen
						cBus.midiLV1KnobC1.get({arg val;
							fSetCurZone.value(
								"31",								// id current zone
								spec.startPos21L.map(zone3.startPos1),	// start current zone
								spec.len31.at(val));					// length current zone
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
						\lenBus, cBus.midiLV1KnobC1.index,
						\startPosition, zone3.startPos1,
						\ampBus, cBus.midiLV1Fader5.index,
						\distBus, cBus.midiLV1CrossFader.index,
						\pitchBus, cBus.midiLV1KnobD1.index,
						\panSpdBus, cBus.midiLV1KnobD2.index,
						\resetPosBus, cBus.spModBus31.index,
						\ffBus, cBus.midiLV1KnobC2.index,
						\ampModSpdBus, cBus.midiLV1Fader8.index,
						\ampModOnBus, cBus.ampModOnBus31.index
					], target: ~aBus.synthGroup);
					// update curZoneStart
					if(curZone == "31", {fSetCurZone.value("31", spec.startPos21L.map(zone3.startPos1), nil)});
				});
			});
			// length
			if((chan==12 && num==80), {
				cBus.midiLV1KnobC1.set(value);
				// update curZoneLen
				if(curZone == "31", {
					fSetCurZone.value("31", nil, spec.len31.at(value))
				});
			});
			// speed SP offset modulation
			if((chan==14 && num==6), {
				zone3.spModSpd1 = 127 - (value*127);
				if(cfg.deBug == 1, {
					("zone3play wait in sec:"+spec.spModSpd31.at(zone3.spModSpd1)).postln;
					("zone3play BPM:"+ (60 / spec.spModSpd31.at(zone3.spModSpd1))).postln;
				});
				// restart zone3 sample pointer modulation task
				if(zone3.play1Act == 1, {zone3.tModSP1.stop; zone3.tModSP1 = Task(fModSP31).play;});
			});
			// speed pan
			if((chan==12 && num==117), {
				cBus.midiLV1KnobD2.set(value);
			});
			// filter freq
			if((chan==12 && num==97), {
				cBus.midiLV1KnobC2.set(value);
			});
			// pitch
			if((chan==12 && num==100), {
				cBus.midiLV1KnobD1.set(value);
			});
			// speed amp mod
			if((chan==14 && num==7), {
				if(value < 0.95,
					{cBus.ampModOnBus31.set(1); cBus.midiLV1Fader8.set(value);}, // switch on amp modulation and send value
					{cBus.ampModOnBus31.set(0);}); // switch off amp modulation
			});

			// Zone 4 controls //////////////////////////////////////////////////////////////////////////
			// volume and trigger
			if((chan==11 && num==0), {
				// set volume bus
				cBus.midiLV2Fader1.set(value);
				// trigger zone
				if(value >= 0.01, { // start zone
					if(zone4.play1Act == 0, {
						zone4.play1Act = 1;
						zone4.play1 =
						Synth(\zone4play1, [
							\gate, 1,
							\lenBus, cBus.midiLV2KnobA1.index,
							\startPosition, zone4.startPos1,
							\ampBus, cBus.midiLV2Fader1.index,
							\distBus, cBus.midiLV2CrossFader.index,
							\pitchBus, cBus.midiLV2JoyY.index,
							\pitch2Bus, cBus.midiLV2JoyY2.index,
							\ffBus, cBus.midiLV2JoyX.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+", 1);
						// update curZoneStart & curZoneLen
						cBus.midiLV2KnobA1.get({arg val;
							fSetCurZone.value(
								"41",								// id current zone
								spec.startPos21L.map(zone4.startPos1),	// start current zone
								val * sRate);						// length current zone
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
							\lenBus, cBus.midiLV2KnobA1.index,
							\startPosition, zone4.startPos1,
							\distBus, cBus.midiLV2CrossFader.index,
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
							\lenBus, cBus.midiLV2KnobA1.index,
							\startPosition, zone4.startPos1,
							\distBus, cBus.midiLV2CrossFader.index,
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
				cBus.midiLV2KnobA1.set(spec.len41.at(value*127));
				// zone17.len1 = value;

				if(cfg.deBug == 1, {("zone4 speed" + ((spec.len41.at(value*127) / 60) * cfg.bpm)).postln;});
				if(zone4.play1Act == 1, { // re-trigger zone
					zone4.play1.release(cfg.zonePlayRelease);
					zone4.play1 =
					Synth(\zone4play1, [
						\gate, 1,
						\lenBus, cBus.midiLV2KnobA1.index,
						\startPosition, zone4.startPos1,
						\ampBus, cBus.midiLV2Fader1.index,
						\distBus, cBus.midiLV2CrossFader.index,
						\pitchBus, cBus.midiLV2JoyY.index,
						\pitch2Bus, cBus.midiLV2JoyY2.index,
						\ffBus, cBus.midiLV2JoyX.index
					], target: ~aBus.synthGroup);
					// update curZoneLen
					if(curZone == "41", {fSetCurZone.value("41", nil, spec.len41.at(value*127) * sRate)});
				});
				if(zone4.play1hfAct == 1, { // re-trigger zone
					zone4.play1hf.release(cfg.zonePlayRelease);
					zone4.play1hf =
					Synth(\zone4play1hf, [
						\gate, 1,
						\lenBus, cBus.midiLV2KnobA1.index,
						\startPosition, zone4.startPos1,
						\distBus, cBus.midiLV2CrossFader.index,
					], target: ~aBus.synthGroup);
				});
				if(zone4.play1lfAct == 1, { // re-trigger zone
					zone4.play1lf.release(cfg.zonePlayRelease);
					zone4.play1lf =
					Synth(\zone4play1lf, [
						\gate, 1,
						\lenBus, cBus.midiLV2KnobA1.index,
						\startPosition, zone4.startPos1,
						\distBus, cBus.midiLV2CrossFader.index,
					], target: ~aBus.synthGroup);
				});
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
						\lenBus, cBus.midiLV2KnobA1.index,
						\startPosition, zone4.startPos1,
						\ampBus, cBus.midiLV2Fader1.index,
						\distBus, cBus.midiLV2CrossFader.index,
						\pitchBus, cBus.midiLV2JoyY.index,
						\pitch2Bus, cBus.midiLV2JoyY2.index,
						\ffBus, cBus.midiLV2JoyX.index
					], target: ~aBus.synthGroup);
					// update curZoneStart
					if(curZone == "41", {
						fSetCurZone.value("41", spec.startPos21L.map(zone4.startPos1), nil);
					});
				});
				if(zone4.play1hfAct == 1, { // re-trigger zone
					zone4.play1hf.release(cfg.zonePlayRelease);
					zone4.play1hf =
					Synth(\zone4play1hf, [
						\gate, 1,
						\lenBus, cBus.midiLV2KnobA1.index,
						\startPosition, zone4.startPos1,
						\distBus, cBus.midiLV2CrossFader.index,
					], target: ~aBus.synthGroup);
				});
				if(zone4.play1lfAct == 1, { // re-trigger zone
					zone4.play1lf.release(cfg.zonePlayRelease);
					zone4.play1lf =
					Synth(\zone4play1lf, [
						\gate, 1,
						\lenBus, cBus.midiLV2KnobA1.index,
						\startPosition, zone4.startPos1,
						\distBus, cBus.midiLV2CrossFader.index,
					], target: ~aBus.synthGroup);
				});
			});
			// distortion
			if((chan==11 && num==19), {
				cBus.midiLV2CrossFader.set(value);
				// zone17.dist1 = value;
			});
			// pitch
			if((chan==9 && num==0), {
				cBus.midiLV2JoyY.set(value);
			});
			if((chan==9 && num==17), {
				cBus.midiLV2JoyY2.set(value);
			});
			// filter freq
			if((chan==9 && num==20), {
				cBus.midiLV2JoyX.set(value);
			});
			if((chan==9 && num==37), {
				cBus.midiLV2JoyX.set(value);
			});

			// Zone 8 controls //////////////////////////////////////////////////////////////////////////
			// volume and trigger
			if((chan==11 && num==2), {
				// set volume bus
				cBus.midiLV2Fader3.set(value);
				// trigger zone
				if(value >= 0.01, { // start zone
					if(zone8.play1Act == 0, {
						zone8.play1Act = 1;
						zone8.play1 =
						Synth(\zone8play1, [
							\gate, 1,
							\lenBus, cBus.midiLV2KnobB2.index,
							\startPosition, zone8.startPos1,
							\ampBus, cBus.midiLV2Fader3.index,
							\distBus, cBus.midiLV2CrossFader.index,
							\pitchBus, cBus.midiLV2KnobB3.index,
							\pitchPattBus, cBus.pitchBus81.index,
							\jumpBus, cBus.jumpBus81.index,
							\ampPattBus, cBus.ampPattBus81.index,
							\panBus, cBus.panBus81.index,
							\dirBus, cBus.dirBus81.index,
							\pattSelBus, cBus.midiLV2KnobB1.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+");
						if(cfg.crashMode == 1, {
							// start pattern modulation task
							zone8.tPatt1 = Task(f81).play;
						});
						// update curZoneStart & curZoneLen
						cBus.midiLV2KnobB2.get({arg val;
							fSetCurZone.value(
								"81",								// id current zone
								spec.startPos21L.map(zone8.startPos1),	// start current zone
								spec.len81.at(val));					// length current zone
						});
					});
				},{ // stop zone
					if(zone8.play1Act == 1, {
						zone8.play1.release;
						fCountZones.value("P-");
						if(cfg.crashMode == 1, {
							zone8.tPatt1.stop;
						});
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
						\lenBus, cBus.midiLV2KnobB2.index,
						\startPosition, zone8.startPos1,
						\ampBus, cBus.midiLV2Fader3.index,
						\distBus, cBus.midiLV2CrossFader.index,
						\pitchBus, cBus.midiLV2KnobB3.index,
						\pitchPattBus, cBus.pitchBus81.index,
						\ampPattBus, cBus.ampPattBus81.index,
						\jumpBus, cBus.jumpBus81.index,
						\panBus, cBus.panBus81.index,
						\dirBus, cBus.dirBus81.index,
						\pattSelBus, cBus.midiLV2KnobB1.index
					], target: ~aBus.synthGroup);
					if(cfg.crashMode == 1, {
						// restart pattern modulation task
						zone8.tPatt1.stop; zone8.tPatt1 = Task(f81).play;
					});
					// update curZoneStart
					if(curZone == "81", {fSetCurZone.value("81", spec.startPos21L.map(zone8.startPos1), nil)});
				});
			});
			// length
			if((chan==9 && num==77), {
				cBus.midiLV2KnobB2.set(value);
				// update curZoneLen
				if(curZone == "81", {
					fSetCurZone.value("81", nil, spec.len81.at(value))
				});
			});
			// pitch
			if((chan==9 && num==78), {
				cBus.midiLV2KnobB3.set(value);
			});
			// pattern select
			if((chan==9 && num==60), {
				zone8.patt1Nbr = spec.patt81.at(value*127);
				cBus.midiLV2KnobB1.set(value);
				// zone17.tempoClock1.tempo = spec.tempo171.map(value);
				fSendLapisStatus.value("zone8pattNbr",zone8.patt1Nbr);
			});

			// Zone 16 controls //////////////////////////////////////////////////////////////////////////
			// 1: volume and trigger
			if((chan==11 && num==4), {
				// set volume bus
				cBus.midiLV2Fader5.set(value);
				// trigger zone
				if(value >= 0.01, { // start zone
					if(zone16.play1Act == 0, {
						zone16.play1Act = 1;
						zone16.play1 =
						Synth(\zone16play1, [
							\gate, 1,
							\ampBus, cBus.midiLV2Fader5.index,
							\distBus, cBus.midiLV2KnobC3.index,
							\resetPosBus, cBus.spModBus161.index,
							\lenBus, cBus.lenBus161.index,
							\panBus, cBus.midiLV2KnobC1.index,
							\ffBus, cBus.midiLV2KnobC2.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+");
						// start sample pointer modulation
						// if(zone16.spModOn1 == 1, {zone16.tModSP1 = Task(fModSP161).play});
						// update curZoneStart & curZoneLen
						cBus.lenBus161.get({arg val;
							fSetCurZone.value(
								"161",				// id current zone
								buffer.dyn1Start,		// start current zone
								val * sRate);			// length current zone
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
				cBus.midiLV2Fader6.set(value);
				// trigger zone
				if(value >= 0.01, { // start zone
					if(zone16.play2Act == 0, {
						zone16.play2Act = 1;
						zone16.play2 =
						Synth("zone16play2"++zone16.mode2, [
							\gate, 1,
							\ampBus, cBus.midiLV2Fader6.index,
							\distBus, cBus.midiLV2KnobD3.index,
							\lenBus, cBus.lenBus162.index,
							\pitchRangeBus, cBus.midiLV2KnobD1.index,
							\pitchSelectBus, cBus.midiLV2KnobD2.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+");
						// update curZoneStart & curZoneLen
						cBus.lenBus162.get({arg val;
							fSetCurZone.value(
								"162",				// id current zone
								buffer.dyn2Start,		// start current zone
								val * sRate);			// length current zone
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
				cBus.midiLV2Fader7.set(value);
				// trigger zone
				if(value >= 0.01, { // start zone
					if(zone16.play3Act == 0, {
						zone16.play3Act = 1;
						zone16.play3 =
						Synth("zone16play3"++zone16.mode3, [
							\gate, 1,
							\ampBus, cBus.midiLV2Fader7.index,
							\distBus, cBus.midiLV2KnobD3.index,
							\lenBus, cBus.lenBus163.index,
							\pitchRangeBus, cBus.midiLV2KnobD1.index,
							\pitchSelectBus, cBus.midiLV2KnobD2.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+");
						// update curZoneStart & curZoneLen
						cBus.lenBus163.get({arg val;
							fSetCurZone.value(
								"163",				// id current zone
								buffer.dyn3Start,		// start current zone
								val * sRate);			// length current zone
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
				cBus.midiLV2Fader8.set(value);
				// trigger zone
				if(value >= 0.01, { // start zone
					if(zone16.play4Act == 0, {
						zone16.play4Act = 1;
						zone16.play4 =
						Synth(\zone16play4, [
							\gate, 1,
							\ampBus, cBus.midiLV2Fader8.index,
							\distBus, cBus.midiLV2KnobC3.index,
							\resetPosBus, cBus.spModBus164.index,
							\lenBus, cBus.lenBus164.index,
							\panBus, cBus.midiLV2KnobC1.index,
							\ffBus, cBus.midiLV2KnobC2.index
						], target: ~aBus.synthGroup);
						fCountZones.value("P+");
						// start sample pointer modulation
						if(zone16.spModOn4 == 1, {zone16.tModSP4 = Task(fModSP164).play});
						// update curZoneStart & curZoneLen
						cBus.lenBus164.get({arg val;
							fSetCurZone.value(
								"164",				// id current zone
								buffer.dyn4Start,		// start current zone
								val * sRate);			// length current zone
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
				cBus.midiLV2KnobC1.set(value);
			});
			// filter frequency
			if((chan==9 && num==97), {
				cBus.midiLV2KnobC2.set(value);
			});
			// pitch mod depth
			if((chan==9 && num==100), {
				cBus.midiLV2KnobD1.set(value);
			});
			// pitch mod type
			if((chan==9 && num==117), {
				cBus.midiLV2KnobD2.set(value);
			});
			// distortion 1 & 4
			if((chan==9 && num==98), {
				cBus.midiLV2KnobC3.set(value);
			});
			// distortion 2 & 3
			if((chan==9 && num==118), {
				cBus.midiLV2KnobD3.set(value);
			});

			// Zone17 beatPlay controls //////////////////////////////////////////////////////////////////////////
			// trigger & volume
			if((chan==14 && num==8), {
				zone17.amp1 = value;

				// trigger zone
				if(value >= 0.01,{ // start zone
					if(zone17.play1Act == 0, {
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
						cBus.midiLV2KnobA1.get({arg val;
							fSetCurZone.value(
								"171",															// id current zone
								spec.startPos21L.map(zone17.startPos1),	// start current zone
								spec.len21L.at(val));									// length current zone
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

			// ZonePulse controls //////////////////////////////////////////////////////////////////////////
			// if((chan==14 && num==12), {
			// 	// set volume bus
			// 	cBus.pulseVolBus.set(value);
			// 	if(value >= 0.01, { // start zone
			// 		if(zonePulse.play1Act == 0, {
			// 			zonePulse.play1Act = 1;
			// 			zonePulse.play1 =
			// 			Synth(\pulse, [
			// 				\volBus, cBus.pulseVolBus.index,
			// 				\speedBus, cBus.pulseSpeedBus.index,
			// 				\widthBus, cBus.pulseWidthBus.index
			// 			], target: ~aBus.synthGroup);
			// 		});
			// 		},{ // stop zone
			// 			if(zonePulse.play1Act == 1, {
			// 				zonePulse.play1.release;
			// 				zonePulse.play1Act = 0;
			// 			});
			// 	});
			// });
			// if((chan==14 && num==13), {
			// 	cBus.pulseSpeedBus.set(value);
			// });
			// if((chan==14 && num==14), {
			// 	cBus.pulseWidthBus.set(value);
			// });

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
		{msg[1] == 2} {cBus.ardAna1Bus.set(msg[2]);}
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
				bufferView[0].timeCursorPosition = curPlayHead*sRate;
				bufferView[0].setSelectionStart(0, msg[4].asFloat*sRate);
				bufferView[0].setSelectionSize(0, msg[5].asFloat*sRate);
				bufferView[1].timeCursorPosition = curPlayHead*sRate - buffer.bStart;
				bufferView[1].setSelectionStart(0, msg[4].asFloat*sRate - buffer.bStart);
				bufferView[1].setSelectionSize(0, msg[5].asFloat*sRate);
				bufferView[2].timeCursorPosition = curPlayHead*sRate - buffer.dyn1Start;
				bufferView[2].setSelectionStart(0, msg[4].asFloat*sRate - buffer.dyn1Start);
				bufferView[2].setSelectionSize(0, msg[5].asFloat*sRate);
				bufferView[3].timeCursorPosition = curPlayHead*sRate - buffer.dyn2Start;
				bufferView[3].setSelectionStart(0, msg[4].asFloat*sRate - buffer.dyn2Start);
				bufferView[3].setSelectionSize(0, msg[5].asFloat*sRate);
				bufferView[4].timeCursorPosition = curPlayHead*sRate - buffer.dyn3Start;
				bufferView[4].setSelectionStart(0, msg[4].asFloat*sRate - buffer.dyn3Start);
				bufferView[4].setSelectionSize(0, msg[5].asFloat*sRate);
				bufferView[5].timeCursorPosition = curPlayHead*sRate - buffer.dyn4Start;
				bufferView[5].setSelectionStart(0, msg[4].asFloat*sRate - buffer.dyn4Start);
				bufferView[5].setSelectionSize(0, msg[5].asFloat*sRate);
			}.defer();
		});
		if((msg[2] == curRecZone.asInt) && (~showBufferView == 1), {  // recording zones
			curRecHead = msg[3];
			{ // update bufferViews
				bufferView[0].setSelectionStart(1, curRecHead*sRate);
				bufferView[0].setSelectionSize(1, 0.5*sRate);
				bufferView[1].setSelectionStart(1, curRecHead*sRate - buffer.bStart);
				bufferView[1].setSelectionSize(1, 0.5*sRate);
				bufferView[2].setSelectionStart(1, curRecHead*sRate - buffer.dyn1Start);
				bufferView[2].setSelectionSize(1, 0.5*sRate);
				bufferView[3].setSelectionStart(1, curRecHead*sRate - buffer.dyn2Start);
				bufferView[3].setSelectionSize(1, 0.5*sRate);
				bufferView[4].setSelectionStart(1, curRecHead*sRate - buffer.dyn3Start);
				bufferView[4].setSelectionSize(1, 0.5*sRate);
				bufferView[5].setSelectionStart(1, curRecHead*sRate - buffer.dyn4Start);
				bufferView[5].setSelectionSize(1, 0.5*sRate);
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
			{msg[3] == buffer.bStart}
			{fDisplayBufferView.value("B")}
			{msg[3] == buffer.dyn1Start}
			{fDisplayBufferView.value("C1")}
			{msg[3] == buffer.dyn2Start}
			{fDisplayBufferView.value("C2")}
			{msg[3] == buffer.dyn3Start}
			{fDisplayBufferView.value("C3")}
			{msg[3] == buffer.dyn4Start}
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
		cBus.ex3dProYpitch.set(spec.pitch61.at(msg[1]));
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
			{{mainBuf.zero; "Buffer cleared.".postln;}.defer()},{
				if(bufPart == "A",
					{fBufferRead.value(sampleArray, buffer.aLen, buffer.aStart, relativePath: relPath);},
					{fBufferRead.value(sampleArray, buffer.bLen, buffer.bStart, relativePath: relPath);}
				);
				if(norm != 0, {mainBuf.normalize(norm); ("Buffer normalized to" + norm).postln;});
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

	// responder to disable/enable x-axis joystick when HID captured is being played
	OSCdef(\lisaDisableXhid, { |msg|
		zone6.disableXhid == msg[1];
	},
	"/disablex"
	).fix;

	///////////////////////////////////////////// functions //////////////////////////////////////
	// modulate sample pointer offset for zone3play1
	fModSP31 = {
		inf.do({
			// repeat for number of elements in the array with offset values
			zone3.stepsOffset1tmp.size.do({arg i;
				// set resetPos bus with new start  position
				cBus.spModBus31.set(zone3.stepsOffset1tmp.at(i));

				if(cfg.deBug == 1, {
					if(i == 0, {"".postln});
					cBus.midiLV1KnobC1.get({arg val;
						("zone3play1 step" + i ++ ":" + (
							spec.startPos21L.map(zone3.startPos1) +
							(zone3.stepsOffset1tmp.at(i) * spec.len31.at(val)) / sRate
						).round(0.1)).postln;
					});
				});
				// wait
				spec.spModSpd31.at(zone3.spModSpd1).wait;
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
	// 			cBus.spModBus161.set(zone16.stepsOffset1.at(i) * modDepth);
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
				cBus.spModBus164.set(zone16.stepsOffset1.at(i) * zone16.spMod4ModDepth.next);
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
			//	cBus.midiLV2KnobB2.get({arg val; ["na offset", (jumpTot % (spec.len81.at(val)/sRate))].postln;});
			if(cfg.deBug == 1, {["zone8.play1: jumpTot na offset", jumpTot].postln;});
			// set parameters
			cBus.pitchBus81.set(zone8.patt1[patt1NbrTmp][elemNbr][3]);
			cBus.ampPattBus81.set(zone8.patt1[patt1NbrTmp][elemNbr][4]);
			cBus.panBus81.set(zone8.patt1[patt1NbrTmp][elemNbr][5]);
			cBus.dirBus81.set(zone8.patt1[patt1NbrTmp][elemNbr][6]);
			// repeats
			zone8.patt1[patt1NbrTmp][elemNbr][2].do({
				zone8.patt1[patt1NbrTmp][elemNbr][1].wait;
				f81jump.value(jumpTot);
			});
			zone8.patt1[patt1NbrTmp][elemNbr][1].wait;
			jumpTot = jumpTot + zone8.patt1[patt1NbrTmp][elemNbr][1];
			//	cBus.midiLV2KnobB2.get({arg val; ["na length", (jumpTot % (spec.len81.at(val)/sRate))].postln;});
			if(cfg.deBug == 1, {["zone8.play1: jumpTot na length", jumpTot].postln;});
			elemNbr = (elemNbr + 1) % zone8.patt1[patt1NbrTmp].size;
		}); // inf.do
	};
	f81jump = {
		arg jump;
		zone8.sign1 = (zone8.sign1 + 1) %2;
		cBus.jumpBus81.set((jump * sRate) + zone8.sign1); // add 0 or 1 frame to make sure the jump happens
	};

	// generic buffer reading function
	fBufferRead = {
		arg sampleList, bufferLen, bufferStart, relativePath = 1, tempFile;
		var numFramesSubTotal = 0, i = 0, numFramesToLoad, sampleDirLocal;

		("\nReading sample(s) into buffer starting at" + (bufferStart/sRate)).postln;
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
				mainBuf.readChannel(sampleDirLocal ++ sampleList[i],
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
			{bufferStart < buffer.bStart}
			{fDisplayBufferView.value("A")}
			{(bufferStart >= buffer.bStart) && (bufferStart < buffer.dyn1Start)}
			{fDisplayBufferView.value("B")}
			{(bufferStart >= buffer.dyn1Start) && (bufferStart < buffer.dyn2Start)}
			{fDisplayBufferView.value("C1")}
			{(bufferStart >= buffer.dyn2Start) && (bufferStart < buffer.dyn3Start)}
			{fDisplayBufferView.value("C2")}
			{(bufferStart >= buffer.dyn3Start) && (bufferStart < buffer.dyn4Start)}
			{fDisplayBufferView.value("C3")}
			{bufferStart >= buffer.dyn4Start}
			{fDisplayBufferView.value("C4")}
			;
		});
	};

	fDisplayBufferView = {
		arg section = "A";
		case
		{section == "A"}
		{
			mainBuf.write(bufferViewFolder++"A.wav","WAV","int16", buffer.aLen, buffer.aStart);
			{
				fileBufferView[0].openRead(bufferViewFolder++"A.wav");
				bufferView[0].soundfile = fileBufferView[0];
				bufferView[0].read(0, buffer.aLen, cfg.bufferViewBlocksize).refresh;
			}.defer(cfg.bufferViewDeferRead);
		}
		{section == "B"}
		{
			mainBuf.write(bufferViewFolder++"B.wav","WAV","int16", buffer.bLen, buffer.bStart);
			{
				fileBufferView[1].openRead(bufferViewFolder++"B.wav");
				bufferView[1].soundfile = fileBufferView[1];
				bufferView[1].read(0, buffer.bLen, cfg.bufferViewBlocksize).refresh;
			}.defer(cfg.bufferViewDeferRead);
		}
		{section == "C1"}
		{
			mainBuf.write(bufferViewFolder++"C1.wav","WAV","int16",  zoneRec.dynLenMaxFrames, buffer.dyn1Start);
			{
				fileBufferView[2].openRead(bufferViewFolder++"C1.wav");
				bufferView[2].soundfile = fileBufferView[2];
				bufferView[2].read(0, zoneRec.dynLenMaxFrames, cfg.bufferViewBlocksize).refresh;
			}.defer(cfg.bufferViewDeferRead);
		}
		{section == "C2"}
		{
			mainBuf.write(bufferViewFolder++"C2.wav","WAV","int16", zoneRec.dynLenMaxFrames, buffer.dyn2Start);
			{
				fileBufferView[3].openRead(bufferViewFolder++"C2.wav");
				bufferView[3].soundfile = fileBufferView[3];
				bufferView[3].read(0, zoneRec.dynLenMaxFrames, cfg.bufferViewBlocksize).refresh;
			}.defer(cfg.bufferViewDeferRead);
		}
		{section == "C3"}
		{
			mainBuf.write(bufferViewFolder++"C3.wav","WAV","int16", zoneRec.dynLenMaxFrames, buffer.dyn3Start);
			{
				fileBufferView[4].openRead(bufferViewFolder++"C3.wav");
				bufferView[4].soundfile = fileBufferView[4];
				bufferView[4].read(0, zoneRec.dynLenMaxFrames, cfg.bufferViewBlocksize).refresh;
			}.defer(cfg.bufferViewDeferRead);
		}
		{section == "C4"}
		{
			mainBuf.write(bufferViewFolder++"C4.wav","WAV","int16", 2*zoneRec.dynLenMaxFrames, buffer.dyn4Start);
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
		buffer.loadToFloatArray(start, num, {
			arg arr, buf;
			"LoadToFloat executed.".postln;
			buf.loadCollection(arr.collect{|x| x*mul}, start, {arg arr, buf;  "Amplify current zone finished.".postln});
		});
	};

	fQuantize = {
		// quantized conversions
		if(cfg.quantize == 1, {
			"\nQuantizing mapping envelopes.".postln;
			spec.len41 = Env.new(
				[60/16, 60/8, 60/4, 60/2, 60/1, 60/0.5] / cfg.bpm,
				[25.6, 25.6, 25.6, 25.6, 25.6],[\step, \step, \step, \step, \step]);
			spec.spModSpd31 = Env.new(
				[60/8, 60/4, 60/2, 60/1, 60/0.5, 60/0.25] / cfg.bpm,
				[25.6, 25.6, 25.6, 25.6, 25.6],[\step, \step, \step, \step, \step]);
		},{
			"\nDe-Quantizing mapping envelopes.".postln;
			spec.len41 = Env.xyc([[0, 0.2,\exp],[64, 30, \lin],[127, 60]]);
			spec.spModSpd31 = Env.new([0.02,10],[127],[\exp]);
		});
		cBus.midiLV2KnobA1.set(spec.len41.at(64));
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

	// sending LapisStatus OSC to local or touchOSC
	fSendLapisStatus = {
		arg type, value;
		if((~lapisStatusDestination == "touchOSC") || (~lapisStatusDestination == "both"),
			{cfg.touchOSCAddr.sendMsg("/lapistatus/"++type,value)});
		if((~lapisStatusDestination == "local") || (~lapisStatusDestination == "both"),
			{cfg.localAddr.sendMsg("/lapistatus",type,value)});
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
			spec.pitch61 = Env([0.25,0.25,0.5,1,2],[0.1,0.2,0.5,0.2],\step);
		}, {
			"\nLiveSampler: Remapping pitch61 because pitchshift is free (not only in octaves)".postln;
			spec.pitch61 = Env.new([0.1,12],[1],[\exp]);
		});
	};

	///////////////////////////////////////////// Tasks //////////////////////////////////////

	// task to postln current zone info for debugging
	tCurZone = Task({
		inf.do({
			['curZone', curZone, curZoneStart / sRate, curZoneLen / sRate].postln;
			1.wait;
		});
	});

	///////////////////////////////////////////// GUI //////////////////////////////////////

	~wLiveSampler = Window("LiveSampler", Rect(20, (screenHeight - 160), 330, 100), false);
	//~wLiveSampler.view.background_(Color.black);
	//~wLiveSampler.alpha_(0.9);
	~wLiveSamplerAvail = 1;

	// display status of zone6.play4
	dispBaseBtn = SmoothButton(~wLiveSampler, Rect(25,10,50,23))
	.border_(1)
	.radius_(3)
	.canFocus_(false)
	.font_(fontButton)
	.background_(Color.white)
	.states_([["BB"]]);

	// display status of zone6.play5
	dispBaseBtn2 = SmoothButton(~wLiveSampler, Rect(80,10,50,23))
	.border_(1)
	.radius_(3)
	.canFocus_(false)
	.font_(fontButton)
	.background_(Color.white)
	.states_([["OS"]]);

	// display status of disabled/enabled start position
	dispDisableStartPos = SmoothButton(~wLiveSampler, Rect(135,10,50,23))
	.border_(1)
	.radius_(3)
	.canFocus_(false)
	.font_(fontButton)
	.background_(Color.white)
	.states_([["SP"]]);

	// display status of disabled/enabled pitch control
	dispDisablePitch = SmoothButton(~wLiveSampler, Rect(190,10,50,23))
	.border_(1)
	.radius_(3)
	.canFocus_(false)
	.font_(fontButton)
	.background_(Color.white)
	.states_([["PT"]]);

	// display number of playback zones
	dispPlay = SmoothButton(~wLiveSampler, Rect(255,10,50,23))
	.border_(1)
	.radius_(3)
	.canFocus_(false)
	.font_(fontButton)
	.background_(Color.white)
	.stringColor_(Color.blue)
	.states_([["0"]]);

	// display number of recording zones
	dispRec = SmoothButton(~wLiveSampler, Rect(255,38,50,23))
	.border_(1)
	.radius_(3)
	.canFocus_(false)
	.font_(fontButton)
	.background_(Color.white)
	.stringColor_(Color.red)
	.states_([["0"]]);

	// display number of effect zones
	dispEfx = SmoothButton(~wLiveSampler, Rect(255,66,50,23))
	.border_(1)
	.radius_(3)
	.canFocus_(false)
	.font_(fontButton)
	.background_(Color.white)
	.states_([["0"]]);

	// drag destination for sample load into A
	loadFileA = DragSink(~wLiveSampler, Rect(25,39,215,21))
	.string_("Drag file(s) to load in A")
	.canFocus_(false)
	.font_(fontLabel)
	.align_(\center)
	.background_(Color.white)
	.stringColor_(Color.black)
	.receiveDragHandler_({
		var dragTemp = View.currentDrag;
		if(dragTemp.isString, {dragTemp = dragTemp.split(nl)}); // if only one file is dragged, make it into an array with this trick
		// dragTemp.postln;
		if(cfg.dragEmptyBeforeLoad == 1, {mainBuf.zero; "Buffer cleared.".postln;});
		fBufferRead.value(dragTemp, mainBuf.numFrames, buffer.aStart, 0);
		if(~showBufferView == 1, {fDisplayBufferView.value("A")});
	});

	// drag destination for sample load into B
	loadFileB = DragSink(~wLiveSampler, Rect(25,67,215,21))
	.canFocus_(false)
	.string_("Drag file(s) to load in B")
	.font_(fontLabel)
	.align_(\center)
	.background_(Color.white)
	.stringColor_(Color.black)
	.receiveDragHandler_({
		var dragTemp = View.currentDrag;
		if(dragTemp.isString, {dragTemp = dragTemp.split(nl)}); // if only one file is dragged, make it into an array with this trick
		// dragTemp.postln;
		if(cfg.dragEmptyBeforeLoad == 1, {mainBuf.zero; "Buffer cleared.".postln;});
		fBufferRead.value(dragTemp, buffer.bLen, buffer.bStart, 0);
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
			mainBuf.zero;
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
		// // P plots buffer
		// if((keycode == 35), {
		// 	mainBuf.plot("Sample Buffer");
		// 	~processBuf.plot("Process Buffer");
		// 	"Buffer being plotted.".postln;
		// });
		// A amplifies current zone
		if((keycode == 0) && (modifiers == 0), {
			fAmpCurZone.value(mainBuf, curZoneStart, curZoneLen, cfg.ampCurZoneFactor);
			"\nAmplifying current zone...".postln;
		});
		// S saves buffer to disk
		if((keycode ==1), {
			mainBuf.write(thisProcess.platform.recordingsDir++"/LiveSampler"++Date.getDate.format("_%y%m%d_%H%M%S")++".aif");
			"LiveSampler: save samplebuffer".postln;
		});
		// T loads testSampleList
		if((keycode == 17), {
			fBufferRead.value(~testSampleList, buffer.aLen, buffer.aStart);
			fBufferRead.value(~testSampleList, buffer.bLen, buffer.bStart);
			fBufferRead.value(~testSampleList, buffer.dyn1Len, buffer.dyn1Start);
			fBufferRead.value(~testSampleList, buffer.dyn2Len, buffer.dyn2Start);
			fBufferRead.value(~testSampleList, buffer.dyn3Len, buffer.dyn3Start);
			fBufferRead.value(~testSampleList, buffer.dyn4Len, buffer.dyn4Start);
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
		bufferViewLab[0] = StaticText(~wBufferView, Rect(20,10,500,15)).font_(Font("Helvetica",10))
		.string_("A                      10                       20                       30                      40                       50                      60");
		bufferViewLab[1] = StaticText(~wBufferView, Rect(475 + 20,10,700,15)).font_(Font("Helvetica",10))
		.string_("B          70                      80                       90                     100                     110                    120                    130                     140                     150");
		bufferViewLab[2] = StaticText(~wBufferView, Rect(20,240,1120,15)).font_(Font("Helvetica",10))
		.string_("C                     160                     170                    180                     190                    200                    210                     220                    230                     240                    250                     260                    270                     280                     290                    300");

		// keyboard tracking
		~wBufferView.view.keyDownAction_({
			arg view, char, modifiers, unicode, keycode;
			// L clears buffer
			if((keycode == 37), {
				mainBuf.zero;
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
	//tCurZone.start;

	// display LapisStatus window
	if(~lapisStatus == 1, {
		LapisStatus.new(inputPeakChans: ~aBus.inputPeakChans, inputPeakStartChan: ~aBus.inputPeakStartChan)
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
		OSCdef(\lisaSampleLoad).free; OSCdef(\lisaQuant).free; OSCdef(\lisaPanic).free; OSCdef(\lisaDisableXhid).free;
		mainBuf.free;
		diskPlay.sampleList.size.do({ arg i;
			if(diskPlay.buf[i].notNil, {diskPlay.buf[i].free});
		});
		mtfBufL.free;
		mtfBufR.free;
		tCurZone.stop;
		zone3.tModSP1.stop;
		// zone16.tModSP1.stop;
		zone16.tModSP4.stop;
		zone8.tPatt1.stop;
		//	if(~wControllersAvail.notNil, {~wControllers.close});
		//	if(~wInOutAvail.notNil, {~wInOut.close});
		//	if(~wSynthKeysAvail.notNil, {~wSynthKeys.close});
		if(~wLapis.notNil, {~wLapis.close});
		~wLiveSamplerAvail = nil;
		if(~wBufferView.notNil, {~wBufferView.close});
	});

	//~testSampleList = ["sines/s 440.aif","sines/s 440.aif","sines/s 440.aif","sines/s 440.aif","sines/s 440.aif"];
	//~testSampleList = ["dr_AmbIntrigue2+Light1b.aif"];
	//~testSampleList = ["voice/ob promise.aiff"];
	//~testSampleList = ["solo2/wd_glass1PSwobblypart.aif"];
	//~testSampleList = ["soundcheck left right.aif"];
	//~testSampleList = ["melodic/mel tokyo almu03"];
	//~testSampleList = ["speeldoosmelodyTS-part1.aif"];
	//~testSampleList = ["v monks.aiff"];
	~testSampleList = ["melodic/mel violins1.aif"];

}); // wait for boot

)

