Shader "Custom/TriplanarVoxel"
{
    Properties
    {
        [NoScaleOffset]_Top("Top", 2D) = "white" {}
        [NoScaleOffset]_Side1("Side1", 2D) = "white" {}
        [NoScaleOffset]_Side2("Side2", 2D) = "white" {}
        _Blend("Blend", Float) = 3
        _TopBlend("TopBlend", Float) = 3
        _TopTiling("TopTiling", Vector) = (1, 1, 0, 0)
        _SideTiling("SideTiling", Vector) = (0.44, 1, 0, 0)
        _Smoothness("Smoothness", Float) = 0.1
        [NoScaleOffset]_TopNormal("TopNormal", 2D) = "white" {}
        [NoScaleOffset]_Side1Normal("Side1Normal", 2D) = "white" {}
        [NoScaleOffset]_Side2Normal("Side2Normal", 2D) = "white" {}
        _TopBlendStrength("TopBlendStrength", Float) = 0
        _TopBlendColor("TopBlendColor", Color) = (0, 0, 0, 0)
        _TopNormalStrength("TopNormalStrength", Float) = 1
        _SideNormalStrength("SideNormalStrength", Float) = 6
        [HideInInspector]_QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector]_QueueControl("_QueueControl", Float) = -1
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "UniversalMaterialType" = "Lit"
            "Queue"="Geometry"
            "ShaderGraphShader"="true"
            "ShaderGraphTargetId"="UniversalLitSubTarget"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
        
        // Render State
        Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DYNAMICLIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
        #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
        #pragma multi_compile_fragment _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        #pragma multi_compile_fragment _ _LIGHT_LAYERS
        #pragma multi_compile_fragment _ DEBUG_DISPLAY
        #pragma multi_compile_fragment _ _LIGHT_COOKIES
        #pragma multi_compile _ _CLUSTERED_RENDERING
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define VARYINGS_NEED_SHADOW_COORD
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_FORWARD
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "ShaderStructures.hlsl"
        uniform StructuredBuffer<Triangle> triangleBuffer;
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

        struct Attributes
        {
             uint id : SV_VertexID;
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
             float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
             float2 staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
             float2 dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
             float3 sh;
            #endif
             float4 fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
             float4 shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 TangentSpaceNormal;
             float3 WorldSpaceTangent;
             float3 WorldSpaceBiTangent;
             float3 WorldSpacePosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float3 interp3 : INTERP3;
             float2 interp4 : INTERP4;
             float2 interp5 : INTERP5;
             float3 interp6 : INTERP6;
             float4 interp7 : INTERP7;
             float4 interp8 : INTERP8;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.interp5.xy =  input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp6.xyz =  input.sh;
            #endif
            output.interp7.xyzw =  input.fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.interp8.xyzw =  input.shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.interp4.xy;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.interp5.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp6.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp7.xyzw;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.interp8.xyzw;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Top_TexelSize;
        float4 _Side1_TexelSize;
        float4 _Side2_TexelSize;
        float _Smoothness;
        float4 _TopNormal_TexelSize;
        float4 _Side1Normal_TexelSize;
        float4 _Side2Normal_TexelSize;
        float4 _TopBlendColor;
        float _TopBlendStrength;
        float2 _TopTiling;
        float2 _SideTiling;
        float _TopNormalStrength;
        float _SideNormalStrength;
        float _Blend;
        float _TopBlend;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Top);
        SAMPLER(sampler_Top);
        TEXTURE2D(_Side1);
        SAMPLER(sampler_Side1);
        TEXTURE2D(_Side2);
        SAMPLER(sampler_Side2);
        TEXTURE2D(_TopNormal);
        SAMPLER(sampler_TopNormal);
        TEXTURE2D(_Side1Normal);
        SAMPLER(sampler_Side1Normal);
        TEXTURE2D(_Side2Normal);
        SAMPLER(sampler_Side2Normal);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }
        
        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }
        
        void Unity_Power_float3(float3 A, float3 B, out float3 Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Blend_Overlay_float4(float4 Base, float4 Blend, out float4 Out, float Opacity)
        {
            float4 result1 = 1.0 - 2.0 * (1.0 - Base) * (1.0 - Blend);
            float4 result2 = 2.0 * Base * Blend;
            float4 zeroOrOne = step(Base, 0.5);
            Out = result2 * zeroOrOne + (1 - zeroOrOne) * result1;
            Out = lerp(Base, Out, Opacity);
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        void Unity_MatrixConstruction_Row_float (float4 M0, float4 M1, float4 M2, float4 M3, out float4x4 Out4x4, out float3x3 Out3x3, out float2x2 Out2x2)
        {
            Out4x4 = float4x4(M0.x, M0.y, M0.z, M0.w, M1.x, M1.y, M1.z, M1.w, M2.x, M2.y, M2.z, M2.w, M3.x, M3.y, M3.z, M3.w);
            Out3x3 = float3x3(M0.x, M0.y, M0.z, M1.x, M1.y, M1.z, M2.x, M2.y, M2.z);
            Out2x2 = float2x2(M0.x, M0.y, M1.x, M1.y);
        }
        
        void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
        {
            Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
        }
        
        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_Multiply_float3x3_float3(float3x3 A, float3 B, out float3 Out)
        {
            Out = mul(A, B);
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0 = UnityBuildTexture2DStructNoScale(_Side1);
            float _Split_8a8287079f9a494382d5e21ff928e867_R_1 = IN.WorldSpacePosition[0];
            float _Split_8a8287079f9a494382d5e21ff928e867_G_2 = IN.WorldSpacePosition[1];
            float _Split_8a8287079f9a494382d5e21ff928e867_B_3 = IN.WorldSpacePosition[2];
            float _Split_8a8287079f9a494382d5e21ff928e867_A_4 = 0;
            float2 _Vector2_422303a2e182451483c76a2df62d8fbd_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_B_3, _Split_8a8287079f9a494382d5e21ff928e867_G_2);
            float2 _Property_f5515325ca8e44f0b693681c1553b814_Out_0 = _SideTiling;
            float2 _TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3;
            Unity_TilingAndOffset_float(_Vector2_422303a2e182451483c76a2df62d8fbd_Out_0, _Property_f5515325ca8e44f0b693681c1553b814_Out_0, float2 (0, 0), _TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3);
            float4 _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0 = SAMPLE_TEXTURE2D(_Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.tex, _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.samplerstate, _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.GetTransformedUV(_TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3));
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_R_4 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.r;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_G_5 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.g;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_B_6 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.b;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_A_7 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.a;
            float3 _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceNormal, _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1);
            float3 _Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1;
            Unity_Absolute_float3(_Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1, _Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1);
            float _Property_c199e3a40a374c27bc4f877aa0779f26_Out_0 = _Blend;
            float3 _Power_63f769573a36444489ea06f547e82f34_Out_2;
            Unity_Power_float3(_Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1, (_Property_c199e3a40a374c27bc4f877aa0779f26_Out_0.xxx), _Power_63f769573a36444489ea06f547e82f34_Out_2);
            float _Property_95e8e8c764df42cd849f5794c47de952_Out_0 = _TopBlend;
            float3 _Vector3_a22857b561994fd0b4fd09b1d80be6b2_Out_0 = float3(1, _Property_95e8e8c764df42cd849f5794c47de952_Out_0, 1);
            float3 _Multiply_901287298f374f398f61deb90e01229f_Out_2;
            Unity_Multiply_float3_float3(_Power_63f769573a36444489ea06f547e82f34_Out_2, _Vector3_a22857b561994fd0b4fd09b1d80be6b2_Out_0, _Multiply_901287298f374f398f61deb90e01229f_Out_2);
            float3 _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2;
            Unity_Maximum_float3(_Multiply_901287298f374f398f61deb90e01229f_Out_2, float3(0, 0, 0), _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2);
            float _Split_3bac21d320964dbca8d9094760c87a24_R_1 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[0];
            float _Split_3bac21d320964dbca8d9094760c87a24_G_2 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[1];
            float _Split_3bac21d320964dbca8d9094760c87a24_B_3 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[2];
            float _Split_3bac21d320964dbca8d9094760c87a24_A_4 = 0;
            float _Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2;
            Unity_Add_float(_Split_3bac21d320964dbca8d9094760c87a24_R_1, _Split_3bac21d320964dbca8d9094760c87a24_G_2, _Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2);
            float _Add_188219e788de45eba666bba49521d656_Out_2;
            Unity_Add_float(_Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2, _Split_3bac21d320964dbca8d9094760c87a24_B_3, _Add_188219e788de45eba666bba49521d656_Out_2);
            float3 _Divide_8aad109457564563994d4710b7e4648a_Out_2;
            Unity_Divide_float3(_Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2, (_Add_188219e788de45eba666bba49521d656_Out_2.xxx), _Divide_8aad109457564563994d4710b7e4648a_Out_2);
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[0];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[1];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[2];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_A_4 = 0;
            float4 _Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2;
            Unity_Multiply_float4_float4(_SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1.xxxx), _Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2);
            UnityTexture2D _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0 = UnityBuildTexture2DStructNoScale(_Top);
            float2 _Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_R_1, _Split_8a8287079f9a494382d5e21ff928e867_B_3);
            float2 _Property_556bde57ae654fa1a27d1f931f71f69d_Out_0 = _TopTiling;
            float2 _TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3;
            Unity_TilingAndOffset_float(_Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0, _Property_556bde57ae654fa1a27d1f931f71f69d_Out_0, float2 (0, 0), _TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3);
            float4 _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0 = SAMPLE_TEXTURE2D(_Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.tex, _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.samplerstate, _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.GetTransformedUV(_TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3));
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_R_4 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.r;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_G_5 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.g;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_B_6 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.b;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_A_7 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.a;
            float4 _Property_b80b6d14d20d46dfa59788b8390c12d8_Out_0 = _TopBlendColor;
            float _Property_bfc90837b07349408e8f8761a44b1114_Out_0 = _TopBlendStrength;
            float4 _Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2;
            Unity_Blend_Overlay_float4(_SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0, _Property_b80b6d14d20d46dfa59788b8390c12d8_Out_0, _Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2, _Property_bfc90837b07349408e8f8761a44b1114_Out_0);
            float4 _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2;
            Unity_Multiply_float4_float4(_Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2.xxxx), _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2);
            float4 _Add_218795fc166a426aa361c539f291e0b1_Out_2;
            Unity_Add_float4(_Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2, _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2, _Add_218795fc166a426aa361c539f291e0b1_Out_2);
            UnityTexture2D _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0 = UnityBuildTexture2DStructNoScale(_Side2);
            float2 _Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_R_1, _Split_8a8287079f9a494382d5e21ff928e867_G_2);
            float2 _Property_d2d6aa174ccc4fc98d6a72e79a21ea63_Out_0 = _SideTiling;
            float2 _TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3;
            Unity_TilingAndOffset_float(_Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0, _Property_d2d6aa174ccc4fc98d6a72e79a21ea63_Out_0, float2 (0, 0), _TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3);
            float4 _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.tex, _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.samplerstate, _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.GetTransformedUV(_TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3));
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_R_4 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.r;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_G_5 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.g;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_B_6 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.b;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_A_7 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.a;
            float4 _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2;
            Unity_Multiply_float4_float4(_SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3.xxxx), _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2);
            float4 _Add_933e680106a64ad8b90f42fd329b74f6_Out_2;
            Unity_Add_float4(_Add_218795fc166a426aa361c539f291e0b1_Out_2, _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2, _Add_933e680106a64ad8b90f42fd329b74f6_Out_2);
            float3 _Normalize_8fbf484698e949e48d41a75c7a42f02c_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceTangent, _Normalize_8fbf484698e949e48d41a75c7a42f02c_Out_1);
            float3 _Normalize_138139e3277b4fae8c902af48021c27b_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceBiTangent, _Normalize_138139e3277b4fae8c902af48021c27b_Out_1);
            float4x4 _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var4x4_4;
            float3x3 _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var3x3_5;
            float2x2 _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var2x2_6;
            Unity_MatrixConstruction_Row_float((float4(_Normalize_8fbf484698e949e48d41a75c7a42f02c_Out_1, 1.0)), (float4(_Normalize_138139e3277b4fae8c902af48021c27b_Out_1, 1.0)), (float4(_Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1, 1.0)), float4 (0, 0, 0, 0), _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var4x4_4, _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var3x3_5, _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var2x2_6);
            UnityTexture2D _Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0 = UnityBuildTexture2DStructNoScale(_Side1Normal);
            float2 _Property_fea94bc210a942a7b8f5e99b572205f2_Out_0 = _SideTiling;
            float2 _TilingAndOffset_f489eaa422e74c34b25248e65cb10f5c_Out_3;
            Unity_TilingAndOffset_float(_Vector2_422303a2e182451483c76a2df62d8fbd_Out_0, _Property_fea94bc210a942a7b8f5e99b572205f2_Out_0, float2 (0, 0), _TilingAndOffset_f489eaa422e74c34b25248e65cb10f5c_Out_3);
            float4 _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0.tex, _Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0.samplerstate, _Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0.GetTransformedUV(_TilingAndOffset_f489eaa422e74c34b25248e65cb10f5c_Out_3));
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_R_4 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.r;
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_G_5 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.g;
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_B_6 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.b;
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_A_7 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.a;
            float _Property_06bb67e1d14d4c7abb3826e91fe5d824_Out_0 = _SideNormalStrength;
            float3 _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.xyz), _Property_06bb67e1d14d4c7abb3826e91fe5d824_Out_0, _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2);
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_R_1 = _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2[0];
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_G_2 = _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2[1];
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_B_3 = _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2[2];
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_A_4 = 0;
            float _Absolute_81d9831799b840b9a1d2b4c566a1622a_Out_1;
            Unity_Absolute_float(_Split_27883ef8495d4e078f3c6ec5be5b3ac3_B_3, _Absolute_81d9831799b840b9a1d2b4c566a1622a_Out_1);
            float _Split_66b91a799fa249599b2cf7d52c20ceae_R_1 = _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1[0];
            float _Split_66b91a799fa249599b2cf7d52c20ceae_G_2 = _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1[1];
            float _Split_66b91a799fa249599b2cf7d52c20ceae_B_3 = _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1[2];
            float _Split_66b91a799fa249599b2cf7d52c20ceae_A_4 = 0;
            float _Multiply_cba9440999d14f09b0349ed5a9d0bb74_Out_2;
            Unity_Multiply_float_float(_Absolute_81d9831799b840b9a1d2b4c566a1622a_Out_1, _Split_66b91a799fa249599b2cf7d52c20ceae_R_1, _Multiply_cba9440999d14f09b0349ed5a9d0bb74_Out_2);
            float4 _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGBA_4;
            float3 _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGB_5;
            float2 _Combine_f3158e4900b649a79aa67d1e219ea4bd_RG_6;
            Unity_Combine_float(_Split_27883ef8495d4e078f3c6ec5be5b3ac3_R_1, _Split_27883ef8495d4e078f3c6ec5be5b3ac3_G_2, 0, 0, _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGBA_4, _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGB_5, _Combine_f3158e4900b649a79aa67d1e219ea4bd_RG_6);
            float4 _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGBA_4;
            float3 _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGB_5;
            float2 _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RG_6;
            Unity_Combine_float(_Split_66b91a799fa249599b2cf7d52c20ceae_B_3, _Split_66b91a799fa249599b2cf7d52c20ceae_G_2, 0, 0, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGBA_4, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGB_5, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RG_6);
            float2 _Add_45086c33520b40bf98a4b4e639013aaa_Out_2;
            Unity_Add_float2(_Combine_f3158e4900b649a79aa67d1e219ea4bd_RG_6, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RG_6, _Add_45086c33520b40bf98a4b4e639013aaa_Out_2);
            float _Split_01fe340496a6496594e1dbcd836efe88_R_1 = _Add_45086c33520b40bf98a4b4e639013aaa_Out_2[0];
            float _Split_01fe340496a6496594e1dbcd836efe88_G_2 = _Add_45086c33520b40bf98a4b4e639013aaa_Out_2[1];
            float _Split_01fe340496a6496594e1dbcd836efe88_B_3 = 0;
            float _Split_01fe340496a6496594e1dbcd836efe88_A_4 = 0;
            float4 _Combine_d41777d14eac458d8432b72821aa860a_RGBA_4;
            float3 _Combine_d41777d14eac458d8432b72821aa860a_RGB_5;
            float2 _Combine_d41777d14eac458d8432b72821aa860a_RG_6;
            Unity_Combine_float(_Multiply_cba9440999d14f09b0349ed5a9d0bb74_Out_2, _Split_01fe340496a6496594e1dbcd836efe88_G_2, _Split_01fe340496a6496594e1dbcd836efe88_R_1, 0, _Combine_d41777d14eac458d8432b72821aa860a_RGBA_4, _Combine_d41777d14eac458d8432b72821aa860a_RGB_5, _Combine_d41777d14eac458d8432b72821aa860a_RG_6);
            float3 _Multiply_25315676ebb14ebf82037668ac8e32b4_Out_2;
            Unity_Multiply_float3_float3(_Combine_d41777d14eac458d8432b72821aa860a_RGB_5, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1.xxx), _Multiply_25315676ebb14ebf82037668ac8e32b4_Out_2);
            UnityTexture2D _Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0 = UnityBuildTexture2DStructNoScale(_TopNormal);
            float2 _Property_c6841a14d6bf45d9bd1e07ea6f72d965_Out_0 = _TopTiling;
            float2 _TilingAndOffset_6e910a893a3a42719219523be1ad6c27_Out_3;
            Unity_TilingAndOffset_float(_Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0, _Property_c6841a14d6bf45d9bd1e07ea6f72d965_Out_0, float2 (0, 0), _TilingAndOffset_6e910a893a3a42719219523be1ad6c27_Out_3);
            float4 _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0 = SAMPLE_TEXTURE2D(_Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0.tex, _Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0.samplerstate, _Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0.GetTransformedUV(_TilingAndOffset_6e910a893a3a42719219523be1ad6c27_Out_3));
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_R_4 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.r;
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_G_5 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.g;
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_B_6 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.b;
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_A_7 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.a;
            float _Property_af07a77e53ef41f499e3970c74406ca7_Out_0 = _TopNormalStrength;
            float3 _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.xyz), _Property_af07a77e53ef41f499e3970c74406ca7_Out_0, _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2);
            float _Split_fbb97fbe21d8477d923efa93f57b1517_R_1 = _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2[0];
            float _Split_fbb97fbe21d8477d923efa93f57b1517_G_2 = _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2[1];
            float _Split_fbb97fbe21d8477d923efa93f57b1517_B_3 = _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2[2];
            float _Split_fbb97fbe21d8477d923efa93f57b1517_A_4 = 0;
            float4 _Combine_50f1cb9c657b489387ee416f1f77022a_RGBA_4;
            float3 _Combine_50f1cb9c657b489387ee416f1f77022a_RGB_5;
            float2 _Combine_50f1cb9c657b489387ee416f1f77022a_RG_6;
            Unity_Combine_float(_Split_fbb97fbe21d8477d923efa93f57b1517_R_1, _Split_fbb97fbe21d8477d923efa93f57b1517_G_2, 0, 0, _Combine_50f1cb9c657b489387ee416f1f77022a_RGBA_4, _Combine_50f1cb9c657b489387ee416f1f77022a_RGB_5, _Combine_50f1cb9c657b489387ee416f1f77022a_RG_6);
            float4 _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGBA_4;
            float3 _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGB_5;
            float2 _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RG_6;
            Unity_Combine_float(_Split_66b91a799fa249599b2cf7d52c20ceae_R_1, _Split_66b91a799fa249599b2cf7d52c20ceae_B_3, 0, 0, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGBA_4, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGB_5, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RG_6);
            float2 _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2;
            Unity_Add_float2(_Combine_50f1cb9c657b489387ee416f1f77022a_RG_6, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RG_6, _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2);
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_R_1 = _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2[0];
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_G_2 = _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2[1];
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_B_3 = 0;
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_A_4 = 0;
            float _Absolute_30a05240f6ed469ba0629dbec0af13f3_Out_1;
            Unity_Absolute_float(_Split_fbb97fbe21d8477d923efa93f57b1517_B_3, _Absolute_30a05240f6ed469ba0629dbec0af13f3_Out_1);
            float _Multiply_7ca96e1a618246f1b490d564baa2e44e_Out_2;
            Unity_Multiply_float_float(_Absolute_30a05240f6ed469ba0629dbec0af13f3_Out_1, _Split_66b91a799fa249599b2cf7d52c20ceae_G_2, _Multiply_7ca96e1a618246f1b490d564baa2e44e_Out_2);
            float4 _Combine_3397125918044e3d9e6e8897e6491ee8_RGBA_4;
            float3 _Combine_3397125918044e3d9e6e8897e6491ee8_RGB_5;
            float2 _Combine_3397125918044e3d9e6e8897e6491ee8_RG_6;
            Unity_Combine_float(_Split_d6e96aca1dcf4a6fa101dc65f44e8e91_R_1, _Multiply_7ca96e1a618246f1b490d564baa2e44e_Out_2, _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_G_2, 0, _Combine_3397125918044e3d9e6e8897e6491ee8_RGBA_4, _Combine_3397125918044e3d9e6e8897e6491ee8_RGB_5, _Combine_3397125918044e3d9e6e8897e6491ee8_RG_6);
            float3 _Multiply_e1d8696c71864d4e928f9d8ae5eae9b4_Out_2;
            Unity_Multiply_float3_float3(_Combine_3397125918044e3d9e6e8897e6491ee8_RGB_5, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2.xxx), _Multiply_e1d8696c71864d4e928f9d8ae5eae9b4_Out_2);
            float3 _Add_be41a1e3b7ab4933be449cce5b94e43b_Out_2;
            Unity_Add_float3(_Multiply_25315676ebb14ebf82037668ac8e32b4_Out_2, _Multiply_e1d8696c71864d4e928f9d8ae5eae9b4_Out_2, _Add_be41a1e3b7ab4933be449cce5b94e43b_Out_2);
            UnityTexture2D _Property_bbc64da39f6544c288772c846dba1d98_Out_0 = UnityBuildTexture2DStructNoScale(_Side2Normal);
            float2 _Property_e2c8ed57e8324498ba6690540c4b01ce_Out_0 = _SideTiling;
            float2 _TilingAndOffset_56b93257dea843cea4cc025009828652_Out_3;
            Unity_TilingAndOffset_float(_Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0, _Property_e2c8ed57e8324498ba6690540c4b01ce_Out_0, float2 (0, 0), _TilingAndOffset_56b93257dea843cea4cc025009828652_Out_3);
            float4 _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0 = SAMPLE_TEXTURE2D(_Property_bbc64da39f6544c288772c846dba1d98_Out_0.tex, _Property_bbc64da39f6544c288772c846dba1d98_Out_0.samplerstate, _Property_bbc64da39f6544c288772c846dba1d98_Out_0.GetTransformedUV(_TilingAndOffset_56b93257dea843cea4cc025009828652_Out_3));
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_R_4 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.r;
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_G_5 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.g;
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_B_6 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.b;
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_A_7 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.a;
            float _Property_34a5f85b6edf4acdad9f5e7f593ef446_Out_0 = _SideNormalStrength;
            float3 _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.xyz), _Property_34a5f85b6edf4acdad9f5e7f593ef446_Out_0, _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2);
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_R_1 = _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2[0];
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_G_2 = _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2[1];
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_B_3 = _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2[2];
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_A_4 = 0;
            float4 _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGBA_4;
            float3 _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGB_5;
            float2 _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RG_6;
            Unity_Combine_float(_Split_e9c2ff6ae8cb459492cfa8a97b4dd778_R_1, _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_G_2, 0, 0, _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGBA_4, _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGB_5, _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RG_6);
            float4 _Combine_77995c8f08c6490681323ba57c634868_RGBA_4;
            float3 _Combine_77995c8f08c6490681323ba57c634868_RGB_5;
            float2 _Combine_77995c8f08c6490681323ba57c634868_RG_6;
            Unity_Combine_float(_Split_66b91a799fa249599b2cf7d52c20ceae_R_1, _Split_66b91a799fa249599b2cf7d52c20ceae_G_2, 0, 0, _Combine_77995c8f08c6490681323ba57c634868_RGBA_4, _Combine_77995c8f08c6490681323ba57c634868_RGB_5, _Combine_77995c8f08c6490681323ba57c634868_RG_6);
            float2 _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2;
            Unity_Add_float2(_Combine_707341f8f2d94e1d82a3f1431a8f8c52_RG_6, _Combine_77995c8f08c6490681323ba57c634868_RG_6, _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2);
            float _Split_f649548941034bbabc90d4e027faf0f0_R_1 = _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2[0];
            float _Split_f649548941034bbabc90d4e027faf0f0_G_2 = _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2[1];
            float _Split_f649548941034bbabc90d4e027faf0f0_B_3 = 0;
            float _Split_f649548941034bbabc90d4e027faf0f0_A_4 = 0;
            float _Absolute_b8f8f975d97c46b7917fe882f3e0568e_Out_1;
            Unity_Absolute_float(_Split_e9c2ff6ae8cb459492cfa8a97b4dd778_B_3, _Absolute_b8f8f975d97c46b7917fe882f3e0568e_Out_1);
            float _Multiply_eb22109da7ee4bde9c64e86cdcb3f703_Out_2;
            Unity_Multiply_float_float(_Absolute_b8f8f975d97c46b7917fe882f3e0568e_Out_1, _Split_66b91a799fa249599b2cf7d52c20ceae_B_3, _Multiply_eb22109da7ee4bde9c64e86cdcb3f703_Out_2);
            float4 _Combine_f18458f1fbea4cafb126653f3c712144_RGBA_4;
            float3 _Combine_f18458f1fbea4cafb126653f3c712144_RGB_5;
            float2 _Combine_f18458f1fbea4cafb126653f3c712144_RG_6;
            Unity_Combine_float(_Split_f649548941034bbabc90d4e027faf0f0_R_1, _Split_f649548941034bbabc90d4e027faf0f0_G_2, _Multiply_eb22109da7ee4bde9c64e86cdcb3f703_Out_2, 0, _Combine_f18458f1fbea4cafb126653f3c712144_RGBA_4, _Combine_f18458f1fbea4cafb126653f3c712144_RGB_5, _Combine_f18458f1fbea4cafb126653f3c712144_RG_6);
            float3 _Multiply_f8671ad3faa54908abf30d5064d2b9ad_Out_2;
            Unity_Multiply_float3_float3(_Combine_f18458f1fbea4cafb126653f3c712144_RGB_5, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3.xxx), _Multiply_f8671ad3faa54908abf30d5064d2b9ad_Out_2);
            float3 _Add_5120cf7e02884188ab7e3ff15353fec9_Out_2;
            Unity_Add_float3(_Add_be41a1e3b7ab4933be449cce5b94e43b_Out_2, _Multiply_f8671ad3faa54908abf30d5064d2b9ad_Out_2, _Add_5120cf7e02884188ab7e3ff15353fec9_Out_2);
            float3 _Multiply_b8253329450045f6993d3c52a44be133_Out_2;
            Unity_Multiply_float3x3_float3(_MatrixConstruction_1497565cfa514012949cd6aca03566ee_var3x3_5, _Add_5120cf7e02884188ab7e3ff15353fec9_Out_2, _Multiply_b8253329450045f6993d3c52a44be133_Out_2);
            float3 _Normalize_8ba6483360404f6a986179ff26c09eac_Out_1;
            Unity_Normalize_float3(_Multiply_b8253329450045f6993d3c52a44be133_Out_2, _Normalize_8ba6483360404f6a986179ff26c09eac_Out_1);
            float _Property_85554735f66147248ee259c177929e1f_Out_0 = _Smoothness;
            surface.BaseColor = (_Add_933e680106a64ad8b90f42fd329b74f6_Out_2.xyz);
            surface.NormalTS = _Normalize_8ba6483360404f6a986179ff26c09eac_Out_1;
            surface.Emission = float3(0, 0, 0);
            surface.Metallic = 0;
            surface.Smoothness = _Property_85554735f66147248ee259c177929e1f_Out_0;
            surface.Occlusion = 1;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
            // use bitangent on the fly like in hdrp
            // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0)* GetOddNegativeScale();
            float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
            // to pr               eserve mikktspace compliance we use same scale renormFactor as was used on the normal.
            // This                is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent = renormFactor * input.tangentWS.xyz;
            output.WorldSpaceBiTangent = renormFactor * bitang;
        
            output.WorldSpacePosition = input.positionWS;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "PBRForwardPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "GBuffer"
            Tags
            {
                "LightMode" = "UniversalGBuffer"
            }
        
        // Render State
        Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DYNAMICLIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
        #pragma multi_compile_fragment _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
        #pragma multi_compile _ SHADOWS_SHADOWMASK
        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
        #pragma multi_compile_fragment _ _LIGHT_LAYERS
        #pragma multi_compile_fragment _ _RENDER_PASS_ENABLED
        #pragma multi_compile_fragment _ DEBUG_DISPLAY
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define VARYINGS_NEED_SHADOW_COORD
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_GBUFFER
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "ShaderStructures.hlsl"
        uniform StructuredBuffer<Triangle> triangleBuffer;
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             uint id : SV_VertexID;
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
             float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
             float2 staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
             float2 dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
             float3 sh;
            #endif
             float4 fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
             float4 shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 TangentSpaceNormal;
             float3 WorldSpaceTangent;
             float3 WorldSpaceBiTangent;
             float3 WorldSpacePosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float3 interp3 : INTERP3;
             float2 interp4 : INTERP4;
             float2 interp5 : INTERP5;
             float3 interp6 : INTERP6;
             float4 interp7 : INTERP7;
             float4 interp8 : INTERP8;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.interp5.xy =  input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp6.xyz =  input.sh;
            #endif
            output.interp7.xyzw =  input.fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.interp8.xyzw =  input.shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.interp4.xy;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.interp5.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp6.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp7.xyzw;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.interp8.xyzw;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Top_TexelSize;
        float4 _Side1_TexelSize;
        float4 _Side2_TexelSize;
        float _Smoothness;
        float4 _TopNormal_TexelSize;
        float4 _Side1Normal_TexelSize;
        float4 _Side2Normal_TexelSize;
        float4 _TopBlendColor;
        float _TopBlendStrength;
        float2 _TopTiling;
        float2 _SideTiling;
        float _TopNormalStrength;
        float _SideNormalStrength;
        float _Blend;
        float _TopBlend;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Top);
        SAMPLER(sampler_Top);
        TEXTURE2D(_Side1);
        SAMPLER(sampler_Side1);
        TEXTURE2D(_Side2);
        SAMPLER(sampler_Side2);
        TEXTURE2D(_TopNormal);
        SAMPLER(sampler_TopNormal);
        TEXTURE2D(_Side1Normal);
        SAMPLER(sampler_Side1Normal);
        TEXTURE2D(_Side2Normal);
        SAMPLER(sampler_Side2Normal);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }
        
        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }
        
        void Unity_Power_float3(float3 A, float3 B, out float3 Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Blend_Overlay_float4(float4 Base, float4 Blend, out float4 Out, float Opacity)
        {
            float4 result1 = 1.0 - 2.0 * (1.0 - Base) * (1.0 - Blend);
            float4 result2 = 2.0 * Base * Blend;
            float4 zeroOrOne = step(Base, 0.5);
            Out = result2 * zeroOrOne + (1 - zeroOrOne) * result1;
            Out = lerp(Base, Out, Opacity);
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        void Unity_MatrixConstruction_Row_float (float4 M0, float4 M1, float4 M2, float4 M3, out float4x4 Out4x4, out float3x3 Out3x3, out float2x2 Out2x2)
        {
            Out4x4 = float4x4(M0.x, M0.y, M0.z, M0.w, M1.x, M1.y, M1.z, M1.w, M2.x, M2.y, M2.z, M2.w, M3.x, M3.y, M3.z, M3.w);
            Out3x3 = float3x3(M0.x, M0.y, M0.z, M1.x, M1.y, M1.z, M2.x, M2.y, M2.z);
            Out2x2 = float2x2(M0.x, M0.y, M1.x, M1.y);
        }
        
        void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
        {
            Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
        }
        
        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_Multiply_float3x3_float3(float3x3 A, float3 B, out float3 Out)
        {
            Out = mul(A, B);
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0 = UnityBuildTexture2DStructNoScale(_Side1);
            float _Split_8a8287079f9a494382d5e21ff928e867_R_1 = IN.WorldSpacePosition[0];
            float _Split_8a8287079f9a494382d5e21ff928e867_G_2 = IN.WorldSpacePosition[1];
            float _Split_8a8287079f9a494382d5e21ff928e867_B_3 = IN.WorldSpacePosition[2];
            float _Split_8a8287079f9a494382d5e21ff928e867_A_4 = 0;
            float2 _Vector2_422303a2e182451483c76a2df62d8fbd_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_B_3, _Split_8a8287079f9a494382d5e21ff928e867_G_2);
            float2 _Property_f5515325ca8e44f0b693681c1553b814_Out_0 = _SideTiling;
            float2 _TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3;
            Unity_TilingAndOffset_float(_Vector2_422303a2e182451483c76a2df62d8fbd_Out_0, _Property_f5515325ca8e44f0b693681c1553b814_Out_0, float2 (0, 0), _TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3);
            float4 _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0 = SAMPLE_TEXTURE2D(_Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.tex, _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.samplerstate, _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.GetTransformedUV(_TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3));
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_R_4 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.r;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_G_5 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.g;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_B_6 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.b;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_A_7 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.a;
            float3 _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceNormal, _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1);
            float3 _Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1;
            Unity_Absolute_float3(_Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1, _Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1);
            float _Property_c199e3a40a374c27bc4f877aa0779f26_Out_0 = _Blend;
            float3 _Power_63f769573a36444489ea06f547e82f34_Out_2;
            Unity_Power_float3(_Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1, (_Property_c199e3a40a374c27bc4f877aa0779f26_Out_0.xxx), _Power_63f769573a36444489ea06f547e82f34_Out_2);
            float _Property_95e8e8c764df42cd849f5794c47de952_Out_0 = _TopBlend;
            float3 _Vector3_a22857b561994fd0b4fd09b1d80be6b2_Out_0 = float3(1, _Property_95e8e8c764df42cd849f5794c47de952_Out_0, 1);
            float3 _Multiply_901287298f374f398f61deb90e01229f_Out_2;
            Unity_Multiply_float3_float3(_Power_63f769573a36444489ea06f547e82f34_Out_2, _Vector3_a22857b561994fd0b4fd09b1d80be6b2_Out_0, _Multiply_901287298f374f398f61deb90e01229f_Out_2);
            float3 _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2;
            Unity_Maximum_float3(_Multiply_901287298f374f398f61deb90e01229f_Out_2, float3(0, 0, 0), _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2);
            float _Split_3bac21d320964dbca8d9094760c87a24_R_1 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[0];
            float _Split_3bac21d320964dbca8d9094760c87a24_G_2 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[1];
            float _Split_3bac21d320964dbca8d9094760c87a24_B_3 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[2];
            float _Split_3bac21d320964dbca8d9094760c87a24_A_4 = 0;
            float _Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2;
            Unity_Add_float(_Split_3bac21d320964dbca8d9094760c87a24_R_1, _Split_3bac21d320964dbca8d9094760c87a24_G_2, _Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2);
            float _Add_188219e788de45eba666bba49521d656_Out_2;
            Unity_Add_float(_Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2, _Split_3bac21d320964dbca8d9094760c87a24_B_3, _Add_188219e788de45eba666bba49521d656_Out_2);
            float3 _Divide_8aad109457564563994d4710b7e4648a_Out_2;
            Unity_Divide_float3(_Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2, (_Add_188219e788de45eba666bba49521d656_Out_2.xxx), _Divide_8aad109457564563994d4710b7e4648a_Out_2);
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[0];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[1];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[2];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_A_4 = 0;
            float4 _Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2;
            Unity_Multiply_float4_float4(_SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1.xxxx), _Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2);
            UnityTexture2D _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0 = UnityBuildTexture2DStructNoScale(_Top);
            float2 _Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_R_1, _Split_8a8287079f9a494382d5e21ff928e867_B_3);
            float2 _Property_556bde57ae654fa1a27d1f931f71f69d_Out_0 = _TopTiling;
            float2 _TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3;
            Unity_TilingAndOffset_float(_Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0, _Property_556bde57ae654fa1a27d1f931f71f69d_Out_0, float2 (0, 0), _TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3);
            float4 _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0 = SAMPLE_TEXTURE2D(_Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.tex, _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.samplerstate, _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.GetTransformedUV(_TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3));
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_R_4 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.r;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_G_5 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.g;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_B_6 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.b;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_A_7 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.a;
            float4 _Property_b80b6d14d20d46dfa59788b8390c12d8_Out_0 = _TopBlendColor;
            float _Property_bfc90837b07349408e8f8761a44b1114_Out_0 = _TopBlendStrength;
            float4 _Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2;
            Unity_Blend_Overlay_float4(_SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0, _Property_b80b6d14d20d46dfa59788b8390c12d8_Out_0, _Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2, _Property_bfc90837b07349408e8f8761a44b1114_Out_0);
            float4 _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2;
            Unity_Multiply_float4_float4(_Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2.xxxx), _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2);
            float4 _Add_218795fc166a426aa361c539f291e0b1_Out_2;
            Unity_Add_float4(_Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2, _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2, _Add_218795fc166a426aa361c539f291e0b1_Out_2);
            UnityTexture2D _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0 = UnityBuildTexture2DStructNoScale(_Side2);
            float2 _Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_R_1, _Split_8a8287079f9a494382d5e21ff928e867_G_2);
            float2 _Property_d2d6aa174ccc4fc98d6a72e79a21ea63_Out_0 = _SideTiling;
            float2 _TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3;
            Unity_TilingAndOffset_float(_Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0, _Property_d2d6aa174ccc4fc98d6a72e79a21ea63_Out_0, float2 (0, 0), _TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3);
            float4 _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.tex, _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.samplerstate, _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.GetTransformedUV(_TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3));
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_R_4 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.r;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_G_5 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.g;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_B_6 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.b;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_A_7 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.a;
            float4 _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2;
            Unity_Multiply_float4_float4(_SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3.xxxx), _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2);
            float4 _Add_933e680106a64ad8b90f42fd329b74f6_Out_2;
            Unity_Add_float4(_Add_218795fc166a426aa361c539f291e0b1_Out_2, _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2, _Add_933e680106a64ad8b90f42fd329b74f6_Out_2);
            float3 _Normalize_8fbf484698e949e48d41a75c7a42f02c_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceTangent, _Normalize_8fbf484698e949e48d41a75c7a42f02c_Out_1);
            float3 _Normalize_138139e3277b4fae8c902af48021c27b_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceBiTangent, _Normalize_138139e3277b4fae8c902af48021c27b_Out_1);
            float4x4 _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var4x4_4;
            float3x3 _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var3x3_5;
            float2x2 _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var2x2_6;
            Unity_MatrixConstruction_Row_float((float4(_Normalize_8fbf484698e949e48d41a75c7a42f02c_Out_1, 1.0)), (float4(_Normalize_138139e3277b4fae8c902af48021c27b_Out_1, 1.0)), (float4(_Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1, 1.0)), float4 (0, 0, 0, 0), _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var4x4_4, _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var3x3_5, _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var2x2_6);
            UnityTexture2D _Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0 = UnityBuildTexture2DStructNoScale(_Side1Normal);
            float2 _Property_fea94bc210a942a7b8f5e99b572205f2_Out_0 = _SideTiling;
            float2 _TilingAndOffset_f489eaa422e74c34b25248e65cb10f5c_Out_3;
            Unity_TilingAndOffset_float(_Vector2_422303a2e182451483c76a2df62d8fbd_Out_0, _Property_fea94bc210a942a7b8f5e99b572205f2_Out_0, float2 (0, 0), _TilingAndOffset_f489eaa422e74c34b25248e65cb10f5c_Out_3);
            float4 _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0.tex, _Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0.samplerstate, _Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0.GetTransformedUV(_TilingAndOffset_f489eaa422e74c34b25248e65cb10f5c_Out_3));
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_R_4 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.r;
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_G_5 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.g;
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_B_6 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.b;
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_A_7 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.a;
            float _Property_06bb67e1d14d4c7abb3826e91fe5d824_Out_0 = _SideNormalStrength;
            float3 _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.xyz), _Property_06bb67e1d14d4c7abb3826e91fe5d824_Out_0, _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2);
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_R_1 = _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2[0];
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_G_2 = _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2[1];
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_B_3 = _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2[2];
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_A_4 = 0;
            float _Absolute_81d9831799b840b9a1d2b4c566a1622a_Out_1;
            Unity_Absolute_float(_Split_27883ef8495d4e078f3c6ec5be5b3ac3_B_3, _Absolute_81d9831799b840b9a1d2b4c566a1622a_Out_1);
            float _Split_66b91a799fa249599b2cf7d52c20ceae_R_1 = _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1[0];
            float _Split_66b91a799fa249599b2cf7d52c20ceae_G_2 = _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1[1];
            float _Split_66b91a799fa249599b2cf7d52c20ceae_B_3 = _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1[2];
            float _Split_66b91a799fa249599b2cf7d52c20ceae_A_4 = 0;
            float _Multiply_cba9440999d14f09b0349ed5a9d0bb74_Out_2;
            Unity_Multiply_float_float(_Absolute_81d9831799b840b9a1d2b4c566a1622a_Out_1, _Split_66b91a799fa249599b2cf7d52c20ceae_R_1, _Multiply_cba9440999d14f09b0349ed5a9d0bb74_Out_2);
            float4 _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGBA_4;
            float3 _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGB_5;
            float2 _Combine_f3158e4900b649a79aa67d1e219ea4bd_RG_6;
            Unity_Combine_float(_Split_27883ef8495d4e078f3c6ec5be5b3ac3_R_1, _Split_27883ef8495d4e078f3c6ec5be5b3ac3_G_2, 0, 0, _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGBA_4, _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGB_5, _Combine_f3158e4900b649a79aa67d1e219ea4bd_RG_6);
            float4 _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGBA_4;
            float3 _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGB_5;
            float2 _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RG_6;
            Unity_Combine_float(_Split_66b91a799fa249599b2cf7d52c20ceae_B_3, _Split_66b91a799fa249599b2cf7d52c20ceae_G_2, 0, 0, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGBA_4, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGB_5, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RG_6);
            float2 _Add_45086c33520b40bf98a4b4e639013aaa_Out_2;
            Unity_Add_float2(_Combine_f3158e4900b649a79aa67d1e219ea4bd_RG_6, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RG_6, _Add_45086c33520b40bf98a4b4e639013aaa_Out_2);
            float _Split_01fe340496a6496594e1dbcd836efe88_R_1 = _Add_45086c33520b40bf98a4b4e639013aaa_Out_2[0];
            float _Split_01fe340496a6496594e1dbcd836efe88_G_2 = _Add_45086c33520b40bf98a4b4e639013aaa_Out_2[1];
            float _Split_01fe340496a6496594e1dbcd836efe88_B_3 = 0;
            float _Split_01fe340496a6496594e1dbcd836efe88_A_4 = 0;
            float4 _Combine_d41777d14eac458d8432b72821aa860a_RGBA_4;
            float3 _Combine_d41777d14eac458d8432b72821aa860a_RGB_5;
            float2 _Combine_d41777d14eac458d8432b72821aa860a_RG_6;
            Unity_Combine_float(_Multiply_cba9440999d14f09b0349ed5a9d0bb74_Out_2, _Split_01fe340496a6496594e1dbcd836efe88_G_2, _Split_01fe340496a6496594e1dbcd836efe88_R_1, 0, _Combine_d41777d14eac458d8432b72821aa860a_RGBA_4, _Combine_d41777d14eac458d8432b72821aa860a_RGB_5, _Combine_d41777d14eac458d8432b72821aa860a_RG_6);
            float3 _Multiply_25315676ebb14ebf82037668ac8e32b4_Out_2;
            Unity_Multiply_float3_float3(_Combine_d41777d14eac458d8432b72821aa860a_RGB_5, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1.xxx), _Multiply_25315676ebb14ebf82037668ac8e32b4_Out_2);
            UnityTexture2D _Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0 = UnityBuildTexture2DStructNoScale(_TopNormal);
            float2 _Property_c6841a14d6bf45d9bd1e07ea6f72d965_Out_0 = _TopTiling;
            float2 _TilingAndOffset_6e910a893a3a42719219523be1ad6c27_Out_3;
            Unity_TilingAndOffset_float(_Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0, _Property_c6841a14d6bf45d9bd1e07ea6f72d965_Out_0, float2 (0, 0), _TilingAndOffset_6e910a893a3a42719219523be1ad6c27_Out_3);
            float4 _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0 = SAMPLE_TEXTURE2D(_Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0.tex, _Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0.samplerstate, _Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0.GetTransformedUV(_TilingAndOffset_6e910a893a3a42719219523be1ad6c27_Out_3));
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_R_4 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.r;
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_G_5 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.g;
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_B_6 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.b;
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_A_7 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.a;
            float _Property_af07a77e53ef41f499e3970c74406ca7_Out_0 = _TopNormalStrength;
            float3 _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.xyz), _Property_af07a77e53ef41f499e3970c74406ca7_Out_0, _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2);
            float _Split_fbb97fbe21d8477d923efa93f57b1517_R_1 = _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2[0];
            float _Split_fbb97fbe21d8477d923efa93f57b1517_G_2 = _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2[1];
            float _Split_fbb97fbe21d8477d923efa93f57b1517_B_3 = _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2[2];
            float _Split_fbb97fbe21d8477d923efa93f57b1517_A_4 = 0;
            float4 _Combine_50f1cb9c657b489387ee416f1f77022a_RGBA_4;
            float3 _Combine_50f1cb9c657b489387ee416f1f77022a_RGB_5;
            float2 _Combine_50f1cb9c657b489387ee416f1f77022a_RG_6;
            Unity_Combine_float(_Split_fbb97fbe21d8477d923efa93f57b1517_R_1, _Split_fbb97fbe21d8477d923efa93f57b1517_G_2, 0, 0, _Combine_50f1cb9c657b489387ee416f1f77022a_RGBA_4, _Combine_50f1cb9c657b489387ee416f1f77022a_RGB_5, _Combine_50f1cb9c657b489387ee416f1f77022a_RG_6);
            float4 _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGBA_4;
            float3 _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGB_5;
            float2 _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RG_6;
            Unity_Combine_float(_Split_66b91a799fa249599b2cf7d52c20ceae_R_1, _Split_66b91a799fa249599b2cf7d52c20ceae_B_3, 0, 0, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGBA_4, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGB_5, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RG_6);
            float2 _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2;
            Unity_Add_float2(_Combine_50f1cb9c657b489387ee416f1f77022a_RG_6, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RG_6, _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2);
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_R_1 = _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2[0];
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_G_2 = _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2[1];
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_B_3 = 0;
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_A_4 = 0;
            float _Absolute_30a05240f6ed469ba0629dbec0af13f3_Out_1;
            Unity_Absolute_float(_Split_fbb97fbe21d8477d923efa93f57b1517_B_3, _Absolute_30a05240f6ed469ba0629dbec0af13f3_Out_1);
            float _Multiply_7ca96e1a618246f1b490d564baa2e44e_Out_2;
            Unity_Multiply_float_float(_Absolute_30a05240f6ed469ba0629dbec0af13f3_Out_1, _Split_66b91a799fa249599b2cf7d52c20ceae_G_2, _Multiply_7ca96e1a618246f1b490d564baa2e44e_Out_2);
            float4 _Combine_3397125918044e3d9e6e8897e6491ee8_RGBA_4;
            float3 _Combine_3397125918044e3d9e6e8897e6491ee8_RGB_5;
            float2 _Combine_3397125918044e3d9e6e8897e6491ee8_RG_6;
            Unity_Combine_float(_Split_d6e96aca1dcf4a6fa101dc65f44e8e91_R_1, _Multiply_7ca96e1a618246f1b490d564baa2e44e_Out_2, _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_G_2, 0, _Combine_3397125918044e3d9e6e8897e6491ee8_RGBA_4, _Combine_3397125918044e3d9e6e8897e6491ee8_RGB_5, _Combine_3397125918044e3d9e6e8897e6491ee8_RG_6);
            float3 _Multiply_e1d8696c71864d4e928f9d8ae5eae9b4_Out_2;
            Unity_Multiply_float3_float3(_Combine_3397125918044e3d9e6e8897e6491ee8_RGB_5, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2.xxx), _Multiply_e1d8696c71864d4e928f9d8ae5eae9b4_Out_2);
            float3 _Add_be41a1e3b7ab4933be449cce5b94e43b_Out_2;
            Unity_Add_float3(_Multiply_25315676ebb14ebf82037668ac8e32b4_Out_2, _Multiply_e1d8696c71864d4e928f9d8ae5eae9b4_Out_2, _Add_be41a1e3b7ab4933be449cce5b94e43b_Out_2);
            UnityTexture2D _Property_bbc64da39f6544c288772c846dba1d98_Out_0 = UnityBuildTexture2DStructNoScale(_Side2Normal);
            float2 _Property_e2c8ed57e8324498ba6690540c4b01ce_Out_0 = _SideTiling;
            float2 _TilingAndOffset_56b93257dea843cea4cc025009828652_Out_3;
            Unity_TilingAndOffset_float(_Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0, _Property_e2c8ed57e8324498ba6690540c4b01ce_Out_0, float2 (0, 0), _TilingAndOffset_56b93257dea843cea4cc025009828652_Out_3);
            float4 _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0 = SAMPLE_TEXTURE2D(_Property_bbc64da39f6544c288772c846dba1d98_Out_0.tex, _Property_bbc64da39f6544c288772c846dba1d98_Out_0.samplerstate, _Property_bbc64da39f6544c288772c846dba1d98_Out_0.GetTransformedUV(_TilingAndOffset_56b93257dea843cea4cc025009828652_Out_3));
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_R_4 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.r;
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_G_5 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.g;
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_B_6 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.b;
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_A_7 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.a;
            float _Property_34a5f85b6edf4acdad9f5e7f593ef446_Out_0 = _SideNormalStrength;
            float3 _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.xyz), _Property_34a5f85b6edf4acdad9f5e7f593ef446_Out_0, _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2);
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_R_1 = _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2[0];
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_G_2 = _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2[1];
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_B_3 = _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2[2];
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_A_4 = 0;
            float4 _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGBA_4;
            float3 _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGB_5;
            float2 _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RG_6;
            Unity_Combine_float(_Split_e9c2ff6ae8cb459492cfa8a97b4dd778_R_1, _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_G_2, 0, 0, _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGBA_4, _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGB_5, _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RG_6);
            float4 _Combine_77995c8f08c6490681323ba57c634868_RGBA_4;
            float3 _Combine_77995c8f08c6490681323ba57c634868_RGB_5;
            float2 _Combine_77995c8f08c6490681323ba57c634868_RG_6;
            Unity_Combine_float(_Split_66b91a799fa249599b2cf7d52c20ceae_R_1, _Split_66b91a799fa249599b2cf7d52c20ceae_G_2, 0, 0, _Combine_77995c8f08c6490681323ba57c634868_RGBA_4, _Combine_77995c8f08c6490681323ba57c634868_RGB_5, _Combine_77995c8f08c6490681323ba57c634868_RG_6);
            float2 _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2;
            Unity_Add_float2(_Combine_707341f8f2d94e1d82a3f1431a8f8c52_RG_6, _Combine_77995c8f08c6490681323ba57c634868_RG_6, _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2);
            float _Split_f649548941034bbabc90d4e027faf0f0_R_1 = _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2[0];
            float _Split_f649548941034bbabc90d4e027faf0f0_G_2 = _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2[1];
            float _Split_f649548941034bbabc90d4e027faf0f0_B_3 = 0;
            float _Split_f649548941034bbabc90d4e027faf0f0_A_4 = 0;
            float _Absolute_b8f8f975d97c46b7917fe882f3e0568e_Out_1;
            Unity_Absolute_float(_Split_e9c2ff6ae8cb459492cfa8a97b4dd778_B_3, _Absolute_b8f8f975d97c46b7917fe882f3e0568e_Out_1);
            float _Multiply_eb22109da7ee4bde9c64e86cdcb3f703_Out_2;
            Unity_Multiply_float_float(_Absolute_b8f8f975d97c46b7917fe882f3e0568e_Out_1, _Split_66b91a799fa249599b2cf7d52c20ceae_B_3, _Multiply_eb22109da7ee4bde9c64e86cdcb3f703_Out_2);
            float4 _Combine_f18458f1fbea4cafb126653f3c712144_RGBA_4;
            float3 _Combine_f18458f1fbea4cafb126653f3c712144_RGB_5;
            float2 _Combine_f18458f1fbea4cafb126653f3c712144_RG_6;
            Unity_Combine_float(_Split_f649548941034bbabc90d4e027faf0f0_R_1, _Split_f649548941034bbabc90d4e027faf0f0_G_2, _Multiply_eb22109da7ee4bde9c64e86cdcb3f703_Out_2, 0, _Combine_f18458f1fbea4cafb126653f3c712144_RGBA_4, _Combine_f18458f1fbea4cafb126653f3c712144_RGB_5, _Combine_f18458f1fbea4cafb126653f3c712144_RG_6);
            float3 _Multiply_f8671ad3faa54908abf30d5064d2b9ad_Out_2;
            Unity_Multiply_float3_float3(_Combine_f18458f1fbea4cafb126653f3c712144_RGB_5, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3.xxx), _Multiply_f8671ad3faa54908abf30d5064d2b9ad_Out_2);
            float3 _Add_5120cf7e02884188ab7e3ff15353fec9_Out_2;
            Unity_Add_float3(_Add_be41a1e3b7ab4933be449cce5b94e43b_Out_2, _Multiply_f8671ad3faa54908abf30d5064d2b9ad_Out_2, _Add_5120cf7e02884188ab7e3ff15353fec9_Out_2);
            float3 _Multiply_b8253329450045f6993d3c52a44be133_Out_2;
            Unity_Multiply_float3x3_float3(_MatrixConstruction_1497565cfa514012949cd6aca03566ee_var3x3_5, _Add_5120cf7e02884188ab7e3ff15353fec9_Out_2, _Multiply_b8253329450045f6993d3c52a44be133_Out_2);
            float3 _Normalize_8ba6483360404f6a986179ff26c09eac_Out_1;
            Unity_Normalize_float3(_Multiply_b8253329450045f6993d3c52a44be133_Out_2, _Normalize_8ba6483360404f6a986179ff26c09eac_Out_1);
            float _Property_85554735f66147248ee259c177929e1f_Out_0 = _Smoothness;
            surface.BaseColor = (_Add_933e680106a64ad8b90f42fd329b74f6_Out_2.xyz);
            surface.NormalTS = _Normalize_8ba6483360404f6a986179ff26c09eac_Out_1;
            surface.Emission = float3(0, 0, 0);
            surface.Metallic = 0;
            surface.Smoothness = _Property_85554735f66147248ee259c177929e1f_Out_0;
            surface.Occlusion = 1;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
            // use bitangent on the fly like in hdrp
            // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0)* GetOddNegativeScale();
            float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
            // to pr               eserve mikktspace compliance we use same scale renormFactor as was used on the normal.
            // This                is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent = renormFactor * input.tangentWS.xyz;
            output.WorldSpaceBiTangent = renormFactor * bitang;
        
            output.WorldSpacePosition = input.positionWS;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
        #include "PBRGBufferPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        ColorMask 0
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_NORMAL_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SHADOWCASTER
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "ShaderStructures.hlsl"
        uniform StructuredBuffer<Triangle> triangleBuffer;
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             uint id : SV_VertexID;
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.normalWS = input.interp0.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Top_TexelSize;
        float4 _Side1_TexelSize;
        float4 _Side2_TexelSize;
        float _Smoothness;
        float4 _TopNormal_TexelSize;
        float4 _Side1Normal_TexelSize;
        float4 _Side2Normal_TexelSize;
        float4 _TopBlendColor;
        float _TopBlendStrength;
        float2 _TopTiling;
        float2 _SideTiling;
        float _TopNormalStrength;
        float _SideNormalStrength;
        float _Blend;
        float _TopBlend;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Top);
        SAMPLER(sampler_Top);
        TEXTURE2D(_Side1);
        SAMPLER(sampler_Side1);
        TEXTURE2D(_Side2);
        SAMPLER(sampler_Side2);
        TEXTURE2D(_TopNormal);
        SAMPLER(sampler_TopNormal);
        TEXTURE2D(_Side1Normal);
        SAMPLER(sampler_Side1Normal);
        TEXTURE2D(_Side2Normal);
        SAMPLER(sampler_Side2Normal);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        // GraphFunctions: <None>
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "ShadowCasterPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        ColorMask 0
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "ShaderStructures.hlsl"
        uniform StructuredBuffer<Triangle> triangleBuffer;
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             uint id : SV_VertexID;
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Top_TexelSize;
        float4 _Side1_TexelSize;
        float4 _Side2_TexelSize;
        float _Smoothness;
        float4 _TopNormal_TexelSize;
        float4 _Side1Normal_TexelSize;
        float4 _Side2Normal_TexelSize;
        float4 _TopBlendColor;
        float _TopBlendStrength;
        float2 _TopTiling;
        float2 _SideTiling;
        float _TopNormalStrength;
        float _SideNormalStrength;
        float _Blend;
        float _TopBlend;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Top);
        SAMPLER(sampler_Top);
        TEXTURE2D(_Side1);
        SAMPLER(sampler_Side1);
        TEXTURE2D(_Side2);
        SAMPLER(sampler_Side2);
        TEXTURE2D(_TopNormal);
        SAMPLER(sampler_TopNormal);
        TEXTURE2D(_Side1Normal);
        SAMPLER(sampler_Side1Normal);
        TEXTURE2D(_Side2Normal);
        SAMPLER(sampler_Side2Normal);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        // GraphFunctions: <None>
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "DepthOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALS
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "ShaderStructures.hlsl"
        uniform StructuredBuffer<Triangle> triangleBuffer;
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             uint id : SV_VertexID;
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 TangentSpaceNormal;
             float3 WorldSpaceTangent;
             float3 WorldSpaceBiTangent;
             float3 WorldSpacePosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Top_TexelSize;
        float4 _Side1_TexelSize;
        float4 _Side2_TexelSize;
        float _Smoothness;
        float4 _TopNormal_TexelSize;
        float4 _Side1Normal_TexelSize;
        float4 _Side2Normal_TexelSize;
        float4 _TopBlendColor;
        float _TopBlendStrength;
        float2 _TopTiling;
        float2 _SideTiling;
        float _TopNormalStrength;
        float _SideNormalStrength;
        float _Blend;
        float _TopBlend;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Top);
        SAMPLER(sampler_Top);
        TEXTURE2D(_Side1);
        SAMPLER(sampler_Side1);
        TEXTURE2D(_Side2);
        SAMPLER(sampler_Side2);
        TEXTURE2D(_TopNormal);
        SAMPLER(sampler_TopNormal);
        TEXTURE2D(_Side1Normal);
        SAMPLER(sampler_Side1Normal);
        TEXTURE2D(_Side2Normal);
        SAMPLER(sampler_Side2Normal);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }
        
        void Unity_MatrixConstruction_Row_float (float4 M0, float4 M1, float4 M2, float4 M3, out float4x4 Out4x4, out float3x3 Out3x3, out float2x2 Out2x2)
        {
            Out4x4 = float4x4(M0.x, M0.y, M0.z, M0.w, M1.x, M1.y, M1.z, M1.w, M2.x, M2.y, M2.z, M2.w, M3.x, M3.y, M3.z, M3.w);
            Out3x3 = float3x3(M0.x, M0.y, M0.z, M1.x, M1.y, M1.z, M2.x, M2.y, M2.z);
            Out2x2 = float2x2(M0.x, M0.y, M1.x, M1.y);
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
        {
            Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
        }
        
        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }
        
        void Unity_Power_float3(float3 A, float3 B, out float3 Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_Multiply_float3x3_float3(float3x3 A, float3 B, out float3 Out)
        {
            Out = mul(A, B);
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 NormalTS;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float3 _Normalize_8fbf484698e949e48d41a75c7a42f02c_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceTangent, _Normalize_8fbf484698e949e48d41a75c7a42f02c_Out_1);
            float3 _Normalize_138139e3277b4fae8c902af48021c27b_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceBiTangent, _Normalize_138139e3277b4fae8c902af48021c27b_Out_1);
            float3 _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceNormal, _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1);
            float4x4 _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var4x4_4;
            float3x3 _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var3x3_5;
            float2x2 _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var2x2_6;
            Unity_MatrixConstruction_Row_float((float4(_Normalize_8fbf484698e949e48d41a75c7a42f02c_Out_1, 1.0)), (float4(_Normalize_138139e3277b4fae8c902af48021c27b_Out_1, 1.0)), (float4(_Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1, 1.0)), float4 (0, 0, 0, 0), _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var4x4_4, _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var3x3_5, _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var2x2_6);
            UnityTexture2D _Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0 = UnityBuildTexture2DStructNoScale(_Side1Normal);
            float _Split_8a8287079f9a494382d5e21ff928e867_R_1 = IN.WorldSpacePosition[0];
            float _Split_8a8287079f9a494382d5e21ff928e867_G_2 = IN.WorldSpacePosition[1];
            float _Split_8a8287079f9a494382d5e21ff928e867_B_3 = IN.WorldSpacePosition[2];
            float _Split_8a8287079f9a494382d5e21ff928e867_A_4 = 0;
            float2 _Vector2_422303a2e182451483c76a2df62d8fbd_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_B_3, _Split_8a8287079f9a494382d5e21ff928e867_G_2);
            float2 _Property_fea94bc210a942a7b8f5e99b572205f2_Out_0 = _SideTiling;
            float2 _TilingAndOffset_f489eaa422e74c34b25248e65cb10f5c_Out_3;
            Unity_TilingAndOffset_float(_Vector2_422303a2e182451483c76a2df62d8fbd_Out_0, _Property_fea94bc210a942a7b8f5e99b572205f2_Out_0, float2 (0, 0), _TilingAndOffset_f489eaa422e74c34b25248e65cb10f5c_Out_3);
            float4 _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0.tex, _Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0.samplerstate, _Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0.GetTransformedUV(_TilingAndOffset_f489eaa422e74c34b25248e65cb10f5c_Out_3));
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_R_4 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.r;
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_G_5 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.g;
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_B_6 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.b;
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_A_7 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.a;
            float _Property_06bb67e1d14d4c7abb3826e91fe5d824_Out_0 = _SideNormalStrength;
            float3 _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.xyz), _Property_06bb67e1d14d4c7abb3826e91fe5d824_Out_0, _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2);
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_R_1 = _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2[0];
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_G_2 = _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2[1];
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_B_3 = _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2[2];
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_A_4 = 0;
            float _Absolute_81d9831799b840b9a1d2b4c566a1622a_Out_1;
            Unity_Absolute_float(_Split_27883ef8495d4e078f3c6ec5be5b3ac3_B_3, _Absolute_81d9831799b840b9a1d2b4c566a1622a_Out_1);
            float _Split_66b91a799fa249599b2cf7d52c20ceae_R_1 = _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1[0];
            float _Split_66b91a799fa249599b2cf7d52c20ceae_G_2 = _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1[1];
            float _Split_66b91a799fa249599b2cf7d52c20ceae_B_3 = _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1[2];
            float _Split_66b91a799fa249599b2cf7d52c20ceae_A_4 = 0;
            float _Multiply_cba9440999d14f09b0349ed5a9d0bb74_Out_2;
            Unity_Multiply_float_float(_Absolute_81d9831799b840b9a1d2b4c566a1622a_Out_1, _Split_66b91a799fa249599b2cf7d52c20ceae_R_1, _Multiply_cba9440999d14f09b0349ed5a9d0bb74_Out_2);
            float4 _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGBA_4;
            float3 _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGB_5;
            float2 _Combine_f3158e4900b649a79aa67d1e219ea4bd_RG_6;
            Unity_Combine_float(_Split_27883ef8495d4e078f3c6ec5be5b3ac3_R_1, _Split_27883ef8495d4e078f3c6ec5be5b3ac3_G_2, 0, 0, _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGBA_4, _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGB_5, _Combine_f3158e4900b649a79aa67d1e219ea4bd_RG_6);
            float4 _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGBA_4;
            float3 _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGB_5;
            float2 _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RG_6;
            Unity_Combine_float(_Split_66b91a799fa249599b2cf7d52c20ceae_B_3, _Split_66b91a799fa249599b2cf7d52c20ceae_G_2, 0, 0, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGBA_4, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGB_5, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RG_6);
            float2 _Add_45086c33520b40bf98a4b4e639013aaa_Out_2;
            Unity_Add_float2(_Combine_f3158e4900b649a79aa67d1e219ea4bd_RG_6, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RG_6, _Add_45086c33520b40bf98a4b4e639013aaa_Out_2);
            float _Split_01fe340496a6496594e1dbcd836efe88_R_1 = _Add_45086c33520b40bf98a4b4e639013aaa_Out_2[0];
            float _Split_01fe340496a6496594e1dbcd836efe88_G_2 = _Add_45086c33520b40bf98a4b4e639013aaa_Out_2[1];
            float _Split_01fe340496a6496594e1dbcd836efe88_B_3 = 0;
            float _Split_01fe340496a6496594e1dbcd836efe88_A_4 = 0;
            float4 _Combine_d41777d14eac458d8432b72821aa860a_RGBA_4;
            float3 _Combine_d41777d14eac458d8432b72821aa860a_RGB_5;
            float2 _Combine_d41777d14eac458d8432b72821aa860a_RG_6;
            Unity_Combine_float(_Multiply_cba9440999d14f09b0349ed5a9d0bb74_Out_2, _Split_01fe340496a6496594e1dbcd836efe88_G_2, _Split_01fe340496a6496594e1dbcd836efe88_R_1, 0, _Combine_d41777d14eac458d8432b72821aa860a_RGBA_4, _Combine_d41777d14eac458d8432b72821aa860a_RGB_5, _Combine_d41777d14eac458d8432b72821aa860a_RG_6);
            float3 _Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1;
            Unity_Absolute_float3(_Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1, _Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1);
            float _Property_c199e3a40a374c27bc4f877aa0779f26_Out_0 = _Blend;
            float3 _Power_63f769573a36444489ea06f547e82f34_Out_2;
            Unity_Power_float3(_Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1, (_Property_c199e3a40a374c27bc4f877aa0779f26_Out_0.xxx), _Power_63f769573a36444489ea06f547e82f34_Out_2);
            float _Property_95e8e8c764df42cd849f5794c47de952_Out_0 = _TopBlend;
            float3 _Vector3_a22857b561994fd0b4fd09b1d80be6b2_Out_0 = float3(1, _Property_95e8e8c764df42cd849f5794c47de952_Out_0, 1);
            float3 _Multiply_901287298f374f398f61deb90e01229f_Out_2;
            Unity_Multiply_float3_float3(_Power_63f769573a36444489ea06f547e82f34_Out_2, _Vector3_a22857b561994fd0b4fd09b1d80be6b2_Out_0, _Multiply_901287298f374f398f61deb90e01229f_Out_2);
            float3 _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2;
            Unity_Maximum_float3(_Multiply_901287298f374f398f61deb90e01229f_Out_2, float3(0, 0, 0), _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2);
            float _Split_3bac21d320964dbca8d9094760c87a24_R_1 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[0];
            float _Split_3bac21d320964dbca8d9094760c87a24_G_2 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[1];
            float _Split_3bac21d320964dbca8d9094760c87a24_B_3 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[2];
            float _Split_3bac21d320964dbca8d9094760c87a24_A_4 = 0;
            float _Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2;
            Unity_Add_float(_Split_3bac21d320964dbca8d9094760c87a24_R_1, _Split_3bac21d320964dbca8d9094760c87a24_G_2, _Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2);
            float _Add_188219e788de45eba666bba49521d656_Out_2;
            Unity_Add_float(_Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2, _Split_3bac21d320964dbca8d9094760c87a24_B_3, _Add_188219e788de45eba666bba49521d656_Out_2);
            float3 _Divide_8aad109457564563994d4710b7e4648a_Out_2;
            Unity_Divide_float3(_Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2, (_Add_188219e788de45eba666bba49521d656_Out_2.xxx), _Divide_8aad109457564563994d4710b7e4648a_Out_2);
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[0];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[1];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[2];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_A_4 = 0;
            float3 _Multiply_25315676ebb14ebf82037668ac8e32b4_Out_2;
            Unity_Multiply_float3_float3(_Combine_d41777d14eac458d8432b72821aa860a_RGB_5, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1.xxx), _Multiply_25315676ebb14ebf82037668ac8e32b4_Out_2);
            UnityTexture2D _Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0 = UnityBuildTexture2DStructNoScale(_TopNormal);
            float2 _Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_R_1, _Split_8a8287079f9a494382d5e21ff928e867_B_3);
            float2 _Property_c6841a14d6bf45d9bd1e07ea6f72d965_Out_0 = _TopTiling;
            float2 _TilingAndOffset_6e910a893a3a42719219523be1ad6c27_Out_3;
            Unity_TilingAndOffset_float(_Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0, _Property_c6841a14d6bf45d9bd1e07ea6f72d965_Out_0, float2 (0, 0), _TilingAndOffset_6e910a893a3a42719219523be1ad6c27_Out_3);
            float4 _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0 = SAMPLE_TEXTURE2D(_Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0.tex, _Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0.samplerstate, _Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0.GetTransformedUV(_TilingAndOffset_6e910a893a3a42719219523be1ad6c27_Out_3));
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_R_4 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.r;
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_G_5 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.g;
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_B_6 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.b;
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_A_7 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.a;
            float _Property_af07a77e53ef41f499e3970c74406ca7_Out_0 = _TopNormalStrength;
            float3 _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.xyz), _Property_af07a77e53ef41f499e3970c74406ca7_Out_0, _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2);
            float _Split_fbb97fbe21d8477d923efa93f57b1517_R_1 = _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2[0];
            float _Split_fbb97fbe21d8477d923efa93f57b1517_G_2 = _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2[1];
            float _Split_fbb97fbe21d8477d923efa93f57b1517_B_3 = _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2[2];
            float _Split_fbb97fbe21d8477d923efa93f57b1517_A_4 = 0;
            float4 _Combine_50f1cb9c657b489387ee416f1f77022a_RGBA_4;
            float3 _Combine_50f1cb9c657b489387ee416f1f77022a_RGB_5;
            float2 _Combine_50f1cb9c657b489387ee416f1f77022a_RG_6;
            Unity_Combine_float(_Split_fbb97fbe21d8477d923efa93f57b1517_R_1, _Split_fbb97fbe21d8477d923efa93f57b1517_G_2, 0, 0, _Combine_50f1cb9c657b489387ee416f1f77022a_RGBA_4, _Combine_50f1cb9c657b489387ee416f1f77022a_RGB_5, _Combine_50f1cb9c657b489387ee416f1f77022a_RG_6);
            float4 _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGBA_4;
            float3 _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGB_5;
            float2 _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RG_6;
            Unity_Combine_float(_Split_66b91a799fa249599b2cf7d52c20ceae_R_1, _Split_66b91a799fa249599b2cf7d52c20ceae_B_3, 0, 0, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGBA_4, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGB_5, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RG_6);
            float2 _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2;
            Unity_Add_float2(_Combine_50f1cb9c657b489387ee416f1f77022a_RG_6, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RG_6, _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2);
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_R_1 = _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2[0];
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_G_2 = _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2[1];
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_B_3 = 0;
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_A_4 = 0;
            float _Absolute_30a05240f6ed469ba0629dbec0af13f3_Out_1;
            Unity_Absolute_float(_Split_fbb97fbe21d8477d923efa93f57b1517_B_3, _Absolute_30a05240f6ed469ba0629dbec0af13f3_Out_1);
            float _Multiply_7ca96e1a618246f1b490d564baa2e44e_Out_2;
            Unity_Multiply_float_float(_Absolute_30a05240f6ed469ba0629dbec0af13f3_Out_1, _Split_66b91a799fa249599b2cf7d52c20ceae_G_2, _Multiply_7ca96e1a618246f1b490d564baa2e44e_Out_2);
            float4 _Combine_3397125918044e3d9e6e8897e6491ee8_RGBA_4;
            float3 _Combine_3397125918044e3d9e6e8897e6491ee8_RGB_5;
            float2 _Combine_3397125918044e3d9e6e8897e6491ee8_RG_6;
            Unity_Combine_float(_Split_d6e96aca1dcf4a6fa101dc65f44e8e91_R_1, _Multiply_7ca96e1a618246f1b490d564baa2e44e_Out_2, _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_G_2, 0, _Combine_3397125918044e3d9e6e8897e6491ee8_RGBA_4, _Combine_3397125918044e3d9e6e8897e6491ee8_RGB_5, _Combine_3397125918044e3d9e6e8897e6491ee8_RG_6);
            float3 _Multiply_e1d8696c71864d4e928f9d8ae5eae9b4_Out_2;
            Unity_Multiply_float3_float3(_Combine_3397125918044e3d9e6e8897e6491ee8_RGB_5, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2.xxx), _Multiply_e1d8696c71864d4e928f9d8ae5eae9b4_Out_2);
            float3 _Add_be41a1e3b7ab4933be449cce5b94e43b_Out_2;
            Unity_Add_float3(_Multiply_25315676ebb14ebf82037668ac8e32b4_Out_2, _Multiply_e1d8696c71864d4e928f9d8ae5eae9b4_Out_2, _Add_be41a1e3b7ab4933be449cce5b94e43b_Out_2);
            UnityTexture2D _Property_bbc64da39f6544c288772c846dba1d98_Out_0 = UnityBuildTexture2DStructNoScale(_Side2Normal);
            float2 _Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_R_1, _Split_8a8287079f9a494382d5e21ff928e867_G_2);
            float2 _Property_e2c8ed57e8324498ba6690540c4b01ce_Out_0 = _SideTiling;
            float2 _TilingAndOffset_56b93257dea843cea4cc025009828652_Out_3;
            Unity_TilingAndOffset_float(_Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0, _Property_e2c8ed57e8324498ba6690540c4b01ce_Out_0, float2 (0, 0), _TilingAndOffset_56b93257dea843cea4cc025009828652_Out_3);
            float4 _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0 = SAMPLE_TEXTURE2D(_Property_bbc64da39f6544c288772c846dba1d98_Out_0.tex, _Property_bbc64da39f6544c288772c846dba1d98_Out_0.samplerstate, _Property_bbc64da39f6544c288772c846dba1d98_Out_0.GetTransformedUV(_TilingAndOffset_56b93257dea843cea4cc025009828652_Out_3));
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_R_4 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.r;
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_G_5 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.g;
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_B_6 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.b;
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_A_7 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.a;
            float _Property_34a5f85b6edf4acdad9f5e7f593ef446_Out_0 = _SideNormalStrength;
            float3 _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.xyz), _Property_34a5f85b6edf4acdad9f5e7f593ef446_Out_0, _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2);
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_R_1 = _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2[0];
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_G_2 = _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2[1];
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_B_3 = _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2[2];
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_A_4 = 0;
            float4 _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGBA_4;
            float3 _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGB_5;
            float2 _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RG_6;
            Unity_Combine_float(_Split_e9c2ff6ae8cb459492cfa8a97b4dd778_R_1, _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_G_2, 0, 0, _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGBA_4, _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGB_5, _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RG_6);
            float4 _Combine_77995c8f08c6490681323ba57c634868_RGBA_4;
            float3 _Combine_77995c8f08c6490681323ba57c634868_RGB_5;
            float2 _Combine_77995c8f08c6490681323ba57c634868_RG_6;
            Unity_Combine_float(_Split_66b91a799fa249599b2cf7d52c20ceae_R_1, _Split_66b91a799fa249599b2cf7d52c20ceae_G_2, 0, 0, _Combine_77995c8f08c6490681323ba57c634868_RGBA_4, _Combine_77995c8f08c6490681323ba57c634868_RGB_5, _Combine_77995c8f08c6490681323ba57c634868_RG_6);
            float2 _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2;
            Unity_Add_float2(_Combine_707341f8f2d94e1d82a3f1431a8f8c52_RG_6, _Combine_77995c8f08c6490681323ba57c634868_RG_6, _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2);
            float _Split_f649548941034bbabc90d4e027faf0f0_R_1 = _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2[0];
            float _Split_f649548941034bbabc90d4e027faf0f0_G_2 = _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2[1];
            float _Split_f649548941034bbabc90d4e027faf0f0_B_3 = 0;
            float _Split_f649548941034bbabc90d4e027faf0f0_A_4 = 0;
            float _Absolute_b8f8f975d97c46b7917fe882f3e0568e_Out_1;
            Unity_Absolute_float(_Split_e9c2ff6ae8cb459492cfa8a97b4dd778_B_3, _Absolute_b8f8f975d97c46b7917fe882f3e0568e_Out_1);
            float _Multiply_eb22109da7ee4bde9c64e86cdcb3f703_Out_2;
            Unity_Multiply_float_float(_Absolute_b8f8f975d97c46b7917fe882f3e0568e_Out_1, _Split_66b91a799fa249599b2cf7d52c20ceae_B_3, _Multiply_eb22109da7ee4bde9c64e86cdcb3f703_Out_2);
            float4 _Combine_f18458f1fbea4cafb126653f3c712144_RGBA_4;
            float3 _Combine_f18458f1fbea4cafb126653f3c712144_RGB_5;
            float2 _Combine_f18458f1fbea4cafb126653f3c712144_RG_6;
            Unity_Combine_float(_Split_f649548941034bbabc90d4e027faf0f0_R_1, _Split_f649548941034bbabc90d4e027faf0f0_G_2, _Multiply_eb22109da7ee4bde9c64e86cdcb3f703_Out_2, 0, _Combine_f18458f1fbea4cafb126653f3c712144_RGBA_4, _Combine_f18458f1fbea4cafb126653f3c712144_RGB_5, _Combine_f18458f1fbea4cafb126653f3c712144_RG_6);
            float3 _Multiply_f8671ad3faa54908abf30d5064d2b9ad_Out_2;
            Unity_Multiply_float3_float3(_Combine_f18458f1fbea4cafb126653f3c712144_RGB_5, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3.xxx), _Multiply_f8671ad3faa54908abf30d5064d2b9ad_Out_2);
            float3 _Add_5120cf7e02884188ab7e3ff15353fec9_Out_2;
            Unity_Add_float3(_Add_be41a1e3b7ab4933be449cce5b94e43b_Out_2, _Multiply_f8671ad3faa54908abf30d5064d2b9ad_Out_2, _Add_5120cf7e02884188ab7e3ff15353fec9_Out_2);
            float3 _Multiply_b8253329450045f6993d3c52a44be133_Out_2;
            Unity_Multiply_float3x3_float3(_MatrixConstruction_1497565cfa514012949cd6aca03566ee_var3x3_5, _Add_5120cf7e02884188ab7e3ff15353fec9_Out_2, _Multiply_b8253329450045f6993d3c52a44be133_Out_2);
            float3 _Normalize_8ba6483360404f6a986179ff26c09eac_Out_1;
            Unity_Normalize_float3(_Multiply_b8253329450045f6993d3c52a44be133_Out_2, _Normalize_8ba6483360404f6a986179ff26c09eac_Out_1);
            surface.NormalTS = _Normalize_8ba6483360404f6a986179ff26c09eac_Out_1;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
            // use bitangent on the fly like in hdrp
            // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0)* GetOddNegativeScale();
            float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
            // to pr               eserve mikktspace compliance we use same scale renormFactor as was used on the normal.
            // This                is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent = renormFactor * input.tangentWS.xyz;
            output.WorldSpaceBiTangent = renormFactor * bitang;
        
            output.WorldSpacePosition = input.positionWS;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "DepthNormalsOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }
        
        // Render State
        Cull Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature _ EDITOR_VISUALIZATION
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_TEXCOORD1
        #define VARYINGS_NEED_TEXCOORD2
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_META
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "ShaderStructures.hlsl"
        uniform StructuredBuffer<Triangle> triangleBuffer;
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             uint id : SV_VertexID;
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 texCoord0;
             float4 texCoord1;
             float4 texCoord2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 WorldSpacePosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float4 interp3 : INTERP3;
             float4 interp4 : INTERP4;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.texCoord0;
            output.interp3.xyzw =  input.texCoord1;
            output.interp4.xyzw =  input.texCoord2;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.texCoord0 = input.interp2.xyzw;
            output.texCoord1 = input.interp3.xyzw;
            output.texCoord2 = input.interp4.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Top_TexelSize;
        float4 _Side1_TexelSize;
        float4 _Side2_TexelSize;
        float _Smoothness;
        float4 _TopNormal_TexelSize;
        float4 _Side1Normal_TexelSize;
        float4 _Side2Normal_TexelSize;
        float4 _TopBlendColor;
        float _TopBlendStrength;
        float2 _TopTiling;
        float2 _SideTiling;
        float _TopNormalStrength;
        float _SideNormalStrength;
        float _Blend;
        float _TopBlend;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Top);
        SAMPLER(sampler_Top);
        TEXTURE2D(_Side1);
        SAMPLER(sampler_Side1);
        TEXTURE2D(_Side2);
        SAMPLER(sampler_Side2);
        TEXTURE2D(_TopNormal);
        SAMPLER(sampler_TopNormal);
        TEXTURE2D(_Side1Normal);
        SAMPLER(sampler_Side1Normal);
        TEXTURE2D(_Side2Normal);
        SAMPLER(sampler_Side2Normal);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }
        
        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }
        
        void Unity_Power_float3(float3 A, float3 B, out float3 Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Blend_Overlay_float4(float4 Base, float4 Blend, out float4 Out, float Opacity)
        {
            float4 result1 = 1.0 - 2.0 * (1.0 - Base) * (1.0 - Blend);
            float4 result2 = 2.0 * Base * Blend;
            float4 zeroOrOne = step(Base, 0.5);
            Out = result2 * zeroOrOne + (1 - zeroOrOne) * result1;
            Out = lerp(Base, Out, Opacity);
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 Emission;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0 = UnityBuildTexture2DStructNoScale(_Side1);
            float _Split_8a8287079f9a494382d5e21ff928e867_R_1 = IN.WorldSpacePosition[0];
            float _Split_8a8287079f9a494382d5e21ff928e867_G_2 = IN.WorldSpacePosition[1];
            float _Split_8a8287079f9a494382d5e21ff928e867_B_3 = IN.WorldSpacePosition[2];
            float _Split_8a8287079f9a494382d5e21ff928e867_A_4 = 0;
            float2 _Vector2_422303a2e182451483c76a2df62d8fbd_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_B_3, _Split_8a8287079f9a494382d5e21ff928e867_G_2);
            float2 _Property_f5515325ca8e44f0b693681c1553b814_Out_0 = _SideTiling;
            float2 _TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3;
            Unity_TilingAndOffset_float(_Vector2_422303a2e182451483c76a2df62d8fbd_Out_0, _Property_f5515325ca8e44f0b693681c1553b814_Out_0, float2 (0, 0), _TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3);
            float4 _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0 = SAMPLE_TEXTURE2D(_Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.tex, _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.samplerstate, _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.GetTransformedUV(_TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3));
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_R_4 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.r;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_G_5 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.g;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_B_6 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.b;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_A_7 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.a;
            float3 _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceNormal, _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1);
            float3 _Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1;
            Unity_Absolute_float3(_Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1, _Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1);
            float _Property_c199e3a40a374c27bc4f877aa0779f26_Out_0 = _Blend;
            float3 _Power_63f769573a36444489ea06f547e82f34_Out_2;
            Unity_Power_float3(_Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1, (_Property_c199e3a40a374c27bc4f877aa0779f26_Out_0.xxx), _Power_63f769573a36444489ea06f547e82f34_Out_2);
            float _Property_95e8e8c764df42cd849f5794c47de952_Out_0 = _TopBlend;
            float3 _Vector3_a22857b561994fd0b4fd09b1d80be6b2_Out_0 = float3(1, _Property_95e8e8c764df42cd849f5794c47de952_Out_0, 1);
            float3 _Multiply_901287298f374f398f61deb90e01229f_Out_2;
            Unity_Multiply_float3_float3(_Power_63f769573a36444489ea06f547e82f34_Out_2, _Vector3_a22857b561994fd0b4fd09b1d80be6b2_Out_0, _Multiply_901287298f374f398f61deb90e01229f_Out_2);
            float3 _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2;
            Unity_Maximum_float3(_Multiply_901287298f374f398f61deb90e01229f_Out_2, float3(0, 0, 0), _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2);
            float _Split_3bac21d320964dbca8d9094760c87a24_R_1 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[0];
            float _Split_3bac21d320964dbca8d9094760c87a24_G_2 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[1];
            float _Split_3bac21d320964dbca8d9094760c87a24_B_3 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[2];
            float _Split_3bac21d320964dbca8d9094760c87a24_A_4 = 0;
            float _Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2;
            Unity_Add_float(_Split_3bac21d320964dbca8d9094760c87a24_R_1, _Split_3bac21d320964dbca8d9094760c87a24_G_2, _Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2);
            float _Add_188219e788de45eba666bba49521d656_Out_2;
            Unity_Add_float(_Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2, _Split_3bac21d320964dbca8d9094760c87a24_B_3, _Add_188219e788de45eba666bba49521d656_Out_2);
            float3 _Divide_8aad109457564563994d4710b7e4648a_Out_2;
            Unity_Divide_float3(_Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2, (_Add_188219e788de45eba666bba49521d656_Out_2.xxx), _Divide_8aad109457564563994d4710b7e4648a_Out_2);
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[0];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[1];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[2];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_A_4 = 0;
            float4 _Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2;
            Unity_Multiply_float4_float4(_SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1.xxxx), _Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2);
            UnityTexture2D _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0 = UnityBuildTexture2DStructNoScale(_Top);
            float2 _Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_R_1, _Split_8a8287079f9a494382d5e21ff928e867_B_3);
            float2 _Property_556bde57ae654fa1a27d1f931f71f69d_Out_0 = _TopTiling;
            float2 _TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3;
            Unity_TilingAndOffset_float(_Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0, _Property_556bde57ae654fa1a27d1f931f71f69d_Out_0, float2 (0, 0), _TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3);
            float4 _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0 = SAMPLE_TEXTURE2D(_Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.tex, _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.samplerstate, _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.GetTransformedUV(_TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3));
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_R_4 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.r;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_G_5 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.g;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_B_6 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.b;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_A_7 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.a;
            float4 _Property_b80b6d14d20d46dfa59788b8390c12d8_Out_0 = _TopBlendColor;
            float _Property_bfc90837b07349408e8f8761a44b1114_Out_0 = _TopBlendStrength;
            float4 _Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2;
            Unity_Blend_Overlay_float4(_SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0, _Property_b80b6d14d20d46dfa59788b8390c12d8_Out_0, _Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2, _Property_bfc90837b07349408e8f8761a44b1114_Out_0);
            float4 _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2;
            Unity_Multiply_float4_float4(_Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2.xxxx), _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2);
            float4 _Add_218795fc166a426aa361c539f291e0b1_Out_2;
            Unity_Add_float4(_Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2, _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2, _Add_218795fc166a426aa361c539f291e0b1_Out_2);
            UnityTexture2D _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0 = UnityBuildTexture2DStructNoScale(_Side2);
            float2 _Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_R_1, _Split_8a8287079f9a494382d5e21ff928e867_G_2);
            float2 _Property_d2d6aa174ccc4fc98d6a72e79a21ea63_Out_0 = _SideTiling;
            float2 _TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3;
            Unity_TilingAndOffset_float(_Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0, _Property_d2d6aa174ccc4fc98d6a72e79a21ea63_Out_0, float2 (0, 0), _TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3);
            float4 _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.tex, _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.samplerstate, _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.GetTransformedUV(_TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3));
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_R_4 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.r;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_G_5 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.g;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_B_6 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.b;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_A_7 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.a;
            float4 _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2;
            Unity_Multiply_float4_float4(_SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3.xxxx), _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2);
            float4 _Add_933e680106a64ad8b90f42fd329b74f6_Out_2;
            Unity_Add_float4(_Add_218795fc166a426aa361c539f291e0b1_Out_2, _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2, _Add_933e680106a64ad8b90f42fd329b74f6_Out_2);
            surface.BaseColor = (_Add_933e680106a64ad8b90f42fd329b74f6_Out_2.xyz);
            surface.Emission = float3(0, 0, 0);
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
        
        
            output.WorldSpacePosition = input.positionWS;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "LightingMetaPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "SceneSelectionPass"
            Tags
            {
                "LightMode" = "SceneSelectionPass"
            }
        
        // Render State
        Cull Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENESELECTIONPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "ShaderStructures.hlsl"
        uniform StructuredBuffer<Triangle> triangleBuffer;
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             uint id : SV_VertexID;
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Top_TexelSize;
        float4 _Side1_TexelSize;
        float4 _Side2_TexelSize;
        float _Smoothness;
        float4 _TopNormal_TexelSize;
        float4 _Side1Normal_TexelSize;
        float4 _Side2Normal_TexelSize;
        float4 _TopBlendColor;
        float _TopBlendStrength;
        float2 _TopTiling;
        float2 _SideTiling;
        float _TopNormalStrength;
        float _SideNormalStrength;
        float _Blend;
        float _TopBlend;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Top);
        SAMPLER(sampler_Top);
        TEXTURE2D(_Side1);
        SAMPLER(sampler_Side1);
        TEXTURE2D(_Side2);
        SAMPLER(sampler_Side2);
        TEXTURE2D(_TopNormal);
        SAMPLER(sampler_TopNormal);
        TEXTURE2D(_Side1Normal);
        SAMPLER(sampler_Side1Normal);
        TEXTURE2D(_Side2Normal);
        SAMPLER(sampler_Side2Normal);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        // GraphFunctions: <None>
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ScenePickingPass"
            Tags
            {
                "LightMode" = "Picking"
            }
        
        // Render State
        Cull Back
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENEPICKINGPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "ShaderStructures.hlsl"
        uniform StructuredBuffer<Triangle> triangleBuffer;
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             uint id : SV_VertexID;
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Top_TexelSize;
        float4 _Side1_TexelSize;
        float4 _Side2_TexelSize;
        float _Smoothness;
        float4 _TopNormal_TexelSize;
        float4 _Side1Normal_TexelSize;
        float4 _Side2Normal_TexelSize;
        float4 _TopBlendColor;
        float _TopBlendStrength;
        float2 _TopTiling;
        float2 _SideTiling;
        float _TopNormalStrength;
        float _SideNormalStrength;
        float _Blend;
        float _TopBlend;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Top);
        SAMPLER(sampler_Top);
        TEXTURE2D(_Side1);
        SAMPLER(sampler_Side1);
        TEXTURE2D(_Side2);
        SAMPLER(sampler_Side2);
        TEXTURE2D(_TopNormal);
        SAMPLER(sampler_TopNormal);
        TEXTURE2D(_Side1Normal);
        SAMPLER(sampler_Side1Normal);
        TEXTURE2D(_Side2Normal);
        SAMPLER(sampler_Side2Normal);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        // GraphFunctions: <None>
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            // Name: <None>
            Tags
            {
                "LightMode" = "Universal2D"
            }
        
        // Render State
        Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_2D
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "ShaderStructures.hlsl"
        uniform StructuredBuffer<Triangle> triangleBuffer;
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             uint id : SV_VertexID;
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 WorldSpacePosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Top_TexelSize;
        float4 _Side1_TexelSize;
        float4 _Side2_TexelSize;
        float _Smoothness;
        float4 _TopNormal_TexelSize;
        float4 _Side1Normal_TexelSize;
        float4 _Side2Normal_TexelSize;
        float4 _TopBlendColor;
        float _TopBlendStrength;
        float2 _TopTiling;
        float2 _SideTiling;
        float _TopNormalStrength;
        float _SideNormalStrength;
        float _Blend;
        float _TopBlend;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Top);
        SAMPLER(sampler_Top);
        TEXTURE2D(_Side1);
        SAMPLER(sampler_Side1);
        TEXTURE2D(_Side2);
        SAMPLER(sampler_Side2);
        TEXTURE2D(_TopNormal);
        SAMPLER(sampler_TopNormal);
        TEXTURE2D(_Side1Normal);
        SAMPLER(sampler_Side1Normal);
        TEXTURE2D(_Side2Normal);
        SAMPLER(sampler_Side2Normal);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }
        
        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }
        
        void Unity_Power_float3(float3 A, float3 B, out float3 Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Blend_Overlay_float4(float4 Base, float4 Blend, out float4 Out, float Opacity)
        {
            float4 result1 = 1.0 - 2.0 * (1.0 - Base) * (1.0 - Blend);
            float4 result2 = 2.0 * Base * Blend;
            float4 zeroOrOne = step(Base, 0.5);
            Out = result2 * zeroOrOne + (1 - zeroOrOne) * result1;
            Out = lerp(Base, Out, Opacity);
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0 = UnityBuildTexture2DStructNoScale(_Side1);
            float _Split_8a8287079f9a494382d5e21ff928e867_R_1 = IN.WorldSpacePosition[0];
            float _Split_8a8287079f9a494382d5e21ff928e867_G_2 = IN.WorldSpacePosition[1];
            float _Split_8a8287079f9a494382d5e21ff928e867_B_3 = IN.WorldSpacePosition[2];
            float _Split_8a8287079f9a494382d5e21ff928e867_A_4 = 0;
            float2 _Vector2_422303a2e182451483c76a2df62d8fbd_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_B_3, _Split_8a8287079f9a494382d5e21ff928e867_G_2);
            float2 _Property_f5515325ca8e44f0b693681c1553b814_Out_0 = _SideTiling;
            float2 _TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3;
            Unity_TilingAndOffset_float(_Vector2_422303a2e182451483c76a2df62d8fbd_Out_0, _Property_f5515325ca8e44f0b693681c1553b814_Out_0, float2 (0, 0), _TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3);
            float4 _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0 = SAMPLE_TEXTURE2D(_Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.tex, _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.samplerstate, _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.GetTransformedUV(_TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3));
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_R_4 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.r;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_G_5 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.g;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_B_6 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.b;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_A_7 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.a;
            float3 _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceNormal, _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1);
            float3 _Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1;
            Unity_Absolute_float3(_Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1, _Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1);
            float _Property_c199e3a40a374c27bc4f877aa0779f26_Out_0 = _Blend;
            float3 _Power_63f769573a36444489ea06f547e82f34_Out_2;
            Unity_Power_float3(_Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1, (_Property_c199e3a40a374c27bc4f877aa0779f26_Out_0.xxx), _Power_63f769573a36444489ea06f547e82f34_Out_2);
            float _Property_95e8e8c764df42cd849f5794c47de952_Out_0 = _TopBlend;
            float3 _Vector3_a22857b561994fd0b4fd09b1d80be6b2_Out_0 = float3(1, _Property_95e8e8c764df42cd849f5794c47de952_Out_0, 1);
            float3 _Multiply_901287298f374f398f61deb90e01229f_Out_2;
            Unity_Multiply_float3_float3(_Power_63f769573a36444489ea06f547e82f34_Out_2, _Vector3_a22857b561994fd0b4fd09b1d80be6b2_Out_0, _Multiply_901287298f374f398f61deb90e01229f_Out_2);
            float3 _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2;
            Unity_Maximum_float3(_Multiply_901287298f374f398f61deb90e01229f_Out_2, float3(0, 0, 0), _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2);
            float _Split_3bac21d320964dbca8d9094760c87a24_R_1 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[0];
            float _Split_3bac21d320964dbca8d9094760c87a24_G_2 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[1];
            float _Split_3bac21d320964dbca8d9094760c87a24_B_3 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[2];
            float _Split_3bac21d320964dbca8d9094760c87a24_A_4 = 0;
            float _Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2;
            Unity_Add_float(_Split_3bac21d320964dbca8d9094760c87a24_R_1, _Split_3bac21d320964dbca8d9094760c87a24_G_2, _Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2);
            float _Add_188219e788de45eba666bba49521d656_Out_2;
            Unity_Add_float(_Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2, _Split_3bac21d320964dbca8d9094760c87a24_B_3, _Add_188219e788de45eba666bba49521d656_Out_2);
            float3 _Divide_8aad109457564563994d4710b7e4648a_Out_2;
            Unity_Divide_float3(_Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2, (_Add_188219e788de45eba666bba49521d656_Out_2.xxx), _Divide_8aad109457564563994d4710b7e4648a_Out_2);
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[0];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[1];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[2];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_A_4 = 0;
            float4 _Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2;
            Unity_Multiply_float4_float4(_SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1.xxxx), _Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2);
            UnityTexture2D _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0 = UnityBuildTexture2DStructNoScale(_Top);
            float2 _Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_R_1, _Split_8a8287079f9a494382d5e21ff928e867_B_3);
            float2 _Property_556bde57ae654fa1a27d1f931f71f69d_Out_0 = _TopTiling;
            float2 _TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3;
            Unity_TilingAndOffset_float(_Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0, _Property_556bde57ae654fa1a27d1f931f71f69d_Out_0, float2 (0, 0), _TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3);
            float4 _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0 = SAMPLE_TEXTURE2D(_Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.tex, _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.samplerstate, _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.GetTransformedUV(_TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3));
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_R_4 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.r;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_G_5 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.g;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_B_6 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.b;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_A_7 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.a;
            float4 _Property_b80b6d14d20d46dfa59788b8390c12d8_Out_0 = _TopBlendColor;
            float _Property_bfc90837b07349408e8f8761a44b1114_Out_0 = _TopBlendStrength;
            float4 _Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2;
            Unity_Blend_Overlay_float4(_SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0, _Property_b80b6d14d20d46dfa59788b8390c12d8_Out_0, _Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2, _Property_bfc90837b07349408e8f8761a44b1114_Out_0);
            float4 _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2;
            Unity_Multiply_float4_float4(_Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2.xxxx), _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2);
            float4 _Add_218795fc166a426aa361c539f291e0b1_Out_2;
            Unity_Add_float4(_Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2, _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2, _Add_218795fc166a426aa361c539f291e0b1_Out_2);
            UnityTexture2D _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0 = UnityBuildTexture2DStructNoScale(_Side2);
            float2 _Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_R_1, _Split_8a8287079f9a494382d5e21ff928e867_G_2);
            float2 _Property_d2d6aa174ccc4fc98d6a72e79a21ea63_Out_0 = _SideTiling;
            float2 _TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3;
            Unity_TilingAndOffset_float(_Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0, _Property_d2d6aa174ccc4fc98d6a72e79a21ea63_Out_0, float2 (0, 0), _TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3);
            float4 _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.tex, _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.samplerstate, _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.GetTransformedUV(_TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3));
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_R_4 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.r;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_G_5 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.g;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_B_6 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.b;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_A_7 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.a;
            float4 _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2;
            Unity_Multiply_float4_float4(_SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3.xxxx), _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2);
            float4 _Add_933e680106a64ad8b90f42fd329b74f6_Out_2;
            Unity_Add_float4(_Add_218795fc166a426aa361c539f291e0b1_Out_2, _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2, _Add_933e680106a64ad8b90f42fd329b74f6_Out_2);
            surface.BaseColor = (_Add_933e680106a64ad8b90f42fd329b74f6_Out_2.xyz);
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
        
        
            output.WorldSpacePosition = input.positionWS;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "PBR2DPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "UniversalMaterialType" = "Lit"
            "Queue"="Geometry"
            "ShaderGraphShader"="true"
            "ShaderGraphTargetId"="UniversalLitSubTarget"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
        
        // Render State
        Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DYNAMICLIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
        #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
        #pragma multi_compile_fragment _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        #pragma multi_compile_fragment _ _LIGHT_LAYERS
        #pragma multi_compile_fragment _ DEBUG_DISPLAY
        #pragma multi_compile_fragment _ _LIGHT_COOKIES
        #pragma multi_compile _ _CLUSTERED_RENDERING
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define VARYINGS_NEED_SHADOW_COORD
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_FORWARD
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "ShaderStructures.hlsl"
        uniform StructuredBuffer<Triangle> triangleBuffer;
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             uint id : SV_VertexID;
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
             float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
             float2 staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
             float2 dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
             float3 sh;
            #endif
             float4 fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
             float4 shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 TangentSpaceNormal;
             float3 WorldSpaceTangent;
             float3 WorldSpaceBiTangent;
             float3 WorldSpacePosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float3 interp3 : INTERP3;
             float2 interp4 : INTERP4;
             float2 interp5 : INTERP5;
             float3 interp6 : INTERP6;
             float4 interp7 : INTERP7;
             float4 interp8 : INTERP8;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.interp5.xy =  input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp6.xyz =  input.sh;
            #endif
            output.interp7.xyzw =  input.fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.interp8.xyzw =  input.shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.interp4.xy;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.interp5.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp6.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp7.xyzw;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.interp8.xyzw;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Top_TexelSize;
        float4 _Side1_TexelSize;
        float4 _Side2_TexelSize;
        float _Smoothness;
        float4 _TopNormal_TexelSize;
        float4 _Side1Normal_TexelSize;
        float4 _Side2Normal_TexelSize;
        float4 _TopBlendColor;
        float _TopBlendStrength;
        float2 _TopTiling;
        float2 _SideTiling;
        float _TopNormalStrength;
        float _SideNormalStrength;
        float _Blend;
        float _TopBlend;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Top);
        SAMPLER(sampler_Top);
        TEXTURE2D(_Side1);
        SAMPLER(sampler_Side1);
        TEXTURE2D(_Side2);
        SAMPLER(sampler_Side2);
        TEXTURE2D(_TopNormal);
        SAMPLER(sampler_TopNormal);
        TEXTURE2D(_Side1Normal);
        SAMPLER(sampler_Side1Normal);
        TEXTURE2D(_Side2Normal);
        SAMPLER(sampler_Side2Normal);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }
        
        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }
        
        void Unity_Power_float3(float3 A, float3 B, out float3 Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Blend_Overlay_float4(float4 Base, float4 Blend, out float4 Out, float Opacity)
        {
            float4 result1 = 1.0 - 2.0 * (1.0 - Base) * (1.0 - Blend);
            float4 result2 = 2.0 * Base * Blend;
            float4 zeroOrOne = step(Base, 0.5);
            Out = result2 * zeroOrOne + (1 - zeroOrOne) * result1;
            Out = lerp(Base, Out, Opacity);
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        void Unity_MatrixConstruction_Row_float (float4 M0, float4 M1, float4 M2, float4 M3, out float4x4 Out4x4, out float3x3 Out3x3, out float2x2 Out2x2)
        {
            Out4x4 = float4x4(M0.x, M0.y, M0.z, M0.w, M1.x, M1.y, M1.z, M1.w, M2.x, M2.y, M2.z, M2.w, M3.x, M3.y, M3.z, M3.w);
            Out3x3 = float3x3(M0.x, M0.y, M0.z, M1.x, M1.y, M1.z, M2.x, M2.y, M2.z);
            Out2x2 = float2x2(M0.x, M0.y, M1.x, M1.y);
        }
        
        void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
        {
            Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
        }
        
        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_Multiply_float3x3_float3(float3x3 A, float3 B, out float3 Out)
        {
            Out = mul(A, B);
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0 = UnityBuildTexture2DStructNoScale(_Side1);
            float _Split_8a8287079f9a494382d5e21ff928e867_R_1 = IN.WorldSpacePosition[0];
            float _Split_8a8287079f9a494382d5e21ff928e867_G_2 = IN.WorldSpacePosition[1];
            float _Split_8a8287079f9a494382d5e21ff928e867_B_3 = IN.WorldSpacePosition[2];
            float _Split_8a8287079f9a494382d5e21ff928e867_A_4 = 0;
            float2 _Vector2_422303a2e182451483c76a2df62d8fbd_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_B_3, _Split_8a8287079f9a494382d5e21ff928e867_G_2);
            float2 _Property_f5515325ca8e44f0b693681c1553b814_Out_0 = _SideTiling;
            float2 _TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3;
            Unity_TilingAndOffset_float(_Vector2_422303a2e182451483c76a2df62d8fbd_Out_0, _Property_f5515325ca8e44f0b693681c1553b814_Out_0, float2 (0, 0), _TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3);
            float4 _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0 = SAMPLE_TEXTURE2D(_Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.tex, _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.samplerstate, _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.GetTransformedUV(_TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3));
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_R_4 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.r;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_G_5 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.g;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_B_6 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.b;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_A_7 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.a;
            float3 _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceNormal, _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1);
            float3 _Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1;
            Unity_Absolute_float3(_Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1, _Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1);
            float _Property_c199e3a40a374c27bc4f877aa0779f26_Out_0 = _Blend;
            float3 _Power_63f769573a36444489ea06f547e82f34_Out_2;
            Unity_Power_float3(_Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1, (_Property_c199e3a40a374c27bc4f877aa0779f26_Out_0.xxx), _Power_63f769573a36444489ea06f547e82f34_Out_2);
            float _Property_95e8e8c764df42cd849f5794c47de952_Out_0 = _TopBlend;
            float3 _Vector3_a22857b561994fd0b4fd09b1d80be6b2_Out_0 = float3(1, _Property_95e8e8c764df42cd849f5794c47de952_Out_0, 1);
            float3 _Multiply_901287298f374f398f61deb90e01229f_Out_2;
            Unity_Multiply_float3_float3(_Power_63f769573a36444489ea06f547e82f34_Out_2, _Vector3_a22857b561994fd0b4fd09b1d80be6b2_Out_0, _Multiply_901287298f374f398f61deb90e01229f_Out_2);
            float3 _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2;
            Unity_Maximum_float3(_Multiply_901287298f374f398f61deb90e01229f_Out_2, float3(0, 0, 0), _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2);
            float _Split_3bac21d320964dbca8d9094760c87a24_R_1 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[0];
            float _Split_3bac21d320964dbca8d9094760c87a24_G_2 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[1];
            float _Split_3bac21d320964dbca8d9094760c87a24_B_3 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[2];
            float _Split_3bac21d320964dbca8d9094760c87a24_A_4 = 0;
            float _Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2;
            Unity_Add_float(_Split_3bac21d320964dbca8d9094760c87a24_R_1, _Split_3bac21d320964dbca8d9094760c87a24_G_2, _Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2);
            float _Add_188219e788de45eba666bba49521d656_Out_2;
            Unity_Add_float(_Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2, _Split_3bac21d320964dbca8d9094760c87a24_B_3, _Add_188219e788de45eba666bba49521d656_Out_2);
            float3 _Divide_8aad109457564563994d4710b7e4648a_Out_2;
            Unity_Divide_float3(_Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2, (_Add_188219e788de45eba666bba49521d656_Out_2.xxx), _Divide_8aad109457564563994d4710b7e4648a_Out_2);
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[0];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[1];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[2];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_A_4 = 0;
            float4 _Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2;
            Unity_Multiply_float4_float4(_SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1.xxxx), _Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2);
            UnityTexture2D _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0 = UnityBuildTexture2DStructNoScale(_Top);
            float2 _Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_R_1, _Split_8a8287079f9a494382d5e21ff928e867_B_3);
            float2 _Property_556bde57ae654fa1a27d1f931f71f69d_Out_0 = _TopTiling;
            float2 _TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3;
            Unity_TilingAndOffset_float(_Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0, _Property_556bde57ae654fa1a27d1f931f71f69d_Out_0, float2 (0, 0), _TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3);
            float4 _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0 = SAMPLE_TEXTURE2D(_Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.tex, _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.samplerstate, _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.GetTransformedUV(_TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3));
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_R_4 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.r;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_G_5 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.g;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_B_6 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.b;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_A_7 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.a;
            float4 _Property_b80b6d14d20d46dfa59788b8390c12d8_Out_0 = _TopBlendColor;
            float _Property_bfc90837b07349408e8f8761a44b1114_Out_0 = _TopBlendStrength;
            float4 _Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2;
            Unity_Blend_Overlay_float4(_SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0, _Property_b80b6d14d20d46dfa59788b8390c12d8_Out_0, _Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2, _Property_bfc90837b07349408e8f8761a44b1114_Out_0);
            float4 _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2;
            Unity_Multiply_float4_float4(_Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2.xxxx), _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2);
            float4 _Add_218795fc166a426aa361c539f291e0b1_Out_2;
            Unity_Add_float4(_Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2, _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2, _Add_218795fc166a426aa361c539f291e0b1_Out_2);
            UnityTexture2D _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0 = UnityBuildTexture2DStructNoScale(_Side2);
            float2 _Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_R_1, _Split_8a8287079f9a494382d5e21ff928e867_G_2);
            float2 _Property_d2d6aa174ccc4fc98d6a72e79a21ea63_Out_0 = _SideTiling;
            float2 _TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3;
            Unity_TilingAndOffset_float(_Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0, _Property_d2d6aa174ccc4fc98d6a72e79a21ea63_Out_0, float2 (0, 0), _TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3);
            float4 _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.tex, _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.samplerstate, _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.GetTransformedUV(_TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3));
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_R_4 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.r;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_G_5 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.g;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_B_6 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.b;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_A_7 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.a;
            float4 _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2;
            Unity_Multiply_float4_float4(_SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3.xxxx), _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2);
            float4 _Add_933e680106a64ad8b90f42fd329b74f6_Out_2;
            Unity_Add_float4(_Add_218795fc166a426aa361c539f291e0b1_Out_2, _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2, _Add_933e680106a64ad8b90f42fd329b74f6_Out_2);
            float3 _Normalize_8fbf484698e949e48d41a75c7a42f02c_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceTangent, _Normalize_8fbf484698e949e48d41a75c7a42f02c_Out_1);
            float3 _Normalize_138139e3277b4fae8c902af48021c27b_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceBiTangent, _Normalize_138139e3277b4fae8c902af48021c27b_Out_1);
            float4x4 _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var4x4_4;
            float3x3 _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var3x3_5;
            float2x2 _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var2x2_6;
            Unity_MatrixConstruction_Row_float((float4(_Normalize_8fbf484698e949e48d41a75c7a42f02c_Out_1, 1.0)), (float4(_Normalize_138139e3277b4fae8c902af48021c27b_Out_1, 1.0)), (float4(_Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1, 1.0)), float4 (0, 0, 0, 0), _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var4x4_4, _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var3x3_5, _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var2x2_6);
            UnityTexture2D _Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0 = UnityBuildTexture2DStructNoScale(_Side1Normal);
            float2 _Property_fea94bc210a942a7b8f5e99b572205f2_Out_0 = _SideTiling;
            float2 _TilingAndOffset_f489eaa422e74c34b25248e65cb10f5c_Out_3;
            Unity_TilingAndOffset_float(_Vector2_422303a2e182451483c76a2df62d8fbd_Out_0, _Property_fea94bc210a942a7b8f5e99b572205f2_Out_0, float2 (0, 0), _TilingAndOffset_f489eaa422e74c34b25248e65cb10f5c_Out_3);
            float4 _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0.tex, _Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0.samplerstate, _Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0.GetTransformedUV(_TilingAndOffset_f489eaa422e74c34b25248e65cb10f5c_Out_3));
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_R_4 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.r;
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_G_5 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.g;
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_B_6 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.b;
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_A_7 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.a;
            float _Property_06bb67e1d14d4c7abb3826e91fe5d824_Out_0 = _SideNormalStrength;
            float3 _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.xyz), _Property_06bb67e1d14d4c7abb3826e91fe5d824_Out_0, _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2);
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_R_1 = _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2[0];
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_G_2 = _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2[1];
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_B_3 = _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2[2];
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_A_4 = 0;
            float _Absolute_81d9831799b840b9a1d2b4c566a1622a_Out_1;
            Unity_Absolute_float(_Split_27883ef8495d4e078f3c6ec5be5b3ac3_B_3, _Absolute_81d9831799b840b9a1d2b4c566a1622a_Out_1);
            float _Split_66b91a799fa249599b2cf7d52c20ceae_R_1 = _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1[0];
            float _Split_66b91a799fa249599b2cf7d52c20ceae_G_2 = _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1[1];
            float _Split_66b91a799fa249599b2cf7d52c20ceae_B_3 = _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1[2];
            float _Split_66b91a799fa249599b2cf7d52c20ceae_A_4 = 0;
            float _Multiply_cba9440999d14f09b0349ed5a9d0bb74_Out_2;
            Unity_Multiply_float_float(_Absolute_81d9831799b840b9a1d2b4c566a1622a_Out_1, _Split_66b91a799fa249599b2cf7d52c20ceae_R_1, _Multiply_cba9440999d14f09b0349ed5a9d0bb74_Out_2);
            float4 _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGBA_4;
            float3 _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGB_5;
            float2 _Combine_f3158e4900b649a79aa67d1e219ea4bd_RG_6;
            Unity_Combine_float(_Split_27883ef8495d4e078f3c6ec5be5b3ac3_R_1, _Split_27883ef8495d4e078f3c6ec5be5b3ac3_G_2, 0, 0, _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGBA_4, _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGB_5, _Combine_f3158e4900b649a79aa67d1e219ea4bd_RG_6);
            float4 _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGBA_4;
            float3 _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGB_5;
            float2 _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RG_6;
            Unity_Combine_float(_Split_66b91a799fa249599b2cf7d52c20ceae_B_3, _Split_66b91a799fa249599b2cf7d52c20ceae_G_2, 0, 0, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGBA_4, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGB_5, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RG_6);
            float2 _Add_45086c33520b40bf98a4b4e639013aaa_Out_2;
            Unity_Add_float2(_Combine_f3158e4900b649a79aa67d1e219ea4bd_RG_6, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RG_6, _Add_45086c33520b40bf98a4b4e639013aaa_Out_2);
            float _Split_01fe340496a6496594e1dbcd836efe88_R_1 = _Add_45086c33520b40bf98a4b4e639013aaa_Out_2[0];
            float _Split_01fe340496a6496594e1dbcd836efe88_G_2 = _Add_45086c33520b40bf98a4b4e639013aaa_Out_2[1];
            float _Split_01fe340496a6496594e1dbcd836efe88_B_3 = 0;
            float _Split_01fe340496a6496594e1dbcd836efe88_A_4 = 0;
            float4 _Combine_d41777d14eac458d8432b72821aa860a_RGBA_4;
            float3 _Combine_d41777d14eac458d8432b72821aa860a_RGB_5;
            float2 _Combine_d41777d14eac458d8432b72821aa860a_RG_6;
            Unity_Combine_float(_Multiply_cba9440999d14f09b0349ed5a9d0bb74_Out_2, _Split_01fe340496a6496594e1dbcd836efe88_G_2, _Split_01fe340496a6496594e1dbcd836efe88_R_1, 0, _Combine_d41777d14eac458d8432b72821aa860a_RGBA_4, _Combine_d41777d14eac458d8432b72821aa860a_RGB_5, _Combine_d41777d14eac458d8432b72821aa860a_RG_6);
            float3 _Multiply_25315676ebb14ebf82037668ac8e32b4_Out_2;
            Unity_Multiply_float3_float3(_Combine_d41777d14eac458d8432b72821aa860a_RGB_5, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1.xxx), _Multiply_25315676ebb14ebf82037668ac8e32b4_Out_2);
            UnityTexture2D _Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0 = UnityBuildTexture2DStructNoScale(_TopNormal);
            float2 _Property_c6841a14d6bf45d9bd1e07ea6f72d965_Out_0 = _TopTiling;
            float2 _TilingAndOffset_6e910a893a3a42719219523be1ad6c27_Out_3;
            Unity_TilingAndOffset_float(_Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0, _Property_c6841a14d6bf45d9bd1e07ea6f72d965_Out_0, float2 (0, 0), _TilingAndOffset_6e910a893a3a42719219523be1ad6c27_Out_3);
            float4 _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0 = SAMPLE_TEXTURE2D(_Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0.tex, _Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0.samplerstate, _Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0.GetTransformedUV(_TilingAndOffset_6e910a893a3a42719219523be1ad6c27_Out_3));
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_R_4 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.r;
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_G_5 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.g;
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_B_6 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.b;
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_A_7 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.a;
            float _Property_af07a77e53ef41f499e3970c74406ca7_Out_0 = _TopNormalStrength;
            float3 _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.xyz), _Property_af07a77e53ef41f499e3970c74406ca7_Out_0, _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2);
            float _Split_fbb97fbe21d8477d923efa93f57b1517_R_1 = _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2[0];
            float _Split_fbb97fbe21d8477d923efa93f57b1517_G_2 = _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2[1];
            float _Split_fbb97fbe21d8477d923efa93f57b1517_B_3 = _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2[2];
            float _Split_fbb97fbe21d8477d923efa93f57b1517_A_4 = 0;
            float4 _Combine_50f1cb9c657b489387ee416f1f77022a_RGBA_4;
            float3 _Combine_50f1cb9c657b489387ee416f1f77022a_RGB_5;
            float2 _Combine_50f1cb9c657b489387ee416f1f77022a_RG_6;
            Unity_Combine_float(_Split_fbb97fbe21d8477d923efa93f57b1517_R_1, _Split_fbb97fbe21d8477d923efa93f57b1517_G_2, 0, 0, _Combine_50f1cb9c657b489387ee416f1f77022a_RGBA_4, _Combine_50f1cb9c657b489387ee416f1f77022a_RGB_5, _Combine_50f1cb9c657b489387ee416f1f77022a_RG_6);
            float4 _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGBA_4;
            float3 _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGB_5;
            float2 _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RG_6;
            Unity_Combine_float(_Split_66b91a799fa249599b2cf7d52c20ceae_R_1, _Split_66b91a799fa249599b2cf7d52c20ceae_B_3, 0, 0, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGBA_4, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGB_5, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RG_6);
            float2 _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2;
            Unity_Add_float2(_Combine_50f1cb9c657b489387ee416f1f77022a_RG_6, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RG_6, _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2);
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_R_1 = _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2[0];
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_G_2 = _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2[1];
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_B_3 = 0;
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_A_4 = 0;
            float _Absolute_30a05240f6ed469ba0629dbec0af13f3_Out_1;
            Unity_Absolute_float(_Split_fbb97fbe21d8477d923efa93f57b1517_B_3, _Absolute_30a05240f6ed469ba0629dbec0af13f3_Out_1);
            float _Multiply_7ca96e1a618246f1b490d564baa2e44e_Out_2;
            Unity_Multiply_float_float(_Absolute_30a05240f6ed469ba0629dbec0af13f3_Out_1, _Split_66b91a799fa249599b2cf7d52c20ceae_G_2, _Multiply_7ca96e1a618246f1b490d564baa2e44e_Out_2);
            float4 _Combine_3397125918044e3d9e6e8897e6491ee8_RGBA_4;
            float3 _Combine_3397125918044e3d9e6e8897e6491ee8_RGB_5;
            float2 _Combine_3397125918044e3d9e6e8897e6491ee8_RG_6;
            Unity_Combine_float(_Split_d6e96aca1dcf4a6fa101dc65f44e8e91_R_1, _Multiply_7ca96e1a618246f1b490d564baa2e44e_Out_2, _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_G_2, 0, _Combine_3397125918044e3d9e6e8897e6491ee8_RGBA_4, _Combine_3397125918044e3d9e6e8897e6491ee8_RGB_5, _Combine_3397125918044e3d9e6e8897e6491ee8_RG_6);
            float3 _Multiply_e1d8696c71864d4e928f9d8ae5eae9b4_Out_2;
            Unity_Multiply_float3_float3(_Combine_3397125918044e3d9e6e8897e6491ee8_RGB_5, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2.xxx), _Multiply_e1d8696c71864d4e928f9d8ae5eae9b4_Out_2);
            float3 _Add_be41a1e3b7ab4933be449cce5b94e43b_Out_2;
            Unity_Add_float3(_Multiply_25315676ebb14ebf82037668ac8e32b4_Out_2, _Multiply_e1d8696c71864d4e928f9d8ae5eae9b4_Out_2, _Add_be41a1e3b7ab4933be449cce5b94e43b_Out_2);
            UnityTexture2D _Property_bbc64da39f6544c288772c846dba1d98_Out_0 = UnityBuildTexture2DStructNoScale(_Side2Normal);
            float2 _Property_e2c8ed57e8324498ba6690540c4b01ce_Out_0 = _SideTiling;
            float2 _TilingAndOffset_56b93257dea843cea4cc025009828652_Out_3;
            Unity_TilingAndOffset_float(_Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0, _Property_e2c8ed57e8324498ba6690540c4b01ce_Out_0, float2 (0, 0), _TilingAndOffset_56b93257dea843cea4cc025009828652_Out_3);
            float4 _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0 = SAMPLE_TEXTURE2D(_Property_bbc64da39f6544c288772c846dba1d98_Out_0.tex, _Property_bbc64da39f6544c288772c846dba1d98_Out_0.samplerstate, _Property_bbc64da39f6544c288772c846dba1d98_Out_0.GetTransformedUV(_TilingAndOffset_56b93257dea843cea4cc025009828652_Out_3));
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_R_4 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.r;
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_G_5 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.g;
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_B_6 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.b;
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_A_7 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.a;
            float _Property_34a5f85b6edf4acdad9f5e7f593ef446_Out_0 = _SideNormalStrength;
            float3 _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.xyz), _Property_34a5f85b6edf4acdad9f5e7f593ef446_Out_0, _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2);
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_R_1 = _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2[0];
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_G_2 = _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2[1];
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_B_3 = _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2[2];
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_A_4 = 0;
            float4 _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGBA_4;
            float3 _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGB_5;
            float2 _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RG_6;
            Unity_Combine_float(_Split_e9c2ff6ae8cb459492cfa8a97b4dd778_R_1, _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_G_2, 0, 0, _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGBA_4, _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGB_5, _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RG_6);
            float4 _Combine_77995c8f08c6490681323ba57c634868_RGBA_4;
            float3 _Combine_77995c8f08c6490681323ba57c634868_RGB_5;
            float2 _Combine_77995c8f08c6490681323ba57c634868_RG_6;
            Unity_Combine_float(_Split_66b91a799fa249599b2cf7d52c20ceae_R_1, _Split_66b91a799fa249599b2cf7d52c20ceae_G_2, 0, 0, _Combine_77995c8f08c6490681323ba57c634868_RGBA_4, _Combine_77995c8f08c6490681323ba57c634868_RGB_5, _Combine_77995c8f08c6490681323ba57c634868_RG_6);
            float2 _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2;
            Unity_Add_float2(_Combine_707341f8f2d94e1d82a3f1431a8f8c52_RG_6, _Combine_77995c8f08c6490681323ba57c634868_RG_6, _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2);
            float _Split_f649548941034bbabc90d4e027faf0f0_R_1 = _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2[0];
            float _Split_f649548941034bbabc90d4e027faf0f0_G_2 = _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2[1];
            float _Split_f649548941034bbabc90d4e027faf0f0_B_3 = 0;
            float _Split_f649548941034bbabc90d4e027faf0f0_A_4 = 0;
            float _Absolute_b8f8f975d97c46b7917fe882f3e0568e_Out_1;
            Unity_Absolute_float(_Split_e9c2ff6ae8cb459492cfa8a97b4dd778_B_3, _Absolute_b8f8f975d97c46b7917fe882f3e0568e_Out_1);
            float _Multiply_eb22109da7ee4bde9c64e86cdcb3f703_Out_2;
            Unity_Multiply_float_float(_Absolute_b8f8f975d97c46b7917fe882f3e0568e_Out_1, _Split_66b91a799fa249599b2cf7d52c20ceae_B_3, _Multiply_eb22109da7ee4bde9c64e86cdcb3f703_Out_2);
            float4 _Combine_f18458f1fbea4cafb126653f3c712144_RGBA_4;
            float3 _Combine_f18458f1fbea4cafb126653f3c712144_RGB_5;
            float2 _Combine_f18458f1fbea4cafb126653f3c712144_RG_6;
            Unity_Combine_float(_Split_f649548941034bbabc90d4e027faf0f0_R_1, _Split_f649548941034bbabc90d4e027faf0f0_G_2, _Multiply_eb22109da7ee4bde9c64e86cdcb3f703_Out_2, 0, _Combine_f18458f1fbea4cafb126653f3c712144_RGBA_4, _Combine_f18458f1fbea4cafb126653f3c712144_RGB_5, _Combine_f18458f1fbea4cafb126653f3c712144_RG_6);
            float3 _Multiply_f8671ad3faa54908abf30d5064d2b9ad_Out_2;
            Unity_Multiply_float3_float3(_Combine_f18458f1fbea4cafb126653f3c712144_RGB_5, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3.xxx), _Multiply_f8671ad3faa54908abf30d5064d2b9ad_Out_2);
            float3 _Add_5120cf7e02884188ab7e3ff15353fec9_Out_2;
            Unity_Add_float3(_Add_be41a1e3b7ab4933be449cce5b94e43b_Out_2, _Multiply_f8671ad3faa54908abf30d5064d2b9ad_Out_2, _Add_5120cf7e02884188ab7e3ff15353fec9_Out_2);
            float3 _Multiply_b8253329450045f6993d3c52a44be133_Out_2;
            Unity_Multiply_float3x3_float3(_MatrixConstruction_1497565cfa514012949cd6aca03566ee_var3x3_5, _Add_5120cf7e02884188ab7e3ff15353fec9_Out_2, _Multiply_b8253329450045f6993d3c52a44be133_Out_2);
            float3 _Normalize_8ba6483360404f6a986179ff26c09eac_Out_1;
            Unity_Normalize_float3(_Multiply_b8253329450045f6993d3c52a44be133_Out_2, _Normalize_8ba6483360404f6a986179ff26c09eac_Out_1);
            float _Property_85554735f66147248ee259c177929e1f_Out_0 = _Smoothness;
            surface.BaseColor = (_Add_933e680106a64ad8b90f42fd329b74f6_Out_2.xyz);
            surface.NormalTS = _Normalize_8ba6483360404f6a986179ff26c09eac_Out_1;
            surface.Emission = float3(0, 0, 0);
            surface.Metallic = 0;
            surface.Smoothness = _Property_85554735f66147248ee259c177929e1f_Out_0;
            surface.Occlusion = 1;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
            // use bitangent on the fly like in hdrp
            // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0)* GetOddNegativeScale();
            float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
            // to pr               eserve mikktspace compliance we use same scale renormFactor as was used on the normal.
            // This                is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent = renormFactor * input.tangentWS.xyz;
            output.WorldSpaceBiTangent = renormFactor * bitang;
        
            output.WorldSpacePosition = input.positionWS;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "PBRForwardPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        ColorMask 0
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_NORMAL_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SHADOWCASTER
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "ShaderStructures.hlsl"
        uniform StructuredBuffer<Triangle> triangleBuffer;
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             uint id : SV_VertexID;
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.normalWS = input.interp0.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Top_TexelSize;
        float4 _Side1_TexelSize;
        float4 _Side2_TexelSize;
        float _Smoothness;
        float4 _TopNormal_TexelSize;
        float4 _Side1Normal_TexelSize;
        float4 _Side2Normal_TexelSize;
        float4 _TopBlendColor;
        float _TopBlendStrength;
        float2 _TopTiling;
        float2 _SideTiling;
        float _TopNormalStrength;
        float _SideNormalStrength;
        float _Blend;
        float _TopBlend;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Top);
        SAMPLER(sampler_Top);
        TEXTURE2D(_Side1);
        SAMPLER(sampler_Side1);
        TEXTURE2D(_Side2);
        SAMPLER(sampler_Side2);
        TEXTURE2D(_TopNormal);
        SAMPLER(sampler_TopNormal);
        TEXTURE2D(_Side1Normal);
        SAMPLER(sampler_Side1Normal);
        TEXTURE2D(_Side2Normal);
        SAMPLER(sampler_Side2Normal);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        // GraphFunctions: <None>
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "ShadowCasterPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        ColorMask 0
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "ShaderStructures.hlsl"
        uniform StructuredBuffer<Triangle> triangleBuffer;
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             uint id : SV_VertexID;
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Top_TexelSize;
        float4 _Side1_TexelSize;
        float4 _Side2_TexelSize;
        float _Smoothness;
        float4 _TopNormal_TexelSize;
        float4 _Side1Normal_TexelSize;
        float4 _Side2Normal_TexelSize;
        float4 _TopBlendColor;
        float _TopBlendStrength;
        float2 _TopTiling;
        float2 _SideTiling;
        float _TopNormalStrength;
        float _SideNormalStrength;
        float _Blend;
        float _TopBlend;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Top);
        SAMPLER(sampler_Top);
        TEXTURE2D(_Side1);
        SAMPLER(sampler_Side1);
        TEXTURE2D(_Side2);
        SAMPLER(sampler_Side2);
        TEXTURE2D(_TopNormal);
        SAMPLER(sampler_TopNormal);
        TEXTURE2D(_Side1Normal);
        SAMPLER(sampler_Side1Normal);
        TEXTURE2D(_Side2Normal);
        SAMPLER(sampler_Side2Normal);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        // GraphFunctions: <None>
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "DepthOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALS
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "ShaderStructures.hlsl"
        uniform StructuredBuffer<Triangle> triangleBuffer;
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             uint id : SV_VertexID;
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 TangentSpaceNormal;
             float3 WorldSpaceTangent;
             float3 WorldSpaceBiTangent;
             float3 WorldSpacePosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Top_TexelSize;
        float4 _Side1_TexelSize;
        float4 _Side2_TexelSize;
        float _Smoothness;
        float4 _TopNormal_TexelSize;
        float4 _Side1Normal_TexelSize;
        float4 _Side2Normal_TexelSize;
        float4 _TopBlendColor;
        float _TopBlendStrength;
        float2 _TopTiling;
        float2 _SideTiling;
        float _TopNormalStrength;
        float _SideNormalStrength;
        float _Blend;
        float _TopBlend;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Top);
        SAMPLER(sampler_Top);
        TEXTURE2D(_Side1);
        SAMPLER(sampler_Side1);
        TEXTURE2D(_Side2);
        SAMPLER(sampler_Side2);
        TEXTURE2D(_TopNormal);
        SAMPLER(sampler_TopNormal);
        TEXTURE2D(_Side1Normal);
        SAMPLER(sampler_Side1Normal);
        TEXTURE2D(_Side2Normal);
        SAMPLER(sampler_Side2Normal);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }
        
        void Unity_MatrixConstruction_Row_float (float4 M0, float4 M1, float4 M2, float4 M3, out float4x4 Out4x4, out float3x3 Out3x3, out float2x2 Out2x2)
        {
            Out4x4 = float4x4(M0.x, M0.y, M0.z, M0.w, M1.x, M1.y, M1.z, M1.w, M2.x, M2.y, M2.z, M2.w, M3.x, M3.y, M3.z, M3.w);
            Out3x3 = float3x3(M0.x, M0.y, M0.z, M1.x, M1.y, M1.z, M2.x, M2.y, M2.z);
            Out2x2 = float2x2(M0.x, M0.y, M1.x, M1.y);
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
        {
            Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
        }
        
        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }
        
        void Unity_Power_float3(float3 A, float3 B, out float3 Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_Multiply_float3x3_float3(float3x3 A, float3 B, out float3 Out)
        {
            Out = mul(A, B);
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 NormalTS;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float3 _Normalize_8fbf484698e949e48d41a75c7a42f02c_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceTangent, _Normalize_8fbf484698e949e48d41a75c7a42f02c_Out_1);
            float3 _Normalize_138139e3277b4fae8c902af48021c27b_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceBiTangent, _Normalize_138139e3277b4fae8c902af48021c27b_Out_1);
            float3 _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceNormal, _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1);
            float4x4 _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var4x4_4;
            float3x3 _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var3x3_5;
            float2x2 _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var2x2_6;
            Unity_MatrixConstruction_Row_float((float4(_Normalize_8fbf484698e949e48d41a75c7a42f02c_Out_1, 1.0)), (float4(_Normalize_138139e3277b4fae8c902af48021c27b_Out_1, 1.0)), (float4(_Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1, 1.0)), float4 (0, 0, 0, 0), _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var4x4_4, _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var3x3_5, _MatrixConstruction_1497565cfa514012949cd6aca03566ee_var2x2_6);
            UnityTexture2D _Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0 = UnityBuildTexture2DStructNoScale(_Side1Normal);
            float _Split_8a8287079f9a494382d5e21ff928e867_R_1 = IN.WorldSpacePosition[0];
            float _Split_8a8287079f9a494382d5e21ff928e867_G_2 = IN.WorldSpacePosition[1];
            float _Split_8a8287079f9a494382d5e21ff928e867_B_3 = IN.WorldSpacePosition[2];
            float _Split_8a8287079f9a494382d5e21ff928e867_A_4 = 0;
            float2 _Vector2_422303a2e182451483c76a2df62d8fbd_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_B_3, _Split_8a8287079f9a494382d5e21ff928e867_G_2);
            float2 _Property_fea94bc210a942a7b8f5e99b572205f2_Out_0 = _SideTiling;
            float2 _TilingAndOffset_f489eaa422e74c34b25248e65cb10f5c_Out_3;
            Unity_TilingAndOffset_float(_Vector2_422303a2e182451483c76a2df62d8fbd_Out_0, _Property_fea94bc210a942a7b8f5e99b572205f2_Out_0, float2 (0, 0), _TilingAndOffset_f489eaa422e74c34b25248e65cb10f5c_Out_3);
            float4 _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0.tex, _Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0.samplerstate, _Property_6d4d000ce45e40638bcb6f8f9540990a_Out_0.GetTransformedUV(_TilingAndOffset_f489eaa422e74c34b25248e65cb10f5c_Out_3));
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_R_4 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.r;
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_G_5 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.g;
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_B_6 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.b;
            float _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_A_7 = _SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.a;
            float _Property_06bb67e1d14d4c7abb3826e91fe5d824_Out_0 = _SideNormalStrength;
            float3 _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_9bf131b6c974418688d95367c422ecbe_RGBA_0.xyz), _Property_06bb67e1d14d4c7abb3826e91fe5d824_Out_0, _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2);
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_R_1 = _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2[0];
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_G_2 = _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2[1];
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_B_3 = _NormalStrength_cd807e7721f1424d9fd3f40309b5903e_Out_2[2];
            float _Split_27883ef8495d4e078f3c6ec5be5b3ac3_A_4 = 0;
            float _Absolute_81d9831799b840b9a1d2b4c566a1622a_Out_1;
            Unity_Absolute_float(_Split_27883ef8495d4e078f3c6ec5be5b3ac3_B_3, _Absolute_81d9831799b840b9a1d2b4c566a1622a_Out_1);
            float _Split_66b91a799fa249599b2cf7d52c20ceae_R_1 = _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1[0];
            float _Split_66b91a799fa249599b2cf7d52c20ceae_G_2 = _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1[1];
            float _Split_66b91a799fa249599b2cf7d52c20ceae_B_3 = _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1[2];
            float _Split_66b91a799fa249599b2cf7d52c20ceae_A_4 = 0;
            float _Multiply_cba9440999d14f09b0349ed5a9d0bb74_Out_2;
            Unity_Multiply_float_float(_Absolute_81d9831799b840b9a1d2b4c566a1622a_Out_1, _Split_66b91a799fa249599b2cf7d52c20ceae_R_1, _Multiply_cba9440999d14f09b0349ed5a9d0bb74_Out_2);
            float4 _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGBA_4;
            float3 _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGB_5;
            float2 _Combine_f3158e4900b649a79aa67d1e219ea4bd_RG_6;
            Unity_Combine_float(_Split_27883ef8495d4e078f3c6ec5be5b3ac3_R_1, _Split_27883ef8495d4e078f3c6ec5be5b3ac3_G_2, 0, 0, _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGBA_4, _Combine_f3158e4900b649a79aa67d1e219ea4bd_RGB_5, _Combine_f3158e4900b649a79aa67d1e219ea4bd_RG_6);
            float4 _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGBA_4;
            float3 _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGB_5;
            float2 _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RG_6;
            Unity_Combine_float(_Split_66b91a799fa249599b2cf7d52c20ceae_B_3, _Split_66b91a799fa249599b2cf7d52c20ceae_G_2, 0, 0, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGBA_4, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RGB_5, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RG_6);
            float2 _Add_45086c33520b40bf98a4b4e639013aaa_Out_2;
            Unity_Add_float2(_Combine_f3158e4900b649a79aa67d1e219ea4bd_RG_6, _Combine_19cb935cc1fd497eb18ed707cfa7b2df_RG_6, _Add_45086c33520b40bf98a4b4e639013aaa_Out_2);
            float _Split_01fe340496a6496594e1dbcd836efe88_R_1 = _Add_45086c33520b40bf98a4b4e639013aaa_Out_2[0];
            float _Split_01fe340496a6496594e1dbcd836efe88_G_2 = _Add_45086c33520b40bf98a4b4e639013aaa_Out_2[1];
            float _Split_01fe340496a6496594e1dbcd836efe88_B_3 = 0;
            float _Split_01fe340496a6496594e1dbcd836efe88_A_4 = 0;
            float4 _Combine_d41777d14eac458d8432b72821aa860a_RGBA_4;
            float3 _Combine_d41777d14eac458d8432b72821aa860a_RGB_5;
            float2 _Combine_d41777d14eac458d8432b72821aa860a_RG_6;
            Unity_Combine_float(_Multiply_cba9440999d14f09b0349ed5a9d0bb74_Out_2, _Split_01fe340496a6496594e1dbcd836efe88_G_2, _Split_01fe340496a6496594e1dbcd836efe88_R_1, 0, _Combine_d41777d14eac458d8432b72821aa860a_RGBA_4, _Combine_d41777d14eac458d8432b72821aa860a_RGB_5, _Combine_d41777d14eac458d8432b72821aa860a_RG_6);
            float3 _Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1;
            Unity_Absolute_float3(_Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1, _Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1);
            float _Property_c199e3a40a374c27bc4f877aa0779f26_Out_0 = _Blend;
            float3 _Power_63f769573a36444489ea06f547e82f34_Out_2;
            Unity_Power_float3(_Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1, (_Property_c199e3a40a374c27bc4f877aa0779f26_Out_0.xxx), _Power_63f769573a36444489ea06f547e82f34_Out_2);
            float _Property_95e8e8c764df42cd849f5794c47de952_Out_0 = _TopBlend;
            float3 _Vector3_a22857b561994fd0b4fd09b1d80be6b2_Out_0 = float3(1, _Property_95e8e8c764df42cd849f5794c47de952_Out_0, 1);
            float3 _Multiply_901287298f374f398f61deb90e01229f_Out_2;
            Unity_Multiply_float3_float3(_Power_63f769573a36444489ea06f547e82f34_Out_2, _Vector3_a22857b561994fd0b4fd09b1d80be6b2_Out_0, _Multiply_901287298f374f398f61deb90e01229f_Out_2);
            float3 _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2;
            Unity_Maximum_float3(_Multiply_901287298f374f398f61deb90e01229f_Out_2, float3(0, 0, 0), _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2);
            float _Split_3bac21d320964dbca8d9094760c87a24_R_1 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[0];
            float _Split_3bac21d320964dbca8d9094760c87a24_G_2 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[1];
            float _Split_3bac21d320964dbca8d9094760c87a24_B_3 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[2];
            float _Split_3bac21d320964dbca8d9094760c87a24_A_4 = 0;
            float _Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2;
            Unity_Add_float(_Split_3bac21d320964dbca8d9094760c87a24_R_1, _Split_3bac21d320964dbca8d9094760c87a24_G_2, _Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2);
            float _Add_188219e788de45eba666bba49521d656_Out_2;
            Unity_Add_float(_Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2, _Split_3bac21d320964dbca8d9094760c87a24_B_3, _Add_188219e788de45eba666bba49521d656_Out_2);
            float3 _Divide_8aad109457564563994d4710b7e4648a_Out_2;
            Unity_Divide_float3(_Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2, (_Add_188219e788de45eba666bba49521d656_Out_2.xxx), _Divide_8aad109457564563994d4710b7e4648a_Out_2);
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[0];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[1];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[2];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_A_4 = 0;
            float3 _Multiply_25315676ebb14ebf82037668ac8e32b4_Out_2;
            Unity_Multiply_float3_float3(_Combine_d41777d14eac458d8432b72821aa860a_RGB_5, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1.xxx), _Multiply_25315676ebb14ebf82037668ac8e32b4_Out_2);
            UnityTexture2D _Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0 = UnityBuildTexture2DStructNoScale(_TopNormal);
            float2 _Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_R_1, _Split_8a8287079f9a494382d5e21ff928e867_B_3);
            float2 _Property_c6841a14d6bf45d9bd1e07ea6f72d965_Out_0 = _TopTiling;
            float2 _TilingAndOffset_6e910a893a3a42719219523be1ad6c27_Out_3;
            Unity_TilingAndOffset_float(_Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0, _Property_c6841a14d6bf45d9bd1e07ea6f72d965_Out_0, float2 (0, 0), _TilingAndOffset_6e910a893a3a42719219523be1ad6c27_Out_3);
            float4 _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0 = SAMPLE_TEXTURE2D(_Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0.tex, _Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0.samplerstate, _Property_1266ddf33f9e4c55ad0cfa577b37bb2c_Out_0.GetTransformedUV(_TilingAndOffset_6e910a893a3a42719219523be1ad6c27_Out_3));
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_R_4 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.r;
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_G_5 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.g;
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_B_6 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.b;
            float _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_A_7 = _SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.a;
            float _Property_af07a77e53ef41f499e3970c74406ca7_Out_0 = _TopNormalStrength;
            float3 _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_d20f2dc37b894e098a73e3f14681d41e_RGBA_0.xyz), _Property_af07a77e53ef41f499e3970c74406ca7_Out_0, _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2);
            float _Split_fbb97fbe21d8477d923efa93f57b1517_R_1 = _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2[0];
            float _Split_fbb97fbe21d8477d923efa93f57b1517_G_2 = _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2[1];
            float _Split_fbb97fbe21d8477d923efa93f57b1517_B_3 = _NormalStrength_d93cb47c529847ddb2a301cb900e417e_Out_2[2];
            float _Split_fbb97fbe21d8477d923efa93f57b1517_A_4 = 0;
            float4 _Combine_50f1cb9c657b489387ee416f1f77022a_RGBA_4;
            float3 _Combine_50f1cb9c657b489387ee416f1f77022a_RGB_5;
            float2 _Combine_50f1cb9c657b489387ee416f1f77022a_RG_6;
            Unity_Combine_float(_Split_fbb97fbe21d8477d923efa93f57b1517_R_1, _Split_fbb97fbe21d8477d923efa93f57b1517_G_2, 0, 0, _Combine_50f1cb9c657b489387ee416f1f77022a_RGBA_4, _Combine_50f1cb9c657b489387ee416f1f77022a_RGB_5, _Combine_50f1cb9c657b489387ee416f1f77022a_RG_6);
            float4 _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGBA_4;
            float3 _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGB_5;
            float2 _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RG_6;
            Unity_Combine_float(_Split_66b91a799fa249599b2cf7d52c20ceae_R_1, _Split_66b91a799fa249599b2cf7d52c20ceae_B_3, 0, 0, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGBA_4, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RGB_5, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RG_6);
            float2 _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2;
            Unity_Add_float2(_Combine_50f1cb9c657b489387ee416f1f77022a_RG_6, _Combine_5469d1e6749c4d939a86c8c52c8d16ff_RG_6, _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2);
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_R_1 = _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2[0];
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_G_2 = _Add_348f0ef5c5504b7a8448f2fe79f69caa_Out_2[1];
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_B_3 = 0;
            float _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_A_4 = 0;
            float _Absolute_30a05240f6ed469ba0629dbec0af13f3_Out_1;
            Unity_Absolute_float(_Split_fbb97fbe21d8477d923efa93f57b1517_B_3, _Absolute_30a05240f6ed469ba0629dbec0af13f3_Out_1);
            float _Multiply_7ca96e1a618246f1b490d564baa2e44e_Out_2;
            Unity_Multiply_float_float(_Absolute_30a05240f6ed469ba0629dbec0af13f3_Out_1, _Split_66b91a799fa249599b2cf7d52c20ceae_G_2, _Multiply_7ca96e1a618246f1b490d564baa2e44e_Out_2);
            float4 _Combine_3397125918044e3d9e6e8897e6491ee8_RGBA_4;
            float3 _Combine_3397125918044e3d9e6e8897e6491ee8_RGB_5;
            float2 _Combine_3397125918044e3d9e6e8897e6491ee8_RG_6;
            Unity_Combine_float(_Split_d6e96aca1dcf4a6fa101dc65f44e8e91_R_1, _Multiply_7ca96e1a618246f1b490d564baa2e44e_Out_2, _Split_d6e96aca1dcf4a6fa101dc65f44e8e91_G_2, 0, _Combine_3397125918044e3d9e6e8897e6491ee8_RGBA_4, _Combine_3397125918044e3d9e6e8897e6491ee8_RGB_5, _Combine_3397125918044e3d9e6e8897e6491ee8_RG_6);
            float3 _Multiply_e1d8696c71864d4e928f9d8ae5eae9b4_Out_2;
            Unity_Multiply_float3_float3(_Combine_3397125918044e3d9e6e8897e6491ee8_RGB_5, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2.xxx), _Multiply_e1d8696c71864d4e928f9d8ae5eae9b4_Out_2);
            float3 _Add_be41a1e3b7ab4933be449cce5b94e43b_Out_2;
            Unity_Add_float3(_Multiply_25315676ebb14ebf82037668ac8e32b4_Out_2, _Multiply_e1d8696c71864d4e928f9d8ae5eae9b4_Out_2, _Add_be41a1e3b7ab4933be449cce5b94e43b_Out_2);
            UnityTexture2D _Property_bbc64da39f6544c288772c846dba1d98_Out_0 = UnityBuildTexture2DStructNoScale(_Side2Normal);
            float2 _Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_R_1, _Split_8a8287079f9a494382d5e21ff928e867_G_2);
            float2 _Property_e2c8ed57e8324498ba6690540c4b01ce_Out_0 = _SideTiling;
            float2 _TilingAndOffset_56b93257dea843cea4cc025009828652_Out_3;
            Unity_TilingAndOffset_float(_Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0, _Property_e2c8ed57e8324498ba6690540c4b01ce_Out_0, float2 (0, 0), _TilingAndOffset_56b93257dea843cea4cc025009828652_Out_3);
            float4 _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0 = SAMPLE_TEXTURE2D(_Property_bbc64da39f6544c288772c846dba1d98_Out_0.tex, _Property_bbc64da39f6544c288772c846dba1d98_Out_0.samplerstate, _Property_bbc64da39f6544c288772c846dba1d98_Out_0.GetTransformedUV(_TilingAndOffset_56b93257dea843cea4cc025009828652_Out_3));
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_R_4 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.r;
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_G_5 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.g;
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_B_6 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.b;
            float _SampleTexture2D_b3149a48f4434873a3618a011602411b_A_7 = _SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.a;
            float _Property_34a5f85b6edf4acdad9f5e7f593ef446_Out_0 = _SideNormalStrength;
            float3 _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2;
            Unity_NormalStrength_float((_SampleTexture2D_b3149a48f4434873a3618a011602411b_RGBA_0.xyz), _Property_34a5f85b6edf4acdad9f5e7f593ef446_Out_0, _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2);
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_R_1 = _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2[0];
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_G_2 = _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2[1];
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_B_3 = _NormalStrength_77d82f6bc5ff43a1ae319945181c934c_Out_2[2];
            float _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_A_4 = 0;
            float4 _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGBA_4;
            float3 _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGB_5;
            float2 _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RG_6;
            Unity_Combine_float(_Split_e9c2ff6ae8cb459492cfa8a97b4dd778_R_1, _Split_e9c2ff6ae8cb459492cfa8a97b4dd778_G_2, 0, 0, _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGBA_4, _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RGB_5, _Combine_707341f8f2d94e1d82a3f1431a8f8c52_RG_6);
            float4 _Combine_77995c8f08c6490681323ba57c634868_RGBA_4;
            float3 _Combine_77995c8f08c6490681323ba57c634868_RGB_5;
            float2 _Combine_77995c8f08c6490681323ba57c634868_RG_6;
            Unity_Combine_float(_Split_66b91a799fa249599b2cf7d52c20ceae_R_1, _Split_66b91a799fa249599b2cf7d52c20ceae_G_2, 0, 0, _Combine_77995c8f08c6490681323ba57c634868_RGBA_4, _Combine_77995c8f08c6490681323ba57c634868_RGB_5, _Combine_77995c8f08c6490681323ba57c634868_RG_6);
            float2 _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2;
            Unity_Add_float2(_Combine_707341f8f2d94e1d82a3f1431a8f8c52_RG_6, _Combine_77995c8f08c6490681323ba57c634868_RG_6, _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2);
            float _Split_f649548941034bbabc90d4e027faf0f0_R_1 = _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2[0];
            float _Split_f649548941034bbabc90d4e027faf0f0_G_2 = _Add_1d10b46618ed46039e23ee065cbe6ddf_Out_2[1];
            float _Split_f649548941034bbabc90d4e027faf0f0_B_3 = 0;
            float _Split_f649548941034bbabc90d4e027faf0f0_A_4 = 0;
            float _Absolute_b8f8f975d97c46b7917fe882f3e0568e_Out_1;
            Unity_Absolute_float(_Split_e9c2ff6ae8cb459492cfa8a97b4dd778_B_3, _Absolute_b8f8f975d97c46b7917fe882f3e0568e_Out_1);
            float _Multiply_eb22109da7ee4bde9c64e86cdcb3f703_Out_2;
            Unity_Multiply_float_float(_Absolute_b8f8f975d97c46b7917fe882f3e0568e_Out_1, _Split_66b91a799fa249599b2cf7d52c20ceae_B_3, _Multiply_eb22109da7ee4bde9c64e86cdcb3f703_Out_2);
            float4 _Combine_f18458f1fbea4cafb126653f3c712144_RGBA_4;
            float3 _Combine_f18458f1fbea4cafb126653f3c712144_RGB_5;
            float2 _Combine_f18458f1fbea4cafb126653f3c712144_RG_6;
            Unity_Combine_float(_Split_f649548941034bbabc90d4e027faf0f0_R_1, _Split_f649548941034bbabc90d4e027faf0f0_G_2, _Multiply_eb22109da7ee4bde9c64e86cdcb3f703_Out_2, 0, _Combine_f18458f1fbea4cafb126653f3c712144_RGBA_4, _Combine_f18458f1fbea4cafb126653f3c712144_RGB_5, _Combine_f18458f1fbea4cafb126653f3c712144_RG_6);
            float3 _Multiply_f8671ad3faa54908abf30d5064d2b9ad_Out_2;
            Unity_Multiply_float3_float3(_Combine_f18458f1fbea4cafb126653f3c712144_RGB_5, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3.xxx), _Multiply_f8671ad3faa54908abf30d5064d2b9ad_Out_2);
            float3 _Add_5120cf7e02884188ab7e3ff15353fec9_Out_2;
            Unity_Add_float3(_Add_be41a1e3b7ab4933be449cce5b94e43b_Out_2, _Multiply_f8671ad3faa54908abf30d5064d2b9ad_Out_2, _Add_5120cf7e02884188ab7e3ff15353fec9_Out_2);
            float3 _Multiply_b8253329450045f6993d3c52a44be133_Out_2;
            Unity_Multiply_float3x3_float3(_MatrixConstruction_1497565cfa514012949cd6aca03566ee_var3x3_5, _Add_5120cf7e02884188ab7e3ff15353fec9_Out_2, _Multiply_b8253329450045f6993d3c52a44be133_Out_2);
            float3 _Normalize_8ba6483360404f6a986179ff26c09eac_Out_1;
            Unity_Normalize_float3(_Multiply_b8253329450045f6993d3c52a44be133_Out_2, _Normalize_8ba6483360404f6a986179ff26c09eac_Out_1);
            surface.NormalTS = _Normalize_8ba6483360404f6a986179ff26c09eac_Out_1;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
            // use bitangent on the fly like in hdrp
            // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0)* GetOddNegativeScale();
            float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
            // to pr               eserve mikktspace compliance we use same scale renormFactor as was used on the normal.
            // This                is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent = renormFactor * input.tangentWS.xyz;
            output.WorldSpaceBiTangent = renormFactor * bitang;
        
            output.WorldSpacePosition = input.positionWS;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "DepthNormalsOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }
        
        // Render State
        Cull Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature _ EDITOR_VISUALIZATION
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_TEXCOORD1
        #define VARYINGS_NEED_TEXCOORD2
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_META
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "ShaderStructures.hlsl"
        uniform StructuredBuffer<Triangle> triangleBuffer;
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             uint id : SV_VertexID;
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 texCoord0;
             float4 texCoord1;
             float4 texCoord2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 WorldSpacePosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float4 interp3 : INTERP3;
             float4 interp4 : INTERP4;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.texCoord0;
            output.interp3.xyzw =  input.texCoord1;
            output.interp4.xyzw =  input.texCoord2;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.texCoord0 = input.interp2.xyzw;
            output.texCoord1 = input.interp3.xyzw;
            output.texCoord2 = input.interp4.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Top_TexelSize;
        float4 _Side1_TexelSize;
        float4 _Side2_TexelSize;
        float _Smoothness;
        float4 _TopNormal_TexelSize;
        float4 _Side1Normal_TexelSize;
        float4 _Side2Normal_TexelSize;
        float4 _TopBlendColor;
        float _TopBlendStrength;
        float2 _TopTiling;
        float2 _SideTiling;
        float _TopNormalStrength;
        float _SideNormalStrength;
        float _Blend;
        float _TopBlend;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Top);
        SAMPLER(sampler_Top);
        TEXTURE2D(_Side1);
        SAMPLER(sampler_Side1);
        TEXTURE2D(_Side2);
        SAMPLER(sampler_Side2);
        TEXTURE2D(_TopNormal);
        SAMPLER(sampler_TopNormal);
        TEXTURE2D(_Side1Normal);
        SAMPLER(sampler_Side1Normal);
        TEXTURE2D(_Side2Normal);
        SAMPLER(sampler_Side2Normal);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }
        
        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }
        
        void Unity_Power_float3(float3 A, float3 B, out float3 Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Blend_Overlay_float4(float4 Base, float4 Blend, out float4 Out, float Opacity)
        {
            float4 result1 = 1.0 - 2.0 * (1.0 - Base) * (1.0 - Blend);
            float4 result2 = 2.0 * Base * Blend;
            float4 zeroOrOne = step(Base, 0.5);
            Out = result2 * zeroOrOne + (1 - zeroOrOne) * result1;
            Out = lerp(Base, Out, Opacity);
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 Emission;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0 = UnityBuildTexture2DStructNoScale(_Side1);
            float _Split_8a8287079f9a494382d5e21ff928e867_R_1 = IN.WorldSpacePosition[0];
            float _Split_8a8287079f9a494382d5e21ff928e867_G_2 = IN.WorldSpacePosition[1];
            float _Split_8a8287079f9a494382d5e21ff928e867_B_3 = IN.WorldSpacePosition[2];
            float _Split_8a8287079f9a494382d5e21ff928e867_A_4 = 0;
            float2 _Vector2_422303a2e182451483c76a2df62d8fbd_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_B_3, _Split_8a8287079f9a494382d5e21ff928e867_G_2);
            float2 _Property_f5515325ca8e44f0b693681c1553b814_Out_0 = _SideTiling;
            float2 _TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3;
            Unity_TilingAndOffset_float(_Vector2_422303a2e182451483c76a2df62d8fbd_Out_0, _Property_f5515325ca8e44f0b693681c1553b814_Out_0, float2 (0, 0), _TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3);
            float4 _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0 = SAMPLE_TEXTURE2D(_Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.tex, _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.samplerstate, _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.GetTransformedUV(_TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3));
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_R_4 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.r;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_G_5 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.g;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_B_6 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.b;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_A_7 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.a;
            float3 _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceNormal, _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1);
            float3 _Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1;
            Unity_Absolute_float3(_Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1, _Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1);
            float _Property_c199e3a40a374c27bc4f877aa0779f26_Out_0 = _Blend;
            float3 _Power_63f769573a36444489ea06f547e82f34_Out_2;
            Unity_Power_float3(_Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1, (_Property_c199e3a40a374c27bc4f877aa0779f26_Out_0.xxx), _Power_63f769573a36444489ea06f547e82f34_Out_2);
            float _Property_95e8e8c764df42cd849f5794c47de952_Out_0 = _TopBlend;
            float3 _Vector3_a22857b561994fd0b4fd09b1d80be6b2_Out_0 = float3(1, _Property_95e8e8c764df42cd849f5794c47de952_Out_0, 1);
            float3 _Multiply_901287298f374f398f61deb90e01229f_Out_2;
            Unity_Multiply_float3_float3(_Power_63f769573a36444489ea06f547e82f34_Out_2, _Vector3_a22857b561994fd0b4fd09b1d80be6b2_Out_0, _Multiply_901287298f374f398f61deb90e01229f_Out_2);
            float3 _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2;
            Unity_Maximum_float3(_Multiply_901287298f374f398f61deb90e01229f_Out_2, float3(0, 0, 0), _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2);
            float _Split_3bac21d320964dbca8d9094760c87a24_R_1 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[0];
            float _Split_3bac21d320964dbca8d9094760c87a24_G_2 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[1];
            float _Split_3bac21d320964dbca8d9094760c87a24_B_3 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[2];
            float _Split_3bac21d320964dbca8d9094760c87a24_A_4 = 0;
            float _Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2;
            Unity_Add_float(_Split_3bac21d320964dbca8d9094760c87a24_R_1, _Split_3bac21d320964dbca8d9094760c87a24_G_2, _Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2);
            float _Add_188219e788de45eba666bba49521d656_Out_2;
            Unity_Add_float(_Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2, _Split_3bac21d320964dbca8d9094760c87a24_B_3, _Add_188219e788de45eba666bba49521d656_Out_2);
            float3 _Divide_8aad109457564563994d4710b7e4648a_Out_2;
            Unity_Divide_float3(_Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2, (_Add_188219e788de45eba666bba49521d656_Out_2.xxx), _Divide_8aad109457564563994d4710b7e4648a_Out_2);
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[0];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[1];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[2];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_A_4 = 0;
            float4 _Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2;
            Unity_Multiply_float4_float4(_SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1.xxxx), _Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2);
            UnityTexture2D _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0 = UnityBuildTexture2DStructNoScale(_Top);
            float2 _Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_R_1, _Split_8a8287079f9a494382d5e21ff928e867_B_3);
            float2 _Property_556bde57ae654fa1a27d1f931f71f69d_Out_0 = _TopTiling;
            float2 _TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3;
            Unity_TilingAndOffset_float(_Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0, _Property_556bde57ae654fa1a27d1f931f71f69d_Out_0, float2 (0, 0), _TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3);
            float4 _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0 = SAMPLE_TEXTURE2D(_Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.tex, _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.samplerstate, _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.GetTransformedUV(_TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3));
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_R_4 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.r;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_G_5 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.g;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_B_6 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.b;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_A_7 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.a;
            float4 _Property_b80b6d14d20d46dfa59788b8390c12d8_Out_0 = _TopBlendColor;
            float _Property_bfc90837b07349408e8f8761a44b1114_Out_0 = _TopBlendStrength;
            float4 _Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2;
            Unity_Blend_Overlay_float4(_SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0, _Property_b80b6d14d20d46dfa59788b8390c12d8_Out_0, _Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2, _Property_bfc90837b07349408e8f8761a44b1114_Out_0);
            float4 _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2;
            Unity_Multiply_float4_float4(_Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2.xxxx), _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2);
            float4 _Add_218795fc166a426aa361c539f291e0b1_Out_2;
            Unity_Add_float4(_Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2, _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2, _Add_218795fc166a426aa361c539f291e0b1_Out_2);
            UnityTexture2D _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0 = UnityBuildTexture2DStructNoScale(_Side2);
            float2 _Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_R_1, _Split_8a8287079f9a494382d5e21ff928e867_G_2);
            float2 _Property_d2d6aa174ccc4fc98d6a72e79a21ea63_Out_0 = _SideTiling;
            float2 _TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3;
            Unity_TilingAndOffset_float(_Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0, _Property_d2d6aa174ccc4fc98d6a72e79a21ea63_Out_0, float2 (0, 0), _TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3);
            float4 _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.tex, _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.samplerstate, _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.GetTransformedUV(_TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3));
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_R_4 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.r;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_G_5 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.g;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_B_6 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.b;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_A_7 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.a;
            float4 _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2;
            Unity_Multiply_float4_float4(_SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3.xxxx), _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2);
            float4 _Add_933e680106a64ad8b90f42fd329b74f6_Out_2;
            Unity_Add_float4(_Add_218795fc166a426aa361c539f291e0b1_Out_2, _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2, _Add_933e680106a64ad8b90f42fd329b74f6_Out_2);
            surface.BaseColor = (_Add_933e680106a64ad8b90f42fd329b74f6_Out_2.xyz);
            surface.Emission = float3(0, 0, 0);
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
        
        
            output.WorldSpacePosition = input.positionWS;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "LightingMetaPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "SceneSelectionPass"
            Tags
            {
                "LightMode" = "SceneSelectionPass"
            }
        
        // Render State
        Cull Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENESELECTIONPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "ShaderStructures.hlsl"
        uniform StructuredBuffer<Triangle> triangleBuffer;
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             uint id : SV_VertexID;
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Top_TexelSize;
        float4 _Side1_TexelSize;
        float4 _Side2_TexelSize;
        float _Smoothness;
        float4 _TopNormal_TexelSize;
        float4 _Side1Normal_TexelSize;
        float4 _Side2Normal_TexelSize;
        float4 _TopBlendColor;
        float _TopBlendStrength;
        float2 _TopTiling;
        float2 _SideTiling;
        float _TopNormalStrength;
        float _SideNormalStrength;
        float _Blend;
        float _TopBlend;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Top);
        SAMPLER(sampler_Top);
        TEXTURE2D(_Side1);
        SAMPLER(sampler_Side1);
        TEXTURE2D(_Side2);
        SAMPLER(sampler_Side2);
        TEXTURE2D(_TopNormal);
        SAMPLER(sampler_TopNormal);
        TEXTURE2D(_Side1Normal);
        SAMPLER(sampler_Side1Normal);
        TEXTURE2D(_Side2Normal);
        SAMPLER(sampler_Side2Normal);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        // GraphFunctions: <None>
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ScenePickingPass"
            Tags
            {
                "LightMode" = "Picking"
            }
        
        // Render State
        Cull Back
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENEPICKINGPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "ShaderStructures.hlsl"
        uniform StructuredBuffer<Triangle> triangleBuffer;
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             uint id : SV_VertexID;
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Top_TexelSize;
        float4 _Side1_TexelSize;
        float4 _Side2_TexelSize;
        float _Smoothness;
        float4 _TopNormal_TexelSize;
        float4 _Side1Normal_TexelSize;
        float4 _Side2Normal_TexelSize;
        float4 _TopBlendColor;
        float _TopBlendStrength;
        float2 _TopTiling;
        float2 _SideTiling;
        float _TopNormalStrength;
        float _SideNormalStrength;
        float _Blend;
        float _TopBlend;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Top);
        SAMPLER(sampler_Top);
        TEXTURE2D(_Side1);
        SAMPLER(sampler_Side1);
        TEXTURE2D(_Side2);
        SAMPLER(sampler_Side2);
        TEXTURE2D(_TopNormal);
        SAMPLER(sampler_TopNormal);
        TEXTURE2D(_Side1Normal);
        SAMPLER(sampler_Side1Normal);
        TEXTURE2D(_Side2Normal);
        SAMPLER(sampler_Side2Normal);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        // GraphFunctions: <None>
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            // Name: <None>
            Tags
            {
                "LightMode" = "Universal2D"
            }
        
        // Render State
        Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_2D
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "ShaderStructures.hlsl"
        uniform StructuredBuffer<Triangle> triangleBuffer;
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             uint id : SV_VertexID;
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 WorldSpacePosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Top_TexelSize;
        float4 _Side1_TexelSize;
        float4 _Side2_TexelSize;
        float _Smoothness;
        float4 _TopNormal_TexelSize;
        float4 _Side1Normal_TexelSize;
        float4 _Side2Normal_TexelSize;
        float4 _TopBlendColor;
        float _TopBlendStrength;
        float2 _TopTiling;
        float2 _SideTiling;
        float _TopNormalStrength;
        float _SideNormalStrength;
        float _Blend;
        float _TopBlend;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Top);
        SAMPLER(sampler_Top);
        TEXTURE2D(_Side1);
        SAMPLER(sampler_Side1);
        TEXTURE2D(_Side2);
        SAMPLER(sampler_Side2);
        TEXTURE2D(_TopNormal);
        SAMPLER(sampler_TopNormal);
        TEXTURE2D(_Side1Normal);
        SAMPLER(sampler_Side1Normal);
        TEXTURE2D(_Side2Normal);
        SAMPLER(sampler_Side2Normal);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }
        
        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }
        
        void Unity_Power_float3(float3 A, float3 B, out float3 Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Blend_Overlay_float4(float4 Base, float4 Blend, out float4 Out, float Opacity)
        {
            float4 result1 = 1.0 - 2.0 * (1.0 - Base) * (1.0 - Blend);
            float4 result2 = 2.0 * Base * Blend;
            float4 zeroOrOne = step(Base, 0.5);
            Out = result2 * zeroOrOne + (1 - zeroOrOne) * result1;
            Out = lerp(Base, Out, Opacity);
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0 = UnityBuildTexture2DStructNoScale(_Side1);
            float _Split_8a8287079f9a494382d5e21ff928e867_R_1 = IN.WorldSpacePosition[0];
            float _Split_8a8287079f9a494382d5e21ff928e867_G_2 = IN.WorldSpacePosition[1];
            float _Split_8a8287079f9a494382d5e21ff928e867_B_3 = IN.WorldSpacePosition[2];
            float _Split_8a8287079f9a494382d5e21ff928e867_A_4 = 0;
            float2 _Vector2_422303a2e182451483c76a2df62d8fbd_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_B_3, _Split_8a8287079f9a494382d5e21ff928e867_G_2);
            float2 _Property_f5515325ca8e44f0b693681c1553b814_Out_0 = _SideTiling;
            float2 _TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3;
            Unity_TilingAndOffset_float(_Vector2_422303a2e182451483c76a2df62d8fbd_Out_0, _Property_f5515325ca8e44f0b693681c1553b814_Out_0, float2 (0, 0), _TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3);
            float4 _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0 = SAMPLE_TEXTURE2D(_Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.tex, _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.samplerstate, _Property_c7df1a4d191d41afab7b2a500c49040d_Out_0.GetTransformedUV(_TilingAndOffset_e56594f4185e474886df7d899d0783c6_Out_3));
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_R_4 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.r;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_G_5 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.g;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_B_6 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.b;
            float _SampleTexture2D_606294bae8f64e59b298b5714dfef126_A_7 = _SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0.a;
            float3 _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceNormal, _Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1);
            float3 _Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1;
            Unity_Absolute_float3(_Normalize_4deba5ada4bd4051bd7949b7c262c14b_Out_1, _Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1);
            float _Property_c199e3a40a374c27bc4f877aa0779f26_Out_0 = _Blend;
            float3 _Power_63f769573a36444489ea06f547e82f34_Out_2;
            Unity_Power_float3(_Absolute_29382e7f1aa74396b3d848152cee46e5_Out_1, (_Property_c199e3a40a374c27bc4f877aa0779f26_Out_0.xxx), _Power_63f769573a36444489ea06f547e82f34_Out_2);
            float _Property_95e8e8c764df42cd849f5794c47de952_Out_0 = _TopBlend;
            float3 _Vector3_a22857b561994fd0b4fd09b1d80be6b2_Out_0 = float3(1, _Property_95e8e8c764df42cd849f5794c47de952_Out_0, 1);
            float3 _Multiply_901287298f374f398f61deb90e01229f_Out_2;
            Unity_Multiply_float3_float3(_Power_63f769573a36444489ea06f547e82f34_Out_2, _Vector3_a22857b561994fd0b4fd09b1d80be6b2_Out_0, _Multiply_901287298f374f398f61deb90e01229f_Out_2);
            float3 _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2;
            Unity_Maximum_float3(_Multiply_901287298f374f398f61deb90e01229f_Out_2, float3(0, 0, 0), _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2);
            float _Split_3bac21d320964dbca8d9094760c87a24_R_1 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[0];
            float _Split_3bac21d320964dbca8d9094760c87a24_G_2 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[1];
            float _Split_3bac21d320964dbca8d9094760c87a24_B_3 = _Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2[2];
            float _Split_3bac21d320964dbca8d9094760c87a24_A_4 = 0;
            float _Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2;
            Unity_Add_float(_Split_3bac21d320964dbca8d9094760c87a24_R_1, _Split_3bac21d320964dbca8d9094760c87a24_G_2, _Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2);
            float _Add_188219e788de45eba666bba49521d656_Out_2;
            Unity_Add_float(_Add_d6d032a7e2b344aba9bac05dde25cd45_Out_2, _Split_3bac21d320964dbca8d9094760c87a24_B_3, _Add_188219e788de45eba666bba49521d656_Out_2);
            float3 _Divide_8aad109457564563994d4710b7e4648a_Out_2;
            Unity_Divide_float3(_Maximum_d6a6aa76a7154b0383501aa5a54def83_Out_2, (_Add_188219e788de45eba666bba49521d656_Out_2.xxx), _Divide_8aad109457564563994d4710b7e4648a_Out_2);
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[0];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[1];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3 = _Divide_8aad109457564563994d4710b7e4648a_Out_2[2];
            float _Split_df24ded5a22d4417a9ca69e6cb3e2203_A_4 = 0;
            float4 _Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2;
            Unity_Multiply_float4_float4(_SampleTexture2D_606294bae8f64e59b298b5714dfef126_RGBA_0, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_R_1.xxxx), _Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2);
            UnityTexture2D _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0 = UnityBuildTexture2DStructNoScale(_Top);
            float2 _Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_R_1, _Split_8a8287079f9a494382d5e21ff928e867_B_3);
            float2 _Property_556bde57ae654fa1a27d1f931f71f69d_Out_0 = _TopTiling;
            float2 _TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3;
            Unity_TilingAndOffset_float(_Vector2_a29f029fb5c24ac8ad191aa559291969_Out_0, _Property_556bde57ae654fa1a27d1f931f71f69d_Out_0, float2 (0, 0), _TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3);
            float4 _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0 = SAMPLE_TEXTURE2D(_Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.tex, _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.samplerstate, _Property_4ae2bb8393204eaaa495a063d1e209b6_Out_0.GetTransformedUV(_TilingAndOffset_e73dd2c6cbcf4ac88e8840a0be5c2455_Out_3));
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_R_4 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.r;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_G_5 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.g;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_B_6 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.b;
            float _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_A_7 = _SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0.a;
            float4 _Property_b80b6d14d20d46dfa59788b8390c12d8_Out_0 = _TopBlendColor;
            float _Property_bfc90837b07349408e8f8761a44b1114_Out_0 = _TopBlendStrength;
            float4 _Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2;
            Unity_Blend_Overlay_float4(_SampleTexture2D_369b2e01ff514356b47ca14e2e50febc_RGBA_0, _Property_b80b6d14d20d46dfa59788b8390c12d8_Out_0, _Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2, _Property_bfc90837b07349408e8f8761a44b1114_Out_0);
            float4 _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2;
            Unity_Multiply_float4_float4(_Blend_db030b4e6d39443bb5ad6b49fb9054bf_Out_2, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_G_2.xxxx), _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2);
            float4 _Add_218795fc166a426aa361c539f291e0b1_Out_2;
            Unity_Add_float4(_Multiply_e0ba3d168be44a50b9546e30ff177123_Out_2, _Multiply_ce3297ae2711476dbebd35e2dc5844bf_Out_2, _Add_218795fc166a426aa361c539f291e0b1_Out_2);
            UnityTexture2D _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0 = UnityBuildTexture2DStructNoScale(_Side2);
            float2 _Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0 = float2(_Split_8a8287079f9a494382d5e21ff928e867_R_1, _Split_8a8287079f9a494382d5e21ff928e867_G_2);
            float2 _Property_d2d6aa174ccc4fc98d6a72e79a21ea63_Out_0 = _SideTiling;
            float2 _TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3;
            Unity_TilingAndOffset_float(_Vector2_e117420f74814c38b7fb9ec17c27d095_Out_0, _Property_d2d6aa174ccc4fc98d6a72e79a21ea63_Out_0, float2 (0, 0), _TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3);
            float4 _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0 = SAMPLE_TEXTURE2D(_Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.tex, _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.samplerstate, _Property_5b2fc29b1d5646539e0d4281d855ccfc_Out_0.GetTransformedUV(_TilingAndOffset_5ab4f1f2bd5f47aebe0b17ed6c2fa4b7_Out_3));
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_R_4 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.r;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_G_5 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.g;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_B_6 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.b;
            float _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_A_7 = _SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0.a;
            float4 _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2;
            Unity_Multiply_float4_float4(_SampleTexture2D_33a19aedaf3e4285bf088d613a89750c_RGBA_0, (_Split_df24ded5a22d4417a9ca69e6cb3e2203_B_3.xxxx), _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2);
            float4 _Add_933e680106a64ad8b90f42fd329b74f6_Out_2;
            Unity_Add_float4(_Add_218795fc166a426aa361c539f291e0b1_Out_2, _Multiply_4be3559cb4b74286b1107439b60e1996_Out_2, _Add_933e680106a64ad8b90f42fd329b74f6_Out_2);
            surface.BaseColor = (_Add_933e680106a64ad8b90f42fd329b74f6_Out_2.xyz);
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
        
        
            output.WorldSpacePosition = input.positionWS;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "PBR2DPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
    }
    CustomEditorForRenderPipeline "UnityEditor.ShaderGraphLitGUI" "UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset"
    CustomEditor "UnityEditor.ShaderGraph.GenericShaderGraphMaterialGUI"
    FallBack "Hidden/Shader Graph/FallbackError"
}