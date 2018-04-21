LapisStatus {

	var inputPeakResp;

	*new
	{
		arg marginX = 10, marginY = 10, height = 25, win, posX = 20, posY = 50, inputPeakChans = 0, inputPeakStartChan = 0,
		font = "Helvetica", vertical = false;

		^super.new.initLapisStatus(marginX, marginY, height, win, posX, posY, inputPeakChans, inputPeakStartChan, font, vertical);
	}

	initLapisStatus
	{
		arg marginX, marginY, height, win, posX, posY, inputPeakChans, inputPeakStartChan, font, vertical;

		var localWin = 0, screenHeight = Window.screenBounds.height;
		var dispBaseBtn, dispBaseBtn2, dispDisablePitch, dispDisableStartPos, dispPlay, dispRec, dispEfx, dispPlaySK;
		var susStatus, bpmSK, zone8patt, bInputPeak = Array.newClear(16);
		var colorStatus = [Color.white, Color.green(0.9), Color.yellow];
		var fontButton = Font(font,height-6);
		var fontLabel = Font(font, 8);
		var textWidth = 42, nbrWidth = 35, space = 4, heightExtra = 0;
		var width = 470, winHeight = height;

		if(vertical, {
			winHeight = height * 6.7;
			width = 78;
			nbrWidth = textWidth;
		});
		if(inputPeakChans > 0) { heightExtra = textWidth + (3*space) };
		if(win.isNil, { // create window
			~wLapis = win = Window("LapisStatus", Rect(posX,posY,width+(2*marginX),winHeight+(2*marginY)+heightExtra),false)
			.background = Color.grey(0.9)
			.alpha = 0.9;
			localWin = 1;
			win.onClose_({
				~wLapis = win = nil;
				this.stop;
			});
		});

		if(vertical, { win.addFlowLayout });

		dispBaseBtn = SmoothButton(win, Rect(marginX,marginY,textWidth,height))
		.border_(1)
		.radius_(3)
		.canFocus_(false)
		.font_(fontButton)
		.background_(Color.white)
		.states_([["BB"]]);

		dispBaseBtn2 = SmoothButton(win, Rect(marginX+textWidth+space,marginY,textWidth,height))
		.border_(1)
		.radius_(3)
		.canFocus_(false)
		.font_(fontButton)
		.background_(Color.white)
		.states_([["OS"]]);

		dispDisableStartPos = SmoothButton(win, Rect(marginX+(2*(textWidth+space)),marginY,textWidth,height))
		.border_(1)
		.radius_(3)
		.canFocus_(false)
		.font_(fontButton)
		.background_(Color.white)
		.states_([["SP"]]);

		dispDisablePitch = SmoothButton(win, Rect(marginX+(3*(textWidth+space)),marginY,textWidth,height))
		.border_(1)
		.radius_(3)
		.canFocus_(false)
		.font_(fontButton)
		.background_(Color.white)
		.states_([["PT"]]);

		dispPlay = SmoothButton(win, Rect(marginX+(4*(textWidth+space)),marginY,nbrWidth,height))
		.border_(1)
		.radius_(3)
		.canFocus_(false)
		.font_(fontButton)
		.stringColor_(Color.blue)
		.background_(Color.white)
		.states_([["0"]]);

		dispRec = SmoothButton(win, Rect(marginX+(4*(textWidth+space))+(1*(nbrWidth+space)),marginY,nbrWidth,height))
		.border_(1)
		.radius_(3)
		.canFocus_(false)
		.font_(fontButton)
		.stringColor_(Color.red)
		.background_(Color.white)
		.states_([["0"]]);

		dispEfx = SmoothButton(win, Rect(marginX+(4*(textWidth+space))+(2*(nbrWidth+space)),marginY,nbrWidth,height))
		.border_(1)
		.radius_(3)
		.canFocus_(false)
		.font_(fontButton)
		.background_(Color.white)
		.states_([["0"]]);

		dispPlaySK = SmoothButton(win, Rect(marginX+(4*(textWidth+space))+(3*(nbrWidth+space)),marginY,nbrWidth,height))
		.border_(1)
		.radius_(3)
		.canFocus_(false)
		.font_(fontButton)
		.stringColor_(Color.blue)
		.background_(Color.white)
		.states_([["0"]]);

		susStatus = SmoothButton(win, Rect(marginX+(4*(textWidth+space))+(4*(nbrWidth+space)),marginY,textWidth,height))
		.border_(1)
		.radius_(3)
		.canFocus_(false)
		.font_(fontButton)
		.background_(Color.white)
		.states_([["Sus"]]);

		if(vertical.not, {
			StaticText(win, Rect(marginX+(5*(textWidth+space))+(4*(nbrWidth+space))+12,marginY-16,textWidth,height))
			.string_("bpm").font_(fontLabel);
		});
		bpmSK = SmoothButton(win, Rect(marginX+(5*(textWidth+space))+(4*(nbrWidth+space)),marginY,textWidth,height))
		.border_(1)
		.radius_(3)
		.canFocus_(false)
		.font_(fontButton)
		.background_(Color.white)
		.states_([["bpm"]]);

		if(vertical.not, {
			StaticText(win, Rect(marginX+(6*(textWidth+space))+(4*(nbrWidth+space))+8,marginY-16,nbrWidth,height))
			.string_("patt").font_(fontLabel);
		});
		zone8patt = SmoothButton(win, Rect(marginX+(6*(textWidth+space))+(4*(nbrWidth+space)),marginY,nbrWidth,height))
		.border_(1)
		.radius_(3)
		.canFocus_(false)
		.font_(fontButton)
		.stringColor_(Color.black)
		.background_(Color.white)
		.states_([["0"]]);

		forBy(inputPeakStartChan, inputPeakStartChan+inputPeakChans-1, 1, { |channel|
				bInputPeak[channel] = Button(win, Rect(10 + (channel*(textWidth+space)),45,textWidth,textWidth))
				.states_([ [(channel+1),Color.black,Color.white] , [(channel+1),Color.white,Color.red] ]);
		});

		OSCdef(\lapisStatus, {arg msg;
			var type, val;
			type = msg[1].asString;
			val = msg[2].asInt;
			case
			{type == "BB"} {{dispBaseBtn.background_(colorStatus[val])}.defer()}
			{type == "OS"} {{dispBaseBtn2.background_(colorStatus[val])}.defer()}
			{type == "SP"} {{dispDisableStartPos.background_(colorStatus[val])}.defer()}
			{type == "PT"} {{dispDisablePitch.background_(colorStatus[val])}.defer()}
			{type == "countPlay"} {{dispPlay.states_([[val.asString]])}.defer()}
			{type == "countRec"} {{dispRec.states_([[val.asString]])}.defer()}
			{type == "countEfx"} {{dispEfx.states_([[val.asString]])}.defer()}
			{type == "countPlaySK"} {{dispPlaySK.states_([[val.asString]])}.defer()}
			{type == "sustain"} {{susStatus.background_(colorStatus[val])}.defer()}
			{type == "shift"} {{bpmSK.background_(colorStatus[val])}.defer()}
			// {type == "prgSK"} {{prgSK.states_([["P"++(val+1)]])}.defer()}
			{type == "midiBPM"} {{bpmSK.states_([[val.asString]])}.defer()}
			{type == "zone8pattNbr"} {
				if(val != zone8patt.states[0][0].asInt, {
				{zone8patt.states_([[val.asString]]); zone8patt.background_(colorStatus[1])}.defer()
				});
			}
			{type == "zone8pattAct"} { {zone8patt.states_([[val.asString]]); zone8patt.background_(colorStatus[0])}.defer()}
			;
		}, "/lapistatus").fix;

		if(inputPeakChans > 0, {
			inputPeakResp = OSCFunc( {|msg|
				forBy(inputPeakStartChan, inputPeakStartChan+inputPeakChans-1, 1, { |channel|
					var baseIndex = 3 + (2*channel);
					var rmsValue = msg.at(baseIndex + 1);
					var value = rmsValue.ampdb.linlin(-80, 0, 0, 1);
					{
						if(value > 0.1) { bInputPeak[channel].value = 1 };
						if(value < 0.05) { bInputPeak[channel].value = 0 };
					}.defer();
				});
			}, ("/localhostInLevels").asSymbol).fix;
		});

		if(localWin == 1, {
			win.front;
		});

	}

	stop
	{
		//	"Removing OSC responder".postln;
		OSCdef(\lapisStatus).remove;
		inputPeakResp.remove;
	}

}