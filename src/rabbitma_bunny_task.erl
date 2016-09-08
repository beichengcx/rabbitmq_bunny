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
-export([cast/6]).



-spec cast(port, string(), pid, binary, integer, binary | list | string) -> any.
cast(Connection, Exchange, Queue, RouteKey, DeliveryMode, PayLoad) ->
  {ok, Channel} = amqp_connection:open_channel(Connection),
  Declare = #'queue.declare'{queue = Queue, exclusive = true},             %% 声明queue
  amqp_channel:call(Channel, Declare), %% 指定Queue会在程序退出后被自动删除
  Binding = #'queue.bind'{
    queue       = Queue,
    exchange    = Exchange,
    routing_key = RouteKey},
  #'queue.bind_ok'{} = amqp_channel:call(Channel, Binding),
  Publish = #'basic.publish'{exchange = Exchange, routing_key = RouteKey},
  Props = #'P_basic'{delivery_mode = DeliveryMode}, %% 2:persistent message
  Msg = #amqp_msg{props = Props, payload = PayLoad},
  amqp_channel:cast(Channel, Publish, Msg).

