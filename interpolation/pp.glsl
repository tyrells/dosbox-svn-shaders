#version 120

// Developed by tyrells
// Based on Marat Tanalin's algorithm: https://tanalin.com/en/articles/integer-scaling/

uniform vec2 rubyInputSize;

#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#define COMPAT_TEXTURE texture
#else
#define COMPAT_VARYING varying
#define COMPAT_ATTRIBUTE attribute
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

const vec2 targetAspectRatio = vec2(4.0, 3.0);

uniform vec2 rubyOutputSize;

COMPAT_ATTRIBUTE vec4 a_position;
COMPAT_VARYING vec2 outCoord;

vec2 calculateScalingRatio(vec2 screenSize, vec2 imageSize, vec2 targetAspectRatio)
{
	float _TargetAspectRatio = targetAspectRatio.x / targetAspectRatio.y;
	float imageAspectRatio = imageSize.x / imageSize.y;

	vec2 maxIntRatio = floor(screenSize / imageSize);

	if (imageAspectRatio == _TargetAspectRatio)
	{
		float ratio = max(min(maxIntRatio.x, maxIntRatio.y), 1.0f);
		return vec2(ratio);
	}

	vec2 maxOutputSize = imageSize * maxIntRatio;
	float maxAspectRatio = maxOutputSize.x / maxOutputSize.y;
	vec2 scalingRatio = vec2(0.0, 0.0);
	// If the ratio MA is lower than the target aspect ratio TA
	if (maxAspectRatio < _TargetAspectRatio)
	{
		scalingRatio.x = maxIntRatio.x;
		float AUH = maxOutputSize.x / _TargetAspectRatio;

		float yUpperScaleFactor = ceil(AUH / imageSize.y);
		float yLowerScaleFactor = floor(AUH / imageSize.y);

		float upperAspectRatio = maxOutputSize.x / (yUpperScaleFactor * imageSize.y);
		float lowerAspectRatio = maxOutputSize.x / (yLowerScaleFactor * imageSize.y);

		float upperTargetError = abs(_TargetAspectRatio - upperAspectRatio);
		float lowerTargetError = abs(_TargetAspectRatio - lowerAspectRatio);

		if (abs(upperTargetError - lowerTargetError) < 0.001)
		{
			float upperImageError = abs(imageAspectRatio - upperAspectRatio);
			float lowerImageError = abs(imageAspectRatio - lowerAspectRatio);
			if (upperImageError < lowerImageError)
				scalingRatio.y = yUpperScaleFactor;
			else
				scalingRatio.y = yLowerScaleFactor;
		}
		// Added an extra check in here to prefer an aspect ratio above 1.0.
		// TODO: This will need to be looked at again for aspect ratios other than 4:3
		else if (lowerTargetError < upperTargetError || upperAspectRatio < 1.0)
			scalingRatio.y = yLowerScaleFactor;
		else
			scalingRatio.y = yUpperScaleFactor;
	}
	// If the ratio MA is greater than the target aspect ratio TA
	else if (maxAspectRatio > _TargetAspectRatio)
	{
		scalingRatio.y = maxIntRatio.y;
		float AUW = maxOutputSize.y * _TargetAspectRatio;

		float xUpperScaleFactor = ceil(AUW / imageSize.x);
		float xLowerScaleFactor = floor(AUW / imageSize.x);

		float upperAspectRatio = (xUpperScaleFactor * imageSize.x) / maxOutputSize.y;
		float lowerAspectRatio = (xLowerScaleFactor * imageSize.x) / maxOutputSize.y;

		float upperTargetError = abs(_TargetAspectRatio - upperAspectRatio);
		float lowerTargetError = abs(_TargetAspectRatio - lowerAspectRatio);

		if (abs(upperTargetError - lowerTargetError) < 0.001)
		{
			float upperImageError = abs(imageAspectRatio - upperAspectRatio);
			float lowerImageError = abs(imageAspectRatio - lowerAspectRatio);
			if (upperImageError < lowerImageError)
				scalingRatio.x = xUpperScaleFactor;
			else
				scalingRatio.x = xLowerScaleFactor;
		}
		// Added an extra check in here to prefer an aspect ratio above 1.0.
		// TODO: This will need to be looked at again for aspect ratios other than 4:3
		else if (upperTargetError < lowerTargetError || lowerAspectRatio < 1.0)
			scalingRatio.x = xUpperScaleFactor;
		else
			scalingRatio.x = xLowerScaleFactor;
	}
	// If the ratio MA is equal to the target aspect ratio TA
	else
		scalingRatio = maxIntRatio;

	if (scalingRatio.x < 1.0)
		scalingRatio.x = 1.0;
	if (scalingRatio.y < 1.0)
		scalingRatio.y = 1.0;

	return scalingRatio;
}

void main()
{
    gl_Position = a_position;

    //vec2 box_scale = vec2(5.0, 6.0);
    vec2 box_scale = calculateScalingRatio(rubyOutputSize, rubyInputSize, targetAspectRatio);
    vec2 scale = (rubyOutputSize / rubyInputSize) / box_scale;
    vec2 middle = vec2(0.5);
    vec2 TexCoord = vec2(a_position.x + 1.0, 1.0 - a_position.y) / 2.0;
    vec2 diff = (TexCoord - middle) * scale;

    outCoord = middle + diff;
}

#elif defined(FRAGMENT)

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#define COMPAT_PRECISION highp
#else
#define COMPAT_PRECISION
#endif

uniform sampler2D rubyTexture;
uniform vec2 rubyTextureSize;

COMPAT_VARYING vec2 outCoord;

void main()
{
    vec4 outColor = COMPAT_TEXTURE(rubyTexture, outCoord * rubyInputSize / rubyTextureSize);
    if ( outCoord.x >= 0.0 && outCoord.x <= 1.0 && outCoord.y >= 0.0 && outCoord.y <= 1.0)
        FragColor = outColor;
    else
       // Can change the background filler colour below
       FragColor = vec4(0.0, 0.0, 0.0, 1.0);
}

#endif
