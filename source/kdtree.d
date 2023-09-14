import std.stdio;
import std.math;
import std.algorithm;
import std.range;
import common; 

struct KDTree (size_t Dim) {

    alias PT = Point!Dim; 
    Node!0 root; // start with the 0 dim 

    // constructor for the KD_Tree 
    this(PT[] points) { root = new Node!0(points);}

    class Node( size_t splitDimension ) {
        // If this is an x node, the next level is "y"
        // If this is a y node, the next level is "z", etc
        enum thisLevel = splitDimension; // This lets you refer to a node's split level with theNode.thisLevel
        enum nextLevel = (splitDimension + 1) % Dim;  
        Node!nextLevel left, right; // Child nodes split by the next level
        PT splitPoint; // where the division is happening.  

        // constructor for the Node 
        this(PT[] points) {
            // base case, if there is only one point remains , no further subdivision is needed
            if(points.length == 1) {
                splitPoint = points[0]; // Store the single point stored in points as the split point 
            } else {
                auto LeftHalf = points.medianByDimension!thisLevel; // contains points from lowest to median point inclusive
                splitPoint = points[points.length / 2];      
                left = new Node!nextLevel(LeftHalf); 
                if(points.length > 2) {
                    auto rightHalf = points[LeftHalf.length + 1..$];
                    right = new Node!nextLevel(rightHalf);
                }
            }
          
        }
       
    }

    PT[] rangeQuery(PT query_pt, float radius) {
        PT[] list; 
        void recurse(size_t nodeDim) (Node!nodeDim node) {
            // check the distance and it to the list 
            //split point is close to the query point within the specified radius, less than means it is within the radius
            if(distance(node.splitPoint, query_pt) < radius) {
                list ~= node.splitPoint;
            }
            // Check if the current node's split point is close to the query point within the specified radius
            //  the split point is within the radius 
            if(node.left !is null && query_pt[node.nextLevel] - radius <= node.left.splitPoint[node.nextLevel]) { 
                recurse(node.left); 
            }
            // the splitpoint is out of the radius.
            if(node.right !is null && query_pt[node.nextLevel] + radius >= node.right.splitPoint[node.nextLevel]) {
                recurse(node.right); 
            }
        }
        recurse(root); 
        return list; // Return the list of points found within the specified radius
    }


    PT[] knnQuery(PT targetPoint, int K) {
        // Create a priority queue to keep track of the nearest points
        auto priorityQueue = makePriorityQueue!Dim(targetPoint);
        AABB!Dim root_abb = AABB!Dim(Point!Dim(-float.infinity), Point!Dim(float.infinity)); 

        void recurse(size_t nodeDim) (Node!nodeDim node, AABB!Dim parent_aabb) {
            // Check if the current node's split point should be inserted into the priority queue
            // If there are less points in the queue than the desired K, or the distance from the split point to the target point
            // is less than the distance from the target point to the point at the front of the queue, insert the split point.
            if (priorityQueue.length < K || distance(node.splitPoint, targetPoint) < distance(targetPoint, priorityQueue.front)) {
                if (priorityQueue.length >= K) {
                    // If the queue is already full (contains K points), remove the point at the front
                    priorityQueue.popFront();
                }
                priorityQueue.insert(node.splitPoint); // Insert the split point into the priority queue
            }

            // Define AABBs for the left and right child nodes
            AABB!Dim left_aabb = parent_aabb; 
            left_aabb.max[node.thisLevel] = node.splitPoint[node.thisLevel]; 
            AABB!Dim right_aabb = parent_aabb; 
            right_aabb.min[node.thisLevel] = node.splitPoint[node.thisLevel]; 

            // Recursively explore the left child node
            if(node.left !is null && (priorityQueue.length < K || distance( closest(left_aabb, targetPoint), targetPoint ) <= distance(targetPoint, priorityQueue.front))){
                recurse(node.left, left_aabb);
            }
            // Recursively explore the right child node if conditions are met
            if(node.right !is null &&  (priorityQueue.length < K || distance (targetPoint, closest(right_aabb, targetPoint)) <= distance ( targetPoint, priorityQueue.front))){
                recurse (node.right, right_aabb); 
            }
        }

        recurse(root,root_abb);
        return priorityQueue.release; 
    }
}


unittest{
    writeln("KDTree KNN Query() Test");
    Point!3[] points = [
        Point!3([4,5,6]),
        Point!3([16,17,18]),  
        Point!3([7,8,9]),
        Point!3([13,14,15]),
         Point!3([10,11,12]),
        Point!3([1,2,3])
        ];


    KDTree!3 kdTree = KDTree!3 (points); 
    auto queryPoint = Point!3([5, 6, 7]);
    float radius = 5.0;
    size_t K = 3; 
    Point!3[] result = kdTree.rangeQuery(queryPoint, K);
    writeln(" KNN Query() result  ", result); 
}


 unittest {
    writeln("****************************************KDTree KNN Query() Test ****************************************");
    Point!3[] points = [
        Point!3([4, 5, 6]),
        Point!3([16, 17, 18]),
        Point!3([7, 8, 9]),
        Point!3([13, 14, 15]),
        Point!3([10, 11, 12]),
        Point!3([1, 2, 3])
    ];

    KDTree!3 kdTree = KDTree!3(points);
    Point!3 queryPoint = Point!3([5, 6, 7]);
    int K = 3;
    Point!3[] result = kdTree.knnQuery(queryPoint, K);
    // Assert the expected number of results
    assert(result.length == K);
    // Assert the expected nearest point
    assert(result[0] == Point!3([1, 2, 3]));
    assert(result[1] == Point!3([4, 5, 6]));
    assert(result[2] == Point!3([7, 8, 9]));

    writeln("KDTree KNN Test");
    Point!2[] points2 = [
        Point!2([1,2]),
        Point!2([3,1]),  
        Point!2([2,3]),
        Point!2([1,5]),
        Point!2([5,1])
        ];

    KDTree!2 kdTree2 = KDTree!2 (points2); 
    auto qt = Point!2([3,3]);
    int k_val = 6;  // K is greater than the available points. 
    Point!2[] result2 = kdTree2.knnQuery(qt, k_val);
    assert(result2.length == 5);  
}


unittest {
    writeln("****************************************KDTree Range Query() Test ****************************************");
    Point!2[] pointsTwo = [
        Point!2([1,2]),
        Point!2([1,0]),  
        Point!2([0,1])
    ];
    auto qp = Point!2([0,0]);
    float rad = 2.0;
    KDTree!2 kdT = KDTree!2 (pointsTwo); 
    Point!2[] resultTwo = kdT.rangeQuery(qp, rad);
    writeln("resultTwo", resultTwo); 
}

