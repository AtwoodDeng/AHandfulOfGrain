import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioInput in;
color white;
FFT   fft;


final int LENGTH = 512;
float[] value = new float[LENGTH];
final float noise = 0.01;


final int searchRange = 50;
final float filter = 0.35;

final int conflictRange = 20;

Boolean ifRecord = false;
int recordCount = 0 ;

void setup()
{
  // set up the screen
  size(512, 500, P2D);
  white = color(255);
  colorMode(HSB,100);
  
  // set up minim
  minim = new Minim(this);
  minim.debugOn();
  
  // get a line in from Minim, default bit depth is 16
  in = minim.getLineIn(Minim.STEREO, 512);
  fft = new FFT( in.bufferSize() , in.sampleRate() );
  background(0);
  
  for(int i = 0 ; i < 256 ; ++ i )
    value[i] = 0;
}

float[] getSpecAnalyze()
{
  // get fft
  fft.forward(in.mix);
  // get spectrum
  float[] spec = new float[fft.specSize()];
  for(int i = 0 ; i < spec.length ; ++ i )
    spec[i] = fft.getBand(i);
    
  //filter by 0.1 * max
  float max = 0;
  for (int i = 0 ; i < spec.length  ; ++ i )
  {
    if (max < spec[i] ) max = spec[i];
  }
  for (int i = 0 ; i < spec.length  ; ++ i )
  {
    if (spec[i] < max * 0.1)
      spec[i] = 0;
  }
  
    
  //filter spec
  float[] spec2 = new float[spec.length];
  spec2[0] = 0;
  spec2[spec2.length-1] = 0;
  
  
  // step 1
  // 2 * a_n^2 - a_n-1^2 - a_n+1^2
  for (int i = 1 ; i < spec2.length-1 ; ++i )
  {
    if (spec[i] == 0)
      spec2[i] = 0 ;
    else
    {
    spec2[i] = 2 * sq(spec[i]) - sq(spec[i-1]) - sq(spec[i+1]);
    if (spec2[i] < 0 )
      spec2[i] = 0 ;
    } 
  }
  
  // step 2
  // search range and filter by 0.2
  float[] spec3 = new float[spec2.length];
  int count3 = 0;
  for (int i = 0 ; i < spec2.length ; ++i )
  {
    Boolean ifUse = true;
    if (spec2[i] == 0 )
     ifUse = false;
    for(int j = i - searchRange / 2 ; j < i + searchRange / 2  ; ++j )
    {
      if (j > 0 && j < spec2.length  && i != j )
      {
        if (spec2[i] < spec2[j] * filter)
          ifUse = false;
      }
    }
    if (ifUse)
    {
      spec3[i] = 1;
      count3 ++;
    }
    else
      spec3[i] = 0;
  }
  
  //step 3
  //search range and filter by 1
  
  float[] spec4 = new float[spec3.length];
  int count = 0;
  for (int i = 0 ; i < spec3.length ; ++i )
  {
    Boolean ifUse = true;
    if (spec3[i] == 0 )
     ifUse = false;
    for(int j = i - conflictRange / 2 ; j < i + conflictRange / 2  ; ++j )
    {
      if (j > 0 && j < spec3.length  && i != j )
      {
        if (spec2[i] < spec2[j] )
          ifUse = false;
      }
    }
    if (ifUse)
    {
      spec4[i] = spec2[i];
      count ++;
    }
    else
      spec4[i] = 0;
  }
  
  return spec4;
}

