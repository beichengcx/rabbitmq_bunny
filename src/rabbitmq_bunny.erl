%%%-------------------------------------------------------------------
%%% @author ycc
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. 九月 2016 18:25
%%%-------------------------------------------------------------------
-define(DURABLE, DURABLE).
-module(rabbitmq_bunny).
-author("ycc").


%% API
-export([init_create_queue/0]).

init_create_queue() ->
  case load_run_option:load_channels() of
    [] ->
      error_logger:error_msg("load rabbitmq_bunny channels faild: channels initialization not found"),
      skip;
    TupleList ->
      lists:map(fun({_ChannelName, Channel}) ->
        rabbitmq_bunny_farm:new_queue(Channel, <<"task_queue">>, ?DURABLE)
      end, TupleList)
  end.