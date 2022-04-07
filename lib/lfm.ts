import axios, { AxiosError, AxiosResponse } from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const apiKey = process.env.LFM_API_KEY;
const sharedSecret = process.env.LFM_SHARED_SECRET;

module lfm {
	export const getJson = (username: string): Promise<any> => new Promise((resolve, reject) => {
		console.log('request for username: ' + username);
		axios.get<any>(
			`http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=${username}&api_key=${apiKey}&format=json`,
			{
				headers: {
					Accept: 'application/json',
				},
			},
		)
		.then((response: AxiosResponse) => {
			console.log('\t->lfm res status is: ', response.status);
			if (response.status !== 200) reject(new Error('Res status is not 200'));
			resolve(response.data);
		})
		.catch((error: AxiosError) => {
			reject(new Error(error.message));
		});
	});
}

export default lfm;
