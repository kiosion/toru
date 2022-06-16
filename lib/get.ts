import { svgTheme } from '../types';

module get {
  export const art = (album: string, url: string): string => {
    switch (album) {
      case 'L’enfer':
        return 'https://cdn.kio.dev/file/lenfer.jpg';
      case 'Santé':
        return 'https://cdn.kio.dev/file/sante.jpg';
      case 'Multitude':
        return 'https://cdn.kio.dev/file/multitude.jpg';
      case 'Racine carrée (Standard US Version)':
        return 'https://cdn.kio.dev/file/racinecarree.jpg';
      case 'Lil Black Heart':
        return 'https://cdn.kio.dev/file/lilblackheart.jpg';
      default:
        return url;
    }
  }

  export const theme = (theme: string): svgTheme => {
    switch (theme) {
      case 'nord':
        return { bgColour: '#2E3440', textColour: '#ECEFF4', accentColour: '#81A1C1' };
      case 'dracula':
        return { bgColour: '#282A36', textColour: '#F8F8F2', accentColour: '#6272A4' };
      case 'solarized':
        return { bgColour: '#FDF6E3', textColour: '#657B83', accentColour: '#839496' };
      case 'shoji':
        return { bgColour: '#E8E8E3', textColour: '#4D4D4D', accentColour: '#4D4D4D' };
      case 'dark':
        return { bgColour: '#1A1A1A', textColour: '#E6E6E6', accentColour: '#CCCCCC' };
      case 'light':
      default:
        return { bgColour: '#F2F2F2', textColour: '#1A1A1A', accentColour: '#8C8C8C' };
    }
  }
}

export default get;
