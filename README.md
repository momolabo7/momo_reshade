# momo_reshade
My own custom reshade shaders and presets.
I'm using Reshade as a way to learn shader programming languages.

I do this because my brain is smol so rather than trying to understand everyone's shaders, I think it's easier to write my own that caters to my smol brain :)

## momo_rgb_multiply

This shader simply multiplies a pixel's RGB color components seperately. 
For example, if you set to multiply red to 1, all red remains the same. 
Multiplying red by 0 will remove all red. 
Multiplying red by 2 will double all red values.
Since max value of a component is 255, you can multiply red by 255 to make EVERYTHING red EXCEPT for things with 0 red (because 0 * 255 is 0!)

Is simple math!

Simple use case would be to multiply everything by 0.5 to make  everything darker and 1.5 to make everything brighter.

# momo_hsl

This shader allows you to adjust the hue/saturation/lightness, similar from photo editting tools like Photoshop.


# momo_texture_overlay

This shader allows you place a texture over the screen! You can resize and move the texture. 
NOTE: I'm currently working on getting rotation to work.
