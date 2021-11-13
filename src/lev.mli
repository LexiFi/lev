(** Thin wrapper around Marc Lehmann's libev library.

libev is small and performant, but this comes at a cost of a few rough edges
and a higher learning curve. Lev tries to make it more usable, but it does not
try to invent a new API. You should be somewhat familiar with async IO and
libev's quirks to use this library effectively.

Some things to keep in mind:

  - It is your responsibility to make sure that fd's are non blocking
  - Watchers are mutable and the event loop will mutate them.
  - All actual read, write, accept, etc. calls are outside the scope of this
    library.

 *)

val ev_version : unit -> int * int

module Timestamp : sig
  type t

  val sleep : t -> unit

  val of_float : float -> t

  val to_float : t -> float
end

module Loop : sig
  type t

  val now : t -> Timestamp.t

  val default : unit -> t
  (** Use this one unless you have a strong reason. The default event loop is
      the only one that can handle child watchers. *)

  val create : unit -> t

  val destroy : t -> unit

  val now_update : t -> unit

  val run :
    t -> [ `No_wait | `Once ] -> [ `No_more_active_watchers | `Otherwise ]

  val depth : t -> int

  val break : t -> [ `Cancel | `One | `All ] -> unit
end

module type Watcher = sig
  type t

  val start : t -> Loop.t -> unit

  val stop : t -> Loop.t -> unit
end

module Periodic : sig
  include Watcher

  type kind =
    | Regular of { offset : Timestamp.t; interval : Timestamp.t option }
    | Custom of (t -> now:Timestamp.t -> Timestamp.t)

  val create : (t -> Loop.t -> unit) -> kind -> t
end

module Io : sig
  module Event : sig
    type t = Read | Write

    module Set : sig
      type t

      type event

      val mem : t -> event -> bool

      val create : ?read:bool -> ?write:bool -> unit -> t
    end
    with type event := t
  end

  include Watcher

  val fd : t -> Unix.file_descr

  val create :
    (t -> Loop.t -> Event.Set.t -> unit) -> Unix.file_descr -> Event.Set.t -> t
end

module Timer : sig
  include Watcher

  val create : ?repeat:float -> after:float -> (t -> Loop.t -> unit) -> t

  val remaining : t -> Loop.t -> Timestamp.t

  val again : t -> Loop.t -> unit
end

module Stat : sig
  include Watcher

  val create : ?interval:Timestamp.t -> (Loop.t -> unit) -> path:string -> t
end

module Child : sig
  include Watcher

  val create :
    (t -> Loop.t -> unit) ->
    pid:[ `Any | `Pid of int ] ->
    [ `Terminate | `Terminate_stop_or_continue ] ->
    t
end

module Signal : sig
  include Watcher

  val create : (Loop.t -> t -> unit) -> signal:int -> t
end

module Cleanup : sig
  include Watcher

  val create : (Loop.t -> unit) -> t
end
