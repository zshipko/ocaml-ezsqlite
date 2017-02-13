exception Sqlite_error of string

(** sqlite3 handle *)
type t

(** Load database from file *)
val load : string -> t

(** sqlite3_stmt handle*)
type stmt

(** Prepare an SQL statement *)
val prepare : t -> string -> stmt

(** Reset a statement -- this does not unbind bound values *)
val reset : stmt -> unit

(** Reset and clear bindings*)
val clear : stmt -> unit

(** Datatypes that can be stored by SQLite *)
type value_handle
type value =
    | Null
    | Blob of string
    | Text of string
    | Double of float
    | Integer of Int64.t
    | Value of value_handle

type kind =
    | INTEGER
    | DOUBLE
    | TEXT
    | BLOB
    | NULL

val bind : stmt -> int -> value -> unit
val bind_dict : stmt -> (string * value) list -> unit
val bind_list : stmt -> value list -> unit

(** Get the number of parameters *)
val parameter_count : stmt -> int

(** Get the index of a named parameter *)
val parameter_index : stmt -> string -> int

val column_text : stmt -> int -> string
val column_blob : stmt -> int -> string
val column_int64 : stmt -> int -> int64
val column_double : stmt -> int -> float

(** Get a value by index *)
val column : stmt -> int -> value

(** Get the column as a blob handler *)
(*val open_blob : t -> int -> int64 -> Blob.t*)

(** Execute a statement that returns no response *)
val exec : stmt -> unit

(** Iterate over each step *)
val iter : stmt -> (stmt -> unit) -> unit

(** Iterate over each step returning a value each time *)
val map : stmt -> (stmt -> 'a) -> 'a list

val fold : stmt -> (stmt -> 'a -> 'a) -> 'a -> 'a

(** Get each column as an array *)
val data : stmt -> value array

(** Get each column as a list of tuples mapping from string to value *)
val dict : stmt -> (string * value) list

(** Get a value's type by index *)
val column_type : stmt -> int -> kind

(** Get the number of columns with data *)
val data_count : stmt -> int

(*(** Get the name of the database a statement is attached to *)
val database_name : t -> string

(** Get the name of a table a statement is attached to *)
val table_name : t -> string*)

(* Get the name of a column by index *)
val column_name : stmt -> int -> string
