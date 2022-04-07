interface procOptions {
	image: string;
	mimetype: string;
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
	mimetype: string;
}

export { procOptions, imgRes };
