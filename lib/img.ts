import sharp from 'sharp';
import fetch from 'node-fetch';

// import * as defaults from '../lib/constants';
import { procOptions, imgRes } from '../types.d';

module img {
	export const fetchImg = (url: string): Promise<imgRes> => new Promise (async (resolve, reject) => {
        const response = await fetch(url);
		const arrayBuffer = await response.arrayBuffer();
		const buffer = Buffer.from(arrayBuffer);
		const mimetype = response.headers.get('content-type') || 'image/jpg';
		resolve({buffer, mimetype});
    });

	const htmlEncode = (str: string): string => {
		return str
			.replace(/&/g, '&amp;')
			.replace(/</g, '&lt;')
			.replace(/>/g, '&gt;')
			.replace(/"/g, '&quot;')
			.replace(/'/g, '&#39;');
	}

	const compImg = (image: Buffer): Promise<string> => new Promise ((resolve, reject) => {
		sharp(image)
			.resize(200,200)
			.composite([
				{
					input: './lib/assets/pause.png',
					gravity: 'center',
					blend: 'multiply',
				},
			])
			.toBuffer()
			.then((buffer) => {
				resolve(buffer.toString('base64'));
			})
			.catch((err) => {
				reject(err);
			});
	});

	export const process = (options: procOptions): Promise<string> => new Promise ((resolve, reject) => {
		// Get args from array
		const { buffer, mimetype, isPaused, bRadius, aRadius, bgColour, textColour, accentColour, tr_title, tr_artist, tr_album } = options;
		const width: number = 412;
		const height: number = 128;
		const tr_title_enc = htmlEncode(tr_title);
		const tr_artist_enc = htmlEncode(tr_artist);
		const tr_album_enc = htmlEncode(tr_album);

		if (isPaused) {
			// Composite image with pause overlay
			compImg(buffer)
				.then((image) => {
					resolve(`
						<svg xmlns="http://www.w3.org/2000/svg" xmlns:xhtml="http://www.w3.org/1999/xhtml" width="${width}" height="${height}">
							<foreignObject width="${width}" height="${height}">
								<style>
									span {
										font-family: 'Century Gothic', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
										overflow: hidden;
										display: -webkit-box;
										-webkit-line-clamp: 2;
										-webkit-box-orient: vertical;
										line-height: 1.5rem;
									}
								</style>
								<div xmlns="http://www.w3.org/1999/xhtml" style="display:flex; flex-direction:row; justify-content:flex-start; align-items:center; width:100%; height:100%; border-radius:${bRadius}px; background-color:${bgColour}; color:${textColour}; padding:0 14px; box-sizing:border-box; overflow:clip;">
									<div style="display:flex; height: fit-content; width: fit-content;">
										<img src="data:${mimetype};base64,${image}" alt="Cover art" style="border: 1.6px solid ${accentColour}; border-radius:${aRadius}px" width="100px" height="100px" />
									</div>
									<div style="display:flex; flex-direction:column; padding-left:14px;">
										<span style="font-size: 20px; font-weight: bold; padding-bottom: 6px; border-bottom: 1.6px solid ${accentColour};">${tr_title_enc}</span>
										<span style="font-size:16px; font-weight:normal; margin-top:4px;">${tr_artist_enc} - ${tr_album_enc}</span>
									</div>
								</div>
							</foreignObject>
						</svg>
					`);
				})
				.catch((err) => {
					reject(err);
				});
		}
		else {
			resolve(`
				<svg xmlns="http://www.w3.org/2000/svg" xmlns:xhtml="http://www.w3.org/1999/xhtml" width="${width}" height="${height}">
					<foreignObject width="${width}" height="${height}">
						<style>
							span {
								font-family: 'Century Gothic', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
								overflow: hidden;
								display: -webkit-box;
								-webkit-line-clamp: 2;
								-webkit-box-orient: vertical;
								line-height: 1.5rem;
							}
						</style>
						<div xmlns="http://www.w3.org/1999/xhtml" style="display:flex; flex-direction:row; justify-content:flex-start; align-items:center; width:100%; height:100%; border-radius:${bRadius}px; background-color:${bgColour}; color:${textColour}; padding:0 14px; box-sizing:border-box; overflow:clip;">
							<div style="display:flex; height: fit-content; width: fit-content;">
								<img src="data:${mimetype};base64,${buffer.toString('base64')}" alt="Cover art" style="border: 1.6px solid ${accentColour}; border-radius:${aRadius}px" width="100px" height="100px" />
							</div>
							<div style="display:flex; flex-direction:column; padding-left:14px;">
								<span style="font-size: 20px; font-weight: bold; padding-bottom: 6px; border-bottom: 1.6px solid ${accentColour};">${tr_title_enc}</span>
								<span style="font-size:16px; font-weight:normal; margin-top:4px;">${tr_artist_enc} - ${tr_album_enc}</span>
							</div>
						</div>
					</foreignObject>
				</svg>
			`);
		}
	});
}

export default img;
