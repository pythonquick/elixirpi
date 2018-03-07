defmodule Elixirpi do
  alias Decimal, as: D

  def term(n) do
    D.div(D.new(1), D.new(n) |> D.mult(D.new(n+1)) |> D.mult(D.new(n+2)))
  end

  def run do
    D.set_context(%D.Context{D.get_context | precision: 100}) 

    pi = 1..10000
      |> Enum.reduce(D.new(0), fn(i, acc) -> acc |> D.add(term(i*4-2)) |> D.sub(term(i*4)) end)
      |> D.mult(D.new(4))


    pi = D.add(pi, D.new(3))
    IO.puts "PI is "
    IO.inspect pi
  end
end
