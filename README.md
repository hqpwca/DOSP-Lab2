# Gossip

## Group member
* Ke Chen 8431-0979
* Bochen Li  

## Running Instruction

* Run `mix escript.build` to build the exectable file of the program
* Run `./gossip [numNodes] [topology] [algorithm] [numfailedNodes]` to run the actual program. (you can also see the Usage by simply run `./gossip` in the command line.

## Convergence
* The Gossip Algorithm will converge when all actors(nodes) have been accessed.
* The Push-Sum Algorithm will converge when one actor(node)'s sum estimation has not changed for 3 times(changing less than 1e-10.

## Time Calculation
We used 2 ways to calculate the total time of the algorithm

* The first way is simply use the Erlang module timer to get the running time of the whole program. We use `:timer.rc` to get the running time of the message passing part of the program (Ignored the time to build the topology).

> We all know that one computer only have limited cores. So we can't model the actual situation in the gossip algorithm. The nodes should be able to transfer in the same time, but when we run the program, only several actors can send and receive message simutaneously. 

> So we used another type of time calculation. Use the steps of the message to show the whole running time in order to get nearer to the actual situation. 

* The step is calculated in the following way:
	1. (Gossip) When a unvisited actor receive a message with step `k`, it will set its step to `k+1`. Then create a subprocess with step `k+1`.
	2. (Gossip) Every time the subprocess sends a message, it will attach the step of itself to the message, then it will increase its own step after it finish sending a message.
	3. (Gossip) The Main process will get when the step of each of the actors when it was acknowledged, and save the maximum. The final running time will be the maximum step when the program converges.
	4. (Pushsum) Since push-sum has only one message to transfer, the step is simply how many nodes the message has visited before it converges.

## Largest Programmes

* Gossip
	1. Full: 4096 nodes (The graph is so large that the time for building topology is longer than the actual running time)
	2. 3D: 64000 nodes (Running larger number of nodes will sometimes get error `(SystemLimitError) a system limit has been reached`)
	3. Rand2D: 8192 nodes (We could actually solve a much larger problem, but we haven't achieve a better way to build the graph, so the graph building time is too long)
	4. Sphere: 8100 nodes (The running time can be very different, sometimes the 
	5. Line: 100 nodes (Larger number of nodes will usually have some node unaccessed)
	6. Imperfect Line: 2000 nodes (Larger number of nodes will usually have some node unaccessed)
* Push-Sum (All node converged)
	1. Full: 500 nodes (Becoming slow rapidly when num of nodes becomes larger )
	2. 3D: 1000 nodes (Slightly faster than full)
	3. Rand2D: 500 nodes (Slower than full)
	4. Sphere: 1444 nodes (Faster than the previous 3)
	5. Line: 400 nodes (Slowest)
	6. Imperfect Line: 20000 nodes (Fastest, time increases almost linearly with num of nodes)