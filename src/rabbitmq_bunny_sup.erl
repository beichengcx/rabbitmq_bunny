%%%-------------------------------------------------------------------
%% @doc rabbitmq_bunny top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(rabbitmq_bunny_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).
-define(HANDER, rabbitmq_bunny_farm).

%%====================================================================
%% API functions
%%====================================================================

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->
    Specs = specs(),
    {ok, { {one_for_all, 0, 1}, [Specs]} }.

%%====================================================================
%% Internal functions
%%====================================================================

specs() ->
    {?HANDER, {?HANDER, start_link, []}, permanent, 5000, worker, [?HANDER]}.
