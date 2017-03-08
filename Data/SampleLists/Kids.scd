// KIds sample list
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
	24: ["Kids/36180__bansemer__deisel-locomotive-moving-engine-only-whistle-blast-once.wav"],
	25: ["/Kids/BoLo.wav"],
	26: ["Kids/94636__dobroide__20100403-brussels-ambulance.wav"],
	27: ["Kids/buurman/buurman1.wav"],
	28: ["Kids/Cars.aiff"],
	29: ["Kids/buurman/buurman oud1.aiff"],
	30: ["Kids/buurman/buurman oud5.aiff"],
	31: [],
	32: ["ZAAG55/Afkortzaag1.wav"],
	33: ["ZAAG55/Bovenloopkraan1.wav"],
	34: ["glas&lepel10VRSP2+.aiff"],
	35: ["plankje2SN1m-Slack_a.aiff"],

	// LX green
	60: ["Kids/122067__lonemonk__06-2011-freight-train-pass-2b.wav"],
	61: ["Kids/buurman/buurman oud3.aiff"],
	62: ["Kids/buurman/buurman2.aiff"],
	63: ["Kids/espresso2.aif"],
	64: [],
	65: ["ZAAG55/Afkortzaag4.wav"],
	66: ["morten/morten perc1.wav", "morten/morten perc3.wav", "morten/morten perc4.wav"],
	67: ["GDRVH/011 ARP25 Sy-Dis2 part1.aif"],
	68: ["MOROS/15-proc3-proc1.aif"],
	69: ["gitaarruis.wav", "dm/dm2 ula tape.wav", "dm/dm2 ula tape.wav"],
	70: ["MOROS/11-proc3-proc1.aif"],
	71: ["ferr tendus1.aiff"]
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
		"SynthKeys/anne-rrr+2.aiff",
		"SynthKeys/Anne-multiph1.aiff",
		"SynthKeys/annesing.aif"
		],
	left:
		[
		"SynthKeys/Kids/82077__benboncan__fly-1a.wav",
		"SynthKeys/Kids/14854__reinsamba__nightingale-song-a.wav",
		"SynthKeys/Kids/espresso2.aif"
		],
	right:
		[
		"SynthKeys/Kids/Stw ped v3 060.aif",
		"SynthKeys/Kids/VI_mV_sus_mp_C4.wav",
		"SynthKeys/Kids/BKL_pA_sus_f_C3.wav",
		"SynthKeys/Kids/Acc Pi Tango f n  4 d.aif",
		"SynthKeys/Kids/13 zacht.aif",
		"SynthKeys/Kids/mel violins1.aif",
		"SynthKeys/kistorgel10.aif"
		]
);

[a,b,c,d,e]
