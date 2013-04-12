// This sketch loads a template PDF and applies it over the generated graphics.
// Some bleed and cropmarks have also been added.

final float BLEED  = mm(5);
final float CARD_W = mm(85);
final float CARD_H = mm(55);
final int PAGE_NUM = 50;

void setup() {
  // Please note that the pdf library needs an absolute path:  
  PDF pdf = new PDF(this, CARD_W + BLEED * 2, CARD_H + BLEED * 2, sketchPath("data/"+System.currentTimeMillis()+".pdf"));
  // Template is loaded here (alswo with absolute path).
  // The template also contains the extra bleed of 5 mm
  pdf.loadTemplate(sketchPath("data/bc-roberta.pdf"));
  
  // Just a worm generator
  WormBucket wb = new WormBucket(CARD_W, CARD_H);

  for (int i=0; i<PAGE_NUM; i++) {  
    wb.generate();
    pdf.pushMatrix();
    pdf.translate(BLEED, BLEED);
    pdf.overPrint(true);
    wb.draw(pdf);    
    pdf.popMatrix();
    pdf.applyTemplate(); 
    cropMarks(pdf, BLEED, BLEED, CARD_W, CARD_H, mm(5), mm(2));
    if (i < PAGE_NUM-1) pdf.nextPage();
  }

  pdf.dispose();
  exit();
}


// Adds crop marks
void cropMarks(PGraphics g, float x, float y, float w, float h, float len, float dist) {
  if (g instanceof PDF) ((PDF) g).strokeK(1);
  else g.stroke(0);
  g.strokeWeight(0.25);   
  g.line(x, y - dist, x, y - dist - len);
  g.line(x + w, y - dist, x + w, y - dist - len);
  g.line(x, y + h + dist, x, y + h + dist + len);
  g.line(x + w, y + h + dist, x + w, y + h + dist + len);    
  g.line(x - dist, y, x - dist - len, y);
  g.line(x - dist, y + h, x - dist - len, y + h);
  g.line(x + w + dist, y, x + w + dist + len, y);
  g.line(x + w + dist, y + h, x + w + dist + len, y + h);
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
