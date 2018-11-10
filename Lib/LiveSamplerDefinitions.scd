(
// specs
~specLS = (
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
	mtfDecay: Env.new([0,0,1,1], [0.55,0.35,0.1], [\lin]),
	mtfSweep: Env.new([0, 0.5], [1], [\lin]),
	mtfMix: Env.new([0,0,1,1], [0.25,0.25,0.5], [\lin]), // mix FreeVerb
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
	dist21: ControlSpec.new(1,~cfgLS.distortionMax,\exp),
	dist21hf: ControlSpec.new(1,~cfgLS.distortionMax,\exp),
	dist21lf: ControlSpec.new(2,~cfgLS.distortionMax,\exp),
	pitch21: ControlSpec.new(0.8,1.2,\lin),
	len21L: Env.xyc([[0, 0.1 * ~sRate,\exp],[0.5, 30 * ~sRate, \lin],[1, 60 * ~sRate]]), // van 0.1 naar 60 sec
	len21R: Env.xyc([[0, 0.1 * ~sRate,\exp],[0.5, 29.8 * ~sRate, \lin],[1, 59.6 * ~sRate]]), // van 0.1 naar 59.6 sec
	startPos21L: ControlSpec.new(
		~bufferLS.aStart,
		~bufferLS.aStart + ~bufferLS.aLen + ~bufferLS.bLen - ~bufferLS.bTail,
		\lin
	),
	startPos21R: ControlSpec.new(
		~bufferLS.aStart,
		~bufferLS.aStart + ~bufferLS.aLen + ~bufferLS.bLen - ~bufferLS.bTail - (0.3*~sRate),
		\lin
	),
	ff21: ControlSpec.new(50,20000,\exp),
	mix21: Env.new([0,0,1,1,0,0],[0.1,0.05,0.7,0.05,0.1],[\lin]),
	mix21lf: Env.new([1,1,0,0],[0.65,0.05,0.3],[\lin]),
	mix21hf: Env.new([0,0,1,1],[0.3,0.05,0.65],[\lin]),
	spModSpd31: Env.new([0.02,10],[127],[\exp]),
	panSpd31: ControlSpec.new(1,50,\lin),
	ampModSpd31: ControlSpec.new(1,0.01,\exp),
	len31: Env.xyc([[0, 0.1 * ~sRate,\exp],[0.5, 30 * ~sRate, \lin],[1, 60 * ~sRate]]), // van 0.1 naar 60 sec
	ff31: Env.new([10,1000,10000,15000],[0.3,0.5,0.2],[\exp,\lin,\exp]),
	mulHPF31: Env.new([1,1,20,50],[0.3,0.5,0.2],[\lin, \lin, \lin]),
	pitch41: ControlSpec.new(0.8,1.2,\lin),
	pitch412: ControlSpec.new(0.1,1.9,\lin),
	ffSpeed41: ControlSpec.new(0.2,2,\lin),
	len41: Env.xyc([[0, 0.2,\exp],[64, 30, \lin],[127, 60]]), // van 0.1 naar 60 sec
	ff41: ControlSpec.new(200,20000,\exp),
	len61: ControlSpec.new(10, 0.03,\exp), // van 10 sec naar 0,03 sec
	startPos61: ControlSpec.new(
		~bufferLS.bStart,
		~bufferLS.bStart + ~bufferLS.bLen - ~bufferLS.bTail,
		\lin,
		0.02 * (~bufferLS.bLen - ~bufferLS.bTail)
	),
	pitch61: Env.new([0.1,12],[1],[\exp]),
	// pitch61: ControlSpec.new(0.1,12,\exp),
	dist61: Env.new([~cfgLS.distortionMax,1],[1], [\exp]),
	// dist61: ControlSpec.new(~cfgLS.distortionMax,1,\exp),
	amp61: ControlSpec.new(0.0,1.0,\lin),
	len61Plus1: ControlSpec.new(2, 0.025,\exp), // van 2 sec naar 0,025 sec
	startPos61Plus1: ControlSpec.new(
		~bufferLS.bStart + (2 * ~sRate),
		~bufferLS.bStart + ~bufferLS.bLen - ~bufferLS.bTail + (2 * ~sRate),
		\lin,
		0.02 * (~bufferLS.bLen - ~bufferLS.bTail + (2 * ~sRate))
	),
	len61Plus2: ControlSpec.new(6, 0.02,\exp), // van 6 sec naar 0,02 sec
	startPos61Plus2: ControlSpec.new(
		~bufferLS.bStart + (4 * ~sRate),
		~bufferLS.bStart + ~bufferLS.bLen - ~bufferLS.bTail + (4 * ~sRate),
		\lin,
		0.02 * (~bufferLS.bLen - ~bufferLS.bTail + (4 * ~sRate))
	),
	len62: ControlSpec.new(1, 0.01,\exp), // van 10 sec naar 0,01 sec
	startPos62: ControlSpec.new(
		~bufferLS.bStart,
		~bufferLS.bStart + ~bufferLS.bLen - ~bufferLS.bTail,
		\lin,
		0.01 * (~bufferLS.bLen - ~bufferLS.bTail)
	),
	ff62: ControlSpec.new(50,5000,\exp),
	pan62: [-1,1,-1,1,-1,1,-1,1,-1].resize(1024, \linear),
	len63: ControlSpec.new(2, 0.015, \exp), // van 2 sec naar 0,02 sec
	startPos63: ControlSpec.new(
		~bufferLS.bStart,
		~bufferLS.bStart + ~bufferLS.bLen - ~bufferLS.bTail,
		\lin,
		0.01 * (~bufferLS.bLen - ~bufferLS.bTail)
	),
	ff63: ControlSpec.new(50,20000,\exp),
	pan63: [1,-1,1].resize(1024, \linear),
	len64: Env.new([2,1,0.005],[0.5,0.5],[\lin,\exp]), // van 2 sec naar 0,005 sec
	startPos64: ControlSpec.new(
		~bufferLS.aStart,
		~bufferLS.aStart + ~bufferLS.aLen - ~bufferLS.aTail,
		\lin,
		0.01 * (~bufferLS.bLen - ~bufferLS.bTail)
	),
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
	distFftDrone: Env.new([15,1],[1]),
	cutoffFftDrone: Env.new([10000,3000,500],[0.5,0.5],[\lin]),
	pulseFftDrone: Env.new([1,0.3,1],[0.5,0.5]),
	amp21: Env.xyc([[0.0, 0.0, \lin], [0.001, 0.001,\exp],[0.2, 0.2, \lin],[1, 1.0]]),
	amp81: Env.new([0,0.001,0.2,0.7],[0.001, 0.2, 0.8],[\lin,\exp,\lin]),
	len81: Env.xyc([[0, 0.1 * ~sRate,\exp],[0.5, 30 * ~sRate, \lin],[1, 60 * ~sRate]]), // van 0.1 naar 60 sec
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
	startPos171: ControlSpec.new(
		~bufferLS.aStart,
		~bufferLS.bStart + ~bufferLS.bLen - ~bufferLS.bTail,
		\lin,
		0.01 * (~bufferLS.bStart + ~bufferLS.bLen - ~bufferLS.bTail)
	),
	amp171: ControlSpec.new(0, 1, \lin),
	dist171: ControlSpec.new(1, 10, \lin),
	tempo171: ControlSpec.new(1,8),
	diskPlayRate: Env.new([33/45,1],[1],[\lin]),
	diskPlayRateMod: Env.new([0,0.05],[1],[\lin]),
	dist181: Env.new([1,10],[1]),
	speed181: Env.new([0.25, 0.25, 0.5, 1, 2], 0.25, \step),
	cutoff182: Env.new([50,600],[1]),
	dist182: Env.new([1,10],[1]),
	feedback182: Env.new([0.0, 0.0, 0.5],[0.5, 0.5]),
	mix182: Env.new([0.0, 0.0, 1],[0.3, 0.7]),
	speed182: Env.new([1, 1, 2, 5, 6], 0.25, \step)
);

// control busses
~cBusLS = (
	// joystick
	ex3dProBusX62: Bus.control(s,1).set(0), ex3dProBusX63: Bus.control(s,1).set(0), ex3dProBusX64: Bus.control(s,1).set(0),
	ex3dProBusX65: Bus.control(s,1).set(0), ex3dProBusX66: Bus.control(s,1).set(0), ex3dProBusX67: Bus.control(s,1).set(0.5),
	ex3dProY: Bus.control(s,1).set(0.5), ex3dProYpitch: Bus.control(s,1).set(~specLS.pitch61.at(0.5)),
	ex3dProR: Bus.control(s,1).set(0.5), ex3dProS: Bus.control(s,1).set(1),
	// Faderfox LV1, LV2
	midiLV1Fader1: Bus.control(s,1).set(0), midiLV1Fader2: Bus.control(s,1).set(0), midiLV1Fader3: Bus.control(s,1).set(0),
	midiLV1Fader4: Bus.control(s,1).set(0), midiLV1Fader5: Bus.control(s,1).set(0), midiLV1Fader8: Bus.control(s,1).set(0),
	midiLV1Fader12: Bus.control(s,1).set(0), midiLV1Fader13: Bus.control(s,1).set(0.5),
	midiLV1Fader14: Bus.control(s,1).set(0), midiLV1Fader15: Bus.control(s,1).set(0.5),
	midiLV1KnobA1: Bus.control(s,1).set(0.5), midiLV1KnobA2: Bus.control(s,1).set(0.5), midiLV1KnobB1: Bus.control(s,1).set(0.5),
	midiLV1KnobB2: Bus.control(s,1).set(0.7), midiLV1KnobB3: Bus.control(s,1).set(0.7), midiLV1KnobC1: Bus.control(s,1).set(0.5),
	midiLV1KnobC2: Bus.control(s,1).set(0),
	midiLV1KnobD1: Bus.control(s,1).set(0.5), midiLV1KnobD2: Bus.control(s,1).set(0),
	midiLV1JoyX: Bus.control(s,1).set(0), midiLV1JoyY: Bus.control(s,1).set(0.5), midiLV1CrossFader: Bus.control(s,1).set(0),
	midiLV1KnobMasterVol: Bus.control(s,1).set(1),
	midiLV2Fader1: Bus.control(s,1).set(0), midiLV2Fader3: Bus.control(s,1).set(0), midiLV2Fader4: Bus.control(s,1).set(0),
	midiLV2Fader5: Bus.control(s,1).set(0), midiLV2Fader6: Bus.control(s,1).set(0), midiLV2Fader7: Bus.control(s,1).set(0),
	midiLV2Fader8: Bus.control(s,1).set(0), midiLV2Fader9: Bus.control(s,1).set(0), midiLV2Fader10: Bus.control(s,1).set(0),
	midiLV2Fader11: Bus.control(s,1).set(0), midiLV2Fader12: Bus.control(s,1).set(0), midiLV2Fader13: Bus.control(s,1).set(0),
	midiLV2Fader14: Bus.control(s,1).set(1),
	midiLV2Fader15: Bus.control(s,1).set(1), midiLV2Fader16: Bus.control(s,1).set(0.7),
	midiLV2KnobA1: Bus.control(s,1).set(~specLS.len41.at(64)), midiLV2KnobA2: Bus.control(s,1).set(0.5),
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
	lenBus161: Bus.control(s,1).set(~bufferLS.dyn1Len / ~sRate), lenBus162: Bus.control(s,1).set(~bufferLS.dyn2Len / ~sRate),
	lenBus163: Bus.control(s,1).set(~bufferLS.dyn3Len / ~sRate), lenBus164: Bus.control(s,1).set(~bufferLS.dyn4Len / ~sRate),
	// pulseVolBus: Bus.control(s,1).set(0), pulseSpeedBus: Bus.control(s,1).set(0), pulseWidthBus: Bus.control(s,1).set(0)
);
)