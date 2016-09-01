%%%-------------------------------------------------------------------
%%% @author ycc
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. 九月 2016 10:42
%%%-------------------------------------------------------------------
-module(rabbitmq_bunny_farm).
-author("ycc").

-behaviour(gen_server).

%% API
-export([start_link/0]).


-export([new_connection/4,
  new_channel/2,
  new_queue/3,
  close_channel/1,
  close_connection/1,
  monitor/0
  ]).


%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-define(SERVER, ?MODULE).
-record(state, {connection = [], channel = []}).
-include("rabbit_bunny.hrl").


%%%===================================================================
%%% API
%%%===================================================================

new_connection(Host, Port, UserName, Passwd) ->
  gen_server:call(rabbitmq_bunny_farm, {new_connection, [Host, Port, UserName, Passwd]}).

new_channel(ChannelType, Connection) ->
  gen_server:call(rabbitmq_bunny_farm, {new_channel, [ChannelType, Connection]}).

new_queue(Channel, QueueName, Durable) ->
  gen_server:call(rabbitmq_bunny_farm, {new_queue, [Channel, QueueName, Durable]}).


close_channel(Channel) ->
  gen_server:call(rabbitmq_bunny_farm, {close_channel, [Channel]}).

close_connection(Connection) ->
  gen_server:call(rabbitmq_bunny_farm, {close_connection, [Connection]}).

monitor() ->
  gen_server:call(rabbitmq_bunny_farm, monitor).

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link() ->
  {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).


%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
  {ok, State :: #state{}} | {ok, State :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term()} | ignore).
init([]) ->
  process_flag(trap_exit, true),
  io:format("start server ~p...~n", [?MODULE]),
%%  gen_server:call(self(), {new_connection, [Host, Port, UserName, Passwd]}),
  ServerOpts = load_run_option:load_bunny(),
  lists:foreach(fun({_tab, Db, Host, Port, UserName, Passwd, _Channels}) ->
    self() ! {new_connection, [Db, Host, Port, UserName, Passwd]}
    end,
    ServerOpts),
  {ok, #state{connection = [], channel = []}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
    State :: #state{}) ->
  {reply, Reply :: term(), NewState :: #state{}} |
  {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_call({new_connection, [Db, Host, Port, UserName, Passwd]}, _From, State) ->
  io:format("Module:~p,Line:~p, new connection!", [?MODULE, ?LINE]),
  {ok, Connection} = amqp_connection:start(#amqp_params_network{host = Host,
    port = Port,
    username = UserName,
    password = Passwd}),
  io:format("Module:~p,Line:~p, new connection: ~p~n",[?MODULE, ?LINE, Connection]),
  {reply, Connection, State#state{connection = [{Db, Connection} | State#state.connection]}};

handle_call({new_channel, [ChannelType, Connection]}, _From, State) ->
  {ok, Channel} = amqp_connection:open_channel(Connection),
  {reply, Channel, State#state{channel = [{ChannelType, Channel} | State#state.channel]}};

handle_call({new_queue, [Channel, QueueName, Durable]}, _From, State) ->
  Reply = amqp_channel:call(Channel, #'queue.declare'{queue = QueueName,
    durable = Durable}),
  {reply, Reply, State#state{channel = [Channel | State#state.channel]}};

handle_call({close_channel, [Channel]}, _From, State) ->
  {ok, Channel} = amqp_channel:close(Channel),
  {reply, Channel, State#state{channel = State#state.channel -- Channel}};

handle_call({close_connection, [Connection]}, _From, State) ->
  {ok, Channel} = amqp_channel:close(Connection),
  {reply, Channel, State#state{channel = State#state.connection -- Connection}};

handle_call(monitor, _From, State) ->
  {reply, State, State};


handle_call(_Request, _From, State) ->
  {reply, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_cast(Request :: term(), State :: #state{}) ->
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_cast(_Request, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
-spec(handle_info(Info :: timeout() | term(), State :: #state{}) ->
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #state{}}).

handle_info({new_connection, [Db, Host, Port, UserName, Passwd]}, State) ->
  {ok, Connection} = amqp_connection:start(#amqp_params_network{host = Host,
  port = Port,
  username = UserName,
  password = Passwd}),
  io:format("Module:~p,Line:~p, new connection: ~p~n",[?MODULE, ?LINE, Connection]),
  {noreply, State#state{connection = [{Db ,Connection} | State#state.connection]}};

handle_info(_Info, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
    State :: #state{}) -> term()).
terminate(_Reason, _State) ->
  ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
-spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
    Extra :: term()) ->
  {ok, NewState :: #state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
