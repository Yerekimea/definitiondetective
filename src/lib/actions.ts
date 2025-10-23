'use server';

import { getSmartHint as getSmartHintFlow, SmartHintInput } from '@/ai/flows/smart-word-hints';

export async function getHintAction(data: {
  word: string;
  incorrectGuesses: string[];
}) {
  try {
    const input: SmartHintInput = {
      word: data.word,
      incorrectGuesses: data.incorrectGuesses.join(''),
      lettersToReveal: 2, 
    };
    const result = await getSmartHintFlow(input);
    if (!result || !result.hint) {
        throw new Error("Invalid hint response from AI.");
    }
    return { hint: result.hint, error: null };
  } catch (error) {
    console.error("Error getting hint:", error);
    return { hint: null, error: 'Failed to get a hint. Please try again.' };
  }
}
