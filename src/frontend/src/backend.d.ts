import type { Principal } from "@icp-sdk/core/principal";
export interface Some<T> {
    __kind__: "Some";
    value: T;
}
export interface None {
    __kind__: "None";
}
export type Option<T> = Some<T> | None;
export interface ScoreEntry {
    role: string;
    score: bigint;
    timestamp: Time;
    playerName: string;
}
export type Time = bigint;
export interface backendInterface {
    getTopScores(): Promise<Array<ScoreEntry>>;
    submitScore(playerName: string, role: string, score: bigint): Promise<void>;
}
