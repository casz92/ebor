# EBOR - Enhanced CBOR for Elixir

EBOR is an optimized CBOR serialization library for Elixir, featuring extended **tuple support up to 255 elements**. Designed for speed, efficiency, and seamless data processing.

## 🚀 Features

- ⚡ **High-performance** CBOR serialization and deserialization.
- 🔄 **Extended tuple support** for up to 255 elements.
- 🔗 **Improved interoperability** with CBOR-based ecosystems.
- 🎯 **Easy-to-use API** for maximum flexibility.

## 🛠 Installation

Add EBOR to your `mix.exs`:

```elixir
defp deps do
  [
    {:ebor, "~> 1.0"}
  ]
end
```

## 📌 Usage
Basic serialization and deserialization:
```elixir
iex> encoded = EBOR.encode({"message", 123, 51.89})

iex> decoded = EBOR.decode(encoded)

iex> decoded
{:ok, {"message", 123, 51.89}, ""}
```

## 📜 License
This project is released under the MIT license. See LICENSE for details.


