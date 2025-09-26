// Compofiller Studio by Yzi 2018
//
// Default template shader

// This shader program is executed in the GPU (or a CPU-based emulation) for
// every pixel (i.e. "fragment" in OpenGL jargon) of every frame.

// The "uniforms" are the same (i.e. uniform) for all pixels/fragments of the frame,
// and they come from the main program.
uniform float time;
uniform vec2 resolution;

// If you choose to save some bytes and not use either of these uniforms, you have to
// do some additional tricks.
//   * time : if you uncheck "[ ] Use time uniform" checkbox, time is in gl_Color.y (green component)
//   * resolution : if you uncheck "[ ] Use resolution uniform" checkbox, you'll have to hard-code the resolution manually

// The uniform-less version could look like this, 88200.0 being the time divider
//float time = gl_Color.y * 256.0 * (65536.0 / 88200.0);
//vec2 resolution = vec2(1280.0, 720.0);

// Uncomment this to use the texture-based features
uniform sampler2D texture_sampler;

// Uncomment this to use the texture-based features
uniform sampler2D texts;


float bar = time; // this is just a coding nicety to highlight that in some calculations we want musical time ... you wouldn't want to have this in a real prod's final version

float maxballs = 0.0;
float globalfade = 0.0;


vec3 lipo = vec3(sin(time*2.7)*3.0, 4.0+sin(time*1.7)*2.0, -1.0+sin(time*1.9)*8.0), // light position
  lico = vec3(1.0, .8, .6)  * (1.0 + sin(time * .3) * 0.3) *  (1.0+fract(bar)*fract(bar*4.0)); // light color


float sphere(vec3 p, float r)
{
  return length(p) - r;
}

// handy function for keeping track of both the closest distance, and which material that surface is
vec2 matmin(vec2 mm, float d, float m)
{
  if (d < mm.x)
    return vec2(d, m);
  else
    return mm;
}

float sqr(float f) { return f*f; }

// signed distance to floor / ground plane, from point p, towards direction rd, floor at height fh
float sdtf(vec3 p, vec3 rd, float fh)
{
  float y = p.y-fh;
  float yzd = sqrt(sqr(y)+sqr(rd.z * y / rd.y)+sqr(rd.x * y / rd.y));
  return yzd * sign(y);
}

// total distance function, sometimes this is called "scene" in ray marchers, because it describes all the things you have in your 3d world
float df(vec3 p, vec3 rd, inout float m)
{  
  float fd = sdtf(p, rd, -2.0); // floor distance, using the ray direction
  vec2 r = vec2(fd, -1.0);

  for (float i=0.0;i<7.0;i+=1.0) {
    if (i >= maxballs) break;
    r = matmin(r, sphere(p - vec3(11.0-i*4.0, 0.0 + sin(i+time), 5.0+sin(i*2.+time*2.3)*1.8), 2.0), 1.0 + i);
  }
  // light source ball
  if (m!=0.0)
    r = matmin(r, sphere(p - lipo, 1.0), 0.0);
  m = r.y;
  return r.x;
}

float shade(vec3 p)
{
  vec3 lv=normalize(lipo-p);
  float r=1.0, s=.4;
  p += lv*s;
  for (float i=0.0;i<100.0;i+=1.0) {
    float dummy=0.0, d=df(p, lv, dummy);
    r=min(r, d/s);
    p += lv*d*0.1;
    if (distance(p, lipo) < 0.1) break;
  }
  return r;
}


void main(void)
{
  vec2 uv = vec2(gl_FragCoord.xy / resolution);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);

