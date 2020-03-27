/*

dugan_CRT-EasyMode_tweaked.glsl
    dugan's ScanLine shader
    adapted by liPillON for usage with DosBox SVN r4319 and later
    no tweaks

source shader files:
https://github.com/duganchen/dosbox_shaders/blob/master/scanline.frag
https://github.com/duganchen/dosbox_shaders/blob/master/scanline.vert

first posted here:
https://www.vogons.org/viewtopic.php?f=32&t=72697

*/
#version 330 core

varying vec2 v_texCoord;
uniform vec2 rubyTextureSize;
uniform vec2 rubyInputSize;
uniform vec2 rubyOutputSize;





#if defined(VERTEX)

attribute vec4 a_position;

out sine_coord
{
  vec2 omega;
} coords;

void main()
{
  gl_Position = a_position;
  v_texCoord = vec2(a_position.x+1.0,1.0-a_position.y)/2.0*rubyInputSize/rubyTextureSize;

  coords.omega = vec2(3.1415 * rubyOutputSize.x * rubyTextureSize.x / rubyInputSize.x, 2.0 * 3.1415 * rubyTextureSize.y);
}





#elif defined(FRAGMENT)

const float SCANLINE_BASE_BRIGHTNESS = 0.95;
const float SCANLINE_SINE_COMP_A = 0.05;
const float SCANLINE_SINE_COMP_B = 0.15;

uniform sampler2D rubyTexture;

in sine_coord
{
  vec2 omega;
} coords;

out vec4 color;

void main()
{
  vec2 sine_comp = vec2(SCANLINE_SINE_COMP_A, SCANLINE_SINE_COMP_B);
  vec3 res = texture(rubyTexture, v_texCoord).xyz;
  vec3 scanline = res * (SCANLINE_BASE_BRIGHTNESS + dot(sine_comp * sin(v_texCoord * coords.omega), vec2(1.0, 1.0)));
  color = vec4(scanline.x, scanline.y, scanline.z, 1.0);
}





#endif
