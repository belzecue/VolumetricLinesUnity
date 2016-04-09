#ifndef VOL_LINE_STRIP_SHADER_INC
#define VOL_LINE_STRIP_SHADER_INC
	
	#include "UnityCG.cginc"
	
	// half4 _MainTex_ST;
	float _LineWidth;
	float _LineScale;
	float _CAMERA_FOV = 60.0f;
	
	struct a2v
	{
		float4 vertex : POSITION;
		float3 prevPos : NORMAL;
		float3 nextPos : TANGENT;
		half2 texcoord : TEXCOORD0;
		float2 texcoord1 : TEXCOORD1;
	};
	
	struct v2f
	{
		float4 pos : SV_POSITION;
		half2 uv : TEXCOORD0;
	};
	
	v2f vert (a2v v)
	{
		v2f o;
		// o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
		// since this shader isn't designed for tiled textures anyway, no need to transform texture:
		o.uv = v.texcoord;
		
		float4 clipPos = mul(UNITY_MATRIX_MVP, v.vertex);
		float4 clipPos_prev = mul(UNITY_MATRIX_MVP, float4(v.prevPos, 1.0));
		float4 clipPos_next = mul(UNITY_MATRIX_MVP, float4(v.nextPos, 1.0));
		
		float scaledLineWidth = _LineWidth * _LineScale
#if FOV_SCALING_ON
			* 60.0 / _CAMERA_FOV // 60 = 180 / scaling factor
#endif
		;
		
		// screen-space offset vectors from previous/next to current:
		float2 scrPos = clipPos.xy/clipPos.w;
		float2 lineDirProj_prev = scaledLineWidth * normalize(scrPos - clipPos_prev.xy/clipPos_prev.w);
		//		if (sign(clipPos_prev.w) != sign(clipPos.w))
		//			lineDirProj_prev = -lineDirProj_prev;
		
		float2 lineDirProj_next = scaledLineWidth * normalize(scrPos - clipPos_next.xy/clipPos_next.w);
		//		if (sign(clipPos_next.w) != sign(clipPos.w))
		//			lineDirProj_next = -lineDirProj_next;
		
		if (distance(v.prevPos, v.nextPos) < 1.0)
		{
			clipPos.x = clipPos.x + lineDirProj_prev.x * v.texcoord1.x;
			clipPos.y = clipPos.y + lineDirProj_prev.y * v.texcoord1.x;
			clipPos.x = clipPos.x + lineDirProj_prev.y * v.texcoord1.y;
			clipPos.y = clipPos.y - lineDirProj_prev.x * v.texcoord1.y;
		}
		else
		{
			clipPos.x = clipPos.x + ((lineDirProj_prev.x * v.texcoord1.x - lineDirProj_next.x * v.texcoord1.x) * .5);
			clipPos.y = clipPos.y + ((lineDirProj_prev.y * v.texcoord1.x - lineDirProj_next.y * v.texcoord1.x) * .5);
			clipPos.x = clipPos.x + ((lineDirProj_prev.y * v.texcoord1.y - lineDirProj_next.y * v.texcoord1.y) * .5);
			clipPos.y = clipPos.y - ((lineDirProj_prev.x * v.texcoord1.y - lineDirProj_next.x * v.texcoord1.y) * .5);
		}
		
		o.pos = clipPos;
		return o;
	}
	
	
	
	fixed _LightSaberFactor;
	fixed4 _Color;
	sampler2D _MainTex;
	
	fixed4 frag(v2f i) : SV_Target
	{
		fixed4 tx = tex2D(_MainTex, i.uv);
		
		return
			tx.a > _LightSaberFactor
			?
			fixed4(1.0, 1.0, 1.0, tx.a)
			:
			tx * _Color
		;
	}
	
#endif
