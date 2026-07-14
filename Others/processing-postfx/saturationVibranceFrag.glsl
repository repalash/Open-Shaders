#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D texture;

varying vec4 vertColor;
varying vec4 vertTexCoord;

uniform float saturation;
uniform float vibrance;

void main() {
    vec4 col = texture2D(texture, vertTexCoord.xy);
    vec3 color = col.rgb;
    float luminance = color.r*0.299 + color.g*0.587 + color.b*0.114;
    float mn = min(min(color.r, color.g), color.b);
    float mx = max(max(color.r, color.g), color.b);
    float sat = (1.0-(mx - mn)) * (1.0-mx) * luminance * 5.0;
    vec3 lightness = vec3((mn + mx)/2.0);

    // vibrance
    color = mix(color, mix(color, lightness, -vibrance), sat);
    // negative vibrance
    color = mix(color, lightness, (1.0-lightness)*(1.0-vibrance)/2.0*abs(vibrance));
    // saturation
    color = mix(color, vec3(luminance), -saturation);

    gl_FragColor = vec4(mix(col.rgb, color, col.a), col.a);
}