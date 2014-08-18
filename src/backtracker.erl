-module(backtracker).
-author("genesislive@outlook.com").
-copyleft("copyleft © 2013 genesislive").

-record(grid, {row, col, maze :: dict(), xy :: list(), opposite :: list()}).
-define(N, 1).    %% N, E, S, W
-define(E, 2).
-define(S, 4).
-define(W, 8).

%% ====================================================================
%% API functions
%% ====================================================================
-export([generate/0, generate/2]).

generate() ->
    generate(random(5, 30), random(5, 30)).

-spec generate(Row :: integer(), Col :: integer()) -> ok.
generate(Row, Col) when is_integer(Row), is_integer(Col) ->
    print_in_console(carve_passages_from(1, 1, initialise(Row, Col)), Row, Col).

%% ====================================================================
%% Internal functions
%% ====================================================================
-spec random(Low :: integer(), High :: integer()) -> integer().
random(Low, High) when is_integer(Low), is_integer(High), Low < High ->
    random:uniform(High - Low) + Low - 1.

-spec shuffle(List :: list()) -> list().
shuffle(List) ->
    [Value || {_, Value} <- lists:sort([{random:uniform(), Val} || Val <- List])].

-spec initialise(Row :: integer(), Col :: integer()) -> #grid{}.
initialise(Row, Col) when is_integer(Row), is_integer(Col) ->
    %% normalize Row, Col
    Rows = dimension(Row),
    Cols = dimension(Col),
    %% direction tuple list: [{-1, 0}, {0, 1}, {1, 0}, {0, -1}]
    XY = array:set(?N, {-1, 0}, array:set(?E, {0, 1}, array:set(?S, {1, 0}, array:set(?W, {0, -1}, array:new())))),
    %% oppsite direction: [1:4, 2:8, 4:1, 8:2]
    Opposite = array:set(?N, ?S, array:set(?E, ?W, array:set(?S, ?N, array:set(?W, ?E, array:new())))),
    %% grid
    Dict =
        lists:foldl(fun(X, DictX) ->
            lists:foldl(fun(Y, DictY) ->
                dict:store({X, Y}, 0, DictY)
            end, DictX, lists:seq(1, Cols))
        end, dict:new(), lists:seq(1, Rows)),
    #grid{row = Rows, col = Cols, maze = Dict, xy = XY, opposite = Opposite}.

-spec dimension(X :: integer()) -> integer().
dimension(X) when is_integer(X) ->
    Filter = fun(Elm, Min, Max) ->
        if
            Elm < Min -> Min;
            Elm > Max -> Max;
            true -> Elm
        end
    end,
    Filter(X, 3, 30).

-spec carve_passages_from(Cx :: integer(), Cy :: integer(), Grid :: #grid{}) -> #grid{}.
carve_passages_from(Cx, Cy, Grid) when is_record(Grid, grid) ->
    Directions = shuffle([?N, ?E, ?S, ?W]),    % N, E, S, W
    #grid{row = Row, col = Col, maze = Dict, xy = XY, opposite = Opposite} = Grid,
    lists:foldl(fun(Direction, Dict1) ->
        {DeltaX, DeltaY} = array:get(Direction, XY),
        Dx = Cx + DeltaX,
        Dy = Cy + DeltaY,
        if
            0 < Dx andalso Dx =< Row andalso 0 < Dy andalso Dy =< Col ->    % isn't out of range
                case dict:fetch({Dx, Dy}, Dict1) of    % if haven't visited yet
                    0 ->
                        NewDict = dict:store({Dx, Dy}, dict:fetch({Dx, Dy}, Dict1) bor array:get(Direction, Opposite),
                            dict:store({Cx, Cy}, dict:fetch({Cx, Cy}, Dict1) bor Direction, Dict1)),
                        carve_passages_from(Dx, Dy, Grid#grid{maze = NewDict});
                    _ ->
                        Dict1
                end;
            true ->
                Dict1
        end
    end, Dict, Directions).

-spec print_in_console(Maze :: dict(), Row :: integer(), Col :: integer()) -> ok.
print_in_console(Maze, Row, Col) ->
    io:format("~s~n", [string:concat(" ", string:copies(" _", Col))]),
    lists:foreach(fun(X) ->
        io:format(" |"),
        lists:foreach(fun(Y) ->
            %% guard expression
            case dict:fetch({X, Y}, Maze) band ?S of
                0 ->
                    io:format("_");
                _ ->
                    io:format(" ")
            end,
            case dict:fetch({X, Y}, Maze) band ?E of
                0 ->
                    io:format("|");
                _ ->
                    io:format(" ")
            end
        end, lists:seq(1, Col)),
        io:format("~n")
    end, lists:seq(1, Row)),
    ok.
