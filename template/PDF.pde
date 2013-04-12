/*
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 * PDF
 * A slightly modified PGraphicsPDF class which permits, 
 * among a few other things, to set colors in CMYK space.
 * Written and used at Resonate.io, Belgrade, 2013
 * Andreas Gysin
 * www.ertdfgcvb.com
 *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 * Part of the Processing project - http://processing.org
 *
 * Copyright (c) 2005-11 Ben Fry and Casey Reas
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License version 2.1 as published by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General
 * Public License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA
 */



import java.awt.Font;
import java.awt.Graphics2D;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.Map;

import com.lowagie.text.*;
import com.lowagie.text.pdf.*;

public class PDF extends PGraphicsJava2D {
  protected File file;
  protected OutputStream output;
  protected Document document;
  protected PdfWriter writer;
  protected PdfContentByte content;
  protected DefaultFontMapper mapper;
  protected String fontList[];

  // AG: field overrides
  protected float width, height; // we want to define width and height as float
  CMYKColor fillColor, strokeColor;

  // AG: additional fields
  private PdfImportedPage template;

  // AG: alternate constructor
  public PDF(PApplet p, float w, float h, String out) {
    // initialize "by hand"
    setParent(p);
    setPrimary(false);
    setPath(out);
    setSize(w, h);
    beginDraw();
  }

  // AG: setSize for float values
  public void setSize(float w, float h) {
    this.width = w;
    this.height = h;
    allocate();
    reapplySettings();
  }

  // AG: a reminder if accessed as a PGraphics instance 
  // the super.width (int = 0) will be returner… so take care.
  public float getWidth() {
    return this.width;
  }
  public float getHeight() {
    return this.width;
  }

  // AG: in case int values are used
  @Override
    public void setSize(int w, int h) {
    setSize((float) w, (float) h);
  }

  // AG: CMYK Methods
  public void strokeCMYK(float c, float m, float y, float k) {
    strokeColorObject = new CMYKColor(c, m, y, k);
    stroke = true;
  }

  public void strokeCMYK(float c, float m, float y, float k, float amount) {
    amount = Math.min(1f, amount);
    strokeColorObject = new CMYKColor(c * amount, m * amount, y * amount, k * amount);
    stroke = true;
  }

  public void strokeCMYK(CMYKColor col) {
    // make a copy
    strokeColorObject = new CMYKColor(col.getCyan(), col.getMagenta(), col.getYellow(), col.getBlack());
    stroke = true;
  }

  public void strokeK(float k) {
    // GrayColor uses whitness as parameter
    strokeColorObject = new GrayColor(1f - k); 
    stroke = true;
  }

  public void fillCMYK(float c, float m, float y, float k) {
    fillColorObject = new CMYKColor(c, m, y, k);
    fill = true;
  }

  public void fillCMYK(float c, float m, float y, float k, float amount) {
    amount = Math.min(1f, amount);
    fillColorObject = new CMYKColor(c * amount, m * amount, y * amount, k * amount);
    fill = true;
  }

  public void fillCMYK(CMYKColor col) {
    // make a copy
    fillColorObject = new CMYKColor(col.getCyan(), col.getMagenta(), col.getYellow(), col.getBlack());
    fill = true;
  }

  public void fillK(float k) {
    fillColorObject = new GrayColor(1f - k);
    fill = true;
  }

  // AG: Spot Methods
  public void fillSpot(String spotColorName, float opacity, float c, float m, float y, float k) {
    PdfSpotColor psc = new PdfSpotColor(spotColorName, opacity, new CMYKColor(c, m, y, k));
    fillColorObject = new SpotColor(psc);
    fill = true;
  }

  // AG: Overpint Methods
  public void overPrint(boolean useOverPrint) {
    PdfGState gs = new PdfGState();
    if (useOverPrint) {
      gs.setOverPrintMode(1);
      gs.setOverPrintNonStroking(true);
      gs.setOverPrintStroking(true);
    } 
    else {
      gs.setOverPrintMode(0);
      gs.setOverPrintNonStroking(false);
      gs.setOverPrintStroking(false);
    }
    content.setGState(gs);
  }

  // AG: template
  public int getPageNumber() {
    // return document.getPageNumber();
    return writer.getCurrentPageNumber();
  }

  // AG: template
  public void loadTemplate(String in) {
    PdfReader reader = null;
    try {
      reader = new PdfReader(in);
    } 
    catch (IOException e) {
      e.printStackTrace();
    }
    template = writer.getImportedPage(reader, 1);
  }
  
