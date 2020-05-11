# A few GLSL shaders for DOSBox SVN

This repo contains a number of shaders ported/created or the new version of DOSBox SVN (r4319) by members of the DOSBox community. The file structure of this repo is based on the structure used in RetroArch, with many of the shaders being ported from [there](https://github.com/libretro/glsl-shaders/):

Unfortunately DOSBox does not currently support shader preset files, so parameters need to be set in the DOSBox config file manually. In order to get these shaders working, you will need to make the following changes to the `dosbox-SVN.conf` configuration file:

    [sdl]
    fullresolution = desktop
    output = opengl / openglnb

    [render]
    scaler = none
    glshader = [name of .glsl file]

DOSBox currently includes two OpenGL outputs (`opengl` and `openglnb`).`opengl` enables bilinear filtering of the input source, while `openglnb` disables bilinear filtering and uses nearest neighbour scaling instead. This parameter has the same effect as the the `filter_linear0` setting in RetroArch .glslp shader preset files. `opengl` is equivalent to the setting `filter_linear0 = true`, while `openglnb` is equivalent to `filter_linear0 = false`.

The table below provides a summary of which `output` setting to use for each shader included in this repo:
|shader name|output setting to use|
|-----------|---------------------|
|crt/crt-aperture.glsl|openglnb|
|crt/crt-caligari.glsl|openglnb|
|crt/crt-easymode.glsl|openglnb|
|crt/crt-easymode.tweaked.glsl|openglnb|
|crt/crt-geom.glsl|openglnb|
|crt/crt-geom.tweaked.glsl|openglnb|
|crt/crt-hyllian.glsl|openglnb|
|crt/crt-lottes-fast.glsl|opengl|
|crt/crt-lottes.glsl|openglnb|
|crt/crt-lottes.tweaked.glsl|openglnb|
|crt/crt-nes-mini.glsl|either|
|crt/crt-pi.glsl|opengl|
|crt/fakelottes.glsl|opengl|
|crt/fakelottes.tweaked.glsl|opengl|
|crt/ScanLine.glsl|openglnb|
|crt/yee64.glsl|either|
|crt/yeetron.glsl|openglnb|
|crt/zfast_crt.glsl|opengl|
|interpolation/pixellate.glsl|openglnb|
|interpolation/pp.glsl|openglnb|

Several of the included shaders have been modified to produce consistent results, regardless of the output which is used however by setting the correct output settings as shown above, the built-in filtering will be used, which could improve the performance of the shader.

The window size will not increase automatically, so you will need to manually set the window resolution or switch to full screen. If the full screen resolution option is not set to `desktop`, the image will be stretched and filtered.

Shaders can be copied to the DOSBox root directory, or alternatively to the `glshaders` subdirectory in the DOSBox configuration directory. The shader can be referenced by the filename, without the .glsl extension. If the shader fails to load, or does not compile correctly, an error/warning message can be seen in the DOSBox output window.

In addition to the shaders ported from RetroArch, the following new shaders are included in this repo:
- interpolation/pp.glsl - a pixel-perfect shader with aspect ratio correction, based on [Marat Tanalin's algorithm](https://tanalin.com/en/articles/integer-scaling/). A [Shadertoy implementation](https://www.shadertoy.com/view/3dsyW7) is also available.
- template.glsl - a shader that doesn't change anything and can be used as a template for other shaders.

I have tested the pixel-perfect shader code against [Marat Tanalin's reference implementation](https://tanalin.com/en/projects/integer-scaling/) and the original DOSBox [Pixel perfect patch](http://www.vogons.org/viewtopic.php?f=32&t=49160) originally included in [DOSBox ECE](https://dosboxece.yesterplay.net/en/). This implementation provides the identical level of scaling for the majority of the input/output resolutions I tested. Testing was conducted using DOSBox SVN r4334, which does not appear to be using the full resolution of the monitor in full screen mode, and therefore some results will be different to the pixel perfect scaling seen in DOSBox ECE. This is probably something that needs to be changed in the DOSBox OpenGL rendering code, but is not something I have looked at yet.

Thanks to [Delfino Furioso](https://www.vogons.org/viewtopic.php?f=32&t=72697) for porting/tweaking many of the CRT shaders.  He has the following recommendations:
- fakelottes for game resolutions up to 640x480
- easymode for game resolutions over 640x480
- geom as a 'jack of all trades' for all resolutions

The tweaked versions mainly reduce the curvature effect and brighten the image.
