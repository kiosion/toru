<div align=center>
<h1>Toru</h1>
<p>A simple API for generating customizable embeds of last.fm activity</p>
</div>

## Demos 🚧

[![Last.fm Activity - Dark theme](https://toru.kio.dev/api/v1/kiosion/?theme=dark)](https://last.fm/user/kiosion)

[![Last.fm Activity - Light theme](https://toru.kio.dev/api/v1/kiosion/?theme=light)](https://last.fm/user/kiosion)

## Usage 🔧

Simply add the following snippet to your Github profile readme (or anywhere else you'd like to embed your last.fm activity):
```
[![Last.fm Activity](https://toru.kio.dev/api/v1/<your_lfm_username>/)](https://last.fm/user/<your_lfm_username>)
```

## Options ⚙️

Toru has a few parameters you can customize through URL query strings:

#### Theme

The theme can be specified by appending `?theme=<theme>`. Available themes are:
- dark/light (both shown above)
- shoji
- dracula
- nord
- solarized

#### Border radius

The border radius of the embed can be specified as an integer by appending `?borderRadius=<radius>`

#### Cover radius

The border radius of the album art can be specified as an integer by appending `?coverRadius=<radius>`

#### Response type

There are two response types: 'json' for the raw JSON response, or 'embed' / unspecified for the embed (default). These can be specified as a string by appending `?res=<type>`

#### Custom SVG asset

You can use a custom SVG asset by appending `?svg=<url>`. Toru will fill in the artist name, track title, album title, and cover art resource as a b64 string.

## Building 🔨

- `npm i` to install all dependancies and dev tools
- Create an .env file in the root directory, and provide a last.fm API key + secret
- Then:
	- `npm run dev` to build + run for development
	- `npm run build`, then `npm run serve` if building for production
- Built JS files are saved to ./dist, and the app is served at localhost:3000

## Contribute ✍️
If you're knowledgeable with Node.js, Express.js, Typescript, or working on similar projects, feel free to contribute!
