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
	24: ["2019/drone/2019-1 drone.wav", "2019/drone/2019-1 drone.wav"],
	25: ["2019/drone/2019-13 drone.wav"],
	26: ["2019/drone/2019-15 drone.wav", "2019/drone/2019-15 drone.wav"],
	27: ["2019/drone/2019-16 drone.wav", "2019/drone/2019-16 drone.wav"],
	28: ["2019/drone/2019-18 drone.wav", "2019/drone/2019-18 drone.wav"],
	29: ["2019/drone/2019-21 drone.wav"],
	30: ["2019/melody/2019-2 mel.wav"],
	31: ["2019/melody/2019-5 mel.wav", "2019/melody/2019-5 mel.wav"],
	32: ["2019/melody/2019-6 mel.wav", "2019/melody/2019-6 mel.wav"],
	33: ["2019/melody/2019-11 mel.wav", "2019/melody/2019-11 mel.wav"],
	34: ["2019/melody/2019-17 mel.wav", "2019/melody/2019-17 mel.wav"],
	35: ["2019/melody/2019-22 mel.wav", "2019/melody/2019-22 mel.wav"],

	// LX blue keyset 2
	36: ["2019/voice/2019-8 voice.wav", "2019/voice/2019-8 voice.wav", "2019/voice/2019-8 voice.wav"],
	37: ["2019/voice/2019-9 voice.wav", "2019/voice/2019-9 voice.wav", "2019/voice/2019-9 voice.wav"],
	38: ["2019/voice/2019-14 voice.wav", "2019/voice/2019-14 voice.wav", "2019/voice/2019-14 voice.wav"],
	39: ["2019/voice/2019-24 voice.wav", "2019/voice/2019-24 voice.wav"],
	40: ["2019/efx/2019-4 efx bullet.wav", "2019/efx/2019-3 efx.wav", "2019/efx/2019-3 efx.wav"],
	41: ["2019/efx/2019-7 efx rhythm.wav", "2019/efx/2019-7 efx rhythm.wav"],
	42: ["2019/efx/2019-10 efx.wav", "2019/efx/2019-10 efx.wav"],
	43: ["2019/efx/2019-12 efx.wav", "2019/efx/2019-12 efx.wav"],
	44: ["2019/efx/2019-19 efx.wav", "2019/efx/2019-19 efx.wav", "2019/efx/2019-19 efx.wav"],
	45: ["2019/efx/2019-20 efx.wav"],
	46: ["2019/efx/2019-23 efx.wav", "2019/efx/2019-23 efx.wav"],
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
	60: ["2019/voice/2019-8 voice.wav", "2019/voice/2019-8 voice.wav", "2019/voice/2019-8 voice.wav"],
	61: ["2019/voice/2019-9 voice.wav", "2019/voice/2019-9 voice.wav", "2019/voice/2019-9 voice.wav"],
	62: ["2019/voice/2019-14 voice.wav", "2019/voice/2019-14 voice.wav", "2019/voice/2019-14 voice.wav"],
	63: ["2019/voice/2019-24 voice.wav", "2019/voice/2019-24 voice.wav"],
	64: ["2019/efx/2019-4 efx bullet.wav", "2019/efx/2019-3 efx.wav", "2019/efx/2019-3 efx.wav"],
	65: ["2019/efx/2019-7 efx rhythm.wav", "2019/efx/2019-7 efx rhythm.wav"],
	66: ["2019/efx/2019-10 efx.wav", "2019/efx/2019-10 efx.wav"],
	67: ["2019/efx/2019-12 efx.wav", "2019/efx/2019-12 efx.wav"],
	68: ["2019/efx/2019-19 efx.wav", "2019/efx/2019-19 efx.wav", "2019/efx/2019-19 efx.wav"],
	69: ["2019/efx/2019-20 efx.wav"],
	70: ["2019/efx/2019-23 efx.wav", "2019/efx/2019-23 efx.wav"],
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
