import Array "mo:core/Array";
import Time "mo:core/Time";
import Order "mo:core/Order";
import List "mo:core/List";
import Runtime "mo:core/Runtime";

actor {
  module ScoreEntry {
    public func compareByScoreDescending(a : ScoreEntry, b : ScoreEntry) : Order.Order {
      Nat.compare(b.score, a.score);
    };
  };

  type ScoreEntry = {
    playerName : Text;
    role : Text; // "escaper" or "hunter"
    score : Nat;
    timestamp : Time.Time;
  };

  let scores = List.empty<ScoreEntry>();

  public shared ({ caller }) func submitScore(playerName : Text, role : Text, score : Nat) : async () {
    if (role != "escaper" and role != "hunter") {
      Runtime.trap("Invalid role. Must be 'escaper' or 'hunter'");
    };

    let scoreEntry : ScoreEntry = {
      playerName;
      role;
      score;
      timestamp = Time.now();
    };

    scores.add(scoreEntry);
  };

  public query ({ caller }) func getTopScores() : async [ScoreEntry] {
    scores.toArray().sort(ScoreEntry.compareByScoreDescending).sliceToArray(0, 10);
  };
};
