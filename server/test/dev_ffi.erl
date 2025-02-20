-module(dev_ffi).

-export([identity/1, atomic_load/1]).

% Used in coercion.
identity(X) ->
    X.

atomic_load(Modules) ->
    case code:atomic_load(Modules) of
        ok ->
            {ok, nil};
        otherwise ->
            otherwise
    end.
