import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Trophy } from "lucide-react";
import { Badge } from "@/components/ui/badge";

const leaderboardData = [
  { rank: 1, player: "Cipher", score: 15200, level: 42, avatar: "https://picsum.photos/seed/leader1/40/40", hint: "person smiling" },
  { rank: 2, player: "Lexi", score: 14850, level: 41, avatar: "https://picsum.photos/seed/leader2/40/40", hint: "woman programmer" },
  { rank: 3, player: "Riddle", score: 13500, level: 38, avatar: "https://picsum.photos/seed/leader3/40/40", hint: "man thinking" },
  { rank: 4, player: "Alex Doe", score: 1250, level: 15, avatar: "https://picsum.photos/seed/avatar1/40/40", hint: "profile picture", isCurrentUser: true },
  { rank: 5, player: "ClueMaster", score: 11900, level: 35, avatar: "https://picsum.photos/seed/leader4/40/40", hint: "woman glasses" },
  { rank: 6, player: "Sherlock", score: 10500, level: 32, avatar: "https://picsum.photos/seed/leader5/40/40", hint: "detective hat" },
  { rank: 7, player: "The Oracle", score: 9800, level: 30, avatar: "https://picsum.photos/seed/leader6/40/40", hint: "wise person" },
];

export default function LeaderboardPage() {
  return (
    <div className="container mx-auto py-8">
      <div className="text-center mb-8">
        <Trophy className="mx-auto h-12 w-12 text-primary" />
        <h1 className="text-4xl font-bold mt-2 font-headline">Leaderboard</h1>
        <p className="text-muted-foreground mt-2">See who's at the top of their game.</p>
      </div>
      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[80px] text-center">Rank</TableHead>
                <TableHead>Player</TableHead>
                <TableHead className="text-right">Score</TableHead>
                <TableHead className="w-[100px] text-right">Level</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {leaderboardData.map((entry) => (
                <TableRow key={entry.rank} className={entry.isCurrentUser ? "bg-primary/10" : ""}>
                  <TableCell className="font-medium text-center text-lg">
                    {entry.rank === 1 ? '🏆' : entry.rank === 2 ? '🥈' : entry.rank === 3 ? '🥉' : entry.rank}
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-3">
                      <Avatar className="h-9 w-9">
                        <AvatarImage src={entry.avatar} alt={entry.player} data-ai-hint={entry.hint} />
                        <AvatarFallback>{entry.player.charAt(0)}</AvatarFallback>
                      </Avatar>
                      <span className="font-medium">{entry.player} {entry.isCurrentUser && "(You)"}</span>
                    </div>
                  </TableCell>
                  <TableCell className="text-right font-mono">{entry.score.toLocaleString()}</TableCell>
                  <TableCell className="text-right">
                    <Badge variant="secondary">{entry.level}</Badge>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
