import sharp from 'sharp';
import fetch from 'node-fetch';

import { svgOptions, imgObj, svgText } from '../types.d';

module img {
	export const get = (url: string): Promise<imgObj> => new Promise (async (resolve, reject) => {
        const response = await fetch(url);
		const arrayBuffer = await response.arrayBuffer();
		const buffer = Buffer.from(arrayBuffer);
		const mimetype = response.headers.get('content-type') || 'image/jpg';
		resolve({buffer, mimetype});
    });

	const htmlEncode = (text: svgText): svgText => {
		let { artist, album, title } = text;
		artist = artist.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
		album = album.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
		title = title.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
		return { artist, album, title };
	}

	export const process = (options: svgOptions): Promise<string> => new Promise (async (resolve, reject) => {
		// Get args from array
		const { image, bRadius, aRadius, theme, text, svgUrl } = options;
		const { buffer, mimetype } = image;
		const { bgColour, textColour, accentColour } = theme;
		const { artist, album, title } = htmlEncode(text);
		const width: number = 412;
		const height: number = 128;

		if (svgUrl) {	
			let svgImg = await fetch(svgUrl).then(res => res.text());
			
			// Replace text in svg
			svgImg = svgImg
				.replace(/\$\{artist\}/g, artist)
				.replace(/\$\{album\}/g, album)
				.replace(/\$\{title\}/g, title)
				.replace(/\$\{image}/g, `data:${mimetype};base64,${buffer.toString('base64')}`);
			
			// Resolve svg
			resolve(svgImg);
		}
		else { resolve(`<svg xmlns="http://www.w3.org/2000/svg" xmlns:xhtml="http://www.w3.org/1999/xhtml" width="${ width }" height="${ height }"><foreignObject width="${ width }" height="${ height }"><style>span { font-family: 'Century Gothic', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; overflow: hidden; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; line-height: 1.5rem; }</style><div xmlns="http://www.w3.org/1999/xhtml" style="display:flex; flex-direction:row; justify-content:flex-start; align-items:center; width:100%; height:100%; border-radius:${ bRadius }px; background-color:${ bgColour }; color:${ textColour }; padding:0 14px; box-sizing:border-box; overflow:clip;"><div style="display:flex; height: fit-content; width: fit-content;"><img src="data:${ mimetype };base64,${buffer.toString('base64')}" alt="Cover art" style="border: 1.6px solid ${ accentColour }; border-radius:${ aRadius }px" width="100px" height="100px" /></div><div style="display:flex; flex-direction:column; padding-left:14px;"><span style="font-size: 20px; font-weight: bold; padding-bottom: 6px; border-bottom: 1.6px solid ${ accentColour };">${ title }</span><span style="font-size:16px; font-weight:normal; margin-top:4px;">${ artist } - ${ album }</span></div></div></foreignObject></svg>`); }
	});
}

export default img;
