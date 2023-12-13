// Loop-Copy-Mutate sample list
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
	26: ["aphextwin/10 partial gen [switched outputs with FM from 1osc] afx1.wav","aphextwin/MODULART3 [schmoo pulse].wav","aphextwin/nqz9 chaos rave. 1st edit +6.wav"],
	34: ["trapper2part2.aif", "trapper6part2.aif"],
	42: ["MOROS//11-proc1-proc1.aif"],
	50: ["MOROS/07-proc1-proc1.aif"],
	58: ["sines/s3 long01part.aiff", "sines/s3 long04 soft no pitch voices.aif"]
);

c = (
	// LX blue
	24: ["LCMBlackEagles/piep.wav", "LCMBlackEagles/piep-pitchshifting.aiff"],
	25: ["LCMBlackEagles/bal.wav"],
	26: ["LCMBlackEagles/doelpunt.wav"],
	27: ["LCMBlackEagles/fluit.wav"],
	28: ["LCMBlackEagles/lekker-mix.aiff"],
	29: ["LCMBlackEagles/stem.wav"],
	30: ["LCMBlackEagles/vangen.wav", "LCMBlackEagles/vangen.wav", "LCMBlackEagles/vangen.wav", "LCMBlackEagles/vangen.wav"],
	31: [],
	32: [],
	33: [],
	34: [],
	35: [],

	// LX blue keyset 2
	36: ["voice/PlayerPianosR1_ed1.wav"],
	37: ["voice/tcp_d2_17_english_man_irdial.wav"],
	38: ["aphextwin/avril altdelay.wav", "melodic/MDfreeze/theme_03_shortb.wav"],
	39: ["station1 rbeq2", "MOROS/10-proc1-proc2.wav" , "solitude/sol verwketel1EQ2part"],
	40: ["GDRVH/004 ARP25 noise part1.aif"],
	41: ["sci-fi/countdown decimate.wav", "sci-fi/alien talk 2 decimate.wav" ],
	42: ["plankje2SN1m-Slack_a.aiff"],
	43: ["voice/v videodr deb.aiff"],
	44: ["SCrecDelay1.aif"],
	45: ["MOROS/01-proc1-proc3.aif"],
	46: ["musicismath/nfbc Another Side of the Forest1.wav","musicismath/nfbc Another Side of the Forest2.wav"],
	47: ["voice/tcp_d1_09_ready_ready_15728_irdial.wav","voice/tcp_d3_11_nnn_old_incarnation_irdial.wav"],

	// LX blue keyset 3
	48: ["Spill/1 strijken-p1-p6.aif"],
	49: ["Spill/2 strijken-p2-p6.aif"],
	50: ["Spill/3 strijken-p1-p5.aif"],
	51: ["Spill/3 strijken-p5-p5.aif"],
	52: ["ZAAG55/Bovenloopkraan2.wav"],
	53: ["ZAAG55/Kettingtakel4.wav"],

	54: ["Spill/3 strijken-p6-p6.aif"], '54out': "B",
	55: ["Spill/4 schoonmaken-p3-p6.aif"], '55out': "B",
	56: ["Spill/4 schoonmaken-p1-p5.aif"], '56out': "B",
	57: ["Spill/5 flageoletten-p6-p5.aif"], '57out': "B",
	58: ["ZAAG55/Afkortzaag1.wav"], '58out': "B",
	59: ["ZAAG55/Boor2.wav"], '59out': "B",

	// LX green
	60: ["LCMBlackEagles/piep.wav", "LCMBlackEagles/piep-pitchshifting.aiff"],
	61: ["LCMBlackEagles/bal.wav"],
	62: ["LCMBlackEagles/doelpunt.wav"],
	63: ["LCMBlackEagles/fluit.wav"],
	64: ["LCMBlackEagles/lekker-mix.aiff"],
	65: ["LCMBlackEagles/stem.wav"],
	66: ["LCMBlackEagles/vangen.wav", "LCMBlackEagles/vangen.wav", "LCMBlackEagles/vangen.wav", "LCMBlackEagles/vangen.wav"],

	67: ["GDRVH/011 ARP25 Sy-Dis2 part1.aif"],
	68: ["MOROS/15-proc3-proc1.aif"],
	69: ["gitaarruis.wav", "dm/dm2 ula tape.wav", "dm/dm2 ula tape.wav"],
	70: ["MOROS/11-proc3-proc1.aif"],
	71: ["plankje3SN1.aiff"]
);

