type 'a bot_or_not =
| Bot
| Not_bot of 'a

type maybe_bool =
| Sure_value of bool
| Maybe

type 'a top_or_not =
| Top
| Not_top of 'a
