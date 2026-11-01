#ifndef HAMLET_GPU_SKINNING_INCLUDED
#define HAMLET_GPU_SKINNING_INCLUDED

#if defined(HAMLET_GPU_SKINNING)
sampler2D _GpuSkinningBoneTexture;

float4 HamletLoadGpuSkinningBoneRow(uint boneIndex, uint rowIndex)
{
    float2 uv = float2(
        ((float)rowIndex + 0.5) * _GpuSkinningBoneTextureSize.x,
        ((float)boneIndex + _GpuSkinningBoneOffset + 0.5) * _GpuSkinningBoneTextureSize.y);
    return tex2Dlod(_GpuSkinningBoneTexture, float4(uv, 0.0, 0.0));
}

void HamletBuildGpuSkinningRows(float4 boneWeights, uint4 boneIndices,
    out float4 row0, out float4 row1, out float4 row2)
{
    if (_GpuSkinningWeightCount < 4.0)
        boneWeights.w = 0.0;
    if (_GpuSkinningWeightCount < 3.0)
        boneWeights.z = 0.0;
    if (_GpuSkinningWeightCount < 2.0)
        boneWeights.y = 0.0;

    float weightSum = dot(boneWeights, float4(1.0, 1.0, 1.0, 1.0));
    if (weightSum <= 0.00001)
    {
        row0 = float4(1.0, 0.0, 0.0, 0.0);
        row1 = float4(0.0, 1.0, 0.0, 0.0);
        row2 = float4(0.0, 0.0, 1.0, 0.0);
        return;
    }

    boneWeights /= weightSum;
    row0 = 0.0;
    row1 = 0.0;
    row2 = 0.0;

    [unroll]
    for (int influence = 0; influence < 4; influence++)
    {
        float weight = boneWeights[influence];
        if (weight <= 0.0)
            continue;

        uint boneIndex = boneIndices[influence];
        row0 += HamletLoadGpuSkinningBoneRow(boneIndex, 0) * weight;
        row1 += HamletLoadGpuSkinningBoneRow(boneIndex, 1) * weight;
        row2 += HamletLoadGpuSkinningBoneRow(boneIndex, 2) * weight;
    }
}

void HamletApplyGpuSkinning(inout float4 positionOS, inout float3 normalOS,
    float4 boneWeights, uint4 boneIndices)
{
    float4 row0;
    float4 row1;
    float4 row2;
    HamletBuildGpuSkinningRows(boneWeights, boneIndices, row0, row1, row2);

    float4 sourcePosition = float4(positionOS.xyz, 1.0);
    float3 sourceNormal = normalOS;
    positionOS.xyz = float3(dot(row0, sourcePosition), dot(row1, sourcePosition), dot(row2, sourcePosition));
    normalOS = normalize(float3(dot(row0.xyz, sourceNormal), dot(row1.xyz, sourceNormal), dot(row2.xyz, sourceNormal)));
}

void HamletApplyGpuSkinning(inout float4 positionOS, inout float3 normalOS, inout float4 tangentOS,
    float4 boneWeights, uint4 boneIndices)
{
    float4 row0;
    float4 row1;
    float4 row2;
    HamletBuildGpuSkinningRows(boneWeights, boneIndices, row0, row1, row2);

    float4 sourcePosition = float4(positionOS.xyz, 1.0);
    float3 sourceNormal = normalOS;
    float3 sourceTangent = tangentOS.xyz;
    positionOS.xyz = float3(dot(row0, sourcePosition), dot(row1, sourcePosition), dot(row2, sourcePosition));
    normalOS = normalize(float3(dot(row0.xyz, sourceNormal), dot(row1.xyz, sourceNormal), dot(row2.xyz, sourceNormal)));
    tangentOS.xyz = normalize(float3(dot(row0.xyz, sourceTangent), dot(row1.xyz, sourceTangent), dot(row2.xyz, sourceTangent)));
}
#endif

#endif
