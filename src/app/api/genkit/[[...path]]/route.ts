import { NextResponse } from 'next/server';
import { getSmartHint } from '@/ai/flows/smart-word-hints';
import { getGameSound } from '@/ai/flows/game-sounds-flow';

// API: POST /api/genkit/[[...path]]
// Accepts JSON body: { action: 'smartHint' | 'gameSound', input: any }
// or derives action from the first path segment.

export async function POST(request: Request) {
  try {
    const url = new URL(request.url);
    const segments = url.pathname.split('/').filter(Boolean);
    // `segments` may be like ['api','genkit','smartHint'] if path used.
    const actionFromPath = segments[segments.length - 1];

    const body = await request.json().catch(() => ({}));
    const action = (body.action as string) || actionFromPath || '';

    if (action === 'smartHint' || action === 'smart-hint') {
      const input = body.input || {};
      // Accept either `incorrectGuesses` as string or array; normalize to string
      let incorrect = input.incorrectGuesses ?? '';
      if (Array.isArray(incorrect)) incorrect = incorrect.join('');

      const hintInput = {
        word: input.word ?? '',
        incorrectGuesses: incorrect,
        lettersToReveal: input.lettersToReveal ?? 2,
      };

      const result = await getSmartHint(hintInput as any);
      return NextResponse.json({ success: true, result });
    }

    if (action === 'gameSound' || action === 'game-sound') {
      const input = body.input ?? '';
      const result = await getGameSound(input as any);
      return NextResponse.json({ success: true, result });
    }

    return NextResponse.json({ error: 'Unknown action' }, { status: 400 });
  } catch (err) {
    console.error('Genkit API error', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function GET() {
  return NextResponse.json({ message: 'Genkit API route: POST actions only' });
}
