/* Credits *
 Threaded Framework Author: Artur Fast
 email: www.SchirmCharmeMelone@gmail.com
 
 http://forum.processing.org/two/discussion/1836/how-to-smooth-audio-fft-data
 http://code.compartmental.net/minim/examples/AudioEffect/LowPassFSFilter/LowPassFSFilter.pde
 
 */

//import and generate Semaphores
import java.util.concurrent.Semaphore;
static Semaphore semaphoreExample = new Semaphore(1); 
//audio proccessing imports
import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

Minim minim;
AudioInput in;
FFT rfft;
FFT lfft;

// GLOBAL DATA


// test values for printing highs/lows
boolean testing = false;
float llow = 99999;
float hhigh = -99999999;

int pattern = 0;
int num_patt;
int sample_rate = 4096;
//int used_in = sample_rate/2 + 1;
int used_in = 300;

float t = 0;
//real and imaginary elements of the fft algorithm for right and left channels
float[] rreal;
float[] rimaginary;
float[] lreal;
float[] limaginary;

//fft values translated to audio levels
//current goal level
float[] levels; 
//previous goal levels
float[] plevels;
//levels for audio bars
float[] bars;
int bar_height = 5;
//number of bins displaying audio levels
int num_bars = 100;
//number of triangles in the outer ring
int num_tri_oring = 50;
//magnitude and frequency used by the topspec function (displays peak values for the background spectrum
float[] TS_mag;
float[] TS_freq;

//min width between peak values
int TS_w = 3;
//number of values top spec looks for
int TS_n = 60;
//spacing between each frequency for the spectrogram
float spec_x = 2.75;

int specSize;
float decay = 1.2;
float smooth = 1.12;



//graphics object we will use to buffer our drawing
PGraphics graphics;

//window dimensions
int multiplicator = 80;
int window_x = 16*multiplicator;
int window_y = 9*multiplicator;


int lastCallLogic = 0; //absolute time when logic thread was called
int lastCallRender = 0; //lastCallRender
int lastCallMisc = 0;

//time passed since last call
int deltaTLogic = 0;
int deltaTRender = 0;

//how often we already called the threads
int countLogicCalls = 0;
int countRenderCalls = 0;

//used to know  how many calls since last fps calculation
int countLogicCallsOld = 0;
int countRenderCallsOld = 0;


/*
Warning! Vsync of your graphics card could reduce your logic fps or your render  fps to your monitor refresh rate!
 Warning! you may even want to have Vsync, i cant help you here.
 */

//framerate of Logic/Render threads
//-1 to run as fast as  possible. be prepared to melt your pc!
int framerateLogic = 300;
int framerateRender = 240;

int framerateMisc = 1; //how often the framerate display will be updated



void setup() {

  //init window
 // size(window_x, window_y); //creates a new window
 size(1280, 720);
  graphics = createGraphics(window_x, window_y);//creates the draw area
  frameRate(framerateRender); //tells the draw function to run

  smooth();

  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, sample_rate);
  rfft = new FFT(in.bufferSize(), in.sampleRate());
  lfft = new FFT(in.bufferSize(), in.sampleRate());
  rfft.logAverages(60, 7);
  lfft.logAverages(60, 7);
  specSize = lfft.specSize();

  levels = new float[used_in];
  plevels = new float[used_in];
  rreal = new float[specSize];
  rimaginary = new float[specSize];
  lreal = new float[specSize];
  limaginary = new float[specSize];
  bars = new float[num_bars];
  TS_freq = new float[TS_n];
  TS_mag = new float[TS_n];

  /*
  why we use createGraphics:
   
   Unlike the main drawing surface which is completely opaque, surfaces created with createGraphics() can have transparency.
   This makes it possible to draw into a graphics and maintain the alpha channel. By using save() to write a PNG or TGA file,
   the transparency of the graphics object will be honored.
   
   from: https://www.processing.org/reference/createGraphics_.html
   
   */


  //start Threads
  //Start a Thread for Logic!
  //Use this one for your logic calculations!
  logicThread.start();

  //start the graphics Thread!
  //actually we render in the main Thread. opengl and lots of other render stuff want to run in the main Thread.
  //Therefore we dont start a new thread and will put the drawing into processings draw() method.
  println(Thread.currentThread().getName() +" : the MainThread is running and used to Render");

  //start the misc Thread. it counts the fps etc.
  //use this for wierd stuff like counting fps and all weird things you can think of that doesnt belong into logic nor rendering
  miscThread.start();
}

