//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 

SamplerState g_samLinear : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

 
cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;
};


cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	float Alpha <float uimin=0.0; float uimax=1.0;> = 1; 
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
	float4x4 tColor <string uiname="Color Transform";>;
};

struct VS_IN
{
	float4 PosO : POSITION;
	float4 Col : COLOR;
};

struct vs2ps
{
    float4 PosWVP: SV_POSITION;
	float4 Col: COLOR;
};

vs2ps VERTEX_COLOR_VS(VS_IN input)
{
    vs2ps Out = (vs2ps)0;
    Out.PosWVP  = mul(input.PosO,mul(tW,tVP));
	Out.Col = input.Col;
    return Out;
}

vs2ps CONSTANT_VS(float4 PosO:Position)
{
	vs2ps Out = (vs2ps)0;
	
	Out.PosWVP = mul(PosO,mul(tW,tVP));
    return Out;
}

float4 VERTEX_COLOR_PS(vs2ps In): SV_Target
{
    float4 col = cAmb * In.Col;
	col.a *= Alpha;
    return col;
}

float4 CONSTANT_PS(vs2ps In): SV_Target
{
    float4 col = cAmb;
	col.a *= Alpha;
    return col;
}

technique10 Vertex_Color
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VERTEX_COLOR_VS() ) );
		SetPixelShader( CompileShader( ps_4_0, VERTEX_COLOR_PS() ) );
	}
}

technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, CONSTANT_VS() ) );
		SetPixelShader( CompileShader( ps_4_0, CONSTANT_PS() ) );
	}
}