d = ( // LX green keyset 2 & 3 -- settings for justPlay synth
	sampleList:
		[
		// green keyset 2
		// keep first 2 empty as they are handled by playing through Loop-Copy-Mutate/loadRecordings.scd
		"empty",
		"empty",
		"LCMBlackEagles/lcm_ball_mix_1.wav",
		"LCMBlackEagles/bal.wav",
		"LCMBlackEagles/doelpunt.wav",
		"LCMBlackEagles/stem.wav",

		"LCMBlackEagles/short/3 seconde.wav",
		"LCMBlackEagles/short/daar achter je.wav",
		"LCMBlackEagles/short/hande hoog.wav",
		"LCMBlackEagles/short/ik heb 5.wav",
		"LCMBlackEagles/short/lekker.wav",
		"LCMBlackEagles/short/rebound.wav",

		// green keyset 3
		"LCMBlackEagles/short/bal1.wav",
		"LCMBlackEagles/short/bal2.wav",
		"LCMBlackEagles/short/doelpunt1.wav",
		"LCMBlackEagles/short/doelpunt2.wav",
		"LCMBlackEagles/short/doelpunt3.wav",
		"LCMBlackEagles/short/fluit1.wav",
		"LCMBlackEagles/short/fluit2.wav",
		"LCMBlackEagles/short/ritme2.wav",
		"LCMBlackEagles/short/ritme3.wav",
		"LCMBlackEagles/short/ritme4.wav",
		"LCMBlackEagles/short/ritme6.wav",
		"LCMBlackEagles/short/vangen.wav",

		// "LCM/Leeuwarden/CP-samples/LEE_JH_CT_TE02_ahhhhhhhh.wav",
		// "LCM/Leeuwarden/CP-samples/LEE_JH_SK_TE02_trtrtrtrtrtr.wav",
		// "LCM/Leeuwarden/CP-samples/LEE_RdR_AD_ME01_skeeslptchup.wav",

		// "LCM/AmsCS/TE02_bradradradbrad.wav",
		// "LCM/AmsCS/TE03_tdaktak-tdaktik.wav",
		// "LCM/AmsCS/TE07_grrrrrrr uuuu.wav",
		// "LCM/AmsCS/TE0011_klatsjssss.wav",
		//
		// "LCM/AmsCS/Te0016_krrrrklikklikkrrr.wav",
		// "LCM/AmsCS/TE0018_klatschekletsel.wav",
		// "LCM/AmsCS/Te0019_eeuiwtje.wav",
		// "LCM/AmsCS/TI01_aaa.wav",
		// "LCM/AmsCS/TI01_rkhu-rkhu-rkhu.wav",
		// "LCM/AmsCS/TI01_ta-ta-ta-ta.wav",
		// "LCM/AmsCS/TI02_shish-shush-shish.wav",
		// "LCM/AmsCS/TI06_tizz qzkch tizz.wav",
		// "LCM/AmsCS/TI09_kgggg.wav",
		// "LCM/AmsCS/TI10_claps.wav",
		// "LCM/AmsCS/TI20_footsteps.wav",
		// "LCM/AmsCS/Ti0025_eewrkhaeewrkha.wav"

		// "LCM/cameroon/ME_3.wav",
		// "LCM/cameroon/ME_4.wav",
		// "LCM/cameroon/ME_6.wav",
		// "LCM/cameroon/TE_03.wav",
		// "LCM/cameroon/TE_05.wav",
		// "LCM/cameroon/TE_07.wav",
		// "LCM/cameroon/TI_1.wav",
		// "LCM/cameroon/TI_2.wav",
		// "LCM/cameroon/TI_3.wav",
		// "LCM/cameroon/TI_4.wav",

		// "LCM/fb/fbv1d2.wav",
		// "LCM/fb/fbv2a2.wav",
		// "LCM/fb/fbv3.wav",
		// "LCM/fb/fbv8a2.wav",
		//
		// "LCM/fb/fbv12.wav",
		// "LCM/fb/fbv23a2.wav",
		// "LCM/fb/fbv23b2.wav",
		// "LCM/fb/fbv24b2.wav",
		// "LCM/fb/fbv25a2.wav",
		// "LCM/fb/fbv27a2.wav",

		// "LCM/ME09_lalalamelody.wav",
		// "LCM/TE05_HhmmmHhmmm.wav",
		// "LCM/TE02_HeouweskelpCambuur.wav",
		// "LCM/ME05_grumble.wav",
		// "LCM/TE09_Mkmakmakmak.wav",
		// "LCM/TI02_trrr-trrr.wav",
		//
		// "LCM/TI03_tch-tch-tch.wav",
		// "LCM/TI04_tl-tl-tl-tl-tl.wav",
		// "LCM/TI05_ding-dong.wav",
		// "LCM/TI06_ssss-k.wav",
		// "LCM/TI08_bbrr-bbrr.wav",
		// "LCM/TI11_dup-dup-dup.wav"
	],
	att: 0.1.dup(24),
	rel: 0.1.dup(24),
	lp: 1.dup(24),
	lpfOn: 1.dup(24),
	rate: 1.dup(24)
	);

e = ( // sample arrays for SynthKeys
	back:
		[
		"SynthKeys/LCMstem.aif",
		"SynthKeys/LeoGrim.aif",
		"SynthKeys/jeannette.wav",
		"SynthKeys/tone2.aiff",
		"SynthKeys/VoiceWalzChorus1b.wav",
		"SynthKeys/VoiceWalzChorus1c-part.wav",
		"SynthKeys/Brute1.wav",
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
		"SynthKeys/cbcl3.aiff",
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
