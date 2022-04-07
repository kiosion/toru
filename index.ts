import express from 'express';
import fetch from 'node-fetch';

const app = express();

import { procOptions, imgRes } from './types.d';

import lfm from './lib/lfm';
import img from './lib/img';

// Root route routes
app.get('/', (req, res) => {
	res.send('Shoo! Nothing to see here');
});

app.get('/api(/)?', (req, res) => {
	res.send('Shoo! Nothing to see here');
})

// API routes
app.get('/api/v1/(*)/?', (req, res) => {
	// Check username is provided
	if ((req.url.split('/')[3].split('/?')[0]) == null) {
		res.status(404).send('Username not provided!');
		return;
	}

	const start = new Date().getTime();
	const uname: string = req.url.split('/')[3].split('?')[0];

	lfm.getJson(uname)
		.then((data: any) => {
			console.log('\t->lfm res took: ' + (new Date().getTime() - start) / 1000 + 's');
			switch (req.query['res']) {
				case 'art': {
					try {
						const url: string = data.recenttracks.track[0].image[3]['#text'];
						if (url == null) throw new Error('Album art URL not found');
						fetch(url)
							.then((actual) => {
								actual.headers.forEach((v, n) => res.setHeader(n, v));
								actual.body?.pipe(res);
							});
						break;
					} 
					catch (error) {
						res.status(500).send('' + error);
						break;
					}
				}
				case 'json': {
					res.send(
						'<pre>' + JSON.stringify(data, null, 4) + '</pre>'
					);
					break;
				}
				case 'html': {
					let tr_name: string = data.recenttracks.track[0].name;
					let tr_artist: string = data.recenttracks.track[0].artist['#text'];
					let tr_album: string = data.recenttracks.track[0].album['#text'];
					let tr_art_url: string = data.recenttracks.track[0].image[3]['#text'];
					let tr_url: string = data.recenttracks.track[0].url;
					let tr_date: string = '';
					if (data.recenttracks.track[0].date != null) tr_date = data.recenttracks.track[0].date['#text'];
					if (data.recenttracks.track[0]['@attr'] != null && data.recenttracks.track[0]['@attr'].nowplaying == 'true') {
						res.send(
							'<div style="text-align:center;width:500px;height:600px;margin:auto;">' +
							`<h2>@${uname}</h2>` +
							`<p>Now playing:</p>` +
							`<img src="${tr_art_url}" alt="Cover art" width="300" height="300">` +
							`<p><a href="${tr_url}" target="_blank">'${tr_name}'</a><br>By ${tr_artist}, on ${tr_album}</p>` +
							'</div>'
						);
					}
					else {
						res.send(
							'<div style="text-align:center;width:500px;height:600px;margin:auto;">' +
							`<h2>@${uname}</h2>` +
							`<p>Last played (on ${tr_date}):</p>` +
							`<img src="${tr_art_url}" alt="Cover art" width="300" height="300">` +
							`<p><a href="${tr_url}" target="_blank">'${tr_name}'</a><br>By ${tr_artist}, on ${tr_album}</p>` +
							'</div>'
						);
					}
				}
				break;
				default: {
					const imgUrl: string = data.recenttracks.track[0].image[3]['#text'];

					const bRadius: number = parseInt(req.query.borderRadius?.toString() || '20');
					const aRadius: number = parseInt(req.query.coverRadius?.toString() || '16');
					const theme: string = req.query.theme?.toString() || 'light';
					let theme_bgColour = '';
					let theme_textColour = '';
					let theme_accentColour = '';
					switch (theme) {
						case 'nord': {
							theme_bgColour = '#2E3440';
							theme_textColour = '#ECEFF4';
							theme_accentColour = '#81A1C1';
						}
						break;
						case 'dracula': {
							theme_bgColour = '#282A36';
							theme_textColour = '#F8F8F2';
							theme_accentColour = '#6272A4';
						}
						break;
						case 'solarized': {
							theme_bgColour = '#FDF6E3';
							theme_textColour = '#657B83';
							theme_accentColour = '#839496';
						}
						break;
						case 'shoji': {
							theme_bgColour = '#E8E8E3';
							theme_textColour = '#4D4D4D';
							theme_accentColour = '#4D4D4D';
						}
						break;
						case 'dark': {
							theme_bgColour = '#1A1A1A';
							theme_textColour = '#E6E6E6';
							theme_accentColour = '#CCCCCC';
						}
						break;
						case 'light':
						default: {
							theme_bgColour = '#F2F2F2';
							theme_textColour = '#1A1A1A';
							theme_accentColour = '#8C8C8C';
						}
						break;
					}

					if (imgUrl == null) throw new Error('Album art URL not found');
					img.fetchImg(imgUrl)
						.then((response: imgRes) => {
							img.process({
								image: response.image,
								mimetype: response.mimetype,
								isPaused: false,
								bRadius: bRadius,
								aRadius: aRadius,
								bgColour: theme_bgColour,
								textColour: theme_textColour,
								accentColour: theme_accentColour,
								tr_title: data.recenttracks.track[0].name,
								tr_artist: data.recenttracks.track[0].artist['#text'],
								tr_album: data.recenttracks.track[0].album['#text'],
							})
								.then((procObj) => {
									res.format({
										'image/svg+xml': () => {
											res.set('Age', '0');
											res.set('Cache-Control', 'public, max-age=0, must-revalidate');
											res.send(procObj);
										}
									});
								});
						})
						.catch((err) => {
							res.status(500).send('' + err);
						});
				}
				break;
			}
		})
		.catch((error: any) => {
			res.status(500).send('' + error);
		});
});

// Listen on port 3000
app.listen(3000, () => {
	console.log('Server is listening on port 3000');
});
