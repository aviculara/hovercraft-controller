import processing.serial.*;

import net.java.games.input.*;
import org.gamecontrolplus.*;
import org.gamecontrolplus.gui.*;

import cc.arduino.*;
import org.firmata.*;

import processing.net.* ;

ControlDevice cont;
ControlIO control;


Serial port ;
String dataToSend ;
boolean Off = false ;
boolean sensorOn = false ; 

//limiting values
int ruddermin = 95 ;
int ruddermid = 148 ;
int ruddermax = 172 ;

int lift_steps = 10 ;
int current_step = 0 ;
int[] thrust_gears = {20,50,90,180} ;

int gear = 0 ;

//for changing and applying lift bar steps
int saved_steps = 10 ;
int saved_current_step = 0 ;

int lift_speed = 0 ;
int thrust_speed = 0 ;

//joystick values
float joyLy ;
float joyLx ;
float joyRy ;
float joyRx ;
float joyLR ;

//buttons
//Button(int x, int y, int bwidth, int bheight, String shape)
//Button buttonx = new Button(
Button buttonLB = new Button(450, 60, 80,40, "rect" );
Button buttonRB = new Button(910, 60, 80,40, "rect" );

Button buttonY = new Button(910, 150 , 50, 50, "ellipse") ;
Button buttonA = new Button(910, 240 , 50, 50, "ellipse") ;
Button buttonX = new Button(860, 195 , 50, 50, "ellipse") ;
Button buttonB = new Button(960, 195 , 50, 50, "ellipse") ;

Button buttonUp = new Button(450, 150, 30, 40 , "rect") ;
Button buttonDown = new Button(450, 240, 30, 40, "rect") ;
Button buttonRight = new Button(500, 195, 40, 30, "rect") ;
Button buttonLeft = new Button(400, 195, 40, 30, "rect") ;

Button select = new Button(610, 195, 40, 30, "ellipse") ;
Button start = new Button(750, 195, 40, 30, "ellipse") ;


void setup(){
  
  size(1040,440) ;

  buttonUp.set_radius(5) ;
  buttonDown.set_radius(5) ;
  buttonRight.set_radius(5) ;
  buttonLeft.set_radius(5) ;
  //port values based on ESP bluetooth outgoing port
  try{
  port = new Serial(this, "COM12", 115200); 
} catch(Exception e){
  println("Error opening serial port : Port not found \nPlease ensure the ESP is connected and port name is correct"); 
  System.exit(-1);
  }
  control = ControlIO.getInstance(this);
  cont = control.getMatchedDevice("complex_control"); //name of the file
  
  if(cont == null) {
    println("there is no valid controller detected");
    System.exit(-1);
  }
}

void draw(){
  getControllerValues() ;
  drawController() ;
  mapValues() ;
  port.write(dataToSend) ;
}

