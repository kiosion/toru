defmodule Toru.Assets do
  @moduledoc """
  Module for getters of constants and assets
  """

  @spec __using__(any) ::
          {:import, [{:column, 7} | {:context, Toru.Assets}, ...],
           [[{any, any}, ...] | {:__aliases__, [...], [...]}, ...]}
  defmacro __using__(_opts) do
    quote do
      import Toru.Assets, only: [get_asset: 1]
    end
  end

  @doc """
  Get an asset from the module by name as atom

  ## Examples

      iex> Toru.Assets.get_asset(:map)
      %{
        "key" => "value"
      }
  """
  @spec get_asset(atom) :: any
  def get_asset(atom) do
    # Check for function of the same name
    if function_exported?(__MODULE__, atom, 0) do
      apply(__MODULE__, atom, [])
    else
      # Check for module of the same name prefixed with "get_"
      if function_exported?(__MODULE__, :"get_#{atom}", 0) do
        apply(__MODULE__, :"get_#{atom}", [])
      else
        raise ArgumentError, "No asset found for #{inspect(atom)}"
      end
    end
  end

  @spec themes :: %{
          optional(<<_::32, _::_*8>>) => %{optional(<<_::32, _::_*16>>) => <<_::56>>}
        }
  def themes() do
    %{
      "light" => %{
        "background" => "#F2F2F2",
        "text" => "#1A1A1A",
        "accent" => "#8C8C8C"
      },
      "dark" => %{
        "background" => "#1A1A1A",
        "text" => "#E6E6E6",
        "accent" => "#CCCCCC"
      },
      "shoji" => %{
        "background" => "#E8E8E3",
        "text" => "#4D4D4D",
        "accent" => "#4D4D4D"
      },
      "solarized" => %{
        "background" => "#FDF6E3",
        "text" => "#657B83",
        "accent" => "#839496"
      },
      "dracula" => %{
        "background" => "#282A36",
        "text" => "#F8F8F2",
        "accent" => "#6272A4"
      },
      "nord" => %{
        "background" => "#2E3440",
        "text" => "#ECEFF4",
        "accent" => "#81A1C1"
      }
    }
  end
end
