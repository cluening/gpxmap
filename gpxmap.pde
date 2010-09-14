/*  
 *  gpxmap - a simple sketch that will load a directory full of GPX files,
 *  render them on a draggable/zoomable map, and allow PDF and PNG export.
 *
 *  Version 0.5
 *
 *  Copyright (C) 2010  Cory Lueninghoener <cluening@gmail.com>
 *  http://www.wirelesscouch.net/labs/gpxmap
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  AMDG
 */

import tomc.gpx.*;
import processing.pdf.*;

/* TODO
 elevation
 - color for depth?
 - stroke width for depth?
 */

GPX gpx;
boolean makepdf = false;
boolean update = true;
boolean issmooth = true;
boolean isloaded = false;
boolean animate = false;
boolean drawvignette = true;
float minlat = -90, maxlat = 90, minlon = -180, maxlon = 180;
PFont font;
String statusmessage = "";
String title = "";
int trknum = Integer.MAX_VALUE, trksegnum = Integer.MAX_VALUE, trkptnum = Integer.MAX_VALUE;
boolean showbar;
int barlimit = 26, barbottom = 26;
int startmillis;
int zoomlevel = 0;
String[] buttons = {"r: Reset View", "p: Save PDF", "e: Export PNG", "z: Zoom Extents"};
String savepath;
PImage vignette;
PVector momentum = new PVector(0, 0);

//int strokecolor = #000000, bgcolor = #FFFFFF, strokealpha = 128; // black on white
int strokecolor = #FFFFFF, bgcolor = #00355b, strokealpha = 128; // blueprint-like
//int strokecolor = #FFFFFF, bgcolor = #000000, strokealpha = 128; //white on black

/*
 *   The Processing-mandated setup() function
 */
void setup(){
  size(1050, 700, P2D);
  
  font = loadFont("Roadgeek2000SeriesE-24.vlw");
  textFont(font);

  vignette = loadImage("vignette.png");

  smooth();

  //minlat = 41.5; maxlat = 42.1; minlon = -88.32; maxlon = -87.65; // Chicago Area
  //minlat = 35.86; maxlat = 35.915; minlon = -106.34; maxlon = -106.24; // Los Alamos Area

  background(bgcolor);
  gpx = new GPX(this);
  //gpx.parse("/Users/cluening/gpx/20100705.gpx");

  //String gpxpath = selectFolder();
  String gpxpath = "/home/cluening/gpx";
  String[] files = listFileNames(gpxpath);

  if(files == null){
    gpxpath = selectFolder();
    files = listFileNames(gpxpath);
  }
  
  //files = null;

  if(files == null){
    print("No files!\n");
    statusmessage = "No files found.";
  }
  else{
    loadfiles(gpxpath, files);
  }
}


/*
 *  The Processing-mandated draw() function.  Also saves PDFs.
 */
void draw(){
  GPXPoint pt, prevpt;
  GPXTrack trk;
  GPXTrackSeg trkseg;
  PGraphics pdf = null;
  int ptstep;
  SimpleDateFormat format = new SimpleDateFormat("yyyy/MM/dd");
  boolean gotdate = false;

  if(makepdf){
    pdf = createGraphics(6400, 4266, PDF, savepath);
    pdf.beginDraw();
    pdf.background(255);
  }

  if(mouseY < barlimit){
    showbar = true;
  }else{
    showbar = false;
  }
  
  if(showbar && barbottom < barlimit){
    barbottom += 3;
    update = true;
  }
  else if(!showbar && barbottom > 0){
    barbottom -= 3;
    update = true;
  }
  
  if(update){
    startmillis = millis();
    background(bgcolor);
    stroke(strokecolor, strokealpha);
    fill(strokecolor);
    
    //print("Redrawing\n");  

    if(!makepdf){
      text(statusmessage, width-(textWidth(statusmessage)+5), height-textDescent());
    }
    //text(title, width-(textWidth(title)+5), height-textDescent());

    for (int i = 0; i < trknum && i < gpx.getTrackCount(); i++) {
      trk = gpx.getTrack(i);
      prevpt = null;
      gotdate = false;
      for (int j = 0; j < trk.size(); j++) {
        trkseg = trk.getTrackSeg(j);
        if(zoomlevel < 5) ptstep = 6;
          else if(zoomlevel < 7) ptstep = 4;
          else if(zoomlevel < 11) ptstep = 2;
          else ptstep = 1;
        for (int k = 0; k < trkseg.size(); k += ptstep) {
          pt = trkseg.getPoint(k);
          if(prevpt != null){
            if(animate && !gotdate){
              statusmessage = format.format(pt.time);
              gotdate = true;
            }
            if(makepdf){
              pdf.line(         map((float)prevpt.lon, minlon, maxlon, 0, pdf.width),
                   pdf.height - map((float)prevpt.lat, minlat, maxlat, 0, pdf.height),
                                map((float)pt.lon, minlon, maxlon, 0, pdf.width),
                   pdf.height - map((float)pt.lat, minlat, maxlat, 0, pdf.height));
            }else{
              // Try to only draw if we need to.  This saves a lot of time on large data sets
              if((prevpt.lon > minlon && prevpt.lon < maxlon) ||
                 (pt.lon > minlon && pt.lon < maxlon) ||
                 (prevpt.lat > minlat && prevpt.lat < maxlat) ||
                 (pt.lat > minlat && pt.lat < maxlat)){

                line(         map((float)prevpt.lon, minlon, maxlon, 0, width),
                     height - map((float)prevpt.lat, minlat, maxlat, 0, height),
                              map((float)pt.lon, minlon, maxlon, 0, width),
                     height - map((float)pt.lat, minlat, maxlat, 0, height));
              }
            }
          }
          prevpt = pt;
        }
      }
    }
    if(trknum < gpx.getTrackCount()){
      trknum++;
      update = true;
    }
    else{
      animate = false;
      update = false;
    }
    //print("Redrew in " + (millis() - startmillis) + " ms, zoom level " + zoomlevel + "\n");
    if(drawvignette == true){
      image(vignette, 0, 0);
    }
    drawbuttonbar();
  }

  if(momentum.mag() > 0){
    //print("Momentum: " + momentum.mag() + " (" + momentum.x + ", " + momentum.y + ")" + "\n");
    momentum.div(1.3);
    if(momentum.mag() < .01){
      momentum.x = 0;
      momentum.y = 0;
    }else{
      //move(map(momentum.y, 0, height, minlat, maxlat), map(momentum.x, 0, width, minlon, maxlon));
      //print("Moving! " + map(momentum.x, 0, width, 0, maxlon-minlon) + "\n");
      move(map(momentum.y, 0, height, 0, maxlat - minlat), map(momentum.x, 0, width, 0, maxlon - minlon));
      update = true;
    }
  }

  if(makepdf){
    pdf.dispose();
    pdf.endDraw();
    makepdf = false;
    statusmessage = "";
    update = true;
  }
}

