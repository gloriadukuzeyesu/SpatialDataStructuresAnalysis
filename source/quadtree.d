import common; 

import std.stdio;
import std.math;
import std.algorithm;
import std.range;


struct QuadTree {

    alias P2 = Point!2; // P2 keyword will be used thru out the file. At compile time, It will be used as Point!2 
    Node root;

    class Node {
        // children NW, NE, SW, SE
        Node NW; 
        Node NE; 
        Node SW; 
        Node SE; 
        P2[] listOfPoints; // stores list of of points contained inside them.
        AABB!2 NodeBoundingBox;  // stores the region Node covers AABB 
        bool isLeaf = false; 

        // constructor of Node 
        this(P2[]list, size_t maxPoint, AABB!2 NodeBoundingBox) {

            if (list.length <= maxPoint) {
                // If the number of points is less than or equal to the threshold, assign the list of points to this node
                this.listOfPoints = list; 
                isLeaf = true; 
        
            } else {
                isLeaf = false; 
                 // Calculate the vertical and horizontal dividers
                auto X_mid= (NodeBoundingBox.min[0] + NodeBoundingBox.max[0]) / 2; 
                auto Y_mid = (NodeBoundingBox.min[1] + NodeBoundingBox.max[1]) / 2; 

               // mid (X_mid, Y_mid) 
                auto rightHalf = list.partitionByDimension!0(X_mid);
                auto leftHalf = list[0 .. $ - rightHalf.length];
                
                // divide the Left half into top and botton and use partitionByDimension to shovel all points based on their coordinates
                auto LeftTopHalf = leftHalf.partitionByDimension!1(Y_mid);
                auto leftBottonHalf = leftHalf[0 .. $ - LeftTopHalf.length];

                // divide the right halft into top and botton 
                auto rightTopHalf = rightHalf.partitionByDimension!1(Y_mid);
                auto rightBottomHalf = rightHalf[0 .. $ - rightTopHalf.length];

                AABB!2 nwNodeBoundingBox =  AABB!2 ( P2([NodeBoundingBox.min[0], Y_mid]), P2([X_mid, NodeBoundingBox.max[1]]));
                NW = new Node(LeftTopHalf, maxPoint,nwNodeBoundingBox);
        
                AABB!2 swNodeBoundingBox = AABB!2( P2([NodeBoundingBox.min[0], NodeBoundingBox.min[1]]), P2([X_mid,Y_mid])); 
                SW = new Node (leftBottonHalf, maxPoint, swNodeBoundingBox);
        
                AABB!2 nENodeBoundingBox = AABB!2( P2([X_mid,Y_mid]), P2( [NodeBoundingBox.max[0],NodeBoundingBox.max[1]] ));
                NE = new Node(rightTopHalf,maxPoint, nENodeBoundingBox); 

                AABB!2 seNodeBoundingBox =  AABB!2 ( P2([X_mid, NodeBoundingBox.min[1]]), P2([NodeBoundingBox.max[0], Y_mid]) );
                SE = new Node(rightBottomHalf,maxPoint,seNodeBoundingBox); 
            }
        }
    }

    // constructor of the Quad Tree 
    this(P2[] list, size_t maxPoint){
        AABB!2 NodeBoundingBox = boundingBox!2(list);
        root = new Node (list,maxPoint,NodeBoundingBox); 
    }


    bool isWithinChildBounds (P2 queryPoint,float radius, Node ChildNode) {
            AABB!2 childNodeBoundingBox = ChildNode.NodeBoundingBox;
            P2 closestPoint = closest(childNodeBoundingBox, queryPoint);
            // Check if the distance between the closest point and the query point
            // is less than or equal to the radius
            float distanceToClosestPoint = distance(closestPoint, queryPoint);
            return distanceToClosestPoint <= radius;
    }

