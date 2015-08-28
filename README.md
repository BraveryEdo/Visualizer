# Visualizer

    Open and run tri.pde with Processing @ https://processing.org/.
    
	With version 3.0 the minim audio processing library needs to be installed explicitly.
	
	go to sketch -> Import Library -> New -> search for minim and install it.
	
    Run with music on, click on the visualizer to see some different bar effects.
    
    If it responds slowly on your processor, try lowering the sample_rate/used_in values.
    
    The visualizer is monitoring the default recording device which is usually your microphone.
    With some hardware set ups you can set the default recording device as the stereo mix going to your speakers/headphones.
    You can change that settings in control panel -> sound -> recording ; right-click, show disabled devices, and set Stereo Mix to default device.

    If you can't set Stereo Mix as the default recording device you will need to reroute the audio using a program like Jack or SoundFlower.

    Alternatively you can see it react to noise through the microphone.


Currently working on:

    Rescaling the spectrum of sound for each of the different visual parts reacts to.
    
    Removing segments that cross over other lines from one end to the other in low poly patterns.

    Varying background styles.

    Varying bar styles.

    Beat detection.