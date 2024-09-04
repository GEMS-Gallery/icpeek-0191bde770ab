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
import Blob "mo:base/Blob";
import Nat8 "mo:base/Nat8";

actor {
  type OrderbookEntry = {
    price: Float;
    quantity: Float;
  };

  type Orderbook = {
    bids: [OrderbookEntry];
    asks: [OrderbookEntry];
  };

  type HttpRequest = {
    url : Text;
    method : Text;
    body : ?Blob;
    headers : [(Text, Text)];
  };

  type HttpResponse = {
    status : Nat;
    headers : [(Text, Text)];
    body : Blob;
  };

  stable var lastUpdateTime: Int = 0;
  var currentOrderbook: ?Orderbook = null;

  public query func getOrderbook(): async Result.Result<Orderbook, Text> {
    switch (currentOrderbook) {
      case (null) { #err("Orderbook not initialized") };
      case (?orderbook) { #ok(orderbook) };
    }
  };

  public func updateOrderbook(): async Result.Result<(), Text> {
    try {
      let binanceData = await fetchOrderbookFromBinance();
      let parsedBids = parseOrderbookEntries(binanceData.bids);
      let parsedAsks = parseOrderbookEntries(binanceData.asks);
      currentOrderbook := ?{ bids = parsedBids; asks = parsedAsks };
      lastUpdateTime := Time.now();
      #ok()
    } catch (error) {
      #err("Error updating orderbook: " # Error.message(error))
    }
  };

  private func fetchOrderbookFromBinance() : async { bids: [(Text, Text)]; asks: [(Text, Text)] } {
    let url = "https://api.binance.com/api/v3/depth?symbol=ICPUSDT&limit=10";
    let ic : actor { http_request : HttpRequest -> async HttpResponse } = actor("aaaaa-aa");
    let response = await ic.http_request({
      url = url;
      method = "GET";
      body = null;
      headers = [];
    });
    switch (response.status) {
      case (200) {
        let responseBody = response.body;
        let jsonObj = parseJSON(responseBody);
        let bids = parseArrayOfArrays(jsonObj, "bids");
        let asks = parseArrayOfArrays(jsonObj, "asks");
        { bids = bids; asks = asks }
      };
      case (_) { throw Error.reject("Failed to fetch data from Binance") }
    }
  };

  private func parseJSON(blob: Blob) : Text {
    let bytes = Blob.toArray(blob);
    let text = Text.fromIter(Array.vals(Array.map<Nat8, Char>(bytes, func (n) { Char.fromNat32(Nat32.fromNat(Nat8.toNat(n))) })));
    text
  };

  private func parseArrayOfArrays(jsonText: Text, key: Text) : [(Text, Text)] {
    // Implement a basic JSON parsing logic here
    // This is a placeholder and needs to be implemented properly
    []
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
