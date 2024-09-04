export const idlFactory = ({ IDL }) => {
  const OrderbookEntry = IDL.Record({
    'quantity' : IDL.Float64,
    'price' : IDL.Float64,
  });
  const Orderbook = IDL.Record({
    'asks' : IDL.Vec(OrderbookEntry),
    'bids' : IDL.Vec(OrderbookEntry),
  });
  const Result_2 = IDL.Variant({ 'ok' : Orderbook, 'err' : IDL.Text });
  const Result_1 = IDL.Variant({ 'ok' : IDL.Float64, 'err' : IDL.Text });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Text });
  return IDL.Service({
    'getLastUpdateTime' : IDL.Func([], [IDL.Int], ['query']),
    'getOrderbook' : IDL.Func([], [Result_2], ['query']),
    'getSpread' : IDL.Func([], [Result_1], ['query']),
    'getTotalVolume' : IDL.Func([], [Result_1], ['query']),
    'updateOrderbook' : IDL.Func([], [Result], []),
  });
};
export const init = ({ IDL }) => { return []; };
