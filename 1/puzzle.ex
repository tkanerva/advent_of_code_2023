defmodule Foo do
  
  @numbers %{
    "one" => 1,
    "two" => 2,
    "three" => 3,
    "four" => 4,
    "five" => 5,
    "six" => 6,
    "seven" => 7,
    "eight" => 8,
    "nine" => 9,
  }
  @invnumbers %{
    "eno" => 1,
    "owt" => 2,
    "eerht" => 3,
    "ruof" => 4,
    "evif" => 5,
    "xis" => 6,
    "neves" => 7,
    "thgie" => 8,
    "enin" => 9,
  }

  def isdigit?(c) do
    cond do
      c >= "0" and c <= "9" -> true
      true -> false
    end
  end

  def grab_numbers({line, reversedline}) do
    [a] = line |> Enum.filter(&isdigit?/1) |> Enum.take(1)
    [b] = reversedline |> Enum.filter(&isdigit?/1) |> Enum.take(1)
    a <> b
  end

  def grab_numbers_2({line, reversedline}) do
    # this uses the scan_num function.
    str = fn x -> List.to_string(x) end
    [r1] = scan_num(line, [])
    [r2] = scan_num(reversedline, [])
    #IO.inspect( [str.(line), r1,r2, str.(reversedline)] )
    r1 <> r2
  end
  
  def parse_num(numberstr) do
    {n, _ignore} = Integer.parse(numberstr)
    n
  end

  def scan_num([], acc) do
    acc
  end
  def scan_num(string, acc) do
    # scan a string for numbers spelled out in letters
    str = fn x -> List.to_string(x) end
    [chr | tail] = string
    foo = recurse_into_word(string, [])
    new = case foo do
	    [num] -> num
	    [] -> chr
	  end
    #IO.inspect(["........", chr, new, tail, str.(acc), ])
    case isdigit?(new) do
      true -> [new]
      false -> scan_num( tail, acc ++ [new] )
    end
  end
  
  def recurse_into_word([], acc) do
    #IO.puts( "<<< #{inspect(acc)} >>>")
    []
  end
  
  def recurse_into_word(string, acc) do
    allnumbers = Map.merge(@numbers, @invnumbers)
    str = fn x -> List.to_string(x) end
    [chr | tail] = string
    #IO.inspect( {chr, tail, str.(acc)} )
    case str.(acc) in Map.keys(allnumbers) do
      true -> [ allnumbers[str.(acc)] |> Integer.to_string() ]
      false -> recurse_into_word(tail, acc ++ [chr])
    end
  end
  
  def readfile() do
    {:ok, data} = File.read("puzzle1.txt")
    data
  end
end

# ignore the last line, which is empty.
data =
  Foo.readfile()
  |> String.split("\n")
  |> Enum.reverse()
  |> tl()
  |> Enum.reverse()

graphemes = data |> Enum.map(&String.graphemes/1)
reversed_g = data |> Enum.map(fn x -> String.graphemes(x) |> Enum.reverse() end)

values_part1 =
  Enum.zip(graphemes, reversed_g)
  |> Enum.map(&Foo.grab_numbers/1)
  |> Enum.map(&Foo.parse_num/1)

values_part2 =
  Enum.zip(graphemes, reversed_g)
  |> Enum.map(&Foo.grab_numbers_2/1)
  |> Enum.map(&Foo.parse_num/1)

values_part2 |> Enum.sum() |> IO.inspect()
