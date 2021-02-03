/**
  \file data-files/shader/VoxelSurface/our.glsl

  Our ray-box intersection

  Parameterized on three macros (can be const in bool GLSL, but that changes the signature of the function):

  RAY_CAN_START_IN_BOX
  :   You can avoid three operations if you know that the ray origin is outside of the box.
      That's true for scenes modeled from opaque objects.
      
      In the general case of transparent objects (or two-sided boxes), you need to test for
      this case and flip the sense of the backface
      test when the ray is in the box. Note that if all that you care about is the intersection
      itself (e.g., you're doing BVH traversal without looking at the distance),
      then the answer is always "yes, the ray hits the box", since you're inside of it,
      and this isn't necessary.
  
   If a distanceToPlane is negative, then the intersection is behind the ray origin and we
   want to ignore it. If a distance is positive, then we need to find the intersection
   point and see if the hit is in bounds. Because we're only considering front faces
   and boxes are convex, we don't have to see which intersection occurs first--any intersection
   with a face must be the only one.      

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef our_glsl
#define our_glsl
#include "Box.glsl"

#include <g3dmath.glsl>


bool ourIntersectBoxCommon(Box box, Ray ray, out float distance, out vec3 normal, const bool rayCanStartInBox, const in bool oriented, in vec3 _invRayDirection) {

    // Move to the box's reference frame. This is unavoidable and un-optimizable.
    ray.origin = box.rotation * (ray.origin - box.center);
    if (oriented) {
        ray.direction = box.rotation * ray.direction;
    }
    
    // This "rayCanStartInBox" branch is evaluated at compile time because `const` in GLSL
    // means compile-time constant. The multiplication by 1.0 will likewise be compiled out
    // when rayCanStartInBox = false.
    float winding;
    if (rayCanStartInBox) {
        // Winding direction: -1 if the ray starts inside of the box (i.e., and is leaving), +1 if it is starting outside of the box
        winding = (maxComponent(abs(ray.origin) * box.invRadius) < 1.0) ? -1.0 : 1.0;
    } else {
        winding = 1.0;
    }

    // We'll use the negated sign of the ray direction in several places, so precompute it.
    // The sign() instruction is fast...but surprisingly not so fast that storing the result
    // temporarily isn't an advantage.
    Vector3 sgn = -sign(ray.direction);

	// Ray-plane intersection. For each pair of planes, choose the one that is front-facing
    // to the ray and compute the distance to it.
    Vector3 distanceToPlane = box.radius * winding * sgn - ray.origin;
    if (oriented) {
        distanceToPlane /= ray.direction;
    } else {
        distanceToPlane *= _invRayDirection;
    }

    // Perform all three ray-box tests and cast to 0 or 1 on each axis. 
    // Use a macro to eliminate the redundant code (no efficiency boost from doing so, of course!)
    // Could be written with 
#   define TEST(U, VW)\
         /* Is there a hit on this axis in front of the origin? Use multiplication instead of && for a small speedup */\
         (distanceToPlane.U >= 0.0) && \
         /* Is that hit within the face of the box? */\
         all(lessThan(abs(ray.origin.VW + ray.direction.VW * distanceToPlane.U), box.radius.VW))

    bvec3 test = bvec3(TEST(x, yz), TEST(y, zx), TEST(z, xy));

    // CMOV chain that guarantees exactly one element of sgn is preserved and that the value has the right sign
    sgn = test.x ? vec3(sgn.x, 0.0, 0.0) : (test.y ? vec3(0.0, sgn.y, 0.0) : vec3(0.0, 0.0, test.z ? sgn.z : 0.0));    

    /*
    // Slower version that interlaces the moves and tests
    sgn = TEST(x, yz) ? vec3(sgn.x, 0.0, 0.0) : (TEST(y, zx) ? vec3(0.0, sgn.y, 0.0) : vec3(0.0, 0.0, TEST(z, xy) ? sgn.z : 0.0));    
    */

    /*   
    // Another slower version, using multiplication masking and test as a float vec3
    // If the intersection was on the x axis, knock out the yz mask
    test.yz *= 1.0 - test.x;
    // If the intersection was in y, copy the bit
    sgn.y   *= test.y;
    // If the intersection was in y, knock out the xz mask
    sgn.xz  *= (1.0 - test.y) * test.xz;
    */
