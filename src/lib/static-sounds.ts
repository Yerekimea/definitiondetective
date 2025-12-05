import wav from 'wav';

// Small helper to synthesize a short beep as a WAV base64 data URI.
export async function synthBeepDataUri(durationMs = 160, freq = 880, rate = 24000) {
  const samples = Math.floor((durationMs / 1000) * rate);
  const pcm = Buffer.alloc(samples * 2);
  for (let i = 0; i < samples; i++) {
    const t = i / rate;
    const v = Math.sin(2 * Math.PI * freq * t) * 0.5;
    const int = Math.max(-1, Math.min(1, v));
    const sample = Math.floor(int * 32767);
    pcm.writeInt16LE(sample, i * 2);
  }

  // Reuse small toWav logic inline to avoid depending on flows implementation.
  const wavBase64 = await new Promise<string>((resolve, reject) => {
    const writer = new wav.Writer({ channels: 1, sampleRate: rate, bitDepth: 16 });
    const bufs: Buffer[] = [];
    writer.on('error', reject);
    writer.on('data', (d: Buffer) => bufs.push(d));
    writer.on('end', () => resolve(Buffer.concat(bufs).toString('base64')));
    writer.write(pcm);
    writer.end();
  });

  return 'data:audio/wav;base64,' + wavBase64;
}

// Public helper to get a small static sound by key. Returns a data URI.
export async function getStaticSound(key: string) {
  switch ((key || '').toLowerCase()) {
    case 'incorrect':
      return await synthBeepDataUri(120, 520);
    case 'win':
      return await synthBeepDataUri(220, 1200);
    case 'correct':
    default:
      return await synthBeepDataUri(160, 880);
  }
}

export default getStaticSound;
