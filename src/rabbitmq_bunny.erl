%%%-------------------------------------------------------------------
%%% @author ycc
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. 九月 2016 18:25
%%%-------------------------------------------------------------------
-module(rabbitmq_bunny).
-author("ycc").
-define(DURABLE, true).
-include("rabbit_bunny.hrl").
-include("rabbit_bunny_common.hrl").

%% API
-export([
  init/0,
  init_queues/0,
  get_config_queue/1]).

-spec init() -> ok | {error, any}.
init() ->
  case rabbitmq_bunny_util:load_bunny() of
    TupleList when is_list(TupleList) ->
%%      io:format("TupleList = ~p~n", [TupleList]),
      lists:foreach(fun({_Tab, Db, DbConfig, Exchange, Queues}) ->
%%        io:format("Module:~p, Line:~p, Conf = ~p~n", [?MODULE, ?LINE, DbConfig]),
        do_set_up(Db, DbConfig, Exchange, Queues)
                    end, TupleList);
    Error ->
      error_logger:error_msg("load rabbitmq_bunny config failed, Reason: ~p~n", [Error]),
      {error, Error}
  end.

-spec init_queues() -> ok | {error, any}.
init_queues() ->
  case load_run_option:load_queues() of
    [] ->
      error_logger:error_msg("load rabbitmq_bunny queues faild: channels initialization not found"),
      skip;
    TupleList ->
      lists:map(fun({Channel, _QueueList}) ->
        rabbitmq_bunny_farm:new_queue(Channel, <<"task_queue">>, ?DURABLE)
                end, TupleList)
  end.

get_config_queue(ChannelType) ->
  ChannelType.

do_set_up(Db, Conf, _Exchange, AllQueue) ->
  io:format("Queues = ~p~n", [AllQueue]),
  {_CTab, Host, Port, UserName, PassWd} = Conf,
  Conn = [Db, Host, Port, UserName, PassWd],
  Connection = rabbitmq_bunny_farm:new_connection(Conn),
  R = lists:map(fun({ChannelType, Queues}) ->
    Channel = rabbitmq_bunny_farm:new_channel(ChannelType, Connection),
    io:format("Channel = ~p~n", [Channel]),
    Q = lists:map(fun(Queue) ->
%%      QDeclare = #'queue.declare'{queue = Queue, durable = true}, % 声明queue,durable 指定Queu持久化
%%      QQ = amqp_channel:call(Channel, QDeclare),
%%      io:format("Module:~p, Line:~p, R = ~p~n", [?MODULE, ?LINE, QQ]),
%%      {Queue, QQ}
     {Queue, rabbitmq_bunny_farm:new_queue(Channel, Queue, ?DURABLE)}
              end,Queues),

      [{ChannelType, Channel}, Q]
            end,AllQueue),
  io:format("Module:~p, Line:~p, R = ~p~n", [?MODULE, ?LINE, R]).
