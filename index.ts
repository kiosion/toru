import express from 'express';
import axios, { AxiosError, AxiosResponse } from 'axios';
import fetch from 'node-fetch'

const app = express();

// type DiscordInfo = {

// }

// type SpotifyInfo = {

// }

// type User = {
// 	id: number;
// 	username: string;
// 	discriminator: string;
// 	avatar: string;
// 	status: string;
// }

async function getUser(userId: string) {
	try {
		// const data: User
		const { data, status } = await axios.get<any>(
			'https://api.lanyard.rest/v1/users/' + userId,
			{
				headers: {
					Accept: 'application/json',
				},
			},
		);
		// for debugging: console.log(JSON.stringify(data, null, 4));
		console.log('request for uid: ' + userId);
		// "response status is: 200"
		console.log('response status is: ', status);

		return data;
	} catch (error) {
		if (axios.isAxiosError(error)) {
			console.log('error message: ', error.message, ' - request url: ', error.config.url);
			return error.message;
		} else {
			console.log('unexpected error: ', error);
			return 'An unexpected error occured';
		}
	}
}

// Root route routes
app.get('/', (req, res) => {
	res.send('Nothing to see here!');
})

// API routes
app.get('/api(/*)?', (req, res) => {
	// set var for current time
	let start = new Date().getTime();
	// Check if the user ID is a number
	if (isNaN(parseInt(req.url.split('/')[2]))) {
		res.status(404).send('User ID NaN or not provided');
		return;
	}
	
	let uid = req.url.split('/')[2].split('?')[0];
	let uid_str = "req: /" + uid;

	// Res w/ some random data for now
	getUser(uid)
		.then(data => {
			console.log('response took: ' + (new Date().getTime() - start) / 1000 + 's');
			switch (req.query['res']) {
				// If 'res=avatar', return only the avatar
				case 'avatar': {
					const url: string = 'https://cdn.discordapp.com/avatars/'+ uid + '/' + data.data.discord_user.avatar + '.webp';
					fetch(url).then((actual) => {
						actual.headers.forEach((v, n) => res.setHeader(n, v));
						actual.body?.pipe(res);
					});
					break;
				}
				case 'spotify-art': {
					if (data.data.listening_to_spotify) {
						const url: string = data.data.spotify.album_art_url;
						fetch(url).then((actual) => {
							actual.headers.forEach((v, n) => res.setHeader(n, v));
							actual.body?.pipe(res);
						});
					}
					else res.send(
						'<h1>' + uid_str + '</h1>' +
						'<p>Error: no spotify activity</p>'
					);
					break;
				}
				default: {
					res.send(
						`<h1>${uid_str}, ${req.query['res']}, ${req.hostname}</h1>` +
						'<img src="https://cdn.discordapp.com/avatars/'+ uid + '/' + data.data.discord_user.avatar + '.webp" alt="User profile picture" />' +
						'<p>res: </p>' +
						'<pre>' + JSON.stringify(data, null, 4) + '</pre>'
					);
					break;
				}
			}
		})
		.catch(error => {
			res.send(
				'<h1>' + uid_str + '</h1>' +
				'<p>Error: ' + error + '</p>'
				);
		});
});

// Listen on port 3000
app.listen(3000, () => {
	console.log('Server is listening on port 3000');
})
