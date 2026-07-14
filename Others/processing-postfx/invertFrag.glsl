#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D texture;

varying vec4 vertColor;
varying vec4 vertTexCoord;

void main() {
    vec4 c = texture2D(texture, vertTexCoord.st) * vertColor;
    c.xyz = 1.0 - c.xyz;
    gl_FragColor = c;
}