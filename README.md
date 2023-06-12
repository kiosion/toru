<div align="center">
  <h1>Toru</h1>
  <p>An API for generating customizable embeds of last.fm activity</p>
</div>

## Demos 🚧

<div align="center">
  <a href="https://last.fm/user/kiosion" target="_blank"><img src="https://toru.kio.dev/api/v1/kiosion?theme=dark" alt="Last.fm Activity" width="380px" /></a>
  <a href="https://last.fm/user/kiosion" target="_blank"><img src="https://toru.kio.dev/api/v1/kiosion?theme=light" alt="Last.fm Activity" width="380px" /></a>
</div>

## Usage 🔧
Simply add the following snippet to your Github profile readme (or anywhere else you'd like to embed your last.fm activity):
```
<img src="https://toru.kio.dev/api/v1/{your_lfm_username}" alt="Last.fm Activity" />
```

You can append `?res=json` to get a JSON response:
```
GET https://toru.kio.dev/api/v1/{your_lfm_username}?res=json
->
{
  status: 200,
  data: {
    url: "https://last.fm/music/X",
    title: "X",
    streamable: false,
    playing: true,
    cover_art: {
      mime_type: "image/png",
      data: "X"
    },
    artist: "X",
    album: "X"
  }
}
```

You can also connect to the Websocket endpoint - recieved frames will be of the "data" field above. Minute-interval pings are required to stay connected.
```
wss://toru.kio.dev/api/v1/ws/{your_lfm_username}
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

#### Blurred background
You can pass `blur` as a query param to enable a blurred background:

<a href="https://last.fm/user/kiosion" target="_blank"><img src="https://toru.kio.dev/api/v1/kiosion?theme=nord&blur" alt="Last.fm Activity" width="380px" /></a>

#### Border width
The width of the borders can be specified (or removed by setting to '0') with `border_width=<int>`:

<a href="https://last.fm/user/kiosion" target="_blank"><img src="https://toru.kio.dev/api/v1/kiosion?theme=dracula&border_width=0" alt="Last.fm Activity" width="380px" /></a>

#### Custom SVG asset
You can alternativly specify a custom SVG asset with `svg_url=<str>`. Toru will fill in the artist name, track title, album title, and cover art resource using the following template strings:
- Cover art -> `${cover_art}` (should be the 'src' attr, as it's sent as a b64-encoded image string)
- Artist -> `${artist}`
- Album -> `${album}`
- Track -> `${title}`

## Building / Testing 🔨
- Clone the repo
- `mix local.hex --if-missing --force && mix local.rebar --if-missing --force` to install Hex and Rebar3
- `mix deps.get` to pull & compile needed dependencies

### Running
- Make sure you have an `.env` file in the project root, with `LFM_TOKEN` set to your last.fm API key, and optionally `PORT` set to the port you want to run the dev server on (default is 4000)
- `make dev` to run the dev server, or `make test` to run all unit tests.

### Building a release
- Environment variables `LFM_TOKEN` and `PORT` are required to build a release
- `make release` compiles environment variables and builds a docker image with the release
- `make run` stops any previuosly running docker container, and runs the new release

## Contributing 🤝
Feel free to open an issue or pull request if you have suggestions or find any bugs!
