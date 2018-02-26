// Robert van Heumen 2011/2012
// Polling of controllers: Arduino, HID en MIDI
// Working with SC 3.7.2

// Data send to responders on IP 127.0.0.1 and port 57120
// Arduino responders: /ard/ana1, /ard/ana2, /ard/dig1, /ard/dig2
// HID extreme 3dpro responder: /hid/ex3d
// MIDI responders: /midi/noteOn, /midi/noteOff, /midi/control

(
var localAddr = NetAddr("127.0.0.1", 57120);
//var localAddr = NetAddrMon("127.0.0.1", 57120); // to monitor outgoing OSC, set ~oscOut = 1
var screenHeight = Window.screenBounds.height, screenWidth = Window.screenBounds.width;

var portName, ardSms, ardTask, ardLabel;
var ardAna1enable = 1, ardAna1, ardAna1Max = 780, ardAna1Min = 3, ardAna1prev = 0; // calibration Arduino input 1
var ardAna2enable = 1, ardAna2 = 0, ardAna2Max = 760, ardAna2Min = 3, ardAna2prev = 0; // calibration Arduino input 2
var ardDig2enable = 1, ardDig2, ardDig2prev = 0;
var ardDig3enable = 1, ardDig3, ardDig3prev = 0;
var ardAna1avail, ardAna2avail, ardDig2avail, ardDig3avail;
var hidLabel, ex3dAvail, ex3dPro;
var iac1ID = 0, iac1i, mulID = 0, lpkID = 0, extID = 0, mulAvail, midiLabel, iac1Avail, lpkAvail, extAvail, iac2ID = 0;
var fontLabel = Font(~font,10), fontButton = Font(~font,12);
var hidRemap = 4; // number to add to HID cookies for remapping

"GlobalVars.scd".loadRelative();
if(~oscSrc == "jx", {"/Users/robert/---data---/audio/junXion/HID2SC.j4xml/".openOS});

///////////////////////////////////////////// HID data acquisition //////////////////////////////////////

HID.findAvailable.do {arg device;
	var elidMapped, physValueMapped;
	if(device.productName == "Logitech Extreme 3D", {
		ex3dPro = HID.open(device.vendorID, device.productID);
		// ex3dPro.postInfo; ex3dPro.postElements;
		ex3dPro.action = { | value, physValue, rawValue,  arrayValue, usage, page, elid |
			// "HID device action: ".post; [value, physValue, rawValue,  arrayValue, usage, page, elid].postln;
			elidMapped = elid + hidRemap; // remap cookie ids
			// remap values
			case
			{elid<12} {physValueMapped = (physValue+1)%2} // buttons
			{(elid==12) || (elid==13)} {physValueMapped = 1023 - physValue} // X & Y
			{(elid==15) || (elid==16)} {physValueMapped = 255 - physValue} // R & S
			{elid==14} {physValueMapped = 7 - (physValue.round(1) / 45)} // Hat
			;
			// ("cookie, map, value, map" + [elid, elidMapped,physValue,physValueMapped]).postln;
			localAddr.sendMsg("/hid/ex3d", elidMapped, physValueMapped);
		};
	});
};

// code for old HIDDeviceService at the end of this file, just to be sure


///////////////////////////////////////////// Arduino data acquisition //////////////////////////////////////

["Serial", SerialPort.devices].postln;
portName = SerialPort.devices.detect{|x| x.contains("tty.usb")};
if(portName.notNil, {
	("Connected to serial port" + portName ++ ".").postln;
	ardSms = ArduinoSMS(portName, 115200);
	ardSms.action = {
		| ... msg |
		// msg.postln;
		if(ardAna1enable == 1,
			{
				ardAna1 = min(1, max(0, (msg[0] - ardAna1Min )) / ardAna1Max).round(0.001);
				if(ardAna1 != ardAna1prev, {
					localAddr.sendMsg("/ard/ana", 1,  ardAna1);
					ardAna1prev = ardAna1;
					// ("Arduino A1:"+[ardAna1,msg[0]]).postln;
				});
		});
		if(ardAna2enable == 1,
			{
				ardAna2 = min(1, max(0, (msg[1] - ardAna2Min )) / ardAna2Max).round(0.001);
				if(ardAna2 != ardAna2prev, {
					localAddr.sendMsg("/ard/ana", 2,  ardAna2);
					ardAna2prev = ardAna2;
					// ("Arduino A2:"+[ardAna2,msg[1]]).postln;
				});
		});
		if(ardDig2enable == 1,
			{
				ardDig2 = msg[2];
				if(ardDig2 != ardDig2prev, {
					localAddr.sendMsg("/ard/dig", 1, ardDig2);
					ardDig2prev = ardDig2;
					// ("Arduino D2:"+ardDig2).postln;
				});
		});
		if(ardDig3enable == 1,
			{
				ardDig3 = msg[3];
				if(ardDig3 != ardDig3prev, {
					localAddr.sendMsg("/ard/dig", 2, ardDig3);
					ardDig3prev = ardDig3;
					// ("Arduino D3:"+ardDig3).postln;
				});
		});
	};

	ardTask = Task({
		inf.do { ardSms.send($r);  0.05.wait; } // where $r is the Char r
	});
	ardTask.start;
	},
	{"No serial port found with name matching 'tty.usbmodem'.".postln}
);


///////////////////////////////////////////// OSC data acquisition //////////////////////////////////////

// OSCdef(\fluisterButton, { |msg|
// 	// ("Controllers: OSC RCV: " ++ msg).postln;
// 	if(ardSms.notNil, {
// 		if(msg[1] == 1, { ardSms.send($s) });
// 		if(msg[1] == 0, { ardSms.send($t) });
// 	});
// }, "/fluisterButton").fix;



///////////////////////////////////////////// MIDI acquisition //////////////////////////////////////

"### Initializing MIDI".postln;
MIDIIn.connectAll;

MIDIdef.noteOn(\controllersNON,{
	arg val, num, chan, src;
	// ["NON", val, num, chan, src].postln;
	localAddr.sendMsg("/midi/noteOn", chan, num, val / 127,
		case {src == iac1ID}{"IAC1"}{src == iac2ID}{"IAC2"}{src == mulID}{"MUL"}{src == lpkID}{"LPK"}{src == extID}{"EXT"});
	}
).fix;

MIDIdef.noteOff(\controllersNOF,{
	arg val, num, chan, src;
	//	["NOF", val, num, chan, src].postln;
	localAddr.sendMsg("/midi/noteOff", chan, num, val / 127,
		case {src == iac1ID}{"IAC1"}{src == iac2ID}{"IAC2"}{src == mulID}{"MUL"}{src == lpkID}{"LPK"}{src == extID}{"EXT"});
	}
).fix;

MIDIdef.cc(\controllersCC,{
	arg val, num, chan, src;
	//	["CC", val, num, chan, src].postln;
	if(~postControllerData == 1, { ["CC", chan, num, val].postln });
	localAddr.sendMsg("/midi/control", chan, num, val / 127,
		case {src == iac1ID}{"IAC1"}{src == iac2ID}{"IAC2"}{src == mulID}{"MUL"}{src == lpkID}{"LPK"}{src == extID}{"EXT"});
	}
).fix;

MIDIClient.sources.size.do({|i|
	// MIDIClient.sources[i].device.postln;
	// MIDIClient.sources[i].name.postln;
	case
	// MOTU Ultralite, Ploytec MIDI Cable -> MUL
	{
		((MIDIClient.sources[i].device == "UltraLite mk3 Hybrid") || (MIDIClient.sources[i].device == "UltraLite mk3 Hybrid #2"))
		&& (MIDIClient.sources[i].name == "MIDI Port")
	}
	{
		mulID = MIDIClient.sources[i].uid;
		// organize MIDI output
		if((~midiOutInit == 1) && (~midiOutDevice == "MUL"), {
			~midiOut = MIDIOut(i);
			~midiOut.latency_(0.01);
			"MIDI out to MUL".postln;
		});
	}
	// LPK, MPK, microKEY -> LPK
	{
		(MIDIClient.sources[i].device == "LPK25") ||
		(MIDIClient.sources[i].device == "MPKmini2") ||
		((MIDIClient.sources[i].device == "microKEY") && (MIDIClient.sources[i].name == "KEYBOARD"))
	}
	{
		lpkID = MIDIClient.sources[i].uid
	}
	// external, M-Audio MidiSport, Teensy MIDI, Ploytec MIDI Cable -> EXT
	{
		((MIDIClient.sources[i].device == "MIDISPORT 2x2") && (MIDIClient.sources[i].name == "Port A")) ||
		(MIDIClient.sources[i].device == "Teensy MIDI") ||
		(MIDIClient.sources[i].device == "Ploytec MIDI Cable")
	}
	{
		extID = MIDIClient.sources[i].uid;
		// organize MIDI output
		if((~midiOutInit == 1) && (~midiOutDevice == "EXT"), {
			~midiOut = MIDIOut(i);
			~midiOut.latency_(0.01);
			"MIDI out to EXT (MIDISPORT or Teensy)".postln;
		});
	}
	// IAC1 -> IAC1
	{
		(MIDIClient.sources[i].device == "IAC Driver") && (MIDIClient.sources[i].name == "IAC Bus 1")
	}
	{
		iac1ID = MIDIClient.sources[i].uid;
		iac1i = i;
		// organize MIDI output
		if((~midiOutInit == 1) && (~midiOutDevice == "IAC1"), {
			~midiOut = MIDIOut(i);
			~midiOut.latency_(0.01);
			"MIDI out to IAC1".postln;
		});
	}
	// IAC2 -> IAC2
	{
		(MIDIClient.sources[i].device == "IAC Driver") && (MIDIClient.sources[i].name == "IAC Bus 2")
	}
	{
		iac2ID = MIDIClient.sources[i].uid;
	}
	;
});

// if MIDI out should be initialized but midiOut is still nil, use IAC1
if((~midiOutInit == 1) && ~midiOut.isNil, {
	~midiOut = MIDIOut(iac1i);
	~midiOut.latency_(0.01);
	("MIDI out to IAC1 (since" + ~midiOutDevice + "is not available)").postln;
	~midiOutDevice = "IAC1";
});

"### Done initializing MIDI".postln;

///////////////////////////////////////////// GUI //////////////////////////////////////

~wControllers = Window("Controllers", Rect(650, (screenHeight - 160), 280, 100),false).background_(Color.white);
~wControllersAvail = 1;

ardLabel = StaticText(~wControllers, Rect(20, 12, 50, 16))
.font_(fontLabel)
.background_(Color.white.alpha_(0.7))
.string_(" Arduino ");

ardAna1avail = SmoothButton(~wControllers, Rect(85,10,40,20))
.border_(1)
.radius_(3)
.canFocus_(false)
.font_(fontButton)
.background_(Color.white)
.states_([["Ana1"]]);

ardAna2avail = SmoothButton(~wControllers, Rect(130,10,40,20))
.border_(1)
.radius_(3)
.canFocus_(false)
.font_(fontButton)
.background_(Color.white)
.states_([["Ana2"]]);

ardDig2avail = SmoothButton(~wControllers, Rect(175,10,40,20))
.border_(1)
.radius_(3)
.canFocus_(false)
.font_(fontButton)
.background_(Color.white)
.states_([["Dig2"]]);

ardDig3avail = SmoothButton(~wControllers, Rect(220,10,40,20))
.border_(1)
.radius_(3)
.canFocus_(false)
.font_(fontButton)
.background_(Color.white)
.states_([["Dig3"]]);

hidLabel = StaticText(~wControllers, Rect(20, 42, 50, 16))
.font_(fontLabel)
.background_(Color.white.alpha_(0.7))
.string_(" HID ");

ex3dAvail = SmoothButton(~wControllers, Rect(85,40,40,20))
.border_(1)
.radius_(3)
.canFocus_(false)
.font_(fontButton)
.background_(Color.white)
.states_([["Ex3d"]]);

midiLabel = StaticText(~wControllers, Rect(20, 72, 50, 16))
.font_(fontLabel)
.background_(Color.white.alpha_(0.7))
.string_(" MIDI ");

mulAvail = SmoothButton(~wControllers, Rect(85,70,40,20))
.border_(1)
.radius_(3)
.canFocus_(false)
.font_(fontButton)
.background_(Color.white)
.states_([["MUL"]]);

iac1Avail = SmoothButton(~wControllers, Rect(130,70,40,20))
.border_(1)
.radius_(3)
.canFocus_(false)
.font_(fontButton)
.background_(Color.white)
.states_([["IAC1"]]);

lpkAvail = SmoothButton(~wControllers, Rect(175,70,40,20))
.border_(1)
.radius_(3)
.canFocus_(false)
.font_(fontButton)
.background_(Color.white)
.states_([["MPK"]]);

extAvail = SmoothButton(~wControllers, Rect(220,70,40,20))
.border_(1)
.radius_(3)
.canFocus_(false)
.font_(fontButton)
.background_(Color.white)
.states_([["EXT"]]);

~wControllers.view.keyDownAction_({
	arg view, char, modifiers, unicode, keycode;
	// [modifiers,keycode].postln;
	// D toggles controller data postln
	if((keycode == 2),  {
		~postControllerData = (~postControllerData + 1)%2;
		if(~postControllerData==1, { "Posting controller data".postln }, { "NOT posting controller data".postln });
	});
});

w = Window("dummy").front; w.close;
~wControllers.front;
if(~alwaysOnTop == 1, {~wControllers.alwaysOnTop_(true)});
if(~wInOutAvail == 1, {localAddr.sendMsg("/imageRefresh")}); // request image refresh

// GUI
if(portName.notNil, {
	if(ardAna1enable == 1, {ardAna1avail.background_(~colorOn);});
	if(ardAna2enable == 1, {ardAna2avail.background_(~colorOn);});
	if(ardDig2enable == 1, {ardDig2avail.background_(~colorOn);});
	if(ardDig3enable == 1, {ardDig3avail.background_(~colorOn);});
});
if(ex3dPro.notNil, {ex3dAvail.background_(~colorOn);});
if(mulID != 0, {mulAvail.background_(~colorOn);});
if(iac1ID != 0, {iac1Avail.background_(~colorOn);});
if(lpkID != 0, {lpkAvail.background_(~colorOn);});
if(extID != 0, {extAvail.background_(~colorOn);});

// collect garbage
~wControllers.onClose_({
	ardTask.stop;
	localAddr.disconnect;
	if((ardSms != nil), { ardSms.close });
	HID.closeAll;
	MIDIdef(\controllersNON).free; MIDIdef(\controllersNOF).free; MIDIdef(\controllersCC).free;
	~wControllersAvail = nil;
});

)

