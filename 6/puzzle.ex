defmodule Foo do

  def sampletext() do
"""
Time:      7  15   30
Distance:  9  40  200
"""
  end

  def readfile() do
    {:ok, data} = File.read("input")
    data
  end

  def parse_line(line) do
    [header, rest] = line |> String.split(":")
    v = rest |> String.split() |> Enum.map(fn x -> Integer.parse(x) |> elem(0) end)
    v
  end

  def exhaustive_search({race_time, record} = entry) do
    lst =
      for x <- 0..race_time do
        velo = x
        traveltime = (race_time - x)
        dist = traveltime*velo
      end

    {entry, lst}
  end

  def count_winning_ways({entry, lst} = input) do
    {race_time, record} = entry
    ways = lst |> Enum.filter(fn x -> x > record end)
    length(ways)
  end

  def number_of_ways(events) do
    events |> Enum.reduce(fn a, b -> a * b end)
  end

  def parsing_for_part2(line) do
    [header, rest] = line |> String.split(":")
    rest |> String.split() |> Enum.join() |> Integer.parse() |> elem(0)
  end
  
end

#input = Foo.sampletext |> String.split("\n") |> Enum.reverse |> tl |> Enum.reverse 
input = Foo.readfile |> String.split("\n") |> Enum.reverse |> tl |> Enum.reverse 
nrows = length(input)
IO.inspect(nrows, label: "nrows")

races = Enum.zip( Enum.map(input, &Foo.parse_line/1))
#IO.inspect races, label: :races

# examine the possible races exhaustively
Enum.map(races, fn x ->
  x 
  |> Foo.exhaustive_search()
  |> Foo.count_winning_ways()
  end)
  |> Foo.number_of_ways()
  |> IO.inspect(charlists: :as_lists, label: "part1 solution")


# Part 2 solution.
races2 = Enum.map(input, &Foo.parsing_for_part2/1)
races2 = [ {hd(races2), tl(races2) |> hd() } ]

#IO.inspect(races2, charlists: :as_lists)

# examine the possible races exhaustively
Enum.map(races2, fn x ->
  x 
  |> Foo.exhaustive_search()
  |> Foo.count_winning_ways()
  end)
  |> Foo.number_of_ways()
  |> IO.inspect(charlists: :as_lists, label: "part2 solution")
