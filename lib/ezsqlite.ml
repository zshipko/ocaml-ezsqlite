exception Sqlite_error of string

let _ =
    Callback.register_exception "sqlite error" (Sqlite_error "")

type t_handle
type t = {
    filename : string;
    mutable db : t_handle;
}

external _ezsqlite_db_load : string -> t_handle = "_ezsqlite_db_load"
external _ezsqlite_db_free : t_handle -> unit = "_ezsqlite_db_free"

let load path =
    let db = {
        filename = path;
        db = _ezsqlite_db_load path;
    } in
    let _ = Gc.finalise (fun x ->
        _ezsqlite_db_free x.db) db in db

type stmt_handle
type stmt = {
    raw : string;
    mutable _db : t;
    mutable stmt : stmt_handle;
}

external _ezsqlite_stmt_prepare : t_handle -> string -> stmt_handle = "_ezsqlite_stmt_prepare"
external _ezsqlite_stmt_finalize : stmt_handle -> unit = "_ezsqlite_stmt_finalize"
external _ezsqlite_stmt_step : stmt_handle -> bool = "_ezsqlite_stmt_step"
external _ezsqlite_stmt_reset : stmt_handle -> unit = "_ezsqlite_stmt_reset"
external _ezsqlite_stmt_clear_bindings : stmt_handle -> unit = "_ezsqlite_stmt_clear_bindings"

let prepare db s =
    let stmt = {
        raw = s;
        _db = db;
        stmt = _ezsqlite_stmt_prepare db.db s;
    } in
    let _ = Gc.finalise (fun x ->
        _ezsqlite_stmt_finalize x.stmt) stmt in stmt

let step stmt = _ezsqlite_stmt_step stmt.stmt
let reset stmt = _ezsqlite_stmt_reset stmt.stmt
let clear_bindings stmt = _ezsqlite_stmt_clear_bindings stmt.stmt

let clear stmt =
    reset stmt;
    clear_bindings stmt

external _ezsqlite_stmt_parameter_count : stmt_handle -> int = "_ezsqlite_stmt_parameter_count"
external _ezsqlite_stmt_parameter_index : stmt_handle -> string -> int  = "_ezsqlite_stmt_parameter_index"
let parameter_count stmt = _ezsqlite_stmt_parameter_count stmt.stmt
let parameter_index stmt = _ezsqlite_stmt_parameter_index stmt.stmt

type value_handle
type value =
    | Null
    | Blob of string
    | Text of string
    | Double of float
    | Integer of Int64.t
    | Value of value_handle

(* BIND *)

external _ezsqlite_bind_null : stmt_handle -> int -> unit = "_ezsqlite_bind_null"
external _ezsqlite_bind_blob : stmt_handle -> int -> string -> unit = "_ezsqlite_bind_blob"
external _ezsqlite_bind_text : stmt_handle -> int -> string -> unit = "_ezsqlite_bind_text"
external _ezsqlite_bind_double : stmt_handle -> int -> float -> unit = "_ezsqlite_bind_double"
external _ezsqlite_bind_int64 : stmt_handle -> int -> int64 -> unit = "_ezsqlite_bind_int64"
external _ezsqlite_bind_value : stmt_handle -> int -> value_handle -> unit = "_ezsqlite_bind_value"

let bind stmt i = function
    | Null -> _ezsqlite_bind_null stmt.stmt i
    | Blob s -> _ezsqlite_bind_blob stmt.stmt i s
    | Text s -> _ezsqlite_bind_text stmt.stmt i s
    | Double d -> _ezsqlite_bind_double stmt.stmt i d
    | Integer d -> _ezsqlite_bind_int64 stmt.stmt i d
    | Value d -> _ezsqlite_bind_value stmt.stmt i d

let bind_dict stmt dict =
    List.iter (fun (k, v) ->
        let i = parameter_index stmt k in
        if i > 0 then
            bind stmt i v) dict

let bind_list stmt list =
    let len = parameter_count stmt in
    try
        List.iteri (fun i x ->
            if i >= len then failwith "end"
            else bind stmt (i + 1) x) list
    with _ -> ()

