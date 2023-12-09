defmodule Foo do

  def sampletext() do
"""
LLR

AAA = (BBB, BBB)
BBB = (AAA, ZZZ)
ZZZ = (ZZZ, ZZZ)
"""
  end

  def readfile() do
    {:ok, data} = File.read("input")
    data
  end

  def parsefile([], acc), do: acc
  def parsefile([line | lines], acc) do
    # first line is always the sequence
    sequence = line |> String.graphemes()
    nodes =
      lines
      |> tl()
      |> Enum.map(fn x -> parse_line(x) end)
      |> IO.inspect
    {sequence, nodes}
  end

  def parse_line(""), do: nil
  def parse_line(line) do
    [header, rest] = line |> String.split("=")
    nodename = header |> String.replace("=", "") |> String.trim
    v = rest |> String.replace("(", "") |> String.replace(")", "") |> String.split(",") |> Enum.map(&String.trim/1)
    {nodename, v}
  end

  def step(tree, "ZZZ", insn, counter, initial_insn) do
    IO.puts " GOAL !!!!!!"
    counter
  end
  
  def step(tree, curnode, [insn | insns], counter, initial_insn) do
    get_node = fn tree, wanted -> hd(for n <- tree, elem(n, 0) == wanted, do: n) end

    node = get_node.(tree, curnode)
    {thisnode, [left, right]} = node

    #IO.inspect([insn, curnode], label: :insn_and_node)
    nextnode =
      case insn do
        "R" -> right
        "L" -> left
        _ -> nil
      end

    newinsn = 
      case insns do
        [] -> initial_insn
        _ -> insns
      end
    step(tree, nextnode, newinsn, counter+1, initial_insn)
  end
  
end

#input = Foo.sampletext |> String.split("\n") |> Enum.reverse |> tl |> Enum.reverse 
input = Foo.readfile |> String.split("\n") |> Enum.reverse |> tl |> Enum.reverse 
data = input |> Foo.parsefile([]) |> IO.inspect(label: :data)

{seq, tree} = data
nextnode = "AAA"

count = Foo.step(tree, nextnode, seq, 0, seq)

IO.inspect count
