import { imgObj, svgTheme, svgText } from './types.d';
import express from 'express';
import fetch from 'node-fetch';
import lfm from './lib/lfm';
import img from './lib/img';
import get from './lib/get';

const app = express();

// Root route routes ?!
app.get('/', (req, res) => {
	res.send('Shoo! Nothing to see here');
});
app.get('/api(/)?', (req, res) => {
	res.send('Shoo! Nothing to see here');
});

// API routes
app.get('/api/v1/(*)/?', (req, res) => {
	// Check username is provided
	if ((req.url.split('/')[3].split('/?')[0]) == null || (req.url.split('/')[3].split('/?')[0]) == '') {
		res.status(404).send('Username not provided!');
		return;
	}

	const start = new Date().getTime();
	const uname: string = req.url.split('/')[3].split('?')[0];

	// Get res from LFM
	lfm.getJson(uname)
		.then((data: any) => {
			console.log('\t->lfm res took: ' + (new Date().getTime() - start) / 1000 + 's');
			switch (req.query['res']) {
				// Case for album cover resource
				case 'cover': {
					try {
						let url: string = data.recenttracks.track[0].image[3]['#text'];
						if (url == null) throw new Error('Album art URL not found');
						fetch(url)
							.then((actual) => {
								actual.headers.forEach((v, n) => res.setHeader(n, v));
								res.set('Age', '0');
								res.set('Cache-Control', 'public, max-age=0, must-revalidate');
								actual.body?.pipe(res);
							});
					} 
					catch (error) {
						res.status(500).send('' + error);
					}
					break;
				}
				// Case for JSON res
				case 'json': {
					res.send('<pre>' + JSON.stringify(data, null, 4) + '</pre>');
					break;
				}
				// Case for default embed
				case 'embed':
				default: {
					// Check LFM returned album text & art url
					if (typeof data.recenttracks.track[0].album['#text'] == 'undefined') throw new Error('Album name not found');
					if (typeof data.recenttracks.track[0].image[2]['#text'] == 'undefined') throw new Error('Album cover URL not found');
					
					// Set some consts
					const bRadius: number = parseInt(req.query.borderRadius?.toString() || '20');
					const aRadius: number = parseInt(req.query.coverRadius?.toString() || '16');
					const coverUrl = get.art(data.recenttracks.track[0].album['#text'], data.recenttracks.track[0].image[2]['#text']);
					const svgTheme: svgTheme = get.theme(req.query.theme?.toString() || 'light');
					const svgText: svgText = { artist: data.recenttracks.track[0].artist['#text'], album: data.recenttracks.track[0].album['#text'], title: data.recenttracks.track[0].name};

					// fetch and process image
					img.get(coverUrl)
						.then((response: imgObj) => {
							img.process({
								image: response,
								isPaused: false,
								bRadius: bRadius,
								aRadius: aRadius,
								theme: svgTheme,
								text: svgText,
							})
								.then((svg) => {
									res.format({
										'image/svg+xml': () => {
											res.set('Age', '0');
											res.set('Cache-Control', 'public, max-age=0, must-revalidate');
											res.send(svg);
										}
									});
								});
						})
						.catch((error) => {
							res.status(500).send('' + error);
						});
				}
				break;
			}
		})
		.catch((error) => {
			res.status(500).send('' + error);
		});
});

// Listen on port 3000
app.listen(3000, () => {
	console.log('Server is listening on port 3000');
});