  // AG: the transform matrix is ignored 
  public void applyTemplate() {
    applyTemplate(0, 0);
  }

  public void applyTemplate(float x, float y) {
    if (template != null) {
      content.addTemplate(template, x, y);
    }
  }

  // ////////////////////////////////////////////////////////////////

  @Override
    public void setPath(String path) {
    this.path = path;
    if (path != null) {
      file = new File(path);
      if (!file.isAbsolute()) file = null;
    }
    if (file == null) {
      throw new RuntimeException("PGraphicsPDF requires an absolute path " + "for the location of the output file.");
    }
  }

  /**
   	 * Set the library to write to an output stream instead of a file.
   	 */
  public void setOutput(OutputStream output) {
    this.output = output;
  }

  /**
   	 * all the init stuff happens in here, in case someone calls size()
   	 * along the way and wants to hork things up.
   	 */
  @Override
    protected void allocate() {
    // can't do anything here, because this will be called by the
    // superclass PGraphics, and the file/path object won't be set yet
    // (since super() called right at the beginning of the constructor)
  }

  @Override
    protected void defaultSettings() { // ignore
    super.defaultSettings();
    textMode = SHAPE;
  }

  @Override
    public void beginDraw() {
    // long t0 = System.currentTimeMillis();

    if (document == null) {
      document = new Document(new Rectangle(width, height));
      try {
        if (file != null) {
          // BufferedOutputStream output = new BufferedOutputStream(stream, 16384);
          output = new BufferedOutputStream(new FileOutputStream(file), 16384);
        } 
        else if (output == null) {
          throw new RuntimeException("PGraphicsPDF requires a path " + "for the location of the output file.");
        }
        writer = PdfWriter.getInstance(document, output);


        document.open();
        //content = writer.getDirectContent();
        content = writer.getDirectContentUnder();
        // template = content.createTemplate(width, height);
      } 
      catch (Exception e) {
        e.printStackTrace();
        throw new RuntimeException("Problem saving the PDF file.");
      }

      // System.out.println("beginDraw fonts " + (System.currentTimeMillis() - t));
      // g2 = content.createGraphics(width, height, getMapper());
      // if (textMode == SHAPE) {
      g2 = content.createGraphicsShapes(width, height);                        
      // } else if (textMode == MODEL) {
      // g2 = content.createGraphics(width, height, getMapper());
      // }
      // g2 = createGraphics();
      // g2 = template.createGraphics(width, height, mapper);
    }
    // System.out.println("beginDraw " + (System.currentTimeMillis() - t0));
    super.beginDraw();

    // Also need to push the matrix since the matrix doesn't reset on each run
    // http://dev.processing.org/bugs/show_bug.cgi?id=1227
    pushMatrix();
  }

  protected DefaultFontMapper getMapper() {
    if (mapper == null) {
      // long t = System.currentTimeMillis();
      mapper = new DefaultFontMapper();

      if (PApplet.platform == PConstants.MACOSX) {
        try {
          String homeLibraryFonts = System.getProperty("user.home") + "/Library/Fonts";
          mapper.insertDirectory(homeLibraryFonts);
        } 
        catch (Exception e) {
          // might be a security issue with getProperty() and user.home
          // if this sketch is running from the web
        }
        // add the system font paths
        mapper.insertDirectory("/System/Library/Fonts");
        mapper.insertDirectory("/Library/Fonts");
      } 
      else if (PApplet.platform == PConstants.WINDOWS) {
        // how to get the windows fonts directory?
        // could be c:\winnt\fonts or c:\windows\fonts or not even c:
        // maybe do a Runtime.exec() on echo %WINDIR% ?
        // Runtime.exec solution might be a mess on systems where the
        // the backslash/colon characters not really used (i.e. JP)

        // find the windows fonts folder
        File roots[] = File.listRoots();
        for (int i = 0; i < roots.length; i++) {
          if (roots[i].toString().startsWith("A:")) {
            // Seems to be a problem with some machines that the A:
            // drive is returned as an actual root, even if not available.
            // This won't fix the issue if the same thing happens with
            // other removable drive devices, but should fix the
            // initial/problem as cited by the bug report:
            // http://dev.processing.org/bugs/show_bug.cgi?id=478
            // If not, will need to use the other fileExists() code below.
            continue;
          }

          File folder = new File(roots[i], "WINDOWS/Fonts");
          if (folder.exists()) {
            mapper.insertDirectory(folder.getAbsolutePath());
            break;
          }
          folder = new File(roots[i], "WINNT/Fonts");
          if (folder.exists()) {
            mapper.insertDirectory(folder.getAbsolutePath());
            break;
          }
        }
      } 
      else if (PApplet.platform == PConstants.LINUX) {
        checkDir("/usr/share/fonts/", mapper);
        checkDir("/usr/local/share/fonts/", mapper);
        checkDir(System.getProperty("user.home") + "/.fonts", mapper);
      }
      // System.out.println("mapping " + (System.currentTimeMillis() - t));
    }
    return mapper;
  }

