// Drone sample list
// a=LV1 b=LV2 c=LX (blue/green)

a = (
	// LV1
	2: ["stoel2-Dis_b.aiff"],
	10: ["dr_AmbIntrigue2+Light1b.aif"],
	18: ["kids in water reverb rbeq.aiff", "GDRVH/BoC2 A97-1.aif"],
	26: ["amawaveseq2detune.aiff"],
	34: ["MOROS/08-proc3-proc1-13-proc1-proc1.wav"],
	42: ["Steenklank/131106-113528.WAV"],
	50: ["Steenklank/131106-115647 spelende kinderen1.WAV"],
	58: ["Steenklank/131106-115647 spelende kinderen2.WAV"]
);

b = (
	// LV2
	2: ["env carrick00part1.aiff"],
	10: ["env car plus radio.aiff"],
	18: ["greyhound bus term rbeq.aiff"],
	26: ["env boat hudson.aiff","env boat hudson.aiff"],
	34: ["GDRVH/015 ARP25 SF lome beat part 1.aif"],
	42: ["MOROS//11-proc1-proc1.aif"],
	50: ["MOROS/07-proc1-proc1.aif"],
	58: ["sines/s3 long01part.aiff", "sines/s3 long04 soft no pitch voices.aif"]
);

c = (
	// LX blue
	24: ["solo2/wd_glass1PSwobblypart.aif"],
	25: ["moros-beat1.aiff"],
	26: ["st roll distance", "st roll distance Rev.aif"],
	27: ["th cumded-dis1.aiff", "th cumded-slack1.aiff"],
	28: ["melodic/mel 310-melodie-low"],
	29: ["th cumded-slack3.aiff"],
	30: ["aphextwin/avril altdelay.wav", "melodic/MDfreeze/theme_03_shortb.wav"],
	31: ["th stabat-dis1.aiff"],
	32: ["voer/a airshaft.aiff"],
	33: ["voer/a alien likes ripley_a.aiff"],
	34: ["silent/ampmod vlow1m.aiff"],
	35: ["solo/so 1m it was indian territory.aiff"],

	// LX blue keyset 2
	36: ["speech/speech1-numbers.wav"],
	37: ["speech/speech12-numbers.wav"],
	38: ["v spider-electron-flow1.aiff"],
	39: ["sci-fi/alien talk decimate.wav"],
	40: ["prince/this is not a dream 1.wav","prince/this is not a dream 1.wav","Alien/moving on second.wav","Alien/moving on second.wav"],
	41: ["sci-fi/countdown decimate.wav", "sci-fi/alien talk 2 decimate.wav" ],
	42: ["v the spider - not this time.aif"],
	43: ["voice/v videodr deb.aiff"],
	44: ["SCrecDelay1.aif"],
	45: ["Gedachtenconcert/stem-collage-1.aif"],
	46: ["musicismath/nfbc Another Side of the Forest1.wav","musicismath/nfbc Another Side of the Forest2.wav"],
	47: ["voice/MD/MDtalk4.aif"],

	// LX green
	60: ["ZAAG55/Afkortzaag1.wav"],
	61: ["env firecrackle1.aiff", "glas&lepel10a.aiff"],
	62: ["ZAAG55/Boor2.wav"],
	63: ["LPcracklebuf.wav"],
	64: ["ZAAG55/Bovenloopkraan2.wav"],
	65: ["ZAAG55/Kettingtakel4.wav"],
	66: ["huh+comasol.aiff"],
	67: ["GDRVH/011 ARP25 Sy-Dis2 part1.aif"],
	68: ["ga schrei03 fluister.aiff"],
	69: [],
	70: ["MOROS/11-proc3-proc1.aif"],
	71: []
);

d = ( // LX green keyset 2 -- settings for justPlay synth
	sampleList:
		[
		"310/Indifferent1.wav",
		"310/Raincarnation1.wav",
		"310/Your Mother1.wav",
		"solo/ampmod lowmidmel mixpart.aif",
		"solo/ampmod pi high1 part1.aiff",
		"solo/so 1m ampmod melodybass2 part1.aiff",

		"solo/so 1m anne session2 part1.aiff",
		"solo/so 1m s3mel14b.aiff",
		"solo2/drone1-24-treble.aif",
		"solo2/drone2-12.aif",
		"voer/a alien lifeform.aif",
		"voer/a alien very bizar.aif"
		],
	att: [],
	rel: 3.dup(24),
	lp: [1,1,1,1,1,1, 1,1,1,1,1,1, 1,1,1,1,1,1, 1,1,1,1,1,1]
	);

e = ( // sample arrays for SynthKeys
	back:
		[
		"SynthKeys/intrigue1.wav",
		"SynthKeys/intrigue2.wav",
		"SynthKeys/intrigue3.wav",
		"SynthKeys/rommel1.aiff",
		"SynthKeys/tone2.aiff",
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
