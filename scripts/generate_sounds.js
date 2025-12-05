const fs = require('fs');
const path = require('path');
const WavEncoder = require('wav').Writer;

function synthWav(filename, durationSec = 0.18, freq = 880, rate = 24000) {
  const samples = Math.floor(durationSec * rate);
  const pcm = Buffer.alloc(samples * 2);
  for (let i = 0; i < samples; i++) {
    const t = i / rate;
    const v = Math.sin(2 * Math.PI * freq * t) * 0.5;
    const sample = Math.floor(v * 32767);
    pcm.writeInt16LE(sample, i * 2);
  }

  const outPath = path.join(process.cwd(), 'public', 'sounds');
  if (!fs.existsSync(outPath)) fs.mkdirSync(outPath, { recursive: true });
  const ws = fs.createWriteStream(path.join(outPath, filename));
  const writer = new WavEncoder({ channels: 1, sampleRate: rate, bitDepth: 16 });
  writer.pipe(ws);
  writer.on('finish', () => console.log('Wrote', filename));
  writer.write(pcm);
  writer.end();
}

synthWav('correct.wav', 0.16, 880);
synthWav('incorrect.wav', 0.12, 520);
synthWav('win.wav', 0.22, 1200);
