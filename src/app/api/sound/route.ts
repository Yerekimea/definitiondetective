import { NextResponse } from 'next/server';
import { getGameSound as getGameSoundFlow } from '@/ai/flows/game-sounds-flow';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { sound } = body;
    const result = await getGameSoundFlow(sound);
    if (!result || !result.soundDataUri) {
      return NextResponse.json({ soundDataUri: null, error: 'Invalid sound response from AI.' }, { status: 500 });
    }
    return NextResponse.json({ soundDataUri: result.soundDataUri, error: null });
  } catch (err) {
    console.error('Error in /api/sound:', err);
    return NextResponse.json({ soundDataUri: null, error: 'Failed to get sound.' }, { status: 500 });
  }
}
