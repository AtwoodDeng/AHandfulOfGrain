import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioInput in;
FFT   fft;

ArrayList<Road> roads = new ArrayList<Road>();
ArrayList<Car> cars = new ArrayList<Car>();


int WIDTH = 1024;
int HEIGHT = 800;
int[][] space = new int[WIDTH][HEIGHT];

final int ROAD_TYPE = 1;
final int NONE_TYPE = -1;

   
float initRate = 0;
final float initRateInit = 5;
final float initRateIntense= 5;
final float initRateGain = 0.5;
final int growMin = 3;
final int growMax = 7;
final int lengthMin = 10;
final int lengthMax = 65;
final int carRadiusMin = 3;
final int carRadiusMax = 25;
final int carColorDiff = 30;


final int roadWeight = 3;

float[] specAna = new float[257];

float[][] grainVector = new float[5][256];
String[] grainFile = {"rice-c.txt","garbanzo-c.txt","blackbean-c.txt","green-c.txt","quinoa-c.txt"};
float[] grainTop = {3.5,2,2,10,2};

float[] grainValue = new float[5];
float[] grainValueEnvironment = new float[5];
Boolean ifRecordEnvironment = false;
Boolean ifStart = false;

int roadCount=0;

float roadAlpha = 0.02;
float carAlpha = 0.02;

color roadColor = #FFFFFF;
color carColor = #ffffff;
float[] grainColor = {60,0,180,120,250,300};
float tempH = 180;

float grainThreshod = 1.5;

void setup()
{
  //size(1024, 800,FX2D);
  colorMode(HSB,360,100,100);
  fullScreen();
  
  roadColor = color(tempH,80,50);
  carColor = color(tempH,80,75);
  // set up road
  Point initPos = new Point(width/2,height/2);
  Road initR = new Road(initPos.x,initPos.y,initPos.x+1,initPos.y+1,3,null);
  
  WIDTH = width;
  HEIGHT = height;
  space = new int[WIDTH][HEIGHT];
  
  for(int i = 0 ; i < WIDTH; ++i)
  for(int j = 0 ; j < HEIGHT; ++j)
    space[i][j] = NONE_TYPE;
  
  roads.add(initR);
  
  // set up audio
  
  // set up minim
  minim = new Minim(this);
  minim.debugOn();
  
  // get a line in from Minim, default bit depth is 16
  in = minim.getLineIn(Minim.STEREO, 512);
  fft = new FFT( in.bufferSize() , in.sampleRate() );
  
  
  // init grain values
  initGrainValue();
  
  // set up background
  background(0);
  
}

void draw()
{
  updateGrainValue();
  if (ifStart)
  {
    grainEffect();
    updateRoad();
    drawRoad();
    updateCar();
    drawCar();
  }else if (ifRecordEnvironment)
  {
    recordEnvironmentSound();
  }
}

void drawRoad()
{
  for (int i = 0; i < roads.size(); i++) {
    Road r = roads.get(i);
    r.display();
  }
}

void updateRoad()
{
  for (int i = 0; i < roads.size(); i++) {
    Road r = roads.get(i);
    r.update();
  }
  
}

void  grainEffect()
{
  initRate = initRateInit;
  for(int i = 0 ; i < 5 ; ++ i )
  {
    float gain = getProperty(grainValue,i) / getProperty(grainValueEnvironment,i);
    float gainValue = (gain - 1 ) / ( grainTop[i] - 1 ) * initRateIntense;
    //println(i,gainValue);
    tempH = lerp(tempH,grainColor[i],0.01 * gainValue);
    initRate += 0.01 + ( gain - grainThreshod ) * initRateGain;
    
    //print tips
    
     //stroke(color(0,0,0));
     //strokeWeight(5);
     //line(0,i*6+10,1024,i*6+10);
     
     //stroke(color(grainColor[i],50,75));
     //strokeWeight(5);
     //line(0,i*6+10, gain * 100,i*6+10);
  }
  
  roadColor = color(tempH,100,93);
  carColor = color(tempH,85,75);
  
  
    
   stroke(color(0,0,0));
   strokeWeight(10);
   line(0,0,WIDTH,0);
   
   stroke(color(tempH,50,75));
   strokeWeight(10);
   line(0,0, initRate * 200 + 50 ,0);
  
}

void updateGrainValue()
{
   // get spectrum
   fft.forward(in.mix);
   
   float[] spec = new float[fft.specSize()];
   for(int i = 0 ; i < spec.length ; ++ i )
     spec[i] = fft.getBand(i);
     
   //normalize
   float l = 0;
   for(int i = 0 ; i < spec.length ; ++ i )
     l += sq(spec[i]);
   l = sqrt(l);
   for(int i = 0 ; i < spec.length ; ++ i )
     spec[i] /= l;
   
     
   for(int i = 0 ; i < grainVector.length ;++i )
   {
     grainValue[i] = 0;
     for(int j = 0 ; j < grainVector[i].length  ;++j)
     {
       grainValue[i] += grainVector[i][j] * spec[j];
       //println(grainVector[i][j],spec[j]);
     }
   }
}

