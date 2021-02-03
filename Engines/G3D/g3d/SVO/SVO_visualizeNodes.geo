#version 420
/**
  \file data-files/shader/SVO/SVO_visualizeNodes.geo

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/

#extension GL_NV_gpu_shader5 : enable
#extension GL_EXT_shader_image_load_store : enable
#extension GL_EXT_bindable_uniform : enable
#extension GL_NV_shader_buffer_load : enable

/** True if this node or one of its parents does not exist */
in int                 discardThisNode[];
in float               radius[];

out vec4 vertColor;

layout(points) in;
layout(line_strip, max_vertices=16) out;

void glBegin() {}
void glEnd() { EndPrimitive(); }

void glVertex3f(float x, float y, float z){
	gl_Position = vec4(x, y, z, 1.0f) * g3d_ObjectToScreenMatrixTranspose;
	EmitVertex();
}

/**
  \param p1 minimum corner
  \param p2 maximum corner
 */
void drawWireCube(vec3 p1, vec3 p2){
    glBegin();
	glVertex3f(p1.x,	p1.y,  p1.z);
	glVertex3f(p1.x,	p2.y,  p1.z);
	glVertex3f(p2.x,	p2.y,  p1.z);
	glVertex3f(p2.x,	p1.y,  p1.z);
	glVertex3f(p1.x,	p1.y,  p1.z);
	glVertex3f(p1.x,	p1.y,  p2.z);
    glEnd();

    glBegin();
	glVertex3f(p1.x,	p2.y,  p2.z);
	glVertex3f(p2.x,	p2.y,  p2.z);
	glVertex3f(p2.x,	p1.y,  p2.z);
	glVertex3f(p1.x,	p1.y,  p2.z);
	glVertex3f(p1.x,	p2.y,  p2.z);	
	glVertex3f(p1.x,	p2.y,  p1.z);
    glEnd();

    glBegin();
	glVertex3f(p2.x,	p2.y,  p1.z);
	glVertex3f(p2.x,	p2.y,  p2.z);
    glEnd();

    glBegin();
	glVertex3f(p2.x,	p1.y,  p1.z);
	glVertex3f(p2.x,	p1.y,  p2.z);
    glEnd();
}

#if 0
void drawCube(vec3 p1, vec3 p2){

	glVertex3f(p1.x, p1.y,  p2.z);
	glVertex3f(p1.x,  p2.y,  p2.z);
	glVertex3f( p2.x,  p2.y,  p2.z);
	glVertex3f( p2.x, p1.y,  p2.z);

	EndPrimitive();

	// Back Face
	glVertex3f(p1.x, p1.y, p1.z);
	glVertex3f( p2.x, p1.y, p1.z);
	glVertex3f( p2.x,  p2.y, p1.z);
	glVertex3f(p1.x,  p2.y, p1.z);

	EndPrimitive();

	// Top Face
	glVertex3f(p1.x,  p2.y, p1.z); 
	glVertex3f( p2.x,  p2.y, p1.z); 
	glVertex3f( p2.x,  p2.y,  p2.z);
	glVertex3f(p1.x,  p2.y,  p2.z);

	EndPrimitive();

	// Bottom Face
	glVertex3f(p1.x, p1.y, p1.z); 
	glVertex3f(p1.x, p1.y,  p2.z);   
	glVertex3f( p2.x, p1.y,  p2.z);  
	glVertex3f( p2.x, p1.y, p1.z);   

	EndPrimitive();

	// Right face
	glVertex3f( p2.x, p1.y, p1.z);   
	glVertex3f( p2.x, p1.y,  p2.z);   
	glVertex3f( p2.x,  p2.y,  p2.z);    
	glVertex3f( p2.x,  p2.y, p1.z);    

	EndPrimitive();

	// Left Face
	glVertex3f(p1.x, p1.y, p1.z);    
	glVertex3f(p1.x,  p2.y, p1.z);    
	glVertex3f(p1.x,  p2.y,  p2.z);    
	glVertex3f(p1.x, p1.y,  p2.z);    

	EndPrimitive();
}
#endif

in vec3 voxColor[];

void main() {
    if (discardThisNode[0] == 0) {
		//vertColor=vec4(gl_in[0].gl_Position.xyz, 1.0f);
		vertColor = vec4(voxColor[0], 1.0f);

    	/*drawWireCube(gl_in[0].gl_Position.xyz - vec3(radius[0]),
                     gl_in[0].gl_Position.xyz + vec3(radius[0]));*/

		drawWireCube(gl_in[0].gl_Position.xyz,
                     gl_in[0].gl_Position.xyz + vec3(radius[0]*2.0f) );
    }
}

