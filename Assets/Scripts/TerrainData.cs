using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Runtime.InteropServices;

public static class TerrainData
{
    // data
    public static Chunk[,,] chunks;

    // GPU buffer size determines size of chunks
    public static readonly uint maxBufferSize = 2147483648;
    public static readonly uint bufferSize = maxBufferSize / 100;

    // parameters
    public static GenerationMethod generationMethod = GenerationMethod.GPU_Full_No_Geometry_Exact;
    public static bool smoothNormals = true;
    public static bool interpolateVertices = true;
    public static float terrainSizeX = 20f;
    public static float terrainSizeY = 10f;
    public static float terrainSizeZ = 20f;
    public static int cubesPerUnit = 20;
    // noise
    public static int seed = 3452;
    public static float noiseFrequency = 2.5f;
    public static float noiseStrength = 0.3f;
    public static int noiseLayers = 9;
    public static float noiseLayerFrequencyMultiplier = 1.8f;
    // debug
    public static bool displayTerrainParameters = false;
    public static bool measureTime = true;

    // computed parameters
    public static bool multithreading = generationMethod == GenerationMethod.CPU_Full_Multithreading;
    public static float cubeSize = 1f / cubesPerUnit;
    public static float maxTerrainSize = Mathf.Max(terrainSizeX, terrainSizeY, terrainSizeZ);
    public static int voxelStructSize = Marshal.SizeOf(typeof(Voxel));
    public static int triangleStructSize = Marshal.SizeOf(typeof(Triangle));
    public static int cubeStructSize = 5 * triangleStructSize;
    public static int maxCubesInBuffer = (int) (bufferSize / cubeStructSize);
    // chunk dimentions in cubes (chunkCubesSide * chunkCubesSide * chunkCubesSide)
    public static int chunkCubesSide = Mathf.FloorToInt(Mathf.Pow(maxCubesInBuffer, 1f / 3f));
    // one layer of cubes on each side is used only to calculate smooth normals and discarded
    public static int chunkCubesSideReal = chunkCubesSide - 2;
    public static int chunkVoxelsSide = chunkCubesSide + 1;
    public static int chunkVoxelsSideReal = chunkVoxelsSide - 2;
    public static float chunksSize = chunkCubesSideReal * cubeSize;
    public static int chunksX = Mathf.CeilToInt(terrainSizeX / chunksSize);
    public static int chunksY = Mathf.CeilToInt(terrainSizeY / chunksSize);
    public static int chunksZ = Mathf.CeilToInt(terrainSizeZ / chunksSize);
    public static int totalChunks = chunksX * chunksY * chunksZ;
    // last chunks in each axis will be a little bit smaller
    public static int totalCubesX = Mathf.RoundToInt(terrainSizeX / cubeSize);
    public static int totalCubesY = Mathf.RoundToInt(terrainSizeY / cubeSize);
    public static int totalCubesZ = Mathf.RoundToInt(terrainSizeZ / cubeSize);
    public static int lastChunkCubesSideRealX = totalCubesX - (chunksX - 1) * chunkCubesSideReal;
    public static int lastChunkCubesSideRealY = totalCubesY - (chunksY - 1) * chunkCubesSideReal;
    public static int lastChunkCubesSideRealZ = totalCubesZ - (chunksZ - 1) * chunkCubesSideReal;
    public static int lastChunkCubesSideX = lastChunkCubesSideRealX + 2;
    public static int lastChunkCubesSideY = lastChunkCubesSideRealY + 2;
    public static int lastChunkCubesSideZ = lastChunkCubesSideRealZ + 2;
    public static int lastChunkVoxelsSideX = lastChunkCubesSideX + 1;
    public static int lastChunkVoxelsSideY = lastChunkCubesSideY + 1;
    public static int lastChunkVoxelsSideZ = lastChunkCubesSideZ + 1;
    public static int lastChunkVoxelsSideRealX = lastChunkVoxelsSideX - 2;
    public static int lastChunkVoxelsSideRealY = lastChunkVoxelsSideY - 2;
    public static int lastChunkVoxelsSideRealZ = lastChunkVoxelsSideZ - 2;

    public enum GenerationMethod
    {
        CPU_Full,
        CPU_Full_Multithreading,
        CPU_GPU,
        GPU_Full_No_Geometry_Exact,
        GPU_Full_No_Geometry_All,
        GPU_Full_Geometry_Exact,
        GPU_Full_Geometry_All
    }

    // structures
    public struct Voxel
    {
        public Vector3 position;
        public float value;
    }

    public struct TriangleTmp
    {
        public Vector3 v1, v2, v3;
        public Vector3 n;
    };

    public struct Triangle
    {
        public Vector3 v1, v2, v3;
        public Vector3 n1, n2, n3;
    }
}
