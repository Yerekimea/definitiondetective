import { NextResponse } from 'next/server';
import { getGameSound as getGameSoundFlow, getGameSoundSafe } from '@/ai/flows/game-sounds-flow';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { sound } = body;
    // Prefer the safe wrapper which includes caching and static fallbacks.
    const result = typeof getGameSoundSafe === 'function'
      ? await getGameSoundSafe(sound)
      : await getGameSoundFlow(sound);

    if (!result || !result.soundDataUri) {
      // Avoid leaking internal details in production responses.
      const isProd = process.env.NODE_ENV === 'production';
      return NextResponse.json({ soundDataUri: null, error: 'Invalid sound response from AI.' }, { status: 500 });
    }
    return NextResponse.json({ soundDataUri: result.soundDataUri, error: null });
  } catch (err) {
    console.error('Error in /api/sound:', err);
    // Don't include detailed error messages in production responses.
    return NextResponse.json({ soundDataUri: null, error: 'Failed to get sound.' }, { status: 500 });
  }
}
