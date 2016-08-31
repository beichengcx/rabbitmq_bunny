%%%-------------------------------------------------------------------
%%% @author ycc
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 八月 2016 17:42
%%%-------------------------------------------------------------------
-author("ycc").

-record(rabbit_bunny, {
  db = "mysql",
  host = "localhost",
  port = 5672,
  username = <<"guest">>,
  password = <<"guest">>}).
