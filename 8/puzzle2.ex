defmodule Foo do

  def sampletext() do
"""
LR

11A = (11B, XXX)
11B = (XXX, 11Z)
11Z = (11B, XXX)
22A = (22B, XXX)
22B = (22C, 22C)
22C = (22Z, 22Z)
22Z = (22B, 22B)
XXX = (XXX, XXX)
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

  def multi_step(tree, ["ZZZ"], insn, counter, initial_insn) do
    IO.puts " GOAL !!!!!!"
    counter
  end
  
  def is_goal?(nodelist) do
    IO.inspect nodelist
    nodelist |> Enum.map(fn x -> String.first(x) == "Z" end) |> Enum.all?()
  end
  
  def multi_step(tree, curnodes_lst, [insn | insns], counter, initial_insn) do
    get_node = fn tree, wanted -> hd(for n <- tree, elem(n, 0) == wanted, do: n) end

    # first, check if we have reached the Goal yet
    case is_goal?(curnodes_lst) do
      true -> counter
      false ->
    
        nodes = Enum.map(curnodes_lst, &(get_node.(tree, &1)))
        
        # calculate next nodes.
        nextnodes =
          nodes
          |> Enum.map(fn {thenode, [left, right]} = node ->
             get_nextnode(insn, [right, left]) end)
      
        newinsns = case insns do
            [] -> initial_insn
            _ -> insns
          end
        multi_step(tree, nextnodes, newinsns, counter+1, initial_insn)
    end
  end

      def get_nextnode(insn, [r, l] = rightleft) do
        case insn do
          "R" -> r
          "L" -> l
          _ -> nil
        end
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


# the "tree" is of form {node, [left, right]}
transform_name = 1 

#input = Foo.sampletext |> String.split("\n") |> Enum.reverse |> tl |> Enum.reverse 
input = Foo.readfile |> String.split("\n") |> Enum.reverse |> tl |> Enum.reverse 
data = input |> Foo.parsefile([]) |> IO.inspect(label: :data)

{seq, tree_initial} = data
# transform data so that all nodenames start with A or Z (faster matching)
tree =
  tree_initial
  |> Enum.map(fn {node, lr} = n ->
      {String.reverse(node), Enum.map(lr, &String.reverse/1)}
      end)

# calculate the list of initial nextnodes.
  nextnodes = tree
  |> Enum.filter(fn {node, lr} = n -> String.first(node) == "A" end)
  |> Enum.map(fn {node, lr} = n -> node end)

IO.inspect(length(tree), label: "length1")
IO.inspect(length(nextnodes), label: "length2")

IO.inspect nextnodes
count = Foo.multi_step(tree, nextnodes, seq, 0, seq)

IO.inspect count
