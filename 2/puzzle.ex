defmodule Foo do

  def testlines() do
"""
Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
"""
  end

  def readfile() do
    {:ok, data} = File.read("input")
    data
  end
  
  def grabcolor(colorstr) do
    case colorstr do
      "red" -> :r
      "green" -> :g
      "blue" -> :b
    end
  end
  
  def parsegame(game) do
    parse_n_and_color = fn [a | rest] -> {Integer.parse(a) |> elem(0), grabcolor(hd(rest))} end
    foo = String.split(game, ",")
    Enum.map(foo, fn x ->
      String.trim(x)
      |> String.split()
      |> parse_n_and_color.()
      end)
  end
  
  def parsegames(games) do
    foo = String.split(games, ";")
    Enum.map(foo, &parsegame/1)
  end
  
  def parseline(txt) do
    # "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green",
    parseidx = fn x -> Integer.parse(x) |> elem(0) end
    case txt do
      "Game " <> rest ->
	[index, games] = rest |> String.split(":")
	%{parseidx.(index) => parsegames(games)}
      _ -> nil
    end
  end

  def accumulate_games([], acc), do: acc
  def accumulate_games([head | tail], acc) do
    accumulate_games(tail, Map.merge(acc, head))
  end
  
  def one_set_valid(s) do
    rules = %{r: 12, g: 13, b: 14}
    m = Enum.map(s, fn {a,b} -> {b, a} end) |> Map.new()
    r = for {k, v} <- rules, do: m[k] == nil or m[k] <= rules[k]
    Enum.all?(r)
  end
  
  def game_valid?(game) do
    # iterate through a set of reveals, testing if any set violates the rules
    game
    |> Enum.map(&one_set_valid/1)
    |> Enum.all?()
  end

  def power_of_set_of_cubes(set) do
    set
    |> Enum.map(fn {n, color} -> n end)
    |> Enum.reduce(&Kernel.*/2)
  end

  def grab_color(sets, color) do
    sets
    |> Enum.map(fn x ->
        Enum.filter(x, fn {a,b} -> b == color end)
        end)
    |> List.flatten()
  end

  def get_maximum([], c), do: {0, c}
  def get_maximum(subset, c) do
    Enum.max(subset, fn a,b -> elem(a, 0) >= elem(b, 0) end)
  end
  
  def minimum_set_of_cubes(sets) do
    colors = [:r, :g, :b]
    colors |> Enum.map(fn c -> grab_color(sets, c) |> get_maximum(c) end)
  end
  
end

lines = Foo.readfile() |> String.split("\n") |> Enum.reverse() |> tl() |> Enum.reverse()

gamemap = Enum.map(lines, &Foo.parseline/1) |> Foo.accumulate_games(%{})

#IO.inspect gamemap

trues = for {k, v} <- gamemap, do: {k, Foo.game_valid?(v)}

powers = for {k, v} <- gamemap, do: Foo.minimum_set_of_cubes(v)

trues
|> Enum.filter(fn {a,b} -> b == true end)
|> Enum.map(fn {a,b} -> a end)
|> Enum.sum()
|> IO.inspect

powers
|> Enum.map(&Foo.power_of_set_of_cubes/1)
|> Enum.sum()
|> IO.inspect()