// var captureHIDenabled = 0; // set to 1 to switch on
// var ex3dProArrayNbr, ex3dProVendor = 0;
// var destTP1ArrayNbr, destTP1Loc = 0, destTP2ArrayNbr, destTP2Loc = 0, destTP1Avail, destTP2Avail;
// var hidCookie = List.new(), hidValue = List.new(), hidTime = List.new(), captureHID = 0, startHIDseries = 0, fRunHID, tRunHID, sRunHID = 0;

// fRunHID = {
// 	inf.do({
// 		hidCookie.size.do({arg i;
// 			if(i > 0, {(hidTime.at(i) - hidTime.at(i - 1)).wait;});
// 			localAddr.sendMsg("/hid/ex3d", hidCookie.asArray.at(i), hidValue.at(i));
// 		});
// 	});
// };

// destTP1Avail = SmoothButton(~wControllers, Rect(130,40,40,20))
// .border_(1)
// .radius_(3)
// .canFocus_(false)
// .font_(fontButton)
// .background_(Color.white)
// .states_([["Tilt1"]]);
//
// destTP2Avail = SmoothButton(~wControllers, Rect(175,40,40,20))
// .border_(1)
// .radius_(3)
// .canFocus_(false)
// .font_(fontButton)
// .background_(Color.white)
// .states_([["Tilt2"]]);