  protected void checkDir(String path, DefaultFontMapper mapper) {
    File folder = new File(path);
    if (folder.exists()) {
      mapper.insertDirectory(path);
      traverseDir(folder, mapper);
    }
  }

  /**
   	 * Recursive walk to get all subdirectories for font fun.
   	 * Patch submitted by Matthias Breuer.
   	 * (<a href="http://dev.processing.org/bugs/show_bug.cgi?id=1566">Bug 1566</a>)
   	 */
  protected void traverseDir(File folder, DefaultFontMapper mapper) {
    File[] files = folder.listFiles();
    for (int i = 0; i < files.length; i++) {
      if (files[i].isDirectory()) {
        mapper.insertDirectory(files[i].getPath());
        traverseDir(new File(files[i].getPath()), mapper);
      }
    }
  }

  @Override
    public void endDraw() {
    // Also need to pop the matrix since the matrix doesn't reset on each run
    // http://dev.processing.org/bugs/show_bug.cgi?id=1227
    popMatrix();

    // This needs to be overridden so that the endDraw() from PGraphicsJava2D
    // is not inherited (it calls loadPixels).
    // http://dev.processing.org/bugs/show_bug.cgi?id=1169
  }

  /**
   	 * Gives the same basic functionality of File.exists but can be
   	 * used to look for removable media without showing a system
   	 * dialog if the media is not present. Workaround pulled from the
   	 * <A HREF="http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=4089199">
   	 * bug report</A> on bugs.sun.com. This bug was fixed in Java 6, and we
   	 * can remove the workaround when we start requiring Java 6.
   	 */
  protected boolean fileExists(File file) {
    try {
      Process process = Runtime.getRuntime().exec(new String[] { 
        "cmd.exe", "/c", "dir", file.getAbsolutePath()
      }
      );

      // We need to consume all available output or the process will block.
      boolean haveExitCode = false;
      int exitCode = -1;
      InputStream out = process.getInputStream();
      InputStream err = process.getErrorStream();

      while (!haveExitCode) {
        while (out.read () >= 0) {
        }
        while (err.read () >= 0) {
        }

        try {
          exitCode = process.exitValue();
          haveExitCode = true;
        } 
        catch (IllegalThreadStateException e) {
          // Not yet complete.
          Thread.sleep(100);
        }
      }
      // int exitCode = process.waitFor();
      return exitCode == 0;
    } 
    catch (IOException e) {
      System.out.println("Unable to check for file: " + file + " : " + e);
      return false;
    } 
    catch (InterruptedException e) {
      System.out.println("Unable to check for file.  Interrupted: " + file + " : " + e);
      return false;
    }
  }

  /**
   	 * Call to explicitly go to the next page from within a single draw().
   	 */
  public void nextPage() {
    PStyle savedStyle = getStyle();
    endDraw();
    g2.dispose();

    try {
      // writer.setPageEmpty(false); // maybe useful later
      document.newPage(); // is this bad if no addl pages are made?
    } 
    catch (Exception e) {
      e.printStackTrace();
    }
    g2 = createGraphics();

    beginDraw();
    style(savedStyle);
  }

  protected Graphics2D createGraphics() {
    if (textMode == SHAPE) {
      return content.createGraphicsShapes(width, height);
    } 
    else if (textMode == MODEL) {
      return content.createGraphics(width, height, getMapper());
    }
    // Should not be reachable...
    throw new RuntimeException("Invalid textMode() selected for PDF.");
  }

  @Override
    public void dispose() {
    this.endDraw();
    if (document != null) {
      g2.dispose();
      document.close(); // can't be done in finalize, not always called
      document = null;
    }
    // new Exception().printStackTrace(System.out);
  }

  /**
   	 * Don't open a window for this renderer, it won't be used.
   	 */
  @Override
    public boolean displayable() {
    return false;
  }

  /*
	 * protected void finalize() throws Throwable {
   	 * System.out.println("calling finalize");
   	 * //document.close(); // do this in dispose instead?
   	 * }
   	 */

