// Eurapco sample list
// a=LV1 b=LV2 c=LX (blue/green)

a = (
	// LV1
	2: ["Eurapco/Coen-collage.wav"],
	10: ["dr_AmbIntrigue2+Light1b.aif"], // ------------ BOW
	18: ["GDRVH/BoC2 A97-1.aif", "melodic/mel tokyo01b.wav"], // ------------ EYE
	26: ["amawaveseq2detune.aiff"], // ------------ ANCHOR SCREW
	34: ["MOROS/08-proc3-proc1-13-proc1-proc1.wav"],
	42: ["mortrob1.wav"], // ------------ SNAP
	50: ["plankje4SN1-Thonk Hectic_a.aiff"], // ------------ PIN
	58: ["lh-snare1-16bit.aif", "lh-snare4-16bit.aif", "lh-snare3-16bit-pt2.aif"] // ------------ SHACKLE SNAP
);

b = (
	// LV2
	2: ["studio1_02.aif"], // ------------ CLIP
	10: ["lh-gaffertape1-16bit.aif", "lh-snare3-16bit-pt1.aif"], // ------------ CLIP PIN
	18: ["GDRVH/015 ARP25 SF lome beat part 1.aif"], // ------------ SHACKLE
	26: ["aphextwin/10 partial gen [switched outputs with FM from 1osc] afx1.wav","aphextwin/MODULART3 [schmoo pulse].wav","aphextwin/nqz9 chaos rave. 1st edit +6.wav"], // ------------ BOLT
	// 26: ["rain1filter1.aiff", "rain1.aiff"], // ------------ BOLT
	34: ["trapper2part2.aif", "trapper6part2.aif"], // ------------ PIN
	42: ["MOROS//11-proc1-proc1.aif"],
	50: ["MOROS/07-proc1-proc1.aif"], // ------------ BOW EYE
	58: ["sines/s3 long01part.aiff", "sines/s3 long04 soft no pitch voices.aif"] // ------------ BOW
);

c = (
	// LX blue
	24: ["MDFreeze/mdfreeze1.aif","MDFreeze/mdfreeze3.aif"],
	25: ["silent/ampmod lowmid mel1+2.wav"],
	26: ["solo/so 1m guitar2a spoffset.aiff"],
	27: ["solo2/so 1m ampmod5.1-melzing1rev-rev.aif"],
	28: ["GDRVH/Mix C006 - 1 - part1ed.aif"],
	29: ["Eurapco/Lilja Collage.wav"],
	30: ["GDRVH/drone A96-1 BOC3-part.aif"],
	31: ["VR/vr 003.3.8part.aiff","VR/vr 010.4part.aiff"],
	32: ["VR/vr 002.8.aiff"],
	33: ["VR/vr 015.8.aiff"],
	34: ["silent/ampmod vlow1m.aiff"],
	35: ["e1-5ringA2.aif","e1-5ringA2.aif"],

	// LX blue keyset 2
	36: ["voice/v marlowe.aif", "voice/v marlowe2.aif", "voice/v marlowe4a part.aif"],
	37: ["v apache gun kill.aiff"],
	38: ["aphextwin/@FX-MATRIXT7b.wav", "voice/v voicemail300404.aif"],
	39: ["sci-fi/alien talk decimate.wav"],
	40: ["prince/this is not a dream 1.wav","prince/this is not a dream 1.wav","Alien/moving on second.wav","Alien/moving on second.wav"],
	41: ["sci-fi/countdown decimate.wav", "sci-fi/alien talk 2 decimate.wav" ],
	42: ["voice/v officeR talk1.aiff", "voice/v officeR talk2 mach3.aiff"],
	43: ["voice/v videodr deb.aiff"],
	44: ["SCrecDelay1.aif"], // ------------ ANCHOR
	45: ["voice/v alien4 where the meat is.aiff"],
	46: ["musicismath/nfbc Another Side of the Forest1.wav","musicismath/nfbc Another Side of the Forest2.wav"],
	47: ["deli/delicatessen4voice.aif","deli/delicatessen4voice.aif"],
	// 39: ["voice/v terry golftees.aiff", "voice/v terry cheerleader.aiff"],
	// 40: ["v dimensionx-1.aiff"],
	// 41: ["voice/v feldman july67 02.aiff"],
	// 46: ["voice/v escape05"],

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
	60: ["MOROS/03-proc1-proc3.aif"], // ------------ BOLT
	61: ["env firecrackle1.aiff", "glas&lepel10a.aiff"], // ------------ BOLT
	62: ["ferr tendus1.aiff"], // ------------ SCREW
	63: ["LPcracklebuf.wav"], // ------------ THIMBLE
	64: ["drink/dr karperlop2.aif", "solitude/sol kraakpart"], // ------------ SHACKLE
	65: ["morten/morten perc1.wav", "morten/morten perc3.wav", "morten/morten perc4.wav"], // ------------ SNAP
	66: ["voer/deadscsi.aiff ts10 stereo.aiff", "th chsession2mo-Dis.aiff"], // ------------ LIMIT
	67: ["GDRVH/011 ARP25 Sy-Dis2 part1.aif"], // ------------ BOLT
	68: ["MOROS/15-proc3-proc1.aif"], // ------------ FORGE
	69: ["gitaarruis.wav", "dm/dm2 ula tape.wav", "dm/dm2 ula tape.wav"], // ------------ CUFF
	70: ["MOROS/11-proc3-proc1.aif"],
	71: ["plankje3SN1.aiff"]
);

