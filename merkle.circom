pragma circom 2.0.0;

include "mimcsponge.circom";

function checkEven(n) {
   // This function checks if the number can always be divided by 2
   // or else the template will throw an error when we will attempt to divide N by 2 

    if (n % 2 == 0) {
        return n;
    } else {
        return n + 1;
    }
}

template RootOfTree(N) { // This templates creates the whole structure of the merkle tree
    assert(N >= 1); // Making sure there is always more than one leaf
    
    signal input leaves[N]; // we take n number of leaves as signal input
    signal output root; // this template will output the root we are looking for

    component parent; // this creates the next level of leaves in the tree
    component hashing[checkEven(N) / 2];

    if (N == 1) {
        root <== leaves[0]; // final root produced
    } else {
        parent = RootOfTree(N / 2); // We call the template recursively until we end up on the root
        for (var i = 0; i < N; i += 2) { // This loop hashes using MiMCSponge two leaves into one
            var index = i / 2;           
            hashing[index] = MiMCSponge(2, 220, 1);

            hashing[index].ins[0] <== leaves[i];
            hashing[index].ins[1] <== leaves[i + 1]; // the leaf jut obtained becomes the next level leaf
            hashing[index].k <== 0;
            
            parent.leaves[i / 2] <== hashing[index].outs[0];
        }
        root <== parent.root; 
    }
}

template MerkleTree (nInputs) {  // The main template where we collect the initial leaves and output there root
    assert(nInputs >= 1); 

    signal input leaves[nInputs]; // We create an array of leaves to store the hash of the leaves obtained
    signal output merkRoot; // Final result 

    component rootComp = RootOfTree(nInputs); // links this template with the RootOfTree's one
    component hashing[nInputs];

    for (var i = 0; i < nInputs; i++) { // This loop hashes a leaf and sends the hash obtained
        hashing[i] = MiMCSponge(1, 220, 1); 
        
        hashing[i].ins[0] <== leaves[i];
        hashing[i].k <== 0;
        
        rootComp.leaves[i] <== hashing[i].outs[0]; // to the other template
    }

    merkleRoot <== rootComp.root; // it takes the final root of the tree from the other template
}

component main {public [leaves]} = MerkleTree(4); // In this case, we start with 4 leaves