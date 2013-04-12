class Worm {
  final static int RIGHT = 0;
  final static int DOWN  = 1;  
  final static int LEFT  = 2;
  final static int UP    = 3;
  final static int LEFT_TURN  = 4;
  final static int RIGHT_TURN = 5;

  float gridSize = 10;  
  int gridW, gridH;
  int x, y;
  int dir; 
  int curveRadius;
  ArrayList<Worm> children = new ArrayList();
  ArrayList<PVector> vertices = new ArrayList();
  boolean alive = true;
  boolean hasParent;
  float curvyness;

  WormBucket bucket;

  CMYKColor col;

  Worm(WormBucket bucket, int gridW, int gridH, float gridSize, float curvyness, int curveRadius) {
    this.bucket = bucket;
    this.gridW = gridW;
    this.gridH = gridH;
    this.gridSize = gridSize;    
    this.curvyness = curvyness;
    this.curveRadius = curveRadius;
    hasParent = false;
    init();  
    col = randomColor();
    addGridPoint();
  }

  Worm(Worm parent, int offset) {
    hasParent = true;   
    bucket = parent.bucket;
    gridW = parent.gridW;
    gridH = parent.gridH;
    gridSize = parent.gridSize;
    curvyness = parent.curvyness;
    curveRadius = parent.curveRadius;
    dir = parent.dir;
    x = parent.x;
    y = parent.y;
    if (dir == RIGHT) y += offset;
    else if (dir == LEFT) y -= offset;
    else if (dir == UP) x += offset;
    else if (dir == DOWN) x -= offset;
    col = randomColor();
    addGridPoint();
  }

  CMYKColor randomColor() {    
    int mode = (int) random(3);
    if (mode == 0) return new CMYKColor(1f, 0f, 0f, 0f);
    else if (mode == 1) return new CMYKColor(0f, 1f, 0f, 0f);
    else if (mode == 2) return new CMYKColor(0f, 0f, 1f, 0f);    
    // else if (mode == 3) return new CMYKColor(1f, 1f, 0f, 0f);
    // else if (mode == 4) return new CMYKColor(0f, 1f, 1f, 0f);
    // else if (mode == 5) return new CMYKColor(1f, 0f, 1f, 0f);
    return new CMYKColor(0, 0, 0, 1f);
  }

  void init() {    
    // which side to start:
    int side = floor(random(1, 4)); // not the RIGHT side

    if (side == UP) {
      x = floor(random(1, gridW-1));
      y = 0;
      dir = DOWN;
    } 
    else if (side == DOWN) {
      x = floor(random(1, gridW-1));
      y = gridH;
      dir = UP;
    } 
    else if (side == LEFT) {
      x = 0;
      y = floor(random(1, gridH-1));
      dir = RIGHT;
    }
    else if (side == RIGHT) {
      x = gridW;
      y = floor(random(1, gridH-1));
      dir = LEFT;
    }
  }

  void addChildren(int num) {
    CMYKColor col2 = randomColor();
    for (int i=0; i<num; i++) {
      Worm w = new Worm(this, children.size() + 1);
      if (i%2==0) w.col = col2;
      else w.col = col;
      children.add(w);
      bucket.addWorm(w);
    }
  }

  void freeChild() {
    if (!children.isEmpty()) {
      Worm w = children.remove(children.size()-1);
      w.hasParent = false;
    }
  }

  int getChildCount() {
    return children.size();
  }

  void addGridPoint() {
    vertices.add(new PVector(x * gridSize, y * gridSize));
  }

  void step() {
    if (!hasParent && alive) {
      if (random(1) <= curvyness) {
        if (random(1) > 0.5) {
          int r = curveRadius;
          turn(LEFT_TURN, r);        
          for (Worm w : children) {          
            w.turn(LEFT_TURN, ++r);
          }
        } 
        else {
          int r = getChildCount() + curveRadius;
          turn(RIGHT_TURN, r); 
          for (Worm w : children) {
            w.turn(RIGHT_TURN, --r);
          }
        }
      }
      else {
        move();
        for (Worm w : children) w.move();
      }
      // At some point a child worm might want to leave the parents path:
      if (random(1) < 0.1) freeChild();

      if (!isInGrid()) {
        alive = false;
        // Free children which might still be inside the grid
        while (!children.isEmpty ()) freeChild();
      }
    }
  }

  boolean isInGrid() {
    return  !(x < 0 || x > gridW || y < 0 || y > gridH);
  }

  void draw(PGraphics g) {
    g.noFill();
    if (g instanceof PDF) {
      ((PDF) g).strokeCMYK(col);
    } 
    else {
      g.stroke(CMYKtoRGB(col));
      g.blendMode(MULTIPLY);
    }
    // g.strokeWeight(1);    
    // g.ellipse(vertices.get(0).x, vertices.get(0).y, gridSize*1.5, gridSize*1.5);            
    g.strokeWeight(gridSize-1);
    g.beginShape();
    for (PVector v : vertices) {
      g.vertex(v.x, v.y);
    }
    g.endShape();

    for (Worm w : children) w.draw(g);
  }

  void move() {
    if (dir == RIGHT) x += 1;
    else if (dir == LEFT) x-= 1;
    else if (dir == DOWN) y += 1;
    else if (dir == UP) y -= 1;
    addGridPoint();
  }

  void turn(int turn, int radius) {  
    int from = (dir + 2) % 4; // just to simplify the statements

    float r = radius * gridSize;
    float cx, cy;

    if (from == LEFT && turn == RIGHT_TURN) {
      cx = x * gridSize;
      cy = (y + radius) * gridSize;
      arc(cx, cy, r, -HALF_PI, 0);
      x += radius;
      y += radius;
    } 
    else if (from == LEFT && turn == LEFT_TURN) {
      cx = x * gridSize;
      cy = (y - radius) * gridSize;
      arc(cx, cy, r, HALF_PI, 0);
      x += radius;
      y -= radius;
    } 
    else  if (from == RIGHT && turn == RIGHT_TURN) {
      cx = x * gridSize;
      cy = (y - radius) * gridSize;
      arc(cx, cy, r, HALF_PI, PI);
      x -= radius;
      y -= radius;
    } 
    else if (from == RIGHT && turn == LEFT_TURN) {
      cx = x * gridSize;
      cy = (y + radius) * gridSize;
      arc(cx, cy, r, PI + HALF_PI, PI);
      x -= radius;
      y += radius;
    } 

    else if (from == DOWN && turn == RIGHT_TURN) {
      cx = (x + radius) * gridSize;
      cy = y * gridSize;
      arc(cx, cy, r, PI, PI + HALF_PI);   
      x += radius;
      y -= radius;
    } 
    else if (from == DOWN && turn == LEFT_TURN) {
      cx = (x - radius) * gridSize;
      cy = y * gridSize;
      arc(cx, cy, r, 0, -HALF_PI);      
      x -= radius;
      y -= radius;
    } 
    else  if (from == UP && turn == RIGHT_TURN) {
      cx = (x - radius) * gridSize;
      cy = y * gridSize;
      arc(cx, cy, r, 0, HALF_PI);  
      x -= radius;
      y += radius;
    } 
    else if (from == UP && turn == LEFT_TURN) {
      cx = (x + radius) * gridSize;
      cy = y * gridSize;
      arc(cx, cy, r, PI, HALF_PI);
      x += radius;
      y += radius;
    }

    //update dir
    if (turn == LEFT_TURN) dir = (dir + 3) % 4;    
    else if (turn == RIGHT_TURN) dir = (dir + 1) % 4;
  }

  void arc(float cx, float cy, float r, float a1, float a2) {
    int res = 50; // could be proportional to the radius
    float arc = (a2 - a1) / res;
    for (int i = 0; i < res+1; i++) {
      float x = cx + cos(a1 + arc * i) * r;
      float y = cy + sin(a1 + arc * i) * r;
      vertices.add(new PVector(x, y));
    }
  }
}

