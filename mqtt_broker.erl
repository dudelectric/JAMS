-module(mqtt_broker).
-export([start/0, accept_loop/1, handle_client/1, handle_pingreq/1, parse_connect/2, send_connack/1]).

start() ->
    {ok, ListenSocket} = gen_tcp:listen(1883, [binary, {packet, 0}, {active, false}, {reuseaddr, true}]),
    io:format("MQTT Broker started. Listening on port 1883...~n"),
    accept_loop(ListenSocket).

accept_loop(ListenSocket) ->
    {ok, Socket} = gen_tcp:accept(ListenSocket),
    io:format("Client connected.~n"),
    handle_client(Socket),
    accept_loop(ListenSocket).

handle_client(Socket) ->
    case gen_tcp:recv(Socket, 0) of
        {ok, <<192, _Rest/binary>>} ->  % PINGREQ header
            io:format("Received PINGREQ, sending PINGRESP~n"),
            handle_pingreq(Socket);  % Handle PINGREQ

        {ok, Data} when is_binary(Data) -> 
            io:format("Received data: ~p~n", [Data]),
            parse_connect(Data, Socket);  % Call parse_connect with data

        {error, _} -> 
            io:format("Error receiving data~n"),
            ok
    end.

handle_pingreq(Socket) ->
    ConnackPacket = <<208, 0>>, % PINGRESP packet (Fixed header)
    case gen_tcp:send(Socket, ConnackPacket) of
        ok -> 
            io:format("Sent PINGRESP to client~n");
        {error, Reason} -> 
            io:format("Error sending PINGRESP: ~p~n", [Reason])
    end.

% Updated parse_connect function to handle CONNECT packet
parse_connect(<<16, RemainingLength:8, ProtocolNameLength:16/big, ProtocolName:ProtocolNameLength/binary, 
               ProtocolLevel:8, ConnectFlags:8, KeepAlive:16/big, 
               ClientIdLength:16/big, ClientId:ClientIdLength/binary, _Rest/binary>>, Socket) when ProtocolName =:= <<"MQTT">> ->
    io:format("CONNECT Packet Received.~n"),
    io:format("Protocol Name: ~p~n", [ProtocolName]),
    io:format("Protocol Level: ~p~n", [ProtocolLevel]),
    io:format("Connect Flags: ~p~n", [ConnectFlags]),
    io:format("Keep Alive: ~p~n", [KeepAlive]),
    io:format("Client ID: ~p~n", [ClientId]),
    send_connack(Socket);

parse_connect(_, _) -> 
    io:format("Invalid CONNECT packet received.~n").

send_connack(Socket) ->
    ConnackPacket = <<32, 2, 0, 0>>, % CONNACK packet
    case gen_tcp:send(Socket, ConnackPacket) of
        ok -> 
            io:format("Sent CONNACK packet.~n");
        {error, Reason} -> 
            io:format("Error sending CONNACK: ~p~n", [Reason])
    end.
