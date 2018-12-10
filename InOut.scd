// InOut: Audio Output Central by Robert van Heumen 2013.
// Tested with SC 3.6.6.

// There are three audio busses you can send Synths to:
// ~aBus.outA (Synth outBusA):
//	sending to efxBus pre-fade for internal efx
//	volume control by Faderfox knob
//	sending to efxBus post-fade for internal efx
// 	sending to outBusMain for last output stage
// ~aBus.outB (Synth outBusB):
//	sending to efxBus pre-fade for internal efx
//	volume control by footpedal via Arduino
//	sending to efxBus post-fade for internal efx
// 	sending to outBusMain for last output stage
// ~aBus.outBL (Synth outBusBL):
//	sending to efxBus pre-fade for internal efx
//	volume control by footpedal via Arduino
//	adding limiter
//	sending to efxBus post-fade for internal efx
// 	sending to outBusMain for last output stage
// ~aBus.outMain (Synth outBusMain):
//	recording in ~processBuf
// 	sending out for resampling
//	check bad values and possibly add subfilter
//	send mono limited to output for analog efx
//	possibly add limiter
//	send to output for monitor with realtime attenuation
//	send to output for mains with realtime attenuation

// Configuration switches on LX
//	RED1 switches between original (RED1=off) and alternative (RED1=on) audio inputs as specified in GlobalVars.rtf
//	RED4 switches between external (RED4=off) and internal (RED4=on, channel 11/12) audio inputs

