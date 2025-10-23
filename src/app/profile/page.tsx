"use client";

import { useAuth } from "@/hooks/use-auth";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import { Trophy, Star, Target } from "lucide-react";
import type { ImagePlaceholder } from "@/lib/placeholder-images";
import placeholderData from '@/lib/placeholder-images.json';

export default function ProfilePage() {
  const { user, loading } = useAuth();
  const router = useRouter();
  const [avatarImage, setAvatarImage] = useState<ImagePlaceholder | undefined>();

  useEffect(() => {
    if (!loading && !user) {
      router.push("/login");
    }
    setAvatarImage(placeholderData.placeholderImages.find(p => p.id === "1"));
  }, [user, loading, router]);

  if (loading || !user) {
    return (
      <div className="container mx-auto py-8">
        <div className="flex flex-col items-center gap-8">
          <Skeleton className="h-32 w-32 rounded-full" />
          <div className="text-center space-y-2">
            <Skeleton className="h-8 w-48" />
            <Skeleton className="h-5 w-64" />
          </div>
          <div className="w-full max-w-md">
            <Skeleton className="h-64 w-full" />
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto py-8">
      <div className="flex flex-col items-center gap-4 text-center">
        <Avatar className="h-32 w-32 border-4 border-primary">
          {avatarImage && <AvatarImage src={avatarImage.imageUrl} alt={user.name} data-ai-hint={avatarImage.imageHint} />}
          <AvatarFallback className="text-4xl">{user.name.charAt(0)}</AvatarFallback>
        </Avatar>
        <div>
          <h1 className="text-4xl font-bold font-headline">{user.name}</h1>
          <p className="text-muted-foreground">{user.email}</p>
        </div>
      </div>
      <Card className="max-w-md mx-auto mt-8">
        <CardHeader>
          <CardTitle>Your Stats</CardTitle>
          <CardDescription>Your Definition Detective journey so far.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between p-3 rounded-lg bg-muted/50">
            <div className="flex items-center gap-3">
              <Trophy className="h-6 w-6 text-primary" />
              <span className="font-medium">Total Score</span>
            </div>
            <Badge variant="secondary" className="text-lg">{user.score.toLocaleString()}</Badge>
          </div>
          <div className="flex items-center justify-between p-3 rounded-lg bg-muted/50">
            <div className="flex items-center gap-3">
              <Star className="h-6 w-6 text-yellow-500" />
              <span className="font-medium">Current Level</span>
            </div>
            <Badge variant="secondary" className="text-lg">{user.level}</Badge>
          </div>
          <div className="flex items-center justify-between p-3 rounded-lg bg-muted/50">
            <div className="flex items-center gap-3">
              <Target className="h-6 w-6 text-green-500" />
              <span className="font-medium">Rank</span>
            </div>
            <Badge variant="secondary" className="text-lg">#1,234</Badge>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
