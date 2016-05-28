-module(ehcu_build).

-export([
    init/1,
    do/1,
    format_error/1
]).

-include("ehcu.hrl").

-define(PROVIDER, build).
-define(DEPS, [app_discovery]).

%% ===================================================================
%% Public API
%% ===================================================================
-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    Provider = providers:create([
        {name, ?PROVIDER},            % The 'user friendly' name of the task
        {module, ?MODULE},            % The module implementation of the task
        {bare, true},                 % The task can be run by the user, always true
        {deps, ?DEPS},                % The list of dependencies
        {example, "rebar3 build"}, % How to use the plugin
        {hooks, {[], []}}, % execute rebar command afterwards
        {opts, []},
        {short_desc, "call release, diaylzyer, and common test"},
        {desc, "Call release, diaylzyer, and common test"}
    ]),
    {ok, rebar_state:add_provider(State, Provider)}.

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    #ehcu_state{
        app_name = AppName
    } = ehcu:ehcu_state(State),

    os:cmd("rm -rf _build/default/lib/" ++ AppName ++ "/ ;\
            rm -rf _build/default/rel/" ++ AppName ++ "/ ;\
            rm -f ebin/" ++ AppName ++ ".appup"),

    ehcu:cmd("./config/rebar3 release"),

    {ok, State}.

-spec format_error(any()) -> iolist().
format_error(Reason) ->
    io_lib:format("~p", [Reason]).

%==================================================================