(
s.waitForBoot({

	///////////////////////////////////////////// Local vars //////////////////////////////////////

	var sRate = s.sampleRate;
	var cfg = (
		processLen: sRate * 30,
		localAddr: NetAddr("127.0.0.1", 57120),
		docDir: Document.dir++"/Lapis/",
		libDir: "Data/",
		startMeter: 1, // start meter window
		startCueMix: 0, // start Motu CueMix FX
		startActMon: 0, // start Activity Monitor
		startMOTUSetup: 0, // start MOTU Audio Setup to check return assign channel
		midiSrc: "MUL", // filtering allowed midi sources; comma-separated list f.e.: MUL = Motu Ultralite, IAC1, IAC2, IAC3, LPK
		background: "image", // background images method (pen or image)
	);
	var ardAna1Bus, midiLV2KnobMasterVol, fInitOutput, fSetImage, fProjectInfo, fServerMeter;
	var specOutAmp = Env.xyc([[0.0, 0.0, \lin], [0.001, 0.001,\exp],[0.2, 0.2, \lin],[1, 1.0]]);
	var specOutAmpNoArd = Env.xyc([[0.0, 0.0, \lin], [0.001, 0.001,\exp],[0.2, 0.2, \lin],[0.5, 1.0], [1,1.0]]);
	var screenHeight = Window.screenBounds.height, screenWidth = Window.screenBounds.width;
	var mainOutChan, mainOutLabel, monOutLabel, monOutChan, inputLabel, inputChan;
	var inGain = Array.newClear(4), inGainLabel;
	var outMonitorAttLabel, outMonitorAttVal, outMainAttLabel, outMainAttVal;
	var oscOn = 0;
	// var imageFileList = ["flower2","flower4","flower5","flower7","flower8","flower1","flower11"], imageSame = false;
	// var imageFileList = ["sound"], imageSame = false;
	// var imageFileList = ["Point1","Point2","Point3","Point4","Point5","Point6"], imageSame = true;
	var imageFileList = ["Sleeuwits", "Stankowski"], imageSame = false;
	var imageFileDone = Array.new(imageFileList.size);
	var fontLabel, fontButton, fontSmall;
	var isRecording = 0;
	var gainDefault = #[1,1,1,1];

	cfg.docDir.postln;

	~aBus = nil; // refresh global vars
	"GlobalVars.scd".loadRelative();
	~processBuf = Buffer.alloc(s, cfg.processLen, 2);
	fontLabel = Font(~font,10); fontButton = Font(~font,12); fontSmall = Font(~font,9);
	s.recChannels_(~aBus.recChannels); ("Number of recording channels set to" + s.recChannels).postln;

	///////////////////////////////////////////// Output Synths //////////////////////////////////////

	// set number of gained channels depending on number of input channels
	// this is done in the same way in ServerMeterRvH.sc
	if( Server.local.options.numInputBusChannels == 2 ) {
		~aBus.gainedChans = ~aBus.gainedChans[0..1];
		gainDefault = #[1,1];
	};

	SynthDef(\inBus, {
		arg gate, gain = gainDefault;
		// var in = SoundIn.ar([0,1,2,3]);
		var in = SoundIn.ar(~aBus.gainedChans);
		if(~aBus.inputThru == 1, { Out.ar(~aBus.inputThruChan, in) });
		SendPeakRMS.kr(in * gain, replyRate: 10, cmdName: "/InBus"); // send to ServerMeter
		Out.ar(50, in * gain);
	}).add;

	SynthDef(\outBusA, {
		arg volBus, gate;
		var sig;
		sig = In.ar(~aBus.outA,2); 			// input from outA bus
		Out.ar(~aBus.outEfxPre, sig);		// output to efx bus pre-fade
		sig = In.kr(volBus,1) * sig * EnvGen.kr(Env.adsr(0,0,1,0),gate); // apply volume control and envelope
		Out.ar(~aBus.outEfxPost, sig);	// output to efx bus post-fade
		Out.ar(~aBus.outMain, sig);		// output to main bus
	}).add;

	SynthDef(\outBusB, {
		arg volBus, gate;
		var sig;
		sig = In.ar(~aBus.outB,2);			// input from outB bus
		Out.ar(~aBus.outEfxPre, sig);		// output to efx bus pre-fade
		sig = In.kr(volBus,1) * sig * EnvGen.kr(Env.adsr(0,0,1,0),gate);	// apply volume control and envelope
		Out.ar(~aBus.outEfxPost, sig);	// output to efx bus post-fade
		Out.ar(~aBus.outMain, sig);		// output to main bus
	}).add;

	SynthDef(\outBusBL, { // like outBusB but with limiter
		arg volBus, gate;
		var sig;
		sig = In.ar(~aBus.outBL,2);					// input from outBL bus
		Out.ar(~aBus.outEfxPre, sig);				// output to efx bus pre-fade
		sig = In.kr(volBus,1) * sig * EnvGen.kr(Env.adsr(0,0,1,0),gate);	// apply fade and envelope
		sig = Limiter.ar(sig, 0.90).clip2(0.95);  // limiter
		Out.ar(~aBus.outEfxPost, sig);			// output to efx bus post-fade
		Out.ar(~aBus.outMain, sig);				// output to main bus
	}).add;

	SynthDef(\outBusMain,{
		arg gate, monAtt, mainAtt, resampAtt;
		var sig, sigMon;

		sig = In.ar(~aBus.outMain,2) * EnvGen.kr(Env.adsr(0,0,1,0),gate);

		// fill circular process buffer
		RecordBuf.ar(sig, ~processBuf, loop: 1);

		// output for resampling (stereo) - has to be done in the main output stage to be able to resample efx too
		if(~aBus.resamplingChan.notNil, {
			Out.ar(~aBus.resamplingChan, resampAtt * sig);
			if (~showResampleMeters) {
				SendPeakRMS.kr(resampAtt * sig, replyRate: 10, cmdName: "/ResampleBus"); // send to ServerMeter
			};
		});

		// tidy up the signal, getting ready to send out
		sig = Select.ar(CheckBadValues.ar(sig, 0, 0), [sig, DC.ar(0), DC.ar(0), sig]);  // don't let bad math hit the speakers
		if(~aBus.outMainSubFilter == 1, {sig = HPF.ar(sig, 50); "InOut: subfilter enabled.".postln;}); // reduce subsonics

		// analog efx output (mono) with limiter
		if(~aBus.outAnalogEfx == 1, {
			Out.ar(~aBus.outAnalogEfxChan, ~aBus.outAnalogEfxAtt * Mix.new(Limiter.ar(sig, 0.9).clip2(0.95)));
		});

		// master limiter
		if(~aBus.outMainLimiter == 1, {sig = Limiter.ar(sig, 0.95).clip2(0.98); "InOut: limiter enabled.".postln;});

		// monitor output
		if(~aBus.outMonitor == 1, {
			if(~aBus.outMonitorStereo == 0, {sigMon = Mix.new(sig)}, {sigMon = sig}); // if mono mixdown to one channel
			if(~aBus.outMonitorCompressed == 1, {sigMon = Compander.ar(sigMon, sigMon, thresh:0.2, slopeAbove:1/4)});
			Out.ar(~aBus.outMonitorChan, monAtt * sigMon);
		});

		// main output
		if(~aBus.outMainStereo == 0, {sig = Mix.new(sig);});
		Out.ar(~aBus.outMainChan, mainAtt * sig);
	}).add;

	s.sync; // to enable SynthDefs to be send to the server


	///////////////////////////////////////////// Init //////////////////////////////////////

	ardAna1Bus = Bus.control(s,1);
	ardAna1Bus.set(specOutAmp.at(1));
	midiLV2KnobMasterVol = Bus.control(s,1);
	midiLV2KnobMasterVol.set(specOutAmp.at(1));

	///////////////////////////////////////////// Functions //////////////////////////////////////

	fInitOutput = {
		arg mode, onClose = 0;
		if(mode == 0,
			{ // stop sound
				~aBus.inGroup.free;
				~aBus.synthGroup.free;
				~aBus.outputGroup.free;
				~aBus.efxGroup.free;
				~aBus.mainGroup.free;
				~aBus.resampleGroup.free;
				if(onClose==0, {
					mainOutChan.background_(Color.white);
					if(~aBus.outMonitor == 1, {monOutChan.background_(Color.white)});
				});
				"InOut: output stopped.".postln;
			},
			{ // init sound
				~aBus.inGroup = Group.new();
				~aBus.synthGroup = Group.new(~aBus.inGroup, \addAfter);
				~aBus.outputGroup = Group.new(~aBus.synthGroup, \addAfter);
				~aBus.efxGroup = Group.new(~aBus.outputGroup, \addAfter);
				~aBus.mainGroup = Group.new(~aBus.efxGroup, \addAfter);
				~aBus.resampleGroup = Group.new(~aBus.mainGroup, \addAfter);
				~aBus.inBusSynth = Synth(\inBus, [\gain, ~aBus.inBusGain, \gate,1], target: ~aBus.inGroup);
				~aBus.outAsynth = Synth(\outBusA, [\volBus, midiLV2KnobMasterVol.index,
					\gate,1], target: ~aBus.outputGroup);
				~aBus.outBsynth = Synth(\outBusB, [\volBus, ardAna1Bus.index,
					\gate,1], target: ~aBus.outputGroup);
				~aBus.outBLsynth = Synth(\outBusBL, [\volBus, ardAna1Bus.index,
					\gate,1], target: ~aBus.outputGroup);
				~aBus.outMainsynth = Synth(\outBusMain, [\gate,1,
					\monAtt, ~aBus.outMonitorAtt.asFloat, \mainAtt, ~aBus.outMainAtt.asFloat, \resampAtt, ~aBus.outResamplingAtt.asFloat,
					\outMainStereo, ~aBus.outMainStereo
				],
				target: ~aBus.mainGroup);
				mainOutChan.background_(~colorOn);
				if(~aBus.outMonitor == 1, {monOutChan.background_(~colorOn)});
				// outMainAttVal.value = ~aBus.outMainAtt;
				// if(~aBus.outMonitor == 1, {outMonitorAttVal.value = ~aBus.outMonitorAtt; });
				"InOut: output initialized.".postln;
		});
	};

	fSetImage = {
		var alpha = 1, colorBg = Color.grey(0.98);
		var imageObj, imageFile, imageFound = 0, imageFileIndex, fPen;
		if(cfg.background == "", {cfg.background = ["pen","image"].choose});
		if(cfg.background == "pen", { // pen drawing
			fPen = { arg win;
				Pen.fillColor = Color.black;
				Pen.moveTo(0@win.bounds.height); Pen.lineTo(screenWidth@win.bounds.height);
				Pen.lineTo(screenWidth@win.bounds.height-5); Pen.lineTo(0@win.bounds.height-5);
				Pen.perform(\fill);
			};
			~wInOut
			.background_(colorBg)
			.alpha_(alpha)
			.drawFunc = { fPen.value(~wInOut) };
			~wInOut.refresh;
			if(~wLiveSamplerAvail.notNil, {
				~wLiveSampler
				.background_(colorBg)
				.alpha_(alpha)
				.drawFunc = { fPen.value(~wLiveSampler) };
				~wLiveSampler.refresh;
			});
			if(~wSynthKeysAvail.notNil, {
				~wSynthKeys
				.background_(colorBg)
				.alpha_(alpha)
				.drawFunc = { fPen.value(~wSynthKeys) };
				~wSynthKeys.refresh;
			});
			if(~wControllersAvail.notNil, {
				w = ~wControllers
				.background_(colorBg)
				.alpha_(alpha)
				.drawFunc = { fPen.value(~wControllers) };
				~wControllers.refresh;
			});
		},
		{ // display images
			while(
				{imageFound == 0}, {
					imageFileIndex = imageFileList.size.rand;
					if(imageFileDone.includes(imageFileIndex).not, {
						imageFileDone.add(imageFileIndex);
						imageFound = 1;
						if(imageFileDone.size == imageFileList.size, {imageFileDone = Array.new(imageFileList.size)});
					});
			});
			imageFile = imageFileList[imageFileIndex];
			imageObj = Image.new(cfg.docDir ++ "/" ++ cfg.libDir ++ "Images/" ++ imageFile ++ if(imageSame,{""},{"-1"}) ++ ".png");
			if(~wLiveSamplerAvail.notNil, {
				~wLiveSampler.view.backgroundImage_(imageObj);
				~wLiveSampler.background_(colorBg);
			});
			imageObj = Image.new(cfg.docDir ++ "/" ++ cfg.libDir ++ "Images/" ++ imageFile ++ if(imageSame,{""},{"-2"}) ++ ".png");
			if(~wSynthKeysAvail.notNil, {
				~wSynthKeys.view.backgroundImage_(imageObj);
				~wSynthKeys.background_(colorBg);
			});
			imageObj = Image.new(cfg.docDir ++ "/" ++ cfg.libDir ++ "Images/" ++ imageFile ++ if(imageSame,{""},{"-3"}) ++ ".png");
			if(~wControllersAvail.notNil, {
				~wControllers.view.backgroundImage_(imageObj);
				~wControllers.background_(colorBg);
			});
			imageObj = Image.new(cfg.docDir ++ "/" ++ cfg.libDir ++ "Images/" ++ imageFile ++ if(imageSame,{""},{"-4"}) ++ ".png");
			~wInOut.view.backgroundImage_(imageObj);
			~wInOut.background_(colorBg);
		});
	};

	fProjectInfo = {
		("\nProject "++~project++"...").postln;
		("\nRED1: Switch inputs 1 & 2 between" +  ~aBus.inChan1 + "&" + ~aBus.inChan2 +
			"to" + ~aBus.inChan1alt + "&" + ~aBus.inChan2alt).postln;
		"RED2: Switch efx bank from deciMate & deLay to multiTapFreeze & ampPitchFol".postln;
		"RED3: Switch efx source from sample playback to input channels".postln;
		("RED4: Switch input channels between"
			+~aBus.inChan1++" & "++~aBus.inChan2+"and"+~aBus.resamplingChan++" & "++(~aBus.resamplingChan+1)).postln;

		"\nInOut keyboard shortcuts:".postln;
		"	esc stops sound output".postln;
		"	i posts project info".postln;
		"	n posts Node info".postln;
		"	m starts s.meter".postln;
		"	o toggles OSC monitor ON/OFF".postln;
		"	alt-r toggles recordiing ON/OFF".postln;

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
		"	d toggles controller data postln\n".postln;
	};

	fServerMeter = {
		ServerMeter(s, xPos: 20, yPos: 150, numResampleChans: if(~showResampleMeters, { 2 }, { 0 }));
	};

	///////////////////////////////////////////// Arduino //////////////////////////////////////

	// responder for analog sensors
	OSCdef(\inoutArdAna, {
		arg msg, time, addr, recvPort;
		// ("SynthKeys OSC RCV ArdAna: " ++ msg).postln;
		case
		{msg[1] == 1} {}
		{msg[1] == 2} {
			ardAna1Bus.set(specOutAmp.at(msg[2]));
			// specOutAmp.at(msg[2]).postln;
		}
		;
	},
	"/ard/ana"
	);

	///////////////////////////////////////////// HID //////////////////////////////////////

	if(~noArduino == 1, { // only if Arduino not available
		OSCdef(\inoutEx3d, {
			arg msg, time, addr, recvPort;
			var cookie = msg[1];
			var val = msg[2];
			// ("InOut OSC RCV Ex3d: " ++ msg).postln;

			if(~oscSrc == "jx", {
				cookie = cookie * 127; 			// back to the MIDI range; this might be f.e. 2 or 2.0001 or 1.9999
				cookie = (cookie + 0.1).floor; 	// make up for rounding errors then make into integer
				// ("Cookie:" + cookie + "Value:" + val).postln;
			});

			case
			{cookie == 20} 		// Slider
			{
				if(~oscSrc == "jx", {val = (1-val) * 255}); // junXion repair
				// ardAna1Bus.set(specOutAmpNoArd.at(msg[2]));
				ardAna1Bus.set(specOutAmpNoArd.at( 1 - (msg[2]/255) ));
			}; // case
		},
		"/hid/ex3d"
		).fix;
	});

	///////////////////////////////////////////// MIDI //////////////////////////////////////

	OSCdef(\inoutCC, {
		arg msg, time, addr, recvPort;
		var chan, num, value, src;
		chan = msg[1];
		num = msg[2];
		value = msg[3];
		src = msg[4].asString;
		//	[chan,num,value, src].postln;

		// only process midi if coming from the right source
		if(cfg.midiSrc.find(src).notNil, {
			// main volume control
			if((chan==11 && num==17), {
				midiLV2KnobMasterVol.set(specOutAmp.at(value));
			});
		}); // only process midi if coming from the right source
	},
	"/midi/control"
	).fix;

	OSCdef(\inoutNON, { |msg|
		var chan, note, value, src;
		chan = msg[1];
		note = msg[2];
		value = msg[3];
		src = msg[4].asString;
		//	[chan,note,value, src].postln;

		// only process midi if coming from the right source
		if(cfg.midiSrc.find(src).notNil, {
			// input channels switching
			if(chan == 0, {
				case
				{(note == 0) && (~aBus.inAlt == 0)} // switching input 1 & 2 to alternative
				{
					("InOut: Switch inputs 1 & 2 from" + ~aBus.inChan1 + "&" + ~aBus.inChan2 +
						"to" + ~aBus.inChan1alt + "&" + ~aBus.inChan2alt).postln;
					~aBus.inChan1 = ~aBus.inChan1alt;
					~aBus.inChan2 = ~aBus.inChan2alt;
					~aBus.inAlt = 1;
					inputChan.states_([[~aBus.inChan1.asString ++ "," ++ ~aBus.inChan2.asString]]);
				}
				{(note == 3) && (~aBus.inInt == 0)} // switching inputs 1 & 2 to internal
				{
					("InOut: Switch inputs 1 & 2 from" + ~aBus.inChan1 + "&" + ~aBus.inChan2 +
						"to" + ~aBus.resamplingChan + "&" + (~aBus.resamplingChan+1)).postln;
					~aBus.inChan1 = ~aBus.resamplingChan;
					~aBus.inChan2 = ~aBus.resamplingChan + 1;
					~aBus.inInt = 1;
					inputChan.states_([[~aBus.inChan1.asString ++ "," ++ ~aBus.inChan2.asString]]);
				};
			});
		}); // only process midi if coming from the right source
	},
	"/midi/noteOn"
	).fix;

	OSCdef(\inoutNOF, {
		arg msg, time, addr, recvPort;
		var chan, note, value, src;
		chan = msg[1];
		note = msg[2];
		value = msg[3];
		src = msg[4].asString;
		//	[chan,note,value, src].postln;

		// only process midi if coming from the right source
		if(cfg.midiSrc.find(src).notNil, {
			// input channels switching
			if(chan==0, {
				case
				{(note == 0) && (~aBus.inAlt == 1)} // switching input 1 & 2 back to original
				{
					("InOut: Switch inputs 1 & 2 from" + ~aBus.inChan1 + "&" + ~aBus.inChan2 +
						"to" + ~aBus.inChan1org + "&" + ~aBus.inChan2org).postln;
					~aBus.inChan1 = ~aBus.inChan1org;
					~aBus.inChan2 = ~aBus.inChan2org;
					~aBus.inAlt = 0;
					inputChan.states_([[~aBus.inChan1.asString ++ "," ++ ~aBus.inChan2.asString]]);
				}
				{(note == 3) && (~aBus.inInt == 1)} // switching inputs 1 & 2 to back to what they were
				{
					("InOut: Switch inputs 1 & 2 from" + ~aBus.inChan1 + "&" + ~aBus.inChan2 + "to" +
						if(~aBus.inAlt == 0, {~aBus.inChan1org}, {~aBus.inChan1alt})  + "&" +
						if(~aBus.inAlt == 0, {~aBus.inChan2org}, {~aBus.inChan2alt})).postln;
					~aBus.inChan1 = if(~aBus.inAlt == 0, {~aBus.inChan1org}, {~aBus.inChan1alt});
					~aBus.inChan2 = if(~aBus.inAlt == 0, {~aBus.inChan2org}, {~aBus.inChan2alt});
					~aBus.inInt = 0;
					inputChan.states_([[~aBus.inChan1.asString ++ "," ++ ~aBus.inChan2.asString]]);
				};
			});
		}); // only process midi if coming from the right source
	},
	"/midi/noteOff"
	).fix;


	///////////////////////////////////////////// OSC responders //////////////////////////////////////

	// responder to stop everything
	OSCdef(\inoutPanic, {
		arg msg, time, addr, recvPort;
		"Panic InOut".postln;
		{fInitOutput.value(0)}.defer();
		{fInitOutput.value(1)}.defer(0.1);
	},
	"/panic"
	);

	// responder to refresh image
	OSCdef(\inoutRefreshImage, {
		arg msg, time, addr, recvPort;
		{fSetImage.value()}.defer();
	},
	"/imageRefresh"
	);

	///////////////////////////////////////////// GUI //////////////////////////////////////

	~wInOut = Window("InOut" + "  |  " + ~project, Rect(940, (screenHeight - 160), 295, 100), false);
	~wInOutAvail = 1;

	inputLabel = StaticText(~wInOut, Rect(20, 12, 50, 16))
	.font_(fontLabel)
	.background_(Color.white.alpha_(0.7))
	.string_(" Input ");

	inputChan = SmoothButton(~wInOut, Rect(85,10,45,20))
	.border_(1)
	.radius_(3)
	.canFocus_(false)
	.font_(fontButton)
	.background_(Color.white)
	.states_([[~aBus.inChan1.asString ++ "," ++ ~aBus.inChan2.asString]]);

	// input channel levels
	4.do {arg i;
		StaticText(~wInOut, Rect(146+(i*30), -2, 20, 15))
		.background_(Color.white.alpha_(0.7)).font_(fontSmall).string_(50+i).align_(\center);
		inGain[i] = (SmoothNumberBox(~wInOut, Rect(140+(i*30), 9, 30, 22))
			.border_(1)
			.radius_(3)
			.background_(Color.white)
			.font_(fontButton)
			.value_(~aBus.inBusGain[i].ampdb.round(0.1))
			.clipHi_(21)
			.clipLo_(-6.0)
			// .canFocus_(false)
			.scroll_step_(1)
			.step_(0.1)
			.align_(\center)
			.action_({
				~aBus.inBusGain[i] = inGain[i].value.dbamp;
				("In "++i++" Gain:" + ~aBus.inBusGain[i]).postln;
				~aBus.inBusSynth.set(\gain,~aBus.inBusGain);
		}));
	};
	inGainLabel = StaticText(~wInOut, Rect(265, 13, 15, 16))
	.background_(Color.white.alpha_(0.7))
	.font_(fontSmall)
	.align_(\center)
	.string_("dB");

	mainOutLabel = StaticText(~wInOut, Rect(20, 42, 50, 16))
	.font_(fontLabel)
	.background_(Color.white.alpha_(0.7))
	.string_(" Output ");

	mainOutChan = SmoothButton(~wInOut, Rect(85,40,45,20))
	.border_(1)
	.radius_(3)
	.canFocus_(false)
	.font_(fontButton)
	.states_([[
		if(~aBus.outMainStereo == 1,
			{~aBus.outMainChan.asString ++ "," ++ (~aBus.outMainChan+1).asString},
			{~aBus.outMainChan.asString})
	]]);

	outMainAttVal = (SmoothNumberBox(~wInOut, Rect(140, 39, 30, 22))
		.border_(1)
		.radius_(3)
		.background_(Color.white)
		.font_(fontButton)
		.value_(~aBus.outMainAtt.ampdb.round(0.1))
		.clipHi_(18.00)
		.clipLo_(-18.00)
		// .canFocus_(false)
		.scroll_step_(1)
		.align_(\center)
		.step_(0.1)
		.action_({
			~aBus.outMainAtt = outMainAttVal.value.dbamp;
			("Main Att:" + ~aBus.outMainAtt).postln;
			~aBus.outMainsynth.set(\mainAtt,~aBus.outMainAtt);
	}));

	outMainAttLabel = StaticText(~wInOut, Rect(175, 43, 15, 16))
	.background_(Color.white.alpha_(0.7))
	.font_(fontSmall)
	.align_(\center)
	.string_("dB");

	if(~aBus.outMonitor == 1, {
		monOutLabel = StaticText(~wInOut, Rect(20, 72, 50, 16))
		.font_(fontLabel)
		.background_(Color.white.alpha_(0.7))
		.string_(" Monitor ");

		monOutChan = SmoothButton(~wInOut, Rect(85,70,45,20))
		.border_(1)
		.radius_(3)
		.canFocus_(false)
		.font_(fontButton)
		.states_([[
			if(~aBus.outMonitorStereo == 1,
				{~aBus.outMonitorChan.asString ++ "," ++ (~aBus.outMonitorChan+1).asString},
				{~aBus.outMonitorChan.asString});
		]]);

		outMonitorAttVal = SmoothNumberBox(~wInOut, Rect(140, 69, 30, 22))
		.border_(1)
		.radius_(3)
		.background_(Color.white)
		.font_(fontButton)
		.value_(~aBus.outMonitorAtt.ampdb.round(0.1))
		.clipHi_(18)
		.clipLo_(-18)
		// .canFocus_(false)
		.scroll_step_(1)
		.align_(\center)
		.step_(0.1)
		.action_({
			~aBus.outMonitorAtt = outMonitorAttVal.value.dbamp;
			("Monitor Att:" + ~aBus.outMonitorAtt).postln;
			~aBus.outMainsynth.set(\monAtt,~aBus.outMonitorAtt);
		});

		outMonitorAttLabel = StaticText(~wInOut, Rect(175, 73, 15, 16))
		.background_(Color.white.alpha_(0.7))
		.font_(fontSmall)
		.align_(\center)
		.string_("dB");
	});

	~wInOut.view.keyDownAction_({
		arg view, char, modifiers, unicode, keycode;
		// [modifiers,keycode].postln;
		// Esc stops sound output
		if((keycode == 53), {cfg.localAddr.sendMsg("/panic");});
		// i changes background image and posts project info
		if((keycode ==34), {
			fSetImage.value();
			fProjectInfo.value();
			// start system preferences display
			if(~wSystem.notNil, {~wSystem.close});
			{(cfg.docDir++"System.scd").load()}.defer(0.1);
		});
		// N posts Node info
		if((keycode ==45), {s.queryAllNodes();});
		// M starts s.meter
		if((keycode ==46) && (~wMeterAvail.isNil), { fServerMeter.() });
		// O starts OSC monitor
		if(keycode ==31, {
			if(oscOn == 0,
				{thisProcess.oscInMonitor(true, addr:1, excl: ['/hid/ex3d','/InBus']); "OSC monitor is ON.".postln;},
				{thisProcess.oscInMonitor(false); "OSC monitor is OFF.".postln;});
			oscOn = (oscOn+1)%2;
		});
		if(keycode==15 && modifiers.isAlt, {
			if(isRecording==0, {
				s.record(thisProcess.platform.recordingsDir++"/Lapis_"++Date.getDate.format("%y%m%d_%H%M%S")++".aif");
				isRecording = 1;
				"Recording started".postln;
			}, {
				s.stopRecording;
				isRecording = 0;
				"Recording stopped".postln;
			});
		});
	});

	// give SC some time to breathe
	s.sync;

	// load controllers, livesampler and synthkeys
	if(~wControllersAvail.isNil, {"Controllers.scd".loadRelative});
	if(~lisa.notNil, {~lisa.loadRelative()});
	if(~sk.notNil, {~sk.loadRelative()});
	// w = Window("dummy").front; w.close;
	~wInOut.front;
	if(~alwaysOnTop == 1, {~wInOut.alwaysOnTop_(true)});

	// initialize output
	fInitOutput.value(1);

	// image
	fSetImage.value();

	// postln project information
	fProjectInfo.value();

	// collect garbage
	~wInOut.onClose_({
		if(isRecording==1, {
			s.stopRecording;
			isRecording = 0;
			"Recording stopped".postln;
		});
		fInitOutput.value(0, onClose:1);
		OSCdef(\inoutArdAna).free; OSCdef(\inoutEx3d).free;
		OSCdef(\inoutCC).free; OSCdef(\inoutNON).free; OSCdef(\inoutNOF).free;
		OSCdef(\inoutPanic).free; OSCdef(\inoutRefreshImage).free;
		~processBuf.free;
		if(~wControllersAvail.notNil, {~wControllers.close});
		if(~wLiveSamplerAvail.notNil, {~wLiveSampler.close});
		if(~wSynthKeysAvail.notNil, {~wSynthKeys.close});
		if(~wMeterAvail.notNil, {~wMeter.close});
		if(~wSystem.notNil, {~wSystem.close});
		~wInOutAvail = nil;
	});

	// start system preferences display
	"System.scd".loadRelative();

	// start CueMix, Activity Monitor, s.meter
	if(cfg.startCueMix == 1, {"osascript -e 'tell application \"CueMix FX\" to activate'".unixCmd;});
	if(cfg.startActMon == 1, {"osascript -e 'tell application \"Activity Monitor\" to activate'".unixCmd;});
	if(cfg.startMOTUSetup == 1, {"osascript -e 'tell application \"MOTU Audio Setup\" to activate'".unixCmd;});
	if( (cfg.startMeter == 1) || (~aBus.inputPeakChans > 0), { fServerMeter.() });
	if(~projectNotes.at(~projectID).notNil, { "open".postln; (cfg.docDir++cfg.libDir++~projectNotes.at(~projectID)).openOS });

}); // wait for boot

)