void initGrainValue()
{
  String[]  lines;
  
  for ( int i = 0 ; i < grainValue.length ; ++ i )
  {
    lines = loadStrings(grainFile[i]);
    for(int j = 0 ; j < grainVector[i].length; j++)
    {
      grainVector[i][j] = float(split(lines[j],',')[1]);
    }
  }
  
  for(int i = 0 ; i < grainValue.length; ++i)
  {
    grainValue[i] = 0;
  }
   
  for(int i = 0 ; i < grainValueEnvironment.length; ++i)
  {
    grainValueEnvironment[i] = 0;
  }
}

void recordEnvironmentSound()
{
  if ( ifRecordEnvironment )
  {
      background(0);
    for(int i = 0 ; i < grainValue.length; ++i)
    {
      grainValueEnvironment[i] = grainValueEnvironment[i] + grainValue[i];
      //print(grainValueEnvironment[i]," ");
      stroke(color(180,100,100));
      line(0,25+i*50,getProperty(grainValueEnvironment,i) * 300,25+i*50);
    }
    //float s = 0;
    //for(int i = 0 ; i < grainValueEnvironment.length; ++i)
    //{
    //  s += sq(grainValueEnvironment[i]);
    //}
    //s = sqrt(s);
    //for(int i = 0 ; i < grainValueEnvironment.length; ++i)
    //{
    //  grainValueEnvironment[i] /= s;
    //}
    
    //println();
   
  }
}

float getProperty(float[] arr , int index)
{
  float sum = 0.00001;
  for(int i = 0 ;i < arr.length ; ++ i )
  {
    sum += arr[i];
  }
  return arr[index]/sum;
}

void keyPressed() {
  if (key == ' ')
  {
    if ( !ifRecordEnvironment )
    {
      ifRecordEnvironment = !ifRecordEnvironment;
    }
    else
    {
     ifRecordEnvironment = false;
     ifStart = true;
     background(0);
    }
  }
  
  if (key == 'g' || key == 'G' )
  {
     ifRecordEnvironment = false;
     ifStart = true;
     background(0);
  }
  
  if (key == 'q')
  {
    exit();
  }
}

/////////////
//// Road
////////////

class Road
{
  public int id;
   public Point from;
   public Point to;
   
   int weight;
   
   public ArrayList<Road> fromConnect = new ArrayList<Road>();
   public ArrayList<Road> toConnect = new ArrayList<Road>();

   
   Road(int _f_x , int _f_y , int _t_x , int _t_y , int _w , Road parent )
   {
     from = new Point(_f_x,_f_y);
     to = new Point(_t_x,_t_y);
     id = roadCount++;
     weight = _w;
     
     coverRoad(this);
   }
   
   Road(Point _f , Point _t , int _w )
   {
     from = _f;
     to = _t;
     weight = _w;
     id = roadCount++;
     coverRoad(this);
   }
   
   float displayProcess = 0;
   float completeProcess = 0;
   public void update()
   {
     if ( displayProcess < 0 )
       displayProcess = 0;
     if (displayProcess < 1.0)
     {
        displayProcess += initRate / lenPoints(from,to) * ( 1.0 + random(-0.2,0.2));
     }else
     {
       displayProcess = 1;
       completeProcess += initRate / lenPoints(from,to) * ( 1.0 + random(-0.2,0.2));
       if (toConnect.size() <= 0 )
       {
          GrowChildren();
       }
     }
      
   }
   
   void GrowChildren()
   {
     ArrayList<Road> children = new ArrayList<Road>(); 
     int num = (int)random(growMin,growMax+0.9);
     
     println("grow ",num);
     
     for( int i = 0 ; i < num ; ++ i )
     {
       Point newTo = getPointByAngleLength(from,to,(i+1) *2*PI/num+random(0.2),(int)random(lengthMin,lengthMax)).Add(to);
       int newId = testRoad(to,newTo);
       if (newId==-2){continue;}
       else if (newId == -1){
         
         Road newRoad = new Road(to, newTo, roadWeight -1 + (int)random(3));
         
         roads.add(newRoad);
         
         //newRoad.fromConnect.add(this);
         //newRoad.fromConnect.addAll(toConnect);
         //toConnect.add(newRoad);
     
         children.add(newRoad);
         //print("add children",newRoad.id);
         //do nothing
       }
     }
     
    ArrayList<Road> roadSet = new ArrayList<Road>(children);
    roadSet.add(this);
    
    toConnect.addAll(roadSet);
      
    for( int i = 0 ; i < children.size() ; ++ i )
    {
      //children.get(i).fromConnect.addAll(roadSet);
      children.get(i).fromConnect.add(this);
    }
    
    Car newCar = new Car(this);
    cars.add(newCar);
     
   }
   
