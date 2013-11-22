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

float4x4 tVP : VIEWPROJECTION;
float4x4 tW : WORLD;

float Alpha <float uimin=0.0; float uimax=1.0;> = 1;
float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
float4x4 tColor <string uiname="Color Transform";>;

float GridWidth = 1.;
float SegmentSize = 1.;
int Resolution = 2;

StructuredBuffer<float4> Indices;
StructuredBuffer<float2> BaseVertexes;
StructuredBuffer<float2> TransformedVertexes;

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
	
	float4 posW = mul(PosO, tW);
	
	//Dirty Hack
	posW *= 0.9999;
	
	float2 pos = posW.xz;
	
	float halfWidth = GridWidth / 2;
	
	int iU = floor((halfWidth + posW.x) / SegmentSize);
	
	int iV = floor((halfWidth - posW.z) / SegmentSize);
	
	int cellIndex = iU + iV * (Resolution - 1);
	
	int4 ind = Indices[cellIndex];
	
	float2 bP0 = BaseVertexes[ind[0]];
	float2 bP1 = BaseVertexes[ind[1]];
	float2 bP2 = BaseVertexes[ind[2]];
	float2 bP3 = BaseVertexes[ind[3]];
	
	float2 tP0 = TransformedVertexes[ind[0]];
	float2 tP1 = TransformedVertexes[ind[1]];
	float2 tP2 = TransformedVertexes[ind[2]];
	float2 tP3 = TransformedVertexes[ind[3]];
	
	float u = (pos.x - bP0.x) / (bP1.x - bP0.x);
	float v = (bP0.y - pos.y) / (bP0.y - bP2.y);
	
	float2 uP0 = (1.0 - u) * tP2 + u * tP3;
	float2 uP1 = (1.0 - u) * tP0 + u * tP1;
	
	float2 uvPos = (1.0 - v) * uP1 + v * uP0;
	
	float2 uvPos2 = 0;
	uvPos2.x = (bP0.x + bP1.x + bP2.x + bP3.x) / 4;
	uvPos2.y = (bP0.y + bP1.y + bP2.y + bP3.y) / 4;
	
	posW.xz = uvPos;
	
	Out.PosWVP = mul(posW, tVP);
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