defmodule Gossip.Node do
	use GenServer

	def start_link(id, type) do
		if type == "gossip" do
			GenServer.start_link(__MODULE__, {:gossip, id, 0, 0, 0, [], 0, false}, name: {:global, id})
		else
			GenServer.start_link(__MODULE__, {:pushsum, id, id/1, 1.0, 0, [], 0, false}, name: {:global, id})
		end
	end

	def add_edge(id1, id2) do
		#IO.inspect {id1, id2}
		GenServer.cast({:global, id1}, {:link, id2})
		GenServer.cast({:global, id2}, {:link, id1})
	end

	def send_message(id, s, w, step) do
		GenServer.cast({:global, id}, {:message, s, w, step})
	end

	def set_failed(id) do
		GenServer.cast({:global, id}, {:failed})
	end

	def init(_args) do
		{:ok, _args}
	end

	def handle_cast({:message, ms, mw, tstep}, {type, id, s, w, times, neighbors, step, fail}) do
		#IO.inspect({:message, ms, mw, tstep, id, s, w})
		nstep = Kernel.max(step, tstep + 1)
		if type == :gossip do
			subname = "subprocess"<> Integer.to_string(id) |> String.to_atom()
			subpro = Process.whereis(subname)
			if subpro == nil && times < 10 && !fail do
				Gossip.Algorithms.acknowledge(id, nstep)
				subpro = spawn(Gossip.Node, :keep_sending_message, [neighbors, nstep])
				Process.register(subpro, subname)
			end
			new_times = times + 1
			if Process.whereis(subname) != nil && new_times >= 10 do
				Process.sleep(5)
				if Process.whereis(subname) != nil && new_times >= 10 do
					Process.whereis(subname) |> Process.exit(:kill)
					#IO.puts "sub process terminated: #{subname}"
				end
				Gossip.Algorithms.finish(id, nstep)
			end
			{:noreply, {type, id, s, w, new_times, neighbors, nstep, fail}}
		else
			if times == 0, do: Gossip.Algorithms.acknowledge(id, nstep)
			new_times = 
				if mw == 0.0 || Kernel.abs(ms/mw - s/w) > 1.0e-10 do
					1
				else
					times + 1
				end
			ns = s + ms
			nw = w + mw
			target = Enum.random(neighbors)
			if new_times <= 3 && !fail do
				send_message(target, ns/2, nw/2, nstep)
			else
				Gossip.Algorithms.finish(id, nstep)
			end
			{:noreply, {type, id, ns/2, nw/2, new_times, neighbors, nstep, fail}}
		end
	end

	def handle_cast({:link, tid}, {type, id, s, w, times, neighbors, step, fail}) do
		{:noreply, {type, id, s, w, times, neighbors ++ [tid], step, fail}}
	end

	def handle_cast({:failed}, {type, id, s, w, times, neighbors, step, fail}) do
		{:noreply, {type, id, s, w, times, neighbors, step, true}}
	end

	def keep_sending_message(neighbors, step) do
		target = Enum.random(neighbors)
		send_message(target, 0, 0, step)
		keep_sending_message(neighbors, step + 1)
	end
end