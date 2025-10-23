"use client";

import { useState, useEffect, useCallback, useMemo, useTransition } from "react";
import { wordList, WordData, getWordByDifficulty, scrambleDefinition } from "@/lib/game-data";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Keyboard } from "@/components/game/keyboard";
import { Lightbulb, RotateCw, CheckCircle, XCircle, Award, PartyPopper } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { getHintAction } from "@/lib/actions";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { cn } from "@/lib/utils";

type GameState = "difficulty-select" | "playing" | "won" | "lost";
type Difficulty = "easy" | "medium" | "hard";
const MAX_INCORRECT_TRIES = 6;

export default function GameClient() {
  const [gameState, setGameState] = useState<GameState>("difficulty-select");
  const [difficulty, setDifficulty] = useState<Difficulty | null>(null);
  const [wordData, setWordData] = useState<WordData | null>(null);
  const [scrambledDef, setScrambledDef] = useState<string>("");
  const [guessedLetters, setGuessedLetters] = useState<{ correct: string[]; incorrect: string[] }>({ correct: [], incorrect: [] });
  const [hint, setHint] = useState<string | null>(null);
  const [score, setScore] = useState(0);
  const [level, setLevel] = useState(1);
  const [isHintLoading, startHintTransition] = useTransition();

  const { toast } = useToast();

  const startNewGame = useCallback((diff: Difficulty) => {
    const newWordData = getWordByDifficulty(diff);
    setDifficulty(diff);
    setWordData(newWordData);
    setScrambledDef(scrambleDefinition(newWordData.definition));
    setGuessedLetters({ correct: [], incorrect: [] });
    setHint(null);
    setGameState("playing");
  }, []);

  const handleGuess = useCallback((letter: string) => {
    if (gameState !== "playing" || guessedLetters.correct.includes(letter) || guessedLetters.incorrect.includes(letter)) {
      return;
    }

    const lowerLetter = letter.toLowerCase();
    if (wordData?.word.toLowerCase().includes(lowerLetter)) {
      setGuessedLetters(prev => ({ ...prev, correct: [...prev.correct, lowerLetter] }));
    } else {
      setGuessedLetters(prev => ({ ...prev, incorrect: [...prev.incorrect, lowerLetter] }));
    }
  }, [wordData, gameState, guessedLetters]);

  const handleHintRequest = () => {
    if (!wordData) return;
    startHintTransition(async () => {
      const { hint: newHint, error } = await getHintAction({
        word: wordData.word,
        incorrectGuesses: guessedLetters.incorrect,
      });

      if (error) {
        toast({
          variant: "destructive",
          title: "Hint Error",
          description: error,
        });
      } else if (newHint) {
        setHint(newHint);
        setScore(s => Math.max(0, s - 5)); // Penalty for using hint
      }
    });
  };

  const displayedWord = useMemo(() => {
    if (!wordData) return [];
    const wordChars = wordData.word.split('');
    return wordChars.map((char) => {
      const lowerChar = char.toLowerCase();
      const isGuessed = guessedLetters.correct.includes(lowerChar);
      const isHinted = hint?.split('')[wordChars.indexOf(char)]?.toLowerCase() === lowerChar;
      if (isGuessed || isHinted) {
        return { char, revealed: true };
      }
      return { char, revealed: false };
    });
  }, [wordData, guessedLetters.correct, hint]);

  useEffect(() => {
    if (!wordData) return;
    const isWon = wordData.word.split('').every(char => guessedLetters.correct.includes(char.toLowerCase()));
    if (isWon) {
      setGameState("won");
      setScore(s => s + (difficulty === 'easy' ? 10 : difficulty === 'medium' ? 20 : 30));
      setLevel(l => l + 1);
    } else if (guessedLetters.incorrect.length >= MAX_INCORRECT_TRIES) {
      setGameState("lost");
    }
  }, [guessedLetters, wordData, difficulty]);


  if (gameState === "difficulty-select") {
    return (
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>Choose Your Difficulty</CardTitle>
          <CardDescription>The challenge awaits, detective.</CardDescription>
        </CardHeader>
        <CardContent className="flex justify-center gap-4">
          <Button onClick={() => startNewGame("easy")} variant="outline">Easy</Button>
          <Button onClick={() => startNewGame("medium")}>Medium</Button>
          <Button onClick={() => startNewGame("hard")} variant="destructive">Hard</Button>
        </CardContent>
      </Card>
    );
  }

  const incorrectTriesLeft = MAX_INCORRECT_TRIES - guessedLetters.incorrect.length;

  return (
    <div className="w-full max-w-4xl mx-auto space-y-8">
      <div className="flex justify-between items-center">
        <div className="flex items-center gap-2 text-lg">
          <Award className="h-6 w-6 text-primary" />
          Score: <span className="font-bold">{score}</span>
        </div>
        <div className="flex items-center gap-2 text-lg">
          Level: <span className="font-bold">{level}</span>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-center">Unscramble the Definition</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-center text-lg italic text-muted-foreground p-4 bg-muted/50 rounded-md">{scrambledDef}</p>
        </CardContent>
      </Card>

      <div className="flex justify-center items-center gap-2 md:gap-4 my-8">
        {displayedWord.map(({ char, revealed }, index) => (
          <div key={index} className="flex items-center justify-center h-12 w-12 md:h-16 md:w-16 border-b-4 border-primary text-3xl md:text-4xl font-bold uppercase bg-muted/30 rounded-md">
            {revealed && <span className="animate-in fade-in zoom-in-50 duration-500">{char}</span>}
          </div>
        ))}
      </div>
      
      {(gameState === "won" || gameState === "lost") ? (
        <Alert variant={gameState === 'won' ? 'default' : 'destructive'} className="text-center">
           {gameState === 'won' ? <CheckCircle className="h-4 w-4" /> : <XCircle className="h-4 w-4" />}
          <AlertTitle className="text-2xl font-bold">
            {gameState === 'won' ? "You solved it!" : "Case closed... incorrectly."}
          </AlertTitle>
          <AlertDescription>
            {gameState === 'won' ? `The word was "${wordData?.word}". Excellent work, detective!` : `The word was "${wordData?.word}". Better luck next time.`}
          </AlertDescription>
          <div className="mt-4 flex justify-center gap-4">
            <Button onClick={() => difficulty && startNewGame(difficulty)}>
              <RotateCw className="mr-2 h-4 w-4" /> Next Case
            </Button>
            <Button variant="outline" onClick={() => setGameState('difficulty-select')}>Change Difficulty</Button>
          </div>
        </Alert>
      ) : (
        <>
          <div className="flex justify-center">
            <Button onClick={handleHintRequest} disabled={isHintLoading}>
              <Lightbulb className={cn("mr-2 h-4 w-4", isHintLoading && "animate-spin")} />
              {isHintLoading ? 'Getting Hint...' : 'Get a Hint (-5 score)'}
            </Button>
          </div>
          <p className="text-center text-muted-foreground">Incorrect Guesses: {guessedLetters.incorrect.join(', ').toUpperCase()} ({incorrectTriesLeft} left)</p>
          <Keyboard onKeyClick={handleGuess} guessedLetters={guessedLetters} />
        </>
      )}
    </div>
  );
}