//draw function. This is our Render Thread
void draw() {

  countRenderCalls++;

  graphics.beginDraw();


  /*
      all drawing calls have to be called from the graphics object.
   so graphics.line(0,0,100,100) instead of line(0,0,100,100)
   */
  //-------------

  //CODE TO DRAW GOES HERE

  graphics.background(0);

  float r = 50*sin(t);
  float r2 = 50*cos(2*t);
  float s = sin(t);
  graphics.stroke(40);
  spectrum();

  topSpec();

  graphics.stroke(0);  
  graphics.fill((int) random(255), 222, random(255), 100);
  ring(width/2, height/2, 3, 75 + r2/2, 2*t, false);
  graphics.fill(31, 182, 222, 100);
  ring(width/2, height/2, 3, 75 + r2/3, 2*t, true);
  graphics.fill(200, 180, 0, 100);
  ring(width/2, height/2, 3, 30 + r2/3, PI+2*t, true);
  graphics.fill(222, 31, 31, 100);
  ring(width/2, height/2, 3, 8 + r2/3, 2*t, true);
  graphics.fill(218, 222, 31, 150);
  ring(width/2, height/2, 6, 100 - r2/1.5, t, true);
  graphics.fill(229, 35, 35, 100);
  ring(width/2, height/2, 11, 125, t, true);
  graphics.fill(229, 136, 35, 100);
  ring(width/2, height/2, 10, 125, -t, true);
  graphics.fill(239, 255, 67, 100);
  ring(width/2, height/2, 12, 125, 1.5*t, true);
  graphics.fill(255, 255, 255, 10);
  ring(width/2, height/2, 6, 46 + r/2, t, true);
  ring(width/2, height/2, 6, 48 + r/2, t, true);
  ring(width/2, height/2, 6, 50 + r/2, t, true);
  ring(width/2, height/2, 6, 52 + r/2, t, true);
  graphics.fill(0, 0, 0, 0);
  graphics.stroke(255);
  equalizerRing(width/2, height/2, num_bars, t);
  ring(width/2, height/2, 100, 177.5, -.75*t+2*s, false);
  ring(width/2, height/2, 100, 175, -.75*t+2*s + PI/100, true);

  t += .02;

  if (testing) {
    graphics.stroke(120);
    graphics.line(0, height/2, width, height/2);
    graphics.line(width/2, 0, width/2, height);
  }

  //-------------
  graphics.endDraw();
  image(graphics, 0, 0);
  //no sleep calculation here because processing  is doing  it for us already
}


