#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D texture;

varying vec4 vertColor;
varying vec4 vertTexCoord;

uniform float brightness;
uniform float contrast;

void main() {
    vec4 c = texture2D(texture, vertTexCoord.st) * vertColor;
    vec3 colorContrasted = c.rgb * contrast;
    vec3 bright = colorContrasted + vec3(brightness, brightness, brightness);

    gl_FragColor = vec4(bright, c.a);
}