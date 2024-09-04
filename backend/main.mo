import Order "mo:base/Order";

import Float "mo:base/Float";
import Int "mo:base/Int";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Text "mo:base/Text";

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

  public func updateOrderbook(): async Result.Result<(), Text> {
    // In a real-world scenario, you would fetch data from an external API here
    // For this example, we'll simulate fetching data
    let simulatedOrderbook: Orderbook = {
      bids = [
        { price = 30.5; quantity = 1.5 },
        { price = 30.4; quantity = 2.0 },
        { price = 30.3; quantity = 3.0 }
      ];
      asks = [
        { price = 30.6; quantity = 1.0 },
        { price = 30.7; quantity = 2.5 },
        { price = 30.8; quantity = 1.8 }
      ];
    };

    currentOrderbook := ?simulatedOrderbook;
    lastUpdateTime := Time.now();
    #ok()
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
}