d = ( // LX green keyset 2 -- settings for justPlay synth
	sampleList:
		[
		"Eurapco/Loops/bigcity-loop.wav",
		"Eurapco/Loops/bigcity-refrein.wav",
		"Eurapco/Loops/strings1-nostrings.wav",
		"Eurapco/Loops/strings2-strings.wav",
		"Eurapco/Loops/lunation-full.wav",
		"Eurapco/Loops/mellow-full.wav",

		"Eurapco/Loops/nowhere-full.wav",
		"Eurapco/Loops/interlude-loop.wav",
		"Eurapco/Loops/interlude-full.wav",
		"Eurapco/Loops/pony1.wav",
		"Eurapco/Loops/pony2.wav",
		"Eurapco/Loops/pony3.wav",

		"Eurapco/Loops/loving-full.wav",
		"Eurapco/Loops/people-loop.wav",
		"Eurapco/Loops/kick-long-loop.wav",
		"Eurapco/Loops/party-full.wav",
		"Eurapco/Loops/yeah-full.wav",
		"Eurapco/Loops/flux-full.wav",

		"box/Ni-Ten-Ichi-Ryu-33rpm-1-60.wav",
		"box/Ni-Ten-Ichi-Ryu-33rpm-2-60.wav",
		"box/Ni-Ten-Ichi-Ryu-33rpm-3-60.wav",
		"box/The Hidden Camera-33rpm-1-90.wav",
		"box/The Hidden Camera-33rpm-2-90.wav",

		],
	att: [],
	rel: 0.1.dup(24),
	lp: 1.dup(24),
	lpfOn: 1.dup(24),
	rate: 1.dup(6)++[1,1,1,33/45,33/45,33/45]++1.dup(12)
	);

e = ( // sample arrays for SynthKeys
	back:
		[
		"SynthKeys/rommel1.aiff",
		"SynthKeys/tone2.aiff",
		"SynthKeys/SauerThickChord.wav",
		"SynthKeys/anne-rrr+2.aiff",
		"SynthKeys/Anne-multiph1.aiff",
		"SynthKeys/annesing.aif"
		],
	left:
		[
		"SynthKeys/Coen-4b.aif",
		"SynthKeys/Coen-8.aif",
		"SynthKeys/Coen-9.aif",
		"SynthKeys/Coen-10.aif",
		"SynthKeys/Coen-11.aif"
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