if (time > 0.0) {

// -------------- demo timings, hit points, what happens when  -------------
  
  globalfade = smoothstep(0.0, 1.0, bar); // fade in

  if (bar <= 4.0) {
	maxballs = 0.0;
  } else if (bar < 8.0) {
	maxballs = 5.0;
  } else if (bar < 12.0) {
	maxballs = 2.0;
  } else if (bar < 16.0) {
	maxballs = 2.0;
  } else if (bar < 24.0) {
	maxballs = 2.0;
  } else if (bar < 29.0) {
	maxballs = 2.0;
  } else if (bar < 31.0) {
	maxballs = 2.0 - floor((bar - 30.0) * 2.0);
  } else {
	globalfade = smoothstep(32.0, 31.0, bar);
  }


// -------------- rendering loop -------------

  vec3 ro=vec3(sin(time*.31)*2.0, 12.0 + sin(time*.13), -15.0 + sin(time*.37)*5.0), // ray origin
    lap=vec3(0.0, 0.0, 1.0),  // look-at point
    fwv=normalize(lap-ro),    // forward vector
    upv=vec3(0.0, 1.0, 0.0),  // up vector
    rtv=cross(upv, fwv);      // right vector
    upv=cross(fwv, rtv);      // up vector, fixed
  mat3 rotmat=mat3(rtv, upv, fwv); // rotation matrix
  vec3 sp=rotmat*vec3(uv, 1.0)+ro, // "screen position", gl_FragCoord.xy mapped to our 3d world
    rd=normalize(sp-ro),      // ray direction
    p=ro;                     // p : our point that marches in space to where the ray direction vector points

  float contrib=1.0; // contribution : how much light contribution is left
  vec3 l=vec3(0.0);  // light/color accumulator that's used for the output pixel/fragment color at the end

  // ray marching loop
  for (float i=0.0; i<100.0; i+=1.0) {
    float m=1.0, // material number
      d=df(p, rd, m); // distance to nearest surface

    if (d<0.0) // did we step inside a surface? step back then
      { p += d*rd; d = 0.0; }

    // are we close enough to a surface to count this as a "hit"
    if (d<0.000001) {
      float a=m; // dymmy
      vec3 e=vec3(0.001, 0.0, 0.0), // "epsilon"
          nv = normalize(vec3(df(p-e.xyy, rd, a), df(p-e.yxy, rd, a), df(p-e.yyx, rd, a))), // surface normal vector
          lv = normalize(p-lipo), // light vector,
          matcol = vec3(mod(m*.9, 1.0), mod(m*.7, 1.0), mod(m*.5, 1.0)); // material color

      if (m!=0.0) {

         l = mix(l,
            max(dot(lv, nv),0.0)*matcol*lico*shade(p),
            contrib); 

        contrib *= 0.2;
        if (contrib < 0.01) break;
        rd = reflect(rd, nv);
        p += rd * .0001;
      } else {
        l = mix(l,
            lico,
            contrib);
      }
    } else { // ray marching didn't hit anything (yet)
      p += rd*d; // <-- step forwards 
      // if you have more complex objects than spheres and a plane in your 3d scene
      // you might want to take shorter steps, like 
      //     p += rd*d * 0.9;
    }
    
    if (length(p) > 99.0) break; // stop marching if we went too far
  } // for ray marching loop


// Uncomment this if you want to try the "Previous frame as texture" feature
//  if (mod(bar, 4.0) > 2.0) l = (l * .1 + .51 * (texture2D(texture_sampler, (gl_FragCoord.xy * .96 + resolution * .02) / (resolution) ).rgb) ) ;

  // Show texts
  vec2 texttop = vec2(0., -.35), pt = (gl_FragCoord.xy / resolution) - texttop;
  if (pt.y > 0.)
    l = l + texture2D(texts, pt).rgb;

  gl_FragColor = vec4(l * (globalfade + (1.0-mod(bar*2.0 + 0.5, 1.0))), 1.0);

  // You should gamma correct the "l" above with something like Sqrt(l), but
  // only if you are not doing it in post-processing step.


} else {

  // ************* post-process pass ******************
  // Uncomment this to try a post-processing "effect"

  vec4 c = texture2D(texture_sampler, (gl_FragCoord.xy / resolution )),
       c1 = texture2D(texture_sampler, ((gl_FragCoord.xy + vec2(1.0, 0.0)) / resolution) ),
       c2 = texture2D(texture_sampler, ((gl_FragCoord.xy + vec2(0.0, 1.0)) / resolution) ),
       c3 = texture2D(texture_sampler, ((gl_FragCoord.xy + vec2(1.0, 1.0)) / resolution) ),
       c4 = texture2D(texture_sampler, ((gl_FragCoord.xy + vec2(-1.0, 1.0)) / resolution) ),
       c5 = texture2D(texture_sampler, ((gl_FragCoord.xy + vec2(-1.0, 0.0)) / resolution) ),
       c6 = texture2D(texture_sampler, ((gl_FragCoord.xy + vec2(-1.0, -1.0)) / resolution) ),
       c7 = texture2D(texture_sampler, ((gl_FragCoord.xy + vec2(0.0, -1.0)) / resolution) ),
       c8 = texture2D(texture_sampler, ((gl_FragCoord.xy + vec2(1.0, -1.0)) / resolution) )
       ;

// weird emboss effect
//  gl_FragColor = (c - c1 - c2 - c3 - c4 + c5 + c6 + c7 + c8) / 2.0;


// some sort of gamma correction with smoothing
    gl_FragColor = sqrt(c * 2.0 + c1 + c2 + c3 + c4 + c5 + c6 + c7 + c8) / 3.0;

}

}