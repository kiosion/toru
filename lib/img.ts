import fs, { unlink } from 'fs';
import imagemagick from 'imagemagick';
import sharp from 'sharp';
import fetch from 'node-fetch';

import * as defaults from '../lib/constants';

module img {

	export async function save(url: string, name: string, returnType: string): Promise<string> {
		try {
			const filePath = defaults.default.tmpPath + name;
			// Download image
			await fetch(url)
				.then((actual) => {
					// Create the file
					new Promise((resolve, reject) => {
						actual.body.pipe(fs.createWriteStream(filePath));
						actual.body
							.on('finish', () => {
								resolve(filePath);
							})
							.on('error', (error) => {
								reject(error);
							})
					});
				})
				.catch((error) => {
					console.log('error: ', error);
				});
			switch (returnType) {
				case 'stream': {
					return Buffer.from(filePath).toString('base64');
				}
				break;
				case 'path':
				default: {
					return filePath;
				}
				break;
			}
		}
		catch (error) {
			console.log('\t->error message: ', error);
			return 'An unexpected error occured';
		}
	}

	export function removeTemp(file1: string, file2: string): boolean {
		// After res, delete album art
		try {
			fs.unlink(file1, (err) => {
				if (err) throw err;
			});
			fs.unlink(file2, (err) => {
				if (err) throw err;
			});
			return true;
		}
		catch (error) {
			console.log('\t->error message: ', error);
			return false;
		}
	}

	export async function getMeta(path: string): Promise<any> {
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

	export async function process(inpPath: string, radius: number): Promise<string> {
		try {
			const newFileName = inpPath.split('/').pop()?.split('.').shift() + '_proc.png';
			const newFilePath = defaults.default.tmpPath + newFileName;
			const mask: string = defaults.default.tmpPath + 'mask-' + Math.random().toString(36).substring(2, 15) + '.png';
			//const mask = defaults.default.assetsPath + "mask.png";
			if (radius < 1 || radius > 50) radius = 16;
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
						mask,
					], function(err) {
						if (err) {
							reject(err);
						}
						else {
							sharp(inpPath)
								.composite([
									{
										input: mask,
										blend: "dest-in",
										gravity: "center",
									},
								])
								.toFile(newFilePath)
								.then(() => {
									unlink(mask, (err) => {
										if (err) throw err;
									});
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

}

export default img;
