defmodule Foo do

  def sampletext() do
"""
seeds: 79 14 55 13

seed-to-soil map:
50 98 2
52 50 48

soil-to-fertilizer map:
0 15 37
37 52 2
39 0 15

fertilizer-to-water map:
49 53 8
0 11 42
42 0 7
57 7 4

water-to-light map:
88 18 7
18 25 70

light-to-temperature map:
45 77 23
81 45 19
68 64 13

temperature-to-humidity map:
0 69 1
1 0 69

humidity-to-location map:
60 56 37
56 93 4
"""    
  end

  def readfile() do
    {:ok, data} = File.read("input")
    data
  end
  
  def parser([], acc), do: {0, :empty, acc}
  def parser(["" | r], acc), do: parser(r, acc)
  def parser([line | lines], acc) do
    # delegate parsing to sub-parser
    {n, mapname, res} =
      case String.split(line, ":") |> hd do
        "seeds" -> subparser(:seeds, String.slice(line, 7, 999999))
	"seed-to-soil map" -> subparser(:seed2soil, lines)
	"soil-to-fertilizer map" -> subparser(:soil2fertilizer, lines)
	"fertilizer-to-water map" -> subparser(:fertilizer2water, lines)
	"water-to-light map" -> subparser(:water2light, lines)
	"light-to-temperature map" -> subparser(:light2temperature, lines)
	"temperature-to-humidity map" -> subparser(:temperature2humidity, lines)
	"humidity-to-location map" -> subparser(:humidity2location, lines)
	_ -> parser(lines, acc)
      end
    # skip N lines of input, before recursing.
    foo = Enum.drop(lines, n) # |> IO.inspect(label: "drop> ")
    parser(foo, Map.put(acc, mapname, res))
  end
  
  def subparser(:seeds, lines) do
    {0,
     :seeds,
     lines |> String.split() |> Enum.map(fn x -> Integer.parse(x) |> elem(0) end)
     }
  end
  def subparser(mapname, lines) do
    tmp = 
      lines
      |> Enum.take_while(fn x -> x != "" end)
      |> Enum.map(&String.split/1)
      |> Enum.map(fn x -> Enum.map(x, fn a -> Integer.parse(a)|> elem(0) end) end)
      |> Enum.map(fn [dest, src, range] -> {dest, src, range} end)
      
    {length(tmp), mapname, tmp}
  end

  def convert(v, t = :seed2soil, %{:seed2soil => ranges} = _data), do: cvt(t, v, ranges)
  def convert(v, t = :soil2fertilizer, %{:soil2fertilizer => ranges} = _data), do: cvt(t, v, ranges)
  def convert(v, t = :fertilizer2water, %{:fertilizer2water => ranges} = _data), do: cvt(t, v, ranges)
  def convert(v, t = :water2light, %{:water2light => ranges} = _data), do: cvt(t, v, ranges)
  def convert(v, t = :light2temperature, %{:light2temperature => ranges} = _data), do: cvt(t, v, ranges)
  def convert(v, t = :temperature2humidity, %{:temperature2humidity => ranges} = _data), do: cvt(t, v, ranges)
  def convert(v, t = :humidity2location, %{:humidity2location => ranges} = _data), do: cvt(t, v, ranges)

  def cvt(convtype, val, ranges) do
    offsets =
      Enum.map(ranges, fn x ->
	{dst, src, rng} = x
	cond do
	  val in src..(src+rng-1) -> (dst-src)
	  true -> 0
        end
      end)

    potential_offset = offsets |> Enum.filter(&(&1 != 0)) 
    offset = case potential_offset do
	       [offs] -> offs
	       _ -> 0
	     end
    
    newval = val + offset
  end
  
  def execute(val, data) do
    cvt = fn x, y -> Foo.convert(x, y, data) end
    val
    |> cvt.(:seed2soil)
    |> cvt.(:soil2fertilizer)
    |> cvt.(:fertilizer2water)
    |> cvt.(:water2light)
    |> cvt.(:light2temperature)
    |> cvt.(:temperature2humidity)
    |> cvt.(:humidity2location)
  end

  def genrange(f, data, start, count, acc), do: acc
  def genrange(f, data, start, count, acc) do
      r = f.( start+count, data)
      foo = genrange(f, data, start, count-1, Enum.min([r, acc]))
      foo
  end
  def genrange_pred(f, data, start, count, acc) when count <= 0, do: acc
  def genrange_pred(f, data, start, count, acc) do
    beginning = f.(start+count-999, data)
    last = f.(start+count, data)

    foo =
    cond do
      abs(beginning-last) == 999 ->
	localmin = Enum.min( [beginning, last] )
	gmin = Enum.min( [localmin, acc] )
	genrange_pred(f, data, start, count-1001, gmin)
      true ->
	r = f.( start+count, data)
	genrange_pred(f, data, start, count-1, Enum.min([r, acc]))
    end
    
  end

  def genrange_par(f, data, start, count, acc) do
    parallel_tasks = 10
    lst = Enum.to_list(1..1_000_000)
    results =
      Enum.chunk_every(lst, div(length(lst), parallel_tasks))
      |> Task.async_stream(fn l -> Enum.map(l, fn x -> f.( start+count+x, data) end) end, timeout: 300_000)
      |> Enum.map(fn {:ok, r} -> r end)
      |> List.flatten()

    minimum = results |> Enum.min()
    #IO.inspect(minimum, label: "min_computed")
    genrange_par(f, data, start, count-1_000_000, [minimum | acc])
  end
  
end


#{n, :empty, data} = Foo.sampletext |> String.split("\n") |> Foo.parser(%{})
{n, :empty, data} = Foo.readfile |> String.split("\n") |> Foo.parser(%{})

seeds = data[:seeds]

cvt = fn x, y -> Foo.convert(x, y, data) end

locations = Enum.map(seeds, fn seed ->
  seed
  |> cvt.(:seed2soil)
  |> cvt.(:soil2fertilizer)
  |> cvt.(:fertilizer2water)
  |> cvt.(:water2light)
  |> cvt.(:light2temperature)
  |> cvt.(:temperature2humidity)
  |> cvt.(:humidity2location)
  end)

IO.inspect(Enum.min(locations), label: "Part 1, minimum")

stream =
  seeds
  |> Enum.chunk_every(2)
  |> Task.async_stream(fn [seed1, n1] ->
      Foo.genrange_pred(&Foo.execute/2, data, seed1, n1, [])
        end,
      timeout: 300_000)
  |> Enum.map(fn {:ok, res} -> res end)
  |> Enum.min()
  |> IO.inspect(label: "Part 2, results")
