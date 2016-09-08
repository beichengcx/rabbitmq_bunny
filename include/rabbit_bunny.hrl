%%%-------------------------------------------------------------------
%%% @author ycc
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 八月 2016 17:42
%%%-------------------------------------------------------------------
-author("ycc").

-include_lib("amqp_client/include/amqp_client.hrl").

-record(rabbit_bunny, {
  db = "mysql",
  connection = "",
  exchange = <<"fanout">>,  %% fanout 收到消息后会将消息广播给所有绑定到它上面的队列
                            %% direct 将此消息投递到发送消息时指定的routing_key和绑
                            %%        定队列到exchange上时的routing_key相同的队列里(routing_key完全匹配)
                            %% topic  将发送消息的 routing_key和绑定队列到exchange上时的routing_key做字符
                            %%        串匹配,符号“#”匹配一个或多个词,符号“*”匹配不多不少一个词,因此“audit.#”
                            %%        能够匹配到“audit.irs.corporate”，但是“audit.*” 只会匹配到“audit.irs”
                            %% headers
  queues = []}).

-record(rabbit_channel, {
  channel = "task",
  queues = [<<"task.queue">>]}).

-record(rabbit_conn, {
  host = "localhost",
  port = 5672,
  username = <<"guest">>,
  password = <<"guest">>
  }).
