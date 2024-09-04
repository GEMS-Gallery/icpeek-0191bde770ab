import Bool "mo:base/Bool";
import Nat "mo:base/Nat";
import Order "mo:base/Order";

import Float "mo:base/Float";
import Int "mo:base/Int";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Char "mo:base/Char";
import Nat32 "mo:base/Nat32";
import Error "mo:base/Error";

actor {
  type OrderbookEntry = {
    price: Float;
    quantity: Float;
  };

  type Orderbook = {
    bids: [OrderbookEntry];
    asks: [OrderbookEntry];
  };

  stable var lastUpdateTime: Int = 0;
  var currentOrderbook: ?Orderbook = null;

  public query func getOrderbook(): async Result.Result<Orderbook, Text> {
    switch (currentOrderbook) {
      case (null) { #err("Orderbook not initialized") };
      case (?orderbook) { #ok(orderbook) };
    }
  };

  public func updateOrderbook(bids: [(Text, Text)], asks: [(Text, Text)]): async Result.Result<(), Text> {
    try {
      let parsedBids = parseOrderbookEntries(bids);
      let parsedAsks = parseOrderbookEntries(asks);
      currentOrderbook := ?{ bids = parsedBids; asks = parsedAsks };
      lastUpdateTime := Time.now();
      #ok()
    } catch (error) {
      #err("Error updating orderbook: " # Error.message(error))
    }
  };

  private func parseOrderbookEntries(entries: [(Text, Text)]) : [OrderbookEntry] {
    Array.map<(Text, Text), OrderbookEntry>(entries, func (entry) {
      {
        price = textToFloat(entry.0);
        quantity = textToFloat(entry.1);
      }
    })
  };

  private func textToFloat(t: Text) : Float {
    let parsed = Text.split(t, #char '.');
    let parts = Iter.toArray(parsed);
    switch (parts.size()) {
      case 0 { 0.0 };
      case 1 {
        let intValue = textToInt(parts[0]);
        Float.fromInt(intValue)
      };
      case 2 {
        let intValue = textToInt(parts[0]);
        let fracValue = textToInt(parts[1]);
        let fracDigits = parts[1].size();
        let fracPart = Float.fromInt(fracValue) / Float.pow(10, Float.fromInt(fracDigits));
        Float.fromInt(intValue) + (if (intValue >= 0) fracPart else -fracPart)
      };
      case _ { 0.0 };
    }
  };

  private func textToInt(t: Text) : Int {
    var int : Int = 0;
    var isNegative = false;
    for (c in t.chars()) {
      if (c == '-') {
        isNegative := true;
      } else if (Char.isDigit(c)) {
        let charValue = Char.toNat32(c);
        let digitValue = Nat32.toNat(charValue - 48);
        int := int * 10 + Int.fromNat(digitValue);
      } else {
        return 0; // Invalid character, return 0
      };
    };
    if (isNegative) -int else int
  };

  public query func getLastUpdateTime(): async Int {
    lastUpdateTime
  };

  public query func getSpread(): async Result.Result<Float, Text> {
    switch (currentOrderbook) {
      case (null) { #err("Orderbook not initialized") };
      case (?orderbook) {
        let lowestAsk = orderbook.asks[0].price;
        let highestBid = orderbook.bids[0].price;
        #ok(lowestAsk - highestBid)
      };
    }
  };

  public query func getTotalVolume(): async Result.Result<Float, Text> {
    switch (currentOrderbook) {
      case (null) { #err("Orderbook not initialized") };
      case (?orderbook) {
        let bidVolume = Array.foldLeft<OrderbookEntry, Float>(orderbook.bids, 0, func(acc, entry) { acc + entry.quantity });
        let askVolume = Array.foldLeft<OrderbookEntry, Float>(orderbook.asks, 0, func(acc, entry) { acc + entry.quantity });
        #ok(bidVolume + askVolume)
      };
    }
  };

  public query func healthCheck() : async Bool {
    true
  };
}
