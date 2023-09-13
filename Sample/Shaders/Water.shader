// Made with Amplify Shader Editor v1.9.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Water"
{
	Properties
	{
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[NoScaleOffset]_FlowMap("FlowMap", 2D) = "bump" {}
		[NoScaleOffset]_WaterNormalMap("WaterNormalMap", 2D) = "bump" {}
		_FlowStrenght("FlowStrenght", Range( 0 , 1)) = 0.1
		_NormalStrenght("NormalStrenght", Range( 0 , 1)) = 0
		_TileScale("TileScale", Range( 0 , 10)) = 4
		_TileScale2("TileScale2", Range( 0 , 2)) = 4
		_DistortionStrenght("DistortionStrenght", Range( 0 , 0.1)) = 0.1
		_FlowSpeed("FlowSpeed", Range( 0 , 1)) = 1
		_Normal2Strenght("Normal2Strenght", Range( 0 , 1)) = 0
		_WaterColor("WaterColor", Color) = (0.2095052,0.4150943,0.2179036,0)
		_SceneDepth("SceneDepth", Range( 0 , 1)) = 1
		_Height("Height", Range( 0 , 1)) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}


		//_TransmissionShadow( "Transmission Shadow", Range( 0, 1 ) ) = 0.5
		//_TransStrength( "Trans Strength", Range( 0, 50 ) ) = 1
		//_TransNormal( "Trans Normal Distortion", Range( 0, 1 ) ) = 0.5
		//_TransScattering( "Trans Scattering", Range( 1, 50 ) ) = 2
		//_TransDirect( "Trans Direct", Range( 0, 1 ) ) = 0.9
		//_TransAmbient( "Trans Ambient", Range( 0, 1 ) ) = 0.1
		//_TransShadow( "Trans Shadow", Range( 0, 1 ) ) = 0.5
		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		_TessValue( "Max Tessellation", Range( 1, 32 ) ) = 16
		_TessMin( "Tess Min Distance", Float ) = 10
		_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		[HideInInspector][ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
		[HideInInspector][ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0
		[HideInInspector][ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0

		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "UniversalMaterialType"="Lit" }

		Cull Back
		ZWrite Off
		ZTest LEqual
		Offset 0 , 0
		AlphaToMask Off

		

		HLSLINCLUDE
		#pragma target 4.5
		#pragma prefer_hlslcc gles
		// ensure rendering platforms toggle list is visible

		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}

		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#define _RECEIVE_SHADOWS_OFF 1
			#pragma multi_compile _ DEBUG_DISPLAY
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_DISTANCE_TESSELLATION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140008
			#define REQUIRE_OPAQUE_TEXTURE 1
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
			#pragma multi_compile_fragment _ _SHADOWS_SOFT
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
			#pragma multi_compile_fragment _ _LIGHT_LAYERS
			#pragma multi_compile_fragment _ _LIGHT_COOKIES
			#pragma multi_compile _ _FORWARD_PLUS

			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ DEBUG_DISPLAY
			#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_FORWARD

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
				#define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_SCREEN_POSITION


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				ASE_SV_POSITION_QUALIFIERS float4 clipPos : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				float4 lightmapUVOrVertexSH : TEXCOORD1;
				half4 fogFactorAndVertexLight : TEXCOORD2;
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					float4 shadowCoord : TEXCOORD6;
				#endif
				#if defined(DYNAMICLIGHTMAP_ON)
					float2 dynamicLightmapUV : TEXCOORD7;
				#endif
				float4 ase_texcoord8 : TEXCOORD8;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _WaterColor;
			float _Height;
			float _FlowStrenght;
			float _FlowSpeed;
			float _TileScale;
			float _NormalStrenght;
			float _TileScale2;
			float _Normal2Strenght;
			float _DistortionStrenght;
			float _SceneDepth;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _WaterNormalMap;
			sampler2D _FlowMap;
			uniform float4 _CameraDepthTexture_TexelSize;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 texCoord35_g1 = v.texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 uv_FlowMap11 = v.texcoord.xy;
				float3 FlowMapUnpacked14 = ( UnpackNormalScale( tex2Dlod( _FlowMap, float4( uv_FlowMap11, 0, 0.0) ), 1.0f ) * _FlowStrenght );
				float2 temp_output_14_0_g1 = ( FlowMapUnpacked14.xy * 1.0 );
				float mulTime5_g1 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g1 = frac( mulTime5_g1 );
				float2 temp_output_18_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * temp_output_7_0_g1 ) );
				float temp_output_48_0_g1 = _TileScale;
				float temp_output_49_0_g1 = 0.0;
				float temp_output_53_0_g1 = _NormalStrenght;
				float3 unpack37_g1 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_18_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1), 0, 0.0) ), temp_output_53_0_g1 );
				unpack37_g1.z = lerp( 1, unpack37_g1.z, saturate(temp_output_53_0_g1) );
				float2 temp_output_19_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * frac( ( mulTime5_g1 + 0.5 ) ) ) );
				float3 unpack41_g1 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_19_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1), 0, 0.0) ), temp_output_53_0_g1 );
				unpack41_g1.z = lerp( 1, unpack41_g1.z, saturate(temp_output_53_0_g1) );
				float temp_output_17_0_g1 = abs( ( ( temp_output_7_0_g1 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g1 = lerp( unpack37_g1 , unpack41_g1 , temp_output_17_0_g1);
				float2 texCoord35_g2 = v.texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_cast_1 = (_TileScale2).xx;
				float2 texCoord104 = v.texcoord.xy * temp_cast_1 + float2( 0,0 );
				float mulTime108 = _TimeParameters.x * 0.1;
				float cos106 = cos( mulTime108 );
				float sin106 = sin( mulTime108 );
				float2 rotator106 = mul( texCoord104 - float2( 0.5,0.5 ) , float2x2( cos106 , -sin106 , sin106 , cos106 )) + float2( 0.5,0.5 );
				float3 unpack101 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( rotator106, 0, 0.0) ), _Normal2Strenght );
				unpack101.z = lerp( 1, unpack101.z, saturate(_Normal2Strenght) );
				float2 temp_output_14_0_g2 = ( unpack101.xy * 1.0 );
				float mulTime5_g2 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g2 = frac( mulTime5_g2 );
				float2 temp_output_18_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * temp_output_7_0_g2 ) );
				float temp_output_48_0_g2 = _TileScale2;
				float temp_output_49_0_g2 = 0.0;
				float temp_output_53_0_g2 = _Normal2Strenght;
				float3 unpack37_g2 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_18_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2), 0, 0.0) ), temp_output_53_0_g2 );
				unpack37_g2.z = lerp( 1, unpack37_g2.z, saturate(temp_output_53_0_g2) );
				float2 temp_output_19_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * frac( ( mulTime5_g2 + 0.5 ) ) ) );
				float3 unpack41_g2 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_19_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2), 0, 0.0) ), temp_output_53_0_g2 );
				unpack41_g2.z = lerp( 1, unpack41_g2.z, saturate(temp_output_53_0_g2) );
				float temp_output_17_0_g2 = abs( ( ( temp_output_7_0_g2 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g2 = lerp( unpack37_g2 , unpack41_g2 , temp_output_17_0_g2);
				float3 Normal100 = BlendNormal( lerpResult22_g1 , lerpResult22_g2 );
				float dotResult188 = dot( Normal100 , float3(1,1,0) );
				float3 Displace162 = ( ( v.ase_normal * _Height ) * dotResult188 );
				
				o.ase_texcoord8.xy = v.texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord8.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = Displace162;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 positionVS = TransformWorldToView( positionWS );
				float4 positionCS = TransformWorldToHClip( positionWS );

				VertexNormalInputs normalInput = GetVertexNormalInputs( v.ase_normal, v.ase_tangent );

				o.tSpace0 = float4( normalInput.normalWS, positionWS.x);
				o.tSpace1 = float4( normalInput.tangentWS, positionWS.y);
				o.tSpace2 = float4( normalInput.bitangentWS, positionWS.z);

				#if defined(LIGHTMAP_ON)
					OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				#endif

				#if !defined(LIGHTMAP_ON)
					OUTPUT_SH( normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz );
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					o.dynamicLightmapUV.xy = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					o.lightmapUVOrVertexSH.zw = v.texcoord.xy;
					o.lightmapUVOrVertexSH.xy = v.texcoord.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				half3 vertexLight = VertexLighting( positionWS, normalInput.normalWS );

				#ifdef ASE_FOG
					half fogFactor = ComputeFogFactor( positionCS.z );
				#else
					half fogFactor = 0;
				#endif

				o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;
				o.clipPosV = positionCS;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_tangent = v.ase_tangent;
				o.texcoord = v.texcoord;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						#ifdef _WRITE_RENDERING_LAYERS
						, out float4 outRenderingLayers : SV_Target1
						#endif
						 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.clipPos );
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float2 sampleCoords = (IN.lightmapUVOrVertexSH.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					float3 WorldNormal = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					float3 WorldTangent = -cross(GetObjectToWorldMatrix()._13_23_33, WorldNormal);
					float3 WorldBiTangent = cross(WorldNormal, -WorldTangent);
				#else
					float3 WorldNormal = normalize( IN.tSpace0.xyz );
					float3 WorldTangent = IN.tSpace1.xyz;
					float3 WorldBiTangent = IN.tSpace2.xyz;
				#endif

				float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				float4 ClipPos = IN.clipPosV;
				float4 ScreenPos = ComputeScreenPos( IN.clipPosV );

				float2 NormalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.clipPos);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#endif

				WorldViewDirection = SafeNormalize( WorldViewDirection );

				float4 ase_screenPosNorm = ScreenPos / ScreenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float2 texCoord35_g1 = IN.ase_texcoord8.xy * float2( 1,1 ) + float2( 0,0 );
				float2 uv_FlowMap11 = IN.ase_texcoord8.xy;
				float3 FlowMapUnpacked14 = ( UnpackNormalScale( tex2D( _FlowMap, uv_FlowMap11 ), 1.0f ) * _FlowStrenght );
				float2 temp_output_14_0_g1 = ( FlowMapUnpacked14.xy * 1.0 );
				float mulTime5_g1 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g1 = frac( mulTime5_g1 );
				float2 temp_output_18_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * temp_output_7_0_g1 ) );
				float temp_output_48_0_g1 = _TileScale;
				float temp_output_49_0_g1 = 0.0;
				float temp_output_53_0_g1 = _NormalStrenght;
				float3 unpack37_g1 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_18_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1) ), temp_output_53_0_g1 );
				unpack37_g1.z = lerp( 1, unpack37_g1.z, saturate(temp_output_53_0_g1) );
				float2 temp_output_19_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * frac( ( mulTime5_g1 + 0.5 ) ) ) );
				float3 unpack41_g1 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_19_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1) ), temp_output_53_0_g1 );
				unpack41_g1.z = lerp( 1, unpack41_g1.z, saturate(temp_output_53_0_g1) );
				float temp_output_17_0_g1 = abs( ( ( temp_output_7_0_g1 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g1 = lerp( unpack37_g1 , unpack41_g1 , temp_output_17_0_g1);
				float2 texCoord35_g2 = IN.ase_texcoord8.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_cast_2 = (_TileScale2).xx;
				float2 texCoord104 = IN.ase_texcoord8.xy * temp_cast_2 + float2( 0,0 );
				float mulTime108 = _TimeParameters.x * 0.1;
				float cos106 = cos( mulTime108 );
				float sin106 = sin( mulTime108 );
				float2 rotator106 = mul( texCoord104 - float2( 0.5,0.5 ) , float2x2( cos106 , -sin106 , sin106 , cos106 )) + float2( 0.5,0.5 );
				float3 unpack101 = UnpackNormalScale( tex2D( _WaterNormalMap, rotator106 ), _Normal2Strenght );
				unpack101.z = lerp( 1, unpack101.z, saturate(_Normal2Strenght) );
				float2 temp_output_14_0_g2 = ( unpack101.xy * 1.0 );
				float mulTime5_g2 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g2 = frac( mulTime5_g2 );
				float2 temp_output_18_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * temp_output_7_0_g2 ) );
				float temp_output_48_0_g2 = _TileScale2;
				float temp_output_49_0_g2 = 0.0;
				float temp_output_53_0_g2 = _Normal2Strenght;
				float3 unpack37_g2 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_18_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2) ), temp_output_53_0_g2 );
				unpack37_g2.z = lerp( 1, unpack37_g2.z, saturate(temp_output_53_0_g2) );
				float2 temp_output_19_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * frac( ( mulTime5_g2 + 0.5 ) ) ) );
				float3 unpack41_g2 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_19_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2) ), temp_output_53_0_g2 );
				unpack41_g2.z = lerp( 1, unpack41_g2.z, saturate(temp_output_53_0_g2) );
				float temp_output_17_0_g2 = abs( ( ( temp_output_7_0_g2 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g2 = lerp( unpack37_g2 , unpack41_g2 , temp_output_17_0_g2);
				float3 Normal100 = BlendNormal( lerpResult22_g1 , lerpResult22_g2 );
				float3 ScreenUV21 = ( float3( (ase_screenPosNorm).xy ,  0.0 ) + ( Normal100 * _DistortionStrenght ) );
				float4 fetchOpaqueVal16 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( ScreenUV21.xy ), 1.0 );
				float4 ScreenColor17 = fetchOpaqueVal16;
				float screenDepth115 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth115 = abs( ( screenDepth115 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _SceneDepth ) );
				float4 lerpResult114 = lerp( ScreenColor17 , _WaterColor , saturate( distanceDepth115 ));
				float4 Final_Water_Color116 = lerpResult114;
				
				float DepthFade121 = distanceDepth115;
				

				float3 BaseColor = Final_Water_Color116.rgb;
				float3 Normal = Normal100;
				float3 Emission = 0;
				float3 Specular = 0.5;
				float Metallic = 0.0;
				float Smoothness = 0.98;
				float Occlusion = 1;
				float Alpha = DepthFade121;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;

				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = IN.clipPos.z;
				#endif

				#ifdef _CLEARCOAT
					float CoatMask = 0;
					float CoatSmoothness = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				InputData inputData = (InputData)0;
				inputData.positionWS = WorldPosition;
				inputData.viewDirectionWS = WorldViewDirection;

				#ifdef _NORMALMAP
						#if _NORMAL_DROPOFF_TS
							inputData.normalWS = TransformTangentToWorld(Normal, half3x3(WorldTangent, WorldBiTangent, WorldNormal));
						#elif _NORMAL_DROPOFF_OS
							inputData.normalWS = TransformObjectToWorldNormal(Normal);
						#elif _NORMAL_DROPOFF_WS
							inputData.normalWS = Normal;
						#endif
					inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				#else
					inputData.normalWS = WorldNormal;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					inputData.shadowCoord = ShadowCoords;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
				#else
					inputData.shadowCoord = float4(0, 0, 0, 0);
				#endif

				#ifdef ASE_FOG
					inputData.fogCoord = IN.fogFactorAndVertexLight.x;
				#endif
					inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					float3 SH = IN.lightmapUVOrVertexSH.xyz;
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					inputData.bakedGI = SAMPLE_GI(IN.lightmapUVOrVertexSH.xy, IN.dynamicLightmapUV.xy, SH, inputData.normalWS);
				#else
					inputData.bakedGI = SAMPLE_GI(IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS);
				#endif

				#ifdef ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#endif

				inputData.normalizedScreenSpaceUV = NormalizedScreenSpaceUV;
				inputData.shadowMask = SAMPLE_SHADOWMASK(IN.lightmapUVOrVertexSH.xy);

				#if defined(DEBUG_DISPLAY)
					#if defined(DYNAMICLIGHTMAP_ON)
						inputData.dynamicLightmapUV = IN.dynamicLightmapUV.xy;
					#endif
					#if defined(LIGHTMAP_ON)
						inputData.staticLightmapUV = IN.lightmapUVOrVertexSH.xy;
					#else
						inputData.vertexSH = SH;
					#endif
				#endif

				SurfaceData surfaceData;
				surfaceData.albedo              = BaseColor;
				surfaceData.metallic            = saturate(Metallic);
				surfaceData.specular            = Specular;
				surfaceData.smoothness          = saturate(Smoothness),
				surfaceData.occlusion           = Occlusion,
				surfaceData.emission            = Emission,
				surfaceData.alpha               = saturate(Alpha);
				surfaceData.normalTS            = Normal;
				surfaceData.clearCoatMask       = 0;
				surfaceData.clearCoatSmoothness = 1;

				#ifdef _CLEARCOAT
					surfaceData.clearCoatMask       = saturate(CoatMask);
					surfaceData.clearCoatSmoothness = saturate(CoatSmoothness);
				#endif

				#ifdef _DBUFFER
					ApplyDecalToSurfaceData(IN.clipPos, surfaceData, inputData);
				#endif

				half4 color = UniversalFragmentPBR( inputData, surfaceData);

				#ifdef ASE_TRANSMISSION
				{
					float shadow = _TransmissionShadow;

					#define SUM_LIGHT_TRANSMISSION(Light)\
						float3 atten = Light.color * Light.distanceAttenuation;\
						atten = lerp( atten, atten * Light.shadowAttenuation, shadow );\
						half3 transmission = max( 0, -dot( inputData.normalWS, Light.direction ) ) * atten * Transmission;\
						color.rgb += BaseColor * transmission;

					SUM_LIGHT_TRANSMISSION( GetMainLight( inputData.shadowCoord ) );

					#if defined(_ADDITIONAL_LIGHTS)
						uint meshRenderingLayers = GetMeshRenderingLayer();
						uint pixelLightCount = GetAdditionalLightsCount();
						#if USE_FORWARD_PLUS
							for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
							{
								FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

								Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
								#ifdef _LIGHT_LAYERS
								if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
								#endif
								{
									SUM_LIGHT_TRANSMISSION( light );
								}
							}
						#endif
						LIGHT_LOOP_BEGIN( pixelLightCount )
							Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
							#ifdef _LIGHT_LAYERS
							if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
							#endif
							{
								SUM_LIGHT_TRANSMISSION( light );
							}
						LIGHT_LOOP_END
					#endif
				}
				#endif

				#ifdef ASE_TRANSLUCENCY
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

					#define SUM_LIGHT_TRANSLUCENCY(Light)\
						float3 atten = Light.color * Light.distanceAttenuation;\
						atten = lerp( atten, atten * Light.shadowAttenuation, shadow );\
						half3 lightDir = Light.direction + inputData.normalWS * normal;\
						half VdotL = pow( saturate( dot( inputData.viewDirectionWS, -lightDir ) ), scattering );\
						half3 translucency = atten * ( VdotL * direct + inputData.bakedGI * ambient ) * Translucency;\
						color.rgb += BaseColor * translucency * strength;

					SUM_LIGHT_TRANSLUCENCY( GetMainLight( inputData.shadowCoord ) );

					#if defined(_ADDITIONAL_LIGHTS)
						uint meshRenderingLayers = GetMeshRenderingLayer();
						uint pixelLightCount = GetAdditionalLightsCount();
						#if USE_FORWARD_PLUS
							for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
							{
								FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

								Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
								#ifdef _LIGHT_LAYERS
								if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
								#endif
								{
									SUM_LIGHT_TRANSLUCENCY( light );
								}
							}
						#endif
						LIGHT_LOOP_BEGIN( pixelLightCount )
							Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
							#ifdef _LIGHT_LAYERS
							if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
							#endif
							{
								SUM_LIGHT_TRANSLUCENCY( light );
							}
						LIGHT_LOOP_END
					#endif
				}
				#endif

				#ifdef ASE_REFRACTION
					float4 projScreenPos = ScreenPos / ScreenPos.w;
					float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, float4( WorldNormal,0 ) ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
					projScreenPos.xy += refractionOffset.xy;
					float3 refraction = SHADERGRAPH_SAMPLE_SCENE_COLOR( projScreenPos.xy ) * RefractionColor;
					color.rgb = lerp( refraction, color.rgb, color.a );
					color.a = 1;
				#endif

				#ifdef ASE_FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif

				#ifdef ASE_FOG
					#ifdef TERRAIN_SPLAT_ADDPASS
						color.rgb = MixFogColor(color.rgb, half3( 0, 0, 0 ), IN.fogFactorAndVertexLight.x );
					#else
						color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
					#endif
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif

				return color;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask R
			AlphaToMask Off

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#define ASE_FOG 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#pragma multi_compile_instancing
			#define _RECEIVE_SHADOWS_OFF 1
			#pragma multi_compile _ DEBUG_DISPLAY
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_DISTANCE_TESSELLATION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140008
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
			
			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_SCREEN_POSITION


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				ASE_SV_POSITION_QUALIFIERS float4 clipPos : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD1;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD2;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _WaterColor;
			float _Height;
			float _FlowStrenght;
			float _FlowSpeed;
			float _TileScale;
			float _NormalStrenght;
			float _TileScale2;
			float _Normal2Strenght;
			float _DistortionStrenght;
			float _SceneDepth;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _WaterNormalMap;
			sampler2D _FlowMap;
			uniform float4 _CameraDepthTexture_TexelSize;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 texCoord35_g1 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 uv_FlowMap11 = v.ase_texcoord.xy;
				float3 FlowMapUnpacked14 = ( UnpackNormalScale( tex2Dlod( _FlowMap, float4( uv_FlowMap11, 0, 0.0) ), 1.0f ) * _FlowStrenght );
				float2 temp_output_14_0_g1 = ( FlowMapUnpacked14.xy * 1.0 );
				float mulTime5_g1 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g1 = frac( mulTime5_g1 );
				float2 temp_output_18_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * temp_output_7_0_g1 ) );
				float temp_output_48_0_g1 = _TileScale;
				float temp_output_49_0_g1 = 0.0;
				float temp_output_53_0_g1 = _NormalStrenght;
				float3 unpack37_g1 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_18_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1), 0, 0.0) ), temp_output_53_0_g1 );
				unpack37_g1.z = lerp( 1, unpack37_g1.z, saturate(temp_output_53_0_g1) );
				float2 temp_output_19_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * frac( ( mulTime5_g1 + 0.5 ) ) ) );
				float3 unpack41_g1 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_19_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1), 0, 0.0) ), temp_output_53_0_g1 );
				unpack41_g1.z = lerp( 1, unpack41_g1.z, saturate(temp_output_53_0_g1) );
				float temp_output_17_0_g1 = abs( ( ( temp_output_7_0_g1 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g1 = lerp( unpack37_g1 , unpack41_g1 , temp_output_17_0_g1);
				float2 texCoord35_g2 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_cast_1 = (_TileScale2).xx;
				float2 texCoord104 = v.ase_texcoord.xy * temp_cast_1 + float2( 0,0 );
				float mulTime108 = _TimeParameters.x * 0.1;
				float cos106 = cos( mulTime108 );
				float sin106 = sin( mulTime108 );
				float2 rotator106 = mul( texCoord104 - float2( 0.5,0.5 ) , float2x2( cos106 , -sin106 , sin106 , cos106 )) + float2( 0.5,0.5 );
				float3 unpack101 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( rotator106, 0, 0.0) ), _Normal2Strenght );
				unpack101.z = lerp( 1, unpack101.z, saturate(_Normal2Strenght) );
				float2 temp_output_14_0_g2 = ( unpack101.xy * 1.0 );
				float mulTime5_g2 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g2 = frac( mulTime5_g2 );
				float2 temp_output_18_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * temp_output_7_0_g2 ) );
				float temp_output_48_0_g2 = _TileScale2;
				float temp_output_49_0_g2 = 0.0;
				float temp_output_53_0_g2 = _Normal2Strenght;
				float3 unpack37_g2 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_18_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2), 0, 0.0) ), temp_output_53_0_g2 );
				unpack37_g2.z = lerp( 1, unpack37_g2.z, saturate(temp_output_53_0_g2) );
				float2 temp_output_19_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * frac( ( mulTime5_g2 + 0.5 ) ) ) );
				float3 unpack41_g2 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_19_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2), 0, 0.0) ), temp_output_53_0_g2 );
				unpack41_g2.z = lerp( 1, unpack41_g2.z, saturate(temp_output_53_0_g2) );
				float temp_output_17_0_g2 = abs( ( ( temp_output_7_0_g2 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g2 = lerp( unpack37_g2 , unpack41_g2 , temp_output_17_0_g2);
				float3 Normal100 = BlendNormal( lerpResult22_g1 , lerpResult22_g2 );
				float dotResult188 = dot( Normal100 , float3(1,1,0) );
				float3 Displace162 = ( ( v.ase_normal * _Height ) * dotResult188 );
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = Displace162;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;
				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;
				o.clipPosV = positionCS;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(	VertexOutput IN
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				float4 ClipPos = IN.clipPosV;
				float4 ScreenPos = ComputeScreenPos( IN.clipPosV );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float4 ase_screenPosNorm = ScreenPos / ScreenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth115 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth115 = abs( ( screenDepth115 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _SceneDepth ) );
				float DepthFade121 = distanceDepth115;
				

				float Alpha = DepthFade121;
				float AlphaClipThreshold = 0.5;
				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = IN.clipPos.z;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.clipPos );
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "Meta"
			Tags { "LightMode"="Meta" }

			Cull Off

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _RECEIVE_SHADOWS_OFF 1
			#pragma multi_compile _ DEBUG_DISPLAY
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_DISTANCE_TESSELLATION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140008
			#define REQUIRE_OPAQUE_TEXTURE 1
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature EDITOR_VISUALIZATION

			#define SHADERPASS SHADERPASS_META

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_VERT_NORMAL


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 texcoord0 : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef EDITOR_VISUALIZATION
					float4 VizUV : TEXCOORD2;
					float4 LightCoord : TEXCOORD3;
				#endif
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _WaterColor;
			float _Height;
			float _FlowStrenght;
			float _FlowSpeed;
			float _TileScale;
			float _NormalStrenght;
			float _TileScale2;
			float _Normal2Strenght;
			float _DistortionStrenght;
			float _SceneDepth;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _WaterNormalMap;
			sampler2D _FlowMap;
			uniform float4 _CameraDepthTexture_TexelSize;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 texCoord35_g1 = v.texcoord0.xy * float2( 1,1 ) + float2( 0,0 );
				float2 uv_FlowMap11 = v.texcoord0.xy;
				float3 FlowMapUnpacked14 = ( UnpackNormalScale( tex2Dlod( _FlowMap, float4( uv_FlowMap11, 0, 0.0) ), 1.0f ) * _FlowStrenght );
				float2 temp_output_14_0_g1 = ( FlowMapUnpacked14.xy * 1.0 );
				float mulTime5_g1 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g1 = frac( mulTime5_g1 );
				float2 temp_output_18_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * temp_output_7_0_g1 ) );
				float temp_output_48_0_g1 = _TileScale;
				float temp_output_49_0_g1 = 0.0;
				float temp_output_53_0_g1 = _NormalStrenght;
				float3 unpack37_g1 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_18_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1), 0, 0.0) ), temp_output_53_0_g1 );
				unpack37_g1.z = lerp( 1, unpack37_g1.z, saturate(temp_output_53_0_g1) );
				float2 temp_output_19_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * frac( ( mulTime5_g1 + 0.5 ) ) ) );
				float3 unpack41_g1 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_19_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1), 0, 0.0) ), temp_output_53_0_g1 );
				unpack41_g1.z = lerp( 1, unpack41_g1.z, saturate(temp_output_53_0_g1) );
				float temp_output_17_0_g1 = abs( ( ( temp_output_7_0_g1 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g1 = lerp( unpack37_g1 , unpack41_g1 , temp_output_17_0_g1);
				float2 texCoord35_g2 = v.texcoord0.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_cast_1 = (_TileScale2).xx;
				float2 texCoord104 = v.texcoord0.xy * temp_cast_1 + float2( 0,0 );
				float mulTime108 = _TimeParameters.x * 0.1;
				float cos106 = cos( mulTime108 );
				float sin106 = sin( mulTime108 );
				float2 rotator106 = mul( texCoord104 - float2( 0.5,0.5 ) , float2x2( cos106 , -sin106 , sin106 , cos106 )) + float2( 0.5,0.5 );
				float3 unpack101 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( rotator106, 0, 0.0) ), _Normal2Strenght );
				unpack101.z = lerp( 1, unpack101.z, saturate(_Normal2Strenght) );
				float2 temp_output_14_0_g2 = ( unpack101.xy * 1.0 );
				float mulTime5_g2 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g2 = frac( mulTime5_g2 );
				float2 temp_output_18_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * temp_output_7_0_g2 ) );
				float temp_output_48_0_g2 = _TileScale2;
				float temp_output_49_0_g2 = 0.0;
				float temp_output_53_0_g2 = _Normal2Strenght;
				float3 unpack37_g2 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_18_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2), 0, 0.0) ), temp_output_53_0_g2 );
				unpack37_g2.z = lerp( 1, unpack37_g2.z, saturate(temp_output_53_0_g2) );
				float2 temp_output_19_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * frac( ( mulTime5_g2 + 0.5 ) ) ) );
				float3 unpack41_g2 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_19_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2), 0, 0.0) ), temp_output_53_0_g2 );
				unpack41_g2.z = lerp( 1, unpack41_g2.z, saturate(temp_output_53_0_g2) );
				float temp_output_17_0_g2 = abs( ( ( temp_output_7_0_g2 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g2 = lerp( unpack37_g2 , unpack41_g2 , temp_output_17_0_g2);
				float3 Normal100 = BlendNormal( lerpResult22_g1 , lerpResult22_g2 );
				float dotResult188 = dot( Normal100 , float3(1,1,0) );
				float3 Displace162 = ( ( v.ase_normal * _Height ) * dotResult188 );
				
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord4 = screenPos;
				
				o.ase_texcoord5.xy = v.texcoord0.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord5.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = Displace162;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				o.clipPos = MetaVertexPosition( v.vertex, v.texcoord1.xy, v.texcoord1.xy, unity_LightmapST, unity_DynamicLightmapST );

				#ifdef EDITOR_VISUALIZATION
					float2 VizUV = 0;
					float4 LightCoord = 0;
					UnityEditorVizData(v.vertex.xyz, v.texcoord0.xy, v.texcoord1.xy, v.texcoord2.xy, VizUV, LightCoord);
					o.VizUV = float4(VizUV, 0, 0);
					o.LightCoord = LightCoord;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 texcoord0 : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.texcoord0 = v.texcoord0;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.texcoord0 = patch[0].texcoord0 * bary.x + patch[1].texcoord0 * bary.y + patch[2].texcoord0 * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float4 screenPos = IN.ase_texcoord4;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float2 texCoord35_g1 = IN.ase_texcoord5.xy * float2( 1,1 ) + float2( 0,0 );
				float2 uv_FlowMap11 = IN.ase_texcoord5.xy;
				float3 FlowMapUnpacked14 = ( UnpackNormalScale( tex2D( _FlowMap, uv_FlowMap11 ), 1.0f ) * _FlowStrenght );
				float2 temp_output_14_0_g1 = ( FlowMapUnpacked14.xy * 1.0 );
				float mulTime5_g1 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g1 = frac( mulTime5_g1 );
				float2 temp_output_18_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * temp_output_7_0_g1 ) );
				float temp_output_48_0_g1 = _TileScale;
				float temp_output_49_0_g1 = 0.0;
				float temp_output_53_0_g1 = _NormalStrenght;
				float3 unpack37_g1 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_18_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1) ), temp_output_53_0_g1 );
				unpack37_g1.z = lerp( 1, unpack37_g1.z, saturate(temp_output_53_0_g1) );
				float2 temp_output_19_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * frac( ( mulTime5_g1 + 0.5 ) ) ) );
				float3 unpack41_g1 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_19_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1) ), temp_output_53_0_g1 );
				unpack41_g1.z = lerp( 1, unpack41_g1.z, saturate(temp_output_53_0_g1) );
				float temp_output_17_0_g1 = abs( ( ( temp_output_7_0_g1 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g1 = lerp( unpack37_g1 , unpack41_g1 , temp_output_17_0_g1);
				float2 texCoord35_g2 = IN.ase_texcoord5.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_cast_2 = (_TileScale2).xx;
				float2 texCoord104 = IN.ase_texcoord5.xy * temp_cast_2 + float2( 0,0 );
				float mulTime108 = _TimeParameters.x * 0.1;
				float cos106 = cos( mulTime108 );
				float sin106 = sin( mulTime108 );
				float2 rotator106 = mul( texCoord104 - float2( 0.5,0.5 ) , float2x2( cos106 , -sin106 , sin106 , cos106 )) + float2( 0.5,0.5 );
				float3 unpack101 = UnpackNormalScale( tex2D( _WaterNormalMap, rotator106 ), _Normal2Strenght );
				unpack101.z = lerp( 1, unpack101.z, saturate(_Normal2Strenght) );
				float2 temp_output_14_0_g2 = ( unpack101.xy * 1.0 );
				float mulTime5_g2 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g2 = frac( mulTime5_g2 );
				float2 temp_output_18_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * temp_output_7_0_g2 ) );
				float temp_output_48_0_g2 = _TileScale2;
				float temp_output_49_0_g2 = 0.0;
				float temp_output_53_0_g2 = _Normal2Strenght;
				float3 unpack37_g2 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_18_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2) ), temp_output_53_0_g2 );
				unpack37_g2.z = lerp( 1, unpack37_g2.z, saturate(temp_output_53_0_g2) );
				float2 temp_output_19_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * frac( ( mulTime5_g2 + 0.5 ) ) ) );
				float3 unpack41_g2 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_19_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2) ), temp_output_53_0_g2 );
				unpack41_g2.z = lerp( 1, unpack41_g2.z, saturate(temp_output_53_0_g2) );
				float temp_output_17_0_g2 = abs( ( ( temp_output_7_0_g2 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g2 = lerp( unpack37_g2 , unpack41_g2 , temp_output_17_0_g2);
				float3 Normal100 = BlendNormal( lerpResult22_g1 , lerpResult22_g2 );
				float3 ScreenUV21 = ( float3( (ase_screenPosNorm).xy ,  0.0 ) + ( Normal100 * _DistortionStrenght ) );
				float4 fetchOpaqueVal16 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( ScreenUV21.xy ), 1.0 );
				float4 ScreenColor17 = fetchOpaqueVal16;
				float screenDepth115 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth115 = abs( ( screenDepth115 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _SceneDepth ) );
				float4 lerpResult114 = lerp( ScreenColor17 , _WaterColor , saturate( distanceDepth115 ));
				float4 Final_Water_Color116 = lerpResult114;
				
				float DepthFade121 = distanceDepth115;
				

				float3 BaseColor = Final_Water_Color116.rgb;
				float3 Emission = 0;
				float Alpha = DepthFade121;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				MetaInput metaInput = (MetaInput)0;
				metaInput.Albedo = BaseColor;
				metaInput.Emission = Emission;
				#ifdef EDITOR_VISUALIZATION
					metaInput.VizUV = IN.VizUV.xy;
					metaInput.LightCoord = IN.LightCoord;
				#endif

				return UnityMetaFragment(metaInput);
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "Universal2D"
			Tags { "LightMode"="Universal2D" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _RECEIVE_SHADOWS_OFF 1
			#pragma multi_compile _ DEBUG_DISPLAY
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_DISTANCE_TESSELLATION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140008
			#define REQUIRE_OPAQUE_TEXTURE 1
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_2D

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_VERT_NORMAL


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _WaterColor;
			float _Height;
			float _FlowStrenght;
			float _FlowSpeed;
			float _TileScale;
			float _NormalStrenght;
			float _TileScale2;
			float _Normal2Strenght;
			float _DistortionStrenght;
			float _SceneDepth;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _WaterNormalMap;
			sampler2D _FlowMap;
			uniform float4 _CameraDepthTexture_TexelSize;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float2 texCoord35_g1 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 uv_FlowMap11 = v.ase_texcoord.xy;
				float3 FlowMapUnpacked14 = ( UnpackNormalScale( tex2Dlod( _FlowMap, float4( uv_FlowMap11, 0, 0.0) ), 1.0f ) * _FlowStrenght );
				float2 temp_output_14_0_g1 = ( FlowMapUnpacked14.xy * 1.0 );
				float mulTime5_g1 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g1 = frac( mulTime5_g1 );
				float2 temp_output_18_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * temp_output_7_0_g1 ) );
				float temp_output_48_0_g1 = _TileScale;
				float temp_output_49_0_g1 = 0.0;
				float temp_output_53_0_g1 = _NormalStrenght;
				float3 unpack37_g1 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_18_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1), 0, 0.0) ), temp_output_53_0_g1 );
				unpack37_g1.z = lerp( 1, unpack37_g1.z, saturate(temp_output_53_0_g1) );
				float2 temp_output_19_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * frac( ( mulTime5_g1 + 0.5 ) ) ) );
				float3 unpack41_g1 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_19_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1), 0, 0.0) ), temp_output_53_0_g1 );
				unpack41_g1.z = lerp( 1, unpack41_g1.z, saturate(temp_output_53_0_g1) );
				float temp_output_17_0_g1 = abs( ( ( temp_output_7_0_g1 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g1 = lerp( unpack37_g1 , unpack41_g1 , temp_output_17_0_g1);
				float2 texCoord35_g2 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_cast_1 = (_TileScale2).xx;
				float2 texCoord104 = v.ase_texcoord.xy * temp_cast_1 + float2( 0,0 );
				float mulTime108 = _TimeParameters.x * 0.1;
				float cos106 = cos( mulTime108 );
				float sin106 = sin( mulTime108 );
				float2 rotator106 = mul( texCoord104 - float2( 0.5,0.5 ) , float2x2( cos106 , -sin106 , sin106 , cos106 )) + float2( 0.5,0.5 );
				float3 unpack101 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( rotator106, 0, 0.0) ), _Normal2Strenght );
				unpack101.z = lerp( 1, unpack101.z, saturate(_Normal2Strenght) );
				float2 temp_output_14_0_g2 = ( unpack101.xy * 1.0 );
				float mulTime5_g2 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g2 = frac( mulTime5_g2 );
				float2 temp_output_18_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * temp_output_7_0_g2 ) );
				float temp_output_48_0_g2 = _TileScale2;
				float temp_output_49_0_g2 = 0.0;
				float temp_output_53_0_g2 = _Normal2Strenght;
				float3 unpack37_g2 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_18_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2), 0, 0.0) ), temp_output_53_0_g2 );
				unpack37_g2.z = lerp( 1, unpack37_g2.z, saturate(temp_output_53_0_g2) );
				float2 temp_output_19_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * frac( ( mulTime5_g2 + 0.5 ) ) ) );
				float3 unpack41_g2 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_19_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2), 0, 0.0) ), temp_output_53_0_g2 );
				unpack41_g2.z = lerp( 1, unpack41_g2.z, saturate(temp_output_53_0_g2) );
				float temp_output_17_0_g2 = abs( ( ( temp_output_7_0_g2 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g2 = lerp( unpack37_g2 , unpack41_g2 , temp_output_17_0_g2);
				float3 Normal100 = BlendNormal( lerpResult22_g1 , lerpResult22_g2 );
				float dotResult188 = dot( Normal100 , float3(1,1,0) );
				float3 Displace162 = ( ( v.ase_normal * _Height ) * dotResult188 );
				
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord2 = screenPos;
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = Displace162;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float4 screenPos = IN.ase_texcoord2;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float2 texCoord35_g1 = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float2 uv_FlowMap11 = IN.ase_texcoord3.xy;
				float3 FlowMapUnpacked14 = ( UnpackNormalScale( tex2D( _FlowMap, uv_FlowMap11 ), 1.0f ) * _FlowStrenght );
				float2 temp_output_14_0_g1 = ( FlowMapUnpacked14.xy * 1.0 );
				float mulTime5_g1 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g1 = frac( mulTime5_g1 );
				float2 temp_output_18_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * temp_output_7_0_g1 ) );
				float temp_output_48_0_g1 = _TileScale;
				float temp_output_49_0_g1 = 0.0;
				float temp_output_53_0_g1 = _NormalStrenght;
				float3 unpack37_g1 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_18_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1) ), temp_output_53_0_g1 );
				unpack37_g1.z = lerp( 1, unpack37_g1.z, saturate(temp_output_53_0_g1) );
				float2 temp_output_19_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * frac( ( mulTime5_g1 + 0.5 ) ) ) );
				float3 unpack41_g1 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_19_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1) ), temp_output_53_0_g1 );
				unpack41_g1.z = lerp( 1, unpack41_g1.z, saturate(temp_output_53_0_g1) );
				float temp_output_17_0_g1 = abs( ( ( temp_output_7_0_g1 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g1 = lerp( unpack37_g1 , unpack41_g1 , temp_output_17_0_g1);
				float2 texCoord35_g2 = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_cast_2 = (_TileScale2).xx;
				float2 texCoord104 = IN.ase_texcoord3.xy * temp_cast_2 + float2( 0,0 );
				float mulTime108 = _TimeParameters.x * 0.1;
				float cos106 = cos( mulTime108 );
				float sin106 = sin( mulTime108 );
				float2 rotator106 = mul( texCoord104 - float2( 0.5,0.5 ) , float2x2( cos106 , -sin106 , sin106 , cos106 )) + float2( 0.5,0.5 );
				float3 unpack101 = UnpackNormalScale( tex2D( _WaterNormalMap, rotator106 ), _Normal2Strenght );
				unpack101.z = lerp( 1, unpack101.z, saturate(_Normal2Strenght) );
				float2 temp_output_14_0_g2 = ( unpack101.xy * 1.0 );
				float mulTime5_g2 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g2 = frac( mulTime5_g2 );
				float2 temp_output_18_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * temp_output_7_0_g2 ) );
				float temp_output_48_0_g2 = _TileScale2;
				float temp_output_49_0_g2 = 0.0;
				float temp_output_53_0_g2 = _Normal2Strenght;
				float3 unpack37_g2 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_18_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2) ), temp_output_53_0_g2 );
				unpack37_g2.z = lerp( 1, unpack37_g2.z, saturate(temp_output_53_0_g2) );
				float2 temp_output_19_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * frac( ( mulTime5_g2 + 0.5 ) ) ) );
				float3 unpack41_g2 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_19_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2) ), temp_output_53_0_g2 );
				unpack41_g2.z = lerp( 1, unpack41_g2.z, saturate(temp_output_53_0_g2) );
				float temp_output_17_0_g2 = abs( ( ( temp_output_7_0_g2 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g2 = lerp( unpack37_g2 , unpack41_g2 , temp_output_17_0_g2);
				float3 Normal100 = BlendNormal( lerpResult22_g1 , lerpResult22_g2 );
				float3 ScreenUV21 = ( float3( (ase_screenPosNorm).xy ,  0.0 ) + ( Normal100 * _DistortionStrenght ) );
				float4 fetchOpaqueVal16 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( ScreenUV21.xy ), 1.0 );
				float4 ScreenColor17 = fetchOpaqueVal16;
				float screenDepth115 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth115 = abs( ( screenDepth115 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _SceneDepth ) );
				float4 lerpResult114 = lerp( ScreenColor17 , _WaterColor , saturate( distanceDepth115 ));
				float4 Final_Water_Color116 = lerpResult114;
				
				float DepthFade121 = distanceDepth115;
				

				float3 BaseColor = Final_Water_Color116.rgb;
				float Alpha = DepthFade121;
				float AlphaClipThreshold = 0.5;

				half4 color = half4(BaseColor, Alpha );

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				return color;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormals" }

			ZWrite On
			Blend One Zero
			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#define ASE_FOG 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#pragma multi_compile_instancing
			#define _RECEIVE_SHADOWS_OFF 1
			#pragma multi_compile _ DEBUG_DISPLAY
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_DISTANCE_TESSELLATION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140008
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_SCREEN_POSITION


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				ASE_SV_POSITION_QUALIFIERS float4 clipPos : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float4 worldTangent : TEXCOORD2;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD3;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD4;
				#endif
				float4 ase_texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _WaterColor;
			float _Height;
			float _FlowStrenght;
			float _FlowSpeed;
			float _TileScale;
			float _NormalStrenght;
			float _TileScale2;
			float _Normal2Strenght;
			float _DistortionStrenght;
			float _SceneDepth;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _WaterNormalMap;
			sampler2D _FlowMap;
			uniform float4 _CameraDepthTexture_TexelSize;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 texCoord35_g1 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 uv_FlowMap11 = v.ase_texcoord.xy;
				float3 FlowMapUnpacked14 = ( UnpackNormalScale( tex2Dlod( _FlowMap, float4( uv_FlowMap11, 0, 0.0) ), 1.0f ) * _FlowStrenght );
				float2 temp_output_14_0_g1 = ( FlowMapUnpacked14.xy * 1.0 );
				float mulTime5_g1 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g1 = frac( mulTime5_g1 );
				float2 temp_output_18_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * temp_output_7_0_g1 ) );
				float temp_output_48_0_g1 = _TileScale;
				float temp_output_49_0_g1 = 0.0;
				float temp_output_53_0_g1 = _NormalStrenght;
				float3 unpack37_g1 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_18_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1), 0, 0.0) ), temp_output_53_0_g1 );
				unpack37_g1.z = lerp( 1, unpack37_g1.z, saturate(temp_output_53_0_g1) );
				float2 temp_output_19_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * frac( ( mulTime5_g1 + 0.5 ) ) ) );
				float3 unpack41_g1 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_19_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1), 0, 0.0) ), temp_output_53_0_g1 );
				unpack41_g1.z = lerp( 1, unpack41_g1.z, saturate(temp_output_53_0_g1) );
				float temp_output_17_0_g1 = abs( ( ( temp_output_7_0_g1 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g1 = lerp( unpack37_g1 , unpack41_g1 , temp_output_17_0_g1);
				float2 texCoord35_g2 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_cast_1 = (_TileScale2).xx;
				float2 texCoord104 = v.ase_texcoord.xy * temp_cast_1 + float2( 0,0 );
				float mulTime108 = _TimeParameters.x * 0.1;
				float cos106 = cos( mulTime108 );
				float sin106 = sin( mulTime108 );
				float2 rotator106 = mul( texCoord104 - float2( 0.5,0.5 ) , float2x2( cos106 , -sin106 , sin106 , cos106 )) + float2( 0.5,0.5 );
				float3 unpack101 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( rotator106, 0, 0.0) ), _Normal2Strenght );
				unpack101.z = lerp( 1, unpack101.z, saturate(_Normal2Strenght) );
				float2 temp_output_14_0_g2 = ( unpack101.xy * 1.0 );
				float mulTime5_g2 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g2 = frac( mulTime5_g2 );
				float2 temp_output_18_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * temp_output_7_0_g2 ) );
				float temp_output_48_0_g2 = _TileScale2;
				float temp_output_49_0_g2 = 0.0;
				float temp_output_53_0_g2 = _Normal2Strenght;
				float3 unpack37_g2 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_18_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2), 0, 0.0) ), temp_output_53_0_g2 );
				unpack37_g2.z = lerp( 1, unpack37_g2.z, saturate(temp_output_53_0_g2) );
				float2 temp_output_19_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * frac( ( mulTime5_g2 + 0.5 ) ) ) );
				float3 unpack41_g2 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_19_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2), 0, 0.0) ), temp_output_53_0_g2 );
				unpack41_g2.z = lerp( 1, unpack41_g2.z, saturate(temp_output_53_0_g2) );
				float temp_output_17_0_g2 = abs( ( ( temp_output_7_0_g2 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g2 = lerp( unpack37_g2 , unpack41_g2 , temp_output_17_0_g2);
				float3 Normal100 = BlendNormal( lerpResult22_g1 , lerpResult22_g2 );
				float dotResult188 = dot( Normal100 , float3(1,1,0) );
				float3 Displace162 = ( ( v.ase_normal * _Height ) * dotResult188 );
				
				o.ase_texcoord5.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord5.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = Displace162;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;
				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 normalWS = TransformObjectToWorldNormal( v.ase_normal );
				float4 tangentWS = float4(TransformObjectToWorldDir( v.ase_tangent.xyz), v.ase_tangent.w);
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				o.worldNormal = normalWS;
				o.worldTangent = tangentWS;

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;
				o.clipPosV = positionCS;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_tangent = v.ase_tangent;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			void frag(	VertexOutput IN
						, out half4 outNormalWS : SV_Target0
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						#ifdef _WRITE_RENDERING_LAYERS
						, out float4 outRenderingLayers : SV_Target1
						#endif
						 )
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				float3 WorldNormal = IN.worldNormal;
				float4 WorldTangent = IN.worldTangent;

				float4 ClipPos = IN.clipPosV;
				float4 ScreenPos = ComputeScreenPos( IN.clipPosV );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float2 texCoord35_g1 = IN.ase_texcoord5.xy * float2( 1,1 ) + float2( 0,0 );
				float2 uv_FlowMap11 = IN.ase_texcoord5.xy;
				float3 FlowMapUnpacked14 = ( UnpackNormalScale( tex2D( _FlowMap, uv_FlowMap11 ), 1.0f ) * _FlowStrenght );
				float2 temp_output_14_0_g1 = ( FlowMapUnpacked14.xy * 1.0 );
				float mulTime5_g1 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g1 = frac( mulTime5_g1 );
				float2 temp_output_18_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * temp_output_7_0_g1 ) );
				float temp_output_48_0_g1 = _TileScale;
				float temp_output_49_0_g1 = 0.0;
				float temp_output_53_0_g1 = _NormalStrenght;
				float3 unpack37_g1 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_18_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1) ), temp_output_53_0_g1 );
				unpack37_g1.z = lerp( 1, unpack37_g1.z, saturate(temp_output_53_0_g1) );
				float2 temp_output_19_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * frac( ( mulTime5_g1 + 0.5 ) ) ) );
				float3 unpack41_g1 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_19_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1) ), temp_output_53_0_g1 );
				unpack41_g1.z = lerp( 1, unpack41_g1.z, saturate(temp_output_53_0_g1) );
				float temp_output_17_0_g1 = abs( ( ( temp_output_7_0_g1 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g1 = lerp( unpack37_g1 , unpack41_g1 , temp_output_17_0_g1);
				float2 texCoord35_g2 = IN.ase_texcoord5.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_cast_1 = (_TileScale2).xx;
				float2 texCoord104 = IN.ase_texcoord5.xy * temp_cast_1 + float2( 0,0 );
				float mulTime108 = _TimeParameters.x * 0.1;
				float cos106 = cos( mulTime108 );
				float sin106 = sin( mulTime108 );
				float2 rotator106 = mul( texCoord104 - float2( 0.5,0.5 ) , float2x2( cos106 , -sin106 , sin106 , cos106 )) + float2( 0.5,0.5 );
				float3 unpack101 = UnpackNormalScale( tex2D( _WaterNormalMap, rotator106 ), _Normal2Strenght );
				unpack101.z = lerp( 1, unpack101.z, saturate(_Normal2Strenght) );
				float2 temp_output_14_0_g2 = ( unpack101.xy * 1.0 );
				float mulTime5_g2 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g2 = frac( mulTime5_g2 );
				float2 temp_output_18_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * temp_output_7_0_g2 ) );
				float temp_output_48_0_g2 = _TileScale2;
				float temp_output_49_0_g2 = 0.0;
				float temp_output_53_0_g2 = _Normal2Strenght;
				float3 unpack37_g2 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_18_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2) ), temp_output_53_0_g2 );
				unpack37_g2.z = lerp( 1, unpack37_g2.z, saturate(temp_output_53_0_g2) );
				float2 temp_output_19_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * frac( ( mulTime5_g2 + 0.5 ) ) ) );
				float3 unpack41_g2 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_19_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2) ), temp_output_53_0_g2 );
				unpack41_g2.z = lerp( 1, unpack41_g2.z, saturate(temp_output_53_0_g2) );
				float temp_output_17_0_g2 = abs( ( ( temp_output_7_0_g2 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g2 = lerp( unpack37_g2 , unpack41_g2 , temp_output_17_0_g2);
				float3 Normal100 = BlendNormal( lerpResult22_g1 , lerpResult22_g2 );
				
				float4 ase_screenPosNorm = ScreenPos / ScreenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth115 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth115 = abs( ( screenDepth115 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _SceneDepth ) );
				float DepthFade121 = distanceDepth115;
				

				float3 Normal = Normal100;
				float Alpha = DepthFade121;
				float AlphaClipThreshold = 0.5;
				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = IN.clipPos.z;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.clipPos );
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				#if defined(_GBUFFER_NORMALS_OCT)
					float2 octNormalWS = PackNormalOctQuadEncode(WorldNormal);
					float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);
					half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);
					outNormalWS = half4(packedNormalWS, 0.0);
				#else
					#if defined(_NORMALMAP)
						#if _NORMAL_DROPOFF_TS
							float crossSign = (WorldTangent.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
							float3 bitangent = crossSign * cross(WorldNormal.xyz, WorldTangent.xyz);
							float3 normalWS = TransformTangentToWorld(Normal, half3x3(WorldTangent.xyz, bitangent, WorldNormal.xyz));
						#elif _NORMAL_DROPOFF_OS
							float3 normalWS = TransformObjectToWorldNormal(Normal);
						#elif _NORMAL_DROPOFF_WS
							float3 normalWS = Normal;
						#endif
					#else
						float3 normalWS = WorldNormal;
					#endif
					outNormalWS = half4(NormalizeNormalPerPixel(normalWS), 0.0);
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "GBuffer"
			Tags { "LightMode"="UniversalGBuffer" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#define _RECEIVE_SHADOWS_OFF 1
			#pragma multi_compile _ DEBUG_DISPLAY
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_DISTANCE_TESSELLATION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140008
			#define REQUIRE_OPAQUE_TEXTURE 1
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
			#pragma multi_compile_fragment _ _SHADOWS_SOFT
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
			#pragma multi_compile_fragment _ _RENDER_PASS_ENABLED

			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
			#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_GBUFFER

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif
			
			#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
				#define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_SCREEN_POSITION


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				ASE_SV_POSITION_QUALIFIERS float4 clipPos : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				float4 lightmapUVOrVertexSH : TEXCOORD1;
				half4 fogFactorAndVertexLight : TEXCOORD2;
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord : TEXCOORD6;
				#endif
				#if defined(DYNAMICLIGHTMAP_ON)
				float2 dynamicLightmapUV : TEXCOORD7;
				#endif
				float4 ase_texcoord8 : TEXCOORD8;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _WaterColor;
			float _Height;
			float _FlowStrenght;
			float _FlowSpeed;
			float _TileScale;
			float _NormalStrenght;
			float _TileScale2;
			float _Normal2Strenght;
			float _DistortionStrenght;
			float _SceneDepth;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _WaterNormalMap;
			sampler2D _FlowMap;
			uniform float4 _CameraDepthTexture_TexelSize;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRGBufferPass.hlsl"

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 texCoord35_g1 = v.texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 uv_FlowMap11 = v.texcoord.xy;
				float3 FlowMapUnpacked14 = ( UnpackNormalScale( tex2Dlod( _FlowMap, float4( uv_FlowMap11, 0, 0.0) ), 1.0f ) * _FlowStrenght );
				float2 temp_output_14_0_g1 = ( FlowMapUnpacked14.xy * 1.0 );
				float mulTime5_g1 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g1 = frac( mulTime5_g1 );
				float2 temp_output_18_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * temp_output_7_0_g1 ) );
				float temp_output_48_0_g1 = _TileScale;
				float temp_output_49_0_g1 = 0.0;
				float temp_output_53_0_g1 = _NormalStrenght;
				float3 unpack37_g1 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_18_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1), 0, 0.0) ), temp_output_53_0_g1 );
				unpack37_g1.z = lerp( 1, unpack37_g1.z, saturate(temp_output_53_0_g1) );
				float2 temp_output_19_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * frac( ( mulTime5_g1 + 0.5 ) ) ) );
				float3 unpack41_g1 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_19_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1), 0, 0.0) ), temp_output_53_0_g1 );
				unpack41_g1.z = lerp( 1, unpack41_g1.z, saturate(temp_output_53_0_g1) );
				float temp_output_17_0_g1 = abs( ( ( temp_output_7_0_g1 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g1 = lerp( unpack37_g1 , unpack41_g1 , temp_output_17_0_g1);
				float2 texCoord35_g2 = v.texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_cast_1 = (_TileScale2).xx;
				float2 texCoord104 = v.texcoord.xy * temp_cast_1 + float2( 0,0 );
				float mulTime108 = _TimeParameters.x * 0.1;
				float cos106 = cos( mulTime108 );
				float sin106 = sin( mulTime108 );
				float2 rotator106 = mul( texCoord104 - float2( 0.5,0.5 ) , float2x2( cos106 , -sin106 , sin106 , cos106 )) + float2( 0.5,0.5 );
				float3 unpack101 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( rotator106, 0, 0.0) ), _Normal2Strenght );
				unpack101.z = lerp( 1, unpack101.z, saturate(_Normal2Strenght) );
				float2 temp_output_14_0_g2 = ( unpack101.xy * 1.0 );
				float mulTime5_g2 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g2 = frac( mulTime5_g2 );
				float2 temp_output_18_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * temp_output_7_0_g2 ) );
				float temp_output_48_0_g2 = _TileScale2;
				float temp_output_49_0_g2 = 0.0;
				float temp_output_53_0_g2 = _Normal2Strenght;
				float3 unpack37_g2 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_18_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2), 0, 0.0) ), temp_output_53_0_g2 );
				unpack37_g2.z = lerp( 1, unpack37_g2.z, saturate(temp_output_53_0_g2) );
				float2 temp_output_19_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * frac( ( mulTime5_g2 + 0.5 ) ) ) );
				float3 unpack41_g2 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_19_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2), 0, 0.0) ), temp_output_53_0_g2 );
				unpack41_g2.z = lerp( 1, unpack41_g2.z, saturate(temp_output_53_0_g2) );
				float temp_output_17_0_g2 = abs( ( ( temp_output_7_0_g2 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g2 = lerp( unpack37_g2 , unpack41_g2 , temp_output_17_0_g2);
				float3 Normal100 = BlendNormal( lerpResult22_g1 , lerpResult22_g2 );
				float dotResult188 = dot( Normal100 , float3(1,1,0) );
				float3 Displace162 = ( ( v.ase_normal * _Height ) * dotResult188 );
				
				o.ase_texcoord8.xy = v.texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord8.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = Displace162;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 positionVS = TransformWorldToView( positionWS );
				float4 positionCS = TransformWorldToHClip( positionWS );

				VertexNormalInputs normalInput = GetVertexNormalInputs( v.ase_normal, v.ase_tangent );

				o.tSpace0 = float4( normalInput.normalWS, positionWS.x);
				o.tSpace1 = float4( normalInput.tangentWS, positionWS.y);
				o.tSpace2 = float4( normalInput.bitangentWS, positionWS.z);

				#if defined(LIGHTMAP_ON)
					OUTPUT_LIGHTMAP_UV(v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy);
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					o.dynamicLightmapUV.xy = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif

				#if !defined(LIGHTMAP_ON)
					OUTPUT_SH(normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz);
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					o.lightmapUVOrVertexSH.zw = v.texcoord.xy;
					o.lightmapUVOrVertexSH.xy = v.texcoord.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				half3 vertexLight = VertexLighting( positionWS, normalInput.normalWS );

				o.fogFactorAndVertexLight = half4(0, vertexLight);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;
				o.clipPosV = positionCS;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_tangent = v.ase_tangent;
				o.texcoord = v.texcoord;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			FragmentOutput frag ( VertexOutput IN
								#ifdef ASE_DEPTH_WRITE_ON
								,out float outputDepth : ASE_SV_DEPTH
								#endif
								 )
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.clipPos );
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float2 sampleCoords = (IN.lightmapUVOrVertexSH.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					float3 WorldNormal = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					float3 WorldTangent = -cross(GetObjectToWorldMatrix()._13_23_33, WorldNormal);
					float3 WorldBiTangent = cross(WorldNormal, -WorldTangent);
				#else
					float3 WorldNormal = normalize( IN.tSpace0.xyz );
					float3 WorldTangent = IN.tSpace1.xyz;
					float3 WorldBiTangent = IN.tSpace2.xyz;
				#endif

				float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				float4 ClipPos = IN.clipPosV;
				float4 ScreenPos = ComputeScreenPos( IN.clipPosV );

				float2 NormalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.clipPos);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#else
					ShadowCoords = float4(0, 0, 0, 0);
				#endif

				WorldViewDirection = SafeNormalize( WorldViewDirection );

				float4 ase_screenPosNorm = ScreenPos / ScreenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float2 texCoord35_g1 = IN.ase_texcoord8.xy * float2( 1,1 ) + float2( 0,0 );
				float2 uv_FlowMap11 = IN.ase_texcoord8.xy;
				float3 FlowMapUnpacked14 = ( UnpackNormalScale( tex2D( _FlowMap, uv_FlowMap11 ), 1.0f ) * _FlowStrenght );
				float2 temp_output_14_0_g1 = ( FlowMapUnpacked14.xy * 1.0 );
				float mulTime5_g1 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g1 = frac( mulTime5_g1 );
				float2 temp_output_18_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * temp_output_7_0_g1 ) );
				float temp_output_48_0_g1 = _TileScale;
				float temp_output_49_0_g1 = 0.0;
				float temp_output_53_0_g1 = _NormalStrenght;
				float3 unpack37_g1 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_18_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1) ), temp_output_53_0_g1 );
				unpack37_g1.z = lerp( 1, unpack37_g1.z, saturate(temp_output_53_0_g1) );
				float2 temp_output_19_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * frac( ( mulTime5_g1 + 0.5 ) ) ) );
				float3 unpack41_g1 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_19_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1) ), temp_output_53_0_g1 );
				unpack41_g1.z = lerp( 1, unpack41_g1.z, saturate(temp_output_53_0_g1) );
				float temp_output_17_0_g1 = abs( ( ( temp_output_7_0_g1 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g1 = lerp( unpack37_g1 , unpack41_g1 , temp_output_17_0_g1);
				float2 texCoord35_g2 = IN.ase_texcoord8.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_cast_2 = (_TileScale2).xx;
				float2 texCoord104 = IN.ase_texcoord8.xy * temp_cast_2 + float2( 0,0 );
				float mulTime108 = _TimeParameters.x * 0.1;
				float cos106 = cos( mulTime108 );
				float sin106 = sin( mulTime108 );
				float2 rotator106 = mul( texCoord104 - float2( 0.5,0.5 ) , float2x2( cos106 , -sin106 , sin106 , cos106 )) + float2( 0.5,0.5 );
				float3 unpack101 = UnpackNormalScale( tex2D( _WaterNormalMap, rotator106 ), _Normal2Strenght );
				unpack101.z = lerp( 1, unpack101.z, saturate(_Normal2Strenght) );
				float2 temp_output_14_0_g2 = ( unpack101.xy * 1.0 );
				float mulTime5_g2 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g2 = frac( mulTime5_g2 );
				float2 temp_output_18_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * temp_output_7_0_g2 ) );
				float temp_output_48_0_g2 = _TileScale2;
				float temp_output_49_0_g2 = 0.0;
				float temp_output_53_0_g2 = _Normal2Strenght;
				float3 unpack37_g2 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_18_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2) ), temp_output_53_0_g2 );
				unpack37_g2.z = lerp( 1, unpack37_g2.z, saturate(temp_output_53_0_g2) );
				float2 temp_output_19_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * frac( ( mulTime5_g2 + 0.5 ) ) ) );
				float3 unpack41_g2 = UnpackNormalScale( tex2D( _WaterNormalMap, (temp_output_19_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2) ), temp_output_53_0_g2 );
				unpack41_g2.z = lerp( 1, unpack41_g2.z, saturate(temp_output_53_0_g2) );
				float temp_output_17_0_g2 = abs( ( ( temp_output_7_0_g2 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g2 = lerp( unpack37_g2 , unpack41_g2 , temp_output_17_0_g2);
				float3 Normal100 = BlendNormal( lerpResult22_g1 , lerpResult22_g2 );
				float3 ScreenUV21 = ( float3( (ase_screenPosNorm).xy ,  0.0 ) + ( Normal100 * _DistortionStrenght ) );
				float4 fetchOpaqueVal16 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( ScreenUV21.xy ), 1.0 );
				float4 ScreenColor17 = fetchOpaqueVal16;
				float screenDepth115 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth115 = abs( ( screenDepth115 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _SceneDepth ) );
				float4 lerpResult114 = lerp( ScreenColor17 , _WaterColor , saturate( distanceDepth115 ));
				float4 Final_Water_Color116 = lerpResult114;
				
				float DepthFade121 = distanceDepth115;
				

				float3 BaseColor = Final_Water_Color116.rgb;
				float3 Normal = Normal100;
				float3 Emission = 0;
				float3 Specular = 0.5;
				float Metallic = 0.0;
				float Smoothness = 0.98;
				float Occlusion = 1;
				float Alpha = DepthFade121;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;

				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = IN.clipPos.z;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				InputData inputData = (InputData)0;
				inputData.positionWS = WorldPosition;
				inputData.positionCS = IN.clipPos;
				inputData.shadowCoord = ShadowCoords;

				#ifdef _NORMALMAP
					#if _NORMAL_DROPOFF_TS
						inputData.normalWS = TransformTangentToWorld(Normal, half3x3( WorldTangent, WorldBiTangent, WorldNormal ));
					#elif _NORMAL_DROPOFF_OS
						inputData.normalWS = TransformObjectToWorldNormal(Normal);
					#elif _NORMAL_DROPOFF_WS
						inputData.normalWS = Normal;
					#endif
				#else
					inputData.normalWS = WorldNormal;
				#endif

				inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				inputData.viewDirectionWS = SafeNormalize( WorldViewDirection );

				inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					float3 SH = IN.lightmapUVOrVertexSH.xyz;
				#endif

				#ifdef ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#else
					#if defined(DYNAMICLIGHTMAP_ON)
						inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, IN.dynamicLightmapUV.xy, SH, inputData.normalWS);
					#else
						inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS );
					#endif
				#endif

				inputData.normalizedScreenSpaceUV = NormalizedScreenSpaceUV;
				inputData.shadowMask = SAMPLE_SHADOWMASK(IN.lightmapUVOrVertexSH.xy);

				#if defined(DEBUG_DISPLAY)
					#if defined(DYNAMICLIGHTMAP_ON)
						inputData.dynamicLightmapUV = IN.dynamicLightmapUV.xy;
						#endif
					#if defined(LIGHTMAP_ON)
						inputData.staticLightmapUV = IN.lightmapUVOrVertexSH.xy;
					#else
						inputData.vertexSH = SH;
					#endif
				#endif

				#ifdef _DBUFFER
					ApplyDecal(IN.clipPos,
						BaseColor,
						Specular,
						inputData.normalWS,
						Metallic,
						Occlusion,
						Smoothness);
				#endif

				BRDFData brdfData;
				InitializeBRDFData
				(BaseColor, Metallic, Specular, Smoothness, Alpha, brdfData);

				Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, inputData.shadowMask);
				half4 color;
				MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, inputData.shadowMask);
				color.rgb = GlobalIllumination(brdfData, inputData.bakedGI, Occlusion, inputData.positionWS, inputData.normalWS, inputData.viewDirectionWS);
				color.a = Alpha;

				#ifdef ASE_FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return BRDFDataToGbuffer(brdfData, inputData, Smoothness, Emission + color.rgb, Occlusion);
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "SceneSelectionPass"
			Tags { "LightMode"="SceneSelectionPass" }

			Cull Off

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _RECEIVE_SHADOWS_OFF 1
			#pragma multi_compile _ DEBUG_DISPLAY
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_DISTANCE_TESSELLATION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140008
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#define SCENESELECTIONPASS 1

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_VERT_NORMAL


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _WaterColor;
			float _Height;
			float _FlowStrenght;
			float _FlowSpeed;
			float _TileScale;
			float _NormalStrenght;
			float _TileScale2;
			float _Normal2Strenght;
			float _DistortionStrenght;
			float _SceneDepth;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _WaterNormalMap;
			sampler2D _FlowMap;
			uniform float4 _CameraDepthTexture_TexelSize;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 texCoord35_g1 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 uv_FlowMap11 = v.ase_texcoord.xy;
				float3 FlowMapUnpacked14 = ( UnpackNormalScale( tex2Dlod( _FlowMap, float4( uv_FlowMap11, 0, 0.0) ), 1.0f ) * _FlowStrenght );
				float2 temp_output_14_0_g1 = ( FlowMapUnpacked14.xy * 1.0 );
				float mulTime5_g1 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g1 = frac( mulTime5_g1 );
				float2 temp_output_18_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * temp_output_7_0_g1 ) );
				float temp_output_48_0_g1 = _TileScale;
				float temp_output_49_0_g1 = 0.0;
				float temp_output_53_0_g1 = _NormalStrenght;
				float3 unpack37_g1 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_18_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1), 0, 0.0) ), temp_output_53_0_g1 );
				unpack37_g1.z = lerp( 1, unpack37_g1.z, saturate(temp_output_53_0_g1) );
				float2 temp_output_19_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * frac( ( mulTime5_g1 + 0.5 ) ) ) );
				float3 unpack41_g1 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_19_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1), 0, 0.0) ), temp_output_53_0_g1 );
				unpack41_g1.z = lerp( 1, unpack41_g1.z, saturate(temp_output_53_0_g1) );
				float temp_output_17_0_g1 = abs( ( ( temp_output_7_0_g1 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g1 = lerp( unpack37_g1 , unpack41_g1 , temp_output_17_0_g1);
				float2 texCoord35_g2 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_cast_1 = (_TileScale2).xx;
				float2 texCoord104 = v.ase_texcoord.xy * temp_cast_1 + float2( 0,0 );
				float mulTime108 = _TimeParameters.x * 0.1;
				float cos106 = cos( mulTime108 );
				float sin106 = sin( mulTime108 );
				float2 rotator106 = mul( texCoord104 - float2( 0.5,0.5 ) , float2x2( cos106 , -sin106 , sin106 , cos106 )) + float2( 0.5,0.5 );
				float3 unpack101 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( rotator106, 0, 0.0) ), _Normal2Strenght );
				unpack101.z = lerp( 1, unpack101.z, saturate(_Normal2Strenght) );
				float2 temp_output_14_0_g2 = ( unpack101.xy * 1.0 );
				float mulTime5_g2 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g2 = frac( mulTime5_g2 );
				float2 temp_output_18_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * temp_output_7_0_g2 ) );
				float temp_output_48_0_g2 = _TileScale2;
				float temp_output_49_0_g2 = 0.0;
				float temp_output_53_0_g2 = _Normal2Strenght;
				float3 unpack37_g2 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_18_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2), 0, 0.0) ), temp_output_53_0_g2 );
				unpack37_g2.z = lerp( 1, unpack37_g2.z, saturate(temp_output_53_0_g2) );
				float2 temp_output_19_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * frac( ( mulTime5_g2 + 0.5 ) ) ) );
				float3 unpack41_g2 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_19_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2), 0, 0.0) ), temp_output_53_0_g2 );
				unpack41_g2.z = lerp( 1, unpack41_g2.z, saturate(temp_output_53_0_g2) );
				float temp_output_17_0_g2 = abs( ( ( temp_output_7_0_g2 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g2 = lerp( unpack37_g2 , unpack41_g2 , temp_output_17_0_g2);
				float3 Normal100 = BlendNormal( lerpResult22_g1 , lerpResult22_g2 );
				float dotResult188 = dot( Normal100 , float3(1,1,0) );
				float3 Displace162 = ( ( v.ase_normal * _Height ) * dotResult188 );
				
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord = screenPos;
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = Displace162;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				o.clipPos = TransformWorldToHClip(positionWS);

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float4 screenPos = IN.ase_texcoord;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth115 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth115 = abs( ( screenDepth115 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _SceneDepth ) );
				float DepthFade121 = distanceDepth115;
				

				surfaceDescription.Alpha = DepthFade121;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;

				#ifdef SCENESELECTIONPASS
					outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				#elif defined(SCENEPICKINGPASS)
					outColor = _SelectionID;
				#endif

				return outColor;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "ScenePickingPass"
			Tags { "LightMode"="Picking" }

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _RECEIVE_SHADOWS_OFF 1
			#pragma multi_compile _ DEBUG_DISPLAY
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_DISTANCE_TESSELLATION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140008
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

		    #define SCENEPICKINGPASS 1

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_VERT_NORMAL


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _WaterColor;
			float _Height;
			float _FlowStrenght;
			float _FlowSpeed;
			float _TileScale;
			float _NormalStrenght;
			float _TileScale2;
			float _Normal2Strenght;
			float _DistortionStrenght;
			float _SceneDepth;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _WaterNormalMap;
			sampler2D _FlowMap;
			uniform float4 _CameraDepthTexture_TexelSize;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 texCoord35_g1 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 uv_FlowMap11 = v.ase_texcoord.xy;
				float3 FlowMapUnpacked14 = ( UnpackNormalScale( tex2Dlod( _FlowMap, float4( uv_FlowMap11, 0, 0.0) ), 1.0f ) * _FlowStrenght );
				float2 temp_output_14_0_g1 = ( FlowMapUnpacked14.xy * 1.0 );
				float mulTime5_g1 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g1 = frac( mulTime5_g1 );
				float2 temp_output_18_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * temp_output_7_0_g1 ) );
				float temp_output_48_0_g1 = _TileScale;
				float temp_output_49_0_g1 = 0.0;
				float temp_output_53_0_g1 = _NormalStrenght;
				float3 unpack37_g1 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_18_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1), 0, 0.0) ), temp_output_53_0_g1 );
				unpack37_g1.z = lerp( 1, unpack37_g1.z, saturate(temp_output_53_0_g1) );
				float2 temp_output_19_0_g1 = ( texCoord35_g1 + ( temp_output_14_0_g1 * frac( ( mulTime5_g1 + 0.5 ) ) ) );
				float3 unpack41_g1 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_19_0_g1*temp_output_48_0_g1 + temp_output_49_0_g1), 0, 0.0) ), temp_output_53_0_g1 );
				unpack41_g1.z = lerp( 1, unpack41_g1.z, saturate(temp_output_53_0_g1) );
				float temp_output_17_0_g1 = abs( ( ( temp_output_7_0_g1 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g1 = lerp( unpack37_g1 , unpack41_g1 , temp_output_17_0_g1);
				float2 texCoord35_g2 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_cast_1 = (_TileScale2).xx;
				float2 texCoord104 = v.ase_texcoord.xy * temp_cast_1 + float2( 0,0 );
				float mulTime108 = _TimeParameters.x * 0.1;
				float cos106 = cos( mulTime108 );
				float sin106 = sin( mulTime108 );
				float2 rotator106 = mul( texCoord104 - float2( 0.5,0.5 ) , float2x2( cos106 , -sin106 , sin106 , cos106 )) + float2( 0.5,0.5 );
				float3 unpack101 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( rotator106, 0, 0.0) ), _Normal2Strenght );
				unpack101.z = lerp( 1, unpack101.z, saturate(_Normal2Strenght) );
				float2 temp_output_14_0_g2 = ( unpack101.xy * 1.0 );
				float mulTime5_g2 = _TimeParameters.x * _FlowSpeed;
				float temp_output_7_0_g2 = frac( mulTime5_g2 );
				float2 temp_output_18_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * temp_output_7_0_g2 ) );
				float temp_output_48_0_g2 = _TileScale2;
				float temp_output_49_0_g2 = 0.0;
				float temp_output_53_0_g2 = _Normal2Strenght;
				float3 unpack37_g2 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_18_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2), 0, 0.0) ), temp_output_53_0_g2 );
				unpack37_g2.z = lerp( 1, unpack37_g2.z, saturate(temp_output_53_0_g2) );
				float2 temp_output_19_0_g2 = ( texCoord35_g2 + ( temp_output_14_0_g2 * frac( ( mulTime5_g2 + 0.5 ) ) ) );
				float3 unpack41_g2 = UnpackNormalScale( tex2Dlod( _WaterNormalMap, float4( (temp_output_19_0_g2*temp_output_48_0_g2 + temp_output_49_0_g2), 0, 0.0) ), temp_output_53_0_g2 );
				unpack41_g2.z = lerp( 1, unpack41_g2.z, saturate(temp_output_53_0_g2) );
				float temp_output_17_0_g2 = abs( ( ( temp_output_7_0_g2 * 2.0 ) - 1.0 ) );
				float3 lerpResult22_g2 = lerp( unpack37_g2 , unpack41_g2 , temp_output_17_0_g2);
				float3 Normal100 = BlendNormal( lerpResult22_g1 , lerpResult22_g2 );
				float dotResult188 = dot( Normal100 , float3(1,1,0) );
				float3 Displace162 = ( ( v.ase_normal * _Height ) * dotResult188 );
				
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord = screenPos;
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = Displace162;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				o.clipPos = TransformWorldToHClip(positionWS);

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float4 screenPos = IN.ase_texcoord;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth115 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth115 = abs( ( screenDepth115 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _SceneDepth ) );
				float DepthFade121 = distanceDepth115;
				

				surfaceDescription.Alpha = DepthFade121;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
						clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;

				#ifdef SCENESELECTIONPASS
					outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				#elif defined(SCENEPICKINGPASS)
					outColor = _SelectionID;
				#endif

				return outColor;
			}

			ENDHLSL
		}
		
	}
	
	CustomEditor "UnityEditor.ShaderGraphLitGUI"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback Off
}
/*ASEBEGIN
Version=19200
Node;AmplifyShaderEditor.CommentaryNode;117;-787.8018,-1201.256;Inherit;False;1122.5;443.9;Final Water Color;8;113;116;114;119;115;111;120;121;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;103;-2804.85,-175.9332;Inherit;False;1980.707;966.9264;Normal;18;106;110;108;109;104;102;97;101;98;88;100;99;86;89;83;87;37;84;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;30;-1765.952,-890.5883;Inherit;False;940.2998;358;ScreenUV;7;21;91;90;19;20;92;93;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;18;-1418.714,-1204.345;Inherit;False;585.7997;299.3;ScreenColor;3;17;16;24;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;13;-1850.432,-519.8921;Inherit;False;1027.4;330.7;FlowMap;5;12;14;26;25;11;;1,1,1,1;0;0
Node;AmplifyShaderEditor.ScreenColorNode;16;-1225.714,-1154.345;Inherit;False;Global;_GrabScreen0;Grab Screen 0;1;0;Create;True;0;0;0;False;0;False;Object;-1;False;False;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SwizzleNode;20;-1497.752,-812.2884;Inherit;False;FLOAT2;0;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;19;-1715.952,-840.5883;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;25;-1206.052,-422.5589;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;26;-1523.951,-278.1594;Inherit;False;Property;_FlowStrenght;FlowStrenght;2;0;Create;True;0;0;0;False;0;False;0.1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;14;-1065.652,-427.7594;Inherit;False;FlowMapUnpacked;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;11;-1511.732,-466.7921;Inherit;True;Property;_FlowMapSampler;FlowMapSampler;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;24;-1407.114,-1156.845;Inherit;False;21;ScreenUV;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;17;-1051.214,-1150.445;Inherit;False;ScreenColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;91;-1159.075,-785.7245;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;92;-1331.347,-730.6183;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;93;-1641.471,-651.814;Inherit;False;Property;_DistortionStrenght;DistortionStrenght;6;0;Create;True;0;0;0;False;0;False;0.1;0.02608696;0;0.1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;21;-1043.185,-779.4555;Inherit;False;ScreenUV;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;90;-1537.9,-729.9567;Inherit;False;100;Normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;84;-2199.947,-125.9332;Inherit;True;14;FlowMapUnpacked;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;37;-2216.753,62.78963;Inherit;False;Property;_NormalStrenght;NormalStrenght;3;0;Create;True;0;0;0;False;0;False;0;0.15;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;87;-2087.964,135.5169;Inherit;False;Constant;_Float3;Float 3;8;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;83;-1663.45,-76.35141;Inherit;False;FlowNormalTexture;-1;;1;5ad90d855624ae64fbfddced331525ef;0;7;52;SAMPLER2D;1;False;26;FLOAT2;0,0;False;53;FLOAT;1;False;27;FLOAT;1;False;28;FLOAT;1;False;48;FLOAT;1;False;49;FLOAT;0;False;4;FLOAT3;0;FLOAT2;30;FLOAT2;31;FLOAT;34
Node;AmplifyShaderEditor.RangedFloatNode;89;-2219.947,277.6563;Inherit;False;Property;_TileScale;TileScale;4;0;Create;True;0;0;0;False;0;False;4;5;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.BlendNormalsNode;99;-1279.972,182.475;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;100;-1049.674,194.5751;Inherit;False;Normal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;88;-2222.947,206.6563;Inherit;False;Property;_FlowSpeed;FlowSpeed;7;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;98;-1617.726,382.8192;Inherit;False;FlowNormalTexture;-1;;2;5ad90d855624ae64fbfddced331525ef;0;7;52;SAMPLER2D;1;False;26;FLOAT2;0,0;False;53;FLOAT;1;False;27;FLOAT;1;False;28;FLOAT;1;False;48;FLOAT;1;False;49;FLOAT;0;False;4;FLOAT3;0;FLOAT2;30;FLOAT2;31;FLOAT;34
Node;AmplifyShaderEditor.SamplerNode;101;-2009.974,407.6385;Inherit;True;Property;_TextureSample2;Texture Sample 2;7;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;97;-2781.719,403.1706;Inherit;False;Property;_Normal2Strenght;Normal2Strenght;8;0;Create;True;0;0;0;False;0;False;0;0.2;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;102;-2782.152,484.5466;Inherit;False;Property;_TileScale2;TileScale2;5;0;Create;True;0;0;0;False;0;False;4;1.76;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;104;-2484.844,466.8455;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;109;-2458.543,582.6339;Inherit;False;Constant;_Vector0;Vector 0;10;0;Create;True;0;0;0;False;0;False;0.5,0.5;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleTimeNode;108;-2445.543,704.6339;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;110;-2611.543,717.6339;Inherit;False;Constant;_Float0;Float 0;10;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;106;-2203.672,540.3428;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;111;-437.4021,-1136.956;Inherit;False;17;ScreenColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.DepthFade;115;-493.402,-896.9567;Inherit;False;True;False;True;2;1;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;119;-246.2182,-955.2607;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;114;-92.40171,-1084.956;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;116;72.59824,-1067.956;Inherit;False;Final Water Color;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;113;-471.402,-1061.956;Inherit;False;Property;_WaterColor;WaterColor;9;0;Create;True;0;0;0;False;0;False;0.2095052,0.4150943,0.2179036,0;0.1635639,0.2059999,0.19044,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;120;-758.5192,-877.7137;Inherit;False;Property;_SceneDepth;SceneDepth;10;0;Create;True;0;0;0;False;0;False;1;0.9499366;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;309.3519,-75.58029;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;True;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;5;False;;10;False;;1;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;6;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthNormals;0;6;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormals;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;7;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;GBuffer;0;7;GBuffer;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;5;False;;10;False;;1;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalGBuffer;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;8;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;SceneSelectionPass;0;8;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;9;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ScenePickingPass;0;9;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.GetLocalVarNode;33;-32.98664,-55.03744;Inherit;False;100;Normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;36;-128.099,77.113;Inherit;False;Constant;_Smoothness;Smoothness;4;0;Create;True;0;0;0;False;0;False;0.98;0.95;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;15;-70.36765,-118.5474;Inherit;False;116;Final Water Color;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;121;-218.7006,-874.5183;Inherit;False;DepthFade;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;122;-37.97266,145.789;Inherit;False;121;DepthFade;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;124;-600.8696,1185.58;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalVertexDataNode;123;-966.869,955.5796;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;137;-1045.972,1095.583;Inherit;False;Property;_Height;Height;11;0;Create;True;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;179;-736.5906,1029.527;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DotProductOpNode;188;-842.6447,1214.934;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;130;-1244.475,1134.63;Inherit;True;100;Normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;190;-1224.199,1322.54;Inherit;False;Constant;_Vector1;Vector 1;13;0;Create;True;0;0;0;False;0;False;1,1,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;162;-431.1404,1190.646;Inherit;True;Displace;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;191;-25.87427,216.0104;Inherit;False;162;Displace;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;34;-1.098939,10.11301;Inherit;False;Constant;_Metalic;Metalic;3;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;12;-1819.432,-469.8921;Inherit;True;Property;_FlowMap;FlowMap;0;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;None;2ddbc509467e439468e9b9046d94f770;False;bump;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;86;-2556.557,138.568;Inherit;True;Property;_WaterNormalMap;WaterNormalMap;1;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;None;59d9f41b9e6e1634e92933a258d55678;True;bump;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;281.3519,-41.58029;Float;False;True;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;Water;94348b07e5e8bab40bd6c8a1e3df54cd;True;Forward;0;1;Forward;20;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;2;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;5;False;;10;False;;1;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForward;False;False;0;;0;0;Standard;41;Workflow;1;0;Surface;1;638298684447595676;  Refraction Model;0;0;  Blend;0;0;Two Sided;1;0;Fragment Normal Space,InvertActionOnDeselection;0;0;Forward Only;0;0;Transmission;0;0;  Transmission Shadow;0.5,False,;0;Translucency;0;0;  Translucency Strength;1,False,;0;  Normal Distortion;0.5,False,;0;  Scattering;2,False,;0;  Direct;0.9,False,;0;  Ambient;0.1,False,;0;  Shadow;0.5,False,;0;Cast Shadows;0;638298687069213288;  Use Shadow Threshold;0;0;Receive Shadows;0;638298687086822091;GPU Instancing;1;638298687081508454;LOD CrossFade;1;0;Built-in Fog;1;0;_FinalColorxAlpha;0;0;Meta Pass;1;0;Override Baked GI;0;0;Extra Pre Pass;0;0;DOTS Instancing;0;0;Tessellation;1;638299472242314872;  Phong;0;0;  Strength;0.5,False,;0;  Type;1;638299478804723862;  Tess;32,False,;638299544686274034;  Min;1,False,;638299544820998831;  Max;10,False,;638299545284573626;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Write Depth;0;0;  Early Z;0;0;Vertex Position,InvertActionOnDeselection;1;0;Debug Display;1;638299401551021103;Clear Coat;0;0;0;10;False;True;False;True;True;True;True;True;True;True;False;;False;0
WireConnection;16;0;24;0
WireConnection;20;0;19;0
WireConnection;25;0;11;0
WireConnection;25;1;26;0
WireConnection;14;0;25;0
WireConnection;11;0;12;0
WireConnection;17;0;16;0
WireConnection;91;0;20;0
WireConnection;91;1;92;0
WireConnection;92;0;90;0
WireConnection;92;1;93;0
WireConnection;21;0;91;0
WireConnection;83;52;86;0
WireConnection;83;26;84;0
WireConnection;83;53;37;0
WireConnection;83;27;87;0
WireConnection;83;28;88;0
WireConnection;83;48;89;0
WireConnection;99;0;83;0
WireConnection;99;1;98;0
WireConnection;100;0;99;0
WireConnection;98;52;86;0
WireConnection;98;26;101;0
WireConnection;98;53;97;0
WireConnection;98;27;87;0
WireConnection;98;28;88;0
WireConnection;98;48;102;0
WireConnection;101;0;86;0
WireConnection;101;1;106;0
WireConnection;101;5;97;0
WireConnection;104;0;102;0
WireConnection;108;0;110;0
WireConnection;106;0;104;0
WireConnection;106;1;109;0
WireConnection;106;2;108;0
WireConnection;115;0;120;0
WireConnection;119;0;115;0
WireConnection;114;0;111;0
WireConnection;114;1;113;0
WireConnection;114;2;119;0
WireConnection;116;0;114;0
WireConnection;121;0;115;0
WireConnection;124;0;179;0
WireConnection;124;1;188;0
WireConnection;179;0;123;0
WireConnection;179;1;137;0
WireConnection;188;0;130;0
WireConnection;188;1;190;0
WireConnection;162;0;124;0
WireConnection;1;0;15;0
WireConnection;1;1;33;0
WireConnection;1;3;34;0
WireConnection;1;4;36;0
WireConnection;1;6;122;0
WireConnection;1;8;191;0
ASEEND*/
//CHKSM=7DE3DF8AE50183A010FAF05A290C60D1357B10D5