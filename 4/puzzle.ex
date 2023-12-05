defmodule Foo do

  # Card 0: 1 2 3 4 5  | 6 7 9 10 11
  def sampletext() do
"""
Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
"""
  end

  def readfile() do
    {:ok, data} = File.read("input")
    data
  end

  def parse_line("Card " <> line) do
    [index, rest] = line |> String.split(":")
    [winning_s, youhave_s | r] = rest |> String.split("|")
    winning = winning_s |> String.split() |> Enum.map(fn x -> Integer.parse(x) |> elem(0) end)
    youhave = youhave_s |> String.split() |> Enum.map(fn x -> Integer.parse(x) |> elem(0) end)
    idx = index |> String.trim() |> Integer.parse() |> elem(0)
    {idx, winning, youhave}
  end

  def score_points(winnings_haves) do
    won = filter_winnings(winnings_haves)
    case mapsz = MapSet.size(won) do
      0 -> 0
      _ -> 2 ** (MapSet.size(won) - 1)
    end
  end

  def filter_winnings({winnings, haves} = winnings_haves) do
    [set_w, set_h] = [winnings, haves] |> Enum.map(&MapSet.new/1)
    MapSet.intersection(set_w, set_h)
  end

  def make_copies(m, amount, idx, _n_rows, 0 ), do: m
  def make_copies(m, amount, idx, n_rows, range ) do
    # need to verify we are not accessing stuff outside of the nrows
    tmp =
    cond do
      idx+range > n_rows -> m
      true ->
        m |> Map.update(idx+range, [], fn cur -> cur ++ List.duplicate(hd(cur), amount) end)
    end
    make_copies(tmp, amount, idx, n_rows, range-1 )
  end  

  def do_iter(new, idx, _n_rows, 0), do: new
  def do_iter(new, idx, n_rows, count) do
    range = Map.get(new, idx) |> hd
    # do not iterate over our map limit
    range = cond do
      idx + range > n_rows -> n_rows
      true -> range
      end
    make_copies(new, count, idx, n_rows, range)
  end

  def iter_thru(cardmap, idx, nrows) when idx >= nrows, do: cardmap
  def iter_thru(cardmap, idx, nrows) do
    get_count = fn m -> length(Map.get(m, idx, [])) end
    count = get_count.(cardmap, idx)
    new_map = Foo.do_iter(cardmap, idx, nrows, count)
    iter_thru(new_map, idx+1, nrows)
  end
end


#input = Foo.sampletext |> String.split("\n") |> Enum.reverse |> tl |> Enum.reverse 
input = Foo.readfile |> String.split("\n") |> Enum.reverse |> tl |> Enum.reverse # |> Enum.take(50)
nrows = length(input)
IO.inspect(nrows, label: "nrows")

tmp = input |> Enum.map(&Foo.parse_line/1) 
points_given = tmp |> Enum.map(fn {i, a, b} -> Foo.score_points({a,b}) end) |> IO.inspect(label: "points_given")

Enum.sum(points_given) |> IO.inspect(label: "sum")

card_map =
  tmp
  |> Enum.map(fn {i,a,b} -> {i, Foo.filter_winnings({a,b})} end)
  |> Enum.map(fn {i, set} -> {i, [set |> MapSet.size()]} end)
  |> Map.new

new = card_map |> IO.inspect(charlists: :as_lists, limit: :infinity, pretty: true, custom_options: [sort_maps: true])

final_map = Foo.iter_thru(new, 1, nrows) 

# count the cards
IO.puts "================================================================="
#IO.inspect( final_map, [ limit: :infinity, charlists: :as_lists, custom_options: [sort_maps: true]])

1..nrows
|> Enum.map(fn idx -> length(Map.get(final_map, idx, [])) end)
|> IO.inspect(limit: :infinity)
|> Enum.sum
|> IO.inspect
