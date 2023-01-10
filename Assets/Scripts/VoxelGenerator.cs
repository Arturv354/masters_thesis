using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class VoxelGenerator
{
    public static void GenerateVoxelValuesCPU(Chunk.ChunkData chunkData)
    {
        if (TerrainData.measureTime) Timer.StartMeasurement(Timer.MeasurementType.Voxel_Generation, chunkData);
        
        (Vector3[,,] voxelPositions, Vector3[,,] voxelDensityInputs) = CalculateVoxelPositionsAndDensityInputs(chunkData);
        float[,,] noiseValues = GeneratePerlinNoise3D(voxelDensityInputs, chunkData);
        float[,,] voxelValues = new float[chunkData.chunkVoxelsSideX, chunkData.chunkVoxelsSideY, chunkData.chunkVoxelsSideZ];

        for (int x = 0; x < chunkData.chunkVoxelsSideX; x++)
        {
            for (int y = 0; y < chunkData.chunkVoxelsSideY; y++)
            {
                for (int z = 0; z < chunkData.chunkVoxelsSideZ; z++)
                {
                    Vector3 densityInput = voxelDensityInputs[x, y, z];
                    float density = -densityInput.y;
                    density += noiseValues[x, y, z];

                    voxelValues[x, y, z] = density;

                    // top layer of terrain should always be air and bottom layer should always be under
                    if (chunkData.chunkY == 0 && (y == 0 || y == 1)) voxelValues[x, y, z] = 1f;
                    if (chunkData.chunkY == TerrainData.chunksY - 1 && (y == chunkData.chunkVoxelsSideY - 1 || y == chunkData.chunkVoxelsSideY - 2)) voxelValues[x, y, z] = -1f;
                }
            }
        }

        if (TerrainData.measureTime) Timer.EndMeasurement(chunkData);
        chunkData.voxelValues = voxelValues;
        chunkData.voxelPositions = voxelPositions;
    }

    private static (Vector3[,,], Vector3[,,]) CalculateVoxelPositionsAndDensityInputs(Chunk.ChunkData chunkData)
    {
        Vector3[,,] voxelPositions = new Vector3[chunkData.chunkVoxelsSideX, chunkData.chunkVoxelsSideY, chunkData.chunkVoxelsSideZ];
        Vector3[,,] voxelDensityInputs = new Vector3[chunkData.chunkVoxelsSideX, chunkData.chunkVoxelsSideY, chunkData.chunkVoxelsSideZ];

        for (int x = 0; x < chunkData.chunkVoxelsSideX; x++)
        {
            for (int y = 0; y < chunkData.chunkVoxelsSideY; y++)
            {
                for (int z = 0; z < chunkData.chunkVoxelsSideZ; z++)
                {
                    float voxelPositionX = chunkData.position.x + (x - 1) * TerrainData.cubeSize - 0.5f * TerrainData.chunksSize;
                    float voxelPositionY = chunkData.position.y + (y - 1) * TerrainData.cubeSize - 0.5f * TerrainData.chunksSize;
                    float voxelPositionZ = chunkData.position.z + (z - 1) * TerrainData.cubeSize - 0.5f * TerrainData.chunksSize;

                    float voxelDensityInputX = voxelPositionX / (TerrainData.maxTerrainSize + TerrainData.cubeSize * 2);
                    float voxelDensityInputY = voxelPositionY / (TerrainData.maxTerrainSize + TerrainData.cubeSize * 2);
                    float voxelDensityInputZ = voxelPositionZ / (TerrainData.maxTerrainSize + TerrainData.cubeSize * 2);

                    voxelPositions[x,y,z] =  new Vector3(voxelPositionX, voxelPositionY, voxelPositionZ);
                    voxelDensityInputs[x, y, z] = new Vector3(voxelDensityInputX, voxelDensityInputY, voxelDensityInputZ);
                }
            }
        }

        return (voxelPositions, voxelDensityInputs);
    }

    private static float[,,] GeneratePerlinNoise3D(Vector3[,,] cubePostions, Chunk.ChunkData chunkData)
    {
        FastNoiseLite noiseGenerator = new FastNoiseLite(TerrainData.seed);
        noiseGenerator.SetNoiseType(FastNoiseLite.NoiseType.Perlin);

        float[,,] noiseValues = new float[chunkData.chunkVoxelsSideX, chunkData.chunkVoxelsSideY, chunkData.chunkVoxelsSideZ];

        for (int x = 0; x < chunkData.chunkVoxelsSideX; x++)
        {
            for (int y = 0; y < chunkData.chunkVoxelsSideY; y++)
            {
                for (int z = 0; z < chunkData.chunkVoxelsSideZ; z++)
                {
                    Vector3 voxelPosition = cubePostions[x, y, z];

                    float noiseValue = 0;

                    for (int i = 0; i < TerrainData.noiseLayers; i++)
                    {
                        float currentNoiseFrequency = TerrainData.noiseFrequency * Mathf.Pow(TerrainData.noiseLayerFrequencyMultiplier, i);
                        float currentNoiseStrength = TerrainData.noiseStrength / Mathf.Pow(2, i);
                        noiseGenerator.SetFrequency(currentNoiseFrequency);

                        noiseValue += noiseGenerator.GetNoise(voxelPosition.x, voxelPosition.y, voxelPosition.z) * currentNoiseStrength;
                    }

                    noiseValues[x, y, z] = noiseValue;
                }
            }
        }

        return noiseValues;
    }
}
