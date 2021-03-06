-module(ehcu_check).

-export([
    init/1,
    do/1,
    format_error/1
]).

-include("ehcu.hrl").

-define(PROVIDER, ck).
-define(DEPS, [app_discovery, dialyzer]).

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
        {example, "rebar3 ck"}, % How to use the plugin
        {hooks, {[], [edoc]}}, % execute rebar command afterwards
        {opts, []},
        {short_desc, "run dialyzer and edoc with overview.edoc if exists"},
        {desc, "Run dialyzer and edoc with overview.edoc if exists"}
    ]),
    {ok, rebar_state:add_provider(State, Provider)}.


-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    #ehcu_state{
        app_name = AppName,
        app_vsn = Vsn,
        plugin_path = PluginPath,
        project_path = ProjectPath
    } = ehcu:ehcu_state(State),

    OverviewEdocPath = filename:append(ProjectPath, "/config/overview.edoc"),

    case filelib:is_regular(OverviewEdocPath) of
        true ->
            os:cmd(filename:append(PluginPath, "/priv/gen_edoc.sh " ++ AppName ++ " " ++ Vsn)),
            io:format("===> Edoc overview generated successfully~n");
        false ->
            io:format("===> config/overview.edoc does not exist, skip genereating overview.~n")
    end,

    {ok, State}.

-spec format_error(any()) -> iolist().
format_error(Reason) ->
    io_lib:format("~p", [Reason]).

%==================================================================