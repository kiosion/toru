interface svgOptions {
  image: imgObj;
  bRadius: number;
  aRadius: number;
  theme: svgTheme;
  text: svgText;
  svgUrl: URL | string | null;
  isPlaying: boolean;
}
interface imgObj {
  buffer: Buffer;
  mimetype: string;
}

interface svgTheme {
  bgColour: string;
  textColour: string; 
  accentColour: string;
}
interface svgText {
  artist: string;
  album: string;
  title: string;
}

export { svgOptions, imgObj, svgTheme, svgText };
