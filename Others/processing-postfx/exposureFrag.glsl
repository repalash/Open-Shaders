#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

uniform sampler2D texture;

varying vec4 vertColor;
varying vec4 vertTexCoord;

vec3 n;

uniform float exposure = 0.0;

void main() {
    vec4 c = texture2D(texture, vertTexCoord.st) * vertColor;
    vec3 n = c.rgb * pow(2.0, exposure);
    gl_FragColor = vec4(n, c.a);
}