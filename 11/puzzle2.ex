defmodule Foo do

  # part 1 has Expansion factor 2, part 2 has 1 million.
  
  # @expansion_factor 2
  @expansion_factor 1_000_000
  
  def sampletext() do
"""
...#......
.......#..
#.........
..........
......#...
.#........
.........#
..........
.......#..
#...#.....
"""
  end

  def readfile() do
    {:ok, data} = File.read("input")
    data
  end

  def parse_line(line) do
    line |> String.graphemes() |> Enum.map(fn x -> parse_sym(x) end)
  end

  def parse_lines(lines) do
    Enum.map(lines, &parse_line/1)
  end

  def symbolmap do
    %{
      "." => :space,
      "#" => :galaxy,
    }
  end
  
  def parse_sym(char), do: Map.get(symbolmap(), char)

  def create_map(rows) do
    coords =
      rows
      |> Enum.with_index(fn row, y ->
           Enum.with_index(row, fn sym, x ->
             {{x,y}, sym}
         end)
      end)

      tmp = List.flatten(coords)
      [xdim_, ydim_] = [Enum.max(tmp, fn {{a,b}, _x}, {{c,d}, _y} -> a >= c end),
			Enum.max(tmp, fn {{a,b}, _x}, {{c,d}, _y} -> b >= d end)]
      [{{xdim, _a}, _b}, {{_c, ydim}, _d}] = [xdim_, ydim_]
      map = tmp |> Map.new() # |> IO.inspect(label: :coords)
      {xdim+1, ydim+1, map}
  end

  def render_map({width, height, m} = map) do
    Enum.map(0..height-1, fn y ->
      render_map(map, y)
      IO.puts("")
    end)
    :ok
  end
  def render_map({width, height, m} = map, rowidx) do
    code = %{
      :space => ".",
      :galaxy => "#",
      }
    Enum.map(0..width-1, fn x ->
      sym = m[{x, rowidx}]
      to_string([Map.get(code, sym, 0x20)])
      |> IO.write()
      end)
  end

  def expander({width, height, m} = map, -1, acc, :vertical), do: {map, acc}
  def expander({width, height, m} = map, x, acc, :vertical)  do
    vert_line = for y <- 0..height-1, do: m[{x, y}]
    new_acc = 
      if not Enum.any?(vert_line, &(&1 == :galaxy)) do
        acc ++ [@expansion_factor]
      else
        acc ++ [1]
      end
    expander(map, x-1, new_acc, :vertical)
  end
  def expander({width, height, m} = map, -1, acc, :horizontal), do: {map, acc}
  def expander({width, height, m} = map, y, acc, :horizontal)  do
    horiz_line = for x <- 0..width-1, do: m[{x, y}]
    new_acc =
      if not Enum.any?(horiz_line, &(&1 == :galaxy)) do
	acc ++ [@expansion_factor]
      else
        acc ++ [1]
      end
    expander(map, y-1, new_acc, :horizontal)
  end
  
  def expand_universe({width, height, m} = map, :vertical) do
    expander(map, width-1, [], :vertical)
  end
  def expand_universe({width, height, m} = map, :horizontal) do
    expander(map, height-1, [], :horizontal)
  end
  
  def enumerate_galaxies({width, height, m} = map) do
    find_galaxy = fn m, x, y -> if m[{x,y}] == :galaxy, do: [{x,y}], else: [] end

    galaxies_ = for y <- 0..height-1, x <- 0..width-1, do: find_galaxy.(m, x, y)

    galaxies =
      galaxies_
      |> List.flatten()
      |> Enum.with_index()

    #IO.inspect(length(Enum.filter(galaxies, fn x -> x end)), label: :galaxies)
  end

  def alt_calculate_dists({a, b} = galaxypair, unitlist_xaxis, unitlist_yaxis) do
    [{coords_a, idx_a} , {coords_b, idx_b} ] = [a, b]
    {xa, ya} = coords_a
    {xb, yb} = coords_b
    # iterate through a step function that will calculate the amount of units to goal
    # first, along X-axis
    step_fun = fn unitlist, start, goal -> for x <- start..goal-1, do: Enum.at(unitlist, x) end

    steps_x = cond do
      (xa - xb) < 0 ->
	step_fun.(unitlist_xaxis, xa, xb) |> Enum.sum()
      (xa - xb) == 0 ->
	0
      true ->
	step_fun.(unitlist_xaxis, xb, xa) |> Enum.sum()
    end
    steps_y = cond do
      (ya - yb) < 0 ->
	step_fun.(unitlist_yaxis, ya, yb) |> Enum.sum()
      (ya - yb) == 0 ->
        0
      true ->
	step_fun.(unitlist_yaxis, yb, ya) |> Enum.sum()
    end
    
    steps_x + steps_y
  end

end


#input = Foo.sampletext |> String.split("\n") |> Enum.reverse |> tl |> Enum.reverse 
input = Foo.readfile |> String.split("\n") |> Enum.reverse |> tl |> Enum.reverse 
data = Foo.parse_lines(input)
map = data |> Foo.create_map()

{expansion1, unitlist_x_r} = Foo.expand_universe(map, :vertical)
{expanded_map, unitlist_y_r} = Foo.expand_universe(expansion1, :horizontal)

[unitlist_x, unitlist_y] = [unitlist_x_r, unitlist_y_r] |> Enum.map(fn x -> (Enum.reverse(x)) end)
expanded_map |> Foo.render_map()

galaxies = Foo.enumerate_galaxies(expanded_map)

{w, h, _stuff} = expanded_map
n = length(galaxies)
lst = galaxies
unique_galaxypairs = for a <- 0..n-1, b <- 0..a, a != b, do: {Enum.at(lst, b), Enum.at(lst, a)}

dists =
  unique_galaxypairs
  |> Enum.map(fn x -> Foo.alt_calculate_dists(x, unitlist_x, unitlist_y) end)
  |> IO.inspect(label: :dists)
  |> Enum.sum()
  |> IO.inspect(label: :summed)

