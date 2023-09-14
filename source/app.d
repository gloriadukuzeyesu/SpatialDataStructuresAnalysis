import std.stdio;

import common;
import dumbknn;
import bucketknn;
import kdTree; 
import quadtree; 
import std.csv;
import std.file;
import std.stdio;
import std.format;


void main()
{
    //because dim is a "compile time parameter" we have to use "static foreach"
    //to loop through all the dimensions we want to test.
    //the {{ are necessary because this block basically gets copy/pasted with
    //dim filled in with 1, 2, 3, ... 7.  The second set of { lets us reuse
    //variable names.

    writeln("dumbKNN results");
    static foreach(dim; 1..8){{
        //get points of the appropriate dimension
        auto trainingPoints = getGaussianPoints!dim(1000);
        auto testingPoints = getUniformPoints!dim(100);
        auto kd = DumbKNN!dim(trainingPoints);
        writeln("tree of dimension ", dim, " built");
        auto sw = StopWatch(AutoStart.no);
        sw.start; //start my stopwatch
        foreach(const ref qp; testingPoints){
           auto resp=  kd.knnQuery(qp, 10);
          // writeln(resp); 
        }
        sw.stop;
        writeln(dim, sw.peek.total!"usecs"); //output the time elapsed in microseconds
        //NOTE, I SOMETIMES GOT TOTALLY BOGUS TIMES WHEN TESTING WITH DMD
        //WHEN YOU TEST WITH LDC, YOU SHOULD GET ACCURATE TIMING INFO...
    }}


  


     // Parameters to vary
    int[] K_values = [9,23,55,70,89,100,120, 150, 250, 50, 25, 200,390, 300, 150, 19, 61, 82, 143, 177, 269];

    int[] N_values = [1000,2084,3324,9098,11039,19168,7296,2000,3000,4000, 5500, 7891,9715, 13171, 1121,20000,35890,4274,4645,9209,11374,24948,26893,29294, 24950, 31369, 31345, 33868,17860, 22753,23841];
  
    // constant values 
    enum dim = 2; 
    enum dimension = 3;
    int K = 10; 
    int  experiments = 3; 
    enum numTrainingPoints = 1000;

    
    File file1 = File("1vary_N_Fixed_D2_and_K.csv", "w");
    file1.writeln(format("dataStructure,K,numTrainingPoints,dim,AverageTime")); 
    writeln("Varying N, FIXED D = 2 and K ");
    foreach(points; N_values)
    {
        auto trainingPoints = getGaussianPoints!dim(points); 
        auto testingPoints = getUniformPoints!dim(100); 
        long kdTotalTime= 0; 
        long quadTotalTime = 0; 
        long bucketTotalTime = 0; 


        // KD TREE
        auto kd_tree = KDTree!dim(trainingPoints);
        for( int exper = 0; exper < experiments; exper++) 
        {
            auto sw = StopWatch(AutoStart.no); // start the timer 
            sw.start; 
            foreach(const ref qp; testingPoints) 
            {
                kd_tree.knnQuery(qp,10);
            }
            sw.stop; 
            kdTotalTime += sw.peek.total!"usecs";
        }
        auto kdAverageTime =  kdTotalTime / experiments; 
        
        file1.writeln(format("KD, %d, %d, %d, %d", K, points, dim, kdAverageTime)); 


        // QUAD TREE
        size_t maxPoint = 10; 
        auto quadTree = QuadTree(trainingPoints, maxPoint);
        for(int exper = 0; exper < experiments; exper++) 
        {
            auto sw = StopWatch(AutoStart.no); // start the timer 
            sw.start; 
            foreach(const ref qp; testingPoints) 
            {
                quadTree.knnQuery(qp,K);
            }
            sw.stop; 
            quadTotalTime += sw.peek.total!"usecs";
        }
        auto quadAverageTime =  quadTotalTime / experiments; 
        file1.writeln(format("Quad, %d, %d, %d, %d", K, points, dim, quadAverageTime)); 

        // BUCKET TREE
        auto bucketTree = BucketKNN!dim(trainingPoints, cast(int)pow(points/64, 1.0/dim)); //rough estimate to get 64 points per cell on average

        for(int i = 0; i < experiments ; i++) {
            auto sw = StopWatch(AutoStart.no);
            sw.start; //start my stopwatch
            foreach(const ref qp; testingPoints) 
            {
                bucketTree.knnQuery(qp, 10);
            }
            sw.stop;
            bucketTotalTime += sw.peek.total!"usecs"; 
        }
        auto bucketAverageTime =  bucketTotalTime / experiments;
        file1.writeln(format("Bucket, %d, %d, %d, %d", K, points, dim, bucketAverageTime)); 
    }

    /*********/

    File file2 = File("2vary_K_Fixed_D2_and_N.csv", "w");
    file2.writeln(format("dataStructure,K,numTrainingPoints,dim,AverageTime"));

    writeln("Varying K, FIXED D = 2 and FIXED N"); 
    foreach(k; K_values)
    {{
        auto trainingPoints = getGaussianPoints!dim(numTrainingPoints);
        auto testingPoints = getUniformPoints!dim(100);
        long kdTotalTime= 0; 
        long quadTotalTime = 0; 
        long bucketTotalTime = 0;

        // KD TREE
        auto kdTree = KDTree!dim(trainingPoints); //rough estimate to get 64 points per cell on average

        for(int exper = 0; exper < 3; exper++)
        {
            auto sw = StopWatch(AutoStart.no);
            sw.start; //start my stopwatch
            foreach(const ref qp; testingPoints)
            {
                kdTree.knnQuery(qp, k);
            }
            sw.stop;
            kdTotalTime += sw.peek.total!"usecs";
        }
        auto kdAverageTime =  kdTotalTime / experiments; 
        file2.writeln(format("KD, %d, %d, %d, %d", k, numTrainingPoints, dim, kdAverageTime)); 

        // QUAD TREE
        size_t maxPoint = 10; 
        auto quadTree = QuadTree(trainingPoints, maxPoint);
        for(int exper = 0; exper < experiments; exper++) 
        {
            auto sw = StopWatch(AutoStart.no); // start the timer 
            sw.start; 
            foreach(const ref qp; testingPoints) 
            {
                quadTree.knnQuery(qp,k);
            }
            sw.stop; 
            quadTotalTime += sw.peek.total!"usecs";
        }
        auto quadAverageTime =  quadTotalTime / experiments; 
        file2.writeln(format("Quad, %d, %d, %d, %d", k, numTrainingPoints, dim, quadAverageTime)); 

        // BUCKET TREE
        auto bucketTree = BucketKNN!dim(trainingPoints, cast(int)pow(numTrainingPoints/64, 1.0/dim)); //rough estimate to get 64 points per cell on average
        for(int i = 0; i < experiments ; i++) {
            auto sw = StopWatch(AutoStart.no);
            sw.start; //start my stopwatch
            foreach(const ref qp; testingPoints) 
            {
                bucketTree.knnQuery(qp, k);
            }
            sw.stop;
            bucketTotalTime += sw.peek.total!"usecs"; 
        }
        auto bucketAverageTime =  bucketTotalTime / experiments;
        file2.writeln(format("Bucket, %d, %d, %d, %d", k, numTrainingPoints, dim, bucketAverageTime)); 
    }}

    /*********/

    File file3 = File("3vary_D_Fixed_N_and_K.csv", "w");
    file3.writeln(format("dataStructure,K,numTrainingPoints,dim,AverageTime"));

    writeln("********************************************data set where you vary one of k, N, or D at a time********************************************"); 

    writeln("Varying D, FIXED N and K"); 
    static foreach(Dim; 3..10)
    {{
        auto trainingPoints = getGaussianPoints!Dim(numTrainingPoints);
        auto testingPoints = getUniformPoints!Dim(100);
        long kdTotalTime= 0; 
        long quadTotalTime = 0; 
        long bucketTotalTime = 0; 

        // KD 
        auto kdTree = KDTree!Dim(trainingPoints); //rough estimate to get 64 points per cell on average

        for(int exper = 0; exper < 3; exper++)
        {
            auto sw = StopWatch(AutoStart.no);
            sw.start; //start my stopwatch
            foreach(const ref qp; testingPoints)
            {
                kdTree.knnQuery(qp, 10);
            }
            sw.stop;
            kdTotalTime += sw.peek.total!"usecs";
        }
        auto kdAverageTime =  kdTotalTime / experiments; 
        file3.writeln(format("KD, %d, %d, %d, %d", K, numTrainingPoints, Dim, kdAverageTime)); 

        // QUAD TREE
        static if(Dim == 2)
        {
            writeln("Dim", Dim);
            size_t maxPoint = 10; 
            auto quadTree = QuadTree(trainingPoints, maxPoint);
            for(int exper = 0; exper < experiments; exper++) 
            {
                auto sw = StopWatch(AutoStart.no); // start the timer 
                sw.start; 
                foreach(const ref qp; testingPoints) 
                {
                    quadTree.knnQuery(qp,10);
                }
                sw.stop; 
                quadTotalTime += sw.peek.total!"usecs";
            }
            auto quadAverageTime =  quadTotalTime / experiments; 
            file3.writeln(format("Quad, %d, %d, %d, %d", K, numTrainingPoints, dim, quadAverageTime)); 
        }
        // BUCKET TREE
        auto bucketTree = BucketKNN!Dim(trainingPoints, cast(int)pow(numTrainingPoints/64, 1.0/Dim)); //rough estimate to get 64 points per cell on average
        for(int i = 0; i < experiments ; i++) {
            auto sw = StopWatch(AutoStart.no);
            sw.start; //start my stopwatch
            foreach(const ref qp; testingPoints) 
            {
                bucketTree.knnQuery(qp, 10);
            }
            sw.stop;
            bucketTotalTime += sw.peek.total!"usecs"; 
        }
        auto bucketAverageTime =  bucketTotalTime / experiments;
        file3.writeln(format("Bucket, %d, %d, %d, %d", K, numTrainingPoints, Dim, bucketAverageTime)); 
    }}

    /*********/

    File file4 = File("4vary_K_Fixed_D_and_N.csv", "w");
    file4.writeln(format("dataStructure,K,numTrainingPoints,dim,AverageTime"));

    writeln("Varying K, FIXED D > 2 and FIXED N"); 
    foreach(k; K_values)
    {{
        auto trainingPoints = getGaussianPoints!dimension(numTrainingPoints);
        auto testingPoints = getUniformPoints!dimension(100);
        long kdTotalTime= 0; 
        long quadTotalTime = 0; 
        long bucketTotalTime = 0;

        // KD TREE
        auto kdTree = KDTree!dimension(trainingPoints); //rough estimate to get 64 points per cell on average

        for(int exper = 0; exper < 3; exper++)
        {
            auto sw = StopWatch(AutoStart.no);
            sw.start; //start my stopwatch
            foreach(const ref qp; testingPoints)
            {
                kdTree.knnQuery(qp, k);
            }
            sw.stop;
            kdTotalTime += sw.peek.total!"usecs";
        }
        auto kdAverageTime =  kdTotalTime / experiments; 
        file4.writeln(format("KD, %d, %d, %d, %d", k, numTrainingPoints, dimension, kdAverageTime)); 

        // BUCKET TREE
        auto bucketTree = BucketKNN!dimension(trainingPoints, cast(int)pow(numTrainingPoints/64, 1.0/dimension)); //rough estimate to get 64 points per cell on average

        for(int i = 0; i < experiments ; i++) {
            auto sw = StopWatch(AutoStart.no);
            sw.start; //start my stopwatch
            foreach(const ref qp; testingPoints) 
            {
                bucketTree.knnQuery(qp, k);
            }
            sw.stop;
            bucketTotalTime += sw.peek.total!"usecs"; 
        }
        auto bucketAverageTime =  bucketTotalTime / experiments;
        file4.writeln(format("Bucket, %d, %d, %d, %d", k, numTrainingPoints, dimension, bucketAverageTime)); 
    }}


    /*********/

    File file5 = File("5vary_N_Fixed_K_and_D.csv", "w");
    file5.writeln(format("dataStructure,K,numTrainingPoints,dim,AverageTime"));

    writeln("Varying N, fixed K and fixed D");
    foreach(points; N_values)
    {
        auto trainingPoints = getGaussianPoints!dimension(points); 
        auto testingPoints = getUniformPoints!dimension(100); 
        long kdTotalTime= 0; 
        long quadTotalTime = 0; 
        long bucketTotalTime = 0; 


        // KD TREE
        auto kd_tree = KDTree!dimension(trainingPoints);
        for( int exper = 0; exper < experiments; exper++) 
        {
            auto sw = StopWatch(AutoStart.no); // start the timer 
            sw.start; 
            foreach(const ref qp; testingPoints) 
            {
                kd_tree.knnQuery(qp,10);
            }
            sw.stop; 
            kdTotalTime += sw.peek.total!"usecs";
        }
        auto kdAverageTime =  kdTotalTime / experiments; 
        file5.writeln(format("KD, %d, %d, %d, %d", K, points, dim, kdAverageTime)); 

        // BUCKET TREE
        auto bucketTree = BucketKNN!dimension(trainingPoints, cast(int)pow(points/64, 1.0/dimension)); //rough estimate to get 64 points per cell on average

        for(int i = 0; i < experiments ; i++) {
            auto sw = StopWatch(AutoStart.no);
            sw.start; //start my stopwatch
            foreach(const ref qp; testingPoints) 
            {
                bucketTree.knnQuery(qp, 10);
            }
            sw.stop;
            bucketTotalTime += sw.peek.total!"usecs"; 
        }
        auto bucketAverageTime =  bucketTotalTime / experiments;
        file5.writeln(format("Bucket, %d, %d, %d, %d", K, points, dimension, bucketAverageTime)); 
    }

    file1.close; 
    file2.close;   
    file3.close;   
    file4.close;   
    file5.close; 
}