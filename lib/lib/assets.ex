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

  @spec themes :: %{String.t() => %{String.t() => String.t()}}
  def themes(), do:
    %{
      "light" => %{
        "background" => "#F4F5F7",
        "text" => "#242932",
        "accent" => "#57606A"
      },
      "dark" => %{
        "background" => "#1A1F24",
        "text" => "#C9D1D9",
        "accent" => "#8B949E"
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

  @spec base_svg :: String.t()
  def base_svg(), do:
    """
    <svg xmlns="http://www.w3.org/2000/svg" xmlns:xhtml="http://www.w3.org/1999/xhtml" width="{{width}}" height="{{height}}" style="overflow:hidden;border-radius:{{bRadius}}px;">
      <foreignObject width="{{width}}" height="{{height}}">
        <style>.bars{position:relative;display:inline-flex;justify-content:space-between;width:12px;height:9px;margin-right:5px;}.bar{width:2.5px;height:100%;background-color:{{theme["accent"]}};border-radius:10000px;transform-origin:bottom;animation:bounce 0.8s ease infinite alternate;content:'';}.bar:nth-of-type(2){animation-delay:-0.8s;}.bar:nth-of-type(3){animation-delay:-1.2s;}@keyframes bounce{0%{transform:scaleY(0.1);}100%{transform:scaleY(1);}}.bgBlur{transform:translate(-10%, -30%);z-index:0;backdrop-filter:blur(18px);filter:blur(18px);background-repeat:no-repeat;position:absolute;top:0;left:0;aspect-ratio:1/1;width:calc({{width}}px + 100px);}:not(.bgBlur){z-index:2;}</style>
        <div xmlns="http://www.w3.org/1999/xhtml" style="display:flex;flex-direction:row;justify-content:flex-start;align-items:center;width:100%;height:100%;border-radius:{{bRadius}}px;background-color:{{theme["background"]}};color:{{theme["text"]}};padding:0 14px;box-sizing:border-box; overflow:clip;">
          <div style="display:flex;height:fit-content;width:fit-content;">
            <img src="data:{{mime_type}};base64,{{cover_art}}" alt="Cover" style="border:{{bWidth}}px solid {{theme["accent"]}};border-radius:{{aRadius}}px; background-color:{{theme["background"]}}" width="100px" height="100px"/>
          </div>
          <div style="display:flex;flex-direction:column;padding-left:14px;">
            <span style="font-family:'Century Gothic',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;overflow:hidden;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;line-height:1.5rem;font-size:20px;font-weight:bold;padding-bottom:calc({{line_margin}}px + {{line_margin}}px / 2);border-bottom:{{bWidth}}px solid {{theme["accent"]}};">{{title}}</span>
            <div style="display:flex;flex-direction:row;justify-content:flex-start;align-items:baseline;width:100%;height:100%;">
              <span style="font-family:'Century Gothic',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;overflow:hidden;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;line-height:1.5rem;font-size:16px;font-weight:normal;margin-top:{{line_margin}}px;">{{playing_indicator}}{{artist}} - {{album}}</span>
            </div>
          </div>
          {{background_image}}
        </div>
      </foreignObject>
    </svg>
    """

  @spec playing_indicator :: String.t()
  def playing_indicator(), do:
    """
    <div class="bars"><span class="bar"/><span class="bar"/><span class="bar"/></div>
    """
end
