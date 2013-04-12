class WormBucket {
  ArrayList<Worm> worms;
  float width, height;
  float gridSize;
  int gridH, gridV;
  
  WormBucket(float width, float height) {
    this.width = width;
    this.height = height;
    worms = new ArrayList();
  }

  void generate() {    
    worms.clear();    
    gridSize = mm(random(1, 4));
    gridH = (int) (width / gridSize) + 6;
    gridV = (int) (height / gridSize) + 6;    
    
    int num = (int)random(2, 8);    
    for (int i=0; i<num; i++) {
      float curvyness = random(0.3, 0.9);
      int radius = (int) random(2, 5);
      int childCount = (int) random(2, 7);      
      Worm w = new Worm(this, gridH, gridV, gridSize, curvyness, radius);
      worms.add(w);
      w.addChildren(childCount);
    }

    boolean oneLeft = true;
    while (oneLeft) {
      oneLeft = false;
      for (Worm w : worms) {
        if (w.alive) {
          w.step();
          oneLeft = true;
        }
      }
    }
  }

  void addWorm(Worm w) {
    worms.add(w);
  }

  void draw(PGraphics g) {
    // an offset
    float ox = -3 * gridSize;
    float oy = -3 * gridSize;
    g.pushMatrix(); 
    g.translate(ox, oy);
    //drawGrid(g);
    for (Worm w : worms) w.draw(g);    
    g.popMatrix();
  }

  void drawGrid(PGraphics g ) {
    g.strokeWeight(0.5);
    float w = gridSize * gridH;
    float h = gridSize * gridV;
    for (int i=0; i<gridH+1; i++) {
      float x = i * gridSize;
      g.line(x, 0, x, h);
    }    
    for (int i=0; i<gridV+1; i++) {
      float y = i * gridSize;
      g.line(0, y, w, y);
    }
  }
}

