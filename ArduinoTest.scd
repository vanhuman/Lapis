
(
var portName, ardSms;
["Serial", SerialPort.devices].postln;
portName = SerialPort.devices.detect{|x| x.contains("tty.usb")};

if(portName.notNil, {
	("Connected to serial port" + portName ++ ".").postln;
	~ardSms = ArduinoSMS(portName, 115200);
	~ardSms.action = {
		| ... msg |
		msg.postln;
	};
	~ardTask = Task({
		inf.do { ~ardSms.send($r);  0.05.wait; } // where $r is the Char r
	});
	~ardTask.start;

});
)

~ardTask.stop;
~ardSms.close