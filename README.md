<div align=center>
<h1>Toru</h1>
<p>A simple API for generating customizable embeds of last.fm activity</p>
</div>

## Demo 🚧
[![Currently listening](https://toru.kio.dev/api/v1/kiosion/?theme=dark&)](https://last.fm/user/kiosion)

## Usage 🔧
Simply add the following snippet to your Github profile readme (or anywhere else you'd like to embed your last.fm activity):
```
[![Most Recent Last.fm Track](https://toru.kio.dev/api/v1/<your_lfm_username>/)](https://last.fm/user/<your_lfm_username>)
```

## Options ⚙️
Toru has a few parameters you can customize through URL query strings:

#### Theme
The theme can be specified using `?theme=<theme>`. Available themes are:
- light
- dark
- shoji
- dracula
- nord
- solarized

#### Border radius
The border radius of the ember can be specified using `?borderRadius=<number>`

#### Cover Radius
The border radius of the album art can be specified using `?coverRadius=<number>`

## Contribute ✍️
If you're knowledgeable with Node.js, Express.js, Typescript, or working on similar projects, feel free to contribute!
