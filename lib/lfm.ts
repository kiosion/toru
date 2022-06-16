import axios, { 
  AxiosError, 
  AxiosResponse 
} from 'axios';
import dotenv from 'dotenv';

dotenv.config();

module lfm {
  export const getJson = (username: string): Promise<any> => new Promise((resolve, reject) => {
    console.log('Request for username: ' + username);
    axios.get<any>(
      `http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=${username}&api_key=${process.env.LFM_API_KEY}&format=json`,
      {
        headers: {
          Accept: 'application/json',
        },
      },
    )
    .then((response: AxiosResponse) => {
      console.log('\t->lfm res status is: ', response.status);
      response.status !== 200 && reject(new Error('Request failed with status: ' + response.status));
      resolve(response.data);
    })
    .catch((error: AxiosError) => {
      reject(new Error(error.message));
    });
  });
}

export default lfm;
