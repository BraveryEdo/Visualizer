//http://forum.processing.org/two/discussion/1836/how-to-smooth-audio-fft-data
//http://code.compartmental.net/minim/examples/AudioEffect/LowPassFSFilter/LowPassFSFilter.pde

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

int pattern = 0;
int num_patt;
int sample_rate = 1024;
//int used_in = sample_rate/2 + 1;
int used_in = 180;


boolean testing = false;
float t = 0;
float[] rreal;
float[] rimaginary;
float[] lreal;
float[] limaginary;
float[] levels;
float[] plevels;
float[] bars;
int bar_height = 10;
int num_bars = 50;
float[] TS_mag;
float[] TS_freq;
int TS_w = 3;
int TS_n = 60;
float spec_x = 2.75;

int specSize;
float decay = 1.2;
float smooth = 1;

void setup() {
  size(1400, 700);
  frameRate(60);
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
}

void draw() {
  background(0);

  //update the buffer of audio data
  rfft.forward(in.right);
  lfft.forward(in.left);

  rreal = rfft.getSpectrumReal();
  lreal = rfft.getSpectrumReal();

  rimaginary = rfft.getSpectrumImaginary();
  limaginary = rfft.getSpectrumImaginary();

  float bandBucket;
  int c = 0;
  int w = rimaginary.length/used_in -1;

  // combine right and left channels, decay if a frequency has lost intensity
  for (int i = 1; i < used_in + 1; i++) {
    bandBucket = 0;
    float bandMax = 0;
    int e = 0;
    
    if (i == used_in) {
      e = rimaginary.length%used_in;
    }
    for (int q = 0; q < w + e -1; q++) {
      float rband = 10*log((sq(rreal[i*w+q]) + sq(rimaginary[i*w+q])))/log(10);
      float lband = 10*log((sq(lreal[i*w+q]) + sq(limaginary[i*w+q])))/log(10);
      float band = (rband+lband)/2;
      bandBucket += band;
      bandMax = max(bandMax, band);
    }

    levels[i-1] -= decay;    //maybe remove this :: see decay in next for loop
    if (levels[i-1] < bandBucket/w+e){
      levels[i-1] = (bandBucket/w+e)*2/3+bandMax/3;
    }
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
        TS_mag[top_c] = min(60, levels[i]);
        TS_freq[top_c++] = 0;
      } else {
        TS_mag[top_c] = levels[i];
        TS_freq[top_c++] = i;
      }
      i += TS_w;
    }
  }

  float r = 50*sin(t);
  float r2 = 50*cos(2*t);
  float s = sin(t);

  stroke(40);
  spectrum();

  topSpec();

  stroke(0);  
  fill((int) random(255), 222, random(255), 100);
  ring(width/2, height/2, 3, 75 + r2/2, 2*t, false);
  fill(31, 182, 222, 100);
  ring(width/2, height/2, 3, 75 + r2/3, 2*t, true);
  fill(200, 180, 0, 100);
  ring(width/2, height/2, 3, 30 + r2/3, PI+2*t, true);
  fill(222, 31, 31, 100);
  ring(width/2, height/2, 3, 8 + r2/3, 2*t, true);
  fill(218, 222, 31, 150);
  ring(width/2, height/2, 6, 100 - r2/1.5, t, true);
  fill(229, 35, 35, 100);
  ring(width/2, height/2, 11, 125, t, true);
  fill(229, 136, 35, 100);
  ring(width/2, height/2, 10, 125, -t, true);
  fill(239, 255, 67, 100);
  ring(width/2, height/2, 12, 125, 1.5*t, true);
  fill(255, 255, 255, 10);
  ring(width/2, height/2, 6, 46 + r/2, t, true);
  ring(width/2, height/2, 6, 48 + r/2, t, true);
  ring(width/2, height/2, 6, 50 + r/2, t, true);
  ring(width/2, height/2, 6, 52 + r/2, t, true);
  fill(0, 0, 0, 0);
  stroke(255);
  equalizerRing(width/2, height/2, num_bars, t);
  ring(width/2, height/2, 100, 177.5, -.75*t+2*s, false);
  ring(width/2, height/2, 100, 175, -.75*t+2*s + PI/100, true);

  t += .02;

  if (testing) {
    stroke(120);
    line(0, height/2, width, height/2);
    line(width/2, 0, width/2, height);
  }
}

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

  //  if(avg > 30 && pattern == 0){
  //    pattern = (int) random(num_patt); 
  //  }

  num_patt = 5;
  if (pattern == 0) {
    for (int i = 0; i < num_bars; i++) {
      bars[i] = levels[i];
    }
  } else if (pattern == 1) {
    for (int i = 0; i < num_bars; i++) {
      bars[i] = 100*sin(2*t+3*i);
    }
  } else if (pattern == 2) {
    for (int i = 0; i < num_bars; i++) {
      bars[i] = 100*(i%2);
    }
  } else if (pattern == 3) {
    for (int i = 0; i < num_bars; i++) {
      bars[i] = 100;
    }
  } else if (pattern == 4) {
    for (int i = 0; i < num_bars; i++) {
      bars[i] = 40+20*(i%2);
    }
    max = 80;
  } else if (pattern == 5) {
    //    for (int m = 0; m < TS_freq.length-1; m++) {
    //      int x1 = (int) (TS_freq[m] + 1);
    //      float f1 = TS_mag[m]; 
    //      int x2 = (int) (TS_freq[m+1] + 1);
    //      float f2 = TS_mag[m+1];
    //      int mx = (x1+x2)/2;
    //      float mf = (f1+f1)/2;
    //      for (int i = x1; i < x2; i++) {
    //        if (i > mf) {
    //        } else {
    //        }
    //      }
    //    }
  }

  float mult = 1;
  if (pattern== 0) mult = 1.25; 

  float o_rot = -.75*t+2*s;
  float i_rad = 187-5*s;
  float o_rad = (200-7*s+max)*mult;
  stroke(255);
  ring(_x, _y, nbars, i_rad, o_rot, false);
  bars(_x, _y, i_rad, 187-5*s, max, t);
  stroke(255);
  ring(_x, _y, nbars, o_rad, o_rot, true);
}

