defmodule Elixirpi do
  alias Decimal, as: D
  @d1 D.new(1)
  @d2 D.new(2)
  @d4 D.new(4)
  @d5 D.new(5)
  @d6 D.new(6)
  @d8 D.new(8)
  @d16 D.new(16)

  def term_slow(n) do
    D.div(D.new(1), D.new(n) |> D.mult(D.new(n+1)) |> D.mult(D.new(n+2)))
  end

  def run_slow do
    D.set_context(%D.Context{D.get_context | precision: 100}) 

    pi = 1..10000
      |> Enum.reduce(D.new(0), fn(i, acc) -> acc |> D.add(term_slow(i*4-2)) |> D.sub(term_slow(i*4)) end)
      |> D.mult(D.new(4))


    pi = D.add(pi, D.new(3))
    IO.puts "PI is "
    IO.inspect pi
  end


  def positive_pow(_num, 0) do
    @d1
  end

  def positive_pow(num, exp) do
    Enum.reduce(1..exp, @d1, fn(_, acc) -> D.mult(acc, num) end)
  end

  def negative_pow(num, exp) do
    D.div(@d1, positive_pow(num, exp))
  end

  def term(digit_position) do
    digit_position_decimal = D.new(digit_position)
    eight_times_digit_pos = D.mult(@d8, digit_position_decimal)
    D.div(@d4, eight_times_digit_pos |> D.add(@d1))
    |> D.sub(D.div(@d2, eight_times_digit_pos |> D.add(@d4)))
    |> D.sub(D.div(@d1, eight_times_digit_pos |> D.add(@d5)))
    |> D.sub(D.div(@d1, eight_times_digit_pos |> D.add(@d6)))
    |> D.mult(negative_pow(@d16, digit_position))
  end


  def run do
    D.set_context(%D.Context{D.get_context | precision: 1000}) 

    pi = Enum.reduce(0..750, D.new(0), fn(digit_pos, pi) -> D.add(term(digit_pos), pi) end)

    IO.puts "PI is "
    IO.inspect pi
  end


end
