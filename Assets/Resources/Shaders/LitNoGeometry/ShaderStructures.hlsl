#ifndef __SHADER_STRUCTURES_INCLUDED__
#define __SHADER_STRUCTURES_INCLUDED__

struct Voxel {
	float3 position;
	float value;
};

struct TriangleTmp {

	float3 v1, v2, v3;
	float3 n;
};

struct Triangle {

	float3 v1, v2, v3;
	float3 n1, n2, n3;
};
#endif