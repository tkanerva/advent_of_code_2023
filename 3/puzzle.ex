defmodule Foo do

  def sampletext() do
"""
467..114..
...*......
..35..633.
......#...
617*......
.....+.58.
..592.....
......755.
...$.*....
.664.598..
"""
  end

  def isdigit?(c) do
    cond do
      c >= "0" and c <= "9" -> true
      true -> false
    end
  end

  def getcoord(line, :symbols) do
    syms = ["*", "=", "/", "%", "#", "&", "$", "-", "@", "+"]

    line
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.filter(fn {x,_idx} -> x in syms end)
  end

  def getcoords(lines, :numbers) do
    lines
    |> Enum.map(fn x ->
      String.graphemes(x)
      |> getcoords_number([], 0)
    end)
  end
  
  def getcoords(lines, symbols_or_numbers) do
    lines
    |> Enum.map(fn x -> getcoord(x, symbols_or_numbers) end)
    |> Enum.with_index()
    |> Enum.map(fn {i, y} -> for {a,x} <- i, do: {x,y, a} end)
  end

  def scan_number([], acc) do
    acc
  end
  def scan_number(chrlist, acc) do
    # scan a number, drop immediately when encountering non-number
    any_number = for x <- 0..9, do: Integer.to_string(x)

    [head | tail] = chrlist
    cond do
      head in any_number -> scan_number(tail, acc ++ [head])
      true -> acc
    end
  end

  def getcoords_n_loop([], counter) do
    { [], counter }
  end
  def getcoords_n_loop(line, counter) do
    any_number = for x <- 0..9, do: Integer.to_string(x)
    
    [head | tail] = line
    cond do
      head in any_number -> {scan_number(line, []), counter}
      true -> getcoords_n_loop(tail, counter + 1)
    end
  end
  
  def getcoords_number([], acc, _counter), do: acc
  def getcoords_number(line, acc, counter) do
    {partnum_l, xpos} = getcoords_n_loop(line, 0)
    abs_xpos = xpos + counter
    {partnum, strlen} = {List.to_string(partnum_l), length(partnum_l)}
    #IO.inspect ">> #{inspect(partnum)} << #{inspect(List.to_string(line))} | #{inspect(acc)}"
    newline = line |> Enum.drop(strlen+xpos)  # annotate this with its position and length
    case strlen do
      0 -> 
	getcoords_number(newline, acc, counter+strlen+xpos)
      _ ->
	getcoords_number(newline, acc ++ [{abs_xpos, strlen, partnum}], counter+strlen+xpos)
    end
  end

  def assemble_coords(nums) do
    # transform the [{xpos, strlen, partnum}..] to [{xpos, ypos, strlen, partnum}..]
    nums
    |> Enum.with_index()
    |> Enum.map(fn {a, y} ->
         a |> Enum.map(fn {i, j, k} -> {i, y, j, k} end)
         end)
  end
  
  def match_in_perimeter?(x, y, symbols) do
    kernel = [{-1, -1}, {0, -1}, {1, -1},
	      {-1, 0},           {1, 0},
	      {-1, 1}, {0, 1}, {1, 1}]

    sym_coords = symbols |> Enum.map(fn {x,y,_s} -> {x,y} end)
    
    kernel
    |> Enum.map(fn {x0, y0} -> {x0+x, y0+y} in sym_coords end)
    |> Enum.any?()
  end

  def is_valid_partnum?({x, y, len, num} = partnum, symbols) do
    # find if there is any Symbol next to it
    (for x2 <- x..(len+x-1), do: match_in_perimeter?(x2, y, symbols) ) |> Enum.any?()
  end

  def is_potential_gear?(symbol, partnums) do
    # try to find two partnums that are connected to this symbol
    for foo <- partnums do
      {x, y, len, partnum} = foo
      tmp = for x2 <- x..(len+x-1), do: match_in_perimeter?(x2, y, [symbol])
      Enum.any?(tmp)
    end
  end

  def is_gear?(symbol, partnums) do
    # find all partnums connected to this symbol. If 2 or greater, we have a gear
    lst = is_potential_gear?(symbol, partnums)
    case length(Enum.filter(lst, fn x -> x == true end)) do
      0 -> false
      1 -> false
      2 -> true
      _ -> false
    end
  end
  
  def readfile() do
    {:ok, data} = File.read("input")
    data
  end
  
end

#txt = Foo.sampletext()
txt = Foo.readfile()

syms = txt |> String.split("\n") |> Foo.getcoords(:symbols) |> List.flatten
nums = txt |> String.split("\n") |> Foo.getcoords(:numbers) |> Foo.assemble_coords() |> List.flatten

# go through all found potential partnums and verify if they are correct
valid_partnums =
  nums |> Enum.filter(fn x -> Foo.is_valid_partnum?(x, syms) end) |> IO.inspect

# now, sum up these things. Sum of valid_partnums is the answer for Part 1
#valid_partnums |> Enum.map(fn {a,b,c,d} -> String.to_integer(d) end) |> Enum.sum() |> IO.inspect

# PART 2 FOLLOWS.

potential_gears = syms |> Enum.filter(fn {x,y,s} -> s == "*" end) |> IO.inspect

gears =
  potential_gears
  |> Enum.filter(fn sym -> Foo.is_gear?(sym, valid_partnums) end)
  |> IO.inspect

gearratios =
  for gear <- gears do
      Enum.zip(
        Foo.is_potential_gear?(gear, valid_partnums),
        valid_partnums)
        |> Enum.filter(fn {a, b} -> a == true end)
        |> Enum.map(fn {a, b} -> elem(b, 3) |> String.to_integer() end)
        |> Enum.reduce(fn a, b -> a*b end)
  end

Enum.sum(gearratios) |> IO.inspect
