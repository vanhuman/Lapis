// Base

(
~lisa = "LiveSampler.scd";
~sk = "SynthKeysMPK.scd";
"InOut.scd".loadRelative();
)

"Curves.scd".loadRelative();

PinoGui.new
FreeAfter

/*

## Notes new features

Joy button 7: FFT Drone

LV1 fader 1-4: Stretched fragments

RED keyset 2:
1: Curves: start resynthesis
2: Curves: switch ON/OFF image control
6/11: switch playback mode zone16play2/3 between fwd-backw and backw
12: switch ON/OFF length modulation zone16play4

DARKGREEN bottom row:
1-4: copy process buffer into A1,A2,B1,B2
5/6: save dynrec 1/3 & 2/4 buffers
7/8: recall dynrec buffers

BLACK:
1/2: start MIDI sequence (second always a bassdrum on the one)
3: change one note
4/5: decrease/increase speed

MPK:
K1/K2: control volume / filter drum synths
K3-K8: GREEN disk-play control: efx level / distortion / vibrato / pitch / filter / volume


?? nil check
!? not nil check
and: { } short circuited (because second operand is a function) and inlined (not the case with &&)
operator precedence: left to right
gcd / lcm
Post << array
if( ) { } { }
while { } { }
f.(x)
# x, y = array
Exception.debug = true;        // enable
Exception.debug = false;    // disable
.postcs        // post the object as a compile string
.debug(caller)    // post the object along with a tag identifying the caller
Error("myFunction-halt").throw;

*/

(
~lisa = nil; ~sk = nil;
"InOut.scd".loadRelative();
)

~pShackleSystemID = 0; "ShackleSystem Server.scd".loadRelative(); // Shackle
~pShackleSystemID = 1; "ShackleSystem Server.scd".loadRelative(); // Shackle Affair
~pShackleSystemID = 6; "ShackleSystem Server.scd".loadRelative(); // Detuning Guitar
"ShackleSystem Client.scd".loadRelative();
"ShackleSystem Client_Ext.scd".loadRelative();

"FF-E3D-simul.scd".loadRelative();
"FF-E3D-simulMPK.scd".loadRelative();

~pID = 4; "Score.scd".loadRelative(); // UFA
~pID = 5; "Score.scd".loadRelative(); // SPILL
"GeluidjesFabriek.scd".loadRelative();
"LiveSampler.scd".loadRelative();
"SynthKeysLPK.scd".loadRelative();
"SynthKeysMPK.scd".loadRelative();
"Controllers.scd".loadRelative();
"MDfreeze.scd".loadRelative();
"MasterFreeze.scd".loadRelative();
"GvdMplay.scd".loadRelative();
"GvdMplayClientGeneric.scd".loadRelative();
"GvdMplayClientShackle-voice.scd".loadRelative();

~vol = s.volume; ~vol.gui;
~vol.free;
s.makeWindow;
ColorPicker.new
Server.killAll
"Research/FreqScopeStereo.scd".loadRelative();
LapisStatus.new

// OSC IN monitor, format: OSC IN -- IP -- port -- message
thisProcess.oscInMonitor(true, addr:1);
thisProcess.oscInMonitor(true, addr:1, excl: ['/InBus','/hid/ex3d', '/ard/ana', '/midi/control']);
thisProcess.oscInMonitor(true, addr:1, excl: ['/InBus','/hid/ex3d', '/ard/ana']);
thisProcess.oscInMonitor(true, addr:1, excl: ['/hid/ex3d','/hybridCtr','/act']);
thisProcess.oscInMonitor(false);

// OSC OUT monitor, format: OSC OUT -- IP -- port -- message
// monitors every NetAddrMon instance
~oscOutMonitor = 1;
~oscOutMonitor = 0;

OSCFunc.trace(false);

