public class Button{
  private int rcolor = 155;
  private int gcolor = 10 ;
  private int bcolor = 10;
  private int x_coord ;
  private int y_coord ;
  private int bwidth ;
  private int bheight ;
  private int radius = 0;
  
  private String shape ;
  
  private boolean current_val ;
  private boolean prev_val ;
  
  public Button(int x, int y, int bwidth, int bheight, String shape){
   //possible shapes are rect and ellipse
   this.x_coord = x ;
   this.y_coord = y ;
   this.bwidth = bwidth ;
   this.bheight = bheight ;
   this.shape = shape ;
  }
  
  public void pressed_color(int r, int g, int b){
    this.rcolor = r ;
    this.gcolor = g ;
    this.bcolor = b ;
  }
  
  public void display(){
    if (this.current_val){
      fill(this.rcolor , this.gcolor, this.bcolor) ;
    }
    else{
      fill(255,255,255) ;
    }
    if(this.shape == "rect"){
      rectMode(CENTER) ;
      rect(this.x_coord, this.y_coord , this.bwidth, this.bheight, this.radius) ;
    }
    else{
      ellipse(this.x_coord, this.y_coord , this.bwidth, this.bheight) ;
    }
  }
  
  public void set_val(boolean val){
   this.current_val = val ;
  }
  
  public void set_prev(boolean val){
   this.prev_val = val ; 
  }
  
  public boolean get_val(){
   return this.current_val ;
  }
  
  public boolean get_prev(){
   return this.prev_val ; 
  }
  
  public void set_radius(int radius){
   this.radius = radius ; 
  }
  
}
