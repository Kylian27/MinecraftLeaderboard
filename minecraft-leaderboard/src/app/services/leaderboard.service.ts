import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Player {
  rank: number;
  username: string;
  blocksBroken: number;
}

@Injectable({
  providedIn: 'root'
})
export class LeaderboardService {
  // L'URL de ton API Flask locale
  private apiUrl = 'http://localhost:5000/api/leaderboard';

  constructor(private http: HttpClient) { }

  getLeaderboard(): Observable<Player[]> {
    return this.http.get<Player[]>(this.apiUrl);
  }
}