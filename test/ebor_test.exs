defmodule EborTest do
  use ExUnit.Case
  doctest EBOR

  test "encodes and decodes a basic tuple" do
    original = {"message", 123, true}
    encoded = EBOR.encode(original)
    {:ok, decoded, _rest} = EBOR.decode(encoded)

    assert decoded == original
  end

  test "supports large tuples up to 256 elements" do
    large_tuple = List.to_tuple(Enum.to_list(1..255))
    encoded = EBOR.encode(large_tuple)
    {:ok, decoded, _rest} = EBOR.decode(encoded)

    assert decoded == large_tuple
    assert tuple_size(decoded) == 255
  end

  defmodule TestStruct, do: defstruct([:tag, :name])

  test "supports encode structs" do
    struct = %TestStruct{tag: "tag", name: "name"}

    encoded = EBOR.encode(struct)
    {:ok, decoded, _rest} = EBOR.decode(encoded)

    assert decoded["tag"] == "tag" and decoded["name"] == "name"
  end
end
