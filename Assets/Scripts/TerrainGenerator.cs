using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Threading;
using System;
using System.Collections.Concurrent;

public class TerrainGenerator : MonoBehaviour
{
    public GameObject chunkPrefabCPU;
    public GameObject chunkPrefabGPU_NoGeometry;
    public GameObject chunkPrefabGPU_Geometry;

    private Dictionary<TerrainData.GenerationMethod, GameObject> chunkPrefabs;

    // fields for multithreading
    private ConcurrentQueue<Chunk> chunkQueue;
    private int chunksGenerated = 0;
    private bool currentlyMultithreading = false;
    private Mesh genericChunkMesh_NoGeometry;
    private Mesh genericChunkMesh_Geometry;

    private void Awake()
    {
        chunkPrefabs = new Dictionary<TerrainData.GenerationMethod, GameObject>()
        {
            { TerrainData.GenerationMethod.CPU_Full, chunkPrefabCPU},
            { TerrainData.GenerationMethod.CPU_Full_Multithreading, chunkPrefabCPU},
            { TerrainData.GenerationMethod.CPU_GPU, chunkPrefabCPU},
            { TerrainData.GenerationMethod.GPU_Full_No_Geometry_Exact, chunkPrefabGPU_NoGeometry},
            { TerrainData.GenerationMethod.GPU_Full_No_Geometry_All, chunkPrefabGPU_NoGeometry},
            { TerrainData.GenerationMethod.GPU_Full_Geometry_Exact, chunkPrefabGPU_Geometry},
            { TerrainData.GenerationMethod.GPU_Full_Geometry_All, chunkPrefabGPU_Geometry},
        };

        if (TerrainData.displayTerrainParameters)
        {
            Debug.Log("Terrain dimentions are " + TerrainData.terrainSizeX + " x " + TerrainData.terrainSizeY + " x " + TerrainData.terrainSizeZ);
            Debug.Log("Generating " + TerrainData.chunksX + " x " + TerrainData.chunksY + " x " + TerrainData.chunksZ + " chunks.");
            Debug.Log("Chunk dimentions are " + TerrainData.chunkCubesSideReal + " x " + TerrainData.chunkCubesSideReal + " x " + TerrainData.chunkCubesSideReal + " cubes");
            Debug.Log("Cube size is " + TerrainData.cubeSize);
            Debug.Log("Chunk size is " + TerrainData.chunksSize);
        }

        GenerateGenericMeshes();
    }

    void Start()
    {
        if (TerrainData.multithreading)
        {
            currentlyMultithreading = true;
            chunkQueue = new ConcurrentQueue<Chunk>();
            chunksGenerated = 0;
        }

        TerrainData.chunks = new Chunk[TerrainData.chunksX, TerrainData.chunksY, TerrainData.chunksZ];

        Vector3 terrainStartPoint = new(-TerrainData.terrainSizeX * 0.5f, -TerrainData.terrainSizeY * 0.5f, -TerrainData.terrainSizeZ * 0.5f);
       
        GameObject prefabToUse = chunkPrefabs[TerrainData.generationMethod];

        for (int x = 0; x < TerrainData.chunksX; x++)
        {
            for (int y = 0; y < TerrainData.chunksY; y++)
            {
                for (int z = 0; z < TerrainData.chunksZ; z++)
                {
                    Vector3 chunkPosition = terrainStartPoint + new Vector3((x + 0.5f) * TerrainData.chunksSize, (y + 0.5f) * TerrainData.chunksSize, (z + 0.5f) * TerrainData.chunksSize);
                    GameObject newChunkObject = Instantiate(prefabToUse, chunkPosition, Quaternion.identity, transform);
                    Chunk chunk = newChunkObject.GetComponent<Chunk>();
                    TerrainData.chunks[x, y, z] = chunk;
                    chunk.Init(x, y, z, this);
                }
            }
        }

        if (TerrainData.measureTime) Timer.Init();

        for (int x = 0; x < TerrainData.chunksX; x++)
        {
            for (int y = 0; y < TerrainData.chunksY; y++)
            {
                for (int z = 0; z < TerrainData.chunksZ; z++)
                {
                    Chunk chunk = TerrainData.chunks[x, y, z];

                    if (TerrainData.multithreading)
                    {
                        ThreadPool.QueueUserWorkItem(delegate { chunk.GenerateTerrain(); });
                    }
                    else
                    {
                        chunk.GenerateTerrain();
                    }   
                }
            }
        }

        if (TerrainData.measureTime && !TerrainData.multithreading) Timer.ShowMeasurements();
    }

    public void AddChunkToQueue(Chunk chunk)
    {
        chunkQueue.Enqueue(chunk);
    }

    private void Update()
    {
        if (currentlyMultithreading)
        {
            while (!chunkQueue.IsEmpty)
            {
                Chunk chunk;
                bool success = chunkQueue.TryDequeue(out chunk);
                if (success)
                {
                    chunk.GenerateMeshCPU();
                    chunksGenerated++;
                }
            }
            if (chunksGenerated == TerrainData.totalChunks)
            {
                currentlyMultithreading = false;
                if (TerrainData.measureTime) Timer.ShowMeasurements();
            }
        }
    }

    private void GenerateGenericMeshes()
    {
        int triangleCount = TerrainData.chunkCubesSideReal * TerrainData.chunkCubesSideReal * TerrainData.chunkCubesSideReal * 5;

        genericChunkMesh_NoGeometry = new Mesh();
        genericChunkMesh_Geometry = new Mesh();
        genericChunkMesh_NoGeometry.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
        genericChunkMesh_Geometry.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;

        Vector3[] vertices = new Vector3[triangleCount * 3];
        int[] triangles = new int[triangleCount * 3];
        for (int i = 0; i < triangleCount * 3; i++)
        {
            triangles[i] = i;
        }

        genericChunkMesh_NoGeometry.vertices = vertices;
        genericChunkMesh_NoGeometry.triangles = triangles;
        genericChunkMesh_Geometry.vertices = vertices;
        genericChunkMesh_Geometry.SetIndices(triangles, MeshTopology.Points, 0);
        Bounds bounds = new Bounds(Vector3.zero, new Vector3(TerrainData.chunksSize, TerrainData.chunksSize, TerrainData.chunksSize));
        genericChunkMesh_NoGeometry.bounds = bounds;
        genericChunkMesh_Geometry.bounds = bounds;
    }

    public Mesh GetGenericChunkMesh_NoGeometry()
    {
        return genericChunkMesh_NoGeometry;
    }

    public Mesh GetGenericChunkMesh_Geometry()
    {
        return genericChunkMesh_Geometry;
    }
}
