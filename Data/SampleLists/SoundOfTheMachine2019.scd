// Shackle sample list
// a=LV1 b=LV2 c=LX (blue/green)

a = (
	// LV1
	2: ["GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav"],
	10: ["GvdM/Dis 2a3 part1.wav", "GvdM/Dis 2a3 part1.wav", "GvdM/Dis 2a3 part1.wav"],
	18: ["GvdM/Dis 2b part1.wav"],
	26: [],
	34: [],
	42: [],
	50: [],
	58: []
);

b = (
	// LV2
	2: ["GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav"],
	10: ["GvdM/Dis 2a3 part1.wav", "GvdM/Dis 2a3 part1.wav", "GvdM/Dis 2a3 part1.wav"],
	18: ["GvdM/Dis 2b part1.wav"],
	26: [],
	34: [],
	42: [],
	50: [],
	58: []
);

c = (
	// LX blue
	24: ["GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav"],
	25: ["GvdM/Dis 2a3 part1.wav", "GvdM/Dis 2a3 part1.wav", "GvdM/Dis 2a3 part1.wav"],
	26: ["GvdM/Dis 2b part1.wav"],
	27: [],
	28: [],
	29: [],
	30: ["GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav", "GvdM/Dis 1c2 part1.wav"], '30out': "B",
	31: ["GvdM/Dis 2a3 part1.wav", "GvdM/Dis 2a3 part1.wav", "GvdM/Dis 2a3 part1.wav"], '31out': "B",
	32: ["GvdM/Dis 2b part1.wav"], '32out': "B",
	33: [],
	34: [],
	35: [],

	// LX green
	60: [],
	61: [],
	62: [],
	63: [],
	64: [],
	65: [],
	66: [],
	67: [],
	68: [],
	69: [],
	70: [],
	71: []
);

d = ( // LX green keyset 2 -- settings for justPlay synth
	sampleList:
		[
		"GvdM/Prime 1c2.wav",
		],
	att: 2.dup(24),
	rel: 2.dup(6) ++ 1.dup(6) ++ [2] ++ 0.1.dup(5) ++ 1.dup(6) ,
	lp: 0.dup(24),
	lpfOn: 1.dup(24),
	rate: 1.dup(24)
	);

e = ( // sample arrays for SynthKeys
	back:
		[
		// "SynthKeys/rommel1.aiff",
		"SynthKeys/Felipe-1.wav",
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
		"SynthKeys/highFlute1.wav",
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
