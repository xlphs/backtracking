defmodule Sudoku do
  def solve do
    # From https://en.wikipedia.org/wiki/Sudoku
    sudoku = [
      [5,   3, :_, :_,  7, :_, :_, :_, :_],
      [6,  :_, :_,  1,  9,  5, :_, :_, :_],
      [:_,  9,  8, :_, :_, :_, :_,  6, :_],
      [8,  :_, :_, :_,  6, :_, :_, :_,  3],
      [4,  :_, :_,  8, :_,  3, :_, :_,  1],
      [7,  :_, :_, :_,  2, :_, :_, :_,  6],
      [:_,  6, :_, :_, :_, :_,  2,  8, :_],
      [:_, :_, :_,  4,  1,  9, :_, :_,  5],
      [:_, :_, :_, :_,  8, :_, :_,  7,  9],
    ]
    {problem, assigned, unassigned} = transform(sudoku)
    case bt(problem, %{constraints: unassigned, solution: assigned}) do
      {:ok, s} -> pretty_print(s.solution)
      _ -> false
    end
  end

  def pretty_print(s) do
    Enum.each(0..8, fn r -> pretty_print_row(s, r) end)
  end
  def pretty_print_row(s, r) do
    idx = for i <- 0..8, do: {r, i}
    line = Map.take(s, idx) |> Map.values |> Enum.join(", ")
    IO.puts "[#{line}]"
  end

  def transform(list) do
    problem = to_map(list)
    assigned = Map.to_list(problem)
      |> Enum.filter(fn {_cell,num} -> num != :_ end)
      |> Enum.into(%{})
    # order of unassigned cells is important because it affects search path
    unassigned = Map.drop(problem, Map.keys(assigned))
      |> Map.keys
      |> Enum.sort_by(&(&1), fn {r1,c1}, {r2,c2} ->
          if r1 == r2 do
            c1 < c2
          else
            r1 < r2
          end
        end)
    {problem, assigned, unassigned}
  end

  def to_map(list), do: to_map(list, %{}, 0)
  def to_map([], p, _i), do: p
  def to_map([h|t], p, row) do
    m = Stream.with_index(h)
      |> Stream.map(fn {num,col} -> %{{row,col} => num} end)
      |> Enum.reduce(%{}, fn x, acc -> Map.merge(acc, x) end)
    to_map(t, Map.merge(p,m), row + 1)
  end

  # entry point, start by generating a list of choices
  def bt(problem, candidate) do
    {next_candidate, choices} = choose(problem, candidate)
    bt(problem, next_candidate, choices)
  end
  def bt(problem, candidate, [choice|rest]) do
    next_candidate = next(problem, candidate, choice)
    case bt(problem, next_candidate) do
      {:ok, solution} -> {:ok, solution}
      false -> bt(problem, candidate, rest)
    end
  end
  def bt(problem, candidate, []) do
    case accept(problem, candidate) do
      true -> {:ok, candidate}
      false -> false
    end
  end

  def choose(_p, %{constraints: cns, solution: sln}=s) do
    case cns do
      [cell|rest] ->
        # {r,c} = cell
        # IO.puts "Making choices for row #{r} col #{c}"
        list = Enum.reduce(1..9, [], fn x,acc ->
          try = Map.put(sln, cell, x)
          add = with p1 <- check_row(try, cell),
                     p2 <- check_col(try, cell),
                     p3 <- check_box(try, cell),
                 do: p1 and p2 and p3
          if add == true do
            [x] ++ acc
          else
            acc
          end
        end) |> Enum.reverse
        choices = Enum.map(list, fn x -> {cell, x} end)
        # IO.inspect choices
        {%{s|constraints: rest}, choices}
      [] -> {s, []}
    end
  end

  def check_row(s, {r,_c}) do
    idx = for i <- 0..8, do: {r, i}
    nums = Map.take(s, idx) |> Map.values
    uniq = Enum.uniq(nums)
    length(nums) == length(uniq)
  end

  def check_col(s, {_r,c}) do
    idx = for i <- 0..8, do: {i, c}
    nums = Map.take(s, idx) |> Map.values
    uniq = Enum.uniq(nums)
    length(nums) == length(uniq)
  end

  def check_box(s, {r,c}) do
    {x, y} = {r - rem(r, 3), c - rem(c, 3)}
    idx = for i <- x..(x+2),
              k <- y..(y+2), do: {i, k}
    nums = Map.take(s, idx) |> Map.values
    uniq = Enum.uniq(nums)
    length(nums) == length(uniq)
  end

  def next(_p, %{solution: sln}=s, {letter,digit}) do
    candidate = Map.put(sln, letter, digit)
    %{s | solution: candidate}
  end

  def accept(p, %{solution: sln}=_s) do
    Map.keys(sln) |> length == Map.keys(p) |> length
  end
end

IO.inspect Sudoku.solve()
