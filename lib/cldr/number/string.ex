defmodule Cldr.Number.String do
  @moduledoc false

  @doc """
  Returns a regex which matches all latin1 characters.

  """
  @latin1 "([\\x00-\\x7F])"
  def latin1 do
    ~r/#{@latin1}/
  end

  @doc """
  Returns a regex which matches all non-latin1 characters.

  """
  @not_latin1 "([^\\x00-\\x7F])"
  def not_latin1 do
    ~r/#{@not_latin1}/
  end

  @doc """
  Replaces characters with a string hex representation.
  """
  def hex_string(string) do
    String.to_charlist(string)
    |> Enum.map(&("\\x" <> Integer.to_string(&1)))
    |> Enum.join()
  end

  @doc """
  Pad a a string (representing a number) with leading "0"'s to the
  specified length.

  ## Options

  * `number` is a string representation of a number.

  * `count` is the final length required of the string.

  """
  @spec pad_leading_zeros(String.t(), integer) :: String.t()
  def pad_leading_zeros(number_string, count) when count <= 0 do
    number_string
  end

  def pad_leading_zeros(number_string, count) do
    :binary.copy("0", count - byte_size(number_string)) <> number_string
  end

  @doc """
  Pad a a string (representing a number) with trailing "0"'s to the
  specified length.

  ## Options

  * `number` is a string representation of a number.

  * `count` is the final length required of the string.

  """
  @spec pad_trailing_zeros(String.t(), integer) :: String.t()
  def pad_trailing_zeros(number_string, count) when count <= 0 do
    number_string
  end

  def pad_trailing_zeros(number_string, count) do
    number_string <> :binary.copy("0", count - byte_size(number_string))
  end

  @doc """
  Split a string up into fixed size chunks.

  Returns a list of strings the size of `size` plus potentially
  one more chunk at the end that is the remainder of the string
  after chunking.

  ## Examples

      iex> Cldr.Number.String.chunk_string("This is a string", 3)
      ["Thi", "s i", "s a", " st", "rin", "g"]

      iex> Cldr.Number.String.chunk_string("1234", 4)
      ["1234"]

      iex> Cldr.Number.String.chunk_string("1234", 3)
      ["123","4"]

      iex> Cldr.Number.String.chunk_string("1234", 3, :reverse)
      ["1", "234"]

  """
  @spec chunk_string(String.t(), integer, :forward | :reverse) :: [String.t()]
  def chunk_string(string, size, direction \\ :forward)

  def chunk_string(string, 0, _direction) do
    [string]
  end

  def chunk_string("", _size, _) do
    [""]
  end

  if Version.compare(System.version(), "1.6.0") in [:gt, :eq] do
    def chunk_string(string, size, :forward) do
      string
      |> String.to_charlist()
      |> Enum.chunk_every(size, size, [])
      |> Enum.map(&List.to_string/1)
    end
  else
    def chunk_string(string, size, :forward) do
      string
      |> String.to_charlist()
      |> Enum.chunk(size, size, [])
      |> Enum.map(&List.to_string/1)
    end
  end

  def chunk_string(string, size, :reverse) do
    len = String.length(string)
    remainder = rem(len, size)

    if remainder > 0 do
      {head, last} = String.split_at(string, remainder)
      [head] ++ do_chunk_string(last, size)
    else
      do_chunk_string(string, size)
    end
  end

  defp do_chunk_string("", _size) do
    []
  end

  defp do_chunk_string(string, size) do
    {chunk, rest} = String.split_at(string, size)
    [chunk] ++ do_chunk_string(rest, size)
  end
end
