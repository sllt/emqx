%%--------------------------------------------------------------------
%% Copyright (c) 2022-2023 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------
-ifndef(EMQX_DS_HRL).
-define(EMQX_DS_HRL, true).

-define(SESSION_TAB, emqx_ds_session).
-define(ITERATOR_REF_TAB, emqx_ds_iterator_ref).
-define(DS_MRIA_SHARD, emqx_ds_shard).

-record(session, {
    %% same as clientid
    id :: emqx_ds:session_id(),
    %% creation time
    created_at :: _Millisecond :: non_neg_integer(),
    expires_at = never :: _Millisecond :: non_neg_integer() | never,
    %% for future usage
    props = #{} :: map()
}).

-record(iterator_ref, {
    ref_id :: {emqx_ds:session_id(), emqx_ds:topic_filter()},
    it_id :: emqx_ds:iterator_id(),
    start_time :: emqx_ds:time(),
    props = #{} :: map()
}).

-endif.
