using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;

public class TerrainShaderManager
{
    private ComputeShader terrainComputeShader;
    private ComputeBuffer voxelBuffer;
    private ComputeBuffer triangleTmpBuffer;
    private ComputeBuffer triangleBuffer;
    private ComputeBuffer outputTriangleBuffer;
    private ComputeBuffer triangleCountBuffer;

    Kernel generateVoxelValuesKernel;
    Kernel runMarchinCubesKernel;
    Kernel smoothNormalsKernel;
    Kernel createOutputKernel;

    public void InitShader(Chunk.ChunkData chunkData)
    {
        terrainComputeShader = (ComputeShader)Resources.Load("Shaders/TerrainGenerator");
        terrainComputeShader.SetFloat("chunkPositionX", chunkData.position.x);
        terrainComputeShader.SetFloat("chunkPositionY", chunkData.position.y);
        terrainComputeShader.SetFloat("chunkPositionZ", chunkData.position.z);
        terrainComputeShader.SetInt("normalSmoothRange", TerrainData.smoothNormals ? 1 : 0);
        terrainComputeShader.SetInt("isTopChunk", chunkData.chunkY == TerrainData.chunksY - 1 ? 1 : 0);
        terrainComputeShader.SetInt("isBottomChunk", chunkData.chunkY == 0 ? 1 : 0);
        terrainComputeShader.SetInt("chunkMaxVoxelsSide", TerrainData.chunkVoxelsSide);
        terrainComputeShader.SetInt("chunkVoxelsSideX", chunkData.chunkVoxelsSideX);
        terrainComputeShader.SetInt("chunkVoxelsSideY", chunkData.chunkVoxelsSideY);
        terrainComputeShader.SetInt("chunkVoxelsSideZ", chunkData.chunkVoxelsSideZ);
        terrainComputeShader.SetInt("chunkMaxCubesSide", TerrainData.chunkCubesSide);
        terrainComputeShader.SetInt("chunkCubesSideX", chunkData.chunkCubesSideX);
        terrainComputeShader.SetInt("chunkCubesSideY", chunkData.chunkCubesSideY);
        terrainComputeShader.SetInt("chunkCubesSideZ", chunkData.chunkCubesSideZ);
        terrainComputeShader.SetFloat("cubeSize", TerrainData.cubeSize);
        terrainComputeShader.SetFloat("maxTerrainSize", TerrainData.maxTerrainSize);
        // noise
        terrainComputeShader.SetInt("seed", TerrainData.seed);
        terrainComputeShader.SetInt("noiseLayers", TerrainData.noiseLayers);
        terrainComputeShader.SetFloat("noiseFrequency", TerrainData.noiseFrequency);
        terrainComputeShader.SetFloat("noiseStrength", TerrainData.noiseStrength);
        terrainComputeShader.SetFloat("noiseLayerFrequencyMultiplier", TerrainData.noiseLayerFrequencyMultiplier);
        generateVoxelValuesKernel = new Kernel(terrainComputeShader, "GenerateVoxelValues");
        runMarchinCubesKernel = new Kernel(terrainComputeShader, "RunMarchinCubes");
        smoothNormalsKernel = new Kernel(terrainComputeShader, "SmoothNormals");
        createOutputKernel = new Kernel(terrainComputeShader, "CreateOutput");
    }

