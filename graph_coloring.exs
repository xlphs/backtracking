defmodule Coloring do
  @moduledoc """
  Color the map of Germany such that no two adjacent states have
  the same color, using 4 colors.
  """

  def germany do
    problem = [
      {:BW, :BY},
      {:TH, :BY},
      {:HE, :BW}, {:HE, :TH}, {:HE, :BY},
      {:RP, :SL}, {:RP, :HE}, {:RP, :BW},
      {:SN, :TH}, {:SN, :BY},
      {:NW, :HE}, {:NW, :RP},
      {:BB, :BE}, {:BB, :SN},
      {:ST, :BB}, {:ST, :SN}, {:ST, :TH},
      {:NI, :HE}, {:NI, :NW},
      {:NI, :HB}, {:NI, :BB}, {:NI, :ST}, {:NI, :TH},
      {:MV, :NI}, {:MV, :BB},
      {:HH, :NI}, {:HH, :SH},
      {:SH, :NI}, {:SH, :HH}, {:SH, :MV}
    ]
    case bt(problem, %{constraints: problem, solution: Keyword.new()}) do
      {:ok, s} ->
        Enum.map(s.solution, fn {s,c} -> {s,color(c)} end)
      _ -> false
    end
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

  def get_color_choices(state, sln) do
    case sln[state] do
      nil -> :lists.seq(1, 4) |> Enum.map(fn c -> {state,c} end)
      _ -> []
    end
  end

  def filter_color_choices(choices, state, sln) do
    filter = sln[state]
    Enum.reduce(choices, [],
      fn ({s,c}, acc) ->
        if c == filter do
          acc
        else
          [{s,c}] ++ acc
        end
    end) |> Enum.reverse
  end

  def choose(p, %{constraints: cns, solution: sln}=s) do
    case cns do
      [h|t] ->
        {sa,sb} = h
        # IO.puts "Making choices for {#{sa}, #{sb}}"
        # generate a list of possible colors choices for sa (state a) or sb
        # depending on which one has not been assigned a color
        # - if all have been assigned, check for conflict, if conflicted, then
        #   return no choices to cause backtracking, otherwise
        #   remove `h` from constraints and recurse
        # - if none of them have been assigned, return choices for sa and keep
        #   `h` in constraints
        # - if either sa or sb has been assigned, return choices of the state
        #   that hasn't been assigned and remove `h` from constraints
        # obviously, if one of the states has been assigned a color, then
        # that color cannot appear in the list of choices
        sa_colors = get_color_choices(sa, sln)
        sb_colors = get_color_choices(sb, sln)
        case sa_colors do
          [] ->
            case sb_colors do
              [] ->
                # sa and sb are both assigned
                if sln[sa] == sln[sb] do
                  {s, []}
                else
                  choose(p, %{s|constraints: t})
                end
              _ ->
                # sa is assigned but sb is not
                sb_colors = filter_color_choices(sb_colors, sa, sln)
                # IO.puts "Logging choices for #{sb}"
                # IO.inspect sb_colors
                {%{s|constraints: t}, sb_colors}
            end
          _ ->
            case sb_colors do
              [] ->
                # sa is not assigned but sb is
                sa_colors = filter_color_choices(sa_colors, sb, sln)
                # IO.puts "Logging choices for #{sa}"
                # IO.inspect sa_colors
                {%{s|constraints: t}, sa_colors}
              _ ->
                # neither sa nor sb has been assigned
                # IO.puts "Logging choices for #{sa}"
                # IO.inspect sa_colors
                {s, sa_colors}
            end
        end
      [] -> {s, []}
    end
  end

  def next(_p, %{solution: sln}=s, {state,color}) do
    candidate = Keyword.put(sln, state, color)
    %{s | solution: candidate}
  end

  def accept(problem, %{solution: solution}=_s) do
    Enum.reduce_while(problem, true, fn ({sa,sb}, acc) ->
      if solution[sa] != nil and solution[sb] != nil do
        {:cont, acc and (solution[sa] != solution[sb])}
      else
        {:halt, false}
      end
    end)
  end

  def color(1), do: :red
  def color(2), do: :green
  def color(3), do: :blue
  def color(4), do: :yellow
  def color(_), do: :badarg
end

IO.inspect Coloring.germany()