    //rangeQuerry 
    P2[] rangeQuery(P2 queryPoint, float radius ) {
        P2[] ret;
       void recurse(Node node) {
            if(node.isLeaf) {
                foreach (point; node.listOfPoints) {
                    // check if the point is within the radius
                    if (distance(point,queryPoint) <= radius) {
                        ret ~= point; 
                    }
                }
            } else {
                //Non-leaf node: Determine which child/children
                //my_P2+radius is/are in, and call rangeQuery recursively

                if(node.NW !is null && isWithinChildBounds(queryPoint,radius,node.NW)) {
                   recurse(node.NW);
                }

                if(node.NE !is null && isWithinChildBounds(queryPoint,radius,node.NE) ) {
                   recurse(node.NE); 
                }

                if(node.SW !is null && isWithinChildBounds(queryPoint,radius,node.SW)) {
                    recurse(node.SW);
                }

                if (node.SE !is null && isWithinChildBounds(queryPoint,radius,node.SE)) {
                    recurse(node.SE); 
                }
                
            }
        }
        recurse(root); 
        return ret; 
    }


// K Nearest Neighbors
    P2[] knnQuery(P2 targetPoint, int K) {
        // Create a priority queue to keep track of the nearest points
        auto priorityQueue = makePriorityQueue(targetPoint);

        // Recursive function to traverse the quad tree
        void recurse(Node node){
            if(node.isLeaf) {
                // Leaf node: iterate through each point in the bucket
                foreach (point; node.listOfPoints) {
                    if ( priorityQueue.length < K) {
                        priorityQueue.insert(point);
                    } else {
                        // Get the farthest point from the priority queue
                        auto worstPoint = priorityQueue.front; // farthest point 
                        if (distance(point,targetPoint) < distance(targetPoint,worstPoint)) {
                            priorityQueue.popFront(); // remove the farthest point which is at the top of the queue
                            priorityQueue.insert(point); 
                        }
                    }
                }

            } else {
                // Internal node: traverse each child node
               // is priority queue not full or is node is closer than worst point
               // closest(node.NW.NodeBoundingBox, targetPoint) finds point that is closer from target point to the bounding box of the child 
                if (priorityQueue.length < K || distance(closest(node.NW.NodeBoundingBox, targetPoint), targetPoint) < distance(targetPoint, priorityQueue.front)){
                    recurse(node.NW);
                }

                if (priorityQueue.length < K || distance(closest(node.NE.NodeBoundingBox, targetPoint), targetPoint) < distance(targetPoint, priorityQueue.front)){
                    recurse(node.NE);
                }

                if (priorityQueue.length < K || distance(closest(node.SW.NodeBoundingBox, targetPoint), targetPoint) < distance(targetPoint, priorityQueue.front)){
                    recurse(node.SW);
                }

                if (priorityQueue.length < K || distance(closest(node.SE.NodeBoundingBox, targetPoint), targetPoint) < distance(targetPoint, priorityQueue.front)){
                    recurse(node.SE);
                }

            }
        }
        recurse(root);
        return priorityQueue.release; // use release to get the array out of the pq
    }


    /**
    NOT REQUIRED: 
    a helper function to find the lenght of tree or how many nodes are in the tree. 
    **/
    int findLength() {
        int count = 0;
        void recurse(Node node) {
            if (node.isLeaf) {
                // Leaf node: Add the number of points in the bucket
                count += node.listOfPoints.length;
            } else {
                // Internal node: Traverse each child node
                if (node.NW !is null) {
                    recurse(node.NW);
                }
                if (node.NE !is null) {
                    recurse(node.NE);
                }
                if (node.SW !is null) {
                    recurse(node.SW);
                }
                if (node.SE !is null) {
                    recurse(node.SE);
                }
            }
        }
        recurse(root);
        return count;
    }

}




unittest{
    writeln("Dummy Quad KnnQuer() Test");
    auto points = [Point!2([-1.3,2.1]), Point!2([-3.4,1.2]), Point!2([2.4,-3.5]), Point!2([0.1,-0.2]), Point!2([0.4,-0.3])];
    size_t maxPoints = 5; 
    auto aabb = boundingBox(points); 

    QuadTree quadTree = QuadTree(points,maxPoints);
    int length = quadTree.findLength(); 
    writeln("length**********", length); 
    int K = 5;
    auto closest_K = quadTree.knnQuery(Point!2([2,2]),K); 
    writeln("closest_K*********************", closest_K); 
}


