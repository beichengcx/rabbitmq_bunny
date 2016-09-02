%%%-------------------------------------------------------------------
%%% @author ycc
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 八月 2016 17:20
%%%-------------------------------------------------------------------
-module(load_run_option).
-author("ycc").

%% API
-export([
  init_config/0,
  load_bunny/0,
  load_bunny/1,
  load_channels/0,
  init_bunny/0,
  reset_bunny/0]).
-include("rabbit_bunny.hrl").
-include("rabbit_bunny_common.hrl").


init_config() ->
  init_bunny(),
  init_channels().


init_bunny() ->
  ets:new(?TAB_CONFIG, [named_table, public, {keypos, #rabbit_bunny.db}]),
  case application:get_env(rabbitmq_bunny, connection) of
    {ok, Conf} ->
      io:format("Config = ~p~n", [Conf]),
      F = fun({Db, [{host, Host},
        {port, Port},
        {username, UserName},
        {password, Passwd},
        {channels, Channels}]}) ->
        Record = #rabbit_bunny{
          db = Db,
          host = Host,
          port = Port,
          username = UserName,
          password = Passwd,
          channels = Channels},
        ets:insert(?TAB_CONFIG, Record)
          end,
      lists:foreach(F, Conf);
    Failed ->
      io:format("Faild init connection host: ~p~n", [Failed]),
      Failed
  end.

init_channels() ->
  ets:new(?TAB_CHANNELS, [named_table, public, bag]),
  case application:get_env(rabbitmq_bunny, channels) of
    {ok, Channels} ->
      lists:foreach(fun(Channel) ->
        ets:insert(?TAB_CHANNELS, {channel_name, Channel})
        end, Channels),
      Channels;
    Failed ->
      io:format("Failed init channels: ~p~n", [Failed]),
      Failed
    end,
  ok.


reset_bunny() ->
  ets:delete(?TAB_CONFIG),
  ets:new(?TAB_CONFIG, [named_table, public, {keypos, #rabbit_bunny.db}]),
  case application:get_env(telegram_cs, connection) of
    {ok, Conf} ->
      F = fun({Db, [{host, Host},
        {port, Port},
        {username, UserName},
        {password, Passwd},
        {channels, Channels}]}) ->
        Record = #rabbit_bunny{
          db = Db,
          host = Host,
          port = Port,
          username = UserName,
          password = Passwd,
          channels = Channels},
        ets:insert(?TAB_CONFIG, Record)
          end,
      lists:foreach(F, Conf);
    Failed ->
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
      io:format("Failed load connection host: ~p~n", [Error])
  end.

load_channels() ->
  case ets:lookup(?TAB_CHANNELS, channel_name) of
    [] ->
      [];
    TupleList when is_list(TupleList) ->
      TupleList
  end.