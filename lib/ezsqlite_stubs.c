#include "sqlite3.h"

#include <caml/mlvalues.h>
#include <caml/custom.h>
#include <caml/alloc.h>
#include <caml/intext.h>
#include <caml/fail.h>
#include <caml/callback.h>
#include <caml/memory.h>

#define WRAP(x) do{if (x != SQLITE_OK){\
    sqlite3_error(x);\
    return Val_unit;\
}}while(0)

void sqlite3_error (int i) {
    caml_raise_with_string(*caml_named_value("sqlite3 exception"), sqlite3_errstr(i));
}

// Db

value _ezsqlite_db_load (value path){
    sqlite3 *handle = NULL;
    WRAP(sqlite3_open (String_val(path), &handle));
    return (value)handle;
}

value _ezsqlite_db_free (value db){
    sqlite3 *handle = (sqlite3*)db;
    WRAP(sqlite3_close(handle));
    return Val_unit;
}

// Stmt
value _ezsqlite_stmt_prepare (value db, value s) {
    sqlite3 *handle = (sqlite3*)db;
    sqlite3_stmt *stmt = NULL;
    WRAP(sqlite3_prepare_v2(handle, String_val(s), caml_string_length(s), &stmt, NULL));
    return (value)stmt;
}

value _ezsqlite_stmt_finalize (value stmt) {
    WRAP(sqlite3_finalize((sqlite3_stmt*)stmt));
    return Val_unit;
}

value _ezsqlite_stmt_step (value stmt){
    int res = sqlite3_step ((sqlite3_stmt*)stmt);
    switch (res){
    case SQLITE_ROW:
        return Val_true;
    case SQLITE_DONE:
        return Val_false;
    default:
        WRAP(res);
        return Val_false;
    }
}

value _ezsqlite_stmt_reset (value stmt) {
    WRAP(sqlite3_reset((sqlite3_stmt*)stmt));
    return Val_unit;
}

value _ezsqlite_stmt_clear_bindings (value stmt) {
    WRAP(sqlite3_clear_bindings((sqlite3_stmt*)stmt));
    return Val_unit;
}


value _ezsqlite_stmt_parameter_count (value stmt) {
    return Val_int (sqlite3_bind_parameter_count ((sqlite3_stmt*)stmt));
}

value _ezsqlite_stmt_parameter_index (value stmt, value name) {
    return Val_int (sqlite3_bind_parameter_index ((sqlite3_stmt*)stmt, String_val(name)));
}

value _ezsqlite_bind_null (value stmt, value i){
    WRAP(sqlite3_bind_null((sqlite3_stmt*)stmt, Int_val(i)));
    return Val_unit;
}

value _ezsqlite_bind_blob (value stmt, value i, value s){
    WRAP(sqlite3_bind_blob((sqlite3_stmt*)stmt, Int_val(i), String_val(s), caml_string_length(s), SQLITE_TRANSIENT));
    return Val_unit;
}

value _ezsqlite_bind_text (value stmt, value i, value s){
    WRAP(sqlite3_bind_text((sqlite3_stmt*)stmt, Int_val(i), String_val(s), caml_string_length(s), SQLITE_TRANSIENT));
    return Val_unit;
}

value _ezsqlite_bind_int64 (value stmt, value i, value b){
    WRAP(sqlite3_bind_int64((sqlite3_stmt*)stmt, Int_val(i), Int64_val(b)));
    return Val_unit;
}

value _ezsqlite_bind_double (value stmt, value i, value b){
    WRAP(sqlite3_bind_double((sqlite3_stmt*)stmt, Int_val(i), Double_val(b)));
    return Val_unit;
}

value _ezsqlite_bind_value (value stmt, value i, value b){
    WRAP(sqlite3_bind_value((sqlite3_stmt*)stmt, Int_val(i), (sqlite3_value*)b));
    return Val_unit;
}

value _ezsqlite_data_count (value stmt){
    return Int_val(sqlite3_data_count((sqlite3_stmt*)stmt));
}

value _ezsqlite_column_type (value stmt, value i){
    return Int_val(sqlite3_column_type((sqlite3_stmt*)stmt, Int_val(i)));
}

value _ezsqlite_column_text (value stmt, value i){
    CAMLparam2(stmt, i);
    CAMLlocal1(s);
    s = caml_copy_string (sqlite3_column_text ((sqlite3_stmt*)stmt, Int_val(i)));
    CAMLreturn(s);
}

value _ezsqlite_column_blob (value stmt, value i){
    CAMLparam2(stmt, i);
    CAMLlocal1(s);
    s = caml_copy_string (sqlite3_column_blob ((sqlite3_stmt*)stmt, Int_val(i)));
    CAMLreturn(s);
}

value _ezsqlite_column_int64 (value stmt, value i){
    CAMLparam2(stmt, i);
    CAMLlocal1(d);
    d = caml_copy_int64(sqlite3_column_int64((sqlite3_stmt*)stmt, Int_val(i)));
    CAMLreturn(d);
}

value _ezsqlite_column_double (value stmt, value i){
    CAMLparam2(stmt, i);
    CAMLlocal1(d);
    d = caml_copy_double(sqlite3_column_double((sqlite3_stmt*)stmt, Int_val(i)));
    CAMLreturn(d);
}

value _ezsqlite_column_value (value stmt, value i){
    return (value)sqlite3_column_value((sqlite3_stmt*)stmt, Int_val(i));
}

value _ezsqlite_column_name (value stmt, value i){
    CAMLparam2(stmt, i);
    CAMLlocal1(s);
    s = caml_copy_string (sqlite3_column_name ((sqlite3_stmt*)stmt, Int_val(i)));
    CAMLreturn(s);
}