(* COLUMN *)

type kind =
    | INTEGER
    | DOUBLE
    | TEXT
    | BLOB
    | NULL

let kind_of_int = function
    | 1 -> INTEGER
    | 2 -> DOUBLE
    | 3 -> TEXT
    | 4 -> BLOB
    | n -> NULL

let int_of_kind = function
    | INTEGER -> 1
    | DOUBLE -> 1
    | TEXT -> 3
    | BLOB -> 4
    | NULL -> 5

external _ezsqlite_data_count : stmt_handle -> int = "_ezsqlite_data_count"
external _ezsqlite_column_type : stmt_handle -> int -> int = "_ezsqlite_column_type"
external _ezsqlite_column_text : stmt_handle -> int -> string = "_ezsqlite_column_text"
external _ezsqlite_column_blob : stmt_handle -> int -> string = "_ezsqlite_column_blob"
external _ezsqlite_column_int64 : stmt_handle -> int -> int64 = "_ezsqlite_column_int64"
external _ezsqlite_column_double : stmt_handle -> int -> float = "_ezsqlite_column_double"
external _ezsqlite_column_value : stmt_handle -> int -> value_handle = "_ezsqlite_column_value"
external _ezsqlite_column_name : stmt_handle -> int -> string = "_ezsqlite_column_name"
external _ezsqlite_database_name : stmt_handle -> int -> string = "_ezsqlite_database_name"
external _ezsqlite_table_name : stmt_handle -> int -> string = "_ezsqlite_table_name"
external _ezsqlite_origin_name : stmt_handle -> int -> string = "_ezsqlite_origin_name"

let data_count stmt =  _ezsqlite_data_count stmt.stmt

let column_text stmt i = if i < data_count stmt then _ezsqlite_column_text stmt.stmt i else raise Not_found

let column_blob stmt i = if i < data_count stmt then _ezsqlite_column_blob stmt.stmt i else raise Not_found

let column_int64 stmt i = if i < data_count stmt then _ezsqlite_column_int64 stmt.stmt i else raise Not_found

let column_double stmt i = if i < data_count stmt then _ezsqlite_column_double stmt.stmt i else raise Not_found

let column_value stmt i = if i > data_count stmt then raise Not_found else _ezsqlite_column_value stmt.stmt i

let column_type stmt i = if i > data_count stmt then raise Not_found else  kind_of_int (_ezsqlite_column_type stmt.stmt i)

let column stmt i =
    match column_type stmt i with
        | INTEGER -> Integer (column_int64 stmt i)
        | DOUBLE -> Double (column_double stmt i)
        | TEXT -> Text (column_text stmt i)
        | BLOB -> Blob (column_blob stmt i)
        | NULL -> Null

let data stmt =
    let len = data_count stmt in
    let dst = Array.make len Null in
    for i = 0 to len - 1 do
        dst.(i) <- column stmt i
    done; dst

let column_name stmt n = if n < data_count stmt then _ezsqlite_column_name stmt.stmt n else raise Not_found
let database_name stmt n = if n < data_count stmt then _ezsqlite_database_name stmt.stmt n else raise Not_found
let table_name stmt n = if n < data_count stmt then _ezsqlite_table_name stmt.stmt n else raise Not_found
let origin_name stmt n = if n < data_count stmt then _ezsqlite_origin_name stmt.stmt n else raise Not_found
let database stmt = stmt._db

let dict stmt =
    data stmt |> Array.to_list |> List.mapi (fun i x ->
        column_name stmt i, x)

let exec stmt =
    while step stmt do () done

let iter stmt fn =
    while step stmt do fn stmt done

let map stmt fn =
    if step stmt then
        let dst = ref [] in
        while step stmt do
            dst := fn stmt::!dst
        done; List.rev !dst
    else []

let fold stmt fn acc =
    if step stmt then
        let dst = ref acc in
        while step stmt do
            dst := fn stmt !dst
        done; !dst
    else acc
