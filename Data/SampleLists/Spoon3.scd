// Spoon3 sample list
// a=LV1 b=LV2 c=LX (blue/green)

a = (
	// LV1
	2: ["stoel2-Dis_b.aiff"],
	10: ["dr_AmbIntrigue2+Light1b.aif"],	// -- Where is everyone
	18: ["GDRVH/BoC2 A97-1.aif", "sines/sc sines3.aif"],
	26: ["GDRVH/002 ARP25 noise Synton filter part1.aif"], 	// --- Rara Avis
	34: ["bl droger1part.aiff", "solitude/sol beaub01EQ1part", "solitude/sol beaubbad01bpart"],
	42: ["morten/morten perc4", "morten/morten perc3"], // --- Business Suit --- Jumped
	50: ["plankje4SN1-Thonk Hectic_a.aiff"], 	// -- Jumped
	58: ["lh-snare1-16bit.aif", "lh-snare4-16bit.aif", "lh-snare3-16bit-pt2.aif"]
);

b = (
	// LV2
	2: ["nate03.aif"],	// --- Distance
	10: ["silent/ampmod highcnst1.aiff"],
	18: ["GDRVH/015 ARP25 SF lome beat part 1.aif"],
	26: ["rain1filter1.aiff", "rain1.aiff"],	// --- Distance
	34: ["trapper2part2.aif", "trapper6part2.aif"],
	42: ["deli/delicatessen1.aif"],
	50: ["silent/ampmod high1part2.aiff"],
	58: ["sines/s3 long01part.aiff", "sines/s3 long04 soft no pitch voices.aif"] 	// --- Kingdom
);

c = (
	// LX blue
	24: ["deli/delicatessen3.aif"],
	25: ["expired/08-proc3-proc3-proc1.aif"],	// --- 80 Miles
	26: ["speeldooscol.aif", "distorted/d mortB01", "speeldoosTSFFT.aif"],
	27: ["glas&lepel10VRSP2+.aiff"], 	// --- Time
	28: ["horns sine1.aif"], 	// --- Kingdom --- Ants
	29: ["expired/09-proc1-proc1-proc1.aif"],	// --- 80 Miles
	30: ["expired/09-proc1-proc3-proc1.aif"],	// --- 80 Miles
	31: ["station1 rbeq2", "01part3FFTFWBW.aif", "midi data overflowb.aiff", "solitude/sol verwketel1EQ2part"],
	32: ["GDRVH/004 ARP25 noise part1.aif"],
	33: ["plankje2SN1m-Slack_a.aiff"],	// -- Jumped
	34: ["silent/ampmod vlow1m.aiff"],
	35: ["VR/vr 013.4part.aiff", "VR/vr 011.5.4part.aiff"],

	// LX blue keyset 2
	// 36: ["jodi Whisp.aif"],
	// 37: ["jo box part2.aiff"],
	// 38: ["jo roses part1.aiff"],
	// 39: ["jo box part1 muffled.aiff","jo box part1.aiff" ],
	36: ["ZAAG55/Aambeeld1.wav"],
	37: ["ZAAG55/Afkortzaag1.wav"],
	38: ["ZAAG55/Afkortzaag6.wav"],
	39: ["ZAAG55/Boor3.wav"],
	40: ["ZAAG55/Boor4.wav"],
	41: ["ZAAG55/Bovenloopkraan2.wav"],
	42: ["ZAAG55/Kettingtakel1.wav"],
	43: ["ZAAG55/Kettingtakel4.wav"],
	44: ["ZAAG55/Lassen1.wav"],
	45: ["ZAAG55/Schaar1.wav"],
	46: ["ZAAG55/Zetbank1.wav"],
	47: ["ZAAG55/Zetbank2.wav"],

	// LX green
	60: ["crackle1.aif", "buffuct02", "cnt02", "cnt01"],  	// --- Distance
	61: ["env firecrackle1.aiff", "glas&lepel10a.aiff"],	// --- Ants
	62: ["ferr tendus1.aiff"],
	63: ["LPcracklebuf"],	// -- Where is everyone
	64: ["drink/dr karperlop2.aif", "solitude/sol kraakpart"],	// --- Tasty Plum
	65: ["morten/morten perc1", "morten/morten perc3", "morten/morten perc4"],
	66: ["voer/deadscsi.aiff ts10 stereo.aiff", "th chsession2mo-Dis.aiff"],
	67: ["GDRVH/011 ARP25 Sy-Dis2 part1.aif"],
	68: ["sines/s 1000Hz krflange01+11"],
	69: ["gitaarruis", "dm/dm2 ula tape", "dm/dm2 ula tape"],
	70: ["env st davids tent1b.aiff", "placard_m/pl tou bekertje2-part1.aif"],	// --- Time
	71: ["GDRVH/002.3.4.2 part.aif"]	// --- Distance
);

d = ( // LX green keyset 2 -- settings for justPlay synth
	sampleList:
		[
		"Wulup 1.wav"
		],
	att: [1],
	rel: [1],
	out: [~aBus.outB]
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
		"SynthKeys/Albert1.aiff",
		"SynthKeys/cbcl2.aiff",
		"SynthKeys/cbcl3.aiff",
		"SynthKeys/chime1.wav",
		"SynthKeys/sol bells01-a.wav"
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