unittest{
    writeln("Tree*******************START getGaussianPoints START ******************************************");
    // Generate Gaussian training points
    auto trainingPoints = getGaussianPoints!2(1000);
    // writeln(trainingPoints); 
    auto testingPoints = getUniformPoints!2(100);
    size_t maxpoints = 5; 
    auto quadTree = QuadTree(trainingPoints, maxpoints);
        foreach(const ref qp; testingPoints) {
        writeln("Query Point: ", qp);
        auto closestK = quadTree.knnQuery(qp, 2);
       writeln("Closest K: ", closestK);
        // Assertion: Ensure the number of closest points is less than or equal to K
        assert(closestK.length <= 10);
    }
    writeln("Tree*******************END   getGaussianPoints   END******************************************");
}



unittest {
    writeln("QuadTree knnQuery Test");
    auto points = [Point!2([-1.3, 2.1]), Point!2([-3.4, 1.2]), Point!2([2.4, -3.5]), Point!2([0.1, -0.2]), Point!2([0.4, -0.3])];
    size_t maxPoints = 5;
    QuadTree quadTree = QuadTree(points, maxPoints);
    int K = 2;
    auto closest_K = quadTree.knnQuery(Point!2([2, 2]), K);
    assert(closest_K.length == 2);
    assert(closest_K[0] == Point!2([0.1, -0.2]));
    assert(closest_K[1] == Point!2([0.4, -0.3]));
    writeln("closest_K    ", closest_K); 
}

unittest {
    writeln("QuadTree rangeQuery Test");
    auto points = [Point!2([-1.3, 2.1]), Point!2([-3.4, 1.2]), Point!2([2.4, -3.5]), Point!2([0.1, -0.2]), Point!2([0.4, -0.3])];
    size_t maxPoints = 5;
    QuadTree quadTree = QuadTree(points, maxPoints);
    float radius = 2.0;
    auto pointsInRange = quadTree.rangeQuery(Point!2([0, 0]), radius); // expect two points within this range. 
    assert(pointsInRange.length == 2);
    assert(pointsInRange[0] == Point!2([0.1, -0.2]));
    assert(pointsInRange[1] == Point!2([0.4, -0.3]));
    writeln("pointsInRange  ", pointsInRange); 
}

unittest {
    writeln("QuadTree Test1. knnQuery && rangeQuery ");
    auto points = [Point!2([-1.3, 2.1]), Point!2([-3.4, 1.2]), Point!2([2.4, -3.5]), Point!2([0.1, -0.2]), Point!2([0.4, -0.3])];
    size_t maxPoints = 5;
    QuadTree quadTree = QuadTree(points, maxPoints);

    int K = 2;
    auto closest_K = quadTree.knnQuery(Point!2([2, 2]), K);
    assert(closest_K.length == 2);
    assert(closest_K[0] == Point!2([0.1, -0.2]));
    assert(closest_K[1] == Point!2([0.4, -0.3]));

    float radius = 2.0;
    auto pointsInRange = quadTree.rangeQuery(Point!2([0, 0]), radius);
    assert(pointsInRange.length == 2);
    assert(pointsInRange[0] == Point!2([0.1, -0.2]));
    assert(pointsInRange[1] == Point!2([0.4, -0.3]));
}

unittest {
    writeln("QuadTree Test2. knnQuery && rangeQuery ");
    auto points = [Point!2([2, 3]), Point!2([1, 1]), Point!2([2, 6]), Point!2([3, 3])];
    size_t maxPoints = 4;
    QuadTree quadTree = QuadTree(points, maxPoints);
    int K = 3; 
    auto closest_K = quadTree.knnQuery(Point!2([2, 2]), K); 
    writeln("closest_K    ", closest_K); 
    assert(closest_K.length == 3);
    assert(closest_K[0] == Point!2([1,1]));
    assert(closest_K[1] == Point!2([2,3]));
    assert(closest_K[2] == Point!2([3,3]));
}







