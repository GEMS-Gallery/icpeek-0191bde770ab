import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface Orderbook {
  'asks' : Array<OrderbookEntry>,
  'bids' : Array<OrderbookEntry>,
}
export interface OrderbookEntry { 'quantity' : number, 'price' : number }
export type Result = { 'ok' : null } |
  { 'err' : string };
export type Result_1 = { 'ok' : number } |
  { 'err' : string };
export type Result_2 = { 'ok' : Orderbook } |
  { 'err' : string };
export interface _SERVICE {
  'getLastUpdateTime' : ActorMethod<[], bigint>,
  'getOrderbook' : ActorMethod<[], Result_2>,
  'getSpread' : ActorMethod<[], Result_1>,
  'getTotalVolume' : ActorMethod<[], Result_1>,
  'healthCheck' : ActorMethod<[], boolean>,
  'updateOrderbook' : ActorMethod<
    [Array<[string, string]>, Array<[string, string]>],
    Result
  >,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
