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
-export([load_config/0,
  load_config/1,
  init_config/0,
  reset_config/0]).
-include("rabbit_bunny.hrl").
-include("rabbit_bunny_common.hrl").


init_config() ->
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
      io:format("Failed = ~p~n", [Failed]),
      Failed
%%      lager:log(error, self(), "*** Module:~p, Line:~p,Init rabbit_bunny config failed, Reason: ~p~n", [?MODULE, ?LINE, Failed])
  end.


reset_config() ->
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
%%      lager:log(error, self(), "*** Module:~p, Line:~p,Init rabbit_bunny config failed, Reason: ~p~n", [?MODULE, ?LINE, Failed])
  end.

load_config() ->
  ets:tab2list(?TAB_CONFIG).


load_config(Key) ->
  case ets:lookup(?TAB_CONFIG, Key) of
    [] ->
      [];
%%      lager:log(error, self(), "*** Module:~p, Line:~p, Load telegram config failed, Reason: ~p~n", [?MODULE, ?LINE, empty]);
    Config when is_list(Config) ->
      [_tab | Conf] = Config,
      Conf
  end.