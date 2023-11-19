
#include "ReShade.fxh"

uniform float multiply_red <
	ui_type = "input";
	ui_label = "Multiply Red";
	ui_tooltip = "Value to multiply all red on the screen by (0-255)";
	ui_step = 0.01;
	> = float(1.0);

uniform float multiply_green <
	ui_type = "input";
	ui_label = "Multiply Green";
	ui_tooltip = "Value to multiply all green on the screen by (0-255)";
	ui_step = 0.01;
	> = float(1.0);
	
uniform float multiply_blue <
	ui_type = "input";
	ui_label = "Multiply Blue";
	ui_tooltip = "Value to multiply all blue on the screen by (0-255)";
	ui_step = 0.01;
	> = float(1.0);
	

float3 momo_rgb_multiply(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 ret = tex2D(ReShade::BackBuffer, texcoord).rgb;
	ret[0] *= multiply_red;
	ret[1] *= multiply_green;
	ret[2] *= multiply_blue;
	
	return ret;
}

technique momo_rgb_multiply
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = momo_rgb_multiply;
	}
}
