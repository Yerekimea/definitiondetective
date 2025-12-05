'use server';
/**
 * @fileOverview Generates game sound effects using Text-to-Speech.
 *
 * - getGameSound - A function that generates a sound effect.
 * - GameSoundInput - The input type for the getGameSound function.
 * - GameSoundOutput - The return type for the getGameSound function.
 */

import {ai} from '@/ai/genkit';
import {z} from 'genkit';
import wav from 'wav';
import {googleAI} from '@genkit-ai/google-genai';
import getStaticSound from '@/lib/static-sounds';

const GameSoundInputSchema = z
  .string()
  .describe(
    'The text to convert to a sound effect (e.g., "ding", "buzz", "level up").'
  );
export type GameSoundInput = z.infer<typeof GameSoundInputSchema>;

const GameSoundOutputSchema = z.object({
  soundDataUri: z.string().describe('The generated sound as a base64 data URI.'),
});
export type GameSoundOutput = z.infer<typeof GameSoundOutputSchema>;

export async function getGameSound(
  input: GameSoundInput
): Promise<GameSoundOutput> {
  return gameSoundFlow(input);
}

// Simple in-memory cache to avoid repeated calls to the TTS for the same
// input during the dev session. Keyed by the input string.
const cache = new Map<string, { soundDataUri: string; ts: number }>();
const CACHE_TTL_MS = 1000 * 60 * 60; // 1 hour

async function sleep(ms: number) {
  return new Promise((res) => setTimeout(res, ms));
}

async function fetchWithRetries(query: string, maxAttempts = 3) {
  let attempt = 0;
  let lastErr: any = null;
  while (attempt < maxAttempts) {
    try {
      const result = await ai.generate({
        model: googleAI.model('gemini-2.5-flash-preview-tts'),
        config: {
          responseModalities: ['AUDIO'],
          speechConfig: {
            voiceConfig: {
              prebuiltVoiceConfig: { voiceName: 'Algenib' },
            },
          },
        },
        prompt: query,
      });
      return result;
    } catch (err: any) {
      lastErr = err;
      // On 429 or transient network errors, wait and retry with backoff.
      const retryAfter = 2 ** attempt * 500;
      await sleep(retryAfter);
      attempt += 1;
    }
  }
  throw lastErr;
}

async function toWav(
  pcmData: Buffer,
  channels = 1,
  rate = 24000,
  sampleWidth = 2
): Promise<string> {
  return new Promise((resolve, reject) => {
    const writer = new wav.Writer({
      channels,
      sampleRate: rate,
      bitDepth: sampleWidth * 8,
    });

    const bufs: Buffer[] = [];
    writer.on('error', reject);
    writer.on('data', function (d) {
      bufs.push(d);
    });
    writer.on('end', function () {
      resolve(Buffer.concat(bufs).toString('base64'));
    });

    writer.write(pcmData);
    writer.end();
  });
}

const gameSoundFlow = ai.defineFlow(
  {
    name: 'gameSoundFlow',
    inputSchema: GameSoundInputSchema,
    outputSchema: GameSoundOutputSchema,
  },
  async query => {
      const { media } = await fetchWithRetries(query);
      if (!media) {
        throw new Error('no media returned');
      }
      const audioBuffer = Buffer.from(media.url.substring(media.url.indexOf(',') + 1), 'base64');
      const wavBase64 = await toWav(audioBuffer);
      return {
        soundDataUri: 'data:audio/wav;base64,' + wavBase64,
      };
  }
);
  // Wrap the exported helper so callers can get a fallback on errors. Uses a
  // simple in-memory cache and static assets mapping as fallback.
  export async function getGameSoundSafe(input: GameSoundInput): Promise<GameSoundOutput> {
    try {
      // use cache
      const now = Date.now();
      const cached = cache.get(input);
      if (cached && now - cached.ts < CACHE_TTL_MS) {
        return { soundDataUri: cached.soundDataUri };
      }

      const result = await gameSoundFlow(input);
      if (result && result.soundDataUri) {
        cache.set(input, { soundDataUri: result.soundDataUri, ts: Date.now() });
        return result;
      }
      throw new Error('Invalid result from gameSoundFlow');
    } catch (err) {
        console.error('gameSoundFlow failed, using static fallback. Reason:', err);
        // Try to return a static data URI mapped for this input key.
        const key = (String(input) || 'correct') as string;
        const staticUri = await getStaticSound(key);
        // store in cache so future calls are cheap.
        cache.set(key, { soundDataUri: staticUri, ts: Date.now() });
        return { soundDataUri: staticUri };
    }
  }