   public void display()
   {
     if ( completeProcess < 1 )
     {
       drawLine(from,plerp(from,to,displayProcess),weight,roadColor,displayProcess * roadAlpha);
       if (displayProcess > 0.7)
       drawLine(from,plerp(from,to,displayProcess),weight+2,roadColor,displayProcess * roadAlpha / 2 );
       if (completeProcess > 0.2)
       drawLine(from,plerp(from,to,displayProcess),weight+4,roadColor,displayProcess * roadAlpha / 3);
     }
   }
   
};


void drawLine(Point from , Point to , int weight, color c, float alpha)
{
  strokeWeight(weight);
  stroke(c,alpha * 255.0);
  strokeCap(SQUARE);

  line(from.x,from.y,to.x,to.y);
}


int testRoad(Point from, Point to)
{
   int tem = space[from.x][from.y];
   space[from.x][from.y] = NONE_TYPE;
   for(int i = 0 ; i < 2047 ; ++ i)
   {
     Point testPoint = plerp(from,to, 1.0 * i / 1000);
     if ( testPoint.x >= WIDTH || testPoint.x < 0 ||
          testPoint.y >= HEIGHT || testPoint.y < 0 )
         return -2;
     if ( space[testPoint.x][testPoint.y] != NONE_TYPE )
     {
       space[from.x][from.y] = tem;
       return space[testPoint.x][testPoint.y];
     } 
   }
   
   return -1; 
}

void coverRoad(Road r)
{
   for(int i = 0 ; i < 2048 ; ++ i)
   {
     Point testPoint = plerp(r.from,r.to, 1.0 * i / 1000);
     space[testPoint.x][testPoint.y] = r.id;
   }
}


////////////
//// Point
////////////
class Point
{
  public int x;
  public int y;

  public Point(int _x , int _y )
  {
    x = _x;
    y = _y;
  }
  
  Point Add(Point a )
  {
    return new Point(x+a.x,y+a.y);
  }
}


Point getPointByAngleLength(Point from, Point to , float angle, int len)
{
  float myAngle = atan((to.y-from.y)/(to.x-from.x+0.01));
  float targetAngle = myAngle - angle;
  
  return new Point((int)(len*cos(targetAngle)),(int)(len*sin(targetAngle)));
}

float lenPoints(Point a ,Point b )
{
  return sqrt(sq(a.x-b.x)+sq(a.y-b.y));
}


Point plerp(Point from , Point to , float p)
{
  return new Point((int)lerp(from.x,to.x,p),(int)lerp(from.y,to.y,p));
}

///////////
//// Car
//////////

class Car
{
  Road tem;
  float radius = 15;
  float timer;
  Point pos;
  float process;
  float velocity = 0.1;
  Point offset = new Point(0,0);
  float offsetVelocity = 2;
  Point from;
  Point to;
  
  float offsetLimit = 5;
  
  float colorDiff = 0;
  
  
  public Car(Road _r)
  {
    tem = _r;
    from = tem.from;
    to = tem.to;
    radius = random(carRadiusMin,carRadiusMax);
    offsetLimit = random(5,10);
    colorDiff = random(-carColorDiff,carColorDiff);
  }
  
  public void update()
  {
    timer += 0.01;
    process += initRate / 2 / lenPoints(from,to) * ( 1.0 + random(-0.2,0.2));
    if (process>1)
     process = 1;
    pos = plerp(tem.from,tem.to,process);
    offset.x += random(-sin(timer)*offsetVelocity,sin(timer)*offsetVelocity);
    if (offset.x > offsetLimit )  offset.x = (int)offsetLimit;
    if (offset.x < -offsetLimit ) offset.x = (int)-offsetLimit;
    offset.y += random(-cos(timer)*offsetVelocity,cos(timer)*offsetVelocity);
    if (offset.y > offsetLimit )  offset.y = (int)offsetLimit;
    if (offset.y < -offsetLimit ) offset.y = (int)-offsetLimit;
    
    if (lenPoints(pos,to) < 0.01)
    {
      if (random(1)<0.3)
       {
          if ( lenPoints(tem.from,to) < 0.01)
          {
            newRoute(tem.from,tem.to,tem);
          }
          else
          {
              newRoute(tem.to,tem.from,tem);
          }
       }
       else
       {
          if ( lenPoints(tem.from,to) < 0.01)
          {
            if (tem.fromConnect.size()>0)
            {
              Road r = tem.fromConnect.get((int)random(tem.fromConnect.size()-0.01));
              newRoute(r.to,r.from,r);
            }else
            {
              newRoute(tem.from,tem.to,tem);
            }
          }
          else
          {
            if (tem.toConnect.size()>0)
            {
              Road r = tem.toConnect.get((int)random(tem.fromConnect.size()-0.01));
              newRoute(r.from,r.to,r);
            }else
            {
              newRoute(tem.to,tem.from,tem);
            }
          }
       }
        
    }
    
    
  }
  
