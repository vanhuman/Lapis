// Crack sample list
// a=LV1 b=LV2 c=LX (blue/green)

a = (
	// LV1
	2: ["stoel2-Dis_b.aiff"], // ------------ LIMIT
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
	26: ["rain1filter1.aiff", "rain1.aiff"], // ------------ BOLT
	34: ["trapper2part2.aif", "trapper6part2.aif"], // ------------ PIN
	42: ["MOROS//11-proc1-proc1.aif"],
	50: ["MOROS/07-proc1-proc1.aif"], // ------------ BOW EYE
	58: ["sines/s3 long01part.aiff", "sines/s3 long04 soft no pitch voices.aif"] // ------------ BOW
);

c = (
	// LX blue
	24: ["crack/sub1.wav"],
	25: ["crack/sub2.wav"],
	26: ["crack/sub3.wav","crack/sub3.wav","crack/sub3.wav"],
	27: ["crack/proc1.wav"],
	28: ["crack/proc4.wav"],
	// 24: ["MOROS/15-proc3-proc3.aif"],
	// 25: ["moros-beat1.aiff"],
	// 26: ["speeldooscol.aif", "distorted/d mortB01.wav", "speeldoosTSFFT.aif"], // ------------ THIMBLE
	// 27: ["glas&lepel10VRSP2+.aiff"], // ------------ PIN
	// 28: ["melodic/mel 310-melodie-low"], // ------------ RIG
	29: ["v belief ralph&heather.aiff"], // ------------ CHOICE
	30: ["melodic/MDfreeze/theme_03_shortb.wav"],
	31: ["station1 rbeq2", "MOROS/10-proc1-proc2.wav" , "solitude/sol verwketel1EQ2part"], // ------------ SHACKLE
	32: ["GDRVH/004 ARP25 noise part1.aif"], // ------------ CUFF
	33: ["plankje2SN1m-Slack_a.aiff"], // ------------ CLIP
	34: ["silent/ampmod vlow1m.aiff"], // ------------ ANCHOR BOW CUFF SHACKLE
	35: ["MOROS/01-proc1-proc3.aif"], // ------------ BOLT

	// LX blue keyset 2
	36: ["voice/v marlowe.aif", "voice/v marlowe2.aif", "voice/v marlowe4a part.aif"],
	37: ["v apache gun kill.aiff"],
	38: ["voice/v voicemail300404.aif", "v voicemail 6aa3a340.aif"],
	39: ["voice/v terry golftees.aiff", "voice/v terry cheerleader.aiff"],
	40: ["v dimensionx-1.aiff"],
	41: ["voice/v feldman july67 02.aiff"],
	42: ["voice/v officeR talk1.aiff", "voice/v officeR talk2 mach3.aiff"],
	43: ["voice/v videodr deb.aiff"],
	44: ["SCrecDelay1.aif"], // ------------ ANCHOR
	45: ["voice/v alien4 where the meat is.aiff"],
	46: ["voice/v escape05"],
	47: ["deli/delicatessen4voice.aif","deli/delicatessen4voice.aif"],

	// LX green
	60: ["crack/sub1.wav"],
	61: ["crack/sub2.wav"],
	62: ["crack/sub3.wav","crack/sub3.wav","crack/sub3.wav"],
	63: ["crack/proc1.wav"],
	64: ["crack/proc4.wav"],
	// 60: ["MOROS/03-proc1-proc3.aif"], // ------------ BOLT
	// 61: ["env firecrackle1.aiff", "glas&lepel10a.aiff"], // ------------ BOLT
	// 62: ["ferr tendus1.aiff"], // ------------ SCREW
	// 63: ["LPcracklebuf.wav"], // ------------ THIMBLE
	// 64: ["drink/dr karperlop2.aif", "solitude/sol kraakpart"], // ------------ SHACKLE
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
		"MOROS/green2/01-proc1-proc3-a.aif",
		"MOROS/green2/11-proc1-a.aif",
		"MOROS/green2/12-proc1-proc3-a.aif",
		"MOROS/green2/12-proc3-proc1-proc1-a.aif",
		"MOROS/green2/14-proc3-proc3-a.aif",
		"MOROS/green2/18-proc2-a.aif",
		"box/Ni-Ten-Ichi-Ryu-33rpm-1-60.wav",
		"box/Ni-Ten-Ichi-Ryu-33rpm-2-60.wav",
		"box/Ni-Ten-Ichi-Ryu-33rpm-3-60.wav",
		"box/Polka Trax 2-1-120.wav",
		"box/The Hidden Camera-33rpm-1-90.wav",
		"box/The Hidden Camera-33rpm-2-90.wav"
		],
	att: [],
	rel: [1,1,1,1,1,1,1,1,1,1,1,1],
	out: []
	);

e = ( // sample arrays for SynthKeys
	back:
		[
		"SynthKeys/Crack/sk2.wav",
		"SynthKeys/Crack/proc1sk.wav",
		"SynthKeys/Crack/proc4sk.wav",
		"SynthKeys/Crack/sub1sk.wav"
		],
	left:
		[
		"SynthKeys/bass1.wav",
		"SynthKeys/bass1+12.wav",
		"SynthKeys/rommel1.aiff",
		"SynthKeys/Albert1.aiff",
		"SynthKeys/cbcl2.aiff",
		"SynthKeys/cbcl3.aiff"
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
