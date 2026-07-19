import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';

function firstDataUri(svgPath, mime) {
  const svg = readFileSync(svgPath, 'utf8');
  const re = new RegExp(`data:image/${mime};base64,([A-Za-z0-9+/=]+)`);
  const m = svg.match(re);
  if (!m) throw new Error(`no ${mime} in ${svgPath}`);
  return Buffer.from(m[1], 'base64');
}

mkdirSync('app/assets/textures', { recursive: true });
mkdirSync('app/assets/img', { recursive: true });

const jpg = firstDataUri('engine/lib/src/spalsh screenM.svg', 'jpeg');
writeFileSync('app/assets/textures/paper.jpg', jpg);
console.log('paper.jpg', jpg.length, 'bytes');

const png = firstDataUri('engine/lib/src/Login M.svg', 'png');
writeFileSync('app/assets/img/google_g.png', png);
console.log('google_g.png', png.length, 'bytes');