  public void display()
  {
    drawEllipse(pos.Add(offset), radius * ( 1 + offset.x/3) , color(tempH + colorDiff, 90, 75 ), carAlpha);
  }
  
  void newRoute(Point f , Point t , Road r)
  {
    from = f;
    to = t;
    tem = r;
    process = 0;
  }
  
}


void drawEllipse(Point pos , float r, color c, float alpha)
{
  strokeWeight(1);
  stroke(c,alpha * 255.0);
  //noFill();
  fill(c,alpha * 50 );
  
  ellipse(pos.x,pos.y,(int)r,(int)r);
}



void drawCar()
{
  for (int i = 0; i < cars.size(); i++) {
    Car c = cars.get(i);
    c.display();
  }
}

void updateCar()
{
  for (int i = 0; i < cars.size(); i++) {
    Car c = cars.get(i);
    c.update();
  }
  
}

//void specAnalyze()
//{
//  final int searchRange = 40;
//  final float filter = 0.2;
//  final int conflictRange = 15;


//  for(int i = 0; i < in.bufferSize() - 1; i++)
//  {
//    in.left.get(i);
//    in.right.get(i);
//  }
//  // get fft
//  fft.forward(in.mix);
  
//    stroke(#AAAA00);
//  for(int i = 0 ; i < fft.specSize() ; i++)
//  {
//     // draw the line for frequency band i
//     line( i , 200 + fft.getBand(i) * 4 , i , 200);
//  }
  
//  // get spectrum
//  float[] spec = new float[fft.specSize()];
//  for(int i = 0 ; i < spec.length ; ++ i )
//    spec[i] = fft.getBand(i);
    
//  //filter by 0.1 * max
//  float max = 0;
//  for (int i = 0 ; i < spec.length  ; ++ i )
//  {
//    if (max < spec[i] ) max = spec[i];
//  }
//  for (int i = 0 ; i < spec.length  ; ++ i )
//  {
//    if (spec[i] < max * 0.1)
//      spec[i] = 0;
//  }
  
    
//  //filter spec
//  float[] spec2 = new float[spec.length];
//  spec2[0] = 0;
//  spec2[spec2.length-1] = 0;
  
  
//  // step 1
//  // 2 * a_n^2 - a_n-1^2 - a_n+1^2
//  for (int i = 1 ; i < spec2.length-1 ; ++i )
//  {
//    if (spec[i] == 0)
//      spec2[i] = 0 ;
//    else
//    {
//    spec2[i] = 2 * sq(spec[i]) - sq(spec[i-1]) - sq(spec[i+1]);
//    if (spec2[i] < 0 )
//      spec2[i] = 0 ;
//    } 
//  }
  
//  // step 2
//  // search range and filter by 0.2
//  float[] spec3 = new float[spec2.length];
//  int count3 = 0;
//  for (int i = 0 ; i < spec2.length ; ++i )
//  {
//    Boolean ifUse = true;
//    if (spec2[i] == 0 )
//     ifUse = false;
//    for(int j = i - searchRange / 2 ; j < i + searchRange / 2  ; ++j )
//    {
//      if (j > 0 && j < spec2.length  && i != j )
//      {
//        if (spec2[i] < spec2[j] * filter)
//          ifUse = false;
//      }
//    }
//    if (ifUse)
//    {
//      spec3[i] = 1;
//      count3 ++;
//    }
//    else
//      spec3[i] = 0;
//  }
  
//  //step 3
//  //search range and filter by 1
  
//  float[] spec4 = new float[spec3.length];
//  int count = 0;
//  for (int i = 0 ; i < spec3.length ; ++i )
//  {
//    Boolean ifUse = true;
//    if (spec3[i] == 0 )
//     ifUse = false;
//    for(int j = i - conflictRange / 2 ; j < i + conflictRange / 2  ; ++j )
//    {
//      if (j > 0 && j < spec3.length  && i != j )
//      {
//        if (spec2[i] < spec2[j] )
//          ifUse = false;
//      }
//    }
//    if (ifUse)
//    {
//      spec4[i] = spec[i];
//      count ++;
//    }
//    else
//      spec4[i] = 0;
//  }
  
//  for(int i = 0 ; i < spec4.length ; ++ i )
//  {
//    specAna[i] = spec4[i];
//  }
//}