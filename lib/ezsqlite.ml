exception Sqlite_error of string

let _ =
    Callback.register_exception "sqlite error" (Sqlite_error "")

type value =
    | Null
    | Blob of string
    | Text of string
    | Double of float
    | Integer of Int64.t

type kind =
    | INTEGER
    | DOUBLE
    | TEXT
    | BLOB
    | NULL

exception Invalid_type

let is_null = function
    | Null -> true
    | _ -> false

let get_string = function
    | Null -> ""
    | Blob s | Text s -> s
    | Integer i -> Int64.to_string i
    | Double d -> string_of_float d

let get_float = function
    | Integer i -> Int64.to_float i
    | Double d -> d
    | Text s -> begin try float_of_string s
        with _ -> raise Invalid_type end
    | _ -> raise Invalid_type

let get_int = function
    | Integer i -> Int64.to_int i
    | Double d -> int_of_float d
    | Text s -> begin try int_of_string s
        with _ -> raise Invalid_type end
    | _ -> raise Invalid_type

let get_int64 = function
    | Integer i -> i
    | Double d -> Int64.of_float d
    | Text s -> begin try Int64.of_string s
        with _ -> raise Invalid_type end
    | _ -> raise Invalid_type

let get_bool = function
    | Integer 0L -> false
    | Integer _ -> true
    | Double 0. -> false
    | Double _ -> true
    | Text ("true"|"TRUE") -> true
    | Text ("false"|"FALSE") -> false
    | _ -> raise Invalid_type

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

(* DB *)

type t_handle
type t = {
    filename : string;
    mutable db : t_handle;
}

external _ezsqlite_db_load : string -> t_handle = "_ezsqlite_db_load"
external _ezsqlite_db_free : t_handle -> unit = "_ezsqlite_db_free"
external _ezsqlite_create_function :  t_handle -> string -> int -> unit = "_ezsqlite_db_create_function"

let load path =
    let db = {
        filename = path;
        db = _ezsqlite_db_load path;
    } in
    let _ = Gc.finalise (fun x ->
        _ezsqlite_db_free x.db) db in db

let auto_extension fn =
    Callback.register "auto extension" (fun x -> fn {filename = ""; db = x})

let commit_hook fn =
    Callback.register "commit hook" fn

let update_hook fn =
    Callback.register "update hook" fn

let create_function db name nargs fn =
    Callback.register name fn;
    _ezsqlite_create_function db.db name nargs

(* STMT *)

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

(* BIND *)
external _ezsqlite_bind_null : stmt_handle -> int -> unit = "_ezsqlite_bind_null"
external _ezsqlite_bind_blob : stmt_handle -> int -> string -> unit = "_ezsqlite_bind_blob"
external _ezsqlite_bind_text : stmt_handle -> int -> string -> unit = "_ezsqlite_bind_text"
external _ezsqlite_bind_double : stmt_handle -> int -> float -> unit = "_ezsqlite_bind_double"
external _ezsqlite_bind_int64 : stmt_handle -> int -> int64 -> unit = "_ezsqlite_bind_int64"

let bind stmt i = function
    | Null -> _ezsqlite_bind_null stmt.stmt i
    | Blob s -> _ezsqlite_bind_blob stmt.stmt i s
    | Text s -> _ezsqlite_bind_text stmt.stmt i s
    | Double d -> _ezsqlite_bind_double stmt.stmt i d
    | Integer d -> _ezsqlite_bind_int64 stmt.stmt i d

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
external _ezsqlite_data_count : stmt_handle -> int = "_ezsqlite_data_count"
external _ezsqlite_column_type : stmt_handle -> int -> int = "_ezsqlite_column_type"
external _ezsqlite_column_text : stmt_handle -> int -> string = "_ezsqlite_column_text"
external _ezsqlite_column_blob : stmt_handle -> int -> string = "_ezsqlite_column_blob"
external _ezsqlite_column_int64 : stmt_handle -> int -> int64 = "_ezsqlite_column_int64"
external _ezsqlite_column_int : stmt_handle -> int -> int = "_ezsqlite_column_int"
external _ezsqlite_column_double : stmt_handle -> int -> float = "_ezsqlite_column_double"
external _ezsqlite_column_name : stmt_handle -> int -> string = "_ezsqlite_column_name"
external _ezsqlite_database_name : stmt_handle -> int -> string = "_ezsqlite_database_name"
external _ezsqlite_table_name : stmt_handle -> int -> string = "_ezsqlite_table_name"
external _ezsqlite_origin_name : stmt_handle -> int -> string = "_ezsqlite_origin_name"

let data_count stmt =  _ezsqlite_data_count stmt.stmt

let column_text stmt i = if i < data_count stmt then _ezsqlite_column_text stmt.stmt i else raise Not_found

let column_blob stmt i = if i < data_count stmt then _ezsqlite_column_blob stmt.stmt i else raise Not_found

let column_int64 stmt i = if i < data_count stmt then _ezsqlite_column_int64 stmt.stmt i else raise Not_found

let column_int stmt i = if i < data_count stmt then _ezsqlite_column_int stmt.stmt i else raise Not_found

let column_double stmt i = if i < data_count stmt then _ezsqlite_column_double stmt.stmt i else raise Not_found

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
    let dst = ref [] in
    while step stmt do
        dst := fn stmt::!dst
    done; List.rev !dst

let fold stmt fn acc =
    let dst = ref acc in
    while step stmt do
        dst := fn stmt !dst
    done; !dst

let run ?bind:(bind=[]) db s fn =
    let x = prepare db s in
    let () = bind_list x bind in
    map x fn

module Backup = struct
    type backup_handle
    type backup = {
        backup : backup_handle;
    }

    external _ezsqlite_backup_init : t_handle -> string -> t_handle -> string -> backup_handle = "_ezsqlite_backup_init"
    external _ezsqlite_backup_finish : backup_handle -> unit = "_ezsqlite_backup_finish"
    external _ezsqlite_backup_step : backup_handle -> int ->  bool = "_ezsqlite_backup_step"
    external _ezsqlite_backup_pagecount : backup_handle -> int = "_ezsqlite_backup_pagecount"
    external _ezsqlite_backup_remaining : backup_handle -> int = "_ezsqlite_backup_remaining"

    let init dst dstName src srcName =
        let b = {
            backup = _ezsqlite_backup_init dst.db dstName src.db srcName
        } in
        let _ = Gc.finalise (fun x ->
            _ezsqlite_backup_finish(x.backup)) in b

    let step b n =
        _ezsqlite_backup_step b.backup n

    let remaining b =
        _ezsqlite_backup_remaining b.backup

    let pagecount b =
        _ezsqlite_backup_pagecount b.backup

end

