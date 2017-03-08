// ABATTOIR sample list (based on Shackle.scd)
// a=LV1 b=LV2 c=LX (blue/green)

a = (
	// LV1
	2: ["stoel2-Dis_b.aiff"],
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
	2: ["studio1_02.aif"],
	10: ["lh-gaffertape1-16bit.aif", "lh-snare3-16bit-pt1.aif"],
	18: ["GDRVH/015 ARP25 SF lome beat part 1.aif"],
	26: ["rain1filter1.aiff", "rain1.aiff"],
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
	29: ["v belief ralph&heather.aiff"],
	30: ["melodic/MDfreeze/theme_03_shortb.wav"],
	31: ["station1 rbeq2", "MOROS/10-proc1-proc2.wav" , "solitude/sol verwketel1EQ2part"],
	32: ["GDRVH/004 ARP25 noise part1.aif"],
	33: ["plankje2SN1m-Slack_a.aiff"],
	34: ["silent/ampmod vlow1m.aiff"],
	35: ["MOROS/01-proc1-proc3.aif"],

	// LX blue keyset 2
	36: ["voice/v marlowe.aif", "voice/v marlowe2.aif", "voice/v marlowe4a part.aif"],
	37: ["v apache gun kill.aiff"],
	38: ["voice/v voicemail300404.aif", "v voicemail 6aa3a340.aif"],
	39: ["voice/v terry golftees.aiff", "voice/v terry cheerleader.aiff"],
	40: ["v dimensionx-1.aiff"],
	41: ["voice/v feldman july67 02.aiff"],
	42: ["voice/v officeR talk1.aiff", "voice/v officeR talk2 mach3.aiff"],
	43: ["voice/v videodr deb.aiff"],
	44: ["SCrecDelay1.aif"],
	45: ["voice/v alien4 where the meat is.aiff"],
	46: ["voice/v escape05"],
	47: ["deli/delicatessen4voice.aif","deli/delicatessen4voice.aif"],

	// LX blue keyset 3
	48: ["ZAAG55/Aambeeld1.wav"],
	49: ["ZAAG55/Afkortzaag1.wav"],
	50: ["ZAAG55/Afkortzaag6.wav"],
	51: ["ZAAG55/Boor3.wav"],
	52: ["ZAAG55/Boor4.wav"],
	53: ["ZAAG55/Bovenloopkraan2.wav"],
	54: ["ZAAG55/Kettingtakel1.wav"],
	55: ["ZAAG55/Kettingtakel4.wav"],
	56: ["ZAAG55/Lassen1.wav"],
	57: ["ZAAG55/Schaar1.wav"],
	58: ["ZAAG55/Zetbank1.wav"],
	59: ["ZAAG55/Zetbank2.wav"],

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
	);

e = ( // sample arrays for SynthKeys
	back:
		[
		"SynthKeys/anne-rrr+2.aiff",
		"SynthKeys/Anne-multiph1.aiff",
		"SynthKeys/annesing.aif"
		],
	left:
		[
		"SynthKeys/bass1.wav",
		"SynthKeys/bass1+12.wav",
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
