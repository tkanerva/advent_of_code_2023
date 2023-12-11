defmodule Foo do

  def sampletext() do
"""
.....
.F-7.
.|.|.
.L-J.
.....
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
      "." => :floor,
      "-" => :east_west,
      "|" => :north_south,
      "L" => :north_east,
      "J" => :north_west,
      "7" => :south_west,
      "F" => :south_east,
      "S" => :startpos,
    }
  end
  
  def parse_sym(char), do: Map.get(symbolmap, char)

  def connectivities(rows) do
    Enum.map(rows, &connectivities_row/1)
  end
  
  def connectivities_row(sym) do
    case sym do
      :floor -> [[0,0,0], [0,0,0], [0,0,0]]
      :east_west -> [[0, 0, 0],
                    [1, 0, 1],
                    [0, 0, 0]]
      :north_south -> [[0, 1, 0],
                      [0, 0, 0],
                      [0, 1, 0]]
      :north_east -> [[0, 1, 0],
                     [0, 0, 1],
                     [0, 0, 0]]
      :north_west -> [[0, 1, 0],
                     [1, 0, 0],
                     [0, 0, 0]]
      :south_west -> [[0, 0, 0],
                     [1, 0, 0],
                     [0, 1, 0]]
      :south_east -> [[0, 0, 0],
                     [0, 0, 1],
                     [0, 1, 0]]
      :startpos ->   [[1, 1, 1], [1,1,1], [1,1,1]]
    end
  end

  def create_map(rows) do

    coords =
      rows
      |> Enum.with_index(fn row, y ->
         #IO.inspect({y,row})
         Enum.with_index(row, fn sym, x ->
           {{x,y}, sym}
         end)
    end)

    tmp = List.flatten(coords)
    tmp |> Map.new() # |> IO.inspect(label: :coords)
  end

  def render_map(m) do
    Enum.map(0..130, fn y ->
      render_map(m, y)
      IO.puts("")
      end)
  end
  def render_map(m, rowidx) do
    ibm_codepage = %{
      :floor => 0x20,
      :startpos => 0x2a,
      :east_west => 0x2550,
      :north_south => 0x2551,
      :north_east => 0x255a,
      :north_west => 0x255d,
      :south_west => 0x2557,
      :south_east => 0x2554,
      }
    Enum.map(0..130, fn x ->
      sym = getsym(m, {x, rowidx})
      to_string([Map.get(ibm_codepage, sym, 0x20)])
      |> IO.write()
      end)
  end
  
  def getsym(m, {x, y} = pos) do
    Map.get(m, {x,y})
  end

  def get_startpos(m) do
    m
    |> Map.filter(fn {_k, v} -> v == :startpos end)
    |> IO.inspect(label: :afterfilter)
    |> Map.keys
    |> IO.inspect(label: :keys)
    |> hd()
  end
  
  def connect_from_startpoint(rows) do
    potential_nextpos =
      rows
      |> Enum.map(fn row ->
            Enum.map(row, fn sym ->
              Enum.filter(connectivities_row(sym), &(&1 == 1))
            end)
      end)
      
  end

  def get_kernel(sym) do
    # mapping of fitting pieces for this sym. {coords, [fittings]}
    sw_ns_se = [ :south_west, :north_south, :south_east ]
    nw_ns_ne = [ :north_west, :north_south, :north_east ]
    ne_ew_se = [ :north_east, :east_west, :south_east ]
    sw_ew_nw = [ :south_west, :east_west, :north_west ]
    case sym do
      :north_south -> [
        { {0, -1}, sw_ns_se },
	{ {0, 1}, nw_ns_ne },
      ]
      :east_west -> [                     
	{ {-1, 0}, ne_ew_se },
        { {1, 0}, sw_ew_nw },
      ]
      :north_east -> [
        { {0, -1}, sw_ns_se },
        { {1, 0}, sw_ew_nw },
      ]
      :north_west -> [
        { {0, -1}, sw_ns_se },
        { {-1, 0}, ne_ew_se },  
      ]
      :south_west -> [
        { {-1, 0}, ne_ew_se },
        { {0, 1}, nw_ns_ne },
      ]
      :south_east -> [
        { {1, 0}, sw_ew_nw },
        { {0, 1}, nw_ns_ne },
      ]
        
      _ -> []
    end
  end

  def offset({x0, y0} = coords, {dx, dy} = vector_to_add), do: {x0+dx, y0+dy}
  
  def guess_right_piece(m, {sx, sy} = startpos) do
    allpieces = [:north_south, :east_west, :north_east, :north_west, :south_west, :south_east]
    perim =
      Enum.map([{-1, 0}, {0, -1}, {1, 0},  {0, 1}], fn coord -> offset(coord, {sx, sy}) end)
    IO.inspect(perim, label: :perim)
    # go through all perimeter positions, try to fit each piece and see if it produces exactly two connections
    res = 
      Enum.map(allpieces, fn sym ->  # try to fit each, one by one
      [fit_pos1, fit_pos2] = get_kernel(sym)
      {coord1, allowed_list1} = fit_pos1
      {coord2, allowed_list2} = fit_pos2
      results = 
      Enum.map(perim, fn coord ->
        check_connectivity_sym(m, startpos, coord, sym)
        end)
      (Enum.filter(results, &(&1)) |> length()) == 2
     end)

    right_piece =
      Enum.filter(Enum.zip(allpieces, res), fn {name, r} -> r end)
      |> Enum.map(fn {a,b} -> a end)
      |> hd()
  end
  
  def get_perimeter({sx, sy} = startpos) do
    for y <- -1..1, x <- -1..1, (x != 0 or y != 0), do: {sx + x, sy + y}
  end

  def check_connectivity(m, {x,y} = startpos, {nx, ny} = newpos) do
    sym = getsym(m, startpos)
    check_connectivity_sym(m, startpos, newpos, sym)
  end
  def check_connectivity_sym(m, {x,y} = startpos, {nx, ny} = newpos, sym) do
    newsym = getsym(m, newpos)
    coord_and_pieces = get_kernel(sym)
    # check the fitting pieces.
    coord_and_pieces
    |> Enum.map(fn {{x0, y0}, pieces} ->
      tmp1 = newsym in pieces # |> IO.inspect(label: "in_pieces?")
      tmp2 = ({x0+x, y0+y} == newpos)
      tmp1 and tmp2
      end)
    |> Enum.any?()
  end

  def traverse(m, {sx, sy} = startpos, acc, 0) do
    List.flatten(acc)
  end
  def traverse(m, {sx, sy} = startpos, acc, nonvis_length) do
    perim = get_perimeter(startpos)
    Enum.map(perim, &(getsym(m, &1)))
 
    newpositions = 
      Enum.filter(perim, fn pos ->
        Foo.check_connectivity(m, startpos, pos)
      end)

    # recurse into both directions. Reject those which have been visited.
    nonvisited = Enum.filter(newpositions, fn x -> x not in acc end)
    case nonvisited do
      [] -> acc
      _ -> Enum.map(nonvisited, fn x -> traverse(m, x, acc ++ [startpos], length(nonvisited)) end)
    end
  end
  
  def farthest_point(path1, path2) do
    1 +
    (Enum.zip(tl(path1), tl(path2))
    |> Enum.take_while(fn {a, b} -> a != b end)
    |> length()
    )
  end
  
end


#input = Foo.sampletext |> String.split("\n") |> Enum.reverse |> tl |> Enum.reverse 
input = Foo.readfile |> String.split("\n") |> Enum.reverse |> tl |> Enum.reverse 

data = Foo.parse_lines(input)

map = 
  data
  |> Foo.create_map()
  |> IO.inspect

startpos = Foo.get_startpos(map)
IO.inspect(startpos, label: :startpos)
Foo.render_map(map)

# after getting startpos, we have to predict the correct symbol to be placed here. otherwise we cannot start.
predicted_piece = Foo.guess_right_piece(map, startpos) |> IO.inspect(label: :predicted_piece)
# push this to the startpos
map = map |> Map.put(startpos, predicted_piece)

path = Foo.traverse(map, startpos, [], 1)
IO.inspect( List.flatten(path), label: :path)

[p1_, p2_] = path
[p1, p2] = Enum.map([p1_, p2_], &List.flatten/1)
Foo.farthest_point(p1, p2) |> IO.inspect(label: :farthest_path)