void draw()
{
  background(0);
  // draw the waveforms
  for(int i = 0; i < in.bufferSize() - 1; i++)
  {
    stroke((1+in.left.get(i))*50,100,100);
    line(i, 50 + in.left.get(i)*50, i+1, 50 + in.left.get(i+1)*50);
    stroke(white);
    line(i, 100 + in.right.get(i)*50, i+1, 100 + in.right.get(i+1)*50);
  }
  
  fft.forward(in.left);
  
  for(int i = 0 ; i < fft.specSize() ; i++)
  {
     // draw the line for frequency band i
     line( i , 150 + fft.getBand(i) * 4 , i , 150 - fft.getBand(i) * 4);
  }
  
    fft.forward(in.right);
  
  stroke(#AAAA00);
  for(int i = 0 ; i < fft.specSize() ; i++)
  {
     // draw the line for frequency band i
     line( i , 200 + fft.getBand(i) * 4 , i , 200);
  }
  
  float[] spec = new float[fft.specSize()];
  for(int i = 0 ; i < spec.length ; ++ i )
    spec[i] = fft.getBand(i);
    
  float ave = 0;
  float max = 0;
  for (int i = 0 ; i < spec.length  ; ++ i )
  {
    spec[i] = abs( spec[i] );
    ave += abs(spec[i]); 
    if (spec[i] < noise)
      spec[i] = 0;
    if (max < spec[i] ) max = spec[i];
  }
  ave /= spec.length/2;
  for (int i = 0 ; i < spec.length  ; ++ i )
  {
    if (spec[i] < max * 0.1)
      spec[i] = 0;
  }
  
  //filter spec
  float[] spec2 = new float[spec.length];
  spec2[0] = 0;
  spec2[spec2.length-1] = 0;
  
  for (int i = 1 ; i < spec2.length-1 ; ++i )
  {
    if (spec[i] == 0)
      spec2[i] = 0 ;
    else
    {
    spec2[i] = 2 * sq(spec[i]) - sq(spec[i-1]) - sq(spec[i+1]);
    if (spec2[i] < 0 )
      spec2[i] = 0 ;
    }
    
  }
    
  stroke(#00AA00);
  for(int i = 0 ; i < spec2.length ; i++)
  {
     // draw the line for frequency band i
     line( i , 250 + spec2[i] *4 , i , 250);
  }
  
  // 2 
  float[] spec3 = new float[spec2.length];
  int count3 = 0;
  for (int i = 0 ; i < spec2.length ; ++i )
  {
    Boolean ifUse = true;
    if (spec2[i] == 0 )
     ifUse = false;
    for(int j = i - searchRange / 2 ; j < i + searchRange / 2  ; ++j )
    {
      if (j > 0 && j < spec2.length  && i != j )
      {
        if (spec2[i] < spec2[j] * filter)
          ifUse = false;
      }
    }
    if (ifUse)
    {
      spec3[i] = 1;
      count3 ++;
    }
    else
      spec3[i] = 0;
  }
  
  stroke(#AA0000);
  for(int i = 0 ; i < spec3.length ; ++i)
  {
     // draw the line for frequency band i
     line( i , 300 + spec3[i] * 9 , i , 300 );
  }
   line( 0 , 330 , count3 , 330 );
  
  //3
  
  
  float[] spec4 = new float[spec3.length];
  int count = 0;
  for (int i = 0 ; i < spec3.length ; ++i )
  {
    Boolean ifUse = true;
    if (spec3[i] == 0 )
     ifUse = false;
    for(int j = i - conflictRange / 2 ; j < i + conflictRange / 2  ; ++j )
    {
      if (j > 0 && j < spec3.length  && i != j )
      {
        if (spec2[i] < spec2[j] )
          ifUse = false;
      }
    }
    if (ifUse)
    {
      spec4[i] = 1;
      count ++;
    }
    else
      spec4[i] = 0;
  }
  
  stroke(#7700AA);
  for(int i = 0 ; i < spec4.length ; ++i)
  {
     // draw the line for frequency band i
     line( i , 350 + spec4[i] * 9 , i , 350 );
  }
   line( 0 , 370 , count , 370 );

  if (ifRecord)
  {
    recordCount ++;
    for(int i = 0 ; i < spec4.length ; ++i)
    {
      value[i] += spec4[i];
    }
    
  }
  
  stroke(#6677FF);
  for(int i = 0 ; i < value.length ; ++i)
  {
     // draw the line for frequency band i
     line( i , 400 + value[i] / recordCount * 10 , i , 400 );
  }
  
}

int printCount = 0 ;
void keyPressed() {
  if (key == ' ')
  {
    ifRecord = !ifRecord;
  }
  if (key == 'p')
  {
    PrintWriter output = createWriter("output " + str(minute()) + ':' + str(second())+".txt");
    for(int i = 0 ; i < LENGTH / 2 ; ++ i )
    {
       output.print(i);
       output.print(' ');
       output.println(value[i]/recordCount);
    }
    output.flush();
    output.close();
  }
  if (key=='q')
   exit();
   
  if (key == 'r')
  {
    for(int i = 0 ; i < value.length; ++i )
     value[i] = 0;
  }
  
}

void stop()
{
  // always close Minim audio classes when you are done with them
  in.close();
  minim.stop();
  super.stop();
}