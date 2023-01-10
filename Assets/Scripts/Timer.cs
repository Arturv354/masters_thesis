using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using UnityEngine;

public static class Timer
{
    private static MeasurementSet[,,] chunkMeasurements;
    private static Stopwatch totalStopWatch;

    private class MeasurementSet
    {
        private Stopwatch stopwatch;
        private MeasurementType currentMeasurement;
        private TimeSpan voxelGenerationMeasurement;
        private TimeSpan marchingCubesMeasurement;
        private TimeSpan meshSmoothingMeasurement;
        private TimeSpan meshBuildingMeasurement;

        public MeasurementSet()
        {
            stopwatch = new Stopwatch();
        }

        public void StartMeasurement(MeasurementType measurementType)
        {
            stopwatch.Start();
            currentMeasurement = measurementType;
        }

        public void StopMeasurement()
        {
            stopwatch.Stop();

            switch (currentMeasurement)
            {
                case MeasurementType.Voxel_Generation:
                    voxelGenerationMeasurement = stopwatch.Elapsed;
                    break;
                case MeasurementType.Marching_Cubes:
                    marchingCubesMeasurement = stopwatch.Elapsed;
                    break;
                case MeasurementType.Mesh_Smoothing:
                    meshSmoothingMeasurement = stopwatch.Elapsed;
                    break;
                case MeasurementType.Mesh_Building:
                    meshBuildingMeasurement = stopwatch.Elapsed;
                    break;
            }

            stopwatch.Reset();
        }
        
        public float GetMeasurement(MeasurementType measurementType)
        {
            return measurementType switch
            {
                MeasurementType.Voxel_Generation => (float) voxelGenerationMeasurement.TotalSeconds,
                MeasurementType.Marching_Cubes => (float) marchingCubesMeasurement.TotalSeconds,
                MeasurementType.Mesh_Smoothing => (float) meshSmoothingMeasurement.TotalSeconds,
                MeasurementType.Mesh_Building => (float) meshBuildingMeasurement.TotalSeconds,
                _ => 0.0f,
            };
        }
    }

    public enum MeasurementType
    {
        Voxel_Generation,
        Marching_Cubes,
        Mesh_Smoothing,
        Mesh_Building
    }

    public static void Init()
    {
        totalStopWatch = new Stopwatch();
        totalStopWatch.Start();

        chunkMeasurements = new MeasurementSet[TerrainData.chunksX, TerrainData.chunksY, TerrainData.chunksZ];

        for (int x = 0; x < TerrainData.chunksX; x++)
        {
            for (int y = 0; y < TerrainData.chunksY; y++)
            {
                for(int z = 0; z < TerrainData.chunksZ; z++)
                {
                    chunkMeasurements[x,y,z] = new MeasurementSet();
                }
            }
        }
    }

    public static void ResetTotalTime()
    {
        totalStopWatch.Reset();
        totalStopWatch.Start();
    }

    public static void StartMeasurement(MeasurementType measurementType, Chunk.ChunkData chunkData)
    {
        MeasurementSet measurementSet = chunkMeasurements[chunkData.chunkX, chunkData.chunkY, chunkData.chunkZ];
        measurementSet.StartMeasurement(measurementType);
    }

    public static void EndMeasurement(Chunk.ChunkData chunkData)
    {
        MeasurementSet measurementSet = chunkMeasurements[chunkData.chunkX, chunkData.chunkY, chunkData.chunkZ];
        measurementSet.StopMeasurement();
    }

    public static void ShowMeasurements()
    {
        float totalVoxelGenerationTime = 0;
        float totalMarchingCubesTime = 0;
        float totalMeshSmoothingTime = 0;
        float totalMeshBuildingTime = 0;

        for (int x = 0; x < TerrainData.chunksX; x++)
        {
            for (int y = 0; y < TerrainData.chunksY; y++)
            {
                for (int z = 0; z < TerrainData.chunksZ; z++)
                {
                    MeasurementSet measurementSet = chunkMeasurements[x, y, z];
                    totalVoxelGenerationTime += measurementSet.GetMeasurement(MeasurementType.Voxel_Generation);
                    totalMarchingCubesTime += measurementSet.GetMeasurement(MeasurementType.Marching_Cubes);
                    totalMeshSmoothingTime += measurementSet.GetMeasurement(MeasurementType.Mesh_Smoothing);
                    totalMeshBuildingTime += measurementSet.GetMeasurement(MeasurementType.Mesh_Building);
                }
            }
        }

        totalStopWatch.Stop();
        float totalTime = (float)totalStopWatch.Elapsed.TotalSeconds;

        if (TerrainData.multithreading)
        {
            float averageVoxelGenerationTime = totalVoxelGenerationTime / TerrainData.totalChunks;
            float averageMarchingCubesTime = totalMarchingCubesTime / TerrainData.totalChunks;
            float averageMeshSmoothingTime = totalMeshSmoothingTime / TerrainData.totalChunks;
            float averageMeshBuildingTime = totalMeshBuildingTime / TerrainData.totalChunks;
            float totalAverageTime = averageVoxelGenerationTime + averageMarchingCubesTime + averageMeshSmoothingTime + averageMeshBuildingTime;

            totalVoxelGenerationTime = (averageVoxelGenerationTime / totalAverageTime) * totalTime;
            totalMarchingCubesTime = (averageMarchingCubesTime / totalAverageTime) * totalTime;
            totalMeshSmoothingTime = (averageMeshSmoothingTime / totalAverageTime) * totalTime;
            totalMeshBuildingTime = (averageMeshBuildingTime / totalAverageTime) * totalTime;
        }

        UnityEngine.Debug.Log("Voxels were generated in " + totalVoxelGenerationTime.ToString("F2") + " seconds");
        UnityEngine.Debug.Log("Marching Cubes completed in " + totalMarchingCubesTime.ToString("F2") + " seconds");
        if (TerrainData.smoothNormals) UnityEngine.Debug.Log("Smoothing normals took " + totalMeshSmoothingTime.ToString("F2") + " seconds");
        UnityEngine.Debug.Log("Mesh was constructed in " + totalMeshBuildingTime.ToString("F2") + " seconds");
        UnityEngine.Debug.Log("Total time spent was " + totalTime.ToString("F2") + " seconds");
    }
}