public void drawController(){
  background(200) ;
  line(320,0,320,440) ;
  
  //sensor indicator
  if(sensorOn){
    fill(200, 0, 0) ;
    textSize(20) ;
    text("Sensor: On", 80, 40) ;
  }
  else{
    fill(100, 100, 100) ;
    textSize(20) ;
    text("Sensor: Off", 80, 40) ;
  }
  
  //controller off indicator
  if( Off){
    fill(100,10,100) ;
    textSize(20) ;
    text("Off: sending 0 data", 80, 80) ;
  }
  
  //thrust indicator
  rectMode(CORNER) ;
  fill(255,255,255) ;
  rect(80,120, 50, 250) ;
  for ( int i = 0 ; i < thrust_gears.length ; i = i +1 ){ //split bar into number of gears
    int g = thrust_gears[i] ;
    int bar_length = int(map(g, 0, 180, 0, 250)) ;
    line(80, 370 - bar_length, 130, 370 - bar_length) ;
    if (i ==gear){
        fill(100,100,100) ;
        rect(80,120, 50, 250- bar_length) ;
    }
  }
  
  //lift indicator
  fill(255,255,255) ;
  rect(210,120, 50, 250) ;
  int thick = int(map(180 / lift_steps, 0, 180, 0, 250));
  for ( int i = 0 ; i <= lift_steps ; i = i +1 ){  //split bar into number of steps
    //float thick = 250 / lift_steps ;
    line(210, 370 - thick * i , 260, 370 - thick * i) ;
  }
  
  //control panel texts
  textSize(15) ;
  fill(100, 100, 100) ;
  text("Thrust", 80, 400) ;
  
  textSize(15) ;
  fill(100, 100, 100) ;
  text("Lift", 210, 400) ;
  
  textSize(15) ;
  fill(100, 100, 100) ;
  text(thrust_speed, 80, 430) ;
  
  textSize(15) ;
  fill(100, 100, 100) ;
  text(lift_speed, 210, 430) ;
  
  //draw joysticks
  fill(100,100,100) ;
  ellipse(560,360,100,100) ; //left joystick housing
  fill(100,100,100) ;
  ellipse(800,360,100,100) ; //right joystick housing
  
  fill(100,100,100) ;
  rectMode(CENTER) ;
  rect(680,60,200,40) ; //lr housing
  
  //move joysticks
  fill(255,255,255) ;
  ellipse(560 + 30* joyLx , 360 + 30 * joyLy ,70,70) ; //(x,y,width,height) left joystick
  
  fill(255,255,255) ;
  ellipse(800+ 30 * joyRx , 360+ 30 * joyRy ,70,70) ; //(x,y,width,height) right joystick
  
  fill(255,255,255) ;
  ellipse(680 - 100 * joyLR ,60,50,50) ; //lr joystick
  
  //draw buttons, function of Button class
  buttonLB.display() ;
  buttonRB.display() ;
  buttonY.display() ;
  buttonA.display() ;
  buttonX.display() ;
  buttonB.display() ;
  buttonUp.display() ;
  buttonDown.display() ;
  buttonRight.display ();
  buttonLeft.display() ;
  select.display() ;
  start.display() ;
  
  textAlign(CENTER) ;
  
  //button names
  textSize(15) ;
  fill(100,100,100) ;
  text("Save" , 910, 245) ;
  
  textSize(15) ;
  fill(100,100,100) ;
  text("Apply" , 610, 230) ;
  
  textSize(15) ;
  fill(100,100,100) ;
  text("Off" , 860, 200) ;
  
  textSize(13) ;
  fill(100,100,100) ;
  text("Sensor" , 910, 155) ;
  
  textAlign(LEFT) ;
 /*
Button buttonY = new Button(910, 150 , 50, 50, "ellipse") ;
Button buttonA = new Button(910, 240 , 50, 50, "ellipse") ;
Button buttonX = new Button(860, 195 , 50, 50, "ellipse") ;
Button buttonB = new Button(960, 195 , 50, 50, "ellipse") ;

Button select = new Button(610, 195, 40, 30, "ellipse") ;
Button start = new Button(750, 195, 40, 30, "ellipse") ; */
}

public void getControllerValues(){
//gets values using gamecontrolplus library
    joyLy = cont.getSlider("joyLy").getValue() ;
    joyLx = cont.getSlider("joyLx").getValue() ;
    joyRy = cont.getSlider("joyRy").getValue() ;
    joyRx = cont.getSlider("joyRx").getValue() ;
    joyLR = cont.getSlider("joyLR").getValue() ;
    
    buttonY.set_val(cont.getButton("buttonY").pressed()) ;
    buttonA.set_val(cont.getButton("buttonA").pressed()) ;
    buttonX.set_val(cont.getButton("buttonX").pressed()) ;
    buttonB.set_val(cont.getButton("buttonB").pressed()) ;
    
    buttonLB.set_val(cont.getButton("buttonLB").pressed()) ;
    buttonRB.set_val(cont.getButton("buttonRB").pressed()) ;
    
    start.set_val( cont.getButton("start").pressed());
    select.set_val( cont.getButton("select").pressed()) ;
    
    hat_press(cont.getHat("dirbuttons").getValue() ) ;
}