// if (HIDDeviceService.buildDeviceList(nil,nil) != nil, {
// 	// get the array number of extreme3DPro and Destroyer Tiltpads
// 	i = 0;
// 	HIDDeviceService.devices.do({arg dev;
// 		["HID", i, dev.manufacturer, dev.product, dev.usage, dev.vendorID, dev.productID, dev.locID].postln;
// 		if(dev.product == "Logitech Extreme 3D",
// 			{
// 				ex3dProArrayNbr = i;
// 				ex3dProVendor = dev.vendorID;
// 				("Connected to Extreme 3D Pro device at slot " ++ ex3dProArrayNbr ++ ".").postln;
// 		});
// 		if(dev.product == "Destroyer Tiltpad",
// 			{
// 				if(destTP1Loc == 0,
// 					{ // first Tiltpad
// 						destTP1ArrayNbr = i;
// 						destTP1Loc = dev.locID;
// 						("Connected to Destroyer Tiltpad first device at slot " ++ destTP1ArrayNbr ++ ".").postln;
// 					},
// 					{ // second Tiltpad
// 						destTP2ArrayNbr = i;
// 						destTP2Loc = dev.locID;
// 						("Connected to Destroyer Tiltpad second device at slot " ++ destTP2ArrayNbr ++ ".").postln;
// 				});
// 		});
// 		i = i + 1;
// 	});
// 	// Destroyer Tiltpad first device
// 	if(destTP1Loc != 0,
// 		{
// 			HIDDeviceService.devices.at(destTP1ArrayNbr).queueDevice;
// 		},
// 		{
// 			"No Destroyer Tiltpad device found.".postln;
// 	});
// 	// Destroyer Tiltpad second device
// 	if(destTP2Loc != 0,
// 		{
// 			HIDDeviceService.devices.at(destTP2ArrayNbr).queueDevice;
// 		},
// 		{
// 			"No second Destroyer Tiltpad device found.".postln;
// 	});
// 	// Logitech Extreme 3D Pro
// 	if(ex3dProVendor != 0,
// 		{
// 			HIDDeviceService.devices.at(ex3dProArrayNbr).queueDevice;
// 		},
// 		{
// 			"No Extreme 3D Pro device found.".postln;
// 	});
// 	// Set action and run eventloop
// 	if((ex3dProVendor != 0) || (destTP1Loc != 0) || (destTP2Loc != 0), {
// 		HIDDeviceService.action_({arg vendorID, productID, locID, cookie, val;
// 			//			[vendorID, productID, locID, cookie, val].postln;
//
// 			if((vendorID != ex3dProVendor) && (locID == destTP1Loc),
// 			{localAddr.sendMsg("/hid/desttp1", cookie, val);});
// 			if((vendorID != ex3dProVendor) && (locID == destTP2Loc),
// 			{localAddr.sendMsg("/hid/desttp2", cookie, val);});
// 			if(vendorID == ex3dProVendor,
// 			{localAddr.sendMsg("/hid/ex3d", cookie, val);});
//
// 			// panic button
// 			if((cookie == 11) && (vendorID == ex3dProVendor) && (val == 0),
// 				{
// 					tRunHID.stop;
// 					localAddr.sendMsg("/panic");
// 			});
//
// 			// capture HID switch
// 			if(cookie == 18 && val == 1 && captureHIDenabled == 1, {
// 				captureHID = (captureHID + 1)%2;
// 				if(captureHID == 1, {
// 					"Start capture HID".postln;
// 					startHIDseries = SystemClock.seconds;
// 					hidCookie.clear;
// 					hidValue.clear;
// 					hidTime.clear;
// 					},
// 					{
// 						"Stop capture HID".postln;
// 						hidCookie.postln;
// 						hidValue.postln;
// 						hidTime.postln;
// 				});
// 			});
//
// 			// capture HID
// 			if(captureHID == 1 && cookie != 18,
// 				{
// 					hidCookie.add(cookie);
// 					hidValue.add(val);
// 					hidTime.add(SystemClock.seconds - startHIDseries);
// 			});
//
// 			// playback HID captured
// 			if(cookie == 18 && val == 5 && captureHIDenabled == 1, {
// 				"Playback captured HID".postln;
// 				sRunHID = (sRunHID + 1)%2;
// 				if(sRunHID == 1,
// 					{
// 						tRunHID = Task(fRunHID).play;
// 						// disable X-axis on joystick to prevent double triggering of zones
// 						localAddr.sendMsg("/disablex",1);
// 					},
// 					{
// 						tRunHID.stop;
// 						// stop all zone6 synths in LiveSampler
// 						localAddr.sendMsg("/panic",6);
// 						// enable X-axis on joystick
// 						localAddr.sendMsg("/disablex",0);
// 				});
// 			});
//
// 			//			mimic control by anne
// 			//			if(cookie == 16,
// 			//				{localAddr.sendMsg("/act", (val / 1023) * 1000);});
// 			//
// 			//			if(cookie == 4,
// 			//				{localAddr.sendMsg("/asw", val);});
//
// 		});
//
// 		HIDDeviceService.runEventLoop;
// 	});
// 	},
// 	{"No HID devices found.".postln}
// );

// if(destTP1Loc != 0, {destTP1Avail.background_(~colorOn);});
// if(destTP2Loc != 0, {destTP2Avail.background_(~colorOn);});

// HIDDeviceService.stopEventLoop;
