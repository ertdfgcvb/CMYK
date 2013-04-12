// This sketch creates some imagery and renders it into 
// a PGraphics preview which can be displayed on screen.
// Some parameters can be modified with the mouse position.
// At each click the current snapshot is saved into a PDF file.

// The final result will be rendered into a small postcard-sized document.
// A6 paper sizes (148 x 105 mm):
// (in some cases it will be desirable to add bleed)
final float CARD_W = mm(148);
final float CARD_H = mm(105);
Circles circles;
PGraphics preview;
PVector previewOffset;
// A CMYK color: at each mousePress we randomize this color.
// It will also be converted approximately to Processing RGB (int) for preview purposes.
CMYKColor col;

void setup() {
  size(800, 600, OPENGL);

  preview = createGraphics(round(CARD_W), round(CARD_H), OPENGL);
  circles = new Circles();

  // make sure the offset gets resetted with the next shift() call:
  previewOffset = new PVector(width, height);   
  shift();
}

void draw() {    
  circles.build(10.0 * mouseY / height + 2.7, dist(0, 0, CARD_W, CARD_H), 1.1);    
  circles.explode(PI * mouseX / width);

  render(preview);  
  image(preview, previewOffset.x, previewOffset.y, preview.width/2, preview.height/2);
}

void mousePressed() {
  savePDF();   
  shift();  
  col = new CMYKColor(random(1), random(1), random(1), 0); 
  circles.reSeed();
}

void render(PGraphics g) {
  // The nasty part: 
  // we check if our renderer is a PDF instance
  // so we can use the custom stroke and fill settings.
  // Pay extra attention to the (float) width and height!
  boolean isPDF = g instanceof PDF;
  float ox, oy;
  g.beginDraw();
  if (isPDF) {
    ox = ((PDF) g).width / 2;
    oy = ((PDF) g).height / 2;
    // There are also some advantages:
    // the fine stroke will not be rendered in the small preview window   
    // ((PDF) g).overPrint(true);
    // ((PDF) g).strokeCMYK(1, 0, 0, 0);
    ((PDF) g).strokeCMYK(col);
    circles.drawCircles(g, ox, oy);
  } 
  else {    
    ox = g.width / 2;
    oy = g.height / 2;
    g.stroke(CMYKtoRGB(col));
    g.background(255);
  }

  circles.drawShapes(g, ox, oy);
  g.endDraw();
}

void savePDF() {  
  // For precise document size creation it’s possible to use float values for witdh and height
  // Watch out for PDF instances which are cast as PGraphics: 
  // println(((PGraphics) pdf).width)); 
  // will output 0...
  // Please note that the pdf library needs an absolute path:  
  PDF pdf = new PDF(this, CARD_W, CARD_H, sketchPath("data/" + System.currentTimeMillis() + ".pdf"));
  render(pdf);
  pdf.dispose();
}

// Shift around the preview image, load a new map and randomize the color
void shift() {  
  float m = 20;
  float w = preview.width/2;
  float h = preview.height/2;
  previewOffset.x += w + m;
  if (previewOffset.x + w + m > width) {
    previewOffset.x = m;
    previewOffset.y += h + m;
    if (previewOffset.y + h + m > height) {
      previewOffset.set(m, m, 0);
      background(230, 230, 230);
    }
  }

  // Randomize the CMYK color
  col = new CMYKColor(random(1), random(1), random(1), 0);
  // Load a random map
  circles.loadMap(loadImage("map_" + (int) random(8) + ".png"));
}

// Converts mm to PostScript points
// This function should be called “pt” but I like how it looks when used:
// mm(29) will be converted to 29mm
public float mm(float pt) {
  return pt * 2.83464567f;
}

// A small helper function to convert CMYK to Processing RGB, for preview purposes
// Formula from http://www.easyrgb.com/index.php?X=MATH
// Convert CMYK > CMY > RGB
// c,m,y,k ranges from 0.0 to 1.0
int CMYKtoRGB(float c, float m, float y, float k) {
  float C = c * (1-k) + k;
  float M = m * (1-k) + k;
  float Y = y * (1-k) + k;
  float r = (1-C) * 255;
  float g = (1-M) * 255;
  float b = (1-Y) * 255;
  return color(r, g, b);
}

int CMYKtoRGB(CMYKColor col) {
  return CMYKtoRGB(col.getCyan(), col.getMagenta(), col.getYellow(), col.getBlack());
}