public void mapValues(){
  //process all data, construct string for sending values
  dataToSend = "" ;
  
  int thrust_max = thrust_gears[gear] ;
  thrust_speed = round(map(joyLR, 0, 1, 0, thrust_max)) ;
  thrust_speed = constrain(thrust_speed, 0, 180) ;
  
  int rudderval = round(customMap(joyRx, -1, 1, ruddermin, ruddermax, ruddermid));
  if(rudderval != ruddermid && thrust_speed == 0 ){
    thrust_speed = 10 ;
  }

  if (press_release(buttonY) ){
    sensorOn = ! sensorOn ;
  }
  
  int sensorval = 0 ;
  if (sensorOn){
    sensorval = 1 ; 
  }
  
  if( start.get_val() ){
    Off = false ;
  }
  
  //lb and rb button changes the lift fan speed in given number of steps
  if (lift_speed > 0 && press_release(buttonLB) && current_step > 0 ){
    current_step = current_step - 1 ;
  }
  else if ( lift_speed < 180 && press_release(buttonRB) && current_step < lift_steps){
    current_step = current_step + 1 ;
  }
  lift_speed = (180 / lift_steps ) * current_step;
  lift_speed = constrain(lift_speed ,0 ,180 ) ;
  
  //up and down buttons change gear
  if (press_release(buttonUp) && gear < thrust_gears.length-1){
    gear = gear + 1 ;    
  }
  else if (press_release(buttonDown) && gear > 0){
   gear = gear - 1 ; 
  }
  
  //right and left buttons change number of lift steps
  if (press_release(buttonRight)){
   lift_steps = lift_steps + 1 ; 
  }
  else if (press_release(buttonLeft)){
   lift_steps = lift_steps - 1 ; 
  }
  
  if(buttonA.get_val()){ //save no of steps
    saved_steps = lift_steps ;
    saved_current_step = current_step ;
  }
  
  if (press_release(select)){ //apply saved no of steps, default 10
   lift_steps = saved_steps ;
   current_step = saved_current_step ;
  }
  
  //sending 0 data when controller is off
  if(buttonX.get_val() || Off){
    Off = true ;
    thrust_speed = 0 ;
    rudderval = ruddermid ;
    sensorval = 0 ;
    lift_speed = 0 ;
    sensorOn = false ;
    current_step = 0 ;
  }
  
  display_bars(lift_speed , thrust_speed) ;
  
  dataToSend = dataToSend + str(thrust_speed) + "," ;
  dataToSend = dataToSend + str(rudderval) + "," ;
  dataToSend = dataToSend + str(sensorval) + "," ;
  dataToSend = dataToSend + str(lift_speed) + "," ;
  dataToSend = dataToSend + "\n" ;
  println(dataToSend) ; //input check. comment out
}

public void hat_press(float value){ //convert hat data to 4 seperate buttons
  if (value == 2){
   buttonUp.set_val(true) ;
  }
  else if (value == 4){
    buttonRight.set_val(true) ;
  }
  else if (value == 6){
    buttonDown.set_val(true) ;
  }
  else if (value == 8){
    buttonLeft.set_val(true) ;
  }
  else{
    buttonUp.set_val(false) ;
    buttonRight.set_val(false) ;
    buttonDown.set_val(false) ;
    buttonLeft.set_val(false) ;
  }
}

// Custom function to map values with a specified midpoint
public float customMap(float value, float min1, float max1, float min2, float max2, float midpoint) { 
  //min1 is the range of original value while min2 is the mapped range
  float mappedValue;
  float mid1 = (min1 + max1) /2 ;
  if (value <= mid1) {
    mappedValue = map(value, min1, mid1, min2, midpoint);
  } else {
    mappedValue = map(value, mid1, max1, midpoint, max2);
  }
  return mappedValue;
}

public boolean press_release(Button button){
  //buttons are to return true only after the pressed button is released
  boolean currentVal = button.get_val() ;
  boolean prevVal = button.get_prev() ;
  if (currentVal && prevVal){
    //do nothing, button is being pressed
    return false ;
  }
  else if (currentVal){
    //button was not pressed but is being pressed
    button.set_prev(true) ;
    return false ;
  }
  else if (prevVal){
   //stopped pressing = press + release
   button.set_prev( false ) ;
   return true ;
  }
  else{
    //not pressed and hasn't been pressed
   return false ; 
  }
  
}

public void display_bars(int lift_speed , int thrust_speed){
 //thrust indicator
  rectMode(CORNER) ;
  fill(155,0,0) ;
  //int thick = 250 / thrust_gears.length ;
  int bar_length = int(map(thrust_speed, 0, 180, 0, 250)) ;
  rect(80,370 - bar_length , 50, bar_length) ;
  
  //lift indicator
  fill(155,0,0) ;
  //thick = 250 / lift_steps ;
  int bar_length2 = int(map(lift_speed, 0, 180, 0, 250)) ;
  rect(210,370 - bar_length2 , 50, bar_length2) ;
}
