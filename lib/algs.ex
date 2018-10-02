defmodule Gossip.Algorithms do
	use GenServer

	def start_link(n, topo) do
		GenServer.start_link(__MODULE__, {topo, n, Map.new, Map.new, 0}, name: {:global, :main})
	end

	def program_start() do
		GenServer.cast({:global, :main}, {:start})
	end

	def program_finish(step) do
		GenServer.cast({:global, :main}, {:finish, step})
	end

	def acknowledge(id, step) do
		GenServer.cast({:global, :main}, {:acknowledged, id, step});
	end

	def finish(id, step) do
		GenServer.cast({:global, :main}, {:finished, id, step});
	end

	def init(args) do
		{:ok, args}
	end

	def handle_cast({:acknowledged, id, step}, {topo, num_nodes, ac_list, fi_list, mstep}) do
		#IO.inspect({:acknowledged, id})
		new_list = Map.put(ac_list, id, 1)
		if topo == "gossip" do
			if num_nodes == map_size(new_list) do
				program_finish(Kernel.max(mstep, step))
			end
		end
		{:noreply, {topo, num_nodes, new_list, fi_list, mstep}}
	end

	def handle_cast({:finished, id, step}, {topo, num_nodes, ac_list, fi_list, mstep}) do
		#IO.inspect({:finished, id, step})
		new_list = Map.put(fi_list, id, 1)
		if topo == "gossip" do
			if map_size(ac_list) == map_size(new_list) do
				program_finish(Kernel.max(mstep, step))
			end
		else
			program_finish(Kernel.max(mstep, step))
		end
		{:noreply, {topo, num_nodes, ac_list, new_list, Kernel.max(mstep, step)}}
	end

	def handle_cast({:start}, {topo, num_nodes, ac_list, fi_list, mstep}) do
		tar = Enum.random(1..num_nodes)
		IO.puts "First send message to Node No.#{tar}"
		Gossip.Node.send_message(tar, 0.0, 0.0, 0)
		{:noreply, {topo, num_nodes, ac_list, fi_list, mstep}}
	end

	def handle_cast({:finish, step}, {topo, num_nodes, ac_list, fi_list, mstep}) do
		if map_size(ac_list) < num_nodes do
			IO.puts "Some nodes haven't been told the message."
			t = Enum.to_list(1..num_nodes) -- Map.keys(ac_list)
			if length(t) < 50 do
				IO.puts "Unaccessed Nodes Num: #{length(t)}"
				IO.inspect t, label: "Unaccessed Nodes: "
			else
				IO.puts "Unaccessed Nodes Num: #{length(t)}"
				IO.inspect t, label: "Unaccessed Nodes(Too many): "
			end
		else
			IO.puts "All nodes have been told the message."
		end
		IO.puts "Total steps: #{step}"
		main = Process.whereis(:main)
		send(main, :finish)
		exit(:normal)
		{:noreply, {topo, num_nodes, ac_list, fi_list, mstep}}
	end
end