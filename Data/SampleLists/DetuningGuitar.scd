// Detuning Guitar sample list
// a=LV1 b=LV2 c=LX (blue/green)

a = (
	// LV1
	2: ["Jasper/J steen2.aif"],
	10: ["dr_AmbIntrigue2+Light1b.aif"],
	18: ["GDRVH/BoC2 A97-1.aif", "melodic/mel tokyo01b.wav"],
	26: ["amawaveseq2detune.aiff"],
	34: ["MOROS/08-proc3-proc1-13-proc1-proc1.wav"],
	42: ["mortrob1.wav"],
	50: ["plankje4SN1-Thonk Hectic_a.aiff"],
	58: ["lh-snare1-16bit.aif", "lh-snare4-16bit.aif", "lh-snare3-16bit-pt2.aif"]
);

b = (
	// LV2
	2: ["Jasper/J rattle string.wav", "Jasper/J heavy friction1.wav"],
	10: ["lh-gaffertape1-16bit.aif", "lh-snare3-16bit-pt1.aif"],
	18: ["GDRVH/015 ARP25 SF lome beat part 1.aif"],
	26: ["aphextwin/10 partial gen [switched outputs with FM from 1osc] afx1.wav","aphextwin/MODULART3 [schmoo pulse].wav","aphextwin/nqz9 chaos rave. 1st edit +6.wav"],
	34: ["trapper2part2.aif", "trapper6part2.aif"],
	42: ["MOROS//11-proc1-proc1.aif"],
	50: ["MOROS/07-proc1-proc1.aif"],
	58: ["sines/s3 long01part.aiff", "sines/s3 long04 soft no pitch voices.aif"]
);

c = (
	// LX blue
	24: ["MOROS/15-proc3-proc3.aif"],
	25: ["moros-beat1.aiff"],
	26: ["speeldooscol.aif", "distorted/d mortB01.wav", "speeldoosTSFFT.aif"],
	27: ["glas&lepel10VRSP2+.aiff"],
	28: ["melodic/mel 310-melodie-low"],
	29: ["Jasper/J detuning low1.wav"],
	30: ["aphextwin/avril altdelay.wav", "melodic/MDfreeze/theme_03_shortb.wav"],
	31: ["station1 rbeq2", "MOROS/10-proc1-proc2.wav" , "solitude/sol verwketel1EQ2part"],
	32: ["Jasper/J stumbling.wav", "Jasper/J tonal plucking1.wav"],
	33: ["plankje2SN1m-Slack_a.aiff"],
	34: ["Jasper/J slide1.wav"],
	35: ["MOROS/01-proc1-proc3.aif"],

	// LX blue keyset 2
	36: ["voice/v marlowe.aif", "voice/v marlowe2.aif", "voice/v marlowe4a part.aif"],
	37: ["v apache gun kill.aiff"],
	38: ["aphextwin/@FX-MATRIXT7b.wav", "voice/v voicemail300404.aif"],
	39: ["musicismath/the past inside the present-dec-trem.wav","musicismath/the past inside the present-dec-trem2+3.wav","sci-fi/alien talk decimate.wav"],
	40: ["prince/this is not a dream 1.wav","prince/this is not a dream 1.wav","Alien/moving on second.wav","Alien/moving on second.wav"],
	41: ["sci-fi/countdown decimate.wav", "sci-fi/alien talk 2 decimate.wav" ],
	42: ["voice/v officeR talk1.aiff", "voice/v officeR talk2 mach3.aiff"],
	43: ["voice/v videodr deb.aiff"],
	44: ["SCrecDelay1.aif"],
	45: ["voice/v alien4 where the meat is.aiff"],
	46: ["voice/v escape05"],
	47: ["deli/delicatessen4voice.aif","deli/delicatessen4voice.aif"],

	// LX blue keyset 3
	48: ["Jasper/J steen2.aif"],
	49: ["Jasper/J rattle string.wav", "Jasper/J heavy friction1.wav"],
	50: ["Jasper/J detuning low1.wav"],
	51: ["Jasper/J stumbling.wav", "Jasper/J tonal plucking1.wav"],
	52: ["Jasper/J slide1.wav"],
	53: [],
	54: ["Jasper/J steen2.aif"], '54out': "B",
	55: ["Jasper/J rattle string.wav", "Jasper/J heavy friction1.wav"], '55out': "B",
	56: ["Jasper/J detuning low1.wav"], '56out': "B",
	57: ["Jasper/J stumbling.wav", "Jasper/J tonal plucking1.wav"], '57out': "B",
	58: ["Jasper/J slide1.wav"], '58out': "B",

	// LX green
	60: ["MOROS/03-proc1-proc3.aif"],
	61: ["env firecrackle1.aiff", "glas&lepel10a.aiff"],
	62: ["ferr tendus1.aiff"],
	63: ["LPcracklebuf.wav"],
	64: ["drink/dr karperlop2.aif", "solitude/sol kraakpart"],
	65: ["morten/morten perc1.wav", "morten/morten perc3.wav", "morten/morten perc4.wav"],
	66: ["voer/deadscsi.aiff ts10 stereo.aiff", "th chsession2mo-Dis.aiff"],
	67: ["GDRVH/011 ARP25 Sy-Dis2 part1.aif"],
	68: ["MOROS/15-proc3-proc1.aif"],
	69: ["gitaarruis.wav", "dm/dm2 ula tape.wav", "dm/dm2 ula tape.wav"],
	70: ["MOROS/11-proc3-proc1.aif"],
	71: ["plankje3SN1.aiff"]
);

d = ( // LX green keyset 2 -- settings for justPlay synth
	sampleList:
		[
		"prince/theme1.wav",
		"prince/theme4.wav",
		"MOROS/green2/12-proc1-proc3-a.aif",
		"MOROS/green2/12-proc3-proc1-proc1-a.aif",
		"MOROS/green2/14-proc3-proc3-a.aif",
		"MOROS/green2/18-proc2-a.aif",
		"Parish/scorn_st2.aif",
		"Parish/scorn_st3.aif",
		"Parish/scorn_st5.aif",
		"Parish/scorn_st6.aif",
		"box/Ni-Ten-Ichi-Ryu-33rpm-1-60.wav",
		"box/Ni-Ten-Ichi-Ryu-33rpm-2-60.wav",
	],
	att: [],
	rel: [1,1,1,1,1,1,1,1,1,1,1,1],
	);

e = ( // sample arrays for SynthKeys
	back:
		[
		"SynthKeys/GuitarFASGRO.aiff",
		"SynthKeys/rommel1.aiff",
		"SynthKeys/tone2.aiff",
		"SynthKeys/anne-rrr+2.aiff",
		"SynthKeys/Anne-multiph1.aiff",
		"SynthKeys/annesing.aif"
		],
	left:
		[
		"SynthKeys/J steen1a.wav",
		"SynthKeys/J rattle string1a.wav",
		"SynthKeys/J slide1a.wav"
		],
	right:
		[
		"SynthKeys/kistorgel10.aif",
		"SynthKeys/kistorgel13.aif",
		"SynthKeys/kistorgel9.aif",
		"SynthKeys/kistorgel8.aif",
		"SynthKeys/kistorgel11.aif",
		"SynthKeys/kistorgel1ps.aiff",
		"SynthKeys/kistorgel2ps.aiff",
		"SynthKeys/kistorgel4ps.aiff"
		]
);

[a,b,c,d,e]
