defprotocol EBOR.Encoder do
  @doc """
  Converts an Elixir data type to its representation in EBOR.
  """

  def encode_into(element, acc)
end

defimpl EBOR.Encoder, for: Atom do
  def encode_into(false, acc), do: <<acc::binary, 0xF4>>
  def encode_into(true, acc), do: <<acc::binary, 0xF5>>
  def encode_into(nil, acc), do: <<acc::binary, 0xF6>>
  def encode_into(:__undefined__, acc), do: <<acc::binary, 0xF7>>
  def encode_into(v, acc), do: EBOR.Utils.encode_string(3, Atom.to_string(v), acc)
end

defimpl EBOR.Encoder, for: BitString do
  def encode_into(s, acc), do: EBOR.Utils.encode_string(3, s, acc)
end

defimpl EBOR.Encoder, for: EBOR.Tag do
  def encode_into(%EBOR.Tag{tag: :bytes, value: s}, acc) do
    EBOR.Utils.encode_string(2, s, acc)
  end

  def encode_into(%EBOR.Tag{tag: :float, value: :inf}, acc) do
    <<acc::binary, 0xF9, 0x7C, 0>>
  end

  def encode_into(%EBOR.Tag{tag: :float, value: :"-inf"}, acc) do
    <<acc::binary, 0xF9, 0xFC, 0>>
  end

  def encode_into(%EBOR.Tag{tag: :float, value: :nan}, acc) do
    <<acc::binary, 0xF9, 0x7E, 0>>
  end

  def encode_into(%EBOR.Tag{tag: :simple, value: val}, acc) when val < 0x100 do
    EBOR.Utils.encode_head(7, val, acc)
  end

  def encode_into(%EBOR.Tag{tag: tag, value: val}, acc) do
    EBOR.Encoder.encode_into(val, EBOR.Utils.encode_head(6, tag, acc))
  end
end

defimpl EBOR.Encoder, for: Date do
  def encode_into(time, acc) do
    EBOR.Encoder.encode_into(
      Date.to_iso8601(time),
      EBOR.Utils.encode_head(6, 0, acc)
    )
  end
end

defimpl EBOR.Encoder, for: DateTime do
  def encode_into(datetime, acc) do
    EBOR.Encoder.encode_into(
      DateTime.to_iso8601(datetime),
      EBOR.Utils.encode_head(6, 0, acc)
    )
  end
end

defimpl EBOR.Encoder, for: Float do
  def encode_into(x, acc), do: <<acc::binary, 0xFB, x::float>>
end

defimpl EBOR.Encoder, for: Integer do
  def encode_into(i, acc) when i >= 0 and i < 0x10000000000000000 do
    EBOR.Utils.encode_head(0, i, acc)
  end

  def encode_into(i, acc) when i < 0 and i >= -0x10000000000000000 do
    EBOR.Utils.encode_head(1, -i - 1, acc)
  end

  def encode_into(i, acc) when i >= 0, do: encode_as_bignum(i, 2, acc)
  def encode_into(i, acc) when i < 0, do: encode_as_bignum(-i - 1, 3, acc)

  defp encode_as_bignum(i, tag, acc) do
    EBOR.Utils.encode_string(
      2,
      :binary.encode_unsigned(i),
      EBOR.Utils.encode_head(6, tag, acc)
    )
  end
end

defimpl EBOR.Encoder, for: List do
  def encode_into([], acc), do: <<acc::binary, 0x80>>

  def encode_into(list, acc) when length(list) < 0x10000000000000000 do
    Enum.reduce(list, EBOR.Utils.encode_head(4, length(list), acc), fn v, acc ->
      EBOR.Encoder.encode_into(v, acc)
    end)
  end

  def encode_into(list, acc) do
    Enum.reduce(list, <<acc::binary, 0x9F>>, fn v, acc ->
      EBOR.Encoder.encode_into(v, acc)
    end) <> <<0xFF>>
  end
end

defimpl EBOR.Encoder, for: Map do
  def encode_into(map, acc) when map_size(map) == 0, do: <<acc::binary, 0xA0>>

  def encode_into(map, acc) when map_size(map) < 0x10000000000000000 do
    Enum.reduce(map, EBOR.Utils.encode_head(5, map_size(map), acc), fn {k, v}, subacc ->
      EBOR.Encoder.encode_into(v, EBOR.Encoder.encode_into(k, subacc))
    end)
  end

  def encode_into(map, acc) do
    Enum.reduce(map, <<acc::binary, 0xBF>>, fn {k, v}, subacc ->
      EBOR.Encoder.encode_into(v, EBOR.Encoder.encode_into(k, subacc))
    end) <> <<0xFF>>
  end
end

# We convert MapSets into lists since there is no 'set' representation
defimpl EBOR.Encoder, for: MapSet do
  def encode_into(map_set, acc) do
    map_set |> MapSet.to_list() |> EBOR.Encoder.encode_into(acc)
  end
end

# We treat all NaiveDateTimes as UTC, if you need to include TimeZone
# information you should convert your data to a regular DateTime
defimpl EBOR.Encoder, for: NaiveDateTime do
  def encode_into(naive_datetime, acc) do
    EBOR.Encoder.encode_into(
      NaiveDateTime.to_iso8601(naive_datetime) <> "Z",
      EBOR.Utils.encode_head(6, 0, acc)
    )
  end
end

# We convert Ranges into lists since there is no 'range' representation
defimpl EBOR.Encoder, for: Range do
  def encode_into(range, acc) do
    range |> Enum.into([]) |> EBOR.Encoder.encode_into(acc)
  end
end

defimpl EBOR.Encoder, for: Time do
  def encode_into(time, acc) do
    EBOR.Encoder.encode_into(
      Time.to_iso8601(time),
      EBOR.Utils.encode_head(6, 0, acc)
    )
  end
end

defimpl EBOR.Encoder, for: Tuple do
  def encode_into(tuple, acc) do
    size = tuple_size(tuple)

    case size <= 255 do
      true ->
        tuple
        |> :erlang.tuple_to_list()
        |> Enum.reduce(<<acc::binary, 0xC4, 0x04, size>>, fn v, acc ->
          EBOR.Encoder.encode_into(v, acc)
        end)

      false ->
        raise ArgumentError, "Tuple size ilegal"
    end
  end
end

defimpl EBOR.Encoder, for: URI do
  def encode_into(uri, acc) do
    EBOR.Encoder.encode_into(
      URI.to_string(uri),
      EBOR.Utils.encode_head(6, 32, acc)
    )
  end
end
