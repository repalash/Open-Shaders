
// Binary Glitch - based on Luminosity.
// use the Mouse to effect the strength.


// by D34N 4L3X
// dean@neuroid.co.uk

// adapted to processing by cansik 2018

#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D texture;

varying vec4 vertColor;
varying vec4 vertTexCoord;

uniform float strength;

void main()
{
    float x = vertTexCoord.x;
    float y = vertTexCoord.y;
   
    // get snapped position
    float psize = 0.04 * strength;
    float psq = 1.0 / psize;

    float px = floor(x * psq + 0.5) * psize;
    float py = floor(y * psq + 0.5) * psize;
    
	vec4 colSnap = texture2D(texture, vec2(px,py));
    
	float lum = pow(1.0 - (colSnap.r + colSnap.g + colSnap.b) / 3.0, strength); // remove the minus one if you want to invert luma
    
    // do move with lum as multiplying factor
    float qsize = psize * lum;
    
    float qsq = 1.0 / qsize;

    float qx = floor( x * qsq + 0.5) * qsize;
    float qy = floor( y * qsq + 0.5) * qsize;

    float rx = (px - qx) * lum + x;
    float ry = (py - qy) * lum + y;
    
	vec4 colMove = texture2D(texture, vec2(rx,ry));

    // final color
    gl_FragColor = colMove;
}