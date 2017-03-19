defmodule Puzzle do
  @moduledoc """
  Solve the cryto arithmetic puzzle
      SEND
    + MORE
   -------
   = MONEY

  SEND = 9567
  MORE = 1085
  MONEY = 10652
  """

  def to_number(l), do: Enum.reduce(l, 0, &(&2*10+&1))

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

  def conflict(sln) do
    with {:ok, s} <- Keyword.fetch(sln, :s),
         {:ok, e} <- Keyword.fetch(sln, :e),
         {:ok, d} <- Keyword.fetch(sln, :d),
         {:ok, y} <- Keyword.fetch(sln, :y),
      do: s+1+1 < 10 or (d+e != y or d+e != y+10)
  end

  def choose(_p, %{constraints: cns, solution: sln}=s) do
    case cns do
      [h|t] ->
        {letter, min} = h
        if letter == :m do
          # m must be equal to 1
          {%{s|constraints: t}, [{:m,1}]}
        else
          if conflict(sln) == true do
            {s, []} # cause backtracking
          else
            # ensure unique digit
            list = :lists.seq(min, 9) -- Keyword.values(sln)
            choices = Enum.map(list, fn d -> {letter,d} end)
            {%{s|constraints: t}, choices}
          end
        end
      [] -> {s, []}
    end
  end

  def next(_p, %{solution: sln}=s, {letter,digit}) do
    candidate = Keyword.put(sln, letter, digit)
    %{s | solution: candidate}
  end

  def accept(_p, %{solution: sln}=_s) do
    success = with {:ok, s} <- Keyword.fetch(sln, :s),
         {:ok, e} <- Keyword.fetch(sln, :e),
         {:ok, n} <- Keyword.fetch(sln, :n),
         {:ok, d} <- Keyword.fetch(sln, :d),
         {:ok, m} <- Keyword.fetch(sln, :m),
         {:ok, o} <- Keyword.fetch(sln, :o),
         {:ok, r} <- Keyword.fetch(sln, :r),
         {:ok, y} <- Keyword.fetch(sln, :y),
         send <- to_number([s,e,n,d]),
         more <- to_number([m,o,r,e]),
         money = to_number([m,o,n,e,y]),
      do: send + more == money and money > 10000 and send > 1000 and more > 1000
    success == true
  end

  def solve do
    # putting the known m=1 as first will reduce backtracking
    problem = [m: 1, s: 0, e: 0, n: 0, d: 0, o: 0, r: 0, y: 0]
    case bt(problem, %{constraints: problem, solution: Keyword.new()}) do
      {:ok, s} -> s.solution
      _ -> false
    end
  end

end

IO.inspect Puzzle.solve()