#   undef TEST
        
    // At most one element of sgn is non-zero now. That element carries the negative sign of the 
    // ray direction as well. Notice that we were able to drop storage of the test vector from registers,
    // because it will never be used again.

    // Mask the distance by the non-zero axis
    // Dot product is faster than this CMOV chain, but doesn't work when distanceToPlane contains nans or infs. 
    //
    distance = (sgn.x != 0.0) ? distanceToPlane.x : ((sgn.y != 0.0) ? distanceToPlane.y : distanceToPlane.z);

    /*
    // This cast is slower; presumably != 0 is in a condition code
    // distance = bool(sgn.x) ? distanceToPlane.x : (bool(sgn.y) ? distanceToPlane.y : distanceToPlane.z);
    */

    // Thus our code above has to protect against nan and inf.
    // Need to protect against nan in fields of distancetoPlane that won't be used
    // distance = dot(distanceToPlane, abs(sgn));

    // Normal must face back along the ray. If you need
    // to know whether we're entering or leaving the box, 
    // then just look at the value of winding. If you need
    // texture coordinates, then use box.invDirection * hitPoint.
    
    if (oriented) {
        normal = sgn * box.rotation;
    } else {
        normal = sgn;
    }
    
    // The following one line avoids the matrix product, but is actually slower,
    // presumably because it still has to do all of the multiplications for the conditional moves
    //    normal = (test.x > 0.0) ? sgn.x * box.rotation[0] : ((test.y > 0.0) ? sgn.y * box.rotation[1] : sgn.z * box.rotation[2]);

    // Was there a hit on any axis? 
    // Use abs(sgn) here, since abs() is free on a GPU...and
    // thus allow the registers from the test variable or a boolean hit variable 
    // to be reclaimed for use during the matrix product above.
    // Saves about 6% by reducing peak register count
    // 
    // Slowest: (abs(sgn.x) + abs(sgn.y) + abs(sgn.z)) > 0.0;
    // Slower: bool(abs(sgn.x) + abs(sgn.y) + abs(sgn.z));

    // Fastest:
    return (sgn.x != 0) || (sgn.y != 0) || (sgn.z != 0);
}


// Just determines whether the ray hits the axis-aligned box.
// invRayDirection is guaranteed to be finite for all elements.
bool ourHitAABox(vec3 boxCenter, vec3 boxRadius, vec3 rayOrigin, vec3 rayDirection, vec3 invRayDirection) {
    rayOrigin -= boxCenter;
    vec3 distanceToPlane = (-boxRadius * sign(rayDirection) - rayOrigin) * invRayDirection;    

#   define TEST(U, V,W)\
         (float(distanceToPlane.U >= 0.0) * \
          float(abs(rayOrigin.V + rayDirection.V * distanceToPlane.U) < boxRadius.V) *\
          float(abs(rayOrigin.W + rayDirection.W * distanceToPlane.U) < boxRadius.W))

    // If the ray is in the box or there is a hit along any axis, then there is a hit
    return bool(float(abs(rayOrigin.x) < boxRadius.x) * 
                float(abs(rayOrigin.y) < boxRadius.y) * 
                float(abs(rayOrigin.z) < boxRadius.z) + 
                TEST(x, y, z) + 
                TEST(y, z, x) + 
                TEST(z, x, y));
#   undef TEST
}


// There isn't really much application for ray-AABB where we don't check if the ray is in the box, so we
// just give a dummy implementation here to allow the test harness to compile.
bool ourOutsideHitAABox(vec3 boxCenter, vec3 boxRadius, vec3 rayOrigin, vec3 rayDirection, vec3 invRayDirection) {
    return ourHitAABox(boxCenter, boxRadius, rayOrigin, rayDirection, invRayDirection);
}

// Ray is always outside of the box
bool ourOutsideIntersectBox(Box box, Ray ray, out float distance, out vec3 normal, const in bool oriented, in vec3 _invRayDirection) {
    return ourIntersectBoxCommon(box, ray, distance, normal, false, oriented, _invRayDirection);
}

bool ourIntersectBox(Box box, Ray ray, out float distance, out vec3 normal, const in bool oriented, in vec3 _invRayDirection) {
    return ourIntersectBoxCommon(box, ray, distance, normal, true, oriented, _invRayDirection);
}


#endif
