import tomc.gpx.*;
import processing.pdf.*;

/* TODO
 elevation
 - color for depth?
 - stroke width for depth?
 */

GPX gpx;
boolean makepdf = false;
boolean in3d = false;
boolean update = true;
boolean issmooth = false;
float minlat = -90, maxlat = 90, minlon = -180, maxlon = 180;
float eminlat = 90, emaxlat = -90, eminlon = 180, emaxlon = -180; // Intitialize extents data
int rotation = 0;
PFont font;
String statusmessage = "";
String title = "";

//int strokecolor = #000000, bgcolor = #FFFFFF, strokealpha = 128; // Default black on white
int strokecolor = #FFFFFF, bgcolor = #00355b, strokealpha = 128; // blueprint-like

void setup(){
  if(in3d){
    size(1050, 700, P3D);
  }else{
    size(1050, 700);
  }
  
  font = loadFont("Roadgeek2000SeriesE-24.vlw");
  textFont(font);
  fill(strokecolor);
  stroke(strokecolor, strokealpha);

  //minlat = 41.5; maxlat = 42.1; minlon = -88.32; maxlon = -87.65; // Chicago Area
  //minlat = 35.86; maxlat = 35.915; minlon = -106.34; maxlon = -106.24; // Los Alamos Area


  gpx = new GPX(this);
  //gpx.parse("/Users/cluening/gpx/20100705.gpx");

  //String gpxpath = selectFolder();
  String gpxpath = "/home/cluening/gpx";
  String[] files = listFileNames(gpxpath);

  if(files == null){
    print("No files!\n");
    statusmessage = "No files found.";
  }
  else{
    print("Parsing...");
    for(int i=0; i<files.length; i++){
      gpx.parse(gpxpath + "/" + files[i]);
    }
    print(" Done!\n");
  }

}

void draw(){
  GPXPoint prevpt;
  PGraphics pdf = null;

  if(makepdf){
    pdf = createGraphics(6400, 4266, PDF, "map.pdf");
    pdf.beginDraw();
    pdf.background(255);
  }

  if(update){
    background(bgcolor);
    if(in3d){
      rotateX(radians(rotation));
    }
    print("Redrawing\n");  

    if(!makepdf){
      text(statusmessage, 5, textAscent());
    }
    text(title, width-(textWidth(title)+5), height-textDescent());

    for (int i = 0; i < gpx.getTrackCount(); i++) {
      GPXTrack trk = gpx.getTrack(i);
      // do something with trk.name
      //print("Got a track: " + trk.name + "\n");
      prevpt = null;
      for (int j = 0; j < trk.size(); j++) {
        GPXTrackSeg trkseg = trk.getTrackSeg(j);
        for (int k = 0; k < trkseg.size(); k++) {
          GPXPoint pt = trkseg.getPoint(k);
          // do something with pt.lat or pt.lon
          if(prevpt != null){
            if(in3d){
              line(         map((float)prevpt.lon, minlon, maxlon, 0, width),
                   height - map((float)prevpt.lat, minlat, maxlat, 0, height),
                            map((float)prevpt.ele, 0, 3000, 0, 300),
                            map((float)pt.lon, minlon, maxlon, 0, width),
                   height - map((float)pt.lat, minlat, maxlat, 0, height),
                            map((float)pt.ele, 0, 3000, 0, 300));
            }else if(makepdf){
              pdf.line(         map((float)prevpt.lon, minlon, maxlon, 0, pdf.width),
                   pdf.height - map((float)prevpt.lat, minlat, maxlat, 0, pdf.height),
                                map((float)pt.lon, minlon, maxlon, 0, pdf.width),
                   pdf.height - map((float)pt.lat, minlat, maxlat, 0, pdf.height));
            }else{
              line(         map((float)prevpt.lon, minlon, maxlon, 0, width),
                   height - map((float)prevpt.lat, minlat, maxlat, 0, height),
                            map((float)pt.lon, minlon, maxlon, 0, width),
                   height - map((float)pt.lat, minlat, maxlat, 0, height));
            }
          }
          prevpt = pt;
        }
      }
    }
    print("Done.\n");
    update = false;
  }
  if(makepdf){
    pdf.dispose();
    pdf.endDraw();
    makepdf = false;
    statusmessage = "";
    update = true;
  }
}

void findextents(){    
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
  // FIXME: Do aspect ratio correcting stuff here.
}

void mouseClicked(){
  print("Clicked!\n");

  float londiff = maxlon - minlon;
  float latdiff = maxlat - minlat;
  float mouselat, mouselon;

  print("mousex: " + mouseX + "\n");

  mouselat = map(height - mouseY, 0, height, minlat, maxlat);
  mouselon = map(mouseX, 0, width, minlon, maxlon);

  print("Mouselat/lon: " + mouselat + ", " + mouselon + "\n");

  if(mouseButton == LEFT){
    print("Zooming in!\n");

    minlat = mouselat - latdiff/4;
    maxlat = mouselat + latdiff/4;

    minlon = mouselon - londiff/4;
    maxlon = mouselon + londiff/4;

    if(minlat < -90) minlat = -90;
    if(maxlat > 90) maxlat = 90;
    if(minlon < -180) minlon = -180;
    if(maxlon > 180) maxlon = 180;

    print("New extents: " + minlat + ", " + minlon + " -> " + maxlat + ", " + maxlon + "\n");
  }
  else if(mouseButton == RIGHT){
    print("Zooming out!\n");

    minlat = mouselat - latdiff;
    maxlat = mouselat + latdiff;

    minlon = mouselon - londiff;
    maxlon = mouselon + londiff;

    if(minlat < -90) minlat = -90;
    if(maxlat > 90) maxlat = 90;
    if(minlon < -180) minlon = -180;
    if(maxlon > 180) maxlon = 180;

    print("New extents: " + minlat + ", " + maxlat + " -> " + minlon + ", " + maxlon + "\n");
  }

  update = true;
}

void mouseDragged(){
  float londiff;
  float latdiff;
  float mouselat, mouselon, pmouselat, pmouselon;
  
  mouselat = map(height - mouseY, 0, height, minlat, maxlat);
  mouselon = map(mouseX, 0, width, minlon, maxlon);
  pmouselat = map(height - pmouseY, 0, height, minlat, maxlat);
  pmouselon = map(pmouseX, 0, width, minlon, maxlon);

  londiff = pmouselon - mouselon;
  latdiff = pmouselat - mouselat;

  minlat += latdiff;
  maxlat += latdiff;
  minlon += londiff;
  maxlon += londiff;

  update = true;
}

void keyPressed(){
  print("Got key!\n");
  if(key == CODED){
    if(keyCode == UP){
      print("Rotating up...\n");
      rotation -= 5;
    } else if(keyCode == DOWN){
      print("Rotating down...\n");
      rotation += 5;
    }
  }
  if(key == 'p'){
    print("Printing!\n");
    statusmessage = "Saving to PDF...";
    update = true;
    redraw();
    makepdf = true;
  }else if(key == 's'){
    if(issmooth){
      noSmooth();
      issmooth = false;
    }else{
      smooth();
      issmooth = true;
    }
  }else if(key == '0'){
    minlat =  -90;
    maxlat =   90;
    minlon = -180;
    maxlon =  180;
  }else if(key == 'w'){
    print("Saving image...");
    save("map.png");
    print("Done.");
  }

  update = true;
}

String[] listFileNames(String dir) {
  File file = new File(dir);
  if (file.isDirectory()) {
    String names[] = file.list();
    return names;
  } 
  else {
    // If it's not a directory
    return null;
  }
}



