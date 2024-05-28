
// @note(momo): Simple version of MultiLUT where there is less hard coding
// Basically I think the MultiLUT that's being passed around is a complete mess
// so I created this simpler version instead.

#define fLUT_TextureName "momo_multilut_yomi.png"
#define fLUT_Selections "Neutral\0Nature's Call\0Cherry Blossom\0Bleach\0Golden Hour\0Vibrant Sands\0Azure\0Macaron\0Vintage Film\0Bubble Gum\0Fountain\0Clear Skies\0Action\0Pastel Purity\0Lens Clarity\0Heart\0Teal and Orange\0Haunt\0"


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform int fLUT_LutSelector < 
    ui_category = "Pass 1";
    ui_type = "combo";
    ui_items = fLUT_Selections;
    ui_label = "LUT to use.";
    ui_tooltip = "LUT to use for color transformation.";
> = 0;

uniform float fLUT_Intensity <
    ui_category = "Pass 1";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Intensity";
    ui_tooltip = "Overall intensity of the LUT effect.";
> = 1.00;

uniform float fLUT_AmountChroma <
    ui_category = "Pass 1";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Chroma Amount";
    ui_tooltip = "Intensity of color/chroma change of the LUT.";
> = 1.00;

uniform float fLUT_AmountLuma <
    ui_category = "Pass 1";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Luma Amount";
    ui_tooltip = "Intensity of luma change of the LUT.";
> = 1.00;


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif


#define _SOURCE_MULTILUT_FILE fLUT_TextureName
#define _SOURCE_MULTILUT_TILE_SIZE 32
#define _SOURCE_MULTILUT_TILE_AMOUNT 32
#define _SOURCE_MULTILUT_AMOUNT 18



texture textMultiLutYomi < source = _SOURCE_MULTILUT_FILE; > { Width = _SOURCE_MULTILUT_TILE_SIZE * _SOURCE_MULTILUT_TILE_AMOUNT; Height = _SOURCE_MULTILUT_TILE_SIZE * _SOURCE_MULTILUT_AMOUNT; Format = RGBA8; };
sampler SamplerMultiLUT { Texture = textMultiLutYomi; };


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float3 apply(in const float3 color, in const float lut)
{
    const float2 texelsize = 1.0 / float2(_SOURCE_MULTILUT_TILE_SIZE * _SOURCE_MULTILUT_TILE_AMOUNT, _SOURCE_MULTILUT_TILE_SIZE);
    float3 lutcoord = float3((color.xy * _SOURCE_MULTILUT_TILE_SIZE - color.xy + 0.5) * texelsize, (color.z  * _SOURCE_MULTILUT_TILE_SIZE - color.z));

    const float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z - lerpfact) * texelsize.y;
    lutcoord.y = lut / _SOURCE_MULTILUT_AMOUNT + lutcoord.y / _SOURCE_MULTILUT_AMOUNT;

    return lerp(tex2D(SamplerMultiLUT, lutcoord.xy).xyz, tex2D(SamplerMultiLUT, float2(lutcoord.x + texelsize.y, lutcoord.y)).xyz, lerpfact);
}

void PS_MultiLUT_Apply(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float3 res : SV_Target)
{
    const float3 color = tex2D(ReShade::BackBuffer, texcoord).xyz;
    const float3 lutcolor = lerp(color, apply(color, fLUT_LutSelector), fLUT_Intensity);
    res = lerp(normalize(color), normalize(lutcolor), fLUT_AmountChroma)
        * lerp(   length(color),    length(lutcolor),   fLUT_AmountLuma);


#if GSHADE_DITHER
	res += TriDither(res, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

technique momo_multilut_yomi
{
    pass MultiLUT_Apply
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MultiLUT_Apply;
    }
}