  // ////////////////////////////////////////////////////////////

  /*
	 * public void endRecord() {
   	 * super.endRecord();
   	 * dispose();
   	 * }
   	 *
   	 *
   	 * public void endRaw() {
   	 * System.out.println("ending raw");
   	 * super.endRaw();
   	 * System.out.println("disposing");
   	 * dispose();
   	 * System.out.println("done");
   	 * }
   	 */

  // ////////////////////////////////////////////////////////////

  /*
	 * protected void rectImpl(float x1, float y1, float x2, float y2) {
   	 * //rect.setFrame(x1, y1, x2-x1, y2-y1);
   	 * //draw_shape(rect);
   	 * System.out.println("rect implements");
   	 * g2.fillRect((int)x1, (int)y1, (int) (x2-x1), (int) (y2-y1));
   	 * }
   	 *
   	 *
   	 * /*
   	 * public void clear() {
   	 * g2.setColor(Color.red);
   	 * g2.fillRect(0, 0, width, height);
   	 * }
   	 */

  // ////////////////////////////////////////////////////////////

  /*
	 * protected void imageImplAWT(java.awt.Image awtImage,
   	 * float x1, float y1, float x2, float y2,
   	 * int u1, int v1, int u2, int v2) {
   	 * pushMatrix();
   	 * translate(x1, y1);
   	 * int awtImageWidth = awtImage.getWidth(null);
   	 * int awtImageHeight = awtImage.getHeight(null);
   	 * scale((x2 - x1) / (float)awtImageWidth,
   	 * (y2 - y1) / (float)awtImageHeight);
   	 * g2.drawImage(awtImage,
   	 * 0, 0, awtImageWidth, awtImageHeight,
   	 * u1, v1, u2, v2, null);
   	 * popMatrix();
   	 * }
   	 */

  // ////////////////////////////////////////////////////////////

  @Override
    public void textFont(PFont which) {
    super.textFont(which);
    checkFont();
    // Make sure a native version of the font is available.
    // if (textFont.getFont() == null) {
    // throw new RuntimeException("Use createFont() instead of loadFont() " +
    // "when drawing text using the PDF library.");
    // }
    // Make sure that this is a font that the PDF library can deal with.
    // if ((textMode != SHAPE) && !checkFont(which.getName())) {
    // System.err.println("Use PGraphicsPDF.listFonts() to get a list of available fonts.");
    // throw new RuntimeException("The font “" + which.getName() + "” cannot be used with PDF Export.");
    // }
  }

  /**
   	 * Change the textMode() to either SHAPE or MODEL. <br/>
   	 * This resets all renderer settings, and therefore must
   	 * be called <EM>before</EM> any other commands that set the fill()
   	 * or the textFont() or anything. Unlike other renderers,
   	 * use textMode() directly after the size() command.
   	 */
  @Override
    public void textMode(int mode) {
    if (textMode != mode) {
      if (mode == SHAPE) {
        textMode = SHAPE;
        g2.dispose();
        // g2 = content.createGraphicsShapes(width, height);
        g2 = createGraphics();
      } 
      else if (mode == MODEL) {
        textMode = MODEL;
        g2.dispose();
        // g2 = content.createGraphics(width, height, mapper);
        g2 = createGraphics();
        // g2 = template.createGraphics(width, height, mapper);
      } 
      else if (mode == SCREEN) {
        throw new RuntimeException("textMode(SCREEN) not supported with PDF");
      } 
      else {
        throw new RuntimeException("That textMode() does not exist");
      }
    }
  }

  @Override
    protected void textLineImpl(char buffer[], int start, int stop, float x, float y) {
    checkFont();
    super.textLineImpl(buffer, start, stop, x, y);
  }

  // ////////////////////////////////////////////////////////////

  @Override
    public void loadPixels() {
    nope("loadPixels");
  }

  @Override
    public void updatePixels() {
    nope("updatePixels");
  }

  @Override
    public void updatePixels(int x, int y, int c, int d) {
    nope("updatePixels");
  }

  //

  @Override
    public int get(int x, int y) {
    nope("get");
    return 0; // not reached
  }

  @Override
    public PImage get(int x, int y, int c, int d) {
    nope("get");
    return null; // not reached
  }

  @Override
    public PImage get() {
    nope("get");
    return null; // not reached
  }

  @Override
    public void set(int x, int y, int argb) {
    nope("set");
  }

  @Override
    public void set(int x, int y, PImage image) {
    nope("set");
  }

  //

