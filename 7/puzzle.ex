defmodule Foo do

  def sampletext() do
    """
    32T3K 765
    T55J5 684
    KK677 28
    KTJJT 220
    QQQJA 483
    """
  end

  def readfile() do
    {:ok, data} = File.read("input")
    data
  end

  def cardvalues(), do: "23456789TJQKA"

  def sym_val_map() do
    for {x, idx} <- String.graphemes(cardvalues) |> Enum.with_index, into: %{}, do: {x, idx+1}
  end
  
  def parse_line(line) do
    line
    |> String.trim()
    |> String.split()
    |> then(fn [a, b] -> {a, Integer.parse(b) |> elem(0)} end)
  end

  def string_to_hand(str) do
    str
    |> String.graphemes()
    |> Enum.map(fn x -> Map.get(sym_val_map, x) end)
  end
  
  def eval_hand(hand_str) do
    ordered = hand_str |> string_to_hand |> Enum.sort
    hand_type =
      case ordered do
	[a, a, a, a, a ] -> :fiveofakind
	[a, a, b, b, b ] -> :fullhouse
	[a, a, a, b, b ] -> :fullhouse
	[a, a, a, a, b ] -> :fourofakind
	[b, a, a, a, a ] -> :fourofakind
	[a, a, a, b, c ] -> :threeofakind
	[b, a, a, a, c ] -> :threeofakind
	[b, c, a, a, a ] -> :threeofakind
	[a, a, b, c, c ] -> :twopair
	[a, a, c, c, b ] -> :twopair
	[b, a, a, c, c ] -> :twopair
	[a, a, b, c, d ] -> :onepair
	[b, a, a, c, d ] -> :onepair
	[b, c, a, a, d ] -> :onepair
	[b, c, d, a, a ] -> :onepair
	[a, b, c, d, e ] -> :highcard
	_ -> nil
      end
    { hand_str |> string_to_hand, hand_type }
  end

  def calculate_strength({_cards, handtype} = _hand) do
    case handtype do
      :fiveofakind -> 7
      :fourofakind -> 6
      :fullhouse -> 5
      :threeofakind -> 4
      :twopair -> 3
      :onepair -> 2
      :highcard -> 1
    end
  end

  def calculate_for_sort({cards, _handtype} = hand) do
    val = 0x100_000 * calculate_strength(hand)
    val = val + 0x10_000 * hd(Enum.slice(cards, 0, 1))
    val = val + 0x1_000 * hd(Enum.slice(cards, 1, 1))
    val = val + 0x100 * hd(Enum.slice(cards, 2, 1))
    val = val + 0x10 * hd(Enum.slice(cards, 3, 1))
    val = val + 0x1 * hd(Enum.slice(cards, 4, 1))
    
    val
  end
  
  def hand_sorter(a, b) do
    {a_hand, _a_bid} = a
    {b_hand, _b_bid} = b
    calculate_for_sort(a_hand) <= calculate_for_sort(b_hand)
  end
  
  def rank_hands(hands_bids) do
    # sort by the strength of the hand
    n = length(hands_bids)
    Enum.zip(1..n,  
      hands_bids |> Enum.sort(&hand_sorter/2)
    )
  end
end

#input = Foo.sampletext |> String.split("\n") |> Enum.reverse |> tl |> Enum.reverse 
input = Foo.readfile |> String.split("\n") |> Enum.reverse |> tl |> Enum.reverse 
data = Enum.map(input, &Foo.parse_line/1)

hands_bids =
data
|> Enum.map(fn {handstr, bid} -> { Foo.eval_hand(handstr), bid } end)

hands_bids
|> Enum.map(fn {hand, _bid} -> hand end)
|> Enum.map(&Foo.calculate_strength/1 )
#|> IO.inspect(charlists: :as_lists)

ranked = Foo.rank_hands(hands_bids) # |> IO.inspect(charlists: :as_lists)
#IO.inspect( ranked, limit: :infinity)

res = ranked |> Enum.map(fn {rank, {hand, bid}} -> rank * bid end)
IO.inspect Enum.sum(res)

