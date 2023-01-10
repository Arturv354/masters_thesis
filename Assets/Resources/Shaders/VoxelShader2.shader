Shader "Custom/VoxelShader2"
{
	SubShader
	{
		Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

		Pass
		{
			Name "ForwardLit"
			Tags { "LightMode" = "UniversalForward"}
			Cull Back

			HLSLPROGRAM

			// Signal this shader requires geometry programs
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			// Lighting and shadow keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT

			// Register our functions
			#pragma vertex vert
			#pragma fragment frag

			#include "ShaderStructures.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
			#include "NMGGeometryHelpers.hlsl"

			uniform StructuredBuffer<Triangle> triangleBuffer;

			struct V2F {

				float4 vertex : SV_POSITION;
				float3 normal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};

			V2F vert(uint id : SV_VertexID)
			{
				V2F output;

				Triangle triangleStruct = triangleBuffer[id / 3];
				float3 localPos;
				float3 normal;
				if (id % 3 == 0) 
				{
					localPos = triangleStruct.v1;
					normal = triangleStruct.n1;
				}
				else if (id % 3 == 1) 
				{
					localPos = triangleStruct.v2;
					normal = triangleStruct.n2;
				}
				else 
				{
					localPos = triangleStruct.v3;
					normal = triangleStruct.n3;
				}

				output.vertex = TransformObjectToHClip(localPos);
				output.normal = normal;
				output.worldPos = localPos + unity_ObjectToWorld._m30_m31_m32;

				return output;
			}

			float4 frag(V2F input) : COLOR
			{
				// Initialize some information for the lighting function
				InputData lightingInput = (InputData)0;
				lightingInput.positionWS = input.worldPos;
				lightingInput.normalWS = normalize(input.normal); // No need to renormalize, since triangles all share normals
				lightingInput.viewDirectionWS = GetViewDirectionFromPosition(input.worldPos);
				lightingInput.shadowCoord = CalculateShadowCoord(input.worldPos, input.vertex);

				// Read the main texture
				float3 albedo = float3(1, 1, 1);

				// Call URP's simple lighting function
				// The arguments are lightingInput, albedo color, specular color, smoothness, emission color, and alpha
				return UniversalFragmentBlinnPhong(lightingInput, albedo, 1, 0, 0, 1, input.normal);
			}
			
			ENDHLSL
		}
	}
}
