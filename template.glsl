#version 330

#if defined(VERTEX)

uniform vec2 rubyTextureSize;
uniform vec2 rubyInputSize;
uniform vec2 rubyOutputSize;

in vec4 a_position;
out vec2 v_texCoord;

void main()
{
    gl_Position = a_position;
    v_texCoord = vec2(a_position.x + 1.0, 1.0 - a_position.y) / 2.0 * rubyInputSize / rubyTextureSize;
}

#elif defined(FRAGMENT)

uniform sampler2D rubyTexture;

in vec2 v_texCoord;

void main()
{
    gl_FragColor = texture(rubyTexture, v_texCoord);
}

#endif