//Pretty ugly way  to create a new Thread. There is a nicer way
//in java 8 but because of backward compatibility we write code  that also  runs in java7
// Passing a Runnable when creating a new thread
Thread logicThread = new Thread(new Runnable() {
  public void run() {
    System.out.println(Thread.currentThread().getName() + " : the logicThread is running");

    //main Logic loop
    while (true) {


      countLogicCalls++;
      //------------
      //CODE FOR LOGIC  GOES HERE

      //update the buffer of audio data
      rfft.forward(in.right);
      lfft.forward(in.left);

      rreal = rfft.getSpectrumReal();
      lreal = rfft.getSpectrumReal();

      rimaginary = rfft.getSpectrumImaginary();
      limaginary = rfft.getSpectrumImaginary();

      // combine right and left channels, decay if a frequency has lost intensity
      for (int i = 1; i < used_in + 1; i++) {

        float rband = 10*log((sq(rreal[i]) + sq(rimaginary[i])))/log(10);
        float lband = 10*log((sq(lreal[i]) + sq(limaginary[i])))/log(10);
        float band = max(0, (rband+lband)/2);


        if (testing) {
          if (band < llow) {
            llow = band;
            println("new low: ", llow);
          }

          if (band > hhigh) {
            hhigh = band;
            println("new high: ", hhigh);
          }
        }

        levels[i-1] -= decay;
        if (levels[i-1] < band) levels[i-1] = band;
      }

      int top_c = 0;

      // smoothing
      for (int i = 0; i < used_in; i++) {
        float diff = levels[i]-plevels[i];
        if (diff > 0) {
          diff = max(diff/smooth, 0);
        } else {
          diff = min(-decay, diff);
        }
        plevels[i] = levels[i];
        levels[i] += diff;

        boolean include = false;

        if (i > 0 && ((i == 1 || i == used_in-1) || //end points
        ((levels[i-1] < levels[i] && levels[i] > levels[i+1]) || // maxima
        (levels[i-1] > levels[i] && levels[i] < levels[i+1]))
          && levels[i] >= 0)) { //minima
          include = true;
        }

        if (levels[i] > 0 && include && top_c < TS_n) {
          if (i == 1) {
            TS_mag[top_c] = min(100, levels[i]);
            TS_freq[top_c++] = 0;
          } else {
            TS_mag[top_c] = levels[i];
            TS_freq[top_c++] = i;
          }
          i += TS_w;
        }
      }

      //------------
      //framelimiter
      int timeToWait = 1000/framerateLogic - (millis()-lastCallLogic); // set framerateLogic to -1 to not limit;
      if (timeToWait > 1) {
        try {
          //sleep long enough so we aren't faster than the logicFPS
          Thread.currentThread().sleep( timeToWait );
        }
        catch ( InterruptedException e )
        {
          e.printStackTrace();
          Thread.currentThread().interrupt();
        }
      }
      /*
      example why we wait excactly: 1000/framerate - (millis-lastcall)
       
       framerate = 100 //framerate we want
       1000/framerate = 10 //time for one loop
       millis = 1952 //current time
       last call logic = 1949 //time when last logic loop finished
       
       how  long should the programm wait??
       
       millis-lastcall = 3 -> the whole loop took 3ms
       
       1000/framerate - (millis-lastcall) = 7ms -> we will have to wait 7ms to keep a framerate of 100
       
       */

      //remember when the last logic loop finished
      lastCallLogic = millis();


      //End of main logic loop
    }
  }
}
);


// Passing a Runnable when creating a new thread
Thread miscThread = new Thread(new Runnable() {
  public void run() {
    System.out.println(Thread.currentThread().getName() + " : the miscThread is running");
    /*
you can access all variables that are defined in main!
     how wunderful and convienent to create lots of global variables! ... im sorry :D
     */



    //main misc loop
    while (true) {

      //-------------      


      /*
    This is a thread for miscellaneaous calculations like fps etc.
       i moved it into an own thread to reduce slow downs
       */


      //fps calculation goes here
      frame.setTitle("logicFPS: " + (countLogicCalls-countLogicCallsOld) +" RenderFps: " + (countRenderCalls-countRenderCallsOld)); //Set the frame title to the frame rate
      countLogicCallsOld = countLogicCalls;
      countRenderCallsOld =countRenderCalls;

      //----------




      //-------------



      //framelimiter
      int timeToWait = 1000/framerateMisc - (millis()-lastCallMisc); // set to -1 to not limit
      if (timeToWait > 1) {
        try {
          //sleep long enough so we aren't faster than the logicFPS
          Thread.currentThread().sleep( timeToWait );
        }
        catch ( InterruptedException e )
        {
          e.printStackTrace();
          Thread.currentThread().interrupt();
        }
      }
      /*
      example why we wait excactly: 1000/framerate - (millis-lastcall)
       
       framerate = 100
       
       1000/framerate = 10
       
       millis = 1952
       lastcall = 1949
       
       how  long should the programm wait??
       
       millis-lastcall = 3 -> the whole excetion took 3ms
       
       1000/framerate - (millis-lastcall) = 7ms -> we will have to wait 7ms to keep a framerate of 100
       
       */


      lastCallMisc = millis();

      //End of main misc loop
      // yes here have to be 4 paranthesis
    }
  }
}
);



