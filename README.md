<div align=center>
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

Toru has a few parameters you can customize through URL query strings (`?` for first param, `&` for following params):

#### Theme

The theme can be specified using `theme=<theme>`. Available themes are:
- dark/light
- shoji
- dracula
- nord
- solarized

#### Border radius

The border radius of the embed can be specified as an integer using `borderRadius=<radius>`

#### Cover radius

The border radius of the album art can be specified as an integer using `coverRadius=<radius>`

#### Response type

There are two response types: 'json' for the raw JSON response, or 'embed' / unspecified for the embed (default). These can be specified as a string using `res=<type>`

#### Custom SVG asset

You can alternativly specify a custom SVG asset using `url=<svg url>`. Toru will fill in the artist name, track title, album title, and cover art resource using the following template strings:
- Cover art -> `${image}` (should be the 'src' attr, as it's a b64-encoded image string)
- Artist -> `${artist}`
- Album -> `${album}`
- Track -> `${title}`

## Building 🔨

- `npm i` to install all dependancies and dev tools
- Create an .env file in the root directory, and provide a last.fm API key + secret
- Then:
	- `npm run dev` to build + run for development
	- `npm run build`, then `npm run serve` if building for production
- Built JS files are saved to ./dist, and the app is served at localhost:3000

## Contribute ✍️
If you're knowledgeable with Node.js, Express.js, Typescript, or working on similar projects, feel free to contribute!
