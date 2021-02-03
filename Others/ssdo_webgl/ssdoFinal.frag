#ifdef GL_ES
precision highp float;
#endif

// input buffers
uniform sampler2D directLightBuffer;
uniform sampler2D indirectBounceBuffer;

varying vec2 vUv;

void main()
{
	vec4 color = texture2D(directLightBuffer, vUv);
	
	color += texture2D(indirectBounceBuffer, vUv);

	gl_FragColor = color;
}