// makes a ring equalizer that displays the levels array on bars number of outputs
void equalizerRing(float _x, float _y, int nbars, float t) {

  float s = sin(t);
  float max = 0;
  float min = 99999;
  float lmax = 0;
  float lmin = 99999;
  int q = 0;

  float avg = 0;

  for (int i = 1; i < num_bars; i++) {
    float l = bars[i];
    if (l > max) {
      q = i;
    }
    avg += l;
    max = max(l, max);
    min = min(l, min);
  }

  avg /= num_bars;

  num_patt = 5;
  if (pattern == 0) {
    for (int i = 0; i < num_bars; i++) {
      bars[i] = levels[i];
    }
  } else if (pattern == 1) {
    // wave traverse the bars
    for (int i = 0; i < num_bars; i++) {
      bars[i] = 100*sin(2*t+3*i);
    }
  } else if (pattern == 2) {
    // alternating bar heights (0 or 100)
    for (int i = 0; i < num_bars; i++) {
      bars[i] = 100*(i%2);
    }
  } else if (pattern == 3) {
    // all max bar height
    for (int i = 0; i < num_bars; i++) {
      bars[i] = 100;
    }
  } else if (pattern == 4) {
    // alternating bar heights (40 or 60)
    for (int i = 0; i < num_bars; i++) {
      bars[i] = 40+20*(i%2);
    }
    max = 80;
  } else if (pattern == 5) {
    /*  for (int m = 0; m < TS_freq.length-1; m++) {
     int x1 = (int) (TS_freq[m] + 1);
     float f1 = TS_mag[m]; 
     int x2 = (int) (TS_freq[m+1] + 1);
     float f2 = TS_mag[m+1];
     int mx = (x1+x2)/2;
     float mf = (f1+f1)/2;
     for (int i = x1; i < x2; i++) {
     if (i > mf) {
     } else {
     }
     }
     }*/
  }


  float o_rot = -.75*t+2*s;
  float i_rad = 187-5*s;
  float o_rad = (200-7*s+max);
  graphics.stroke(255);
  ring(_x, _y, nbars, i_rad, o_rot, false);
  bars(_x, _y, i_rad, 187-5*s, max, t);
  graphics.stroke(255);
  ring(_x, _y, num_tri_oring, o_rad, o_rot, true);
}

void bars(float _x, float _y, float low, float min, float max, float rot) {

  float angle = TWO_PI / num_bars;
  float a = 0;
  float mult = 1;

  if (max < 50 && max > 12) {
    mult = 55/max;
  }

  float s = (low*PI/num_bars)*.8;
  graphics.rectMode(CENTER);

  graphics.pushMatrix();
  graphics.translate(_x, _y);
  graphics.rotate(rot);
  for (int i = 0; i < num_bars; i ++) {
    graphics.pushMatrix();
    graphics.rotate(a);
    float r = random(255);
    float b = random(255);
    float g = random(255);
    float z = random(5); 
    for (int j = 0; j < bars[i]*mult; j+= bar_height) {
      graphics.stroke(r-j, b-j, g-j, 120+z*j);
      graphics.rect(0, s+low + j, s, s*2/3);
    }
    graphics.popMatrix();
    a+= angle;
  }
  graphics.popMatrix();
}

void spectrum() {
  int w = 1; 
  for (int i = 0; i < used_in-w; i+=w) {
    float s = spec_x;
    float s2 = 10;
    //bottom left
    graphics.stroke(255-random(5)*i, random(255), random(255), random(20)+5);
    graphics.line(s*i, height, s*i, height-plevels[i]*s2);
    graphics.line(s*i, height-plevels[i]*s2, s*(i+w), height-plevels[i+w]*s2);

    //top left
    graphics.stroke(255-random(2)*i, random(255)+i, random(255), random(20)+5);
    graphics.line(s*i, 0, s*i, plevels[i]*s2);
    graphics.line(s*i, plevels[i]*s2, s*(i+w), plevels[i+w]*s2);

    //bottom right
    graphics.stroke(255-random(5)*i, random(255), random(255), random(20)+5);
    graphics.line(width-s*i, height, width-s*i, height-plevels[i]*s2);
    graphics.line(width-s*i, height-plevels[i]*s2, width-s*(i+w), height-plevels[i+w]*s2);

    //top right
    graphics.stroke(255-random(2)*i, random(255)+i, random(255), random(20)+5);
    graphics.line(width-s*i, 0, width-s*i, plevels[i]*s2);
    graphics.line(width-s*i, plevels[i]*s2, width-s*(i+w), plevels[i+w]*s2);
  }
}


