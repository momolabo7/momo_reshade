// TODO
//   [] Blending

#include "ReShade.fxh"

#define overlay_scale_x  float(input_width / BUFFER_WIDTH) 
#define overlay_scale_y  float(input_height / BUFFER_HEIGHT) 
#define overlay_pos_x    float(input_x/BUFFER_WIDTH)
#define overlay_pos_y    float(input_y/BUFFER_HEIGHT)

uniform float input_x <
  ui_type = "slider";
  ui_label = "X";
  ui_tooltip = "X position of the overlay";
  ui_step = 0.01;
  ui_min = -BUFFER_HEIGHT/2;
  ui_max = BUFFER_WIDTH + BUFFER_WIDTH/2;
> = float(BUFFER_WIDTH/2);

uniform float input_y <
  ui_type = "slider";
  ui_label = "Y";
  ui_tooltip = "Y position of the overlay";
  ui_step = 0.01;
  ui_min = -BUFFER_HEIGHT/2;
  ui_max = BUFFER_HEIGHT + BUFFER_HEIGHT/2;
> = float(BUFFER_HEIGHT/2);

uniform float input_width <
  ui_type = "slider";
  ui_label = "Width";
  ui_tooltip = "Width of the overlay";
  ui_step = 0.01;
  ui_min = 0;
  ui_max = BUFFER_WIDTH;
> = float(BUFFER_WIDTH/2);

uniform float input_height <
  ui_type = "slider";
  ui_label = "Height";
  ui_tooltip = "Height of the overlay";
  ui_step = 0.01;
  ui_min = 0;
  ui_max = BUFFER_HEIGHT;
> = float(BUFFER_HEIGHT/2);

uniform float input_rotation <
  ui_type = "slider";
  ui_label = "Rotation";
  ui_tooltip = "";
  ui_step = 0.01;
  ui_min = 0;
  ui_max = 360;
> = float(90.0);

texture2D overlay_texture < source = "momo_texture_overlay.png"; > 
{ 
  Width = BUFFER_WIDTH; 
  Height = BUFFER_HEIGHT; 
  Format = RGBA8; 
};

sampler2D overlay_sampler { 
  Texture = overlay_texture; 
};

//
// NOTE(momo): 
// 
// The reason why the matices are the inverse of their
// supposed normal versions is because they are going to 
// be multiplied by the screen buffer's UV texture coordinates
// in order to get the final UV to be sampled by the texture.
//
// As an example, to scale the overlay to half the buffer's width,
// we would take the buffer's UV.x value and multiplying it by 2.
// It's easier to see the numbers on how this works imo:
//   - 0.1 on buffer width is mapped to 0.2 on the overlay width
//   - 0.2 on the buffer width is mapped to 0.4 on the overlay width
//   - 0.5 on the buffer width is mapped to 1 on the overlay width
//   -- This means that end of the overlay texture width  is mapped to the midwidth of the buffer
//
// To be honest, the function names and code doesn't really make sense once you understand
// this concept. But my brain is terribly small and I want to think about it in a way
// where whenever I think about 'I want it to be 0.5 of the buffer size', I will just 
// multiply the buffer's current UV by 0.5.
//

float3x3 make_translation (float x, float y) {
  return float3x3 (
    1, 0, 0,
    0, 1, 0,
    -x, -y, 1
  );
}
float3x3 make_scale (in float x, in float y) {
  return float3x3 (
      1/x, 0,   0,
      0,   1/y, 0,
      0,   0,   1
  );
}

float3x3 make_translation2 (float x, float y) {
  return float3x3 (
    1, 0, -x,
    0, 1, -y,
    0, 0, 1
  );
}

float3x3 make_rotation(in float rad) {

  float rot = rad * (3.1415926 / 180.0);

  return float3x3 (
    cos(rot), (sin(rot)*BUFFER_WIDTH)/BUFFER_HEIGHT, 0,
    (-sin(rot)*BUFFER_HEIGHT)/BUFFER_WIDTH, cos(rot),0,
    0,0,1
  );

}


float3 momo_texture_overlay(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{ 
  float3x3 o = make_translation(-0.5, -0.5);
  float3x3 r = make_rotation(input_rotation);
  float3x3 s = make_scale(overlay_scale_x, overlay_scale_y);
  float3x3 t = make_translation(overlay_pos_x, overlay_pos_y);

  float3 uv = float3(texcoord.x, texcoord.y, 1);
  float3 overlay_texcoord = mul(mul(mul(mul(uv, t), r), s), o);



  float4 overlay = tex2D(overlay_sampler, overlay_texcoord.xy);
  float3 buffer = tex2D(ReShade::BackBuffer, texcoord).rgb;

  // NOTE: lerp(start, end, percentage);

  if (overlay_texcoord.x <= 1.0 && overlay_texcoord.y <= 1.0 && 
      overlay_texcoord.x >= 0.0 && overlay_texcoord.y >= 0.0)
  {
    return lerp(buffer, overlay.rgb, overlay.a);
  }

  // Otherwise just return the buffer color
  return buffer;
}



technique momo_texture_overlay
{
  pass
  {
    VertexShader = PostProcessVS;
    PixelShader = momo_texture_overlay;
  }
}