void bars(float _x, float _y, float low, float min, float max, float rot) {

  float angle = TWO_PI / num_bars;
  float a = 0;
  float mult = 1;

  if (max < 50 && max > 12) {
    mult = 55/max;
  }

  float s = (low*PI/num_bars)*.8;
  rectMode(CENTER);

  pushMatrix();
  translate(_x, _y);
  rotate(rot);
  for (int i = 0; i < num_bars; i ++) {
    pushMatrix();
    rotate(a);
    float r = random(255);
    float b = random(255);
    float g = random(255);
    float z = random(5); 
    for (int j = 0; j < bars[i]*mult; j+= bar_height) {
      stroke(r-j, b-j, g-j, 120+z*j);
      rect(0, s+low + j, s, s*2/3);
    }
    popMatrix();
    a+= angle;
  }
  popMatrix();
}

void spectrum() {
  int w = 1; 
  for (int i = 0; i < used_in-w; i+=w) {
    float s = spec_x;
    float s2 = 10;
    //bottom left
    stroke(255-random(5)*i, random(255), random(255), random(20)+5);
    line(s*i, height, s*i, height-plevels[i]*s2);
    line(s*i, height-plevels[i]*s2, s*(i+w), height-plevels[i+w]*s2);

    //top left
    stroke(255-random(2)*i, random(255)+i, random(255), random(20)+5);
    line(s*i, 0, s*i, plevels[i]*s2);
    line(s*i, plevels[i]*s2, s*(i+w), plevels[i+w]*s2);

    //bottom right
    stroke(255-random(5)*i, random(255), random(255), random(20)+5);
    line(width-s*i, height, width-s*i, height-plevels[i]*s2);
    line(width-s*i, height-plevels[i]*s2, width-s*(i+w), height-plevels[i+w]*s2);

    //top right
    stroke(255-random(2)*i, random(255)+i, random(255), random(20)+5);
    line(width-s*i, 0, width-s*i, plevels[i]*s2);
    line(width-s*i, plevels[i]*s2, width-s*(i+w), plevels[i+w]*s2);
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
  stroke(br, bb, bg, ba);

  line(x1, height, x1, height-y1);
  line(x1, height-y1, x2, height-y2);

  //top left
  stroke(tr, tb, tg, ta);

  line(x1, 0, x1, y1);
  line(x1, y1, x2, y2);

  //bottom right
  stroke(br, bb, bg, ba);

  line(width-x1, height, width-x1, height-y1);
  line(width-x1, height-y1, width-x2, height-y2);

  //top right
  stroke(tr, tb, tg, ta);

  line(width-x1, 0, width-x1, y1);
  line(width-x1, y1, width-x2, y2);
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

  pushMatrix();
  translate(_x, _y);
  rotate(rot);
  for (int i = 0; i < _n; i++) {
    float tx = sin(rads)*_r;
    float ty = cos(rads)*_r;
    tri(tx, ty, rads, s, ori);
    rads += diff;
  }
  popMatrix();
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

  pushMatrix();
  translate(_x, _y);

  if (ori) {
    rotate(PI/2.0-_r);
  } else {
    rotate(PI+PI/2.0-_r);
  }

  polygon(0, 0, _s, 3);
  popMatrix();
}

// for creating regular polygons
void polygon(float x, float y, float radius, int npoints) {
  float angle = TWO_PI / npoints;
  beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * radius;
    float sy = y + sin(a) * radius;
    vertex(sx, sy);
  }
  endShape(CLOSE);
}

void mouseClicked() {
  pattern = (int) random(num_patt);
}

void stop() {
  in.close();
  minim.stop();
}

