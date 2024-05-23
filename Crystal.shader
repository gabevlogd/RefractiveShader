Shader "Custom/Crystal"
{
    Properties
    {
        _FresnelColor("Fresnel Color", Color) = (1, 1, 1, 1)
        _Color("Color", Color) = (1, 1, 1, 1)
        _FresnelIntensity("Fresnel Intensity", Range(0, 10)) = 1
        _FresnelPower("Fresnel Power", Range(0, 10)) = 1
        _RefractionIndex("Refraction Index", Range(-1, 1)) = 1
        _Intensity("Refraction Intensity", Range(0, 1)) = 1
    }



    SubShader
    {
        // Grab the current screen content into _GrabTexture
        GrabPass{ "_GrabTexture" }

        Tags {"Queue" = "Transparent"}
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 grabPos : TEXTCORD0;
                float3 normal : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            float2 ProjectDirectionToClipSpace(float3 direction)
            {
                // Convert the direction vector to homogeneous coordinates (w = 0 for direction vectors)
                float4 directionHomogeneous = float4(direction, 0.0);

                // Transform the direction from local space to view space
                float4 viewSpaceDirection = mul(UNITY_MATRIX_V, directionHomogeneous);

                // Transform the direction from view space to clip space
                float4 clipSpaceDirection = mul(UNITY_MATRIX_P, viewSpaceDirection);

                // Convert to 2D by taking the x and y components
                float2 clipSpace2D = clipSpaceDirection.xy;

                return clipSpace2D;
            }

            sampler2D _GrabTexture;

            float4 _FresnelColor;
            float4 _Color;

            float _FresnelIntensity;
            float _FresnelPower;
            float _RefractionIndex;
            float _Intensity;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //normalize in the frag for a smoothest result
                i.viewDir = normalize(i.viewDir);
                i.normal = normalize(i.normal);

                //-------------- refraction ----------------
                float3 refractDir = refract(-i.viewDir, i.normal, _RefractionIndex);
                float2 reftactDirClipSpace = ProjectDirectionToClipSpace(refractDir);
                float2 grabUV = (i.grabPos.xy / i.grabPos.w) + (reftactDirClipSpace * _Intensity);
                //avoid the stretching of the grab texture at the edges by repeating it instead
                grabUV = grabUV - floor(grabUV);
                float4 grabColor = tex2D(_GrabTexture, grabUV);
                //------------ refraction end --------------

                //---------------- fresnel -----------------
                float NdotV = dot(i.normal, i.viewDir);
                float fresnelAmount = 1 - max(0, NdotV);
                float4 fresnelColor = pow(fresnelAmount, _FresnelPower) * _FresnelIntensity * _FresnelColor;
                //-------------- fresnel end ---------------

                float4 outColor = lerp(fresnelColor, grabColor * _Color, NdotV);
                return outColor;
            }

            ENDCG
        }
    }
}
