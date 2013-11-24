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

Texture2D texture2d <string uiname="Texture";>;

float AlphaThreshold = 0;

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

float MinY = -1;
float MaxY = 1;

float4 lowerColor <bool color=true; String uiname="Lower Min";> = { 1.0f,1.0f,1.0f,1.0f };
float4 rangeColor <bool color=true; String uiname="In Range";> = { 1.0f,1.0f,1.0f,1.0f };
float4 greaterColor <bool color=true; String uiname="Greater Max";> = { 1.0f,1.0f,1.0f,1.0f };

struct VS_IN
{
	float4 PosO : POSITION;
	float4 Col : COLOR;
};

struct vs2ps
{
    float4 PosWVP: SV_POSITION;
	float4 Col: COLOR;
	float4 TexCd: TEXCOORD0;
};

float2 cartogramDeform(float2 pos) {
	float halfWidth = GridWidth / 2;
	
	int iU = floor((halfWidth + pos.x) / SegmentSize);
	
	int iV = floor((halfWidth - pos.y) / SegmentSize);
	
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
	
	return uvPos;
}

vs2ps RANGE_COLOR_VS(VS_IN input)
{
    vs2ps Out = (vs2ps)0;
	float4 posW = mul(input.PosO, tW);
	
	//Dirty Hack
	posW *= 0.9999;
	
	float2 pos = posW.xz;
	
	float2 uvPos = cartogramDeform(pos);
	
	posW.xz = uvPos;
	
    Out.PosWVP = mul(posW, tVP);
	
	float4 color = input.Col;
	
	float y = posW.y;
	
	if(y > MinY && y < MaxY) {
		color *= rangeColor;
	} else if(y <= MinY) {
		color *= lowerColor;
	} else {
		color *= greaterColor;
	}
	
	Out.Col = color;
    return Out;
}

vs2ps VERTEX_COLOR_VS(VS_IN input)
{
    vs2ps Out = (vs2ps)0;
	float4 posW = mul(input.PosO, tW);
	
	//Dirty Hack
	posW *= 0.9999;
	
	float2 pos = posW.xz;
	
	float2 uvPos = cartogramDeform(pos);
	
	posW.xz = uvPos;
	
    Out.PosWVP = mul(posW, tVP);
	Out.Col = input.Col;
    return Out;
}

vs2ps CONSTANT_VS(float4 PosO:Position, float4 TexCd: TEXCOORD0)
{
	vs2ps Out = (vs2ps)0;
	float4 posW = mul(PosO, tW);
	
	//Dirty Hack
	posW *= 0.9999;
	
	float2 pos = posW.xz;
	
	float2 uvPos = cartogramDeform(pos);
	
	posW.xz = uvPos;
	
	Out.PosWVP = mul(posW, tVP);
	Out.TexCd = TexCd;
    return Out;
}

float4 VERTEX_COLOR_PS(vs2ps In): SV_Target
{
    float4 col = cAmb * In.Col;
	col.a *= Alpha;
	
	if(col.a < 0.2) discard;
    return col;
}

float4 CONSTANT_PS(vs2ps In): SV_Target
{
    float4 col = texture2d.Sample(g_samLinear,In.TexCd.xy) * cAmb;
	col.a *= Alpha;
    return col;
}

technique10 Range_Color
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, RANGE_COLOR_VS() ) );
		SetPixelShader( CompileShader( ps_4_0, VERTEX_COLOR_PS() ) );
	}
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