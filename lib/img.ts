import fetch, {
  Response
} from 'node-fetch';
import {
  svgOptions,
  imgObj,
  svgText
} from '@types';

module img {
  export const get = (url: string): Promise<imgObj> => new Promise (async (resolve, reject) => {
    const response = await fetch(url);
    const arrayBuffer = await response.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    const mimetype = response.headers.get('content-type') || 'image/jpg';
    resolve({buffer, mimetype});
  });

  const htmlEncode = (text: svgText): svgText => {
    return {
      artist: text.artist.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;'),
      album: text.album.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;'),
      title: text.title.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;'),
    }
  }

  export const process = (options: svgOptions): Promise<string> => new Promise (async (resolve, reject) => {
    const { image, bRadius, aRadius, theme, text, svgUrl } = options;
    const { buffer, mimetype } = image;
    const { bgColour, textColour, accentColour } = theme;
    const { artist, album, title } = htmlEncode(text);
    const width = 412;
    const height = 128;

    svgUrl
      ? resolve(
        await fetch(svgUrl)
          .then(async (res: Response) => {
            if (res.status != 200) throw new Error(`${res.status} - Resource not found`);
            if (res.headers.get('content-type') !== 'image/svg+xml') throw new Error('Resource provided not an SVG');
            return (await res.text())
              .replace(/\$\{artist\}/g, artist)
              .replace(/\$\{album\}/g, album)
              .replace(/\$\{title\}/g, title)
              .replace(/\$\{image}/g, `data:${mimetype};base64,${buffer.toString('base64')}`);
          }).catch((e: any) => { return `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xhtml="http://www.w3.org/1999/xhtml" width="${width}" height="${height}"><foreignObject width="${width}" height="${height}"><div xmlns="http://www.w3.org/1999/xhtml" style="display:flex; flex-direction:row; justify-content:center; align-items:center; width:100%; height:100%;"><span style="display:-webkit-box;font-family: 'Century Gothic', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;line-height:1.5rem;color:black">${e}</span></div></foreignObject></svg>`})
        )
      : resolve(`<svg xmlns="http://www.w3.org/2000/svg" xmlns:xhtml="http://www.w3.org/1999/xhtml" width="${width}" height="${height}"><foreignObject width="${width}" height="${height}"><style>.bars{position:relative;display:inline-flex;justify-content:space-between;width:12px;height:12px;margin-right:4px;}.bar{width:2px;height:100%;background-color:${accentColour};border-radius:10000px;transform-origin:bottom;animation:bounce 0.8s ease infinite alternate;contents:'';}.bar:nth-of-type(2){animation-delay:-0.8s;}.bar:nth-of-type(3){animation-delay:-1.2s;}@keyframes bounce{0%{transform:scaleY(0.1);}100%{transform:scaleY(1);}}</style><div xmlns="http://www.w3.org/1999/xhtml" style="display:flex;flex-direction:row;justify-content:flex-start;align-items:center;width:100%;height:100%; border-radius:${bRadius}px;background-color:${bgColour};color:${textColour};padding:0 14px;box-sizing:border-box; overflow:clip;"><div style="display:flex;height:fit-content;width:fit-content;"><img src="data:${mimetype};base64,${buffer.toString('base64')}" alt="Cover" style="border:1.6px solid ${accentColour};border-radius:${aRadius}px; background-color:${accentColour}" width="100px" height="100px"/></div><div style="display:flex;flex-direction:column;padding-left:14px;"><span style="font-family:'Century Gothic',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;overflow:hidden;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;line-height:1.5rem;font-size:20px;font-weight:bold;padding-bottom:6px;border-bottom:1.6px solid ${accentColour};">${title}</span><div style="display:flex;flex-direction:row;justify-content:flex-start;align-items:baseline;width:100%;height:100%;"><span style="font-family:'Century Gothic',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;overflow:hidden;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;line-height:1.5rem;font-size:16px;font-weight:normal;margin-top:4px;"><div class="bars"><span class="bar"/><span class="bar"/><span class="bar"/></div>${artist} - ${album}</span></div></div></div></foreignObject></svg>`);
  });
}

export default img;
