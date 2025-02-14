-module(dev_ffi).


-export([identity/1, run_server/0, stop_server/1, tick_server/1]).

% Used in coercion.
identity(X) ->
    X.

% @external(erlang, "lustre_dev_tools_ffi", "exec")
% pub fn exec(
%   run command: String,
%   with args: List(String),
%   in in: String,
% ) -> Result(String, #(Int, String))

run_server() ->
    Port =
        open_port({spawn_executable, os:find_executable("gleam")},
                   [{args, ["run"]},
                   {cd, "."}]),
        list_to_binary(port_to_list(Port)).

stop_server(Port) ->
    port_close(list_to_port(binary_to_list(Port))).

tick_server(Port) ->
    do_exec(list_to_port(binary_to_list(Port)), []).

do_exec(Port, Acc) ->
    receive
        {Port, {data, Data}} ->
            do_exec(Port, [Data | Acc]);
        {Port, {exit_status, 0}} ->
            port_close(Port),
            {ok, list_to_binary(lists:reverse(Acc))};
        {Port, {exit_status, Code}} ->
            port_close(Port),
            {error, {Code, list_to_binary(lists:reverse(Acc))}};
        {Port, closed} ->
            {ok, list_to_binary(lists:reverse(Acc))};
        {'EXIT', Port, Code} ->
            {error, {Code, list_to_binary(lists:reverse(Acc))}}
    end.
