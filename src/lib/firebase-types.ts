export type UserProfile = {
    id: string;
    username: string;
    email: string;
    totalScore: number;
    highestLevel: number;
    createdAt: string;
    updatedAt: string;
};

export type GameSession = {
    id: string;
    userProfileId: string;
    score: number;
    difficulty: string;
    seed: string;
    startTime: string;
    endTime: string;
};
