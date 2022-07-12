import 'module-alias/register';
import express from 'express';
import fetch from 'node-fetch';
import {
  img,
  get,
  lfm
} from '@libs';
import {
  DEFAULT_BORDER_RADIUS,
  DEFAULT_COVER__RADIUS,
  DEFAULT_SVG_THEME
} from '@consts';
import {
  imgObj,
  svgTheme,
  svgText
} from '@types';

const app = express();

app.get('/api/v1/(*)/?', (req, res) => {
  if ((req.url.split('/')[3].split('/?')[0]) == null || (req.url.split('/')[3].split('/?')[0]) == '') {
    res.status(404).send(
      `<center style="font-family: 'Century Gothic', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;"><h1>Error</h1><p>Username not provided</p></center>`
    );
    return;
  }

  const start = new Date().getTime();
  const uname: string = req.url.split('/')[3].split('?')[0];

  lfm.getJson(uname)
    .then((data: any) => {
      console.log('\t->lfm res took: ' + (new Date().getTime() - start) / 1000 + 's');
      switch (req.query['res']) {
        case 'json': {
          res.set('Content-Type', 'application/json');
          res.set('Age', '0');
          res.set('Cache-Control', 'public, max-age=0, must-revalidate');
          res.send(JSON.stringify(data.recenttracks.track[0], null, 4));
          break;
        }
        case 'cover': {
          try {
            let url: string = data.recenttracks.track[0].image[3]['#text'];
            if (url == null) throw new Error('Cover art URL not found');
            fetch(url)
              .then((actual) => {
                actual.headers.forEach((v, n) => res.setHeader(n, v));
                res.set('Age', '0');
                res.set('Cache-Control', 'public, max-age=0, must-revalidate');
                actual.body?.pipe(res);
              });
          } 
          catch (e: any) {
            res.status(500).send('' + e);
          }
          break;
        }
        case 'embed':
        default: {
          if (typeof data.recenttracks.track[0].album['#text'] == 'undefined') throw new Error('Album name not found');
          if (typeof data.recenttracks.track[0].image[2]['#text'] == 'undefined') throw new Error('Cover art URL not found');

          const bRadius: number = parseInt(req.query?.borderRadius?.toString() || DEFAULT_BORDER_RADIUS);
          const aRadius: number = parseInt(req.query?.coverRadius?.toString() || DEFAULT_COVER__RADIUS);
          const coverUrl = get.art(
            data.recenttracks.track[0].album['#text'],
            data.recenttracks.track[0].image[2]['#text']
          );
          const svgTheme: svgTheme = get.theme(req.query.theme?.toString() || DEFAULT_SVG_THEME);
          const svgText: svgText = {
            artist: data.recenttracks.track[0].artist['#text'],
            album: data.recenttracks.track[0].album['#text'],
            title: data.recenttracks.track[0].name
          };
          let svgUrl: URL | string | null = req.query.url?.toString() || null;
          if (svgUrl) try { svgUrl = new URL(svgUrl); } catch { svgUrl = null; }
          const isPlaying: boolean = data.recenttracks.track?.[0]?.['@attr']?.nowplaying === 'true';

          img.get(coverUrl)
            .then((response: imgObj) => {
              img.process({
                image: response,
                bRadius: bRadius,
                aRadius: aRadius,
                theme: svgTheme,
                text: svgText,
                svgUrl: svgUrl,
                isPlaying
              })
                .then((svg: string) => {
                  res.format({
                    'image/svg+xml': () => {
                      res.set('Age', '0');
                      res.set('Cache-Control', 'public, max-age=0, must-revalidate');
                      res.send(svg);
                    }
                  });
                });
            })
            .catch((e: any) => {
              res.status(500).send('' + e);
            });
        }
        break;
      }
    })
    .catch((e: any) => {
      res.status(500).send('' + e);
    });
});

app.get('/*', (req, res) => {
  res.send(
    `<center style="font-family:'Century Gothic',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;"><h1>Error</h1><p>Cannot GET ${req.url}</p></center>`
  );
});

app.listen(3000, () => {
  console.log('Server is running on port 3000');
});
