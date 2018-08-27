%%--------------------------------------------------------------------
%% Copyright (c) 2013-2017 EMQ Enterprise, Inc. (http://emqtt.io)
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

-module(emqx_mock_client).

-behaviour(gen_server).

-export([start_link/1, open_session/3, stop/1]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {clean_start, client_id, client_pid}).

start_link(ClientId) ->
    gen_server:start_link(?MODULE, [ClientId], []).

open_session(ClientPid, ClientId, Zone) ->
    gen_server:call(ClientPid, {start_session, ClientPid, ClientId, Zone}).

stop(CPid) ->
    gen_server:call(CPid, stop).

init([ClientId]) ->
    {ok, 
     #state{clean_start = true,
            client_id = ClientId}
    }.

handle_call({start_session, ClientPid, ClientId, Zone}, _From, State) ->
    Attrs = #{ zone        => Zone,
               client_id   => ClientId,
               client_pid  => ClientPid,
               clean_start => true,
               username    => undefined,
               conn_props  => undefined
             },
    {ok, SessPid} = emqx_sm:open_session(Attrs),
    {reply, {ok, SessPid}, State#state{
                             clean_start = true,
                             client_id = ClientId, 
                             client_pid = ClientPid
                            }};

handle_call(stop, _From, State) ->
    {stop, normal, ok, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