  @Override
    public void mask(int alpha[]) {
    nope("mask");
  }

  @Override
    public void mask(PImage alpha) {
    nope("mask");
  }

  //

  @Override
    public void filter(int kind) {
    nope("filter");
  }

  @Override
    public void filter(int kind, float param) {
    nope("filter");
  }

  //

  @Override
    public void copy(int sx1, int sy1, int sx2, int sy2, int dx1, int dy1, int dx2, int dy2) {
    nope("copy");
  }

  @Override
    public void copy(PImage src, int sx1, int sy1, int sx2, int sy2, int dx1, int dy1, int dx2, int dy2) {
    nope("copy");
  }

  //

  public void blend(int sx, int sy, int dx, int dy, int mode) {
    nope("blend");
  }

  public void blend(PImage src, int sx, int sy, int dx, int dy, int mode) {
    nope("blend");
  }

  @Override
    public void blend(int sx1, int sy1, int sx2, int sy2, int dx1, int dy1, int dx2, int dy2, int mode) {
    nope("blend");
  }

  @Override
    public void blend(PImage src, int sx1, int sy1, int sx2, int sy2, int dx1, int dy1, int dx2, int dy2, int mode) {
    nope("blend");
  }

  //

  @Override
    public boolean save(String filename) {
    nope("save");
    return false;
  }

  // ////////////////////////////////////////////////////////////

  /**
   	 * Add a directory that should be searched for font data. <br/>
   	 * On Mac OS X, the following directories are added by default:
   	 * <UL>
   	 * <LI>/System/Library/Fonts
   	 * <LI>/Library/Fonts
   	 * <LI>~/Library/Fonts
   	 * </UL>
   	 * On Windows, all drive letters are searched for WINDOWS\Fonts
   	 * or WINNT\Fonts, any that exists is added. <br/>
   	 * <br/>
   	 * On Linux or any other platform, you'll need to add the
   	 * directories by hand. (If there are actual standards here that we
   	 * can use as a starting point, please file a bug to make a note of it)
   	 */
  public void addFonts(String directory) {
    mapper.insertDirectory(directory);
  }

  /**
   	 * Check whether the specified font can be used with the PDF library.
   	 *
   	 * @param name
   	 *        name of the font
   	 * @return true if it's ok
   	 */
  protected void checkFont() {
    Font awtFont = (Font) textFont.getNative();
    if (awtFont == null) { // always need a native font or reference to it
      throw new RuntimeException("Use createFont() instead of loadFont() " + "when drawing text using the PDF library.");
    } 
    else if (textMode != SHAPE) {
      if (textFont.isStream()) {
        throw new RuntimeException("Use textMode(SHAPE) with PDF when loading " + ".ttf and .otf files with createFont().");
      } 
      else if (mapper.getAliases().get(textFont.getName()) == null) {
        // System.out.println("alias for " + name + " = " + mapper.getAliases().get(name));
        // System.err.println("Use PGraphicsPDF.listFonts() to get a list of " +
        // "fonts that can be used with PDF.");
        // throw new RuntimeException("The font “" + textFont.getName() + "” " +
        // "cannot be used with PDF Export.");
        if (textFont.getName().equals("Lucida Sans")) {
          throw new RuntimeException("Use textMode(SHAPE) with the default " + "font when exporting to PDF.");
        } 
        else {
          throw new RuntimeException("Use textMode(SHAPE) with " + "“" + textFont.getName() + "” " + "when exporting to PDF.");
        }
      }
    }
  }

  /**
   	 * List the fonts known to the PDF renderer. This is like PFont.list(),
   	 * however not all those fonts are available by default.
   	 */
  public String[] listFonts() {
    if (fontList == null) {
      HashMap<?, ?> map = getMapper().getAliases();
      // Set entries = map.entrySet();
      // fontList = new String[entries.size()];
      fontList = new String[map.size()];
      int count = 0;
      for (Object entry : map.entrySet()) {
        fontList[count++] = (String) ((Map.Entry) entry).getKey();
      }
      // Iterator it = entries.iterator();
      // int count = 0;
      // while (it.hasNext()) {
      // Map.Entry entry = (Map.Entry) it.next();
      // //System.out.println(entry.getKey() + "-->" + entry.getValue());
      // fontList[count++] = (String) entry.getKey();
      // }
      fontList = PApplet.sort(fontList);
    }
    return fontList;
  }

  // ////////////////////////////////////////////////////////////

  protected void nope(String function) {
    throw new RuntimeException("No " + function + "() for PGraphicsPDF");
  }
}