void topSpec() {
  float h = 0;
  float s = spec_x;
  float s2 = 7;

  if (TS_freq[0] != 0) {
    fourLine(0, 0, s*TS_freq[0], s2*TS_mag[0], 
    255*sin(h), random(255), random(255), random(80)+95, 
    255*sin(h), random(255), random(255), random(110)+55);
  }

  for (int i = 0; i < TS_n-1; i++) {

    TS_mag[i+1] = TS_mag[i+1]/2.75;

    float tr = 255*sin(h) - random(5)*i;//255-random(2)*i
    float tb = random(255);
    float tg = random(255);

    float br = 255*sin(PI-h) + random(5)*i;//255-random(5)*i
    float bb = random(255);
    float bg = random(255);

    float ba  = random(80)+95-i*2;
    float ta = random(110)+55;

    h += .05;

    fourLine(s*TS_freq[i], TS_mag[i]*s2, s*TS_freq[i+1], TS_mag[i+1]*s2, tr, tb, tg, ta, br, bb, bg, ba);

    TS_mag[i]--;
  }
  TS_mag[TS_n-1]--;
}

void fourLine(float x1, float y1, float x2, float y2, float tr, float tb, float tg, float ta, float br, float bb, float bg, float ba) {
  //bottom left
 graphics.stroke(br, bb, bg, ba);

  graphics.line(x1, height, x1, height-y1);
  graphics.line(x1, height-y1, x2, height-y2);

  //top left
  graphics.stroke(tr, tb, tg, ta);

  graphics.line(x1, 0, x1, y1);
  graphics.line(x1, y1, x2, y2);

  //bottom right
  graphics.stroke(br, bb, bg, ba);

  graphics.line(width-x1, height, width-x1, height-y1);
  graphics.line(width-x1, height-y1, width-x2, height-y2);

  //top right
  graphics.stroke(tr, tb, tg, ta);

  graphics.line(width-x1, 0, width-x1, y1);
  graphics.line(width-x1, y1, width-x2, y2);
}


//creates a ring of outward facing triangles
void ring(float _x, float _y, int _n, float _r, float rot, Boolean ori) {
  // _x, _y = center point
  // _n = number of triangles in ring
  // _r = radius of ring (measured to tri center point)
  // ori = orientation true = out, false = in
  if (testing) {
    println("\nring: ", _x, ", ", _y, " #", _n, " radius:", _r);
  }

  float rads = 0;
  float s = (_r*PI/_n)*.9;
  float diff = TWO_PI/_n; 

  graphics.pushMatrix();
  graphics.translate(_x, _y);
  graphics.rotate(rot);
  for (int i = 0; i < _n; i++) {
    float tx = sin(rads)*_r;
    float ty = cos(rads)*_r;
    tri(tx, ty, rads, s, ori);
    rads += diff;
  }
  graphics.popMatrix();
}

//creates an triangle with its center at _x, _y rotated by _r
void tri(float _x, float _y, float _r, float _s, boolean ori) {
  // _x, _y = center point
  // _r = rotation (radians)
  // _s = triangle size (edge length in pixels)
  // ori = determines if it starts pointed up or down

  if (testing) {
    println("triangle: ", _x, ", ", _y, " rot: ", (int) _r*360/PI, " s: ", _s, "ori: ", ori);
  }

  graphics.pushMatrix();
  graphics.translate(_x, _y);

  if (ori) {
    graphics.rotate(PI/2.0-_r);
  } else {
    graphics.rotate(PI+PI/2.0-_r);
  }

  polygon(0, 0, _s, 3);
  graphics.popMatrix();
}

// for creating regular polygons
void polygon(float x, float y, float radius, int npoints) {
  float angle = TWO_PI / npoints;
  graphics.beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * radius;
    float sy = y + sin(a) * radius;
    graphics.vertex(sx, sy);
  }
  graphics.endShape(CLOSE);
}

void mouseClicked() {
  pattern = (int) random(num_patt);
}

void stop() {
  in.close();
  minim.stop();
}