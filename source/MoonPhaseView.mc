using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Application as App;
using Toybox.Math as Math;
using Toybox.Time as Time;

var fast_updates = true;  // check if user looks at his fenix3 is set in onhide() at the end of source code
var width, height, device_settings;
var prim_color = Gfx.COLOR_RED;  // primary color
var sec_color = Gfx.COLOR_DK_RED; // secondary color
var pic_Moon;

var SYNODIC = 29.53058867; //constante pour la période synodique

class MoonPhaseView extends Ui.WatchFace {

    //! Load your resources here
    function onLayout(dc) {
     	width = dc.getWidth();
     	height = dc.getHeight();
     	device_settings = Sys.getDeviceSettings(); // general device settings like 24or12h mode
     	pic_Moon = null;
     	pic_Moon = Ui.loadResource(Rez.Drawables.Moon);
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    }

    //! Update the view
    function onUpdate(dc) {
    
    	// clear the screen, just draw a black rectangle
    	dc.setColor( Gfx.COLOR_BLACK,  Gfx.COLOR_BLACK);
    	dc.fillRectangle(0, 0, width, height);
    	dc.clear();
    
        //READ TIME, DATE and stuff like that
        var clockTime = Sys.getClockTime();
        var dateStrings = Time.Gregorian.info( Time.now(), Time.FORMAT_MEDIUM);
        var dateStrings_s = Time.Gregorian.info( Time.now(), Time.FORMAT_SHORT);
        var hour, min, time, day, sec, month;
        var jour;
        var x=0;
        day  = dateStrings.day;
        month  = dateStrings.month;
        min  = clockTime.min;
        hour = clockTime.hour;
        sec  = clockTime.sec;
          
        jour = CalcPhase();
    
        dc.drawBitmap (0,0,pic_Moon);	
        
        // Now we are going to draw a filled circle of the same diameter of the pic, just to hide the moon
		if (jour < SYNODIC/2) {
			x = 109 - (jour*218)/(SYNODIC/2);	
		} else {
			x = 109 - (jour-SYNODIC)*(218/(SYNODIC/2));
		}
		
        dc.setColor( Gfx.COLOR_BLACK,  Gfx.COLOR_BLACK);
        dc.fillCircle(x, 109, 109);
        
        // READ activity data (steps, movebar level)
        var activity = ActivityMonitor.getInfo();
        
        // Draw the thin 60 Minute lines
        draw_min(dc,60,1,(height/2),(height/2-12), Gfx.COLOR_DK_GRAY,360); 
        
        // draw the big 5 Min lines
        draw_min(dc,12,3,(height/2),(height/2-20), Gfx.COLOR_DK_BLUE,360);  

        // draw tiny date-circle
        dc.setColor( Gfx.COLOR_WHITE,  Gfx.COLOR_WHITE);
        dc.fillCircle(width/2, height-height/4, 15);

        //write day of month
		dc.setColor( Gfx.COLOR_BLACK,  Gfx.COLOR_TRANSPARENT);
        dc.drawText(width/2, height-height/4-15, Gfx.FONT_MEDIUM, day.toString(), Gfx.TEXT_JUSTIFY_CENTER);
      	
      	draw_watch_finger(dc,hour,min,sec);
      	drawArbor(dc);
        
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
        fast_updates = false;
        Ui.requestUpdate();
    }

    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
        fast_updates = true;    // indicator that everythings goes fast now (fast = 1 sec per update)    
        Ui.requestUpdate();
    }

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
        fast_updates = false;
        Ui.requestUpdate();
    }
    
    // Draw a polygon    
	// @param dc Device Context to Draw
	// @param coords Polygon coordinates of the hand
    
    function drawPolygon (dc,coords,thickness) {
    	var i;
    	dc.setPenWidth (thickness);
    	for (i=0; i<coords.size(); i++) {
	    	
    		if (i<coords.size()-1 ) {
    			dc.drawLine (coords[i][0],coords[i][1], coords[i+1][0],coords[i+1][1]);
    		} else {
    			dc.drawLine (coords[i][0], coords[i][1],coords[0][0],coords[0][1]);
    		}
    	}
    }
    
	// Draw a rotated polygon
	// @param dc Device Context to Draw
	// @param angle Angle of the polygon
	// @param coords Polygon coordinates of the hand
	// @param filled 0 if the polygon is to be filled
	// Well, sinus and cosinus were a long long time ago, the code may be optimized a little bit
	
	function drawRotatedPolygon(dc, angle, coords, filled){
		var result = new [coords.size()];
		var centerX = dc.getWidth() / 2;
		var centerY = dc.getHeight() / 2;
		var cos = Math.cos(angle + Math.PI);
		var sin = Math.sin(angle + Math.PI);

		// Transform the coordinates to apply the needed rotation

		for (var i = 0; i < coords.size(); i += 1) {
			var x = (coords[i][0] * cos) - (coords[i][1] * sin);
			var y = (coords[i][0] * sin) + (coords[i][1] * cos);
			result[i] = [centerX + x, centerY + y];
		}
		// Draw the polygon, considering if it needs to be filled
		if (filled == 0) {
			dc.fillPolygon(result);
		} else {
			drawPolygon (dc,result,filled);
		}
	}
	
	// Draw a Hand
	// @param dc Device context to draw to
	// @param angle Angle of the watch hand
	// @param shape of the hand, with colors. Basically a n dimension array of an 3D array containing : the polygon and the color and if whenever the polygon is filled or not
	
	function drawHand (dc, angle, shape) {
		var i;
		for (i=0;i<shape.size();i++) {
			dc.setColor(shape[i][1], shape[i][1]);
			drawRotatedPolygon(dc, angle, shape[i][0],shape[i][2]);
		}
	
	}   
	
	function drawArbor (dc) {

		dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
		dc.fillCircle(width / 2, height / 2, 7);
		// Inner arbor
		dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_DK_BLUE);
		dc.fillCircle(width / 2, height / 2, 3);
		dc.setColor(Gfx.COLOR_DK_BLUE,Gfx.COLOR_DK_BLUE);
		dc.drawCircle(width / 2, height / 2, 3);

	}
    
    // draw the analog watch fingers
    // dc, 14, 23 , COLOR, penWidhth hour, PenWidthmin, inner radian, hour radian, minite radian           
    function draw_watch_finger(dc,hour, min, sec){
    	var hourHand,minuteHand, secondHand;
    	var minuteLength=85;
    	var minuteWidth=4;
    	var minuteShape = [
    		[[
				[-minuteWidth ,minuteLength-2*minuteWidth],
				[minuteWidth ,minuteLength-2*minuteWidth],
				[0 ,minuteLength]
			],Gfx.COLOR_DK_BLUE, 0],
			[[
				[-minuteWidth,0],
				[minuteWidth,0],
				[minuteWidth,(minuteLength - 2*minuteWidth)],
				[-minuteWidth,(minuteLength - 2*minuteWidth)]
			],Gfx.COLOR_DK_BLUE, 0],
			[[
				[-minuteWidth,0],
				[minuteWidth,0],
				[minuteWidth,-minuteLength/8],
				[-minuteWidth,-minuteLength/8]
			], Gfx.COLOR_DK_BLUE, 0],
			[[
				[-minuteWidth+2,minuteLength/5],
				[minuteWidth-2,minuteLength/5],
				[minuteWidth-2,(minuteLength - 2*minuteWidth)-2],
				[-minuteWidth+2,(minuteLength - 2*minuteWidth)-2]
			],Gfx.COLOR_DK_GREEN, 0]
		];
    	var hourLength=55;
		var hourWidth = 4;
		var hourShape = [
			[[
				[-hourWidth*3 ,hourLength-3*hourWidth],
				[hourWidth*3 ,hourLength-3*hourWidth],
				[0 ,hourLength]
			], Gfx.COLOR_DK_BLUE,0],
			[[
				[-hourWidth,0],
				[hourWidth,0],
				[hourWidth,(hourLength - 3*hourWidth)],
				[-hourWidth,(hourLength - 3*hourWidth)]
			], Gfx.COLOR_DK_BLUE,0],
			[[
				[-hourWidth,0],
				[hourWidth,0],
				[hourWidth,-hourLength/5],
				[-hourWidth,-hourLength/5]
			], Gfx.COLOR_DK_BLUE,0],
			[[
				[-hourWidth+2,hourLength/5],
				[hourWidth-2,hourLength/5],
				[hourWidth-2,(hourLength - 2*hourWidth)-2],
				[-hourWidth+2,(hourLength - 2*hourWidth)-2]
			],Gfx.COLOR_DK_GREEN, 0]
		];
    	var secondLength = 100;
		var secondWidth = 2;
		// Define shape of the hand
		//Point
		var secondShape = [
			[[
				[-secondWidth ,secondLength-2*secondWidth],
				[secondWidth ,secondLength-2*secondWidth],
				[0 ,secondLength]
			], Gfx.COLOR_DK_RED,0],
			[[
				[-secondWidth,0],
				[secondWidth,0],
				[secondWidth,(secondLength - 2*secondWidth)],
				[-secondWidth,(secondLength - 2*secondWidth)]
			], Gfx.COLOR_DK_RED,0],
			[[
				[ -secondWidth,0],
				[ -secondWidth*3,-secondLength/5],
				[ secondWidth*3,-secondLength/5],
				[ secondWidth,0]
			], Gfx.COLOR_DK_GRAY,0]
		];

    	//DRAW HANDS
    		
        hourHand = (((hour % 12) * 60) + min);
        hourHand = hourHand / (12 * 60.0);
        hourHand = hourHand * Math.PI * 2;
		drawHand (dc,hourHand,hourShape); 
		
		minuteHand = (min / 60.0) * Math.PI * 2;
		drawHand (dc,minuteHand,minuteShape);
		
		if (fast_updates) {
			secondHand = (sec / 60.0) * Math.PI * 2;
			drawHand (dc,secondHand, secondShape);
		
		}
    }

    // draw minute and 5 minute lines

    function draw_min(dc,divisor,pen,rad1,rad2, color, maxdeg){  
            var xx, x, yy, y, winkel;
            winkel = 0;
            dc.setPenWidth(pen);
            dc.setColor( Gfx.COLOR_WHITE,  color);
            for (var k = 0; k <divisor; k++){
                winkel =   k * (360/divisor);
                winkel = winkel.toFloat();
                if (winkel < maxdeg){
	                yy  = rad1 + rad2 * ( Math.cos(Math.PI*((180+-1*winkel.toFloat())/180)));
	                y = rad1 + rad1 * ( Math.cos(Math.PI*((180+-1*winkel.toFloat())/180)));  
	                xx  = rad1 + rad2 * ( Math.sin(Math.PI*((180+-1*winkel.toFloat())/180)));
	                x = rad1 + rad1 *  ( Math.sin(Math.PI*((180+-1*winkel.toFloat())/180)));
	                // draw line
					dc.setColor( color,  color);
					dc.drawLine(x, y, xx, yy);
				}                
             }
            dc.setPenWidth(1);
    }
  
	function CalcPhase() {

		var MSPARJOUR = 24 * 60 * 60 * 1000; //constante pour le nombre de millisecondes par jour

		var DateRef, Today, msDiff;
		var mfullMoon;
		var phase,day;

		var fullMoon = { :second => 0, :hour => 8, :minute => 53, :year => 2003, :month => 7, :day => 29	};
	
	  	mfullMoon = Time.Gregorian.moment(fullMoon); 
		DateRef = mfullMoon.value();
  		Today = Time.now().value(); //date du jour
  		msDiff = (Today - DateRef)*1000.0 + 86400000.0; //on calcule la différence en millisecondes
  		phase = (msDiff * 100.0 )/(SYNODIC * 86400000.0); //on calcule le pourcentage de la phase
  		while(phase>100) {
	   		phase -= 100;
		}
	
		day = SYNODIC*phase/100;
	  	return day;

	}

}
