import express from 'express';
import fetch from 'node-fetch'
import fs from 'fs';
import path from 'path';

const app = express();

import * as defaults from './lib/constants';

import lfm from './lib/lfm';
import img from './lib/img';

// Root route routes
app.get('/', (req, res) => {
	res.send('Nothing to see here!');
});

// API routes
app.get('/api/v1/(*)/?', (req, res) => {
	// Check username is provided
	if ((req.url.split('/')[3].split('/?')[0]) == null) {
		res.status(404).send('Username not provided!');
		return;
	}

	const start = new Date().getTime();
	const uname: string = req.url.split('/')[3].split('?')[0];

	lfm.getActivity(uname)
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
						res.status(500).send('Error: ' + error);
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
				// temp for now, this needs to be split up BADLY lol
				default: {
					// Check query, todo make this more dynamic
					const queryRad: number = parseInt((req.query.radius || '0').toString());
					const imgUrl: string = data.recenttracks.track[0].image[3]['#text'];
					const fileName: string = data.recenttracks.track[0].name.replace(/[^a-zA-Z0-9()\-]/g, '_')+'.jpg';
					// Download album art to tmpPath
					try {
						// todo: replace with default if no art
						if (imgUrl == null) throw new Error('Album art URL not found');
						img.save(imgUrl, fileName, 'path')
							.then((resPath: string) => {
								img.process(resPath, queryRad)
									.then((procPath) => {
										// If procPath contains 'error', throw error
										if (procPath.includes('error')) throw new Error(procPath);
										// Send image to client, use callback to delete tmp image
										res.sendFile(path.resolve(procPath), (err) => {
											if (err) throw err;
											if (!img.removeTemp(resPath, procPath)) throw new Error('Failed to delete temp files');
										});
									});
							});
					}
					catch (error) {
						res.status(500).send('Error: ' + error);
					}
				}
				break;
			}
		})
		.catch((error: any) => {
			res.status(500).send('Error: ' + error);
		});
});

// Listen on port 3000
app.listen(3000, () => {
	console.log('Server is listening on port 3000');
});