/*
 *  Draw a dropdown bar with buttons or information labels
 */
void drawbuttonbar(){
  float textheight = textAscent() - (barlimit - barbottom - 2);
  int y = 10;

  fill(255, 255, 255, 128);
  noStroke();
  rect(0, 0, width, barbottom);
  
  fill(0, 0, 0);
  for(int i=0; i<buttons.length; i++){
    text(buttons[i], y, textheight);
    y += textWidth(buttons[i]) + 20;
  }

}

/*
 *  Find the extents of the current data set.
 */
void findextents(){    
  float diff = 0, ndiff;
  float fheight = height, fwidth = width;
  float eminlat = 90, emaxlat = -90, eminlon = 180, emaxlon = -180;
  float nminlat, nmaxlat, nminlon, nmaxlon;
  
  for (int i = 0; i < gpx.getTrackCount(); i++) {
    GPXTrack trk = gpx.getTrack(i);
    // do something with trk.name
    for (int j = 0; j < trk.size(); j++) {
      GPXTrackSeg trkseg = trk.getTrackSeg(j);
      for (int k = 0; k < trkseg.size(); k++) {
        GPXPoint pt = trkseg.getPoint(k);
        // do something with pt.lat or pt.lon
        if(pt.lat < eminlat){
          eminlat = (float)pt.lat;
        }
        if(pt.lat > emaxlat){
          emaxlat = (float)pt.lat;
        }
        if(pt.lon < eminlon){
          eminlon = (float)pt.lon;
        }
        if(pt.lon > emaxlon){
          emaxlon = (float)pt.lon;
        }
      }
    }
  }

  if((emaxlat - eminlat)/(emaxlon - eminlon) > (fheight/fwidth)){
    //print("Fixing lon\n");
    diff = ((fwidth * (emaxlat - eminlat))/fheight);
    nminlat = eminlat;
    nmaxlat = emaxlat;
    nminlon = (emaxlon - eminlon)/2.0 + eminlon - diff/2;
    nmaxlon = (emaxlon - eminlon)/2.0 + eminlon + diff/2;
  }else if((emaxlat - eminlat)/(emaxlon - eminlon) < (fheight/fwidth)){
    //print("Fixing lat\n");
    diff = ((fheight * (emaxlon - eminlon))/fwidth);
    nminlat = (emaxlat - eminlat)/2.0 + eminlat - diff/2;
    nmaxlat = (emaxlat - eminlat)/2.0 + eminlat + diff/2;
    nminlon = eminlon;
    nmaxlon = emaxlon;
  }else{
    nminlat = eminlat;
    nmaxlat = emaxlat;
    nminlon = eminlon;
    nmaxlon = emaxlon;
  }

  diff = maxlon - minlon;
  ndiff = nmaxlon - nminlon;

  if(diff > ndiff){
    while(diff > ndiff){
      diff /= 2;
      zoomlevel++;
    }
  }else{
    while(ndiff > diff){
      ndiff /= 2;
      zoomlevel++;
    }
  }

  //print("New zoom level: " + zoomlevel + "\n");

  minlat = nminlat;
  maxlat = nmaxlat;
  minlon = nminlon;
  maxlon = nmaxlon;
}

