defmodule Gossip.Topology do
	def build(num_nodes, type, topology, fail_nodes) do
		start_nodes(num_nodes, type)
		new_num_nodes =
			case topology do
				"full" -> 
					build_full(num_nodes, 1, 2)
					num_nodes
				"3D" -> 
					len = Kernel.trunc(nth_root(3, num_nodes))
					build_3D(len, len*len*len, 1, 1, 1, 1)
					len*len*len
				"rand2D" -> 
					posx = List.to_tuple Enum.map(1..num_nodes, fn(x) -> :rand.uniform end)
					posy = List.to_tuple Enum.map(1..num_nodes, fn(x) -> :rand.uniform end)
					build_rand2D(num_nodes, 1, 2, posx, posy)
					num_nodes
				"sphere" ->
					len = Kernel.trunc(nth_root(2, num_nodes))
					build_sphere(len, len*len, 1, 1, 1)
					len * len
				"line" -> 
					build_line(num_nodes, 2)
					num_nodes
				"imp2D" ->
					build_line(num_nodes, 2)
					unlinked_list = Enum.to_list(1..num_nodes)
					build_imp2D(1, unlinked_list)
					num_nodes
				_ ->
					IO.puts "Error: Topology type error!"
					num_nodes
			end

		IO.puts("Topology build complete.")

		fail_list = 
			if fail_nodes > 0 do
				Enum.take_random(1..new_num_nodes, fail_nodes)
			else
				nil
			end

		if fail_list != nil do
			fail_list = Enum.sort(fail_list)
			Enum.each(fail_list, fn(x) -> Gossip.Node.set_failed(x) end)
			IO.puts("Failed nodes shutted down complete.")
		end

		{new_num_nodes, fail_list}
	end

	def start_nodes(num_nodes, type) do
		Enum.each(1..num_nodes, fn(x) -> Gossip.Node.start_link(x, type) end)
	end

	def nth_root(n, x, precision \\ 1.0e-5) do
		f = fn(prev) -> ((n - 1) * prev + x / :math.pow(prev, (n-1))) / n end
		fixed_point(f, x, precision, f.(x))
	end
 
	defp fixed_point(_, guess, tolerance, next) when abs(guess - next) < tolerance, do: next
	defp fixed_point(f, _, tolerance, next), do: fixed_point(f, next, tolerance, f.(next))

	def build_full(num_nodes, p1, p2) when p2 > num_nodes, do: nil
	def build_full(num_nodes, p1, p2) do
		Gossip.Node.add_edge(p1, p2)
		if p2 < num_nodes do
			build_full(num_nodes, p1, p2 + 1)
		else
			build_full(num_nodes, p1 + 1, p1 + 2)
		end
	end

	def build_3D(len, num_nodes, x, y, z, pos) when pos == num_nodes, do: nil
	def build_3D(len, num_nodes, x, y, z, pos) do
		if x < len, do: Gossip.Node.add_edge(pos, pos + 1)
		if y < len, do: Gossip.Node.add_edge(pos, pos + len)
		if z < len, do: Gossip.Node.add_edge(pos, pos + len * len)

		if x < len, do: build_3D(len, num_nodes, x+1, y, z, pos + 1)
		if x == len && y < len, do: build_3D(len, num_nodes, 1, y + 1, z, pos + 1)
		if x == len && y == len, do: build_3D(len, num_nodes, 1, 1, z+1, pos + 1)
	end

	def build_rand2D(num_nodes, p1, p2, posx, posy) when p2 > num_nodes, do: nil
	def build_rand2D(num_nodes, p1, p2, posx, posy) do
		disx = elem(posx, p1 - 1) - elem(posx, p2 - 1)
		disy = elem(posy, p1 - 1) - elem(posy, p2 - 1)
		if :math.sqrt(disx*disx + disy*disy) < 0.1 do
			Gossip.Node.add_edge(p1, p2)
		end
		if p2 < num_nodes do
			build_rand2D(num_nodes, p1, p2 + 1, posx, posy)
		else
			build_rand2D(num_nodes, p1 + 1, p1 + 2, posx, posy)
		end
	end

	def build_sphere(len, num_nodes, x, y, pos) do
		if x < len, do: Gossip.Node.add_edge(pos, pos + 1), else: Gossip.Node.add_edge(pos, pos - len + 1)
		if y < len, do: Gossip.Node.add_edge(pos, pos + len), else: Gossip.Node.add_edge(pos, Integer.mod(pos-1, len) + 1)

		if x < len, do: build_sphere(len, num_nodes, x+1, y, pos + 1)
		if x == len && y < len, do: build_sphere(len, num_nodes, 1, y + 1, pos + 1)
	end

	def build_line(num_nodes, pos) when pos > num_nodes, do: nil
	def build_line(num_nodes, pos) do
		Gossip.Node.add_edge(pos, pos-1)
		if pos < num_nodes, do: build_line(num_nodes, pos + 1)
	end

	def build_imp2D(pos, ulist) do
		if Enum.empty?(ulist) do
			nil
		else
			nlist =
				if pos in ulist do
					tlist = List.delete(ulist, pos)
					tar = Enum.random(tlist)
					tlist = List.delete(tlist, tar)
					Gossip.Node.add_edge(pos, tar)
					tlist
				else
					ulist
				end
			build_imp2D(pos + 1, nlist)
		end
	end
end