defmodule Foo do

  @expansion_factor 10
  
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

  # doing row/col expansion in an immutable language requires quite a lot of code

  def col_copy_loop({width, height, m} = map, s, d, -1), do: m
  def col_copy_loop({width, height, m} = map, s, d, y) do
    new_m = {width, height, Map.put(m, {d, y}, m[{s, y}])}
    col_copy_loop(new_m, s, d, y-1)
  end
  def row_copy_loop({width, height, m} = map, s, d, -1), do: m
  def row_copy_loop({width, height, m} = map, s, d, x) do
    new_m = {width, height, Map.put(m, {x, d}, m[{x, s}])}
    row_copy_loop(new_m, s, d, x-1)
  end
  
  def copy_column({width, height, m} = map, src_col, dest_col) do
    col_copy_loop({width, height, m} = map, src_col, dest_col, height)
  end
  def copy_row({width, height, m} = map, src_row, dest_row) do
    row_copy_loop({width, height, m} = map, src_row, dest_row, width)
  end

  def col_mv_loop({width, height, m} = map, cpos, -1), do: m
  def col_mv_loop({width, height, m} = map, cpos, dx) do
    newm = {width, height, copy_column(map, cpos+dx, cpos+dx+1)}
    col_mv_loop(newm, cpos, dx-1)
  end
  
  def row_mv_loop({width, height, m} = map, rpos, -1), do: m
  def row_mv_loop({width, height, m} = map, rpos, dy) do
    newm = {width, height, copy_row(map, rpos+dy, rpos+dy+1)}
    row_mv_loop(newm, rpos, dy-1)
  end
  
  def insert_column({width, height, m} = map, col, cpos) do
    {width+1, height, col_mv_loop(map, cpos, width-cpos)}  # increment width
  end

  def insert_row({width, height, m} = map, row, rpos) do
    {width, height+1, row_mv_loop(map, rpos, height-rpos)}  # increment height
  end
  
  def expander({width, height, m} = map, -1, :vertical), do: map
  def expander({width, height, m} = map, x, :vertical)  do
    vert_line = for y <- 0..height-1, do: m[{x, y}]
    new_m =
      if not Enum.any?(vert_line, &(&1 == :galaxy)) do
        insert_column(map, [0], x)
      else
        map
      end
    expander(new_m, x-1, :vertical)
  end
  def expander({width, height, m} = map, -1, :horizontal), do: map
  def expander({width, height, m} = map, y, :horizontal)  do
    horiz_line = for x <- 0..width-1, do: m[{x, y}]
    new_m =
      if not Enum.any?(horiz_line, &(&1 == :galaxy)) do
        insert_row(map, [0], y)
      else
        map
      end
    expander(new_m, y-1, :horizontal)
  end
  
  def expand_universe({width, height, m} = map, :vertical) do
    expander(map, width-1, :vertical)
  end
  def expand_universe({width, height, m} = map, :horizontal) do
    expander(map, height-1, :horizontal)
  end
  
  def enumerate_galaxies({width, height, m} = map) do
    find_galaxy = fn m, x, y -> if m[{x,y}] == :galaxy, do: [{x,y}], else: [] end

    galaxies_ = for y <- 0..height-1, x <- 0..width-1, do: find_galaxy.(m, x, y)

    galaxies =
      galaxies_
      |> List.flatten()
      |> Enum.with_index()

  end

  def calculate_distances({a, b} = galaxypair) do
    [{coords_a, idx_a}, {coords_b, idx_b}] = [a, b]
    # distance is a step function from a to b, we can transform it to step first along the x axis and then y
    {xa, ya} = coords_a
    {xb, yb} = coords_b
    {dist_x, dist_y} = {abs(xa - xb), abs(ya - yb)}
    dist_x + dist_y
  end

end


#input = Foo.sampletext |> String.split("\n") |> Enum.reverse |> tl |> Enum.reverse 
input = Foo.readfile |> String.split("\n") |> Enum.reverse |> tl |> Enum.reverse 

data = Foo.parse_lines(input)

map = data |> Foo.create_map()

expanded_map =
  map
  |> Foo.expand_universe(:vertical)
  |> Foo.expand_universe(:horizontal)

expanded_map |> Foo.render_map()
galaxies = Foo.enumerate_galaxies(expanded_map)

{w, h, _stuff} = expanded_map
n = length(galaxies)
lst = galaxies
unique_galaxypairs = for a <- 0..n-1, b <- 0..a, a != b, do: {Enum.at(lst, b), Enum.at(lst, a)}
dists =
  unique_galaxypairs
  |> Enum.map(&Foo.calculate_distances/1)
  |> IO.inspect(label: :dists)
  |> Enum.sum()
  |> IO.inspect(label: :summed)

