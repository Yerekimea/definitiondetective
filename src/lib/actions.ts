'use server';

import { getSmartHint as getSmartHintFlow, SmartHintInput } from '@/ai/flows/smart-word-hints';
import { getGameSound as getGameSoundFlow, GameSoundInput } from '@/ai/flows/game-sounds-flow';

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

export async function getSoundAction(sound: string) {
    try {
        const input: GameSoundInput = sound;
        const result = await getGameSoundFlow(input);
        if (!result || !result.soundDataUri) {
            throw new Error('Invalid sound response from AI.');
        }
        return { soundDataUri: result.soundDataUri, error: null };
    } catch (error) {
        console.error(`Error getting sound for "${sound}":`, error);
        return { soundDataUri: null, error: `Failed to get sound: ${sound}` };
    }
}
