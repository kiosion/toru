import express from 'express';
import axios, { AxiosError, AxiosResponse } from 'axios';
import fetch from 'node-fetch'
import dotenv from 'dotenv';
import fs from 'fs';
import imagemagick from 'imagemagick';
import path from 'path';
import { stringify } from 'querystring';

const app = express();
const sharp = require('sharp');

dotenv.config();

const apiKey = process.env.LFM_API_KEY;
const sharedSecret = process.env.LFM_SHARED_SECRET;

const tmpPath = './tmp/';

async function getLFM(username: string): Promise<any> {
	try {
		const { data, status} = await axios.get<any>(
			`http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=${username}&api_key=${apiKey}&format=json`,
			{
				headers: {
					Accept: 'application/json',
				},
			},
		);
		console.log('request for username: ' + username);
		// "response status is: 200"
		console.log('\t->lfm res status is: ', status);

		return data;
	} catch (error) {
		if (axios.isAxiosError(error)) {
			console.log('\t->error message: ', error.message, ' - request url: ', error.config.url);
			return error.message;
		} else {
			console.log('\t->unexpected error: ', error);
			return 'An unexpected error occured';
		}
	}
}

async function getMeta(path: string): Promise<any> {
	try {
		const metadata = await sharp(path).metadata();
		console.log('\t->image proccessed: ', metadata.format);
		return metadata;
	}
	catch (error) {
		console.log('\t->error: ', error);
		return 'An unexpected error occured';
	}
}

async function processImg(inpPath: string, radius: number): Promise<string> {
	try {
		const newFileName = inpPath.split('/').pop()?.split('.').shift() + '_proc.png';
		const newFilePath = tmpPath + newFileName;
		// Round the corners of the image
		await new Promise((resolve, reject) => {
			// Create mask
			imagemagick
				.convert([
					"-size", 300 + "x" + 300,
					"xc:none",
					"-fill", "black",
					"-draw",
					"roundrectangle" + " 0,0,300,300," + radius + "," + radius, 
					"./assets/mask.png",
				], function(err) {
					if (err) {
						reject(err);
					}
					else {
						sharp(inpPath)
							.composite([
								{
									input: "./assets/mask.png",
									blend: "dest-in",
									gravity: "center",
								},
							])
							.toFile(newFilePath)
							.then(() => {
								resolve(newFilePath);
							})
							.catch((error: any) => {
								reject(error);
							});
					}
				});
		});
		// Return new image path
		return newFilePath;
	}
	catch (error) {
		console.log('\t->proc error (' + inpPath + '): ', error);
		return 'An unexpected error occured';
	}
}

async function saveImage(fileName: string, data: NodeJS.ReadableStream): Promise<string> {
	try {
		const filePath = tmpPath + fileName;
		// Create the file
		await new Promise((resolve, reject) => {
			data.pipe(fs.createWriteStream(filePath));
			data
				.on('close', () => {
					resolve(filePath);
				})
				.on('error', (error) => {
					reject(error);
				})
		});
		// Return path once resolved
		return filePath;
	}
	catch (error) {
		console.log('\t->save error: ', error);
		return 'An unexpected error occured';
	}
}

// Root route routes
app.get('/', (req, res) => {
	res.send('Nothing to see here!');
});

