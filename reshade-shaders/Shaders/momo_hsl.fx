//
// TODO: I should write a blog spot about this...
// because information on how HSL colors are derived
// is scarily scarce.
//
#include "ReShade.fxh"

uniform float input_hue_offset <
  ui_type = "slider";
  ui_label = "Hue Offset";
  ui_tooltip = "Offsets the hue of the scene from 0.0 - 360.0 degrees\nNote that hue is simply 'color', represented by the counter-clockwise rotational degree on the color wheel.\n0.0 represents 0 degrees.\n1.0 represents 360 degrees.\n\nConsult the color wheel for what the degrees mean.\nExample 1: starting from red, 120 degrees offset will bring you to green, 240 degrees offset will bring you to blue, 360 degrees will bring you back to red.\nExample 2: If you start from green, 120 degrees offset will bring you to blue, 240 degrees offset will bring you ";
  ui_step = 0.01;
  ui_min = 0;
  ui_max = 360;
> = float(0.0);

uniform float input_saturation_multiplier <
  ui_type = "slider";
  ui_label = "Saturation Multiplier";
  ui_tooltip = "Multiplies the saturation value of the scene.\nSaturation is the 'strength' of the color.\n1.0 is the normal saturation, means nothing changes.\n0.0 means the 'strength' of the color is 0, which basically makes everything greyscale.\n2.0 doubles the 'strength' of the color.";
  ui_step = 0.01;
  ui_min = 0.0;
  ui_max = 5.0;
> = float(1.0);

uniform float input_lightness_multipler <
  ui_type = "slider";
  ui_label = "Add Lightness";
  ui_tooltip = "Adds 'Lightness' to the scene. Lightness is generally speaking the amount of black and white in the color. Negative values add more 'black' and positive values add more 'white' to the scene.";
  ui_step = 0.01;
  ui_min = -1.0;
  ui_max = 1.0;
> = float(0.0);



float max_of_3(float a, float b, float c) {
  return max(max(a,b),c);
}

float min_of_3(float a, float b, float c) {
  return min(min(a,b),c);
}


// Remember that hue represents degree in color wheel
// Since our rgb_to_hsl function returns hue as a range of [0.0 - 1.0]
//
// 0/3 is red          (0 degrees)
// 1/3 is green        (120 degrees)
// 2/3 is blue         (240 degrees)
// 3/3 is back to red  (360 degrees)
// 
float3 rgb_to_hsl(float3 rgb) {
  float r = rgb.r;
  float g = rgb.g;
  float b = rgb.b;


  float max_channel = max_of_3(r,g,b);
  float min_channel = min_of_3(r,g,b);
  float delta = max_channel - min_channel; // aka chroma

  float l = (max_channel + min_channel)/2;

  if (delta == 0) {
    // Means no 'chroma'.
    // This means that it's grey
    return float3(0,0,l);
  }

  float h = 0;
  // Calculate hue

  if (max_channel == r) {
    h = 60.0 * ((g - b) / delta + (g < b ? 6 : 0));
  }
  else if (max_channel == g) {
    h = 60.0 * (((b - r)/delta)+ 2);
  }
  else if (max_channel == b) {
    h = 60.0 * (((r - g)/delta)+ 4);
  }
  h /= 360;

  // Calculate saturation
  float s = delta/(1.f - abs(2*l-1));

  return float3(h,s,l);
}

float hue_to_color(float p, float q, float t) 
{
  if (t < 0) 
    t += 1.0;
  if (t > 1.0) 
    t -= 1.0;
  if (t < 1.0/6.0) 
    return p + (q - p) * 6.0 * t;
  if (t < 1.0/2.0) 
    return q;
  if (t < 2.0/3.0)   
    return p + (q - p) * (2.0/3.0 - t) * 6.0;

  return p;

}

float3 hsl_to_rgb(float3 hsl) {
  float h = hsl[0];
  float s = hsl[1];
  float l = hsl[2];

  if (s == 0) {
    // grey case
    return float3(l,l,l);
  }

  float q = (l < 0.5f) ? (l * (1.0 + s)) : (l + s - (l * s));
  float p = 2.0 * l - q;

  float r = hue_to_color(p, q, h + 1.0/3.0);
  float g = hue_to_color(p, q, h);
  float b = hue_to_color(p, q, h - 1.0/3.0);

  return float3(r,g,b);

}


// NOTE(momo): This is not a generic wrap algorithm.
// It's only to wrap overflowing beyond 1.0 ONCE.
float wrap(float v) {
  return (v > 1.0) ? (v - 1.0) : (v);
}

float3 debug_flatten(float3 v, int index) {
  float c = v[index];
  return float3(c,c,c);
}


float3 momo_hsl(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
  float3 rgb = tex2D(ReShade::BackBuffer, texcoord).rgb;

  //float3 rgb = float3(debug_red, debug_green, debug_blue);

  float3 hsl = rgb_to_hsl(rgb);

  hsl[0] = wrap(hsl[0] +  input_hue_offset/360.0);
  hsl[1] = max(min(hsl[1] * input_saturation_multiplier, 1.0), 0.0);
  
  // NOTE: Okay this was a bit tricky to figure out but I THINK
  // what image editors do is that they ADD a PERCENTAGE of 'white'
  // ...NOT adding a flat percentage.
  //
  // It's NOT:
  //   lightness += input
  // It's actually:
  //   lightness += 1.0 * input 
  // where input is a valid from -1 to 1.
  //      
  hsl[2] = max(min(hsl[2] + (1.0 * input_lightness_multipler), 1.0), 0.0);

  float3 ret = hsl_to_rgb(hsl);


  return ret;
}

technique momo_hsl
{
  pass
  {
    VertexShader = PostProcessVS;
    PixelShader = momo_hsl;
  }
}
