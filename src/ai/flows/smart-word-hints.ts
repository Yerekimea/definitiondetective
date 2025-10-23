'use server';

/**
 * @fileOverview This file defines a Genkit flow for providing smart word hints based on previous incorrect guesses.
 *
 * The flow uses an LLM to determine the most helpful letters to reveal in a word puzzle hint, considering the letters the player has already tried.
 *
 * - `getSmartHint` - A function that takes the word, incorrect guesses and the number of letters to reveal as input and returns a smart hint.
 * - `SmartHintInput` - The input type for the `getSmartHint` function.
 * - `SmartHintOutput` - The return type for the `getSmartHint` function.
 */

import {ai} from '@/ai/genkit';
import {z} from 'genkit';

const SmartHintInputSchema = z.object({
  word: z.string().describe('The word to provide a hint for.'),
  incorrectGuesses: z.string().describe('The letters the player has already guessed incorrectly.'),
  lettersToReveal: z.number().describe('The number of letters to reveal in the hint.'),
});
export type SmartHintInput = z.infer<typeof SmartHintInputSchema>;

const SmartHintOutputSchema = z.object({
  hint: z.string().describe('The smart hint, with revealed letters and underscores for the rest.'),
});
export type SmartHintOutput = z.infer<typeof SmartHintOutputSchema>;

export async function getSmartHint(input: SmartHintInput): Promise<SmartHintOutput> {
  return smartHintFlow(input);
}

const smartHintPrompt = ai.definePrompt({
  name: 'smartHintPrompt',
  input: {schema: SmartHintInputSchema},
  output: {schema: SmartHintOutputSchema},
  prompt: `You are an AI assistant designed to provide smart hints for word puzzles.

The word to provide a hint for is: {{{word}}}
The letters the player has already guessed incorrectly are: {{{incorrectGuesses}}}
The number of letters to reveal in the hint is: {{{lettersToReveal}}}

Considering the word and the incorrect guesses, determine the most helpful letters to reveal to the player.

Return a hint where the revealed letters are shown and the rest of the letters are represented by underscores.
For example, if the word is "example", incorrect guesses are "xyz", and letters to reveal is 2, the hint should be "e_a__p_e".

Make sure to NOT reveal any letters which are part of incorrect guesses.

Hint:`,
});

const smartHintFlow = ai.defineFlow(
  {
    name: 'smartHintFlow',
    inputSchema: SmartHintInputSchema,
    outputSchema: SmartHintOutputSchema,
  },
  async input => {
    const {output} = await smartHintPrompt(input);
    return {
      hint: output?.hint ?? '',
    };
  }
);
