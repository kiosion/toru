interface procOptions {
	image: string;
	buffer: Buffer;
	mimetype: string;
	bgBlur: boolean;
	isPaused: boolean;
	bRadius: number;
	aRadius: number;
	bgColour: string;
	textColour: string;
	accentColour: string;
	tr_title: string;
	tr_artist: string;
	tr_album: string;
}
interface imgRes {
	image: string;
	buffer: Buffer;
	mimetype: string;
}

export { procOptions, imgRes };