/*
 *  Handle mouse clicks.  Left-click to zoom in, right-click to zoom out.
 */
void mouseClicked(){
  //print("Clicked!\n");

  float londiff = maxlon - minlon;
  float latdiff = maxlat - minlat;
  float mouselat, mouselon;

  momentum.x = 0;
  momentum.y = 0;

  //print("mousex: " + mouseX + "\n");

  mouselat = map(height - mouseY, 0, height, minlat, maxlat);
  mouselon = map(mouseX, 0, width, minlon, maxlon);

  //print("Mouselat/lon: " + mouselat + ", " + mouselon + "\n");

  if(mouseButton == LEFT){
    //print("Zooming in!\n");

    zoomlevel++;
    
    minlat = mouselat - latdiff/4;
    maxlat = mouselat + latdiff/4;

    minlon = mouselon - londiff/4;
    maxlon = mouselon + londiff/4;

    if(minlat < -90) minlat = -90;
    if(maxlat > 90) maxlat = 90;
    if(minlon < -180) minlon = -180;
    if(maxlon > 180) maxlon = 180;

    //print("New extents: " + minlat + ", " + minlon + " -> " + maxlat + ", " + maxlon + "\n");
  }
  else if(mouseButton == RIGHT){
    //print("Zooming out!\n");

    zoomlevel--;
    if(zoomlevel < 0) zoomlevel = 0;
    
    minlat = mouselat - latdiff;
    maxlat = mouselat + latdiff;

    minlon = mouselon - londiff;
    maxlon = mouselon + londiff;

    if(minlat < -90) minlat = -90;
    if(maxlat > 90) maxlat = 90;
    if(minlon < -180) minlon = -180;
    if(maxlon > 180) maxlon = 180;

    //print("New extents: " + minlat + ", " + maxlat + " -> " + minlon + ", " + maxlon + "\n");
  }

  //print("New clicked zoomlevel: " + zoomlevel + "\n");

  update = true;
}

/*
 *  Handle mouse dragging events.  This does all of the panning calculation.
 */

void mouseDragged(){
  float londiff;
  float latdiff;
  float mouselat, mouselon, pmouselat, pmouselon;
  
  mouselat = map(mouseY, height, 0, minlat, maxlat);
  mouselon = map(mouseX, 0, width, minlon, maxlon);
  pmouselat = map(pmouseY, height, 0, minlat, maxlat);
  pmouselon = map(pmouseX, 0, width, minlon, maxlon);

  move(pmouselat - mouselat, pmouselon - mouselon);
  
  update = true;
}

void move(float latdiff, float londiff){
  if((minlat + latdiff >= -90) && (maxlat + latdiff <= 90)){
    minlat += latdiff;
    maxlat += latdiff;
  }
  if((minlon + londiff >= -180) && (maxlon + londiff <= 180)){
    minlon += londiff;
    maxlon += londiff;
  }
}

void mouseReleased(){
  momentum.x = pmouseX - mouseX;
  momentum.y = mouseY - pmouseY; // Backwards because of backwards coordinate system.
  
  if(momentum.mag() > 5){
    momentum.mult(2);
  }else{
    momentum.x = 0;
    momentum.y = 0;
  }
}

/*
 *  Handle key presses.
 */
void keyPressed(){
  //print("Got key!\n");
  if(key == 'p'){
    savepath = selectOutput();
    makepdf = true;
  }else if(key == 's'){
    if(issmooth){
      noSmooth();
      issmooth = false;
    }else{
      smooth();
      issmooth = true;
    }
  }else if(key == 'r'){
    minlat =  -90;
    maxlat =   90;
    minlon = -180;
    maxlon =  180;
    zoomlevel = 0;
  }else if(key == 'e'){
    savepath = selectOutput();
    if(savepath != null){
      save(savepath);
    }
  }else if(key == 'z'){
    findextents();
  }else if(key == 'a'){
    animate = true;
    trknum = 0;
  }else if(key == 'v'){
    if(drawvignette){
      drawvignette = false;
    }else{
      drawvignette = true;
    }
  }

  update = true;
}

/*
 *  Load the selected files into the earlier-defined "gpx" object.
 */
void loadfiles(String path, String[] files){
  print("Parsing...");
  for(int i=0; i<files.length; i++){
    //print("Parsing " + files[i] + "\n");
    gpx.parse(path + "/" + files[i]);
  }
  print(" Done!\n");
}

/*
 *  Find all of the files contained in a selected directory.
 */
String[] listFileNames(String dir) {
  File file = new File(dir);
  if (file.isDirectory()) {
    String names[] = file.list();

    Arrays.sort(names);

    return names;
  } 
  else {
    // If it's not a directory
    return null;
  }
}



