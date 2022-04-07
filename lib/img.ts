import sharp from 'sharp';
import fetch from 'node-fetch';

import * as defaults from '../lib/constants';
import { procOptions, imgRes } from '../types.d';

module img {
	export const fetchImg = (url: string): Promise<imgRes> => new Promise (async (resolve, reject) => {
        const response = await fetch(url);
		const arrayBuffer = await response.arrayBuffer();
		const buffer = Buffer.from(arrayBuffer);
		const image = buffer.toString('base64');
		const mimetype = response.headers.get('content-type') || 'image/jpg';
		resolve({image, buffer, mimetype});
    });

	export const getMeta = (path: string): Promise<any> => new Promise ((resolve, reject) => {
		sharp(path).metadata()
			.then((data) => {
				resolve(data);
			})
			.catch((error) => {
				reject(error);
			});
	});

	const blurImg = (img: Buffer): Promise<string> => new Promise ((resolve, reject) => {
		sharp(img)
			.blur(14)
			.toBuffer()
			.then((data) => {
				resolve(data.toString('base64'))
			});
	});

	const htmlEncode = (str: string): string => {
		return str
			.replace(/&/g, '&amp;')
			.replace(/</g, '&lt;')
			.replace(/>/g, '&gt;')
			.replace(/"/g, '&quot;')
			.replace(/'/g, '&#39;');
	}

	export const process = (options: procOptions): Promise<string> => new Promise ((resolve, reject) => {
		// Get args from array
		const { image, buffer, mimetype, bgBlur, isPaused, bRadius, aRadius, bgColour, textColour, accentColour, tr_title, tr_artist, tr_album } = options;
		const width: number = 412;
		const height: number = 128;
		const tr_title_enc = htmlEncode(tr_title);
		const tr_artist_enc = htmlEncode(tr_artist);
		const tr_album_enc = htmlEncode(tr_album);
		
		resolve(`
			<svg xmlns="http://www.w3.org/2000/svg" xmlns:xhtml="http://www.w3.org/1999/xhtml" width="${width}" height="${height}">
				<foreignObject width="${width}" height="${height}">
					<style>
						span {
							font-family: 'Century Gothic', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
						}
					</style>
					<div xmlns="http://www.w3.org/1999/xhtml" style="
						display: flex;
						flex-direction: row;
						justify-content: flex-start;
						align-items: center;
						width:100%;
						height:100%;
						border-radius:${bRadius}px;
						background-color:${bgColour};
						color:${textColour};
						padding: 0 14px;
						box-sizing: border-box;
						overflow: clip;
					">
						<div style="
							display: flex;
							height: fit-content;
							width: fit-content;
							z-index: 1;
						">
							<img src="data:${mimetype};base64,${image}" alt="Cover art" style="border: 1.6px solid ${accentColour}; border-radius:${aRadius}px" width="100px" height="100px" />
						</div>
						<div style="
							display: flex; 
							flex-direction: column;
							padding-left: 12px; 
							z-index: 1;
						">
							<span style="
								font-size: 20px; 
								font-weight: bold; 
								padding-bottom: 6px; 
								line-height: 1.5rem; 
								overflow: hidden;
								display: -webkit-box;
								-webkit-line-clamp: 2;
								-webkit-box-orient: vertical;
								border-bottom: 1.6px solid ${accentColour};
							">${tr_title_enc}</span>
							
							<span style="
								font-size: 16px; 
								font-weight: normal; 
								margin-top: 4px; 
								line-height: 1.4rem; 
								overflow: hidden;
								display: -webkit-box;
								-webkit-line-clamp: 2;
								-webkit-box-orient: vertical;
							">${tr_artist_enc} - ${tr_album_enc}</span>
						</div>
					</div>
				</foreignObject>
			</svg>
		`);
	});
}

export default img;
