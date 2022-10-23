<div align="center">
<h1>Toru</h1>
<p>A simple API for generating customizable embeds of last.fm activity</p>
</div>

## Demos 🚧

<div align="center">
  <a href="https://last.fm/user/kiosion" target="_blank"><img src="https://toru.kio.dev/api/v1/kiosion?theme=dark" alt="Last.fm Activity" width="380px" /></a>
  <a href="https://last.fm/user/kiosion" target="_blank"><img src="https://toru.kio.dev/api/v1/kiosion?theme=light" alt="Last.fm Activity" width="380px" /></a>
  <a href="https://last.fm/user/kiosion" target="_blank"><img src="https://toru.kio.dev/api/v1/kiosion?theme=shoji" alt="Last.fm Activity" width="380px" /></a>
  <a href="https://last.fm/user/kiosion" target="_blank"><img src="https://toru.kio.dev/api/v1/kiosion?theme=nord" alt="Last.fm Activity" width="380px" /></a>
</div>

## Usage 🔧
Simply add the following snippet to your Github profile readme (or anywhere else you'd like to embed your last.fm activity):
```
<img src="https://toru.kio.dev/api/v1/{your_lfm_username}" alt="Last.fm Activity" />
```

## Options ⚙️
Toru has a few parameters you can customize through URL query strings:

#### Theme
The theme can be specified with `theme=<str>`. Available themes are:
- dark/light
- shoji
- dracula
- nord
- solarized

#### Border radius
The border radius of the embed can be specified as an integer with `border_radius=<int>`

#### Cover radius
The border radius of the album art can be specified as an integer with `cover_radius=<int>`

#### Response type
There are two response types: 'json' for the raw JSON response, or 'embed' / unspecified for the embed (default). These can be specified as a string with `res=<str>`

#### Custom SVG asset
You can alternativly specify a custom SVG asset with `svg_url=<str>`. Toru will fill in the artist name, track title, album title, and cover art resource using the following template strings:
- Cover art -> `${cover_art}` (should be the 'src' attr, as it's sent as a b64-encoded image string)
- Artist -> `${artist}`
- Album -> `${album}`
- Track -> `${title}`

## Building / Testing 🔨
- Clone the repo
- `mix local.hex --if-missing --force && mix local.rebar --force` to install Hex and Rebar3
- `mix deps.get` to pull & compile dependencies
- Make sure you have a `.env` file in the project root, with `LFM_API_KEY` set to your last.fm API key
- `make dev` to run in dev mode, `make prod` to build a release docker image, or `make test` to run all unit tests

## Contributing 🤝
Feel free to open an issue or PR if you have suggestions or find any bugs!
