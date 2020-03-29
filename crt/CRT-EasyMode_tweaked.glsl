/*

dugan_CRT-EasyMode_tweaked.glsl
    dugan's CRT-EasyMode port
    adapted by liPillON for usage with DosBox SVN r4319 and later
    slightly tweaked the parameters in order to: 
    - reduce the blurring, 
    - bump up the brightness a bit, 
    - strengthen the crt mask

source shader files:
https://github.com/duganchen/dosbox_shaders/blob/master/crt-easymode.frag
https://github.com/duganchen/dosbox_shaders/blob/master/crt-easymode.vert

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

void main()
{
  gl_Position = a_position;
  v_texCoord = vec2(a_position.x+1.0,1.0-a_position.y)/2.0*rubyInputSize/rubyTextureSize;
}





#elif defined(FRAGMENT)

uniform sampler2D rubyTexture;

#define BRIGHT_BOOST 1.25               //tweaked
#define DILATION 1.0
#define GAMMA_INPUT 2.0
#define GAMMA_OUTPUT 1.8
#define MASK_SIZE 1.0
#define MASK_STAGGER 0.0
#define MASK_STRENGTH 0.45              //tweaked
#define MASK_DOT_HEIGHT 1.0
#define MASK_DOT_WIDTH 1.0
#define SCANLINE_BEAM_WIDTH_MAX 1.5
#define SCANLINE_BEAM_WIDTH_MIN 1.5
#define SCANLINE_BRIGHT_MAX 0.65
#define SCANLINE_BRIGHT_MIN 0.35
#define SCANLINE_CUTOFF 400.0
#define SCANLINE_STRENGTH 1.0
#define SHARPNESS_H 0.55                //tweaked
#define SHARPNESS_V 0.55                //tweaked

#define FIX(c) max(abs(c), 1e-5)
#define PI 3.141592653589
#define TEX2D(c) dilate(texture(tex, c))

// Set to 0 to use linear filter and gain speed
#define ENABLE_LANCZOS 1

vec4 dilate(vec4 col)
{
    vec4 x = mix(vec4(1.0), col, DILATION);

    return col * x;
}

float curve_distance(float x, float sharp)
{

/*
    apply half-circle s-curve to distance for sharper (more pixelated) interpolation
    single line formula for Graph Toy:
    0.5 - sqrt(0.25 - (x - step(0.5, x)) * (x - step(0.5, x))) * sign(0.5 - x)
*/

    float x_step = step(0.5, x);
    float curve = 0.5 - sqrt(0.25 - (x - x_step) * (x - x_step)) * sign(0.5 - x);

    return mix(x, curve, sharp);
}

mat4 get_color_matrix(sampler2D tex, vec2 co, vec2 dx)
{
    return mat4(TEX2D(co - dx), TEX2D(co), TEX2D(co + dx), TEX2D(co + 2.0 * dx));
}

vec3 filter_lanczos(vec4 coeffs, mat4 color_matrix)
{
    vec4 col = color_matrix * coeffs;
    vec4 sample_min = min(color_matrix[1], color_matrix[2]);
    vec4 sample_max = max(color_matrix[1], color_matrix[2]);

    col = clamp(col, sample_min, sample_max);

    return col.rgb;
}

out vec4 color;

void main()
{
    vec2 dx = vec2(1.0 / rubyTextureSize.x, 0.0);
    vec2 dy = vec2(0.0, 1.0 / rubyTextureSize.y);
    vec2 pix_co = v_texCoord * rubyTextureSize - vec2(0.5, 0.5);
    vec2 tex_co = (floor(pix_co) + vec2(0.5, 0.5)) / rubyTextureSize;
    vec2 dist = fract(pix_co);
    float curve_x;
    vec3 col, col2;

#if ENABLE_LANCZOS
    curve_x = curve_distance(dist.x, SHARPNESS_H * SHARPNESS_H);

    vec4 coeffs = PI * vec4(1.0 + curve_x, curve_x, 1.0 - curve_x, 2.0 - curve_x);

    coeffs = FIX(coeffs);
    coeffs = 2.0 * sin(coeffs) * sin(coeffs / 2.0) / (coeffs * coeffs);
    coeffs /= dot(coeffs, vec4(1.0));

    col = filter_lanczos(coeffs, get_color_matrix(rubyTexture, tex_co, dx));
    col2 = filter_lanczos(coeffs, get_color_matrix(rubyTexture, tex_co + dy, dx));
#else
    curve_x = curve_distance(dist.x, SHARPNESS_H);

    col = mix(TEX2D(tex_co).rgb, TEX2D(tex_co + dx).rgb, curve_x);
    col2 = mix(TEX2D(tex_co + dy).rgb, TEX2D(tex_co + dx + dy).rgb, curve_x);
#endif

    col = mix(col, col2, curve_distance(dist.y, SHARPNESS_V));
    col = pow(col, vec3(GAMMA_INPUT / (DILATION + 1.0)));

    float luma = dot(vec3(0.2126, 0.7152, 0.0722), col);
    float bright = (max(col.r, max(col.g, col.b)) + luma) / 2.0;
    float scan_bright = clamp(bright, SCANLINE_BRIGHT_MIN, SCANLINE_BRIGHT_MAX);
    float scan_beam = clamp(bright * SCANLINE_BEAM_WIDTH_MAX, SCANLINE_BEAM_WIDTH_MIN, SCANLINE_BEAM_WIDTH_MAX);
    float scan_weight = 1.0 - pow(cos(v_texCoord.y * 2.0 * PI * rubyTextureSize.y) * 0.5 + 0.5, scan_beam) * SCANLINE_STRENGTH;

    float mask = 1.0 - MASK_STRENGTH;    
    vec2 mod_fac = floor(v_texCoord * rubyOutputSize * rubyTextureSize / (rubyInputSize * vec2(MASK_SIZE, MASK_DOT_HEIGHT * MASK_SIZE)));
    int dot_no = int(mod((mod_fac.x + mod(mod_fac.y, 2.0) * MASK_STAGGER) / MASK_DOT_WIDTH, 3.0));
    vec3 mask_weight;

    if (dot_no == 0) mask_weight = vec3(1.0, mask, mask);
    else if (dot_no == 1) mask_weight = vec3(mask, 1.0, mask);
    else mask_weight = vec3(mask, mask, 1.0);

    if (rubyInputSize.y >= SCANLINE_CUTOFF) scan_weight = 1.0;

    col2 = col.rgb;
    col *= vec3(scan_weight);
    col = mix(col, col2, scan_bright);
    col *= mask_weight;
    col = pow(col, vec3(1.0 / GAMMA_OUTPUT));

    color = vec4(col * BRIGHT_BOOST, 1.0);
}





#endif
