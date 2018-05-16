// Clock

(
~setClock = {
	arg interval = 30;
	var task = {
		inf.do { |count|
			('### ' ++ (count * interval).asTimeStringHM).postln;
			interval.wait;
		}
	};
	var clock = Task(task);
	clock
};
)
