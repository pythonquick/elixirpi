defmodule Elixirpi.Worker do
  alias Elixirpi.Collector
  alias Decimal, as: D

  # Commonly used formula constants:
  @d1 D.new(1)
  @d2 D.new(2)
  @d4 D.new(4)
  @d5 D.new(5)
  @d6 D.new(6)
  @d8 D.new(8)
  @d16 D.new(16)

  defp calc_sixteen_power(0, _) do
    @d1
  end

  defp calc_sixteen_power(exp, exponent_cache) do
    {cache_exp, cache_sixteen_power} = exponent_cache
    Enum.reduce(cache_exp+1..exp, cache_sixteen_power, fn(_, acc) -> D.mult(acc, @d16) end)
  end

  def term(digit_position, sixteen_power) do
    digit_position_decimal = D.new(digit_position)
    eight_times_digit_pos = D.mult(@d8, digit_position_decimal)
    D.div(@d4, eight_times_digit_pos |> D.add(@d1))
      |> D.sub(D.div(@d2, eight_times_digit_pos |> D.add(@d4)))
      |> D.sub(D.div(@d1, eight_times_digit_pos |> D.add(@d5)))
      |> D.sub(D.div(@d1, eight_times_digit_pos |> D.add(@d6)))
      |> D.div(sixteen_power)
  end

  def process_next_digits(precision) do
    D.set_context(%D.Context{D.get_context | precision: precision})
    {next_digit_positions, exponent_cache} = Collector.next_digits

    # Calculate each digit term in concurrent stream of Tasks:
    Task.async_stream(next_digit_positions, fn digit_position ->
      D.set_context(%D.Context{D.get_context | precision: precision})
      exponent = digit_position
      sixteen_power = calc_sixteen_power(exponent, exponent_cache)
      {term(digit_position, sixteen_power), {exponent, sixteen_power}}
    end, timeout: 100000)
    |> Enum.each(fn {:ok, {next_term, exponent_cache}} ->
      Collector.update_pi(next_term, exponent_cache)
    end)

    next_digit_positions
  end

  def keep_processing_digits(precision) do
    next_digit_positions = process_next_digits(precision)
    case next_digit_positions do
      [] -> IO.puts "Worker finished"
      _ -> keep_processing_digits(precision)
    end
  end

  def run do
    Node.connect :"master@gmac.local"
    :global.sync()
    precision = Collector.precision
    keep_processing_digits(precision)
  end
end
