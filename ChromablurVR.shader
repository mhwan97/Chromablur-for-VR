Shader "Hidden/Custom/ChromablurVR"
{
	HLSLINCLUDE
#define KERNEL_MEDIUM
#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/Builtins/DiskKernels.hlsl"
	
	//the main texture
	TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
	float4 _MainTex_TexelSize;

	TEXTURE2D_SAMPLER2D(_CameraDepthTexture, sampler_CameraDepthTexture);

	//Blur size
	float _BlurSize;

	//RGB Channel
	int _RGB;

	//Disc blur mode
	int _DiskFlag;

	//Gaussian vertical pass
	float4 vblurFrag(VaryingsDefault i) : SV_TARGET
	{
		float4 RGB = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
		float sumr = 0;
		float sumb = 0;
		int kern = 20;

		float stDevSquared = 0.05;
		float E = 2.71828182846;

		for (float idx = 0; idx < kern; idx++)
		{
			float offset = (idx / (kern-1) - 0.5)*_BlurSize;
			float2 uv = i.texcoord + float2(0, offset);
			float gaussr = (1 / sqrt(2 * PI*stDevSquared)) * pow(E, -((offset * offset) / (2 * stDevSquared)));
			float gaussb = (1 / sqrt(2 * PI*0.01)) * pow(E, -((offset * offset) / (2 * 0.01)));
			RGB.r += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).r*gaussr;
			RGB.b += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).b*gaussb;
			sumr += gaussr;
			sumb += gaussb;
		}
		RGB.r = RGB.r / sumr;
		RGB.b = RGB.b / sumb;
		return RGB;
	}

	//Gaussian horizontal pass
	float4 hblurFrag(VaryingsDefault i) : SV_TARGET
	{
		float invAspect = _ScreenParams.y / _ScreenParams.x;
		float4 RGB = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
		float sumr = 0;
		float sumb = 0;
		int kern = 20;

		float stDevSquared = 0.05;
		float E = 2.71828182846;

		for (float idx = 0; idx < kern; idx++)
		{
			float offset = (idx / (kern-1) - 0.5)*_BlurSize*invAspect;
			float2 uv = i.texcoord + float2(offset, 0);
			float gaussr = (1 / sqrt(2 * PI*stDevSquared)) * pow(E, -((offset * offset) / (2 * stDevSquared)));
			float gaussb = (1 / sqrt(2 * PI*0.01)) * pow(E, -((offset * offset) / (2 * 0.01)));
			RGB.r += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).r*gaussr;
			RGB.b += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).b*gaussb;
			sumr += gaussr;
			sumb += gaussb;
		}
		RGB.r = RGB.r / sumr;
		RGB.b = RGB.b / sumb;
		return RGB;
	}
		//Disk kernel blur
		float4 diskKernFrag(VaryingsDefault i) : SV_TARGET
		{
			float invAspect = _ScreenParams.y / _ScreenParams.x;
			float radius = 5;

			float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, i.texcoord).r;
			depth = Linear01Depth(depth);
			depth = depth * _ProjectionParams.z;

			if (_DiskFlag == 1) {
				//sradius = radius * _BlurSize;
			}
			else if (_DiskFlag == 2) {
				if (depth < _ProjectionParams.z * 0.004)
				{
					_RGB = 2;
				}
				else if(depth > _ProjectionParams.z * 0.02)
				{
					_RGB = 0;
				}
			}
			else if (_DiskFlag == 3) {
				radius = 10 / depth;
			}

			UNITY_LOOP
			float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
			for (int idx = 0; idx < kSampleCount; idx++)
			{
				float2 uv = kDiskKernel[idx] * _MainTex_TexelSize * _ScreenParams.y;// *radius;
				uv.x = uv.x * invAspect;
				if (_RGB == 0) //red in focus
				{
					float3 pixelRad = float3(0, 0.00101, 0.00229) * radius;// *(1 - depth);
					col.g += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + uv * pixelRad.g).g;
					col.b += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + uv * pixelRad.b).b;
				}
				else if (_RGB == 1) //green in focus
				{
					float3 pixelRad = float3(0.00101, 0, 0.00127) * radius;
					col.r += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + uv * pixelRad.r).r;
					col.b += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + uv * pixelRad.b).b;
				}
				else if (_RGB == 2) //blue in focus
				{
					//float3 pixelRad = float3(0.00229, 0.001127, 0) * radius;
					float3 pixelRad = float3(0.0015, 0.0005, 0) * radius;
					col.r += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + uv * pixelRad.r).r;
					col.g += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + uv * pixelRad.g).g;
				}
				
			}
			if (_RGB == 0) //red in focus
			{
				col.g = col.g / kSampleCount;
				col.b = col.b / kSampleCount;
			}
			else if (_RGB == 1) //green in focus
			{
				col.r = col.r / kSampleCount;
				col.b = col.b / kSampleCount;
			}
			else if (_RGB == 2) //blue in focus
			{
				col.g = col.g / kSampleCount;
				col.r = col.r / kSampleCount;
			}
			
			return col;
		}

	ENDHLSL


		SubShader {
		// markers that specify that we don't need culling 
		// or comparing/writing to the depth buffer
		Cull Off
			ZWrite Off
			ZTest Always

			Pass
		{
			HLSLPROGRAM
#pragma vertex VertDefault
#pragma fragment vblurFrag

			ENDHLSL
		}
			Pass
		{
			HLSLPROGRAM
#pragma vertex VertDefault
#pragma fragment hblurFrag

			ENDHLSL
		}
			Pass
		{
			HLSLPROGRAM
#pragma vertex VertDefault
#pragma fragment diskKernFrag
			ENDHLSL
		}
	}
}