// API routes
app.get('/api/v1(/*)?', (req, res) => {
	const start = new Date().getTime();
	// Check username is provided
	if ((req.url.split('/')[3].split('?')[0]) == null) {
		res.status(404).send('Username not provided!');
		return;
	}
	
	let uname: string = req.url.split('/')[3].split('?')[0];

	// Res w/ some random data for now
	getLFM(uname)
		.then(data => {
			console.log('\t->lfm res took: ' + (new Date().getTime() - start) / 1000 + 's');
			switch (req.query['res']) {
				case 'art': {
					try {
						const url: string = data.recenttracks.track[0].image[3]['#text'];
						// If no album art, return default
						if (url == null) throw new Error('No album art found');
						fetch(url).then((actual) => {
							actual.headers.forEach((v, n) => res.setHeader(n, v));
							actual.body?.pipe(res);
						});
						break;
					} 
					catch (error) {
						res.send(
							'<div style="text-align:center;width:500px;height:600px;margin:auto;">' +
							'<h1>Error</h1>' +
							`<p>${error}</p>` +
							'</div>'
						);
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

					// Check if "@attr" is present and is true
					if (data.recenttracks.track[0]['@attr'] != null && data.recenttracks.track[0]['@attr'].nowplaying == 'true') {
						res.send(
							'<div style="text-align:center;width:500px;height:600px;margin:auto;">' +
							`<h2>@${uname}</h2>` +
							`<p>Now playing:</p>` +
							`<img src="${tr_art_url}" alt="Cover art" width="300" height="300">` +
							`<p><a href="${tr_url}" target="_blank">'${tr_name}'</a><br>By ${tr_artist}, on ${tr_album}</p>` +
							'</div>'
						);
						break;
					}
					else {
						res.send(
							'<div style="text-align:center;width:500px;height:600px;margin:auto;">' +
							`<h2>@${uname}</h2>` +
							`<p>Last played (${tr_date}):</p>` +
							`<img src="${tr_art_url}" alt="Cover art" width="300" height="300">` +
							`<p><a href="${tr_url}" target="_blank">'${tr_name}'</a><br>By ${tr_artist}, on ${tr_album}</p>` +
							'</div>'
						);
						break;
					}
				}
				// temp for now, this needs to be split up BADLY lol
				default: {
					// Check query, todo make this more dynamic
					const queryRad: number = parseInt((req.query.res || '14').toString());
					// Download album art to tmpPath
					if (data.recenttracks.track[0].image[3]['#text'] != null) {
						const fileName: string = data.recenttracks.track[0].name.replace(/[^a-zA-Z0-9]/g, '_')+'.jpg';
						fetch(data.recenttracks.track[0].image[3]['#text'])
							.then((actual) => {
								// Save image to tmpPath
								saveImage(fileName, actual.body)
									.then((resPath) => {
										// If resPath contains 'error', throw error
										if (resPath.includes('error')) throw new Error(resPath);
										try {
											// Get metadata from image
											processImg(resPath, queryRad)
												.then((procPath) => {
													// If procPath contains 'error', throw error
													if (procPath.includes('error')) throw new Error(procPath);
													// Send image to client, use callback to delete image
													res.sendFile(path.resolve(procPath), (err) => {
														if (err) throw err;
														// After res, delete album art
														fs.unlink(resPath, (err) => {
															if (err) throw err;
														});
														fs.unlink(procPath, (err) => {
															if (err) throw err;
														});
													});
													// B64 encode album art
													// fs.readFile(procPath, (err, data) => {
													// 	if (err) throw err;
													// 	let b64data: string = Buffer.from(data).toString('base64');
													// 	res.send(
													// 		'<div style="background-color:black;color:white;text-align:center;width:500px;height:600px;margin:auto;">' +
													// 		`<h2>@${uname}</h2>` +
													// 		`<p>Downloaded album art (${resPath}):</p>` +
													// 		`<img src="data:image/png;base64,${b64data}" alt="Cover art" width="300" height="300">` +
													// 		'</div>'
													// 	);
													// 	// After res, delete album art
													// 	fs.unlink(resPath, (err) => {
													// 		if (err) throw err;
													// 	});
													// 	fs.unlink(procPath, (err) => {
													// 		if (err) throw err;
													// 	});
													// 	console.log('\t->final response took: ' + (new Date().getTime() - start) / 1000 + 's');
													// });
												});
										}
										catch (error) {
											res.send(
												'<div style="text-align:center;width:500px;height:600px;margin:auto;">' +
												'<h1>Error</h1>' +
												`<p>${error}</p>` +
												'</div>'
											);
										}
									});
							})
							.catch((error) => {
								console.log('error: ', error);
							});
					}
					break;
				}
			}
		})
		.catch(error => {
			res.send(
				'<h1>' + uname + '</h1>' +
				'<p>Error: ' + error + '</p>'
				);
		});
});

// Listen on port 3000
app.listen(3000, () => {
	console.log('Server is listening on port 3000');
});
