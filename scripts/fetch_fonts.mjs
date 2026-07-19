import { writeFileSync, mkdirSync } from 'node:fs';

// A API css2 devolve URLs .ttf estáticos quando o User-Agent não anuncia
// suporte a woff2 (mesmo mecanismo do pacote google_fonts em runtime).
const UA = 'curl/8.0';

async function cssFor(family, weights) {
  const url = `https://fonts.googleapis.com/css2?family=${family}:wght@${weights.join(';')}`;
  const res = await fetch(url, { headers: { 'User-Agent': UA } });
  if (!res.ok) throw new Error(`css2 ${family}: ${res.status}`);
  return res.text();
}

function ttfUrls(css) {
  // blocos: font-weight: NNN; ... src: url(...ttf)
  const out = {};
  const re = /font-weight:\s*(\d+);[^}]*url\((https:[^)]+\.ttf)\)/g;
  for (const m of css.matchAll(re)) out[m[1]] = m[2];
  return out;
}

async function download(url, path) {
  const res = await fetch(url, { headers: { 'User-Agent': UA } });
  if (!res.ok) throw new Error(`${url}: ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  writeFileSync(path, buf);
  console.log(path, buf.length, 'bytes');
}

mkdirSync('app/assets/fonts', { recursive: true });

const nunito = ttfUrls(await cssFor('Nunito', [400, 500, 600, 700]));
const fredoka = ttfUrls(await cssFor('Fredoka', [600, 700]));

const nunitoNames = {
  400: 'Nunito-Regular.ttf',
  500: 'Nunito-Medium.ttf',
  600: 'Nunito-SemiBold.ttf',
  700: 'Nunito-Bold.ttf',
};
for (const [w, name] of Object.entries(nunitoNames)) {
  if (!nunito[w]) throw new Error(`Nunito ${w} não veio no css`);
  await download(nunito[w], `app/assets/fonts/${name}`);
}
const fredokaNames = { 600: 'Fredoka-SemiBold.ttf', 700: 'Fredoka-Bold.ttf' };
for (const [w, name] of Object.entries(fredokaNames)) {
  if (!fredoka[w]) throw new Error(`Fredoka ${w} não veio no css`);
  await download(fredoka[w], `app/assets/fonts/${name}`);
}
