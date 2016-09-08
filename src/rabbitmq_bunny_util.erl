%%%-------------------------------------------------------------------
%%% @author ycc
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 八月 2016 17:20
%%%-------------------------------------------------------------------
-module(rabbitmq_bunny_util).
-author("ycc").

%% API
-export([
  get_conf/0,
  init_config/0,
  load_bunny/0,
  load_bunny/1,
  load_queues/0,
  init_bunny/0,
  init_queue/0,
  init_queues/0,
  reset_bunny/0,
  create_queue/0,
  close/0
  ]).
-include("rabbit_bunny.hrl").
-include("rabbit_bunny_common.hrl").


init_config() ->
  init_bunny().
%%  init_queues().


get_conf() ->
  application:get_env(rabbitmq_bunny, connection).


init_bunny() ->
  ets:new(?TAB_CONFIG, [named_table, public, {keypos, #rabbit_bunny.db}]),
  case application:get_env(rabbitmq_bunny, connection) of
    {ok, Conf} ->
      io:format("Config = ~p~n", [Conf]),
      F = fun({Db, [
        {connection, [
          {host, Host},
          {port, Port},
          {username, UserName},
          {password, Passwd}]
        },
        {exchange, Exchange},
        {queues, Queues}]}) ->
        Record = #rabbit_bunny{
          db = Db,
          connection = #rabbit_conn{
            host = Host,
            port = Port,
            username = UserName,
            password = Passwd},
          exchange = Exchange,
          queues = Queues},
        ets:insert(?TAB_CONFIG, Record)
          end,
      lists:foreach(F, Conf);
    Failed ->
      io:format("Faild init rabbitmq_bunny connection host: ~p~n", [Failed]),
      Failed
  end.


init_queue() ->
  F = fun({Connection, Exchange, Queue, RouteKey, DeliveryMode,PayLoad }) ->
    {ok, Channel} = amqp_connection:open_channel(Connection),
    QDeclare = #'queue.declare'{queue = Queue, exclusive = true}, % 声明queue,exclusive 指定Queue会在程序退出后被自动删除
    amqp_channel:call(Channel, QDeclare),
    Binding = #'queue.bind'{
      queue       = Queue,
      exchange    = Exchange,     %% fanout/direct/topic/headers
      routing_key = RouteKey},
    #'queue.bind_ok'{} = amqp_channel:call(Channel, Binding),
    Publish = #'basic.publish'{exchange = Exchange, routing_key = RouteKey},
    Props = #'P_basic'{delivery_mode = DeliveryMode}, %% 2:persistent message
    Msg = #amqp_msg{props = Props, payload = PayLoad},
    amqp_channel:cast(Channel, Publish, Msg)
    end,
  F.

create_queue() ->
  F = fun({Connection, Exchange, Queue, RouteKey, DeliveryMode,PayLoad }) ->
    {ok, Channel} = amqp_connection:open_channel(Connection),
    QDeclare = #'queue.declare'{queue = Queue, exclusive = true}, % 声明queue,exclusive 指定Queue会在程序退出后被自动删除
    amqp_channel:call(Channel, QDeclare),
    Binding = #'queue.bind'{
      queue       = Queue,
      exchange    = Exchange,     %% fanout/direct/topic/headers
      routing_key = RouteKey},
    #'queue.bind_ok'{} = amqp_channel:call(Channel, Binding),
    Publish = #'basic.publish'{exchange = Exchange, routing_key = RouteKey},
    Props = #'P_basic'{delivery_mode = DeliveryMode}, %% 2:persistent message
    Msg = #amqp_msg{props = Props, payload = PayLoad},
    amqp_channel:cast(Channel, Publish, Msg)
      end,
  F.

close() ->
  F = fun({Connection, _Exchange, _Queue, _RouteKey, _DeliveryMode,_PayLoad }) ->
    {ok, Channel} = amqp_connection:open_channel(Connection),
    amqp_channel:close(Channel),
    amqp_connection:close(Connection)
      end,
  F.




init_queues() ->
  ets:new(?TAB_CHANNELS, [named_table, public, {keypos, #rabbit_channel.channel}]),
  case application:get_env(rabbitmq_bunny, queues) of
    {ok, Conf} ->
      io:format("queues = ~p~n", [Conf]),
      F = fun({Channel, QueueList}) ->
        Record = #rabbit_channel{
          channel = Channel,
          queues = QueueList},
        ets:insert(?TAB_CHANNELS, Record)
          end,
      lists:foreach(F, Conf);
    Failed ->
      io:format("Faild init rabbitmq_bunny channel config: ~p~n", [Failed]),
      Failed
  end.


reset_bunny() ->
  ets:delete(?TAB_CONFIG),
  ets:new(?TAB_CONFIG, [named_table, public, {keypos, #rabbit_bunny.db}]),
  case application:get_env(rabbitmq_bunny, connection) of
    {ok, Conf} ->
      io:format("Config = ~p~n", [Conf]),
      F = fun({Db, [
        {connection,
          {host, Host},
          {port, Port},
          {username, UserName},
          {password, Passwd}
        },
        {exchange, Exchange},
        {queues, Queues}]}) ->
        Record = #rabbit_bunny{
          db = Db,
          connection = #rabbit_conn{
            host = Host,
            port = Port,
            username = UserName,
            password = Passwd},
          exchange = Exchange,
          queues = Queues},
        ets:insert(?TAB_CONFIG, Record)
          end,
      lists:foreach(F, Conf);
    Failed ->
      io:format("Faild init rabbitmq_bunny connection host: ~p~n", [Failed]),
      Failed
  end.

load_bunny() ->
  ets:tab2list(?TAB_CONFIG).

load_bunny(Key) ->
  case ets:lookup(?TAB_CONFIG, Key) of
    [] ->
      [];
    Config when is_list(Config) ->
      Config;
    Error ->
      io:format("Failed load rabbitmq_bunny connection host: ~p~n", [Error]),
      []
  end.

load_queues() ->
  case ets:tab2list(?TAB_CHANNELS) of
    List when is_list(List) ->
      lists:map(fun({_Tab, Channel, Queues}) ->
        {Channel, Queues}
                end, List);
    Failed ->
      io:format("Failed load rabbitmq_bunny queues: ~p~n", [Failed]),
      []
  end.