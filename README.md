# Lapis
Laptop Instrument built by Robert van Heumen.

This instrument is used with a joystick, 3 Faderfox MIDI controllers, a volume pedal through an Arduino and an AKAI MPK controller. 

To run the instrument, open SuperCollider and run this:

// Lapis instrument
(
~lisa = "LiveSampler.scd";
~sk = "SynthKeysMPK.scd";
"Lapis/InOut.scd".loadRelative();
)

// Simulacrum to simulate the physical controllers
"Lapis/FF-E3D-simulMPK.scd".loadRelative();

The file GlobalVars.scd contains the configuration of the instrument. There is additional configuration in LiveSampler.scd, InOut.scd and SynthKeysMPK.scd. The only reference to files and folders outside the folder where this README.md resides is the sample directory specified in LiveSampler.scd (read the next section for specifics). 

How sample files are connected to the load-buttons on the controller:
1. GlobalVars.scd: the ~projectId is specified from a list containing projectnames
2. LiveSampler.scd: cfg.sampleDir specifies a root folder for samples
3. /Data/SampleLists/ contains files by projectname, as specified in step 1
4. The file paths specified in these files are relative to the root folder set in step 2

To use the internal IAC MIDI bus, this has to be enabled in the Audio-MIDI setup application (that should be available in the macOS). The ports are named ‘IAC Bus 1’, ‘IAC Bus 2’, ‘IAC Bus 3’. 

This project depends on the rvh-lib library (on Github) and the quarks wslib, XML, arduino, crucialviews and possibly Feedback, FreeAfter and Freesound.