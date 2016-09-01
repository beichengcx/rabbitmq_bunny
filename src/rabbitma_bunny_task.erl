%%%-------------------------------------------------------------------
%%% @author ycc
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. 九月 2016 11:01
%%%-------------------------------------------------------------------
-module(rabbitma_bunny_task).
-author("ycc").

-include("rabbit_bunny.hrl").
%% API
-export([cast/5]).



-spec cast(port, pid, binary, integer, binary | list | string) -> any.
cast(Channel, Exchange, RoutingKey, DeliveryMode, PayLoad) ->
  amqp_channel:cast(Channel,
    #'basic.publish'{
      exchange = Exchange,
      routing_key = RoutingKey},
    #amqp_msg{props = #'P_basic'{delivery_mode = DeliveryMode},
      payload = PayLoad}).


