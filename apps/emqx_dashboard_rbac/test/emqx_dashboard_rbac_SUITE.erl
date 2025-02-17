%%--------------------------------------------------------------------
%% Copyright (c) 2023 EMQ Technologies Co., Ltd. All Rights Reserved.
%%--------------------------------------------------------------------

-module(emqx_dashboard_rbac_SUITE).

-compile(nowarn_export_all).
-compile(export_all).

-include("emqx_dashboard.hrl").
-include_lib("eunit/include/eunit.hrl").

-import(emqx_dashboard_api_test_helpers, [request/4, uri/1]).

-define(DEFAULT_SUPERUSER, <<"admin_user">>).
-define(DEFAULT_SUPERUSER_PASS, <<"admin_password">>).
-define(ADD_DESCRIPTION, <<>>).

all() ->
    emqx_common_test_helpers:all(?MODULE).

init_per_suite(Config) ->
    emqx_mgmt_api_test_util:init_suite([emqx_conf]),
    Config.

end_per_suite(_Config) ->
    emqx_mgmt_api_test_util:end_suite([emqx_conf]).

end_per_testcase(_, _Config) ->
    All = emqx_dashboard_admin:all_users(),
    [emqx_dashboard_admin:remove_user(Name) || #{username := Name} <- All].

t_create_bad_role(_) ->
    ?assertEqual(
        {error, <<"Role does not exist">>},
        emqx_dashboard_admin:add_user(
            ?DEFAULT_SUPERUSER,
            ?DEFAULT_SUPERUSER_PASS,
            <<"bad_role">>,
            ?ADD_DESCRIPTION
        )
    ).

t_permission(_) ->
    add_default_superuser(),

    ViewerUser = <<"viewer_user">>,
    ViewerPassword = <<"add_password">>,

    %% add by superuser
    {ok, 200, Payload} = emqx_dashboard_api_test_helpers:request(
        ?DEFAULT_SUPERUSER,
        ?DEFAULT_SUPERUSER_PASS,
        post,
        uri([users]),
        #{
            username => ViewerUser,
            password => ViewerPassword,
            role => ?ROLE_VIEWER,
            description => ?ADD_DESCRIPTION
        }
    ),

    ?assertMatch(
        #{
            <<"username">> := ViewerUser,
            <<"role">> := ?ROLE_VIEWER,
            <<"description">> := ?ADD_DESCRIPTION
        },
        emqx_utils_json:decode(Payload, [return_maps])
    ),

    %% add by viewer
    ?assertMatch(
        {ok, 403, _},
        emqx_dashboard_api_test_helpers:request(
            ViewerUser,
            ViewerPassword,
            post,
            uri([users]),
            #{
                username => ViewerUser,
                password => ViewerPassword,
                role => ?ROLE_VIEWER,
                description => ?ADD_DESCRIPTION
            }
        )
    ),

    ok.

t_update_role(_) ->
    add_default_superuser(),

    %% update role by superuser
    {ok, 200, Payload} = emqx_dashboard_api_test_helpers:request(
        ?DEFAULT_SUPERUSER,
        ?DEFAULT_SUPERUSER_PASS,
        put,
        uri([users, ?DEFAULT_SUPERUSER]),
        #{
            role => ?ROLE_VIEWER,
            description => ?ADD_DESCRIPTION
        }
    ),

    ?assertMatch(
        #{
            <<"username">> := ?DEFAULT_SUPERUSER,
            <<"role">> := ?ROLE_VIEWER,
            <<"description">> := ?ADD_DESCRIPTION
        },
        emqx_utils_json:decode(Payload, [return_maps])
    ),

    %% update role by viewer
    ?assertMatch(
        {ok, 403, _},
        emqx_dashboard_api_test_helpers:request(
            ?DEFAULT_SUPERUSER,
            ?DEFAULT_SUPERUSER_PASS,
            put,
            uri([users, ?DEFAULT_SUPERUSER]),
            #{
                role => ?ROLE_SUPERUSER,
                description => ?ADD_DESCRIPTION
            }
        )
    ),
    ok.

t_clean_token(_) ->
    Username = <<"admin_token">>,
    Password = <<"public_www1">>,
    Desc = <<"desc">>,
    NewDesc = <<"new desc">>,
    {ok, _} = emqx_dashboard_admin:add_user(Username, Password, ?ROLE_SUPERUSER, Desc),
    {ok, Token} = emqx_dashboard_admin:sign_token(Username, Password),
    FakeReq = #{method => <<"GET">>},
    {ok, Username} = emqx_dashboard_admin:verify_token(FakeReq, Token),
    %% change description
    {ok, _} = emqx_dashboard_admin:update_user(Username, ?ROLE_SUPERUSER, NewDesc),
    timer:sleep(5),
    {ok, Username} = emqx_dashboard_admin:verify_token(FakeReq, Token),
    %% change role
    {ok, _} = emqx_dashboard_admin:update_user(Username, ?ROLE_VIEWER, NewDesc),
    timer:sleep(5),
    {error, not_found} = emqx_dashboard_admin:verify_token(FakeReq, Token),
    ok.

add_default_superuser() ->
    {ok, _NewUser} = emqx_dashboard_admin:add_user(
        ?DEFAULT_SUPERUSER,
        ?DEFAULT_SUPERUSER_PASS,
        ?ROLE_SUPERUSER,
        ?ADD_DESCRIPTION
    ).
