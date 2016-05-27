-module(ehcu).

-export([
    init/1,
    ehcu_state/1
]).

-include("ehcu.hrl").

-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    PluginInfo = lists:keyfind(atom_to_binary(?PLUGIN_NAME, utf8), 2, rebar_state:all_plugin_deps(State)),
    PluginPath = rebar_app_info:dir(PluginInfo),
    {ok, FileList} = file:list_dir(filename:append(PluginPath, "src")),

    FinalState = lists:foldl(
        fun(FileName, AccState) ->
            case re:run(FileName, <<"^(ehcu_.*)\.erl">>, [global, {capture, all_but_first, list}]) of
                {match, [[ModuleNameStr]]} ->
                    ModuleName = list_to_atom(ModuleNameStr),
                    {ok, UpdatedAccState} = ModuleName:init(AccState),
                    UpdatedAccState;
                nomatch ->
                    AccState
            end
        end, State, FileList),

    {ok, FinalState}.

%%--------------------------------------------------------------------
%% @doc
%% Generate ehcu state.
%%
%% @end
%%--------------------------------------------------------------------
-spec ehcu_state(rebar_state:t()) -> #ehcu_state{}.
ehcu_state(State) ->
    ProjectPath = rebar_state:dir(State),
    ProjectSrcPath = filename:append(ProjectPath, "src"),

    {ok, FileList} = file:list_dir(ProjectSrcPath),
    SrcFileName = retrieve_n_break(
        fun(FileName) ->
            case re:run(FileName, <<".*\.app\.src">>) of
                {match, _Match} ->
                    true;
                nomatch ->
                    false
            end
        end, FileList),

    SrcFilePath = filename:append(ProjectSrcPath, SrcFileName),

    {ok, [{application, RawAppName, ConfigList} = SrcConfig | _Rest]} = file:consult(SrcFilePath),
    {vsn, Vsn} = lists:keyfind(vsn, 1, ConfigList),
    PluginInfo = lists:keyfind(atom_to_binary(?PLUGIN_NAME, utf8), 2, rebar_state:all_plugin_deps(State)),

    RebarConfigPath = filename:append(ProjectPath, "rebar.config"),
    {ok, RebarConfig} = file:consult(RebarConfigPath),

    #ehcu_state{
        app_name = atom_to_list(RawAppName),
        app_vsn = Vsn,
        plugin_path = rebar_app_info:dir(PluginInfo),
        project_path = ProjectPath,
        src_config = SrcConfig,
        src_file_path = SrcFilePath,
        rebar_config_path = RebarConfigPath,
        rebar_config = RebarConfig
    }.

%%--------------------------------------------------------------------
%% @doc
%% Retrieve value from List and return the match value once found by
%% omitting rest elements from list.
%%
%% @end
%%--------------------------------------------------------------------
-spec retrieve_n_break(Func, List) -> Elem | undefined when
    Elem :: term(),
    List :: list(),
    Func :: fun((Elem) -> boolean()).
retrieve_n_break(Func, [H | T]) ->
    case Func(H) of
        true ->
            H;
        false ->
            retrieve_n_break(Func, T)
    end;
retrieve_n_break(Func, []) when is_function(Func, 1) -> undefined.