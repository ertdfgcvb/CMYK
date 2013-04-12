import java.util.Random;

// Just a class to render some circles, based on a lookup map.
// Note that in the drawing methods a PGraphics argument is passed, 
// this will let us select the render target, unfortunately not without some painful casting...

class Circles {
  PImage map;
  ArrayList<Circle>circles;   
  float spacing;
  float strokeSpacing = 0.6;
  int seed;

  Circles() {       
    circles = new ArrayList();
  }

  void build(float spacing, float maxRadius, float mapScale) {
    if (map != null) {
      this.spacing = spacing;      
      int num = floor(maxRadius / spacing) + 1;
      num *= 1.5; // a few extra circles    
      circles.clear();
      for (int i=0; i<num; i++) {
        float radius = i * spacing + (spacing + strokeSpacing) / 2; 
        circles.add(new Circle(radius, map, mapScale));
      }
    }
  }

  void loadMap(PImage map) {
    this.map = map;
  }

  void drawShapes(PGraphics g, float x, float y) {
    g.strokeWeight(max(strokeSpacing, spacing - strokeSpacing));
    g.pushMatrix();
    g.translate(x, y);
    for (Circle c : circles) {
      c.drawShape(g);
    }
    g.popMatrix();
  }

  void drawCircles(PGraphics g, float x, float y) {
    g.noFill();
    g.strokeWeight(strokeSpacing / 2);
    for (Circle c : circles) {
      g.ellipse(x, y, c.radius * 2, c.radius * 2);
    }
  }

  void reSeed() {
    seed = millis();
  }

  void explode(float val) {
    Random r = new Random(seed);
    for (Circle c : circles) {
      float a = map(r.nextFloat(), 0, 1, -val, val);
      c.setAng(a);
    }
  }

  // nested class
  class Circle {
    float ang, dang;
    float radius;
    int steps;
    PVector[] vertices;
    int[] colors;

    Circle(float radius, PImage map, float mapScale) {
      this.radius = radius;

      steps = floor(min(400, max(30, PI * radius * 2)));
      vertices = new PVector[steps];
      colors = new int[steps];

      float a = TWO_PI / steps;    
      float ox = map.width/2;
      float oy = map.height/2;
      for (int i=0; i<steps; i++) {
        float x = cos(a * i) * radius;
        float y = sin(a * i) * radius;
        // the PImage.get(x, y) function returns black 
        // for pixels read outside the image area...
        color c = map.get(round(x / mapScale + ox), round(y / mapScale + oy));
        // we could also store the actual color
        // colors[i] = c;
        // and the use it directly... but instead we just build a lookup map
        if (brightness(c) < 10) {
          colors[i] = 0;
        } 
        else {
          colors[i] = 1;
        }
        vertices[i] = new PVector(x, y);
      }
    }

    void setAng(float a) {
      // dang = a;
      ang = a;
    }

    void drawShape(PGraphics g) {
      // for animation purposes:
      // ang = ang + (dang - ang) * 0.1;      
      PVector p1, p2;
      g.strokeCap(ROUND);
      g.noFill();
      g.pushMatrix();
      g.rotate(ang);            
      // we use LINES to avoid blending
      // this will give an unexpected result with strokeCap other than ROUND      
      g.beginShape(LINES); 
      for (int i=0; i<steps; i++) {
        int c = colors[i%steps];        
        if (c == 1) {
          p1 = vertices[i%steps];
          p2 = vertices[(i + 1) % steps];
          g.vertex(p1.x, p1.y);
          g.vertex(p2.x, p2.y);
        }
      }     
      g.endShape();
      g.popMatrix();
    }
  }
}

