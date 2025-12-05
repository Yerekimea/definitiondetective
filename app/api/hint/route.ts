import { NextResponse } from 'next/server';
import { getSmartHint as getSmartHintFlow } from '../../../src/ai/flows/smart-word-hints';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { word, incorrectGuesses, lettersToReveal } = body;
    const input = {
      word,
      incorrectGuesses: (incorrectGuesses || []).join(''),
      lettersToReveal: lettersToReveal || 0,
    };
    const result = await getSmartHintFlow(input);
    if (!result || !result.hint) {
      return NextResponse.json({ hint: null, error: 'Invalid hint response from AI.' }, { status: 500 });
    }
    return NextResponse.json({ hint: result.hint, error: null });
  } catch (err) {
    console.error('Error in /api/hint:', err);
    return NextResponse.json({ hint: null, error: 'Failed to get a hint.' }, { status: 500 });
  }
}
