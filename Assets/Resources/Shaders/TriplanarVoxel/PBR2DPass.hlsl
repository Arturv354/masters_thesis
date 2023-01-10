PackedVaryings vert(Attributes input)
{
    Triangle triangleStruct = triangleBuffer[input.id / 3];
    float3 localPos;
    float3 normal;
    if (input.id % 3 == 0)
    {
        localPos = triangleStruct.v1;
        normal = triangleStruct.n1;
    }
    else if (input.id % 3 == 1)
    {
        localPos = triangleStruct.v2;
        normal = triangleStruct.n2;
    }
    else
    {
        localPos = triangleStruct.v3;
        normal = triangleStruct.n3;
    }
    input.positionOS = localPos;
    input.normalOS = normal;

    float3 t1 = cross(normal, float3(0, 0, 1));
    float3 t2 = cross(normal, float3(0, 1, 1));
    if (length(t1) > length(t2))
    {
        input.tangentOS = float4(t1,1);
    }
    else
    {
        input.tangentOS = float4(t2,1);
    }

    Varyings output = (Varyings)0;
    output = BuildVaryings(input);
    PackedVaryings packedOutput = (PackedVaryings)0;
    packedOutput = PackVaryings(output);
    return packedOutput;
}

half4 frag(PackedVaryings packedInput) : SV_TARGET
{
    Varyings unpacked = UnpackVaryings(packedInput);
    UNITY_SETUP_INSTANCE_ID(unpacked);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(unpacked);
    SurfaceDescription surfaceDescription = BuildSurfaceDescription(unpacked);

    #if _ALPHATEST_ON
        half alpha = surfaceDescription.Alpha;
        clip(alpha - surfaceDescription.AlphaClipThreshold);
    #elif _SURFACE_TYPE_TRANSPARENT
        half alpha = surfaceDescription.Alpha;
    #else
        half alpha = 1;
    #endif

    half4 color = half4(surfaceDescription.BaseColor, alpha);
    return color;
}