    public void RunShader(Chunk.ChunkData chunkData)
    {
        int totalVoxels = TerrainData.chunkVoxelsSide * TerrainData.chunkVoxelsSide * TerrainData.chunkVoxelsSide;
        int totalCubes = TerrainData.chunkCubesSide * TerrainData.chunkCubesSide * TerrainData.chunkCubesSide;
        int totalTriangles = totalCubes * 5;

        if (TerrainData.measureTime) Timer.StartMeasurement(Timer.MeasurementType.Voxel_Generation, chunkData);
        voxelBuffer = new ComputeBuffer(totalVoxels, Marshal.SizeOf(typeof(TerrainData.Voxel)));
        generateVoxelValuesKernel.SetBuffer("voxelBuffer", voxelBuffer);
        generateVoxelValuesKernel.Dispatch(totalVoxels);
        if (TerrainData.measureTime) Timer.EndMeasurement(chunkData);

        if (TerrainData.measureTime) Timer.StartMeasurement(Timer.MeasurementType.Marching_Cubes, chunkData);
        triangleTmpBuffer = new ComputeBuffer(totalTriangles, Marshal.SizeOf(typeof(TerrainData.TriangleTmp)));
        runMarchinCubesKernel.SetBuffer("voxelBuffer", voxelBuffer);
        runMarchinCubesKernel.SetBuffer("triangleTmpBuffer", triangleTmpBuffer);
        runMarchinCubesKernel.Dispatch(totalCubes);
        if (TerrainData.measureTime) Timer.EndMeasurement(chunkData);

        if (TerrainData.measureTime) Timer.StartMeasurement(Timer.MeasurementType.Mesh_Smoothing, chunkData);
        triangleBuffer = new ComputeBuffer(totalTriangles, Marshal.SizeOf(typeof(TerrainData.Triangle)));
        smoothNormalsKernel.SetBuffer("triangleTmpBuffer", triangleTmpBuffer);
        smoothNormalsKernel.SetBuffer("triangleBuffer", triangleBuffer);
        smoothNormalsKernel.Dispatch(totalTriangles);
        if (TerrainData.measureTime) Timer.EndMeasurement(chunkData);

        if (TerrainData.measureTime) Timer.StartMeasurement(Timer.MeasurementType.Mesh_Building, chunkData);
        outputTriangleBuffer = new ComputeBuffer(totalTriangles, Marshal.SizeOf(typeof(TerrainData.Triangle)), ComputeBufferType.Append);
        outputTriangleBuffer.SetCounterValue(0);
        createOutputKernel.SetBuffer("triangleBuffer", triangleBuffer);
        createOutputKernel.SetBuffer("outputTriangleBuffer", outputTriangleBuffer);
        createOutputKernel.Dispatch(totalTriangles);
    }

    public void GenerateMeshData(Chunk.ChunkData chunkData)
    {
        // Get triangle data from shader
        int triangleCount = GetTriangleCount();
        TerrainData.Triangle[] triangleStructs = new TerrainData.Triangle[triangleCount];
        outputTriangleBuffer.GetData(triangleStructs, 0, 0, triangleCount);

        Vector3[] vertices = new Vector3[triangleCount * 3];
        int[] triangles = new int[triangleCount * 3];
        Vector3[] normals = new Vector3[triangleCount * 3];

        for (int i = 0; i < triangleCount; i++)
        {
            TerrainData.Triangle triangleStruct = triangleStructs[i];
            vertices[i * 3] = triangleStruct.v1;
            vertices[i * 3 + 1] = triangleStruct.v2;
            vertices[i * 3 + 2] = triangleStruct.v3;
            triangles[i * 3] = i * 3;
            triangles[i * 3 + 1] = i * 3 + 1;
            triangles[i * 3 + 2] = i * 3 + 2;
            normals[i * 3] = triangleStruct.n1;
            normals[i * 3 + 1] = triangleStruct.n2;
            normals[i * 3 + 2] = triangleStruct.n3;
        }

        chunkData.vertices = vertices;
        chunkData.triangles = triangles;
        chunkData.normals = normals;
    }

    public int GetTriangleCount()
    {
        // Get number of triangles in the triangle buffer
        triangleCountBuffer = new ComputeBuffer(1, sizeof(int), ComputeBufferType.Raw);
        ComputeBuffer.CopyCount(outputTriangleBuffer, triangleCountBuffer, 0);
        int[] triangleCountArray = { 0 };
        triangleCountBuffer.GetData(triangleCountArray);
        return triangleCountArray[0];
    }

    public ComputeBuffer GetOutputBuffer()
    {
        return outputTriangleBuffer;
    }

    public struct Kernel
    {
        private int kernelNum;
        private int threadNum;
        private ComputeShader computeShader;

        public Kernel(ComputeShader computeShader, string kernelName)
        {
            this.computeShader = computeShader;
            kernelNum = this.computeShader.FindKernel(kernelName);
            this.computeShader.GetKernelThreadGroupSizes(kernelNum, out uint threadNumOutX, out _, out _);
            threadNum = (int) threadNumOutX;
        }

        public void SetBuffer(string bufferName, ComputeBuffer computeBuffer)
        {
            computeShader.SetBuffer(kernelNum, bufferName, computeBuffer);
        }

        public void Dispatch(int totalThreads)
        {
            computeShader.Dispatch(kernelNum, Mathf.CeilToInt((float)totalThreads / threadNum), 1, 1);
        }
    }

    public void CleanUp(bool clearOutputBuffer)
    {
        voxelBuffer.Release();
        triangleTmpBuffer.Release();
        triangleBuffer.Release();
        triangleCountBuffer.Release();
        if (clearOutputBuffer) outputTriangleBuffer.Release();
    }
}
