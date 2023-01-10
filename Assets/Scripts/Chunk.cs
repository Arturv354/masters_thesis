using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Chunk : MonoBehaviour
{
    private ChunkData chunkData;
    private TerrainGenerator terrainGenerator;
    private TerrainShaderManager terrainShaderManager;

    public ChunkData GetChunkData()
    {
        return chunkData;
    }

    public class ChunkData 
    {
        public Vector3 position;
        public int chunkX;
        public int chunkY;
        public int chunkZ;
        public int chunkVoxelsSideX;
        public int chunkVoxelsSideY;
        public int chunkVoxelsSideZ;
        public int chunkVoxelsSideRealX;
        public int chunkVoxelsSideRealY;
        public int chunkVoxelsSideRealZ;
        public int chunkCubesSideX;
        public int chunkCubesSideY;
        public int chunkCubesSideZ;
        public int chunkCubesSideRealX;
        public int chunkCubesSideRealY;
        public int chunkCubesSideRealZ;
        public int[] triangles;
        public Vector3[] vertices;
        public Vector3[] normals;
        public float[,,] voxelValues;
        public Vector3[,,] voxelPositions;
        public MarchingCubes.Cube[,,] cubes;
    }

    public void Init(int chunkX, int chunkY, int chunkZ, TerrainGenerator terrainGenerator)
    {
        this.terrainGenerator = terrainGenerator;

        chunkData = new ChunkData()
        {
            position = transform.position,
            chunkX = chunkX,
            chunkY = chunkY,
            chunkZ = chunkZ,
            chunkVoxelsSideX = chunkX == TerrainData.chunksX - 1 ? TerrainData.lastChunkVoxelsSideX : TerrainData.chunkVoxelsSide,
            chunkVoxelsSideY = chunkY == TerrainData.chunksY - 1 ? TerrainData.lastChunkVoxelsSideY : TerrainData.chunkVoxelsSide,
            chunkVoxelsSideZ = chunkZ == TerrainData.chunksZ - 1 ? TerrainData.lastChunkVoxelsSideZ : TerrainData.chunkVoxelsSide,
            chunkVoxelsSideRealX = chunkX == TerrainData.chunksX - 1 ? TerrainData.lastChunkVoxelsSideRealX : TerrainData.chunkVoxelsSideReal,
            chunkVoxelsSideRealY = chunkY == TerrainData.chunksY - 1 ? TerrainData.lastChunkVoxelsSideRealY : TerrainData.chunkVoxelsSideReal,
            chunkVoxelsSideRealZ = chunkZ == TerrainData.chunksZ - 1 ? TerrainData.lastChunkVoxelsSideRealZ : TerrainData.chunkVoxelsSideReal,
            chunkCubesSideX = chunkX == TerrainData.chunksX - 1 ? TerrainData.lastChunkCubesSideX : TerrainData.chunkCubesSide,
            chunkCubesSideY = chunkY == TerrainData.chunksY - 1 ? TerrainData.lastChunkCubesSideY : TerrainData.chunkCubesSide,
            chunkCubesSideZ = chunkZ == TerrainData.chunksZ - 1 ? TerrainData.lastChunkCubesSideZ : TerrainData.chunkCubesSide,
            chunkCubesSideRealX = chunkX == TerrainData.chunksX - 1 ? TerrainData.lastChunkCubesSideRealX : TerrainData.chunkCubesSideReal,
            chunkCubesSideRealY = chunkY == TerrainData.chunksY - 1 ? TerrainData.lastChunkCubesSideRealY : TerrainData.chunkCubesSideReal,
            chunkCubesSideRealZ = chunkZ == TerrainData.chunksZ - 1 ? TerrainData.lastChunkCubesSideRealZ : TerrainData.chunkCubesSideReal,
        };
    }

    public void GenerateTerrain()
    {
        switch (TerrainData.generationMethod)
        {
            case TerrainData.GenerationMethod.CPU_Full:
                GenerateMeshDataCPU();
                GenerateMeshCPU();
                break;

            case TerrainData.GenerationMethod.CPU_Full_Multithreading:
                GenerateMeshDataCPU();
                terrainGenerator.AddChunkToQueue(this);
                break;

            case TerrainData.GenerationMethod.CPU_GPU:
                RunComputeShader();
                GenerateMeshDataGPU();
                CleanUpComputeBuffers(true);
                GenerateMeshCPU();
                break;

            case TerrainData.GenerationMethod.GPU_Full_No_Geometry_Exact:
                RunComputeShader();
                GenerateMeshGPU_NoGeometry();
                CleanUpComputeBuffers(false);
                break;

            case TerrainData.GenerationMethod.GPU_Full_No_Geometry_All:
                break;

            case TerrainData.GenerationMethod.GPU_Full_Geometry_Exact:
                break;

            case TerrainData.GenerationMethod.GPU_Full_Geometry_All:
                break;
        }
    }

    private void GenerateMeshDataCPU()
    {        
        VoxelGenerator.GenerateVoxelValuesCPU(chunkData);
        MarchingCubes.RunMarchinCubes(chunkData);
        MarchingCubes.GenerateMeshData(chunkData);
    }

    private void RunComputeShader()
    {
        terrainShaderManager = new TerrainShaderManager();
        terrainShaderManager.InitShader(chunkData);
        terrainShaderManager.RunShader(chunkData);
    }

    private void GenerateMeshDataGPU()
    {
        terrainShaderManager.GenerateMeshData(chunkData);
    }

    private void CleanUpComputeBuffers(bool clearOutputBuffer)
    {
        terrainShaderManager.CleanUp(clearOutputBuffer);
    }

    public void GenerateMeshCPU()
    {
        Mesh mesh = new Mesh();
        mesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
        mesh.vertices = chunkData.vertices;
        mesh.triangles = chunkData.triangles;
        mesh.normals = chunkData.normals;
        GetComponent<MeshFilter>().mesh = mesh;
        if (TerrainData.measureTime) Timer.EndMeasurement(chunkData);
    }

    public void GenerateMeshGPU_NoGeometry()
    {
        int triangleCount = terrainShaderManager.GetTriangleCount();

        Mesh mesh = new Mesh();
        mesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;

        Vector3[] vertices = new Vector3[triangleCount * 3];
        int[] triangles = new int[triangleCount * 3];
        for (int i = 0; i < triangleCount * 3; i++)
        {
            triangles[i] = i;
        }

        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.bounds = new Bounds(Vector3.zero, new Vector3(TerrainData.chunksSize, TerrainData.chunksSize, TerrainData.chunksSize));
        GetComponent<MeshFilter>().mesh = mesh;
        Material terrainMaterial = GetComponent<MeshRenderer>().material;
        terrainMaterial.SetBuffer("triangleBuffer", terrainShaderManager.GetOutputBuffer());

        if (TerrainData.measureTime) Timer.EndMeasurement(chunkData);
    }
}
