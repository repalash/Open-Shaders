#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D texture;

uniform float amount;
uniform float falloff;

varying vec4 vertColor;
varying vec4 vertTexCoord;

void main() {
    vec4 color = texture2D(texture, vertTexCoord.xy);

    float dist = distance(vertTexCoord.xy, vec2(0.5, 0.5));
    color.rgb *= smoothstep(0.8, falloff * 0.799, dist * (amount + falloff));

    gl_FragColor = color;
}
