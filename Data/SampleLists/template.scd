// Loop-Copy-Mutate sample list
// a=LV1 b=LV2 c=LX (blue/green)

a = (
	// LV1
	2: [],
	10: [],
	18: [],
	26: [],
	34: [],
	42: [],
	50: [],
	58: []
);

b = (
	// LV2
	2: [],
	10: [],
	18: [],
	26: [],
	34: [],
	42: [],
	50: [],
	58: []
);

c = (
	// LX blue
	24: [],
	25: [],
	26: [],
	27: [],
	28: [],
	29: [],
	30: [],
	31: [],
	32: [],
	33: [],
	34: [],
	35: [],

	// LX blue keyset 2
	36: [],
	37: [],
	38: [],
	39: [],
	40: [],
	41: [],
	42: [],
	43: [],
	44: [],
	45: [],
	46: [],
	47: [],

	// LX blue keyset 3
	48: [],
	49: [],
	50: [],
	51: [],
	52: [],
	53: [],

	54: [], '54out': "B",
	55: [], '55out': "B",
	56: [], '56out': "B",
	57: [], '57out': "B",
	58: [], '58out': "B",
	59: [], '59out': "B",

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

d = ( // LX green keyset 2 & 3 -- settings for justPlay synth
	sampleList:
		[
		// green keyset 2
		// keep first 2 empty as they are handled by playing through Loop-Copy-Mutate/loadRecordings.scd
		"empty",
		"empty",

		"empty",
		"empty",
		"empty",
		"empty",

		"empty",
		"empty",
		"empty",
		"empty",
		"empty",
		"empty",

		// green keyset 3
		"empty",
		"empty",
		"empty",
		"empty",
		"empty",
		"empty",
		"empty",
		"empty",
		"empty",
		"empty",
		"empty",
		"empty",
	],
	att: 0.1.dup(24),
	rel: 0.1.dup(24),
	lp: 1.dup(24),
	lpfOn: 1.dup(24),
	rate: 1.dup(24)
	);

e = ( // sample arrays for SynthKeys, path relative to the Data folder
	back:
		[
		"SynthKeys/kistorgel10.aif",
		],
	left:
		[
		],
	right:
		[
		]
);

[a,b,c,d,e]
