defmodule Gossip do
	def main(args) do
		unless length(args) == 4 do
			IO.puts "Usage: ./gossip numNodes topos(full, 3D, rand2D, sphere, line, imp2D) algs(gossip, push-sum) failedNodes"
		else
			numNodes  = Enum.at(args,0) |> String.to_integer()
			topology  = Enum.at(args,1)
			algorithm = Enum.at(args,2)
			failNodes = Enum.at(args,3) |> String.to_integer()
			
			if numNodes < failNodes, do: IO.puts("Too many failNodes!")

			{numNodes, failList} = Gossip.Topology.build(numNodes, algorithm, topology, failNodes)
			IO.puts "Final nodes after fitting in topology: #{numNodes}"
			if failList != nil, do: IO.inspect failList, label: "Fail Nodes List: "

			Gossip.Algorithms.start_link(numNodes, algorithm, failNodes)
			{time,_} = :timer.tc(fn -> time_algs end)
			IO.puts "Actual Time: #{time}"
		end
	end

	def time_algs() do
		Process.register(self(), :main)
		Gossip.Algorithms.program_start
		receive do
			:finish -> nil
		end
	end
end