// Robert van Heumen 2012, 2015
// Faderfox, Logitech Extreme 3D pro & LPK simulacra

(
var localAddr = NetAddr("127.0.0.1", 57120);
var wFF, wFFsimul, mFaders1, mFaders2, sCross1, sCross2, bm1, bm2, bmBlue, bmBlue2, bmBlue3, bmGreen, bmGreen2, bmGreen3, bmRed, bmRed2, bmBlack;
var wE3Dsimul, joyE3Dxy, joyE3Dr, joyE3Ds, joyE3Db1, joyE3Db2, joyE3Db3, joyE3Db4, joyE3Db5, joyE3Db6, joyE3Db7, joyE3Db8, joyE3Db9, joyE3Db11, joyE3Db12;
var wKeysimul, bmKeysBankAgui, bmKeysBankBgui, keysBankALabel, keysBankBLabel;
var joyE3DhsF, joyE3DhsB, joyE3DhsL, joyE3DhsR;
var kn1A1, kn1A2, kn1A3, kn1B1, kn1B2, kn1B3, kn1C1, kn1C2, kn1C3, kn1D1, kn1D2, kn1D3, joy1, kn1main;
var kn2A1, kn2A2, kn2A3, kn2B1, kn2B2, kn2B3, kn2C1, kn2C2, kn2C3, kn2D1, kn2D2, kn2D3, joy2, kn2main;
var kn1Left = 10, kn1Top = 80, kn2Left = 170, kn2Top = 80;
var bm1array = [2,10,18,26,34,42,50,58];
var bm2array = [2,10,18,26,34,42,50,58];
var bmBlueArray = [[24,25,26,27,28,29], [30,31,32,33,34,35]];
var bmBlue2Array = [[36,37,38,39,40,41], [42,43,44,45,46,47]];
var bmBlue3Array = [[48,49,50,51,52,53], [54,55,56,57,58,59]];
var bmGreenArray = [[60,61,62,63,64,65], [66,67,68,69,70,71]];
var bmGreen2Array = [[72,73,74,75,76,77], [78,79,80,81,82,83]];
var bmGreen2OnArray = [[0,0,0,0,0,0], [0,0,0,0,0,0]];
var bmGreen3Array = [[84,85,86,87,88,89], [90,91,92,93,94,95]];
var bmGreen3OnArray = [[0,0,0,0,0,0], [0,0,0,0,0,0]];
var bmRedArray = [[0,1,2,3,4,5], [6,7,8,9,10,11]];
var bmRed2Array = [[12,13,14,15,16,17], [18,19,20,21,22,23]];
var bmRedOnArray = [[0,0,0,0,0,0], [0,0,0,0,0,0]];
var bmRed2OnArray = [[0,0,0,0,0,0], [0,0,0,0,0,0]];
var bmBlackArray = [[13,15,18,20,22,0], [12,14,16,17,19,21]];
var bmKeysBankAmidi = [[24,25,26,27],[20,21,22,23]];
var bmKeysBankAOn = [[0,0,0,0], [0,0,0,0]];
var bmKeysBankBmidi = [[32,33,34,35],[28,29,30,31]];
var bmKeysBankBOn = [[0,0,0,0], [0,0,0,0]];
var lv11Label, lv12Label, lx2Label, joyE3Label, arduinoLabel;
var keyB, ardAna1;
var bShift2, shift2 = 0;
var backImage = "/Users/Robert/---data---/Audio/SC/Data/Images/yellow.png";

var version = "1.0 MPK";
var screenHeight = Window.screenBounds.height, screenWidth = Window.screenBounds.width;

// change OSC source from jx to sc temporarily
var oscSrcOnStart = ~oscSrc;
~oscSrc = "sc";
"Set OSC source to 'sc'".postln;

///////////////////////////////////////////// GUI //////////////////////////////////////

wFF = Window("Lapis Simulacrum " ++ version, Rect(20, (screenHeight - 670), 1150, 570)).background_(Color.white);
// w.view.backgroundImage_(Image.new(backImage));
wFF.drawFunc = {
	rrand(10,15).do{|i|
		Pen.color = [Color.grey,Color(0.0, 0.0, 0.7, 0.5)].wchoose([0.9,0.1]);
		Pen.fillColor = Color.grey(0.95);
		Pen.addRect(
			Rect((wFF.bounds.width).rand, -2, 20, (wFF.bounds.height + 4))
		);
		// Pen.perform(\stroke);
		Pen.fill;
	};
};


//wFFsimul = Window("FaderFox Simulacrum " ++ version, Rect(20, (screenHeight - 570), 480, 380));
//wE3Dsimul = Window("Extreme 3d Pro Simulacrum " ++ version, Rect((screenWidth - 770), (screenHeight - 570), 380, 380));
wFFsimul = CompositeView(wFF, Rect(20, 20, 480, 380));
wE3Dsimul = CompositeView(wFF, Rect(540, 0, 580, 400));
wKeysimul = CompositeView(wFF, Rect(20, 450, 480, 200));

//wFFsimul.background_(Color.white);
//wE3Dsimul.background_(Color.white);

//////// LV1.1 ////////

lv11Label = StaticText(wFFsimul, Rect(60, 355, 200, 30));
lv11Label.font = Font("Helvetica", 15);
lv11Label.string = "LV1.1";

lv12Label = StaticText(wFFsimul, Rect(220, 355, 200, 30));
lv12Label.font = Font("Helvetica", 15);
lv12Label.string = "LV1.2";

lx2Label = StaticText(wFFsimul, Rect(380, 355, 200, 30));
lx2Label.font = Font("Helvetica", 15);
lx2Label.string = "LX2";

joy1 = Slider2D(wFFsimul, Rect(10, 10, 65, 65))
.background_(Color.grey(0.9));
joy1.canFocus = false;
joy1.action_({
	localAddr.sendMsg("/midi/control", 13 - 1, 20, joy1.x, "MUL");
	localAddr.sendMsg("/midi/control", 13 - 1, 0, joy1.y, "MUL");
});
joy1.knobColor_(Color(0.0, 0.0, 0.7, 0.5));

kn1main = Knob.new(wFFsimul, Rect(85, 20, 50, 50));
kn1main.canFocus = false;
kn1main.action_({
	localAddr.sendMsg("/midi/control", 15 - 1, 17, kn1main.value, "MUL");
});

mFaders1 = MultiSliderView(wFFsimul, Rect(10, 170, 16.8*8, 100))
.background_(Color.grey(0.9))
.size_(8)
.indexThumbSize_(14.4)
.valueThumbSize_(5)
.isFilled_(true)
.strokeColor_(Color(0.0, 0.0, 0.7, 0.5))
.gap_(2)
.canFocus_(false)
.fillColor_(Color(0.0, 0.0, 0.7, 0.5))
.action_({
	localAddr.sendMsg("/midi/control", 15 - 1, mFaders1.index + (shift2*8), mFaders1.value[mFaders1.index], "MUL");
});

sCross1 = SmoothSlider(wFFsimul, Rect(10, 280, 135, 20))
.hilightColor_(Color(0.0, 0.0, 0.7, 0.5))
.background_(Color.blue.alpha_(0))
.knobColor_(Color(0.0, 0.0, 0.7, 0.5))
.border_(1)
.borderColor_(Color.grey(0.4))
.knobSize_(0.1)
.canFocus_(false)
.action_({
	localAddr.sendMsg("/midi/control", 15 - 1, 19, sCross1.value, "MUL");
});

bm1 = BoxMatrix(wFFsimul,Rect(10,310,135,15),8,1);
bm1.canFocus = false;
bm1.defaultStyle.boxColor = Color(0.0, 0.0, 0.7, 0.5);
bm1.defaultStyle.borderColor = Color.black;
bm1.mouseDownAction = {arg box;
	localAddr.sendMsg("/midi/noteOn", 13 - 1, bm1array[box[\point].x] , 127, "MUL");
};

kn1A1 = Knob.new(wFFsimul, Rect(kn1Left, kn1Top + 60, 30, 30));
kn1A1.canFocus = false;
kn1A1.action_({
	localAddr.sendMsg("/midi/control", 13 - 1, 40, kn1A1.value, "MUL");
});

kn1A2 = Knob.new(wFFsimul, Rect(kn1Left, kn1Top + 30, 30, 30));
kn1A2.canFocus = false;
kn1A2.action_({
	localAddr.sendMsg("/midi/control", 13 - 1, 57, kn1A2.value, "MUL");
});
kn1A2.color_([Color(0.0, 0.0, 0.7, 0.3), kn1A2.color[1], kn1A2.color[2], kn1A2.color[3]]);

kn1A3 = Knob.new(wFFsimul, Rect(kn1Left, kn1Top, 30, 30));
kn1A3.canFocus = false;
kn1A3.action_({
	localAddr.sendMsg("/midi/control", 13 - 1, 58, kn1A3.value, "MUL");
});
kn1A3.color_([Color(0.0, 0.0, 0.7, 0.1), kn1A3.color[1], kn1A3.color[2], kn1A3.color[3]]);

kn1B1 = Knob.new(wFFsimul, Rect(kn1Left + 35, kn1Top + 60, 30, 30));
kn1B1.canFocus = false;
kn1B1.action_({
	localAddr.sendMsg("/midi/control", 13 - 1, 60, kn1B1.value, "MUL");
});

kn1B2 = Knob.new(wFFsimul, Rect(kn1Left + 35, kn1Top + 30, 30, 30));
kn1B2.canFocus = false;
kn1B2.action_({
	localAddr.sendMsg("/midi/control", 13 - 1, 77, kn1B2.value, "MUL");
});
kn1B2.color_([Color(0.0, 0.0, 0.7, 0.3), kn1B2.color[1], kn1B2.color[2], kn1B2.color[3]]);

kn1B3 = Knob.new(wFFsimul, Rect(kn1Left + 35, kn1Top, 30, 30));
kn1B3.canFocus = false;
kn1B3.action_({
	localAddr.sendMsg("/midi/control", 13 - 1, 78, kn1B3.value, "MUL");
});
kn1B3.color_([Color(0.0, 0.0, 0.7, 0.1), kn1B3.color[1], kn1B3.color[2], kn1B3.color[3]]);

kn1C1 = Knob.new(wFFsimul, Rect(kn1Left + 70, kn1Top + 60, 30, 30));
kn1C1.canFocus = false;
kn1C1.action_({
	localAddr.sendMsg("/midi/control", 13 - 1, 80, kn1C1.value, "MUL");
});

kn1C2 = Knob.new(wFFsimul, Rect(kn1Left + 70, kn1Top + 30, 30, 30));
kn1C2.canFocus = false;
kn1C2.action_({
	localAddr.sendMsg("/midi/control", 13 - 1, 97, kn1C2.value, "MUL");
});
kn1C2.color_([Color(0.0, 0.0, 0.7, 0.3), kn1C2.color[1], kn1C2.color[2], kn1C2.color[3]]);

kn1C3 = Knob.new(wFFsimul, Rect(kn1Left + 70, kn1Top, 30, 30));
kn1C3.canFocus = false;
kn1C3.action_({
	localAddr.sendMsg("/midi/control", 13 - 1, 98, kn1C3.value, "MUL");
});
kn1C3.color_([Color(0.0, 0.0, 0.7, 0.1), kn1C3.color[1], kn1C3.color[2], kn1C3.color[3]]);

kn1D1 = Knob.new(wFFsimul, Rect(kn1Left + 105, kn1Top + 60, 30, 30));
kn1D1.canFocus = false;
kn1D1.action_({
	localAddr.sendMsg("/midi/control", 13 - 1, 100, kn1D1.value, "MUL");
});

kn1D2 = Knob.new(wFFsimul, Rect(kn1Left + 105, kn1Top + 30, 30, 30));
kn1D2.canFocus = false;
kn1D2.action_({
	localAddr.sendMsg("/midi/control", 13 - 1, 117, kn1D2.value, "MUL");
});
kn1D2.color_([Color(0.0, 0.0, 0.7, 0.3), kn1D2.color[1], kn1D2.color[2], kn1D2.color[3]]);

kn1D3 = Knob.new(wFFsimul, Rect(kn1Left + 105, kn1Top, 30, 30));
kn1D3.canFocus = false;
kn1D3.action_({
	localAddr.sendMsg("/midi/control", 13 - 1, 118, kn1D3.value, "MUL");
});
kn1D3.color_([Color(0.0, 0.0, 0.7, 0.1), kn1D3.color[1], kn1D3.color[2], kn1D3.color[3]]);

//////// LV1.2 ////////

joy2 = Slider2D(wFFsimul, Rect(170, 10, 65, 65))
.background_(Color.grey(0.9));
joy2.canFocus = false;
joy2.action_({
	localAddr.sendMsg("/midi/control", 10 - 1, 20, joy2.x, "MUL");
	localAddr.sendMsg("/midi/control", 10 - 1, 0, joy2.y, "MUL");
});
joy2.knobColor_(Color(0.0, 0.0, 0.7, 0.5));

kn2main = Knob.new(wFFsimul, Rect(245, 20, 50, 50));
kn2main.canFocus = false;
kn2main.action_({
	localAddr.sendMsg("/midi/control", 12 - 1, 17, kn2main.value, "MUL");
});

mFaders2 = MultiSliderView(wFFsimul, Rect(170, 170, 16.8*8, 100))
.background_(Color.grey(0.9))
.size_(8)
.indexThumbSize_(14.4)
.valueThumbSize_(5)
.isFilled_(true)
.strokeColor_(Color(0.0, 0.0, 0.7, 0.5))
.gap_(2)
.canFocus_(false)
.fillColor_(Color(0.0, 0.0, 0.7, 0.5))
.action_({
	localAddr.sendMsg("/midi/control", 12 - 1, mFaders2.index + (shift2*8), mFaders2.value[mFaders2.index], "MUL");
});

bShift2 = (SmoothButton(wFFsimul, Rect(120, 340, 80, 15))
	.radius_(3)
	.border_(1)
	.canFocus_(false)
	.states_([["shift", Color.white, Color(0.0, 0.0, 0.7, 0.5)],["shift", Color.black, Color.white]])
	.action_({
		shift2 = (shift2 + 1) % 2;
		("LV's shifted to" + shift2).postln;
	})
);

sCross2 = SmoothSlider(wFFsimul, Rect(170, 280, 135, 20))
.hilightColor_(Color(0.0, 0.0, 0.7, 0.5))
.background_(Color.blue.alpha_(0))
.knobColor_(Color(0.0, 0.0, 0.7, 0.5))
.border_(1)
.borderColor_(Color.grey(0.4))
.knobSize_(0.1)
.canFocus_(false)
.action_({
	localAddr.sendMsg("/midi/control", 12 - 1, 19, sCross2.value, "MUL");
});

bm2 = BoxMatrix(wFFsimul,Rect(170,310,135,15),8,1);
bm2.canFocus = false;
bm2.defaultStyle.boxColor = Color(0.0, 0.0, 0.7, 0.5);
bm2.defaultStyle.borderColor = Color.black;
bm2.mouseDownAction = {arg box;
	localAddr.sendMsg("/midi/noteOn", 10 - 1, bm2array[box[\point].x] , 127, "MUL");
};

kn2A1 = Knob.new(wFFsimul, Rect(kn2Left, kn2Top + 60, 30, 30));
kn2A1.canFocus = false;
kn2A1.action_({
	localAddr.sendMsg("/midi/control", 10 - 1, 40, kn2A1.value, "MUL");
});

kn2A2 = Knob.new(wFFsimul, Rect(kn2Left, kn2Top + 30, 30, 30));
kn2A2.canFocus = false;
kn2A2.action_({
	localAddr.sendMsg("/midi/control", 10 - 1, 57, kn2A2.value, "MUL");
});
kn2A2.color_([Color(0.0, 0.0, 0.7, 0.3), kn2A2.color[1], kn2A2.color[2], kn2A2.color[3]]);

kn2A3 = Knob.new(wFFsimul, Rect(kn2Left, kn2Top, 30, 30));
kn2A3.canFocus = false;
kn2A3.action_({
	localAddr.sendMsg("/midi/control", 10 - 1, 58, kn2A3.value, "MUL");
});
kn2A3.color_([Color(0.0, 0.0, 0.7, 0.1), kn2A3.color[1], kn2A3.color[2], kn2A3.color[3]]);

kn2B1 = Knob.new(wFFsimul, Rect(kn2Left + 35, kn2Top + 60, 30, 30));
kn2B1.canFocus = false;
kn2B1.action_({
	localAddr.sendMsg("/midi/control", 10 - 1, 60, kn2B1.value, "MUL");
});

kn2B2 = Knob.new(wFFsimul, Rect(kn2Left + 35, kn2Top + 30, 30, 30));
kn2B2.canFocus = false;
kn2B2.action_({
	localAddr.sendMsg("/midi/control", 10 - 1, 77, kn2B2.value, "MUL");
});
kn2B2.color_([Color(0.0, 0.0, 0.7, 0.3), kn2B2.color[1], kn2B2.color[2], kn2B2.color[3]]);

kn2B3 = Knob.new(wFFsimul, Rect(kn2Left + 35, kn2Top, 30, 30));
kn2B3.canFocus = false;
kn2B3.action_({
	localAddr.sendMsg("/midi/control", 10 - 1, 78, kn2B3.value, "MUL");
});
kn2B3.color_([Color(0.0, 0.0, 0.7, 0.1), kn2B3.color[1], kn2B3.color[2], kn2B3.color[3]]);

kn2C1 = Knob.new(wFFsimul, Rect(kn2Left + 70, kn2Top + 60, 30, 30));
kn2C1.canFocus = false;
kn2C1.action_({
	localAddr.sendMsg("/midi/control", 10 - 1, 80, kn2C1.value, "MUL");
});

kn2C2 = Knob.new(wFFsimul, Rect(kn2Left + 70, kn2Top + 30, 30, 30));
kn2C2.canFocus = false;
kn2C2.action_({
	localAddr.sendMsg("/midi/control", 10 - 1, 97, kn2C2.value, "MUL");
});
kn2C2.color_([Color(0.0, 0.0, 0.7, 0.3), kn2C2.color[1], kn2C2.color[2], kn2C2.color[3]]);

kn2C3 = Knob.new(wFFsimul, Rect(kn2Left + 70, kn2Top, 30, 30));
kn2C3.canFocus = false;
kn2C3.action_({
	localAddr.sendMsg("/midi/control", 10 - 1, 98, kn2C3.value, "MUL");
});
kn2C3.color_([Color(0.0, 0.0, 0.7, 0.1), kn2C3.color[1], kn2C3.color[2], kn2C3.color[3]]);

kn2D1 = Knob.new(wFFsimul, Rect(kn2Left + 105, kn2Top + 60, 30, 30));
kn2D1.canFocus = false;
kn2D1.action_({
	localAddr.sendMsg("/midi/control", 10 - 1, 100, kn2D1.value, "MUL");
});

kn2D2 = Knob.new(wFFsimul, Rect(kn2Left + 105, kn2Top + 30, 30, 30));
kn2D2.canFocus = false;
kn2D2.action_({
	localAddr.sendMsg("/midi/control", 10 - 1, 117, kn2D2.value, "MUL");
});
kn2D2.color_([Color(0.0, 0.0, 0.7, 0.3), kn2D2.color[1], kn2D2.color[2], kn2D2.color[3]]);

kn2D3 = Knob.new(wFFsimul, Rect(kn2Left + 105, kn2Top, 30, 30));
kn2D3.canFocus = false;
kn2D3.action_({
	localAddr.sendMsg("/midi/control", 10 - 1, 118, kn2D3.value, "MUL");
});
kn2D3.color_([Color(0.0, 0.0, 0.7, 0.1), kn2D3.color[1], kn2D3.color[2], kn2D3.color[3]]);

//////// LX2 ////////

bmBlue = BoxMatrix(wFFsimul,Rect(330,10,135,40),6,2);
bmBlue.canFocus = false;
bmBlue.defaultStyle.boxColor = Color(0.0, 0.0, 0.7, 0.5);
bmBlue.defaultStyle.borderColor = Color.black;
bmBlue.mouseDownAction = {arg box;
	localAddr.sendMsg("/midi/noteOn", 1 - 1, bmBlueArray[box[\point].y][box[\point].x] , 127, "MUL");
};

bmBlue2 = BoxMatrix(wFFsimul,Rect(330,53,135,25),6,2);
bmBlue2.canFocus = false;
bmBlue2.defaultStyle.boxColor = Color(0.0, 0.0, 0.7, 0.5);
bmBlue2.defaultStyle.borderColor = Color.black;
bmBlue2.mouseDownAction = {arg box;
	localAddr.sendMsg("/midi/noteOn", 1 - 1, bmBlue2Array[box[\point].y][box[\point].x] , 127, "MUL");
};

bmBlue3 = BoxMatrix(wFFsimul,Rect(330,81,135,25),6,2);
bmBlue3.canFocus = false;
bmBlue3.defaultStyle.boxColor = Color(0.0, 0.0, 0.7, 0.5);
bmBlue3.defaultStyle.borderColor = Color.black;
bmBlue3.mouseDownAction = {arg box;
	localAddr.sendMsg("/midi/noteOn", 1 - 1, bmBlue3Array[box[\point].y][box[\point].x] , 127, "MUL");
};

bmGreen = BoxMatrix(wFFsimul,Rect(330,109,135,40),6,2);
bmGreen.canFocus = false;
bmGreen.defaultStyle.boxColor = Color(0.0, 0.7, 0.0, 0.5);
bmGreen.defaultStyle.borderColor = Color.black;
bmGreen.mouseDownAction = {arg box;
	localAddr.sendMsg("/midi/noteOn", 1 - 1, bmGreenArray[box[\point].y][box[\point].x] , 127, "MUL");
};

bmGreen2 = BoxMatrix(wFFsimul,Rect(330,152,135,25),6,2);
bmGreen2.canFocus = false;
bmGreen2.defaultStyle.boxColor = Color(0.0, 0.7, 0.0, 0.5);
bmGreen2.defaultStyle.borderColor = Color.black;
bmGreen2.styles['focused'] = (
	boxColor: Color(0.0, 0.0, 0.0, 0.0);
);
bmGreen2.mouseDownAction = {arg box;
	if(bmGreen2OnArray[box[\point].y][box[\point].x] == 0,
		{
			bmGreen2OnArray[box[\point].y][box[\point].x] = 1;
			box.boxColor = Color(0.0, 0.7, 0.0, 1.0);
			localAddr.sendMsg("/midi/noteOn", 1 - 1, bmGreen2Array[box[\point].y][box[\point].x] , 127, "MUL");
		},
		{
			box.boxColor = Color(0.0, 0.7, 0.0, 0.5);
			bmGreen2OnArray[box[\point].y][box[\point].x] = 0;
			localAddr.sendMsg("/midi/noteOff", 1 - 1, bmGreen2Array[box[\point].y][box[\point].x] , 0, "MUL");
	});
};

bmGreen3 = BoxMatrix(wFFsimul,Rect(330,180,135,25),6,2);
bmGreen3.canFocus = false;
bmGreen3.defaultStyle.boxColor = Color(0.0, 0.7, 0.0, 0.5);
bmGreen3.defaultStyle.borderColor = Color.black;
bmGreen3.styles['focused'] = (
	boxColor: Color(0.0, 0.0, 0.0, 0.0);
);
bmGreen3.mouseDownAction = {arg box;
	if(bmGreen3OnArray[box[\point].y][box[\point].x] == 0,
		{
			bmGreen3OnArray[box[\point].y][box[\point].x] = 1;
			box.boxColor = Color(0.0, 0.7, 0.0, 1.0);
			localAddr.sendMsg("/midi/noteOn", 1 - 1, bmGreen3Array[box[\point].y][box[\point].x] , 127, "MUL");
		},
		{
			box.boxColor = Color(0.0, 0.7, 0.0, 0.5);
			bmGreen3OnArray[box[\point].y][box[\point].x] = 0;
			localAddr.sendMsg("/midi/noteOff", 1 - 1, bmGreen3Array[box[\point].y][box[\point].x] , 0, "MUL");
	});
};

bmRed = BoxMatrix(wFFsimul,Rect(330,208,135,40),6,2);
bmRed.canFocus = false;
bmRed.defaultStyle.boxColor = Color(0.7, 0.0, 0.0, 0.5);
bmRed.defaultStyle.borderColor = Color.black;
bmRed.styles['focused'] = (
	boxColor: Color(0.0, 0.0, 0.0, 0.0);
);
bmRed.mouseDownAction = {arg box;
	if(bmRedOnArray[box[\point].y][box[\point].x] == 0,
		{
			bmRedOnArray[box[\point].y][box[\point].x] = 1;
			box.boxColor = Color(0.7, 0.0, 0.0, 1.0);
			localAddr.sendMsg("/midi/noteOn", 1 - 1, bmRedArray[box[\point].y][box[\point].x] , 127, "MUL");
		},
		{
			box.boxColor = Color(0.7, 0.0, 0.0, 0.5);
			bmRedOnArray[box[\point].y][box[\point].x] = 0;
			localAddr.sendMsg("/midi/noteOff", 1 - 1, bmRedArray[box[\point].y][box[\point].x] , 0, "MUL");
	});
};

bmRed2 = BoxMatrix(wFFsimul,Rect(330,251,135,25),6,2);
bmRed2.canFocus = false;
bmRed2.defaultStyle.boxColor = Color(0.7, 0.0, 0.0, 0.5);
bmRed2.defaultStyle.borderColor = Color.black;
bmRed2.styles['focused'] = (
	boxColor: Color(0.0, 0.0, 0.0, 0.0);
);
bmRed2.mouseDownAction = {arg box;
	if(bmRed2OnArray[box[\point].y][box[\point].x] == 0,
		{
			bmRed2OnArray[box[\point].y][box[\point].x] = 1;
			box.boxColor = Color(0.7, 0.0, 0.0, 1.0);
			localAddr.sendMsg("/midi/noteOn", 1 - 1, bmRed2Array[box[\point].y][box[\point].x] , 127, "MUL");
		},
		{
			box.boxColor = Color(0.7, 0.0, 0.0, 0.5);
			bmRed2OnArray[box[\point].y][box[\point].x] = 0;
			localAddr.sendMsg("/midi/noteOff", 1 - 1, bmRed2Array[box[\point].y][box[\point].x] , 0, "MUL");
	});
};
// bmRed2.mouseDownAction = {arg box;
// 	localAddr.sendMsg("/midi/noteOn", 1 - 1, bmRed2Array[box[\point].y][box[\point].x] , 127, "MUL");
// };

bmBlack = BoxMatrix(wFFsimul,Rect(330,285,135,40),6,2);
bmBlack.canFocus = false;
bmBlack.defaultStyle.boxColor = Color(0.0, 0.0, 0.0, 0.5);
bmBlack.defaultStyle.borderColor = Color.black;
bmBlack.mouseDownAction = {arg box;
	localAddr.sendMsg("/midi/noteOn", 3 - 1, bmBlackArray[box[\point].y][box[\point].x] , 127, "MUL");
};

////////// Keys ////////

bmKeysBankAgui = BoxMatrix(wKeysimul,Rect(30,0,100,50),4,2);
bmKeysBankAgui.canFocus_(false);
bmKeysBankAgui.defaultStyle.boxColor = Color(0.7, 0.0, 0.0, 0.5);
bmKeysBankAgui.defaultStyle.borderColor = Color.black;
bmKeysBankAgui.styles['focused'] = (
	boxColor: Color(0.0, 0.0, 0.0, 0.0)
);
bmKeysBankAgui.mouseDownAction_({arg box;
	if(bmKeysBankAOn[box[\point].y][box[\point].x] == 0,
		{
			bmKeysBankAOn[box[\point].y][box[\point].x] = 1;
			box.boxColor = Color(0.7, 0.0, 0.0, 1.0);
			localAddr.sendMsg("/midi/control", 0, bmKeysBankAmidi[box[\point].y][box[\point].x] , 1, "LPK");
		},
		{
			box.boxColor = Color(0.7, 0.0, 0.0, 0.5);
			bmKeysBankAOn[box[\point].y][box[\point].x] = 0;
			localAddr.sendMsg("/midi/control", 0, bmKeysBankAmidi[box[\point].y][box[\point].x] , 0, "LPK");
	});
});
bmKeysBankAgui.at(0@1).title = "   1";
bmKeysBankAgui.at(3@1).title = " sus";
bmKeysBankAgui.at(0@0).title = "   5";
keysBankALabel = StaticText(wKeysimul, Rect(20, 60, 150, 30)).font_(Font("Helvetica", 15)).string_("MPK Pads Bank A");

bmKeysBankBgui = BoxMatrix(wKeysimul,Rect(190,0,100,50),4,2);
bmKeysBankBgui.canFocus_(false);
bmKeysBankBgui.defaultStyle.boxColor = Color(0.7, 0.0, 0.0, 0.5);
bmKeysBankBgui.defaultStyle.borderColor = Color.black;
bmKeysBankBgui.styles['focused'] = (
	boxColor: Color(0.0, 0.0, 0.0, 0.0)
);
bmKeysBankBgui.mouseDownAction_({arg box;
	if(bmKeysBankBOn[box[\point].y][box[\point].x] == 0,
		{
			bmKeysBankBOn[box[\point].y][box[\point].x] = 1;
			box.boxColor = Color(0.7, 0.0, 0.0, 1.0);
			localAddr.sendMsg("/midi/control", 0, bmKeysBankBmidi[box[\point].y][box[\point].x] , 1, "LPK");
		},
		{
			box.boxColor = Color(0.7, 0.0, 0.0, 0.5);
			bmKeysBankBOn[box[\point].y][box[\point].x] = 0;
			localAddr.sendMsg("/midi/control", 0, bmKeysBankBmidi[box[\point].y][box[\point].x] , 0, "LPK");
	});
});
bmKeysBankBgui.at(0@1).title = "   1";
bmKeysBankBgui.at(0@0).title = "   5";
keysBankBLabel = StaticText(wKeysimul, Rect(180, 60, 150, 30)).font_(Font("Helvetica", 15)).string_("MPK Pads Bank B");

////////// Extreme 3D pro ////////

joyE3Label = StaticText(wE3Dsimul, Rect(135, 375, 200, 30));
joyE3Label.font = Font("Helvetica", 15);
joyE3Label.string = "Joystick Extreme 3D Pro";

joyE3Dxy = Slider2D(wE3Dsimul, Rect(120, 120, 200, 200))
.background_(Color.grey(0.9))
.canFocus_(false)
.x_(0.5)
.y_(0.5)
.action_({
	localAddr.sendMsg("/hid/ex3d", 16, (1 - joyE3Dxy.x) * 1024);
	localAddr.sendMsg("/hid/ex3d", 17, joyE3Dxy.y * 1024);
});
joyE3Dxy.knobColor_(Color(0.0, 0.0, 0.7, 0.5));

joyE3Dr = Knob(wE3Dsimul, Rect(340, 200, 50, 50))
.canFocus_(false)
.value_(0.5)
.action_({
	localAddr.sendMsg("/hid/ex3d", 19, (1 - joyE3Dr.value) * 255)
});

joyE3Ds = SmoothSlider(wE3Dsimul, Rect(120, 330, 200, 20))
.hilightColor_(Color(0.0, 0.0, 0.7, 0.5))
.background_(Color.blue.alpha_(0))
.knobColor_(Color(0.0, 0.0, 0.7, 0.5))
.border_(1)
.borderColor_(Color.grey(0.4))
.knobSize_(0.1)
.canFocus_(false)
.action_({
	localAddr.sendMsg("/hid/ex3d", 20, (1 - joyE3Ds.value) * 255);
});

joyE3Db1 = SmoothButton(wE3Dsimul, Rect(235, 50, 30, 30))
.radius_(3)
.border_(1);
joyE3Db1.canFocus = false;
joyE3Db1.states = [["B1", Color.white, Color(0.0, 0.0, 0.7, 0.5)],["B1", Color.black, Color.white]];
joyE3Db1.action_({
	localAddr.sendMsg("/hid/ex3d", 4, (joyE3Db1.value - 1).abs);
});

joyE3Db2 = SmoothButton(wE3Dsimul, Rect(120, 50, 30, 30))
.radius_(3)
.border_(1);
joyE3Db2.canFocus = false;
joyE3Db2.states = [["B2", Color.white, Color(0.0, 0.0, 0.7, 0.5)],["B2", Color.black, Color.white]];
joyE3Db2.action_({
	localAddr.sendMsg("/hid/ex3d", 5, (joyE3Db2.value - 1).abs);
});

joyE3Db5 = SmoothButton(wE3Dsimul, Rect(180, 30, 30, 30))
.radius_(3)
.border_(1);
joyE3Db5.canFocus = false;
joyE3Db5.states = [["B5", Color.white, Color(0.0, 0.0, 0.7, 0.5)],["B5", Color.black, Color.white]];
joyE3Db5.action_({
	localAddr.sendMsg("/hid/ex3d", 8, (joyE3Db5.value - 1).abs);
});

joyE3Db6 = SmoothButton(wE3Dsimul, Rect(290, 30, 30, 30))
.radius_(3)
.border_(1);
joyE3Db6.canFocus = false;
joyE3Db6.states = [["B6", Color.white, Color(0.0, 0.0, 0.7, 0.5)],["B6", Color.black, Color.white]];
joyE3Db6.action_({
	localAddr.sendMsg("/hid/ex3d", 9, 1);
	{joyE3Db6.value_(0)}.defer(0.3);
});

joyE3Db3 = SmoothButton(wE3Dsimul, Rect(180, 70, 30, 30))
.radius_(3)
.border_(1);
joyE3Db3.canFocus = false;
joyE3Db3.states = [["B3", Color.white, Color(0.0, 0.0, 0.7, 0.5)],["B3", Color.black, Color.white]];
joyE3Db3.action_({
	localAddr.sendMsg("/hid/ex3d", 6, 0);
});

joyE3Db4 = SmoothButton(wE3Dsimul, Rect(290, 70, 30, 30))
.radius_(3)
.border_(1);
joyE3Db4.canFocus = false;
joyE3Db4.states = [["B4", Color.white, Color(0.0, 0.0, 0.7, 0.5)],["B4", Color.black, Color.white]];
joyE3Db4.action_({
	localAddr.sendMsg("/hid/ex3d", 7, 0);
});

joyE3Db9 = SmoothButton(wE3Dsimul, Rect(20, 220, 30, 30))
.radius_(3)
.border_(1);
joyE3Db9.canFocus = false;
joyE3Db9.states = [["B9", Color.white, Color(0.0, 0.0, 0.7, 0.5)],["B9", Color.black, Color.white]];
joyE3Db9.action_({
	localAddr.sendMsg("/hid/ex3d", 12, 0);
});

joyE3Db8 = SmoothButton(wE3Dsimul, Rect(60, 180, 30, 30))
.radius_(3)
.border_(1);
joyE3Db8.canFocus = false;
joyE3Db8.states = [["B8", Color.white, Color(0.0, 0.0, 0.7, 0.5)],["B8", Color.black, Color.white]];
joyE3Db8.action_({
	// localAddr.sendMsg("/hid/ex3d", 11, 0);
	localAddr.sendMsg("/panic");
	{joyE3Db8.value_(0)}.defer(0.3);
});

joyE3Db7 = SmoothButton(wE3Dsimul, Rect(20, 180, 30, 30))
.radius_(3)
.border_(1);
joyE3Db7.canFocus = false;
joyE3Db7.states = [["B7", Color.white, Color(0.0, 0.0, 0.7, 0.5)],["B7", Color.black, Color.white]];
joyE3Db7.action_({
	localAddr.sendMsg("/hid/ex3d", 10, 0);
});

joyE3Db11 = SmoothButton(wE3Dsimul, Rect(20, 260, 30, 30))
.radius_(3)
.border_(1);
joyE3Db11.canFocus = false;
joyE3Db11.states = [["B11", Color.white, Color(0.0, 0.0, 0.7, 0.5)],["B11", Color.black, Color.white]];
joyE3Db11.action_({
	localAddr.sendMsg("/hid/ex3d", 14, 1);
});

joyE3Db12 = SmoothButton(wE3Dsimul, Rect(60, 260, 30, 30))
.radius_(3)
.border_(1);
joyE3Db12.canFocus = false;
joyE3Db12.states = [["B12", Color.white, Color(0.0, 0.0, 0.7, 0.5)],["B12", Color.black, Color.white]];
joyE3Db12.action_({
	localAddr.sendMsg("/hid/ex3d", 15, 1);
});

joyE3DhsF = SmoothButton(wE3Dsimul, Rect(40, 30, 30, 30)).border_(1); // hatswitch forward
joyE3DhsF.canFocus = false;
joyE3DhsF.states = [["F", Color.white, Color(0.0, 0.0, 0.7, 0.5)],["F", Color.black, Color.white]];
joyE3DhsF.action_({
	if(joyE3DhsF.value == 1,
		{
			localAddr.sendMsg("/hid/ex3d", 18, 7);
			{joyE3DhsF.valueAction_(0)}.defer(0.1);
		},
		{
			localAddr.sendMsg("/hid/ex3d", 18, -1)
	});
});

joyE3DhsL = SmoothButton(wE3Dsimul, Rect(20, 50, 30, 30)).border_(1); // hatswitch left
joyE3DhsL.canFocus = false;
joyE3DhsL.states = [["L", Color.white, Color(0.0, 0.0, 0.7, 0.5)],["L", Color.black, Color.white]];
joyE3DhsL.action_({
	if(joyE3DhsL.value == 1,
		{
			localAddr.sendMsg("/hid/ex3d", 18, 1);
			{joyE3DhsL.valueAction_(0)}.defer(0.1);
		},
		{
			localAddr.sendMsg("/hid/ex3d", 18, -1)
	});
});

joyE3DhsB = SmoothButton(wE3Dsimul, Rect(40, 70, 30, 30)).border_(1); // hatswitch backward
joyE3DhsB.canFocus = false;
joyE3DhsB.states = [["B", Color.white, Color(0.0, 0.0, 0.7, 0.5)],["B", Color.black, Color.white]];
joyE3DhsB.action_({
	if(joyE3DhsB.value == 1,
		{
			localAddr.sendMsg("/hid/ex3d", 18, 3);
			{joyE3DhsB.valueAction_(0)}.defer(0.1);
		},
		{
			localAddr.sendMsg("/hid/ex3d", 18, -1)
	});
});

joyE3DhsR = SmoothButton(wE3Dsimul, Rect(60, 50, 30, 30)).border_(1); // hatswitch right
joyE3DhsR.canFocus = false;
joyE3DhsR.states = [["R", Color.white, Color(0.0, 0.0, 0.7, 0.5)],["R", Color.black, Color.white]];
joyE3DhsR.action_({
	if(joyE3DhsR.value == 1,
		{
			localAddr.sendMsg("/hid/ex3d", 18, 5);
			{joyE3DhsR.valueAction_(0)}.defer(0.1);
		},
		{
			localAddr.sendMsg("/hid/ex3d", 18, -1)
	});
});

////////// Arduino ////////

arduinoLabel = StaticText(wE3Dsimul, Rect(465, 375, 200, 30));
arduinoLabel.font = Font("Helvetica", 15);
arduinoLabel.string = "Arduino pedal";

ardAna1 = SmoothSlider(wE3Dsimul, Rect(480, 120, 60, 200))
.hilightColor_(Color(0.0, 0.0, 0.7, 0.5))
.background_(Color.blue.alpha_(0))
.knobColor_(Color(0.0, 0.0, 0.7, 0.5))
.border_(1)
.borderColor_(Color.grey(0.4))
.knobSize_(0.05)
.value_(0.5)
.canFocus_(false)
.action_({
	localAddr.sendMsg("/ard/ana", 2, ardAna1.value);
});

////////// Keyboard ////////

v = Window("dummy").front; v.close;

keyB = KeyboardWindow(bounds: Rect(450, 400, 600, 100));
keyB.downAction = { |chan, note, velo|
	localAddr.sendMsg("/midi/noteOn", chan, note + (12*~octave), velo, "LPK");
};
keyB.upAction = { |chan, note, velo|
	localAddr.sendMsg("/midi/noteOff", chan, note + (12*~octave), velo, "LPK");
};

// init
wFF.front;

// collect garbage
wFF.onClose_({
	localAddr.disconnect;
	keyB.close;
	~oscSrc = oscSrcOnStart;
	("Set OSC source to '"++~oscSrc++"'").postln;
});

//wFFsimul.front;
//wE3Dsimul.front;

//// collect garbage
//wFFsimul.onClose_({
//	localAddr.disconnect;
//	wE3Dsimul.close;
//	keyB.close;
//	});
//
//wE3Dsimul.onClose_({
//	wFFsimul.close;
//	keyB.close;
//	});
)

