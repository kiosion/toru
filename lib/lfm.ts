import axios, { AxiosError, AxiosResponse } from 'axios';
import dotenv from 'dotenv';
import img from './img';

dotenv.config();

const apiKey = process.env.LFM_API_KEY;
const sharedSecret = process.env.LFM_SHARED_SECRET;

module lfm {
	export async function getActivity(username: string): Promise<any> {
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
}

export default lfm;
