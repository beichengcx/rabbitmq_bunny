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
-define(DURABLE, durable).

%% API
-export([
  init_create_queues/0,
  get_config_queue/1]).

init_create_queues() ->
  case load_run_option:load_queues() of
    [] ->
      error_logger:error_msg("load rabbitmq_bunny queues faild: channels initialization not found"),
      skip;
    TupleList ->
      lists:map(fun({Channel, QueueList}) ->
        rabbitmq_bunny_farm:new_queue(Channel, <<"task_queue">>, ?DURABLE)
                end, TupleList)
  end.

get_config_queue(ChannelType) ->
  ChannelType.
