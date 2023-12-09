defmodule Foo do

  def sampletext() do
"""
0 3 6 9 12 15
1 3 6 10 15 21
10 13 16 21 30 45
"""
  end

  def readfile() do
    {:ok, data} = File.read("input")
    data
  end

  def parse_line(line) do
    line |> String.split(" ") |> Enum.map(fn x -> Integer.parse(x) |> elem(0) end)
  end

  def all_zeroes?(lst) do
    lst |> Enum.all?(&(&1 == 0))
  end
  
  def difference_values([], acc), do: acc
  def difference_values([single], acc), do: acc
  def difference_values([a, b | t] = lst, acc) do
    difference_values([b | t], acc ++ [b-a])
  end

  def pyramid([], acc), do: acc
  def pyramid(lst, acc) do
    case all_zeroes?(lst) do
      true -> acc
      false ->
        newvals = difference_values(lst, []) # |> IO.inspect( label: :newvals)
        pyramid(newvals, [newvals | acc])
    end
  end

  def fill_missing([bottom | rest] = pyramid, :firstpart) do
    addzero = fn [h | t] -> [h ++ [0] | t] end
    fill(addzero.(pyramid), :firstpart) |> Enum.reverse |> List.first
  end
  def fill_missing([bottom | rest] = pyramid, :secondpart) do
    addzero = fn [h | t] -> [h ++ [0] | t] end
    fill(addzero.(pyramid), :secondpart) |> List.first
  end

  # take the last val of bottom row, and append the sum of it and next rows last member to next row.
  def fill([], atomi), do: :empty
  def fill([single], atomi), do: single
  def fill([lowest, lower | rest], :firstpart) do
    a = lowest |> Enum.reverse |> List.first
    b = lower |> Enum.reverse |> List.first
    c = a + b
    lower = lower ++ [c]
    fill([lower | rest], :firstpart)
  end
  def fill([lowest, lower | rest], :secondpart) do
    a = lowest |> List.first
    b = lower |> List.first
    c = b - a
    lower = [c] ++ lower
    fill([lower | rest], :secondpart)
  end
  
end

#input = Foo.sampletext |> String.split("\n") |> Enum.reverse |> tl |> Enum.reverse 
input = Foo.readfile |> String.split("\n") |> Enum.reverse |> tl |> Enum.reverse 

values = Enum.map(input, &Foo.parse_line/1)
#IO.inspect values, label: :values

values
|> Enum.map(fn history ->
  res = history |> Foo.pyramid([])
  Foo.fill_missing(res ++ [history], :firstpart)
    end)
|> Enum.sum()
|> IO.inspect(label: "result_for_part1")

values
|> Enum.map(fn history ->
  res = history |> Foo.pyramid([])
  Foo.fill_missing(res ++ [history], :secondpart)
    end)
|> Enum.sum()
|> IO.inspect(label: "result_for_part2")
