%{

(*
 Portions Copyright (c) 2013-2014, Grégoire Henry, OCamlPro
 
 Portions Copyright (c) 1996-2013, PostgreSQL Global Development Group
 
 Portions Copyright (c) 1994, The Regents of the University of California
 
 Permission to use, copy, modify, and distribute this software and its
 documentation for any purpose, without fee, and without a written agreement
 is hereby granted, provided that the above copyright notice and this
 paragraph and the following two paragraphs appear in all copies.
 
 IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING
 LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATIONS TO
 PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
*)

module Loc = Sql_loc
open Sql

let mkloc value loc = { Loc.value; loc }
type error =
  | Column_number_mismatch

exception EError of error * Loc.t
let eerror loc e = raise (EError (e, loc))

let pp_print_error ppf =
  let open Format in
  function
  | Column_number_mismatch ->
      fprintf ppf "number of columns does not match number of values"

%}

%token <string> BCONST
%token <float> FCONST
%token <Z.t> ICONST
%token <string> SCONST

%token COMMA
%token SEMI
%token COLON
%token DOT
%token LPAREN RPAREN
%token LBRACKET RBRACKET
%token PLUS MINUS
%token CARET
%token STAR DIV PERCENT
%token LT GT EQ
%token TYPECAST
%token COLON_EQUALS

%token <string> Op
%token <string> IDENT
%token <int> PARAM

%token EOF

%token NULLS_LAST NULLS_FIRST
%token WITH_TIME

(* Precedence *)

%nonassoc    SET                (* see relation_expr_opt_alias *)
%left        UNION EXCEPT
%left        INTERSECT
%left        OR
%left        AND
%right       NOT
%right       EQ
%nonassoc    LT GT
%nonassoc    LIKE ILIKE SIMILAR
%nonassoc    ESCAPE
(* %nonassoc    OVERLAPS *) (* MENHIR *)
%nonassoc    BETWEEN
%nonassoc    IN_P
%left        POSTFIXOP        (* dummy for postfix Op rules *)
(*
 * To support target_el without AS, we must give IDENT an explicit priority
 * between POSTFIXOP and Op.  We can safely assign the same priority to
 * various unreserved keywords as needed to resolve ambiguities (this can't
 * have any bad effects since obviously the keywords will still behave the
 * same as if they weren't keywords).  We need to do this for PARTITION,
 * RANGE, ROWS to support opt_existing_window_name; and for RANGE, ROWS
 * so that they can follow a_expr without creating postfix-operator problems;
 * and for NULL so that it can follow b_expr in col_qual_list without creating
 * postfix-operator problems.
 *
 * The frame_bound productions UNBOUNDED PRECEDING and UNBOUNDED FOLLOWING
 * are even messier: since UNBOUNDED is an unreserved keyword (per spec!),
 * there is no principled way to distinguish these from the productions
 * a_expr PRECEDING/FOLLOWING.  We hack this up by giving UNBOUNDED slightly
 * lower precedence than PRECEDING and FOLLOWING.  At present this doesn't
 * appear to cause UNBOUNDED to be treated differently from other unreserved
 * keywords anywhere else in the grammar, but it's definitely risky.  We can
 * blame any funny behavior of UNBOUNDED on the SQL standard, though.
 *)
%nonassoc    UNBOUNDED        (* ideally should have same precedence as IDENT *)
%nonassoc    IDENT NULL_P PARTITION RANGE ROWS PRECEDING FOLLOWING
%left        Op OPERATOR      (* multi-character ops and user-defined operators *)
%nonassoc    NOTNULL
%nonassoc    ISNULL
%nonassoc    IS               (* sets precedence for IS NULL, etc *)
%left        PLUS MINUS
%left        STAR DIV PERCENT
%left        CARET
(* Unary Operators *)
%left        AT               (* sets precedence for AT TIME ZONE *)
%left        COLLATE
%right       UMINUS
(* %left        LBRACKET RBRACKET *) (* MENHIR *)
%left        LPAREN RPAREN
%left        TYPECAST
(* %left        DOT *) (* MENHIR *)
(*
 * These might seem to be low-precedence, but actually they are not part
 * of the arithmetic hierarchy at all in their use as JOIN operators.
 * We make them high-precedence to support their use as function names.
 * They wouldn't be given a precedence at all, were it not that we need
 * left-associativity among the JOIN rules themselves.
 *)
%left        JOIN CROSS LEFT FULL RIGHT INNER_P NATURAL
(* kluge to keep xml_whitespace_option from causing shift/reduce conflicts *)
%right       PRESERVE STRIP_P

%start <Sql.t list> stmtblock

%%

(*
 *    The target production for the whole parse.
 *)
stmtblock:
| stmts = separated_list(SEMI +,stmt) EOF { stmts }

stmt:
| alter_event_trig_stmt
| alter_database_stmt
| alter_database_set_stmt
| alter_default_privileges_stmt
| alter_domain_stmt
| alter_enum_stmt
| alter_extension_stmt
| alter_extension_contents_stmt
| alter_fdw_stmt
| alter_foreign_server_stmt
| alter_foreign_table_stmt
| alter_function_stmt
| alter_group_stmt
| alter_object_schema_stmt
| alter_owner_stmt
| alter_seq_stmt
| alter_table_stmt
| alter_composite_type_stmt
| alter_role_set_stmt
| alter_role_stmt
| alter_tSConfiguration_stmt
| alter_tSDictionary_stmt
| alter_user_mapping_stmt
| alter_user_set_stmt
| alter_user_stmt
| analyze_stmt
| check_point_stmt
| close_portal_stmt
| cluster_stmt
| comment_stmt
| constraints_set_stmt
| copy_stmt
| create_as_stmt
| create_assert_stmt
| create_cast_stmt
| create_conversion_stmt
| create_domain_stmt
| create_extension_stmt
| create_fdw_stmt
| create_foreign_server_stmt
| create_foreign_table_stmt
| create_function_stmt
| create_group_stmt
| create_mat_view_stmt
| create_op_class_stmt
| create_op_family_stmt
| alter_op_family_stmt
| create_pLang_stmt
| create_schema_stmt
| create_seq_stmt
| create_stmt
| create_table_space_stmt
| create_trig_stmt
| create_event_trig_stmt
| create_role_stmt
| create_user_stmt
| create_user_mapping_stmt
| createdb_stmt
| deallocate_stmt
| declare_cursor_stmt
| define_stmt
    { Not_implemented (Loc.loc $startpos $endpos) }
| stmt = delete_stmt
    { Delete stmt }
| discard_stmt
| do_stmt
| drop_assert_stmt
| drop_cast_stmt
| drop_fdw_stmt
| drop_foreign_server_stmt
| drop_group_stmt
| drop_op_class_stmt
| drop_op_family_stmt
| drop_owned_stmt
| drop_pLang_stmt
| drop_rule_stmt
| drop_stmt
| drop_table_space_stmt
| drop_trig_stmt
| drop_role_stmt
| drop_user_stmt
| drop_user_mapping_stmt
| dropdb_stmt
| execute_stmt
| explain_stmt
| fetch_stmt
| grant_stmt
| grant_role_stmt
| index_stmt
    { Not_implemented (Loc.loc $startpos $endpos) }
| stmt = insert_stmt
    { Insert stmt }
| listen_stmt
| refresh_mat_view_stmt
| load_stmt
| lock_stmt
| notify_stmt
| prepare_stmt
| reassign_owned_stmt
| reindex_stmt
| remove_aggr_stmt
| remove_func_stmt
| remove_oper_stmt
| rename_stmt
| revoke_stmt
| revoke_role_stmt
| rule_stmt
| sec_label_stmt
    { Not_implemented (Loc.loc $startpos $endpos) }
| stmt = select_stmt
    { Select stmt }
| transaction_stmt
| truncate_stmt
| unlisten_stmt
    { Not_implemented (Loc.loc $startpos $endpos) }
| stmt = update_stmt
    { Update stmt }
| vacuum_stmt
| variable_reset_stmt
| variable_set_stmt
| variable_show_stmt
| view_stmt
    { Not_implemented (Loc.loc $startpos $endpos) }

(*****************************************************************************
 *
 * Create a new Postgres DBMS role
 *
 *****************************************************************************)

create_role_stmt:
| CREATE ROLE role_id opt_with opt_role_list
{ }

opt_with:
| WITH
| (* EMPTY *)
{ }

(*
 * Options for CREATE ROLE and ALTER ROLE (also used by CREATE/ALTER USER
 * for backwards compatibility).  Note: the only option required by SQL99
 * is "WITH ADMIN name".
 *)
opt_role_list:
| opt_role_list create_opt_role_elem
| (* EMPTY *)
{ }

alter_opt_role_list:
| alter_opt_role_list alter_opt_role_elem
| (* EMPTY *)
{ }

alter_opt_role_elem:
| PASSWORD sconst
| PASSWORD NULL_P
| ENCRYPTED PASSWORD sconst
| UNENCRYPTED PASSWORD sconst
| INHERIT
| CONNECTION LIMIT signed_iconst
| VALID UNTIL sconst
(*    Supported but not documented for roles, for use by ALTER GROUP. *)
| USER name_list
| IDENT
{ }

create_opt_role_elem:
| alter_opt_role_elem
(* The following are not supported by ALTER ROLE/USER/GROUP *)
| SYSID iconst
| ADMIN name_list
| ROLE name_list
| IN_P ROLE name_list
| IN_P GROUP_P name_list
{ }

(*****************************************************************************
 *
 * Create a new Postgres DBMS user (role with implied login ability)
 *
 *****************************************************************************)

create_user_stmt:
| CREATE USER role_id opt_with opt_role_list
{ }

(*****************************************************************************
 *
 * Alter a postgresql DBMS role
 *
 *****************************************************************************)

alter_role_stmt:
| ALTER ROLE role_id opt_with alter_opt_role_list
{ }

opt_in_database:
| IN_P DATABASE database_name
| (* EMPTY *)
{ }

alter_role_set_stmt:
| ALTER ROLE role_id opt_in_database set_reset_clause
| ALTER ROLE ALL opt_in_database set_reset_clause
{ }


(*****************************************************************************
 *
 * Alter a postgresql DBMS user
 *
 *****************************************************************************)

alter_user_stmt:
| ALTER USER role_id opt_with alter_opt_role_list
{ }

alter_user_set_stmt:
| ALTER USER role_id set_reset_clause
{ }

(*****************************************************************************
 *
 * Drop a postgresql DBMS role
 *
 * XXX Ideally this would have CASCADE/RESTRICT options, but since a role
 * might own objects in multiple databases, there is presently no way to
 * implement either cascading or restricting.  Caveat DBA.
 *****************************************************************************)

drop_role_stmt:
| DROP ROLE name_list
| DROP ROLE IF_P EXISTS name_list
{ }

(*****************************************************************************
 *
 * Drop a postgresql DBMS user
 *
 * XXX Ideally this would have CASCADE/RESTRICT options, but since a user
 * might own objects in multiple databases, there is presently no way to
 * implement either cascading or restricting.  Caveat DBA.
 *****************************************************************************)

drop_user_stmt:
| DROP USER name_list
| DROP USER IF_P EXISTS name_list
{ }

(*****************************************************************************
 *
 * Create a postgresql group (role without login ability)
 *
 *****************************************************************************)

create_group_stmt:
| CREATE GROUP_P role_id opt_with opt_role_list
{ }

(*****************************************************************************
 *
 * Alter a postgresql group
 *
 *****************************************************************************)

alter_group_stmt:
| ALTER GROUP_P role_id add_drop USER name_list
{ }


add_drop:
| ADD_P
| DROP
{ }


(*****************************************************************************
 *
 * Drop a postgresql group
 *
 * XXX see above notes about cascading DROP USER; groups have same problem.
 *****************************************************************************)

drop_group_stmt:
| DROP GROUP_P name_list
| DROP GROUP_P IF_P EXISTS name_list
{ }



(*****************************************************************************
 *
 * Manipulate a schema
 *
 *****************************************************************************)

create_schema_stmt:
| CREATE SCHEMA opt_schema_name AUTHORIZATION role_id opt_schema_elt_list
| CREATE SCHEMA col_id opt_schema_elt_list
| CREATE SCHEMA IF_P NOT EXISTS opt_schema_name AUTHORIZATION role_id opt_schema_elt_list
| CREATE SCHEMA IF_P NOT EXISTS col_id opt_schema_elt_list
{ }


opt_schema_name:
| col_id
| (* EMPTY *)
{ }

opt_schema_elt_list:
| opt_schema_elt_list schema_stmt
| (* EMPTY *)
{ }


(*
 *    schema_stmt are the ones that can show up inside a CREATE SCHEMA
 *    statement (in addition to by themselves).
 *)
schema_stmt:
| create_stmt
| index_stmt
| create_seq_stmt
| create_trig_stmt
| grant_stmt
| view_stmt
{ }


(*****************************************************************************
 *
 * Set PG internal variable
 *      SET name TO 'var_value'
 * Include SQL syntax (thomas 1997-10-22):
 *      SET TIME ZONE 'var_value'
 *
 *****************************************************************************)

variable_set_stmt:
| SET set_rest
| SET LOCAL set_rest
| SET SESSION set_rest
{ }


set_rest:
| TRANSACTION transaction_mode_list
| SESSION CHARACTERISTICS AS TRANSACTION transaction_mode_list
| set_rest_more
{ }

set_rest_more:    (* Generic SET syntaxes: *)
| var_name TO var_list
| var_name EQ var_list
| var_name TO DEFAULT
| var_name EQ DEFAULT
| var_name FROM CURRENT_P
(* Special syntaxes mandated by SQL standard: *)
| TIME ZONE zone_value
| CATALOG_P sconst
| SCHEMA sconst
| NAMES opt_encoding
| ROLE non_reserved_word_or_sconst
| SESSION AUTHORIZATION non_reserved_word_or_sconst
| SESSION AUTHORIZATION DEFAULT
| XML_P OPTION document_or_content
(* Special syntaxes invented by Postgre_sQL: *)
| TRANSACTION SNAPSHOT sconst
{ }


var_name:
| col_id
| var_name DOT col_id
{ }


var_list:
| var_value
| var_list COMMA var_value
{ }

var_value:
| opt_boolean_or_string
| numeric_only
{ }


iso_level:
| READ UNCOMMITTED
| READ COMMITTED
| REPEATABLE READ
| SERIALIZABLE
{ }

opt_boolean_or_string:
| TRUE_P
| FALSE_P
| ON
(*
 * OFF is also accepted as a boolean value, but is handled by
 * the non_reserved_word rule.  The action for booleans and strings
 * is the same, so we don't need to distinguish them here.
 *)
| non_reserved_word_or_sconst
{ }

(* Timezone values can be:
 * - a string such as 'pst8pdt'
 * - an identifier such as "pst8pdt"
 * - an integer or floating point number
 * - a time interval per SQL99
 * col_id gives reduce/reduce errors against const_interval and LOCAL,
 * so use IDENT (meaning we reject anything that is a key word).
 *)
zone_value:
| sconst
| IDENT
| const_interval sconst opt_interval
| const_interval LPAREN iconst RPAREN sconst opt_interval
| numeric_only
| DEFAULT
| LOCAL
{ }

opt_encoding:
| sconst
| DEFAULT
| (* EMPTY *)
{ }

non_reserved_word_or_sconst:
| non_reserved_word
| sconst
{ }

variable_reset_stmt:
| RESET var_name
| RESET TIME ZONE
| RESET TRANSACTION ISOLATION LEVEL
| RESET SESSION AUTHORIZATION
| RESET ALL
{ }


(* set_reset_clause allows SET or RESET without LOCAL *)
set_reset_clause:
| SET set_rest
| variable_reset_stmt
{ }

(* set_reset_clause allows SET or RESET without LOCAL *)
function_set_reset_clause:
| SET set_rest_more
| variable_reset_stmt
{ }


variable_show_stmt:
| SHOW var_name
| SHOW TIME ZONE
| SHOW TRANSACTION ISOLATION LEVEL
| SHOW SESSION AUTHORIZATION
| SHOW ALL
{ }



constraints_set_stmt:
| SET CONSTRAINTS constraints_set_list constraints_set_mode
{ }


constraints_set_list:
| ALL
| qualified_name_list
{ }

constraints_set_mode:
| DEFERRED
| IMMEDIATE
{ }


(*
 * Checkpoint statement
 *)
check_point_stmt:
| CHECKPOINT
{ }



(*****************************************************************************
 *
 * DISCARD
 *
 *****************************************************************************)

discard_stmt:
| DISCARD ALL
| DISCARD TEMP
| DISCARD TEMPORARY
| DISCARD PLANS
{ }



(*****************************************************************************
 *
 *    ALTER [ TABLE | INDEX | SEQUENCE | VIEW | MATERIALIZED VIEW ] variations
 *
 * Note: we accept all subcommands for each of the five variants, and sort
 * out what's really legal at execution time.
 *****************************************************************************)

alter_table_stmt:
| ALTER TABLE relation_expr alter_table_cmds
| ALTER TABLE IF_P EXISTS relation_expr alter_table_cmds
| ALTER INDEX qualified_name alter_table_cmds
| ALTER INDEX IF_P EXISTS qualified_name alter_table_cmds
| ALTER SEQUENCE qualified_name alter_table_cmds
| ALTER SEQUENCE IF_P EXISTS qualified_name alter_table_cmds
| ALTER VIEW qualified_name alter_table_cmds
| ALTER VIEW IF_P EXISTS qualified_name alter_table_cmds
| ALTER MATERIALIZED VIEW qualified_name alter_table_cmds
| ALTER MATERIALIZED VIEW IF_P EXISTS qualified_name alter_table_cmds
{ }


alter_table_cmds:
| alter_table_cmd
| alter_table_cmds COMMA alter_table_cmd
{ }

alter_table_cmd:
(* ALTER TABLE <name> ADD <coldef> *)
| ADD_P column_def
(* ALTER TABLE <name> ADD COLUMN <coldef> *)
| ADD_P COLUMN column_def
(* ALTER TABLE <name> ALTER [COLUMN] <colname>  *)
| ALTER opt_column col_id alter_column_default
(* ALTER TABLE <name> ALTER [COLUMN] <colname> DROP NOT NULL *)
| ALTER opt_column col_id DROP NOT NULL_P
(* ALTER TABLE <name> ALTER [COLUMN] <colname> SET NOT NULL *)
| ALTER opt_column col_id SET NOT NULL_P
(* ALTER TABLE <name> ALTER [COLUMN] <colname> SET STATISTICS <signed_iconst> *)
| ALTER opt_column col_id SET STATISTICS signed_iconst
(* ALTER TABLE <name> ALTER [COLUMN] <colname> SET ( column_parameter = value [, ... ] ) *)
| ALTER opt_column col_id SET reloptions
(* ALTER TABLE <name> ALTER [COLUMN] <colname> SET ( column_parameter = value [, ... ] ) *)
| ALTER opt_column col_id RESET reloptions
(* ALTER TABLE <name> ALTER [COLUMN] <colname> SET STORAGE <storagemode> *)
| ALTER opt_column col_id SET STORAGE col_id
(* ALTER TABLE <name> DROP [COLUMN] IF EXISTS <colname> [RESTRICT|CASCADE] *)
| DROP opt_column IF_P EXISTS col_id opt_drop_behavior
(* ALTER TABLE <name> DROP [COLUMN] <colname> [RESTRICT|CASCADE] *)
| DROP opt_column col_id opt_drop_behavior
(*
 * ALTER TABLE <name> ALTER [COLUMN] <colname> [SET DATA] TYPE <type_name>
 *        [ USING <expression> ]
 *)
| ALTER opt_column col_id opt_set_data TYPE_P type_name opt_collate_clause alter_using
(* ALTER FOREIGN TABLE <name> ALTER [COLUMN] <colname> OPTIONS *)
| ALTER opt_column col_id alter_generic_options
(* ALTER TABLE <name> ADD CONSTRAINT ... *)
| ADD_P table_constraint
(* ALTER TABLE <name> VALIDATE CONSTRAINT ... *)
| VALIDATE CONSTRAINT name
(* ALTER TABLE <name> DROP CONSTRAINT IF EXISTS <name> [RESTRICT|CASCADE] *)
| DROP CONSTRAINT IF_P EXISTS name opt_drop_behavior
(* ALTER TABLE <name> DROP CONSTRAINT <name> [RESTRICT|CASCADE] *)
| DROP CONSTRAINT name opt_drop_behavior
(* ALTER TABLE <name> SET WITH OIDS  *)
| SET WITH OIDS
(* ALTER TABLE <name> SET WITHOUT OIDS  *)
| SET WITHOUT OIDS
(* ALTER TABLE <name> CLUSTER ON <indexname> *)
| CLUSTER ON name
(* ALTER TABLE <name> SET WITHOUT CLUSTER *)
| SET WITHOUT CLUSTER
(* ALTER TABLE <name> ENABLE TRIGGER <trig> *)
| ENABLE_P TRIGGER name
(* ALTER TABLE <name> ENABLE ALWAYS TRIGGER <trig> *)
| ENABLE_P ALWAYS TRIGGER name
(* ALTER TABLE <name> ENABLE REPLICA TRIGGER <trig> *)
| ENABLE_P REPLICA TRIGGER name
(* ALTER TABLE <name> ENABLE TRIGGER ALL *)
| ENABLE_P TRIGGER ALL
(* ALTER TABLE <name> ENABLE TRIGGER USER *)
| ENABLE_P TRIGGER USER
(* ALTER TABLE <name> DISABLE TRIGGER <trig> *)
| DISABLE_P TRIGGER name
(* ALTER TABLE <name> DISABLE TRIGGER ALL *)
| DISABLE_P TRIGGER ALL
(* ALTER TABLE <name> DISABLE TRIGGER USER *)
| DISABLE_P TRIGGER USER
(* ALTER TABLE <name> ENABLE RULE <rule> *)
| ENABLE_P RULE name
(* ALTER TABLE <name> ENABLE ALWAYS RULE <rule> *)
| ENABLE_P ALWAYS RULE name
(* ALTER TABLE <name> ENABLE REPLICA RULE <rule> *)
| ENABLE_P REPLICA RULE name
(* ALTER TABLE <name> DISABLE RULE <rule> *)
| DISABLE_P RULE name
(* ALTER TABLE <name> INHERIT <parent> *)
| INHERIT qualified_name
(* ALTER TABLE <name> NO INHERIT <parent> *)
| NO INHERIT qualified_name
(* ALTER TABLE <name> OF <type_name> *)
| OF any_name
(* ALTER TABLE <name> NOT OF *)
| NOT OF
(* ALTER TABLE <name> OWNER TO role_id *)
| OWNER TO role_id
(* ALTER TABLE <name> SET TABLESPACE <tablespacename> *)
| SET TABLESPACE name
(* ALTER TABLE <name> SET (...) *)
| SET reloptions
(* ALTER TABLE <name> RESET (...) *)
| RESET reloptions
| alter_generic_options
{ }

alter_column_default:
| SET DEFAULT a_expr
| DROP DEFAULT
{ }

opt_drop_behavior:
| CASCADE
| RESTRICT
| (* EMPTY *)
{ }

opt_collate_clause:
| COLLATE any_name
| (* EMPTY *)
{ }

alter_using:
| USING a_expr
| (* EMPTY *)
{ }

reloptions:
| LPAREN reloption_list RPAREN
{ }

opt_reloptions:
| WITH reloptions
| (* EMPTY *)
{ }

reloption_list:
| reloption_elem
| reloption_list COMMA reloption_elem
{ }

(* This should match def_elem and also allow qualified names *)
reloption_elem:
| col_label EQ def_arg
| col_label
| col_label DOT col_label EQ def_arg
| col_label DOT col_label
{ }



(*****************************************************************************
 *
 *    ALTER TYPE
 *
 * really variants of the ALTER TABLE subcommands with different spellings
 *****************************************************************************)

alter_composite_type_stmt:
| ALTER TYPE_P any_name alter_type_cmds
{ }

alter_type_cmds:
| alter_type_cmd
| alter_type_cmds COMMA alter_type_cmd
{ }

alter_type_cmd:
(* ALTER TYPE <name> ADD ATTRIBUTE <coldef> [RESTRICT|CASCADE] *)
| ADD_P ATTRIBUTE table_func_element opt_drop_behavior
(* ALTER TYPE <name> DROP ATTRIBUTE IF EXISTS <attname> [RESTRICT|CASCADE] *)
| DROP ATTRIBUTE IF_P EXISTS col_id opt_drop_behavior
(* ALTER TYPE <name> DROP ATTRIBUTE <attname> [RESTRICT|CASCADE] *)
| DROP ATTRIBUTE col_id opt_drop_behavior
(* ALTER TYPE <name> ALTER ATTRIBUTE <attname> [SET DATA] TYPE <type_name> [RESTRICT|CASCADE] *)
| ALTER ATTRIBUTE col_id opt_set_data TYPE_P type_name opt_collate_clause opt_drop_behavior
{ }



(*****************************************************************************
 *
 *        QUERY:
 *                close <portalname>
 *
 *****************************************************************************)

close_portal_stmt:
| CLOSE cursor_name
| CLOSE ALL
{ }



(*****************************************************************************
 *
 *        QUERY:
 *                COPY relname [(column_list)] FROM/TO file [WITH] [(options)]
 *                COPY ( SELECT ... ) TO file    [WITH] [(options)]
 *
 *                where 'file' can be one of:
 *
 *
 *                In the preferred syntax the options are comma-separated
 *                and use generic identifiers instead of keywords.  The pre-9.0
 *                syntax had a hard-wired, space-separated set of options.
 *
 *                Really old syntax, from versions 7.2 and prior:
 *                COPY [ BINARY ] table [ WITH OIDS ] FROM/TO file
 *                    [ [ USING ] DELIMITERS 'delimiter' ] ]
 *                    [ WITH NULL AS 'null string' ]
 *                This option placement is not supported with COPY (SELECT...).
 *
 *****************************************************************************)

copy_stmt:
| COPY opt_binary qualified_name opt_column_list opt_oids
            copy_from opt_program copy_file_name copy_delimiter opt_with copy_options
| COPY select_with_parens TO opt_program copy_file_name opt_with copy_options
{ }


copy_from:
| FROM
| TO
{ }

opt_program:
| PROGRAM
| (* EMPTY *)
{ }

(*
 * copy_file_name NULL indicates stdio is used. Whether stdin or stdout is
 * used depends on the direction. (It really doesn't make sense to copy from
 * stdout. We silently correct the "typo".)         - AY 9/94
 *)
copy_file_name:
| sconst
| STDIN
| STDOUT
{ }

copy_options:
| copy_opt_list
| LPAREN copy_generic_opt_list RPAREN
{ }

(* old COPY option syntax *)
copy_opt_list:
| copy_opt_list copy_opt_item
| (* EMPTY *)
{ }

copy_opt_item:
| BINARY
| OIDS
| FREEZE
| DELIMITER opt_as sconst
| NULL_P opt_as sconst
| CSV
| HEADER_P
| QUOTE opt_as sconst
| ESCAPE opt_as sconst
| FORCE QUOTE column_list
| FORCE QUOTE STAR
| FORCE NOT NULL_P column_list
| ENCODING sconst
{ }


(* The following exist for backward compatibility with very old versions *)

opt_binary:
| BINARY
| (* EMPTY *)
{ }

opt_oids:
| WITH OIDS
| (* EMPTY *)
{ }

copy_delimiter:
| opt_using DELIMITERS sconst
| (* EMPTY *)
{ }

opt_using:
| USING
| (* EMPTY *)
{ }

(* new COPY option syntax *)
copy_generic_opt_list:
| copy_generic_opt_elem
| copy_generic_opt_list COMMA copy_generic_opt_elem
{ }


copy_generic_opt_elem:
| col_label copy_generic_opt_arg
{ }


copy_generic_opt_arg:
| opt_boolean_or_string
| numeric_only
| STAR
| LPAREN copy_generic_opt_arg_list RPAREN
| (* EMPTY *)
{ }

copy_generic_opt_arg_list:
| copy_generic_opt_arg_list_item
| copy_generic_opt_arg_list COMMA copy_generic_opt_arg_list_item
{ }


(* beware of emitting non-string list elements here; see commands/define.c *)
copy_generic_opt_arg_list_item:
| opt_boolean_or_string
{ }


(*****************************************************************************
 *
 *        QUERY:
 *                CREATE TABLE relname
 *
 *****************************************************************************)

create_stmt:
| CREATE opt_temp TABLE qualified_name LPAREN opt_table_element_list RPAREN
            opt_inherit opt_with_rel on_commit_option opt_table_space
| CREATE opt_temp TABLE IF_P NOT EXISTS qualified_name LPAREN
    opt_table_element_list RPAREN opt_inherit opt_with_rel on_commit_option
    opt_table_space
| CREATE opt_temp TABLE qualified_name OF any_name
    opt_typed_table_element_list opt_with_rel on_commit_option opt_table_space
| CREATE opt_temp TABLE IF_P NOT EXISTS qualified_name OF any_name
    opt_typed_table_element_list opt_with_rel on_commit_option opt_table_space
{ }


(*
 * Redundancy here is needed to avoid shift/reduce conflicts,
 * since TEMP is not a reserved word.  See also opt_temp_table_name.
 *
 * NOTE: we accept both GLOBAL and LOCAL options.  They currently do nothing,
 * but future versions might consider GLOBAL to request SQL-spec-compliant
 * temp table behavior, so warn about that.  Since we have no modules the
 * LOCAL keyword is really meaningless; furthermore, some other products
 * implement LOCAL as meaning the same as our default temp table behavior,
 * so we'll probably continue to treat LOCAL as a noise word.
 *)
opt_temp:
| TEMPORARY
| TEMP
| LOCAL TEMPORARY
| LOCAL TEMP
| GLOBAL TEMPORARY
| GLOBAL TEMP
| UNLOGGED
| (* EMPTY *)
{ }

opt_table_element_list:
| table_element_list
| (* EMPTY *)
{ }

opt_typed_table_element_list:
| LPAREN typed_table_element_list RPAREN
| (* EMPTY *)
{ }

table_element_list:
| table_element
| table_element_list COMMA table_element
{ }


typed_table_element_list:
| typed_table_element
| typed_table_element_list COMMA typed_table_element
{ }


table_element:
| column_def
| table_like_clause
| table_constraint
{ }

typed_table_element:
| column_options
| table_constraint
{ }

column_def:
| col_id type_name create_generic_options col_qual_list
{ }


column_options:
| col_id WITH OPTIONS col_qual_list
{ }


col_qual_list:
| col_qual_list col_constraint
| (* EMPTY *)
{ }

col_constraint:
| CONSTRAINT name col_constraint_elem
| col_constraint_elem
| constraint_attr
| COLLATE any_name
{ }


(* DEFAULT NULL is already the default for Postgres.
 * But define it here and carry it forward into the system
 * to make it explicit.
 * - thomas 1998-09-13
 *
 * WITH NULL and NULL are not SQL-standard syntax elements,
 * so leave them out. Use DEFAULT NULL to explicitly indicate
 * that a column may have that value. WITH NULL leads to
 * shift/reduce conflicts with WITH TIME ZONE anyway.
 * - thomas 1999-01-08
 *
 * DEFAULT expression must be b_expr not a_expr to prevent shift/reduce
 * conflict on NOT (since NOT might start a subsequent NOT NULL constraint,
 * or be part of a_expr NOT LIKE or similar constructs).
 *)
col_constraint_elem:
| NOT NULL_P
| NULL_P
| UNIQUE opt_definition opt_cons_table_space
| PRIMARY KEY opt_definition opt_cons_table_space
| CHECK LPAREN a_expr RPAREN opt_no_inherit
| DEFAULT b_expr
| REFERENCES qualified_name opt_column_list key_match key_actions
{ }


(*
 * constraint_attr represents constraint attributes, which we parse as if
 * they were independent constraint clauses, in order to avoid shift/reduce
 * conflicts (since NOT might start either an independent NOT NULL clause
 * or an attribute).  parse_utilcmd.c is responsible for attaching the
 * attribute information to the preceding "real" constraint node, and for
 * complaining if attribute clauses appear in the wrong place or wrong
 * combinations.
 *
 * See also constraint_attribute_spec, which can be used in places where
 * there is no parsing conflict.  (Note: currently, NOT VALID and NO INHERIT
 * are allowed clauses in constraint_attribute_spec, but not here.  Someday we
 * might need to allow them here too, but for the moment it doesn't seem
 * useful in the statements that use constraint_attr.)
 *)
constraint_attr:
| DEFERRABLE
| NOT DEFERRABLE
| INITIALLY DEFERRED
| INITIALLY IMMEDIATE
{ }



table_like_clause:
| LIKE qualified_name table_like_option_list
{ }

table_like_option_list:
| table_like_option_list INCLUDING table_like_option
| table_like_option_list EXCLUDING table_like_option
| (* EMPTY *)
{ }

table_like_option:
| DEFAULTS
| CONSTRAINTS
| INDEXES
| STORAGE
| COMMENTS
| ALL
{ }


(* constraint_elem specifies constraint syntax which is not embedded into
 *    a column definition. col_constraint_elem specifies the embedded form.
 * - thomas 1997-12-03
 *)
table_constraint:
| CONSTRAINT name constraint_elem
| constraint_elem
{ }

constraint_elem:
| CHECK LPAREN a_expr RPAREN constraint_attribute_spec
| UNIQUE LPAREN column_list RPAREN opt_definition opt_cons_table_space
                constraint_attribute_spec
| UNIQUE existing_index constraint_attribute_spec
| PRIMARY KEY LPAREN column_list RPAREN opt_definition opt_cons_table_space
                constraint_attribute_spec
| PRIMARY KEY existing_index constraint_attribute_spec
| EXCLUDE access_method_clause LPAREN exclusion_constraint_list RPAREN
                opt_definition opt_cons_table_space exclusion_where_clause
                constraint_attribute_spec
| FOREIGN KEY LPAREN column_list RPAREN REFERENCES qualified_name
                opt_column_list key_match key_actions constraint_attribute_spec
{ }


opt_no_inherit:
| NO INHERIT
| (* EMPTY *)
{ }

opt_column_list:
| LPAREN column_list RPAREN
| (* EMPTY *)
{ }

column_list:
| column_elem
| column_list COMMA column_elem
{ }

column_elem:
| col_id
{ }


key_match:
| MATCH FULL
| MATCH PARTIAL
| MATCH SIMPLE
| (* EMPTY *)
{ }


exclusion_constraint_list:
| exclusion_constraint_elem
| exclusion_constraint_list COMMA exclusion_constraint_elem
{ }


exclusion_constraint_elem:
| index_elem WITH any_operator
            (* allow OPERATOR() decoration for the benefit of ruleutils.c *)
| index_elem WITH OPERATOR LPAREN any_operator RPAREN
{ }


exclusion_where_clause:
| WHERE LPAREN a_expr RPAREN
| (* EMPTY *)
{ }

(*
 * We combine the update and delete actions into one value temporarily
 * for simplicity of parsing, and then break them down again in the
 * calling production.  update is in the left 8 bits, delete in the right.
 * Note that NOACTION is the default.
 *)
key_actions:
| key_update
| key_delete
| key_update key_delete
| key_delete key_update
| (* EMPTY *)
{ }


key_update:
| ON UPDATE key_action
{ }

key_delete:
| ON DELETE_P key_action
{ }

key_action:
| NO ACTION
| RESTRICT
| CASCADE
| SET NULL_P
| SET DEFAULT
{ }

opt_inherit:
| INHERITS LPAREN qualified_name_list RPAREN
| (* EMPTY *)
{ }

(* WITH (options) is preferred, WITH OIDS and WITHOUT OIDS are legacy forms *)
opt_with_rel:
| WITH reloptions
| WITH OIDS
| WITHOUT OIDS
| (* EMPTY *)
{ }

on_commit_option:
| ON COMMIT DROP
| ON COMMIT DELETE_P ROWS
| ON COMMIT PRESERVE ROWS
| (* EMPTY *)
{ }

opt_table_space:
| TABLESPACE name
| (* EMPTY *)
{ }

opt_cons_table_space:
| USING INDEX TABLESPACE name
| (* EMPTY *)
{ }

existing_index:
| USING INDEX index_name
{ }


(*****************************************************************************
 *
 *        QUERY:
 *                CREATE TABLE relname AS select_stmt [ WITH [NO] DATA ]
 *
 *
 * Note: SELECT ... INTO is a now-deprecated alternative for this.
 *
 *****************************************************************************)

create_as_stmt:
| CREATE opt_temp TABLE create_as_target AS select_stmt opt_with_data
{ }


create_as_target:
| qualified_name opt_column_list opt_with_rel on_commit_option opt_table_space
{ }


opt_with_data:
| WITH DATA_P
| WITH NO DATA_P
| (* EMPTY *)
{ }


(*****************************************************************************
 *
 *        QUERY:| *                CREATE MATERIALIZED VIEW relname AS select_stmt
 *
 *****************************************************************************)

create_mat_view_stmt:
| CREATE opt_no_log MATERIALIZED VIEW create_mv_target AS select_stmt opt_with_data
{ }


create_mv_target:
| qualified_name opt_column_list opt_reloptions opt_table_space
{ }


opt_no_log:
| UNLOGGED
| (* EMPTY *)
{ }


(*****************************************************************************
 *
 *        QUERY:
 *                REFRESH MATERIALIZED VIEW qualified_name
 *
 *****************************************************************************)

refresh_mat_view_stmt:
| REFRESH MATERIALIZED VIEW qualified_name opt_with_data
{ }



(*****************************************************************************
 *
 *        QUERY:| *                CREATE SEQUENCE seqname
 *                ALTER SEQUENCE seqname
 *
 *****************************************************************************)

create_seq_stmt:
| CREATE opt_temp SEQUENCE qualified_name opt_seq_opt_list
{ }


alter_seq_stmt:
| ALTER SEQUENCE qualified_name seq_opt_list
| ALTER SEQUENCE IF_P EXISTS qualified_name seq_opt_list
{ }



opt_seq_opt_list:
| seq_opt_list
| (* EMPTY *)
{ }

seq_opt_list:
| seq_opt_elem
| seq_opt_list seq_opt_elem
{ }

seq_opt_elem:
| CACHE numeric_only
| CYCLE
| NO CYCLE
| INCREMENT opt_by numeric_only
| MAXVALUE numeric_only
| MINVALUE numeric_only
| NO MAXVALUE
| NO MINVALUE
| OWNED BY any_name
| START opt_with numeric_only
| RESTART
| RESTART opt_with numeric_only
{ }


opt_by:
| BY
| (* empty *)
{ }

numeric_only:
| FCONST
| MINUS FCONST
| signed_iconst
{ }

numeric_only_list:
| numeric_only
| numeric_only_list COMMA numeric_only
{ }

(*****************************************************************************
 *
 *        QUERIES :| *                CREATE [OR REPLACE] [TRUSTED] [PROCEDURAL] LANGUAGE ...
 *                DROP [PROCEDURAL] LANGUAGE ...
 *
 *****************************************************************************)

create_pLang_stmt:
| CREATE opt_or_replace opt_trusted opt_procedural LANGUAGE non_reserved_word_or_sconst
| CREATE opt_or_replace opt_trusted opt_procedural LANGUAGE non_reserved_word_or_sconst
              HANDLER handler_name opt_inline_handler opt_validator
{ }


opt_trusted:
| TRUSTED
| (* EMPTY *)
{ }

(* This ought to be just func_name, but that causes reduce/reduce conflicts
 * (CREATE LANGUAGE is the only place where func_name isn't followed by LPAREN).
 * Work around by using simple names, instead.
 *)
handler_name:
| name
| name attrs
{ }

opt_inline_handler:
| INLINE_P handler_name
| (* EMPTY *)
{ }

validator_clause:
| VALIDATOR handler_name
| NO VALIDATOR
{ }

opt_validator:
| validator_clause
| (* EMPTY *)
{ }

drop_pLang_stmt:
| DROP opt_procedural LANGUAGE non_reserved_word_or_sconst opt_drop_behavior
| DROP opt_procedural LANGUAGE IF_P EXISTS non_reserved_word_or_sconst opt_drop_behavior
{ }


opt_procedural:
| PROCEDURAL
| (* EMPTY *)
{ }

(*****************************************************************************
 *
 *        QUERY:
 *             CREATE TABLESPACE tablespace LOCATION '/path/to/tablespace/'
 *
 *****************************************************************************)

create_table_space_stmt:
| CREATE TABLESPACE name opt_table_space_owner LOCATION sconst
{ }


opt_table_space_owner:
| OWNER name
| (*EMPTY *)
{ }

(*****************************************************************************
 *
 *        QUERY:
 *                DROP TABLESPACE <tablespace>
 *
 *        No need for drop behaviour as we cannot implement dependencies for
 *        objects in other databases; we can only support RESTRICT.
 *
 ****************************************************************************)

drop_table_space_stmt:
| DROP TABLESPACE name
| DROP TABLESPACE IF_P EXISTS name
{ }


(*****************************************************************************
 *
 *        QUERY:
 *             CREATE EXTENSION extension
 *             [ WITH ] [ SCHEMA schema ] [ VERSION version ] [ FROM oldversion ]
 *
 *****************************************************************************)

create_extension_stmt:
| CREATE EXTENSION name opt_with create_extension_opt_list
| CREATE EXTENSION IF_P NOT EXISTS name opt_with create_extension_opt_list
{ }


create_extension_opt_list:
| create_extension_opt_list create_extension_opt_item
| (* EMPTY *)
{ }


create_extension_opt_item:
| SCHEMA name
| VERSION_P non_reserved_word_or_sconst
| FROM non_reserved_word_or_sconst
{ }


(*****************************************************************************
 *
 * ALTER EXTENSION name UPDATE [ TO version ]
 *
 *****************************************************************************)

alter_extension_stmt:
| ALTER EXTENSION name UPDATE alter_extension_opt_list
{ }


alter_extension_opt_list:
| alter_extension_opt_list alter_extension_opt_item
| (* EMPTY *)
{ }


alter_extension_opt_item:
| TO non_reserved_word_or_sconst
{ }


(*****************************************************************************
 *
 * ALTER EXTENSION name ADD/DROP object-identifier
 *
 *****************************************************************************)

alter_extension_contents_stmt:
| ALTER EXTENSION name add_drop AGGREGATE func_name aggr_args
| ALTER EXTENSION name add_drop CAST LPAREN type_name AS type_name RPAREN
| ALTER EXTENSION name add_drop COLLATION any_name
| ALTER EXTENSION name add_drop CONVERSION_P any_name
| ALTER EXTENSION name add_drop DOMAIN_P any_name
| ALTER EXTENSION name add_drop FUNCTION function_with_argtypes
| ALTER EXTENSION name add_drop opt_procedural LANGUAGE name
| ALTER EXTENSION name add_drop OPERATOR any_operator oper_argtypes
| ALTER EXTENSION name add_drop OPERATOR CLASS any_name USING access_method
| ALTER EXTENSION name add_drop OPERATOR FAMILY any_name USING access_method
| ALTER EXTENSION name add_drop SCHEMA name
| ALTER EXTENSION name add_drop EVENT TRIGGER name
| ALTER EXTENSION name add_drop TABLE any_name
| ALTER EXTENSION name add_drop TEXT_P SEARCH PARSER any_name
| ALTER EXTENSION name add_drop TEXT_P SEARCH DICTIONARY any_name
| ALTER EXTENSION name add_drop TEXT_P SEARCH TEMPLATE any_name
| ALTER EXTENSION name add_drop TEXT_P SEARCH CONFIGURATION any_name
| ALTER EXTENSION name add_drop SEQUENCE any_name
| ALTER EXTENSION name add_drop VIEW any_name
| ALTER EXTENSION name add_drop MATERIALIZED VIEW any_name
| ALTER EXTENSION name add_drop FOREIGN TABLE any_name
| ALTER EXTENSION name add_drop FOREIGN DATA_P WRAPPER name
| ALTER EXTENSION name add_drop SERVER name
| ALTER EXTENSION name add_drop TYPE_P any_name
{ }


(*****************************************************************************
 *
 *        QUERY:
 *             CREATE FOREIGN DATA WRAPPER name options
 *
 *****************************************************************************)

create_fdw_stmt:
| CREATE FOREIGN DATA_P WRAPPER name opt_fdw_options create_generic_options
{ }


fdw_option:
| HANDLER handler_name
| NO HANDLER
| VALIDATOR handler_name
| NO VALIDATOR
{ }

fdw_options:
| fdw_option
| fdw_options fdw_option
{ }

opt_fdw_options:
| fdw_options
| (* EMPTY *)
{ }

(*****************************************************************************
 *
 *        QUERY:
 *                DROP FOREIGN DATA WRAPPER name
 *
 ****************************************************************************)

drop_fdw_stmt:
| DROP FOREIGN DATA_P WRAPPER name opt_drop_behavior
| DROP FOREIGN DATA_P WRAPPER IF_P EXISTS name opt_drop_behavior
{ }


(*****************************************************************************
 *
 *        QUERY:
 *                ALTER FOREIGN DATA WRAPPER name options
 *
 ****************************************************************************)

alter_fdw_stmt:
| ALTER FOREIGN DATA_P WRAPPER name opt_fdw_options alter_generic_options
| ALTER FOREIGN DATA_P WRAPPER name fdw_options
{ }


(* Options definition for CREATE FDW, SERVER and USER MAPPING *)
create_generic_options:
| OPTIONS LPAREN generic_option_list RPAREN
| (* EMPTY *)
{ }

generic_option_list:
| generic_option_elem
| generic_option_list COMMA generic_option_elem
{ }


(* Options definition for ALTER FDW, SERVER and USER MAPPING *)
alter_generic_options:
| OPTIONS    LPAREN alter_generic_option_list RPAREN
{ }

alter_generic_option_list:
| alter_generic_option_elem
| alter_generic_option_list COMMA alter_generic_option_elem
{ }


alter_generic_option_elem:
| generic_option_elem
| SET generic_option_elem
| ADD_P generic_option_elem
| DROP generic_option_name
{ }


generic_option_elem:
| generic_option_name generic_option_arg
{ }


generic_option_name:
| col_label
{ }

(* We could use def_arg here, but the spec only requires string literals *)
generic_option_arg:
| sconst
{ }

(*****************************************************************************
 *
 *        QUERY:
 *             CREATE SERVER name [TYPE] [VERSION] [OPTIONS]
 *
 *****************************************************************************)

create_foreign_server_stmt:
| CREATE SERVER name opt_type opt_foreign_server_version
                         FOREIGN DATA_P WRAPPER name create_generic_options
{ }


opt_type:
| TYPE_P sconst
| (* EMPTY *)
{ }


foreign_server_version:
| VERSION_P sconst
| VERSION_P NULL_P
{ }

opt_foreign_server_version:
| foreign_server_version
| (* EMPTY *)
{ }

(*****************************************************************************
 *
 *        QUERY:
 *                DROP SERVER name
 *
 ****************************************************************************)

drop_foreign_server_stmt:
| DROP SERVER name opt_drop_behavior
| DROP SERVER IF_P EXISTS name opt_drop_behavior
{ }


(*****************************************************************************
 *
 *        QUERY:
 *                ALTER SERVER name [VERSION] [OPTIONS]
 *
 ****************************************************************************)

alter_foreign_server_stmt:
| ALTER SERVER name foreign_server_version alter_generic_options
| ALTER SERVER name foreign_server_version
| ALTER SERVER name alter_generic_options
{ }


(*****************************************************************************
 *
 *        QUERY:
 *             CREATE FOREIGN TABLE relname (...) SERVER name (...)
 *
 *****************************************************************************)

create_foreign_table_stmt:
| CREATE FOREIGN TABLE qualified_name
            LPAREN opt_table_element_list RPAREN
            SERVER name create_generic_options
| CREATE FOREIGN TABLE IF_P NOT EXISTS qualified_name
            LPAREN opt_table_element_list RPAREN
            SERVER name create_generic_options
{ }


(*****************************************************************************
 *
 *        QUERY:
 *             ALTER FOREIGN TABLE relname [...]
 *
 *****************************************************************************)

alter_foreign_table_stmt:
| ALTER FOREIGN TABLE relation_expr alter_table_cmds
| ALTER FOREIGN TABLE IF_P EXISTS relation_expr alter_table_cmds
{ }


(*****************************************************************************
 *
 *        QUERY:
 *             CREATE USER MAPPING FOR auth_ident SERVER name [OPTIONS]
 *
 *****************************************************************************)

create_user_mapping_stmt:
| CREATE USER MAPPING FOR auth_ident SERVER name create_generic_options
{ }


(* User mapping authorization identifier *)
auth_ident:
| CURRENT_USER
| USER
| role_id
{ }

(*****************************************************************************
 *
 *        QUERY:
 *                DROP USER MAPPING FOR auth_ident SERVER name
 *
 ****************************************************************************)

drop_user_mapping_stmt:
| DROP USER MAPPING FOR auth_ident SERVER name
| DROP USER MAPPING IF_P EXISTS FOR auth_ident SERVER name
{ }


(*****************************************************************************
 *
 *        QUERY:
 *                ALTER USER MAPPING FOR auth_ident SERVER name OPTIONS
 *
 ****************************************************************************)

alter_user_mapping_stmt:
| ALTER USER MAPPING FOR auth_ident SERVER name alter_generic_options
{ }


(*****************************************************************************
 *
 *        QUERIES :
 *                CREATE TRIGGER ...
 *                DROP TRIGGER ...
 *
 *****************************************************************************)

create_trig_stmt:
| CREATE TRIGGER name trigger_action_time trigger_events ON
            qualified_name trigger_for_spec trigger_when
            EXECUTE PROCEDURE func_name LPAREN trigger_func_args RPAREN
| CREATE CONSTRAINT TRIGGER name AFTER trigger_events ON
            qualified_name opt_constr_from_table constraint_attribute_spec
            FOR EACH ROW trigger_when
            EXECUTE PROCEDURE func_name LPAREN trigger_func_args RPAREN
{ }


trigger_action_time:
| BEFORE
| AFTER
| INSTEAD OF
{ }

trigger_events:
| trigger_one_event
| trigger_events OR trigger_one_event
{ }


trigger_one_event:
| INSERT
| DELETE_P
| UPDATE
| UPDATE OF column_list
| TRUNCATE
{ }


trigger_for_spec:
| FOR trigger_for_opt_each trigger_for_type
| (* EMPTY *)
{ }


trigger_for_opt_each:
| EACH
| (* EMPTY *)
{ }

trigger_for_type:
| ROW
| STATEMENT
{ }

trigger_when:
| WHEN LPAREN a_expr RPAREN
| (* EMPTY *)
{ }

trigger_func_args:
| trigger_func_arg
| trigger_func_args COMMA trigger_func_arg
| (* EMPTY *)
{ }

trigger_func_arg:
| iconst
| FCONST
| sconst
| col_label
{ }

opt_constr_from_table:
| FROM qualified_name
| (* EMPTY *)
{ }

constraint_attribute_spec:
| (* EMPTY *)
| constraint_attribute_spec constraint_attribute_elem
{ }


constraint_attribute_elem:
| NOT DEFERRABLE
| DEFERRABLE
| INITIALLY IMMEDIATE
| INITIALLY DEFERRED
| NOT VALID
| NO INHERIT
{ }


drop_trig_stmt:
| DROP TRIGGER name ON any_name opt_drop_behavior
| DROP TRIGGER IF_P EXISTS name ON any_name opt_drop_behavior
{ }



(*****************************************************************************
 *
 *        QUERIES :
 *                CREATE EVENT TRIGGER ...
 *                ALTER EVENT TRIGGER ...
 *
 *****************************************************************************)

create_event_trig_stmt:
| CREATE EVENT TRIGGER name ON col_label
            EXECUTE PROCEDURE func_name LPAREN RPAREN
| CREATE EVENT TRIGGER name ON col_label
            WHEN event_trigger_when_list
            EXECUTE PROCEDURE func_name LPAREN RPAREN
{ }


event_trigger_when_list:
| event_trigger_when_item
| event_trigger_when_list AND event_trigger_when_item
{ }


event_trigger_when_item:
| col_id IN_P LPAREN event_trigger_value_list RPAREN
{ }


event_trigger_value_list:
| SCONST
| event_trigger_value_list COMMA SCONST
{ }


alter_event_trig_stmt:
| ALTER EVENT TRIGGER name enable_trigger
{ }


enable_trigger:
| ENABLE_P
| ENABLE_P REPLICA
| ENABLE_P ALWAYS
| DISABLE_P
{ }

(*****************************************************************************
 *
 *        QUERIES:
 *                CREATE ASSERTION ...
 *                DROP ASSERTION ...
 *
 *****************************************************************************)

create_assert_stmt:
| CREATE ASSERTION name CHECK LPAREN a_expr RPAREN
            constraint_attribute_spec
{ }


drop_assert_stmt:
| DROP ASSERTION name opt_drop_behavior
{ }



(*****************************************************************************
 *
 *        QUERY:
 *                define (aggregate,operator,type)
 *
 *****************************************************************************)

define_stmt:
| CREATE AGGREGATE func_name aggr_args definition
| CREATE AGGREGATE func_name old_aggr_definition
| CREATE OPERATOR any_operator definition
| CREATE TYPE_P any_name definition
| CREATE TYPE_P any_name
| CREATE TYPE_P any_name AS LPAREN opt_table_func_element_list RPAREN
| CREATE TYPE_P any_name AS ENUM_P LPAREN opt_enum_val_list RPAREN
| CREATE TYPE_P any_name AS RANGE definition
| CREATE TEXT_P SEARCH PARSER any_name definition
| CREATE TEXT_P SEARCH DICTIONARY any_name definition
| CREATE TEXT_P SEARCH TEMPLATE any_name definition
| CREATE TEXT_P SEARCH CONFIGURATION any_name definition
| CREATE COLLATION any_name definition
| CREATE COLLATION any_name FROM any_name
{ }


definition:
| LPAREN def_list RPAREN
{ }

def_list:
| def_elem
| def_list COMMA def_elem
{ }

def_elem:
| col_label EQ def_arg
| col_label
{ }


(* Note: any simple identifier will be returned as a type name! *)
def_arg:
| func_type
| reserved_keyword
| qual_all_op
| numeric_only
| sconst
{ }

aggr_args:
| LPAREN type_list RPAREN
| LPAREN STAR RPAREN
{ }

old_aggr_definition:
| LPAREN old_aggr_list RPAREN
{ }

old_aggr_list:
| old_aggr_elem
| old_aggr_list COMMA old_aggr_elem
{ }

(*
 * Must use IDENT here to avoid reduce/reduce conflicts; fortunately none of
 * the item names needed in old aggregate definitions are likely to become
 * SQL keywords.
 *)
old_aggr_elem:
| IDENT EQ def_arg
{ }


opt_enum_val_list:
| enum_val_list
| (* EMPTY *)
{ }

enum_val_list:
| sconst
| enum_val_list COMMA sconst
{ }


(*****************************************************************************
 *
 *    ALTER TYPE enumtype ADD ...
 *
 *****************************************************************************)

alter_enum_stmt:
| ALTER TYPE_P any_name ADD_P VALUE_P opt_if_not_exists sconst
| ALTER TYPE_P any_name ADD_P VALUE_P opt_if_not_exists sconst BEFORE sconst
| ALTER TYPE_P any_name ADD_P VALUE_P opt_if_not_exists sconst AFTER sconst
{ }

opt_if_not_exists:
| IF_P NOT EXISTS
| (* empty *)
{ }


(*****************************************************************************
 *
 *        QUERIES:
 *                CREATE OPERATOR CLASS ...
 *                CREATE OPERATOR FAMILY ...
 *                ALTER OPERATOR FAMILY ...
 *                DROP OPERATOR CLASS ...
 *                DROP OPERATOR FAMILY ...
 *
 *****************************************************************************)

create_op_class_stmt:
| CREATE OPERATOR CLASS any_name opt_default FOR TYPE_P type_name
            USING access_method opt_opfamily AS opclass_item_list
{ }


opclass_item_list:
| opclass_item
| opclass_item_list COMMA opclass_item
{ }

opclass_item:
| OPERATOR iconst any_operator opclass_purpose opt_recheck
| OPERATOR iconst any_operator oper_argtypes opclass_purpose
              opt_recheck
| FUNCTION iconst func_name func_args
| FUNCTION iconst LPAREN type_list RPAREN func_name func_args
| STORAGE type_name
{ }


opt_default:
| DEFAULT
| (* EMPTY *)
{ }

opt_opfamily:
| FAMILY any_name
| (* EMPTY *)
{ }

opclass_purpose:
| FOR SEARCH
| FOR ORDER BY any_name
| (* EMPTY *)
{ }

opt_recheck:
| RECHECK
| (* EMPTY *)
{ }


create_op_family_stmt:
| CREATE OPERATOR FAMILY any_name USING access_method
{ }


alter_op_family_stmt:
| ALTER OPERATOR FAMILY any_name USING access_method ADD_P opclass_item_list
| ALTER OPERATOR FAMILY any_name USING access_method DROP opclass_drop_list
{ }


opclass_drop_list:
| opclass_drop
| opclass_drop_list COMMA opclass_drop
{ }

opclass_drop:
| OPERATOR iconst LPAREN type_list RPAREN
| FUNCTION iconst LPAREN type_list RPAREN
{ }



drop_op_class_stmt:
| DROP OPERATOR CLASS any_name USING access_method opt_drop_behavior
| DROP OPERATOR CLASS IF_P EXISTS any_name USING access_method opt_drop_behavior
{ }


drop_op_family_stmt:
| DROP OPERATOR FAMILY any_name USING access_method opt_drop_behavior
| DROP OPERATOR FAMILY IF_P EXISTS any_name USING access_method opt_drop_behavior
{ }



(*****************************************************************************
 *
 *        QUERY:
 *
 *        DROP OWNED BY username [, username ...] [ RESTRICT | CASCADE ]
 *        REASSIGN OWNED BY username [, username ...] TO username
 *
 *****************************************************************************)
drop_owned_stmt:
| DROP OWNED BY name_list opt_drop_behavior
{ }


reassign_owned_stmt:
| REASSIGN OWNED BY name_list TO name
{ }


(*****************************************************************************
 *
 *        QUERY:
 *
 *        DROP itemtype [ IF EXISTS ] itemname [, itemname ...]
 *           [ RESTRICT | CASCADE ]
 *
 *****************************************************************************)

drop_stmt:
| DROP drop_type IF_P EXISTS any_name_list opt_drop_behavior
| DROP drop_type any_name_list opt_drop_behavior
| DROP INDEX CONCURRENTLY any_name_list opt_drop_behavior
| DROP INDEX CONCURRENTLY IF_P EXISTS any_name_list opt_drop_behavior
{ }



drop_type:
| TABLE
| SEQUENCE
| VIEW
| MATERIALIZED VIEW
| INDEX
| FOREIGN TABLE
| EVENT TRIGGER
| TYPE_P
| DOMAIN_P
| COLLATION
| CONVERSION_P
| SCHEMA
| EXTENSION
| TEXT_P SEARCH PARSER
| TEXT_P SEARCH DICTIONARY
| TEXT_P SEARCH TEMPLATE
| TEXT_P SEARCH CONFIGURATION
{ }

any_name_list:
| any_name
| any_name_list COMMA any_name
{ }

any_name:
| col_id
| col_id attrs
{ }

attrs:
| DOT attr_name
| attrs DOT attr_name
{ }



(*****************************************************************************
 *
 *        QUERY:
 *                truncate table relname1, relname2, ...
 *
 *****************************************************************************)

truncate_stmt:
| TRUNCATE option(TABLE) relation_expr_list opt_restart_seqs opt_drop_behavior
{ }


opt_restart_seqs:
| CONTINUE_P IDENTITY_P
| RESTART IDENTITY_P
| (* EMPTY *)
{ }

(*****************************************************************************
 *
 *    The COMMENT ON statement can take different forms based upon the type of
 *    the object associated with the comment. The form of the statement is:
 *
 *    COMMENT ON [ [ CONVERSION | COLLATION | DATABASE | DOMAIN |
 *                 EXTENSION | EVENT TRIGGER | FOREIGN DATA WRAPPER |
 *                 FOREIGN TABLE | INDEX | [PROCEDURAL] LANGUAGE |
 *                 MATERIALIZED VIEW | ROLE | SCHEMA | SEQUENCE |
 *                 SERVER | TABLE | TABLESPACE |
 *                 TEXT SEARCH CONFIGURATION | TEXT SEARCH DICTIONARY |
 *                 TEXT SEARCH PARSER | TEXT SEARCH TEMPLATE | TYPE |
 *                 VIEW] <objname> |
 *                 AGGREGATE <aggname> (arg1, ...) |
 *                 CAST (<src type> AS <dst type>) |
 *                 COLUMN <relname>.<colname> |
 *                 CONSTRAINT <constraintname> ON <relname> |
 *                 FUNCTION <funcname> (arg1, arg2, ...) |
 *                 LARGE OBJECT <oid> |
 *                 OPERATOR <op> (leftoperand_typ, rightoperand_typ) |
 *                 OPERATOR CLASS <name> USING <access-method> |
 *                 OPERATOR FAMILY <name> USING <access-method> |
 *                 RULE <rulename> ON <relname> |
 *                 TRIGGER <triggername> ON <relname> ]
 *               IS 'text'
 *
 *****************************************************************************)

comment_stmt:
| COMMENT ON comment_type any_name IS comment_text
| COMMENT ON AGGREGATE func_name aggr_args IS comment_text
| COMMENT ON FUNCTION func_name func_args IS comment_text
| COMMENT ON OPERATOR any_operator oper_argtypes IS comment_text
| COMMENT ON CONSTRAINT name ON any_name IS comment_text
| COMMENT ON RULE name ON any_name IS comment_text
| COMMENT ON RULE name IS comment_text
| COMMENT ON TRIGGER name ON any_name IS comment_text
| COMMENT ON OPERATOR CLASS any_name USING access_method IS comment_text
| COMMENT ON OPERATOR FAMILY any_name USING access_method IS comment_text
| COMMENT ON LARGE_P OBJECT_P numeric_only IS comment_text
| COMMENT ON CAST LPAREN type_name AS type_name RPAREN IS comment_text
| COMMENT ON opt_procedural LANGUAGE any_name IS comment_text
{ }


comment_type:
| COLUMN
| DATABASE
| SCHEMA
| INDEX
| SEQUENCE
| TABLE
| DOMAIN_P
| TYPE_P
| VIEW
| MATERIALIZED VIEW
| COLLATION
| CONVERSION_P
| TABLESPACE
| EXTENSION
| ROLE
| FOREIGN TABLE
| SERVER
| FOREIGN DATA_P WRAPPER
| EVENT TRIGGER
| TEXT_P SEARCH CONFIGURATION
| TEXT_P SEARCH DICTIONARY
| TEXT_P SEARCH PARSER
| TEXT_P SEARCH TEMPLATE
{ }

comment_text:
| sconst
| NULL_P
{ }


(*****************************************************************************
 *
 *  SECURITY LABEL [FOR <provider>] ON <object> IS <label>
 *
 *  As with COMMENT ON, <object> can refer to various types of database
 *  objects (e.g. TABLE, COLUMN, etc.).
 *
 *****************************************************************************)

sec_label_stmt:
| SECURITY LABEL opt_provider ON security_label_type any_name
            IS security_label
| SECURITY LABEL opt_provider ON AGGREGATE func_name aggr_args
              IS security_label
| SECURITY LABEL opt_provider ON FUNCTION func_name func_args
              IS security_label
| SECURITY LABEL opt_provider ON LARGE_P OBJECT_P numeric_only
              IS security_label
| SECURITY LABEL opt_provider ON opt_procedural LANGUAGE any_name
              IS security_label
{ }


opt_provider:
| FOR non_reserved_word_or_sconst
| (* empty *)
{ }

security_label_type:
| COLUMN
| DATABASE
| EVENT TRIGGER
| FOREIGN TABLE
| SCHEMA
| SEQUENCE
| TABLE
| DOMAIN_P
| ROLE
| TABLESPACE
| TYPE_P
| VIEW
| MATERIALIZED VIEW
{ }

security_label:
| sconst
| NULL_P
{ }

(*****************************************************************************
 *
 *        QUERY:
 *            fetch/move
 *
 *****************************************************************************)

fetch_stmt:
| FETCH fetch_args
| MOVE fetch_args
{ }


fetch_args:
| cursor_name
| from_in cursor_name
| NEXT opt_from_in cursor_name
| PRIOR opt_from_in cursor_name
| FIRST_P opt_from_in cursor_name
| LAST_P opt_from_in cursor_name
| ABSOLUTE_P signed_iconst opt_from_in cursor_name
| RELATIVE_P signed_iconst opt_from_in cursor_name
| signed_iconst opt_from_in cursor_name
| ALL opt_from_in cursor_name
| FORWARD opt_from_in cursor_name
| FORWARD signed_iconst opt_from_in cursor_name
| FORWARD ALL opt_from_in cursor_name
| BACKWARD opt_from_in cursor_name
| BACKWARD signed_iconst opt_from_in cursor_name
| BACKWARD ALL opt_from_in cursor_name
{ }


from_in:
| FROM
| IN_P
{ }

opt_from_in:
| from_in
| (* EMPTY *)
{ }


(*****************************************************************************
 *
 * GRANT and REVOKE statements
 *
 *****************************************************************************)

grant_stmt:
| GRANT privileges ON privilege_target TO grantee_list
            opt_grant_grant_option
{ }


revoke_stmt:
| REVOKE privileges ON privilege_target
            FROM grantee_list opt_drop_behavior
| REVOKE GRANT OPTION FOR privileges ON privilege_target
            FROM grantee_list opt_drop_behavior
{ }



(*
 * Privilege names are represented as strings; the validity of the privilege
 * names gets checked at execution.  This is a bit annoying but we have little
 * choice because of the syntactic conflict with lists of role names in
 * GRANT/REVOKE.  What's more, we have to call out in the "privilege"
 * production any reserved keywords that need to be usable as privilege names.
 *)

(* either ALL [PRIVILEGES] or a list of individual privileges *)
privileges:
| privilege_list
| ALL
| ALL PRIVILEGES
| ALL LPAREN column_list RPAREN
| ALL PRIVILEGES LPAREN column_list RPAREN
{ }


privilege_list:
| privilege
| privilege_list COMMA privilege
{ }

privilege:
| SELECT opt_column_list
| REFERENCES opt_column_list
| CREATE opt_column_list
| col_id opt_column_list
{ }



(* Don't bother trying to fold the first two rules into one using
 * opt_table.  You're going to get conflicts.
 *)
privilege_target:
| qualified_name_list
| TABLE qualified_name_list
| SEQUENCE qualified_name_list
| FOREIGN DATA_P WRAPPER name_list
| FOREIGN SERVER name_list
| FUNCTION function_with_argtypes_list
| DATABASE name_list
| DOMAIN_P any_name_list
| LANGUAGE name_list
| LARGE_P OBJECT_P numeric_only_list
| SCHEMA name_list
| TABLESPACE name_list
| TYPE_P any_name_list
| ALL TABLES IN_P SCHEMA name_list
| ALL SEQUENCES IN_P SCHEMA name_list
| ALL FUNCTIONS IN_P SCHEMA name_list
{ }



grantee_list:
| grantee
| grantee_list COMMA grantee
{ }

grantee:
| role_id
| GROUP_P role_id
{ }



opt_grant_grant_option:
| WITH GRANT OPTION
| (* EMPTY *)
{ }

function_with_argtypes_list:
| function_with_argtypes
| function_with_argtypes_list COMMA function_with_argtypes
{ }


function_with_argtypes:
| func_name func_args
{ }


(*****************************************************************************
 *
 * GRANT and REVOKE ROLE statements
 *
 *****************************************************************************)

grant_role_stmt:
| GRANT privilege_list TO name_list opt_grant_admin_option opt_granted_by
{ }


revoke_role_stmt:
| REVOKE privilege_list FROM name_list opt_granted_by opt_drop_behavior
| REVOKE ADMIN OPTION FOR privilege_list FROM name_list opt_granted_by opt_drop_behavior
{ }


opt_grant_admin_option:
| WITH ADMIN OPTION
| (* EMPTY *)
{ }

opt_granted_by:
| GRANTED BY role_id
| (* EMPTY *)
{ }

(*****************************************************************************
 *
 * ALTER DEFAULT PRIVILEGES statement
 *
 *****************************************************************************)

alter_default_privileges_stmt:
| ALTER DEFAULT PRIVILEGES def_ACL_option_list def_ACL_action
{ }


def_ACL_option_list:
| def_ACL_option_list def_ACL_option
| (* EMPTY *)
{ }

def_ACL_option:
| IN_P SCHEMA name_list
| FOR ROLE name_list
| FOR USER name_list
{ }


(*
 * This should match GRANT/REVOKE, except that individual target objects
 * are not mentioned and we only allow a subset of object types.
 *)
def_ACL_action:
| GRANT privileges ON defacl_privilege_target TO grantee_list
            opt_grant_grant_option
| REVOKE privileges ON defacl_privilege_target
            FROM grantee_list opt_drop_behavior
| REVOKE GRANT OPTION FOR privileges ON defacl_privilege_target
            FROM grantee_list opt_drop_behavior
{ }


defacl_privilege_target:
| TABLES
| FUNCTIONS
| SEQUENCES
| TYPES_P
{ }


(*****************************************************************************
 *
 *        QUERY:  CREATE INDEX
 *
 * Note: we cannot put TABLESPACE clause after WHERE clause unless we are
 * willing to make TABLESPACE a fully reserved word.
 *****************************************************************************)

index_stmt:
| CREATE opt_unique INDEX opt_concurrently opt_index_name
  ON qualified_name access_method_clause LPAREN index_params RPAREN
  opt_reloptions opt_table_space option(where_clause)
{ }


opt_unique:
| UNIQUE
| (* EMPTY *)
{ }

opt_concurrently:
| CONCURRENTLY
| (* EMPTY *)
{ }

opt_index_name:
| index_name
| (* EMPTY *)
{ }

access_method_clause:
| USING access_method
| (* EMPTY *)
{ }

index_params:
| index_elem
| index_params COMMA index_elem
{ }

(*
 * Index attributes can be either simple column references, or arbitrary
 * expressions in parens.  For backwards-compatibility reasons, we allow
 * an expression that's just a function call to be written without parens.
 *)
index_elem:
| col_id opt_collate opt_class opt_asc_desc opt_nulls_order
| func_expr opt_collate opt_class opt_asc_desc opt_nulls_order
| LPAREN a_expr RPAREN opt_collate opt_class opt_asc_desc opt_nulls_order
{ }


opt_collate:
| COLLATE any_name
| (* EMPTY *)
{ }

opt_class:
| any_name
| USING any_name
| (* EMPTY *)
{ }

opt_asc_desc:
| ASC
| DESC
| (* EMPTY *)
{ }

opt_nulls_order:
| NULLS_FIRST
| NULLS_LAST
| (* EMPTY *)
{ }


(*****************************************************************************
 *
 *        QUERY:
 *                create [or replace] function <fname>
 *                        [(<type-1> )]
 *                        returns <type-r>
 *                        as <filename or code in language as appropriate>
 *                        language <lang> [with parameters]
 *
 *****************************************************************************)

create_function_stmt:
| CREATE opt_or_replace FUNCTION func_name func_args_with_defaults
            RETURNS func_return createfunc_opt_list opt_definition
| CREATE opt_or_replace FUNCTION func_name func_args_with_defaults
              RETURNS TABLE LPAREN table_func_column_list RPAREN createfunc_opt_list opt_definition
| CREATE opt_or_replace FUNCTION func_name func_args_with_defaults
              createfunc_opt_list opt_definition
{ }


opt_or_replace:
| OR REPLACE
| (* EMPTY *)
{ }

func_args:
| LPAREN func_args_list RPAREN
| LPAREN RPAREN
{ }

func_args_list:
| func_arg
| func_args_list COMMA func_arg
{ }

(*
 * func_args_with_defaults is separate because we only want to accept
 * defaults in CREATE FUNCTION, not in ALTER etc.
 *)
func_args_with_defaults:
| LPAREN func_args_with_defaults_list RPAREN
| LPAREN RPAREN
{ }

func_args_with_defaults_list:
| func_arg_with_default
| func_args_with_defaults_list COMMA func_arg_with_default
{ }


(*
 * The style with arg_class first is SQL99 standard, but Oracle puts
 * param_name first; accept both since it's likely people will try both
 * anyway.  Don't bother trying to save productions by letting arg_class
 * have an empty alternative ... you'll get shift/reduce conflicts.
 *
 * We can catch over-specified arguments here if we want to,
 * but for now better to silently swallow typmod, etc.
 * - thomas 2000-03-22
 *)
func_arg:
| arg_class param_name func_type
| param_name arg_class func_type
| param_name func_type
| arg_class func_type
| func_type
{ }


(* INOUT is SQL99 standard, IN OUT is for Oracle compatibility *)
arg_class:
| IN_P
| OUT_P
| INOUT
| IN_P OUT_P
| VARIADIC
{ }

(*
 * Ideally param_name should be col_id, but that causes too many conflicts.
 *)
param_name:
| type_function_name
{ }

func_return:
| func_type
{ }


(*
 * We would like to make the %TYPE productions here be col_id attrs etc,
 * but that causes reduce/reduce conflicts.  type_function_name
 * is next best choice.
 *)
func_type:
| type_name
| type_function_name attrs PERCENT TYPE_P
| SETOF type_function_name attrs PERCENT TYPE_P
{ }


func_arg_with_default:
| func_arg
| func_arg DEFAULT a_expr
| func_arg EQ a_expr
{ }



createfunc_opt_list:
(* Must be at least one to prevent conflict *)
| createfunc_opt_item
| createfunc_opt_list createfunc_opt_item
{ }

(*
 * Options common to both CREATE FUNCTION and ALTER FUNCTION
 *)
common_func_opt_item:
| CALLED ON NULL_P INPUT_P
| RETURNS NULL_P ON NULL_P INPUT_P
| STRICT_P
| IMMUTABLE
| STABLE
| VOLATILE
| EXTERNAL SECURITY DEFINER
| EXTERNAL SECURITY INVOKER
| SECURITY DEFINER
| SECURITY INVOKER
| LEAKPROOF
| NOT LEAKPROOF
| COST numeric_only
| ROWS numeric_only
| function_set_reset_clause
{ }


createfunc_opt_item:
| AS func_as
| LANGUAGE non_reserved_word_or_sconst
| WINDOW
| common_func_opt_item
{ }


func_as:
| sconst
| sconst COMMA sconst
{ }


opt_definition:
| WITH definition
| (* EMPTY *)
{ }

table_func_column:
| param_name func_type
{ }


table_func_column_list:
| table_func_column
| table_func_column_list COMMA table_func_column
{ }


(*****************************************************************************
 * ALTER FUNCTION
 *
 * RENAME and OWNER subcommands are already provided by the generic
 * ALTER infrastructure, here we just specify alterations that can
 * only be applied to functions.
 *
 *****************************************************************************)
alter_function_stmt:
| ALTER FUNCTION function_with_argtypes alterfunc_opt_list opt_restrict
{ }


alterfunc_opt_list:
(* At least one option must be specified *)
| common_func_opt_item
| alterfunc_opt_list common_func_opt_item
{ }

(* Ignored, merely for SQL compliance *)
opt_restrict:
| RESTRICT
| (* EMPTY *)
{ }


(*****************************************************************************
 *
 *        QUERY:
 *
 *        DROP FUNCTION funcname (arg1, arg2, ...) [ RESTRICT | CASCADE ]
 *        DROP AGGREGATE aggname (arg1, ...) [ RESTRICT | CASCADE ]
 *        DROP OPERATOR opname (leftoperand_typ, rightoperand_typ) [ RESTRICT | CASCADE ]
 *
 *****************************************************************************)

remove_func_stmt:
| DROP FUNCTION func_name func_args opt_drop_behavior
| DROP FUNCTION IF_P EXISTS func_name func_args opt_drop_behavior
{ }


remove_aggr_stmt:
| DROP AGGREGATE func_name aggr_args opt_drop_behavior
| DROP AGGREGATE IF_P EXISTS func_name aggr_args opt_drop_behavior
{ }


remove_oper_stmt:
| DROP OPERATOR any_operator oper_argtypes opt_drop_behavior
| DROP OPERATOR IF_P EXISTS any_operator oper_argtypes opt_drop_behavior
{ }


oper_argtypes:
| LPAREN type_name RPAREN
| LPAREN type_name COMMA type_name RPAREN
| LPAREN NONE COMMA type_name RPAREN                    (* left unary *)
| LPAREN type_name COMMA NONE RPAREN                    (* right unary *)
{ }


any_operator:
| all_op
| col_id DOT any_operator
{ }


(*****************************************************************************
 *
 *        DO <anonymous code block> [ LANGUAGE language ]
 *
 * We use a Def_elem list for future extensibility, and to allow flexibility
 * in the clause order.
 *
 *****************************************************************************)

do_stmt:
| DO dostmt_opt_list
{ }


dostmt_opt_list:
| dostmt_opt_item
| dostmt_opt_list dostmt_opt_item
{ }

dostmt_opt_item:
| sconst
| LANGUAGE non_reserved_word_or_sconst
{ }


(*****************************************************************************
 *
 *        CREATE CAST / DROP CAST
 *
 *****************************************************************************)

create_cast_stmt:
| CREATE CAST LPAREN type_name AS type_name RPAREN
                    WITH FUNCTION function_with_argtypes cast_context
| CREATE CAST LPAREN type_name AS type_name RPAREN
                    WITHOUT FUNCTION cast_context
| CREATE CAST LPAREN type_name AS type_name RPAREN
                    WITH INOUT cast_context
{ }


cast_context:
| AS IMPLICIT_P
| AS ASSIGNMENT
| (* EMPTY *)
{ }


drop_cast_stmt:
| DROP CAST opt_if_exists LPAREN type_name AS type_name RPAREN opt_drop_behavior
{ }


opt_if_exists:
| IF_P EXISTS
| (* EMPTY *)
{ }


(*****************************************************************************
 *
 *        QUERY:
 *
 *        REINDEX type <name> [FORCE]
 *
 * FORCE no longer does anything, but we accept it for backwards compatibility
 *****************************************************************************)

reindex_stmt:
| REINDEX reindex_type qualified_name opt_force
| REINDEX SYSTEM_P name opt_force
| REINDEX DATABASE name opt_force
{ }


reindex_type:
| INDEX
| TABLE
{ }

opt_force:
| FORCE
| (* EMPTY *)
{ }


(*****************************************************************************
 *
 * ALTER THING name RENAME TO newname
 *
 *****************************************************************************)

rename_stmt:
| ALTER AGGREGATE func_name aggr_args RENAME TO name
| ALTER COLLATION any_name RENAME TO name
| ALTER CONVERSION_P any_name RENAME TO name
| ALTER DATABASE database_name RENAME TO database_name
| ALTER DOMAIN_P any_name RENAME TO name
| ALTER DOMAIN_P any_name RENAME CONSTRAINT name TO name
| ALTER FOREIGN DATA_P WRAPPER name RENAME TO name
| ALTER FUNCTION function_with_argtypes RENAME TO name
| ALTER GROUP_P role_id RENAME TO role_id
| ALTER opt_procedural LANGUAGE name RENAME TO name
| ALTER OPERATOR CLASS any_name USING access_method RENAME TO name
| ALTER OPERATOR FAMILY any_name USING access_method RENAME TO name
| ALTER SCHEMA name RENAME TO name
| ALTER SERVER name RENAME TO name
| ALTER TABLE relation_expr RENAME TO name
| ALTER TABLE IF_P EXISTS relation_expr RENAME TO name
| ALTER SEQUENCE qualified_name RENAME TO name
| ALTER SEQUENCE IF_P EXISTS qualified_name RENAME TO name
| ALTER VIEW qualified_name RENAME TO name
| ALTER VIEW IF_P EXISTS qualified_name RENAME TO name
| ALTER MATERIALIZED VIEW qualified_name RENAME TO name
| ALTER MATERIALIZED VIEW IF_P EXISTS qualified_name RENAME TO name
| ALTER INDEX qualified_name RENAME TO name
| ALTER INDEX IF_P EXISTS qualified_name RENAME TO name
| ALTER FOREIGN TABLE relation_expr RENAME TO name
| ALTER FOREIGN TABLE IF_P EXISTS relation_expr RENAME TO name
| ALTER TABLE relation_expr RENAME opt_column name TO name
| ALTER TABLE IF_P EXISTS relation_expr RENAME opt_column name TO name
| ALTER MATERIALIZED VIEW qualified_name RENAME opt_column name TO name
| ALTER MATERIALIZED VIEW IF_P EXISTS qualified_name RENAME opt_column name TO name
| ALTER TABLE relation_expr RENAME CONSTRAINT name TO name
| ALTER FOREIGN TABLE relation_expr RENAME opt_column name TO name
| ALTER FOREIGN TABLE IF_P EXISTS relation_expr RENAME opt_column name TO name
| ALTER RULE name ON qualified_name RENAME TO name
| ALTER TRIGGER name ON qualified_name RENAME TO name
| ALTER EVENT TRIGGER name RENAME TO name
| ALTER ROLE role_id RENAME TO role_id
| ALTER USER role_id RENAME TO role_id
| ALTER TABLESPACE name RENAME TO name
| ALTER TABLESPACE name SET reloptions
| ALTER TABLESPACE name RESET reloptions
| ALTER TEXT_P SEARCH PARSER any_name RENAME TO name
| ALTER TEXT_P SEARCH DICTIONARY any_name RENAME TO name
| ALTER TEXT_P SEARCH TEMPLATE any_name RENAME TO name
| ALTER TEXT_P SEARCH CONFIGURATION any_name RENAME TO name
| ALTER TYPE_P any_name RENAME TO name
| ALTER TYPE_P any_name RENAME ATTRIBUTE name TO name opt_drop_behavior
{ }


opt_column:
| COLUMN
| (* EMPTY *)
{ }

opt_set_data:
| SET DATA_P
| (* EMPTY *)
{ }

(*****************************************************************************
 *
 * ALTER THING name SET SCHEMA name
 *
 *****************************************************************************)

alter_object_schema_stmt:
| ALTER AGGREGATE func_name aggr_args SET SCHEMA name
| ALTER COLLATION any_name SET SCHEMA name
| ALTER CONVERSION_P any_name SET SCHEMA name
| ALTER DOMAIN_P any_name SET SCHEMA name
| ALTER EXTENSION any_name SET SCHEMA name
| ALTER FUNCTION function_with_argtypes SET SCHEMA name
| ALTER OPERATOR any_operator oper_argtypes SET SCHEMA name
| ALTER OPERATOR CLASS any_name USING access_method SET SCHEMA name
| ALTER OPERATOR FAMILY any_name USING access_method SET SCHEMA name
| ALTER TABLE relation_expr SET SCHEMA name
| ALTER TABLE IF_P EXISTS relation_expr SET SCHEMA name
| ALTER TEXT_P SEARCH PARSER any_name SET SCHEMA name
| ALTER TEXT_P SEARCH DICTIONARY any_name SET SCHEMA name
| ALTER TEXT_P SEARCH TEMPLATE any_name SET SCHEMA name
| ALTER TEXT_P SEARCH CONFIGURATION any_name SET SCHEMA name
| ALTER SEQUENCE qualified_name SET SCHEMA name
| ALTER SEQUENCE IF_P EXISTS qualified_name SET SCHEMA name
| ALTER VIEW qualified_name SET SCHEMA name
| ALTER VIEW IF_P EXISTS qualified_name SET SCHEMA name
| ALTER MATERIALIZED VIEW qualified_name SET SCHEMA name
| ALTER MATERIALIZED VIEW IF_P EXISTS qualified_name SET SCHEMA name
| ALTER FOREIGN TABLE relation_expr SET SCHEMA name
| ALTER FOREIGN TABLE IF_P EXISTS relation_expr SET SCHEMA name
| ALTER TYPE_P any_name SET SCHEMA name
{ }


(*****************************************************************************
 *
 * ALTER THING name OWNER TO newname
 *
 *****************************************************************************)

alter_owner_stmt:
| ALTER AGGREGATE func_name aggr_args OWNER TO role_id
| ALTER COLLATION any_name OWNER TO role_id
| ALTER CONVERSION_P any_name OWNER TO role_id
| ALTER DATABASE database_name OWNER TO role_id
| ALTER DOMAIN_P any_name OWNER TO role_id
| ALTER FUNCTION function_with_argtypes OWNER TO role_id
| ALTER opt_procedural LANGUAGE name OWNER TO role_id
| ALTER LARGE_P OBJECT_P numeric_only OWNER TO role_id
| ALTER OPERATOR any_operator oper_argtypes OWNER TO role_id
| ALTER OPERATOR CLASS any_name USING access_method OWNER TO role_id
| ALTER OPERATOR FAMILY any_name USING access_method OWNER TO role_id
| ALTER SCHEMA name OWNER TO role_id
| ALTER TYPE_P any_name OWNER TO role_id
| ALTER TABLESPACE name OWNER TO role_id
| ALTER TEXT_P SEARCH DICTIONARY any_name OWNER TO role_id
| ALTER TEXT_P SEARCH CONFIGURATION any_name OWNER TO role_id
| ALTER FOREIGN DATA_P WRAPPER name OWNER TO role_id
| ALTER SERVER name OWNER TO role_id
| ALTER EVENT TRIGGER name OWNER TO role_id
{ }



(*****************************************************************************
 *
 *        QUERY:     Define Rewrite Rule
 *
 *****************************************************************************)

rule_stmt:
| CREATE opt_or_replace RULE name AS
            ON event TO qualified_name option(where_clause)
            DO opt_instead rule_action_list
{ }


rule_action_list:
| NOTHING
| rule_action_stmt
| LPAREN rule_action_multi RPAREN
{ }

(* the thrashing around here is to discard "empty" statements... *)
rule_action_multi:
| rule_action_multi SEMI rule_action_stmt_or_empty
| rule_action_stmt_or_empty
{ }


rule_action_stmt:
| select_stmt
| insert_stmt
| update_stmt
| delete_stmt
| notify_stmt
{ }

rule_action_stmt_or_empty:
| rule_action_stmt
|    (* EMPTY *)
{ }

event:
| SELECT
| UPDATE
| DELETE_P
| INSERT
{ }

opt_instead:
| INSTEAD
| ALSO
| (* EMPTY *)
{ }


drop_rule_stmt:
| DROP RULE name ON any_name opt_drop_behavior
| DROP RULE IF_P EXISTS name ON any_name opt_drop_behavior
{ }



(*****************************************************************************
 *
 *        QUERY:
 *                NOTIFY <identifier> can appear both in rule bodies and
 *                as a query-level command
 *
 *****************************************************************************)

notify_stmt:
| NOTIFY col_id notify_payload
{ }


notify_payload:
| COMMA sconst
| (* EMPTY *)
{ }

listen_stmt:
| LISTEN col_id
{ }


unlisten_stmt:
| UNLISTEN col_id
| UNLISTEN STAR
{ }



(*****************************************************************************
 *
 *        Transactions:| *
 *        BEGIN / COMMIT / ROLLBACK
 *        (also older versions END / ABORT)
 *
 *****************************************************************************)

transaction_stmt:
| ABORT_P opt_transaction
| BEGIN_P opt_transaction transaction_mode_list_or_empty
| START TRANSACTION transaction_mode_list_or_empty
| COMMIT opt_transaction
| END_P opt_transaction
| ROLLBACK opt_transaction
| SAVEPOINT col_id
| RELEASE SAVEPOINT col_id
| RELEASE col_id
| ROLLBACK opt_transaction TO SAVEPOINT col_id
| ROLLBACK opt_transaction TO col_id
| PREPARE TRANSACTION sconst
| COMMIT PREPARED sconst
| ROLLBACK PREPARED sconst
{ }


opt_transaction:
| WORK
| TRANSACTION
| (* EMPTY *)
{ }

transaction_mode_item:
| ISOLATION LEVEL iso_level
| READ ONLY
| READ WRITE
| DEFERRABLE
| NOT DEFERRABLE
{ }


(* Syntax with commas is SQL-spec, without commas is Postgres historical *)
transaction_mode_list:
| transaction_mode_item
| transaction_mode_list COMMA transaction_mode_item
| transaction_mode_list transaction_mode_item
{ }


transaction_mode_list_or_empty:
| transaction_mode_list
| (* EMPTY *)
{ }



(*****************************************************************************
 *
 *    QUERY:
 *        CREATE [ OR REPLACE ] [ TEMP ] VIEW <viewname> LPARENtarget-list RPAREN
 *            AS <query> [ WITH [ CASCADED | LOCAL ] CHECK OPTION ]
 *
 *****************************************************************************)

view_stmt:
| CREATE opt_temp VIEW qualified_name opt_column_list opt_reloptions
                AS select_stmt opt_check_option
| CREATE OR REPLACE opt_temp VIEW qualified_name opt_column_list opt_reloptions
                AS select_stmt opt_check_option
| CREATE opt_temp RECURSIVE VIEW qualified_name LPAREN column_list RPAREN opt_reloptions
                AS select_stmt
| CREATE OR REPLACE opt_temp RECURSIVE VIEW qualified_name LPAREN column_list RPAREN opt_reloptions
                AS select_stmt
{ }


opt_check_option:
| WITH CHECK OPTION
| WITH CASCADED CHECK OPTION
| WITH LOCAL CHECK OPTION
| (* EMPTY *)
{ }

(*****************************************************************************
 *
 *        QUERY:
 *                LOAD "filename"
 *
 *****************************************************************************)

load_stmt:
| LOAD file_name
{ }



(*****************************************************************************
 *
 *        CREATE DATABASE
 *
 *****************************************************************************)

createdb_stmt:
| CREATE DATABASE database_name opt_with createdb_opt_list
{ }


createdb_opt_list:
| createdb_opt_list createdb_opt_item
| (* EMPTY *)
{ }

createdb_opt_item:
| TABLESPACE opt_equal name
| TABLESPACE opt_equal DEFAULT
| LOCATION opt_equal sconst
| LOCATION opt_equal DEFAULT
| TEMPLATE opt_equal name
| TEMPLATE opt_equal DEFAULT
| ENCODING opt_equal sconst
| ENCODING opt_equal iconst
| ENCODING opt_equal DEFAULT
| LC_COLLATE_P opt_equal sconst
| LC_COLLATE_P opt_equal DEFAULT
| LC_CTYPE_P opt_equal sconst
| LC_CTYPE_P opt_equal DEFAULT
| CONNECTION LIMIT opt_equal signed_iconst
| OWNER opt_equal name
| OWNER opt_equal DEFAULT
{ }


(*
 *    Though the equals sign doesn't match other WITH options, pg_dump uses
 *    equals for backward compatibility, and it doesn't seem worth removing it.
 *)
opt_equal:
| EQ
| (* EMPTY *)
{ }


(*****************************************************************************
 *
 *        ALTER DATABASE
 *
 *****************************************************************************)

alter_database_stmt:
| ALTER DATABASE database_name opt_with alterdb_opt_list
| ALTER DATABASE database_name SET TABLESPACE name
{ }


alter_database_set_stmt:
| ALTER DATABASE database_name set_reset_clause
{ }



alterdb_opt_list:
| alterdb_opt_list alterdb_opt_item
| (* EMPTY *)
{ }

alterdb_opt_item:
| CONNECTION LIMIT opt_equal signed_iconst
{ }



(*****************************************************************************
 *
 *        DROP DATABASE [ IF EXISTS ]
 *
 * This is implicitly CASCADE, no need for drop behavior
 *****************************************************************************)

dropdb_stmt:
| DROP DATABASE database_name
| DROP DATABASE IF_P EXISTS database_name
{ }



(*****************************************************************************
 *
 * Manipulate a domain
 *
 *****************************************************************************)

create_domain_stmt:
| CREATE DOMAIN_P any_name opt_as type_name col_qual_list
{ }


alter_domain_stmt:
(* ALTER DOMAIN <domain>  *)
| ALTER DOMAIN_P any_name alter_column_default
(* ALTER DOMAIN <domain> DROP NOT NULL *)
| ALTER DOMAIN_P any_name DROP NOT NULL_P
(* ALTER DOMAIN <domain> SET NOT NULL *)
| ALTER DOMAIN_P any_name SET NOT NULL_P
(* ALTER DOMAIN <domain> ADD CONSTRAINT ... *)
| ALTER DOMAIN_P any_name ADD_P table_constraint
(* ALTER DOMAIN <domain> DROP CONSTRAINT <name> [RESTRICT|CASCADE] *)
| ALTER DOMAIN_P any_name DROP CONSTRAINT name opt_drop_behavior
(* ALTER DOMAIN <domain> DROP CONSTRAINT IF EXISTS <name> [RESTRICT|CASCADE] *)
| ALTER DOMAIN_P any_name DROP CONSTRAINT IF_P EXISTS name opt_drop_behavior
(* ALTER DOMAIN <domain> VALIDATE CONSTRAINT <name> *)
| ALTER DOMAIN_P any_name VALIDATE CONSTRAINT name
{ }

opt_as:
| AS
| (* EMPTY *)
{ }


(*****************************************************************************
 *
 * Manipulate a text search dictionary or configuration
 *
 *****************************************************************************)

alter_tSDictionary_stmt:
| ALTER TEXT_P SEARCH DICTIONARY any_name definition
{ }


alter_tSConfiguration_stmt:
| ALTER TEXT_P SEARCH CONFIGURATION any_name ADD_P MAPPING FOR name_list WITH any_name_list
| ALTER TEXT_P SEARCH CONFIGURATION any_name ALTER MAPPING FOR name_list WITH any_name_list
| ALTER TEXT_P SEARCH CONFIGURATION any_name ALTER MAPPING REPLACE any_name WITH any_name
| ALTER TEXT_P SEARCH CONFIGURATION any_name ALTER MAPPING FOR name_list REPLACE any_name WITH any_name
| ALTER TEXT_P SEARCH CONFIGURATION any_name DROP MAPPING FOR name_list
| ALTER TEXT_P SEARCH CONFIGURATION any_name DROP MAPPING IF_P EXISTS FOR name_list
{ }



(*****************************************************************************
 *
 * Manipulate a conversion
 *
 *        CREATE [DEFAULT] CONVERSION <conversion_name>
 *        FOR <encoding_name> TO <encoding_name> FROM <func_name>
 *
 *****************************************************************************)

create_conversion_stmt:
| CREATE opt_default CONVERSION_P any_name FOR sconst
            TO sconst FROM any_name
{ }


(*****************************************************************************
 *
 *        QUERY:
 *                CLUSTER [VERBOSE] <qualified_name> [ USING <index_name> ]
 *                CLUSTER [VERBOSE]
 *                CLUSTER [VERBOSE] <index_name> ON <qualified_name> (for pre-8.3)
 *
 *****************************************************************************)

cluster_stmt:
| CLUSTER opt_verbose qualified_name cluster_index_specification
| CLUSTER opt_verbose
  (* kept for pre-8.3 compatibility *)
| CLUSTER opt_verbose index_name ON qualified_name
{ }


cluster_index_specification:
| USING index_name
| (* EMPTY *)
{ }


(*****************************************************************************
 *
 *        QUERY:
 *                VACUUM
 *                ANALYZE
 *
 *****************************************************************************)

vacuum_stmt:
| VACUUM opt_full opt_freeze opt_verbose
| VACUUM opt_full opt_freeze opt_verbose qualified_name
| VACUUM opt_full opt_freeze opt_verbose analyze_stmt
| VACUUM LPAREN vacuum_option_list RPAREN
| VACUUM LPAREN vacuum_option_list RPAREN qualified_name opt_name_list
{ }


vacuum_option_list:
| vacuum_option_elem
| vacuum_option_list COMMA vacuum_option_elem
{ }

vacuum_option_elem:
| analyze_keyword
| VERBOSE
| FREEZE
| FULL
{ }

analyze_stmt:
| analyze_keyword opt_verbose
| analyze_keyword opt_verbose qualified_name opt_name_list
{ }


analyze_keyword:
| ANALYZE
| ANALYSE (* British *)
{ }

opt_verbose:
| VERBOSE
| (* EMPTY *)
{ }

opt_full:
| FULL
| (* EMPTY *)
{ }

opt_freeze:
| FREEZE
| (* EMPTY *)
{ }

opt_name_list:
| LPAREN list = name_list RPAREN
    { list }
| (* EMPTY *)
    { [] }


(*****************************************************************************
 *
 *        QUERY:
 *                EXPLAIN [ANALYZE] [VERBOSE] query
 *                EXPLAIN ( options ) query
 *
 *****************************************************************************)

explain_stmt:
| EXPLAIN explainable_stmt
| EXPLAIN analyze_keyword opt_verbose explainable_stmt
| EXPLAIN VERBOSE explainable_stmt
| EXPLAIN LPAREN explain_option_list RPAREN explainable_stmt
{ }


explainable_stmt:
| select_stmt
| insert_stmt
| update_stmt
| delete_stmt
| declare_cursor_stmt
| create_as_stmt
| create_mat_view_stmt
| refresh_mat_view_stmt
| execute_stmt                    (* by default all are $$=$1 *)
{ }

explain_option_list:
| explain_option_elem
| explain_option_list COMMA explain_option_elem
{ }


explain_option_elem:
| explain_option_name explain_option_arg
{ }


explain_option_name:
| non_reserved_word
| analyze_keyword
{ }

explain_option_arg:
| opt_boolean_or_string
| numeric_only
| (* EMPTY *)
{ }

(*****************************************************************************
 *
 *        QUERY:
 *                PREPARE <plan_name> [(args, ...)] AS <query>
 *
 *****************************************************************************)

prepare_stmt:
| PREPARE name prep_type_clause AS preparable_stmt
{ }


prep_type_clause:
| LPAREN type_list RPAREN
| (* EMPTY *)
{ }

preparable_stmt:
| stmt = select_stmt
    { Select stmt }
| stmt = insert_stmt
    { Insert stmt }
| stmt = update_stmt
    { Update stmt }
| stmt = delete_stmt
    { Delete stmt }

(*****************************************************************************
 *
 * EXECUTE <plan_name> [(params, ...)]
 * CREATE TABLE <name> AS EXECUTE <plan_name> [(params, ...)]
 *
 *****************************************************************************)

execute_stmt:
| EXECUTE name execute_param_clause
| CREATE opt_temp TABLE create_as_target AS
                EXECUTE name execute_param_clause opt_with_data
{ }


execute_param_clause:
| LPAREN expr_list RPAREN
| (* EMPTY *)
{ }

(*****************************************************************************
 *
 *        QUERY:
 *                DEALLOCATE [PREPARE] <plan_name>
 *
 *****************************************************************************)

deallocate_stmt:
| DEALLOCATE name
| DEALLOCATE PREPARE name
| DEALLOCATE ALL
| DEALLOCATE PREPARE ALL
{ }


(*****************************************************************************
 *
 *        QUERY:
 *                INSERT STATEMENTS
 *
 *****************************************************************************)

insert_stmt:
| with_ = option(with_clause)
  INSERT INTO relation = qualified_name
              values = insert_rest
              returning = returning_clause
    { { with_; relation; values; returning;
        loc = Loc.loc $startpos $endpos } }

insert_rest:
| stmt = select_stmt
    { `Values ([], stmt)}
| LPAREN ids = separated_nonempty_list(COMMA, qualified_name) RPAREN
  stmt = select_stmt
    { `Values (ids, stmt) }
| DEFAULT VALUES
    { `Default }

returning_clause:
| RETURNING list = separated_nonempty_list(COMMA, target_el)
    { list }
| (* EMPTY *)
    { [] }


(*****************************************************************************
 *
 *        QUERY:
 *                DELETE STATEMENTS
 *
 *****************************************************************************)

delete_stmt:
| with_ = option(with_clause)
  DELETE_P FROM relation = relation_expr_opt_alias
                using = using_clause
                where = option(where_or_current_clause)
                returning = returning_clause
    { { with_; relation; using; where; returning;
        loc = Loc.loc $startpos $endpos } }


using_clause:
| USING list = separated_nonempty_list (COMMA, table_ref)
    { list }
| (* EMPTY *)
    { [] }


(*****************************************************************************
 *
 *        QUERY:
 *                LOCK TABLE
 *
 *****************************************************************************)

lock_stmt:
| LOCK_P option(TABLE) relation_expr_list opt_lock opt_nowait
{ }


opt_lock:
| IN_P lock_type MODE
| (* EMPTY *)
{ }

lock_type:
| ACCESS SHARE
| ROW SHARE
| ROW EXCLUSIVE
| SHARE UPDATE EXCLUSIVE
| SHARE
| SHARE ROW EXCLUSIVE
| EXCLUSIVE
| ACCESS EXCLUSIVE
{ }

opt_nowait:
| NOWAIT
| (* EMPTY *)
{ }


(*****************************************************************************
 *
 *        QUERY:
 *                update_stmt (UPDATE)
 *
 *****************************************************************************)

update_stmt:
| with_ = option(with_clause)
  UPDATE relation = relation_expr_opt_alias
  SET set_clauses = separated_nonempty_list (COMMA, set_clause)
  from = from_clause
  where = option(where_or_current_clause)
  returning = returning_clause
    { { with_; relation; set_clauses = List.concat set_clauses;
        from; where; returning;
        loc = Loc.loc $startpos $endpos; } }

set_clause:
| target = qualified_name EQ value = ctext_expr
    { [target, value] }
| LPAREN targets = separated_nonempty_list(COMMA, qualified_name) RPAREN EQ
  values = ctext_row
    { try List.map2 (fun id v -> (id, v)) targets values
      with _ -> eerror (Loc.loc $startpos $endpos) Column_number_mismatch}


(*****************************************************************************
 *
 *        QUERY:
 *                CURSOR STATEMENTS
 *
 *****************************************************************************)
declare_cursor_stmt:
| DECLARE cursor_name cursor_options CURSOR opt_hold FOR select_stmt
{ }


cursor_name:
| name = name
  { name }

cursor_options:
| cursor_options NO SCROLL
| cursor_options SCROLL
| cursor_options BINARY
| cursor_options INSENSITIVE
| (* EMPTY *)
{ }

opt_hold:
| WITH HOLD
| WITHOUT HOLD
| (* EMPTY *)
{ }

(*****************************************************************************
 *
 *        QUERY:
 *                SELECT STATEMENTS
 *
 *****************************************************************************)

(* A complete SELECT statement looks like this.
 *
 * The rule returns either a single select_stmt node or a tree of them,
 * representing a set-operation tree.
 *
 * There is an ambiguity when a sub-SELECT is within an a_expr and there
 * are excess parentheses: do the parentheses belong to the sub-SELECT or
 * to the surrounding a_expr?  We don't really care, but bison wants to know.
 * To resolve the ambiguity, we are careful to define the grammar so that
 * the decision is staved off as long as possible: as long as we can keep
 * absorbing parentheses into the sub-SELECT, we will do so, and only when
 * it's no longer possible to do that will we decide that parens belong to
 * the expression.    For example, in "SELECT (((SELECT 2)) + 3)" the extra
 * parentheses are treated as part of the sub-select.  The necessity of doing
 * it that way is shown by "SELECT (((SELECT 2)) UNION SELECT 2)".    Had we
 * parsed "((SELECT 2))" as an a_expr, it'd be too late to go back to the
 * SELECT viewpoint when we see the UNION.
 *
 * This approach is implemented by defining a nonterminal select_with_parens,
 * which represents a SELECT with at least one outer layer of parentheses,
 * and being careful to use select_with_parens, never LPAREN select_stmt RPAREN,
 * in the expression grammar.  We will then have shift-reduce conflicts
 * which we can resolve in favor of always treating LPAREN <select> RPAREN as
 * a select_with_parens.  To resolve the conflicts, the productions that
 * conflict with the select_with_parens productions are manually given
 * precedences lower than the precedence of RPAREN, thereby ensuring that we
 * shift RPAREN (and then reduce to select_with_parens) rather than trying to
 * reduce the inner <select> nonterminal to something else.  We use UMINUS
 * precedence for this, which is a fairly arbitrary choice.
 *
 * To be able to define select_with_parens itself without ambiguity, we need
 * a nonterminal select_no_parens that represents a SELECT structure with no
 * outermost parentheses.  This is a little bit tedious, but it works.
 *
 * In non-expression contexts, we use select_stmt which can represent a SELECT
 * with or without outer parentheses.
 *)

select_stmt:
| stmt = select_no_parens          %prec UMINUS
| stmt = select_with_parens        %prec UMINUS
    { stmt }

select_with_parens:
| LPAREN stmt = select_no_parens RPAREN
| LPAREN stmt = select_with_parens RPAREN
    { stmt }

(*
 * This rule parses the equivalent of the standard's <query expression>.
 * The duplicative productions are annoying, but hard to get rid of without
 * creating shift/reduce conflicts.
 *
 *    The locking clause (FOR UPDATE etc) may be before or after LIMIT/OFFSET.
 *    In <=7.2.X, LIMIT/OFFSET had to be after FOR UPDATE
 *    We now support both orderings, but prefer LIMIT/OFFSET before the locking
 * clause.
 *    2002-08-28 bjm
 *)
select_no_parens:
| stmt = simple_select
    { stmt }
| select_clause sort_clause
| select_clause opt_sort_clause for_locking_clause opt_select_limit
| select_clause opt_sort_clause select_limit opt_for_locking_clause
| with_clause select_clause
| with_clause select_clause sort_clause
| with_clause select_clause opt_sort_clause for_locking_clause opt_select_limit
| with_clause select_clause opt_sort_clause select_limit opt_for_locking_clause
    { Not_implemented_select (Loc.loc $startpos $endpos) }

select_clause:
| s = simple_select
| s = select_with_parens
    { s }

(*
 * This rule parses SELECT statements that can appear within set operations,
 * including UNION, INTERSECT and EXCEPT.  LPAREN and RPAREN can be used to specify
 * the ordering of the set operations.    Without LPAREN and RPAREN we want the
 * operations to be ordered per the precedence specs at the head of this file.
 *
 * As with select_no_parens, simple_select cannot have outer parentheses,
 * but can have parenthesized subclauses.
 *
 * Note that sort clauses cannot be included at this level --- SQL requires
 *        SELECT foo UNION SELECT bar ORDER BY baz
 * to be parsed as
 *        (SELECT foo UNION SELECT bar) ORDER BY baz
 * not
 *        SELECT foo UNION (SELECT bar ORDER BY baz)
 * Likewise for WITH, FOR UPDATE and LIMIT.  Therefore, those clauses are
 * described as part of the select_no_parens production, not simple_select.
 * This does not limit functionality, because you can reintroduce these
 * clauses inside parentheses.
 *
 * NOTE: only the leftmost component select_stmt should have INTO.
 * However, this is not checked by the grammar; parse analysis must check it.
 *)
simple_select:
| SELECT distinct = opt_distinct
         targets = separated_nonempty_list(COMMA, target_el)
         into = option(into_clause)
         from = from_clause;
         where = option(where_clause)
         group_clause having_clause window_clause
    { Simple_select { distinct; targets; into; from; where;
		      loc = Loc.loc $startpos $endpos } }
| VALUES rows = separated_nonempty_list (COMMA, ctext_row)
    { Values (rows, Loc.loc $startpos $endpos) }
| TABLE rel = relation_expr
    { Simple_select { targets = [Star Loc.dummy_loc];
                      into = None;
		      from = [Relation(rel, None, Loc.dummy_loc)];
		      where = None; distinct = None;
		      loc = Loc.loc $startpos $endpos }}
| left = select_clause UNION distinct = opt_all right = select_clause
    { Union (left, right, distinct, Loc.loc $startpos $endpos) }
| left = select_clause INTERSECT distinct = opt_all right = select_clause
    { Intersect (left, right, distinct, Loc.loc $startpos $endpos) }
| left = select_clause EXCEPT distinct = opt_all right = select_clause
    { Except (left, right, distinct, Loc.loc $startpos $endpos) }


(*
 * SQL standard WITH clause looks like:| *
 * WITH [ RECURSIVE ] <query name> [ (<column>,...) ]
 *        AS (query) [ SEARCH or CYCLE clause ]
 *
 * We don't currently support the SEARCH or CYCLE clause.
 *)
with_clause:
| WITH tables = separated_nonempty_list(COMMA, common_table_expr)
    { (false, tables) }
| WITH RECURSIVE tables = separated_nonempty_list(COMMA, common_table_expr)
    { (true, tables) }

common_table_expr:
| name = name names = opt_name_list AS LPAREN stmt = preparable_stmt RPAREN
    { (name, names, stmt) }

into_clause:
| INTO name = opt_temp_table_name
    { name }


(*
 * Redundancy here is needed to avoid shift/reduce conflicts,
 * since TEMP is not a reserved word.  See also opt_temp.
 *)
opt_temp_table_name:
| TEMPORARY option(TABLE) name = qualified_name
| TEMP option(TABLE) name = qualified_name
| LOCAL TEMPORARY option(TABLE) name = qualified_name
| LOCAL TEMP option(TABLE) name = qualified_name
| GLOBAL TEMPORARY option(TABLE) name = qualified_name
| GLOBAL TEMP option(TABLE) name = qualified_name
    { `Temp, name }
| UNLOGGED option(TABLE) name = qualified_name
    { `Unlogged, name }
| ioption(TABLE) name = qualified_name
    { `Default, name }


opt_all:
| ALL
    { None }
| DISTINCT
| (* EMPTY *)
    { Some [] }

(* We use (NIL) as a placeholder to indicate that all target expressions
 * should be placed in the DISTINCT list during parsetree analysis.
 *)
opt_distinct:
| DISTINCT
    { Some [] }
| DISTINCT ON LPAREN list = separated_nonempty_list(COMMA, a_expr) RPAREN
    { Some list }
| ALL
| (* EMPTY *)
    { None }

opt_sort_clause:
| sort_clause
| (* EMPTY *)
{ }

sort_clause:
| ORDER BY sortby_list
{ }

sortby_list:
| sortby
| sortby_list COMMA sortby
{ }

sortby:
| a_expr USING qual_all_op opt_nulls_order
| a_expr opt_asc_desc opt_nulls_order
{ }



select_limit:
| limit_clause offset_clause
| offset_clause limit_clause
| limit_clause
| offset_clause
{ }

opt_select_limit:
| select_limit
| (* EMPTY *)
{ }

limit_clause:
| LIMIT select_limit_value
| LIMIT select_limit_value COMMA select_offset_value
(* SQL:2008 syntax *)
| FETCH first_or_next opt_select_fetch_first_value row_or_rows ONLY
{ }


offset_clause:
| OFFSET select_offset_value
(* SQL:2008 syntax *)
| OFFSET select_offset_value2 row_or_rows
{ }

select_limit_value:
| a_expr
| ALL
{ }


select_offset_value:
| a_expr
{ }

(*
 * Allowing full expressions without parentheses causes various parsing
 * problems with the trailing ROW/ROWS key words.  SQL only calls for
 * constants, so we allow the rest only with parentheses.  If omitted,
 * default to 1.
 *)
opt_select_fetch_first_value:
| signed_iconst
| LPAREN a_expr RPAREN
| (* EMPTY *)
{ }

(*
 * Again, the trailing ROW/ROWS in this case prevent the full expression
 * syntax.  c_expr is the best we can do.
 *)
select_offset_value2:
| c_expr
{ }

(* noise words *)
row_or_rows:
| ROW
| ROWS
{ }

first_or_next:
| FIRST_P
| NEXT
{ }


group_clause:
| GROUP_P BY expr_list
| (* EMPTY *)
{ }

having_clause:
| HAVING a_expr
| (* EMPTY *)
{ }

for_locking_clause:
| for_locking_items
| FOR READ ONLY
{ }

opt_for_locking_clause:
| for_locking_clause
| (* EMPTY *)
{ }

for_locking_items:
| for_locking_item
| for_locking_items for_locking_item
{ }

for_locking_item:
| for_locking_strength locked_rels_list opt_nowait
{ }


for_locking_strength:
| FOR UPDATE
| FOR NO KEY UPDATE
| FOR SHARE
| FOR KEY SHARE
{ }

locked_rels_list:
| OF qualified_name_list
| (* EMPTY *)
{ }



(*****************************************************************************
 *
 *    clauses common to all Optimizable stmts:
 *        from_clause        - allow list of both JOIN expressions and table names
 *        where_clause    - qualifications for joins or restrictions
 *
 *****************************************************************************)

from_clause:
| FROM list = separated_nonempty_list(COMMA, table_ref) { list }
| (* EMPTY *) { [] }

(*
 * table_ref is where an alias clause can be attached.
 *)
table_ref:
| rel = relation_expr alias = option(alias_clause)
    { Relation (rel, alias, Loc.loc $startpos $endpos) }
| func_table func_alias_clause
| LATERAL_P func_table func_alias_clause
    { Not_implemented_tableref (Loc.loc $startpos $endpos) }
| select = select_with_parens alias = option(alias_clause)
    { Inner_select (select, alias, Loc.loc $startpos $endpos) }
| LATERAL_P select_with_parens option(alias_clause)
    { Not_implemented_tableref (Loc.loc $startpos $endpos) }
| join = joined_table
    { Join (join , None, Loc.loc $startpos $endpos) }
| LPAREN join = joined_table RPAREN alias = alias_clause
    { Join (join , Some alias, Loc.loc $startpos $endpos) }

(*
 * It may seem silly to separate joined_table from table_ref, but there is
 * method in SQL's madness: if you don't do it this way you get reduce-
 * reduce conflicts, because it's not clear to the parser generator whether
 * to expect alias_clause after RPAREN or not.  For the same reason we must
 * treat 'JOIN' and 'join_type JOIN' separately, rather than allowing
 * join_type to expand to empty; if we try it, the parser generator can't
 * figure out when to reduce an empty join_type right after table_ref.
 *
 * Note that a CROSS JOIN is the same as an unqualified
 * INNER JOIN, and an INNER JOIN/ON has the same shape
 * but a qualification expression to limit membership.
 * A NATURAL JOIN implicitly matches column names between
 * tables and the shape is determined by which columns are
 * in common. We'll collect columns during the later transformations.
 *)

joined_table:
| LPAREN join = joined_table RPAREN
    { join }
| left = table_ref CROSS JOIN right = table_ref
    { { left; right; kind = Inner; cond = On (True Loc.dummy_loc);
	loc = Loc.loc $startpos $endpos } }
| left = table_ref kind = join_type JOIN right = table_ref cond = join_qual
    { { left; right; kind; cond; loc = Loc.loc $startpos $endpos } }
| left = table_ref JOIN right = table_ref cond = join_qual
    { { left; right; kind = Inner; cond;
	loc = Loc.loc $startpos $endpos } }
| left = table_ref NATURAL kind = join_type JOIN right = table_ref
    { { left; right; kind; cond = Natural;
	loc = Loc.loc $startpos $endpos } }
| left = table_ref NATURAL JOIN right = table_ref
    { { left; right; kind = Inner; cond = Natural;
	loc = Loc.loc $startpos $endpos } }

alias_clause:
| AS id = col_id LPAREN columns = name_list RPAREN
    { (id, columns) }
| AS id = col_id
    { (id, []) }
| id = col_id LPAREN columns = name_list RPAREN
    { (id, columns) }
| id = col_id
    { (id, []) }

(*
 * func_alias_clause can include both an Alias and a coldeflist, so we make it
 * return a 2-element list that gets disassembled by calling production.
 *)
func_alias_clause:
| alias_clause
| AS LPAREN table_func_element_list RPAREN
| AS col_id LPAREN table_func_element_list RPAREN
| col_id LPAREN table_func_element_list RPAREN
| (* EMPTY *)
{ }


join_type:
| FULL join_outer
    { Full_outer }
| LEFT join_outer
    { Left_outer }
| RIGHT join_outer
    { Right_outer }
| INNER_P
    { Inner }

(* OUTER is just noise... *)
join_outer:
| OUTER_P
| (* EMPTY *)
  { }

(* JOIN qualification clauses
 * Possibilities are:
 *    USING ( column list ) allows only unqualified column names,
 *                          which must match between tables.
 *    ON expr allows more general qualifications.
 *
 * We return USING as a List node, while an ON-expr will not be a List.
 *)

join_qual:
| USING LPAREN ids = name_list RPAREN
    { Using ids }
| ON e = a_expr
    { On e }


relation_expr:
| name = qualified_name
    { RelationName name }
| qualified_name STAR
| ONLY qualified_name
| ONLY LPAREN qualified_name RPAREN
    { Not_implemented_relation (Loc.loc $startpos $endpos) }



relation_expr_list:
| list = separated_nonempty_list(COMMA, relation_expr) { list }


(*
 * Given "UPDATE foo set set ...", we have to decide without looking any
 * further ahead whether the first "set" is an alias or the UPDATE's SET
 * keyword.  Since "set" is allowed as a column name both interpretations
 * are feasible.  We resolve the shift/reduce conflict by giving the first
 * relation_expr_opt_alias production a higher precedence than the SET token
 * has, causing the parser to prefer to reduce, in effect assuming that the
 * SET is not an alias.
 *)
relation_expr_opt_alias:
| rel = relation_expr                    %prec UMINUS
    { rel, None }
| rel = relation_expr ioption(AS) alias = col_id
    { rel, Some (alias) }



func_table:
| func_expr
{ }


where_clause:
| WHERE expr = a_expr { expr }

(* variant for UPDATE and DELETE *)
where_or_current_clause:
| WHERE expr = a_expr
    { `Expr expr}
| WHERE CURRENT_P OF name = cursor_name
    { `Current name }


opt_table_func_element_list:
| table_func_element_list
| (* EMPTY *)
{ }

table_func_element_list:
| table_func_element
| table_func_element_list COMMA table_func_element
{ }


table_func_element:
| col_id type_name opt_collate_clause
{ }


(*****************************************************************************
 *
 *    Type syntax
 *        SQL introduces a large amount of type-specific syntax.
 *        Define individual clauses to handle these cases, and use
 *         the generic case to handle regular type-extensible Postgres syntax.
 *        - thomas 1997-10-10
 *
 *****************************************************************************)

type_name:
| simple_type_name opt_array_bounds
| SETOF simple_type_name opt_array_bounds
(* SQL standard syntax, currently only one-dimensional *)
| simple_type_name ARRAY LBRACKET iconst RBRACKET
| SETOF simple_type_name ARRAY LBRACKET iconst RBRACKET
| simple_type_name ARRAY
| SETOF simple_type_name ARRAY
{ }


opt_array_bounds:
| opt_array_bounds LBRACKET RBRACKET
| opt_array_bounds LBRACKET iconst RBRACKET
| (* EMPTY *)
{ }


simple_type_name:
| generic_type
| numeric
| bit
| character
| const_datetime
| const_interval opt_interval
| const_interval LPAREN iconst RPAREN opt_interval
{ }


(* We have a separate const_type_name to allow defaulting fixed-length
 * types such as CHAR() and BIT() to an unspecified length.
 * SQL9x requires that these default to a length of one, but this
 * makes no sense for constructs like CHAR 'hi' and BIT '0101',
 * where there is an obvious better choice to make.
 * Note that const_interval is not included here since it must
 * be pushed up higher in the rules to accommodate the postfix
 * options (e.g. INTERVAL '1' YEAR). Likewise, we have to handle
 * the generic-type-name case in AExpr_const to avoid premature
 * reduce/reduce conflicts against function names.
 *)
const_type_name:
| numeric
| const_bit
| const_character
| const_datetime
{ }

(*
 * generic_type covers all type names that don't have special syntax mandated
 * by the standard, including qualified names.  We also allow type modifiers.
 * To avoid parsing conflicts against function invocations, the modifiers
 * have to be shown as expr_list here, but parse analysis will only accept
 * constants for them.
 *)
generic_type:
| type_function_name opt_type_modifiers
| type_function_name attrs opt_type_modifiers
{ }


opt_type_modifiers:
| LPAREN expr_list RPAREN
| (* EMPTY *)
{ }

(*
 * SQL numeric data types
 *)
numeric:
| INT_P
| INTEGER
| SMALLINT
| BIGINT
| REAL
| FLOAT_P opt_float
| DOUBLE_P PRECISION
| DECIMAL_P opt_type_modifiers
| DEC opt_type_modifiers
| NUMERIC opt_type_modifiers
| BOOLEAN_P
{ }


opt_float:
| LPAREN iconst RPAREN
| (* EMPTY *)
{ }


(*
 * SQL bit-field data types
 * The following implements BIT() and BIT VARYING().
 *)
bit:
| bit_with_length
| bit_without_length
{ }


(* const_bit is like bit except "BIT" defaults to unspecified length *)
(* See notes for const_character, which addresses same issue for "CHAR" *)
const_bit:
| bit_with_length
| bit_without_length
{ }


bit_with_length:
| BIT opt_varying LPAREN expr_list RPAREN
{ }

bit_without_length:
| BIT opt_varying
{ }



(*
 * SQL character data types
 * The following implements CHAR() and VARCHAR().
 *)
character:
| character_with_length
| character_without_length
{ }

const_character:
| character_with_length
| character_without_length
{ }


character_with_length:
| character LPAREN iconst RPAREN opt_charset
{ }


character_without_length:
| raw_character opt_charset
{ }


raw_character:
| CHARACTER opt_varying
| CHAR_P opt_varying
| VARCHAR
| NATIONAL CHARACTER opt_varying
| NATIONAL CHAR_P opt_varying
| NCHAR opt_varying
{ }


opt_varying:
| VARYING
| (* EMPTY *)
{ }

opt_charset:
| CHARACTER SET col_id
| (* EMPTY *)
{ }

(*
 * SQL date/time types
 *)
const_datetime:
| TIMESTAMP LPAREN iconst RPAREN opt_timezone
| TIMESTAMP opt_timezone
| TIME LPAREN iconst RPAREN opt_timezone
| TIME opt_timezone
{ }


const_interval:
| INTERVAL
{ }


opt_timezone:
| WITH_TIME ZONE
| WITHOUT TIME ZONE
| (* EMPTY *)
{ }

opt_interval:
| YEAR_P
| MONTH_P
| DAY_P
| HOUR_P
| MINUTE_P
| interval_second
| YEAR_P TO MONTH_P
| DAY_P TO HOUR_P
| DAY_P TO MINUTE_P
| DAY_P TO interval_second
| HOUR_P TO MINUTE_P
| HOUR_P TO interval_second
| MINUTE_P TO interval_second
| (* EMPTY *)
{ }


interval_second:
| SECOND_P
| SECOND_P LPAREN iconst RPAREN
{ }



(*****************************************************************************
 *
 *    expression grammar
 *
 *****************************************************************************)

(*
 * General expressions
 * This is the heart of the expression syntax.
 *
 * We have two expression types: a_expr is the unrestricted kind, and
 * b_expr is a subset that must be used in some places to avoid shift/reduce
 * conflicts.  For example, we can't do BETWEEN as "BETWEEN a_expr AND a_expr"
 * because that use of AND conflicts with AND as a boolean operator.  So,
 * b_expr is used in BETWEEN and we remove boolean keywords from b_expr.
 *
 * Note that LPAREN a_expr RPAREN is a b_expr, so an unrestricted expression can
 * always be used by surrounding it with parens.
 *
 * c_expr is all the productions that are common to a_expr and b_expr;
 * it's factored out just to eliminate redundant coding.
 *)
a_expr:
| e = c_expr
    { e }
| a_expr TYPECAST type_name
| a_expr COLLATE any_name
| a_expr AT TIME ZONE a_expr      %prec AT
    { Not_implemented_expr (Loc.loc $startpos $endpos) }
(*
 * These operators must be called out explicitly in order to make use
 * of bison's automatic operator-precedence handling.  All other
 * operator names are handled by the generic productions using "Op",
 * below; and all those operators will have the same precedence.
 *
 * If you add more explicitly-known operators, be sure to add them
 * also to b_expr and to the math_op list above.
 *)
| PLUS e = a_expr                     %prec UMINUS
    { e }
| MINUS e = a_expr                    %prec UMINUS
    { UnOp (UMinus, e, Loc.loc $startpos $endpos) }
| e1 = a_expr PLUS e2 = a_expr
    { BinOp(Plus, e1, e2, Loc.loc $startpos $endpos) }
| e1 = a_expr MINUS e2 = a_expr
    { BinOp (Minus, e1, e2, Loc.loc $startpos $endpos) }
| e1 = a_expr STAR e2 = a_expr
    { BinOp (Mult, e1, e2, Loc.loc $startpos $endpos) }
| e1 = a_expr DIV e2 = a_expr
    { BinOp (Div, e1, e2, Loc.loc $startpos $endpos) }
| e1 = a_expr PERCENT e2 = a_expr
    { BinOp (Mod, e1, e2, Loc.loc $startpos $endpos) }
| e1 = a_expr CARET e2 = a_expr
    { BinOp (Pow, e1, e2, Loc.loc $startpos $endpos) }
| e1 = a_expr LT e2 = a_expr
    { BinOp (Lt, e1, e2, Loc.loc $startpos $endpos) }
| e1 = a_expr GT e2 = a_expr
    { BinOp (Gt, e1, e2, Loc.loc $startpos $endpos) }
| e1 = a_expr EQ e2 = a_expr
    { BinOp (Eq, e1, e2, Loc.loc $startpos $endpos) }
| e1 = a_expr op = qual_op e2 = a_expr            %prec Op
    { BinOp (BOp op, e1, e2, Loc.loc $startpos $endpos) }
| op = qual_op e = a_expr                   %prec Op
| e = a_expr op = qual_op                   %prec POSTFIXOP
    { UnOp (UOp op, e, Loc.loc $startpos $endpos) }
| e1 = a_expr AND e2 = a_expr
    { BinOp (And, e1, e2, Loc.loc $startpos $endpos) }
| e1 = a_expr OR e2 = a_expr
    { BinOp (Or, e1, e2, Loc.loc $startpos $endpos) }
| NOT e = a_expr
    { UnOp (Not, e, Loc.loc $startpos $endpos) }
| a_expr LIKE a_expr
| a_expr LIKE a_expr ESCAPE a_expr
| a_expr NOT LIKE a_expr
| a_expr NOT LIKE a_expr ESCAPE a_expr
| a_expr ILIKE a_expr
| a_expr ILIKE a_expr ESCAPE a_expr
| a_expr NOT ILIKE a_expr
| a_expr NOT ILIKE a_expr ESCAPE a_expr
| a_expr SIMILAR TO a_expr                %prec SIMILAR
| a_expr SIMILAR TO a_expr ESCAPE a_expr
| a_expr NOT SIMILAR TO a_expr            %prec SIMILAR
| a_expr NOT SIMILAR TO a_expr ESCAPE a_expr
    { Not_implemented_expr (Loc.loc $startpos $endpos) }
(* Null_test clause
 * Define SQL-style Null test clause.
 * Allow two forms described in the standard:
 *    a IS NULL
 *    a IS NOT NULL
 * Allow two SQL extensions
 *    a ISNULL
 *    a NOTNULL
 *)
| e = a_expr IS NULL_P                         (* %prec IS *) (* MENHIR *)
| e = a_expr ISNULL
    { UnOp (IsNull, e, Loc.loc $startpos $endpos) }
| e = a_expr IS NOT NULL_P                     (* %prec IS *) (* MENHIR *)
| e = a_expr NOTNULL
    { UnOp (IsNotNull, e, Loc.loc $startpos $endpos) }
| row OVERLAPS row
    { Not_implemented_expr (Loc.loc $startpos $endpos) }
| e = a_expr IS TRUE_P                         (* %prec IS *) (* MENHIR *)
    { UnOp(IsTrue, e, Loc.loc $startpos $endpos) }
| e = a_expr IS NOT TRUE_P                     (* %prec IS *) (* MENHIR *)
    { UnOp (IsNotTrue, e, Loc.loc $startpos $endpos) }
| e = a_expr IS FALSE_P                        (* %prec IS *) (* MENHIR *)
    { UnOp (IsFalse, e, Loc.loc $startpos $endpos) }
| e = a_expr IS NOT FALSE_P                    (* %prec IS *) (* MENHIR *)
    { UnOp (IsNotFalse, e, Loc.loc $startpos $endpos) }
| a_expr IS UNKNOWN                        (* %prec IS *) (* MENHIR *)
| a_expr IS NOT UNKNOWN                    (* %prec IS *) (* MENHIR *)
| a_expr IS DISTINCT FROM a_expr              %prec IS
| a_expr IS NOT DISTINCT FROM a_expr          %prec IS
| a_expr IS OF LPAREN type_list RPAREN     (* %prec IS *) (* MENHIR *)
| a_expr IS NOT OF LPAREN type_list RPAREN (* %prec IS *) (* MENHIR *)
(*
 *    Ideally we would not use hard-wired operators below but
 *    instead use opclasses.  However, mixed data types and other
 *    issues make this difficult:
 *    http://archives.postgresql.org/pgsql-hackers/2008-08/msg01142.php
 *)
| a_expr BETWEEN opt_asymmetric b_expr AND b_expr        %prec BETWEEN
| a_expr NOT BETWEEN opt_asymmetric b_expr AND b_expr    %prec BETWEEN
| a_expr BETWEEN SYMMETRIC b_expr AND b_expr            %prec BETWEEN
| a_expr NOT BETWEEN SYMMETRIC b_expr AND b_expr        %prec BETWEEN
| a_expr IN_P in_expr
| a_expr NOT IN_P in_expr
| a_expr subquery_op sub_type select_with_parens    (* %prec Op *) (* MENHIR *)
| a_expr subquery_op sub_type LPAREN a_expr RPAREN        (* %prec Op *) (* MENHIR *)
| UNIQUE select_with_parens
| a_expr IS DOCUMENT_P                    (* %prec IS *) (* MENHIR *)
| a_expr IS NOT DOCUMENT_P                (* %prec IS *) (* MENHIR *)
    { Not_implemented_expr (Loc.loc $startpos $endpos) }

(*
 * Restricted expressions
 *
 * b_expr is a subset of the complete expression syntax defined by a_expr.
 *
 * Presently, AND, NOT, IS, and IN are the a_expr keywords that would
 * cause trouble in the places where b_expr is used.  For simplicity, we
 * just eliminate all the boolean-keyword-operator productions from b_expr.
 *)
b_expr:
| e = c_expr
    { e }
| b_expr TYPECAST type_name
    { Not_implemented_expr (Loc.loc $startpos $endpos) }
| PLUS e = b_expr                     %prec UMINUS
    { e }
| MINUS e = b_expr                    %prec UMINUS
    { UnOp (UMinus, e, Loc.loc $startpos $endpos) }
| e1 = b_expr PLUS e2 = b_expr
    { BinOp (Plus, e1, e2, Loc.loc $startpos $endpos) }
| e1 = b_expr MINUS e2 = b_expr
    { BinOp (Minus, e1, e2, Loc.loc $startpos $endpos) }
| e1 = b_expr STAR e2 = b_expr
    { BinOp (Mult, e1, e2, Loc.loc $startpos $endpos) }
| e1 = b_expr DIV e2 = b_expr
    { BinOp (Div, e1, e2, Loc.loc $startpos $endpos) }
| e1 = b_expr PERCENT e2 = b_expr
    { BinOp (Mod, e1, e2, Loc.loc $startpos $endpos) }
| e1 = b_expr CARET e2 = b_expr
    { BinOp (Pow, e1, e2, Loc.loc $startpos $endpos) }
| e1 = b_expr LT e2 = b_expr
    { BinOp (Lt, e1, e2, Loc.loc $startpos $endpos) }
| e1 = b_expr GT e2 = b_expr
    { BinOp (Gt, e1, e2, Loc.loc $startpos $endpos) }
| e1 = b_expr EQ e2 = b_expr
    { BinOp (Eq, e1, e2, Loc.loc $startpos $endpos) }
| e1 = b_expr op = qual_op e2 = b_expr                 %prec Op
    { BinOp (BOp op, e1, e2, Loc.loc $startpos $endpos) }
| op = qual_op e = b_expr                        %prec Op
| e = b_expr op = qual_op                        %prec POSTFIXOP
    { UnOp (UOp op, e, Loc.loc $startpos $endpos) }
| b_expr IS DISTINCT FROM b_expr        %prec IS
| b_expr IS NOT DISTINCT FROM b_expr    %prec IS
| b_expr IS OF LPAREN type_list RPAREN        (* %prec IS *) (* MENHIR *)
| b_expr IS NOT OF LPAREN type_list RPAREN    (* %prec IS *) (* MENHIR *)
| b_expr IS DOCUMENT_P               (* %prec IS *) (* MENHIR *)
| b_expr IS NOT DOCUMENT_P           (* %prec IS *) (* MENHIR *)
    { Not_implemented_expr (Loc.loc $startpos $endpos) }

(*
 * Productions that can be used in both a_expr and b_expr.
 *
 * Note: productions that refer recursively to a_expr or b_expr mostly
 * cannot appear here.    However, it's OK to refer to a_exprs that occur
 * inside parentheses, such as function arguments; that cannot introduce
 * ambiguity to the b_expr syntax.
 *)
c_expr:
| id = col_id indir = list(indirection_el)
    { Column_ref (id, indir, Loc.loc $startpos $endpos) }
| const = a_expr_const
    { const }
| PARAM option(indirection_el)
    { Not_implemented_expr (Loc.loc $startpos $endpos) }
| LPAREN e = a_expr RPAREN
    { e }
| LPAREN a_expr RPAREN indirection_el
| case_expr
| func_expr
| select_with_parens                               %prec UMINUS
| select_with_parens nonempty_list(indirection_el)
| EXISTS select_with_parens
| ARRAY select_with_parens
| ARRAY array_expr
| row
    { Not_implemented_expr (Loc.loc $startpos $endpos) }


(*
 * func_expr is split out from c_expr just so that we have a classification
 * for "everything that is a function call or looks like one".  This isn't
 * very important, but it saves us having to document which variants are
 * legal in the backwards-compatible functional-index syntax for CREATE INDEX.
 * (Note that many of the special SQL functions wouldn't actually make any
 * sense as functional index entries, but we ignore that consideration here.)
 *)
func_expr:
| func_name LPAREN RPAREN over_clause
| func_name LPAREN func_arg_list RPAREN over_clause
| func_name LPAREN VARIADIC func_arg_expr RPAREN over_clause
| func_name LPAREN func_arg_list COMMA VARIADIC func_arg_expr RPAREN over_clause
| func_name LPAREN func_arg_list sort_clause RPAREN over_clause
| func_name LPAREN ALL func_arg_list opt_sort_clause RPAREN over_clause
| func_name LPAREN DISTINCT func_arg_list opt_sort_clause RPAREN over_clause
| func_name LPAREN STAR RPAREN over_clause
| COLLATION FOR LPAREN a_expr RPAREN
| CURRENT_DATE
| CURRENT_TIME
| CURRENT_TIME LPAREN iconst RPAREN
| CURRENT_TIMESTAMP
| CURRENT_TIMESTAMP LPAREN iconst RPAREN
| LOCALTIME
| LOCALTIME LPAREN iconst RPAREN
| LOCALTIMESTAMP
| LOCALTIMESTAMP LPAREN iconst RPAREN
| CURRENT_ROLE
| CURRENT_USER
| SESSION_USER
| USER
| CURRENT_CATALOG
| CURRENT_SCHEMA
| CAST LPAREN a_expr AS type_name RPAREN
| EXTRACT LPAREN extract_list RPAREN
| OVERLAY LPAREN overlay_list RPAREN
| POSITION LPAREN position_list RPAREN
| SUBSTRING LPAREN substr_list RPAREN
| TREAT LPAREN a_expr AS type_name RPAREN
| TRIM LPAREN BOTH trim_list RPAREN
| TRIM LPAREN LEADING trim_list RPAREN
| TRIM LPAREN TRAILING trim_list RPAREN
| TRIM LPAREN trim_list RPAREN
| NULLIF LPAREN a_expr COMMA a_expr RPAREN
| COALESCE LPAREN expr_list RPAREN
| GREATEST LPAREN expr_list RPAREN
| LEAST LPAREN expr_list RPAREN
| XMLCONCAT LPAREN expr_list RPAREN
| XMLELEMENT LPAREN NAME_P col_label RPAREN
| XMLELEMENT LPAREN NAME_P col_label COMMA xml_attributes RPAREN
| XMLELEMENT LPAREN NAME_P col_label COMMA expr_list RPAREN
| XMLELEMENT LPAREN NAME_P col_label COMMA xml_attributes COMMA expr_list RPAREN
| XMLEXISTS LPAREN c_expr xmlexists_argument RPAREN
| XMLFOREST LPAREN xml_attribute_list RPAREN
| XMLPARSE LPAREN document_or_content a_expr xml_whitespace_option RPAREN
| XMLPI LPAREN NAME_P col_label RPAREN
| XMLPI LPAREN NAME_P col_label COMMA a_expr RPAREN
| XMLROOT LPAREN a_expr COMMA xml_root_version opt_xml_root_standalone RPAREN
| XMLSERIALIZE LPAREN document_or_content a_expr AS simple_type_name RPAREN
{ }


(*
 * SQL/XML support
 *)
xml_root_version:
| VERSION_P a_expr
| VERSION_P NO VALUE_P
{ }


opt_xml_root_standalone:
| COMMA STANDALONE_P YES_P
| COMMA STANDALONE_P NO
| COMMA STANDALONE_P NO VALUE_P
| (* EMPTY *)
{ }


xml_attributes:
| XMLATTRIBUTES LPAREN xml_attribute_list RPAREN
{ }

xml_attribute_list:
| xml_attribute_el
| xml_attribute_list COMMA xml_attribute_el
{ }

xml_attribute_el:
| a_expr AS col_label
| a_expr
{ }


document_or_content:
| DOCUMENT_P
| CONTENT_P
{ }

xml_whitespace_option:
| PRESERVE WHITESPACE_P
| STRIP_P WHITESPACE_P
| (* EMPTY *)
{ }

(* We allow several variants for SQL and other compatibility. *)
xmlexists_argument:
| PASSING c_expr
| PASSING c_expr BY REF
| PASSING BY REF c_expr
| PASSING BY REF c_expr BY REF
{ }



(*
 * Window Definitions
 *)
window_clause:
| WINDOW window_definition_list
| (* EMPTY *)
{ }

window_definition_list:
| window_definition
| window_definition_list COMMA window_definition
{ }


window_definition:
| col_id AS window_specification
{ }


over_clause:
| OVER window_specification
| OVER col_id
| (* EMPTY *)
{ }


window_specification:
| LPAREN opt_existing_window_name opt_partition_clause
                        opt_sort_clause opt_frame_clause RPAREN
{ }


(*
 * If we see PARTITION, RANGE, or ROWS as the first token after the LPAREN
 * of a window_specification, we want the assumption to be that there is
 * no existing_window_name; but those keywords are unreserved and so could
 * be col_ids.  We fix this by making them have the same precedence as IDENT
 * and giving the empty production here a slightly higher precedence, so
 * that the shift/reduce conflict is resolved in favor of reducing the rule.
 * These keywords are thus precluded from being an existing_window_name but
 * are not reserved for any other purpose.
 *)
opt_existing_window_name:
| col_id
| (* EMPTY *)                %prec Op
{ }

opt_partition_clause:
| PARTITION BY expr_list
| (* EMPTY *)
{ }

(*
 * For frame clauses, we return a Window_def, but only some fields are used:
 * frame_options, start_offset, and end_offset.
 *
 * This is only a subset of the full SQL:2008 frame_clause grammar.
 * We don't support <window frame exclusion> yet.
 *)
opt_frame_clause:
| RANGE frame_extent
| ROWS frame_extent
| (* EMPTY *)
{ }


frame_extent:
| frame_bound
| BETWEEN frame_bound AND frame_bound
{ }


(*
 * This is used for both frame start and frame end, with output set up on
 * the assumption it's frame start; the frame_extent productions must reject
 * invalid cases.
 *)
frame_bound:
| UNBOUNDED PRECEDING
| UNBOUNDED FOLLOWING
| CURRENT_P ROW
| a_expr PRECEDING
| a_expr FOLLOWING
{ }



(*
 * Supporting nonterminals for expressions.
 *)

(* Explicit row production.
 *
 * SQL99 allows an optional ROW keyword, so we can now do single-element rows
 * without conflicting with the parenthesized a_expr production.  Without the
 * ROW keyword, there must be more than one a_expr inside the parens.
 *)
row:
| ROW LPAREN expr_list RPAREN
| ROW LPAREN RPAREN
| LPAREN a_expr COMMA expr_list RPAREN
{ }

sub_type:
| ANY
| SOME
| ALL
{ }

all_op:
| Op
| math_op
{ }

math_op:
| PLUS
| MINUS
| STAR
| DIV
| PERCENT
| CARET
| LT
| GT
| EQ
{ }

qual_op:
| op = Op { `Op op }
| OPERATOR LPAREN op = any_operator RPAREN { `Any op }


qual_all_op:
| all_op
| OPERATOR LPAREN any_operator RPAREN
{ }


subquery_op:
| all_op
| OPERATOR LPAREN any_operator RPAREN
| LIKE
| NOT LIKE
| ILIKE
| NOT ILIKE
{ }

(* cannot put SIMILAR TO here, because SIMILAR TO is a hack.
 * the regular expression is preprocessed by a function (similar_escape),
 * and the ~ operator for posix regular expressions is used.
 *        x SIMILAR TO y     ->    x ~ similar_escape(y)
 * this transformation is made on the fly by the parser upwards.
 * however the Sub_link structure which handles any/some/all stuff
 * is not ready for such a thing.
 *)
expr_list:
| list = separated_nonempty_list(COMMA, a_expr)
    { list }


(* function arguments can have names *)
func_arg_list:
| func_arg_expr
| func_arg_list COMMA func_arg_expr
{ }


func_arg_expr:
| a_expr
| param_name COLON_EQUALS a_expr
{ }


type_list:
| type_name
| type_list COMMA type_name
{ }

array_expr:
| LBRACKET expr_list RBRACKET
| LBRACKET array_expr_list RBRACKET
| LBRACKET RBRACKET
{ }


array_expr_list:
| array_expr
| array_expr_list COMMA array_expr
{ }


extract_list:
| extract_arg FROM a_expr
| (* EMPTY *)
{ }

(* Allow delimited string sconst in extract_arg as an SQL extension.
 * - thomas 2001-04-12
 *)
extract_arg:
| IDENT
| YEAR_P
| MONTH_P
| DAY_P
| HOUR_P
| MINUTE_P
| SECOND_P
| sconst
{ }

(* OVERLAY() arguments
 * SQL99 defines the OVERLAY() function:
 * o overlay(text placing text from int for int)
 * o overlay(text placing text from int)
 * and similarly for binary strings
 *)
overlay_list:
| a_expr overlay_placing substr_from substr_for
| a_expr overlay_placing substr_from
{ }


overlay_placing:
| PLACING a_expr
{ }


(* position_list uses b_expr not a_expr to avoid conflict with general IN *)

position_list:
| b_expr IN_P b_expr
| (* EMPTY *)
{ }

(* SUBSTRING() arguments
 * SQL9x defines a specific syntax for arguments to SUBSTRING():
 * o substring(text from int for int)
 * o substring(text from int) get entire string from starting point "int"
 * o substring(text for int) get first "int" characters of string
 * o substring(text from pattern) get entire string matching pattern
 * o substring(text from pattern for escape) same with specified escape char
 * We also want to support generic substring functions which accept
 * the usual generic list of arguments. So we will accept both styles
 * here, and convert the SQL9x style to the generic list for further
 * processing. - thomas 2000-11-28
 *)
substr_list:
| a_expr substr_from substr_for
| a_expr substr_for substr_from
| a_expr substr_from
| a_expr substr_for
| expr_list
| (* EMPTY *)
{ }


substr_from:
| FROM a_expr
{ }

substr_for:
| FOR a_expr
{ }

trim_list:
| a_expr FROM expr_list
| FROM expr_list
| expr_list
{ }

in_expr:
| select_with_parens
| LPAREN expr_list RPAREN
{ }

(*
 * Define SQL-style CASE clause.
 * - Full specification
 *    CASE WHEN a = b THEN c ... ELSE d END
 * - Implicit argument
 *    CASE a WHEN b THEN c ... ELSE d END
 *)
case_expr:
| CASE case_arg when_clause_list case_default END_P
{ }


when_clause_list:
  (* There must be at least one *)
| when_clause
| when_clause_list when_clause
{ }

when_clause:
| WHEN a_expr THEN a_expr
{ }


case_default:
| ELSE a_expr
| (* EMPTY *)
{ }

case_arg:
| a_expr
| (* EMPTY *)
{ }

indirection_el:
| DOT name = attr_name
    { IDot (name, Loc.loc $startpos $endpos) }
| DOT STAR
    { IDotStar (Loc.loc $startpos $endpos) }
| LBRACKET e = a_expr RBRACKET
    { IBracket (e, None, Loc.loc $startpos $endpos) }
| LBRACKET e1 = a_expr COLON e2 = a_expr RBRACKET
    { IBracket (e1, Some e2, Loc.loc $startpos $endpos) }

indirection:
| list = nonempty_list(indirection_el) { list }

opt_asymmetric:
| ASYMMETRIC
| (* EMPTY *)
{ }

(*
 * The SQL spec defines "contextually typed value expressions" and
 * "contextually typed row value constructors", which for our purposes
 * are the same as "a_expr" and "row" except that DEFAULT can appear at
 * the top level.
 *)

ctext_expr:
| e = a_expr
    { (Some e, Loc.loc $startpos $endpos) }
| DEFAULT
    { (None, Loc.loc $startpos $endpos) }

(*
 * We should allow ROW LPAREN ctext_expr_list RPAREN too, but that seems to require
 * making VALUES a fully reserved word, which will probably break more apps
 * than allowing the noise-word is worth.
 *)
ctext_row:
| LPAREN list = separated_nonempty_list (COMMA, ctext_expr) RPAREN
    { list }


(*****************************************************************************
 *
 *    target list for SELECT
 *
 *****************************************************************************)

target_el:
| expr = a_expr AS id = col_label
    { Expr (expr, Some id, Loc.loc $startpos $endpos) }
(*
 * We support omitting AS only for column labels that aren't
 * any known keyword.  There is an ambiguity against postfix
 * operators: is "a ! b" an infix expression, or a postfix
 * expression and a column label?  We prefer to resolve this
 * as an infix expression, which we accomplish by assigning
 * IDENT a precedence higher than POSTFIXOP.
 *)
| expr = a_expr id = IDENT
    { Expr (expr, Some (mkloc id (Loc.loc $startpos(id) $endpos(id))),
	    Loc.loc $startpos $endpos) }
| expr = a_expr { Expr (expr, None, Loc.loc $startpos $endpos) }
| STAR { Star (Loc.loc $startpos $endpos) }



(*****************************************************************************
 *
 *    Names and constants
 *
 *****************************************************************************)

qualified_name_list:
| list = separated_nonempty_list(COMMA, qualified_name) { list }

(*
 * The production for a qualified relation name has to exactly match the
 * production for a qualified func_name, because in a FROM clause we cannot
 * tell which we are parsing until we see what comes after it (LPAREN for a
 * func_name, something else for a relation). Therefore we allow 'indirection'
 * which may contain subscripts, and reject that case in the C code.
 *)
qualified_name:
| id = col_id { (id, [], Loc.loc $startpos $endpos) }
| id = col_id indir = indirection { (id, indir, Loc.loc $startpos $endpos) }

name_list:
| list = separated_nonempty_list(COMMA, name) { list }

name:
| id = col_id { id }

database_name:
| id = col_id { id }

access_method:
| id = col_id { id }

attr_name:
| lbl = col_label { lbl }

index_name:
| id = col_id { id }

file_name:
| name = sconst { (name, Loc.loc $startpos $endpos) }

(*
 * The production for a qualified func_name has to exactly match the
 * production for a qualified columnref, because we cannot tell which we
 * are parsing until we see what comes after it (LPAREN or sconst for a func_name,
 * anything else for a columnref).  Therefore we allow 'indirection' which
 * may contain subscripts, and reject that case in the C code.  (If we
 * ever implement SQL99-like methods, such syntax may actually become legal!)
 *)
func_name:
| type_function_name
| col_id indirection
{ }



(*
 * Constants
 *)
a_expr_const:
| iconst = iconst { Int (iconst, Loc.loc $startpos $endpos) }
| fconst = FCONST { Float (fconst, Loc.loc $startpos $endpos) }
| sconst = SCONST { String (sconst, Loc.loc $startpos $endpos) }
| bconst = BCONST { Bitstring (bconst, Loc.loc $startpos $endpos) }
| func_name sconst
| func_name LPAREN func_arg_list RPAREN sconst
| const_type_name sconst
| const_interval sconst opt_interval
| const_interval LPAREN iconst RPAREN sconst opt_interval
    { Not_implemented_expr (Loc.loc $startpos $endpos) }
| TRUE_P  { True (Loc.loc $startpos $endpos) }
| FALSE_P { False (Loc.loc $startpos $endpos) }
| NULL_P  { Null (Loc.loc $startpos $endpos) }

iconst:
| iconst = ICONST { iconst }

sconst:
| sconst = SCONST { sconst }

role_id:
| id = non_reserved_word { id }

signed_iconst:
| iconst
| PLUS iconst
| MINUS iconst
{ }

(*
 * Name classification hierarchy.
 *
 * IDENT is the lexeme returned by the lexer for identifiers that match
 * no known keyword.  In most cases, we can accept certain keywords as
 * names, not only IDENTs.    We prefer to accept as many such keywords
 * as possible to minimize the impact of "reserved words" on programmers.
 * So, we divide names into several possible classes.  The classification
 * is chosen in part to make keywords acceptable as names wherever possible.
 *)

(* Column identifier --- names that can be column, table, etc names.
 *)
col_id:
| id = IDENT
| id = unreserved_keyword
| id = col_name_keyword
{ mkloc id (Loc.loc $startpos $endpos) }

(* Type/function identifier --- names that can be type or function names.
 *)
type_function_name:
| id = IDENT
| id = unreserved_keyword
| id = type_func_name_keyword
{ mkloc id (Loc.loc $startpos $endpos) }

(* Any not-fully-reserved word --- these names can be, eg, role names.
 *)
non_reserved_word:
| id = IDENT
| id = unreserved_keyword
| id = col_name_keyword
| id = type_func_name_keyword
{ mkloc id (Loc.loc $startpos $endpos) }

(* Column label --- allowed labels in "AS" clauses.
 * This presently includes *all* Postgres keywords.
 *)
col_label:
| id = IDENT
| id = unreserved_keyword
| id = col_name_keyword
| id = type_func_name_keyword
| id = reserved_keyword
    { mkloc id (Loc.loc $startpos $endpos) }


(*
 * Keyword category lists.  Generally, every keyword present in
 * the Postgres grammar should appear in exactly one of these lists.
 *
 * Put a new keyword into the first list that it can go into without causing
 * shift or reduce conflicts.  The earlier lists define "less reserved"
 * categories of keywords.
 *
 * Make sure that each keyword's category in kwlist.h matches where
 * it is listed here.  (Someday we may be able to generate these lists and
 * kwlist.h's table from a common master list.)
 *)

(* "Unreserved" keywords --- available for use as any kind of name.
 *)
unreserved_keyword:
| ABORT_P { "abort" }
| ABSOLUTE_P { "absolute" }
| ACCESS { "access" }
| ACTION { "action" }
| ADD_P { "add" }
| ADMIN { "admin" }
| AFTER { "after" }
| AGGREGATE { "aggregate" }
| ALSO { "also" }
| ALTER { "alter" }
| ALWAYS { "always" }
| ASSERTION { "assertion" }
| ASSIGNMENT { "assignment" }
| AT { "at" }
| ATTRIBUTE { "attribute" }
| BACKWARD { "backward" }
| BEFORE { "before" }
| BEGIN_P { "begin" }
| BY { "by" }
| CACHE { "cache" }
| CALLED { "called" }
| CASCADE { "cascade" }
| CASCADED { "cascaded" }
| CATALOG_P { "catalog" }
| CHAIN { "chain" }
| CHARACTERISTICS { "characteristics" }
| CHECKPOINT { "checkpoint" }
| CLASS { "class" }
| CLOSE { "close" }
| CLUSTER { "cluster" }
| COMMENT { "comment" }
| COMMENTS { "comments" }
| COMMIT { "commit" }
| COMMITTED { "committed" }
| CONFIGURATION { "configuration" }
| CONNECTION { "connection" }
| CONSTRAINTS { "constraints" }
| CONTENT_P { "content" }
| CONTINUE_P { "continue" }
| CONVERSION_P { "conversion" }
| COPY { "copy" }
| COST { "cost" }
| CSV { "csv" }
| CURRENT_P { "current" }
| CURSOR { "cursor" }
| CYCLE { "cycle" }
| DATA_P { "data" }
| DATABASE { "database" }
| DAY_P { "day" }
| DEALLOCATE { "deallocate" }
| DECLARE { "declare" }
| DEFAULTS { "defaults" }
| DEFERRED { "deferred" }
| DEFINER { "definer" }
| DELETE_P { "delete" }
| DELIMITER { "delimiter" }
| DELIMITERS { "delimiters" }
| DICTIONARY { "dictionary" }
| DISABLE_P { "disable" }
| DISCARD { "discard" }
| DOCUMENT_P { "document" }
| DOMAIN_P { "domain" }
| DOUBLE_P { "double" }
| DROP { "drop" }
| EACH { "each" }
| ENABLE_P { "enable" }
| ENCODING { "encoding" }
| ENCRYPTED { "encrypted" }
| ENUM_P { "enum" }
| ESCAPE { "escape" }
| EVENT { "event" }
| EXCLUDE { "exclude" }
| EXCLUDING { "excluding" }
| EXCLUSIVE { "exclusive" }
| EXECUTE { "execute" }
| EXPLAIN { "explain" }
| EXTENSION { "extension" }
| EXTERNAL { "external" }
| FAMILY { "family" }
| FIRST_P { "first" }
| FOLLOWING { "following" }
| FORCE { "force" }
| FORWARD { "forward" }
| FUNCTION { "function" }
| FUNCTIONS { "functions" }
| GLOBAL { "global" }
| GRANTED { "granted" }
| HANDLER { "handler" }
| HEADER_P { "header" }
| HOLD { "hold" }
| HOUR_P { "hour" }
| IDENTITY_P { "identity" }
| IF_P { "if" }
| IMMEDIATE { "immediate" }
| IMMUTABLE { "immutable" }
| IMPLICIT_P { "implicit" }
| INCLUDING { "including" }
| INCREMENT { "increment" }
| INDEX { "index" }
| INDEXES { "indexes" }
| INHERIT { "inherit" }
| INHERITS { "inherits" }
| INLINE_P { "inline" }
| INPUT_P { "input" }
| INSENSITIVE { "insensitive" }
| INSERT { "insert" }
| INSTEAD { "instead" }
| INVOKER { "invoker" }
| ISOLATION { "isolation" }
| KEY { "key" }
| LABEL { "label" }
| LANGUAGE { "language" }
| LARGE_P { "large" }
| LAST_P { "last" }
| LC_COLLATE_P { "lc_collate" }
| LC_CTYPE_P { "lc_ctype" }
| LEAKPROOF { "leakproof" }
| LEVEL { "level" }
| LISTEN { "listen" }
| LOAD { "load" }
| LOCAL { "local" }
| LOCATION { "location" }
| LOCK_P { "lock" }
| MAPPING { "mapping" }
| MATCH { "match" }
| MATERIALIZED { "materialized" }
| MAXVALUE { "maxvalue" }
| MINUTE_P { "minute" }
| MINVALUE { "minvalue" }
| MODE { "mode" }
| MONTH_P { "month" }
| MOVE { "move" }
| NAME_P { "name" }
| NAMES { "names" }
| NEXT { "next" }
| NO { "no" }
| NOTHING { "nothing" }
| NOTIFY { "notify" }
| NOWAIT { "nowait" }
| NULLS_P { "nulls" }
| OBJECT_P { "object" }
| OF { "of" }
| OFF { "off" }
| OIDS { "oids" }
| OPERATOR { "operator" }
| OPTION { "option" }
| OPTIONS { "options" }
| OWNED { "owned" }
| OWNER { "owner" }
| PARSER { "parser" }
| PARTIAL { "partial" }
| PARTITION { "partition" }
| PASSING { "passing" }
| PASSWORD { "password" }
| PLANS { "plans" }
| PRECEDING { "preceding" }
| PREPARE { "prepare" }
| PREPARED { "prepared" }
| PRESERVE { "preserve" }
| PRIOR { "prior" }
| PRIVILEGES { "privileges" }
| PROCEDURAL { "procedural" }
| PROCEDURE { "procedure" }
| PROGRAM { "program" }
| QUOTE { "quote" }
| RANGE { "range" }
| READ { "read" }
| REASSIGN { "reassign" }
| RECHECK { "recheck" }
| RECURSIVE { "recursive" }
| REF { "ref" }
| REFRESH { "refresh" }
| REINDEX { "reindex" }
| RELATIVE_P { "relative" }
| RELEASE { "release" }
| RENAME { "rename" }
| REPEATABLE { "repeatable" }
| REPLACE { "replace" }
| REPLICA { "replica" }
| RESET { "reset" }
| RESTART { "restart" }
| RESTRICT { "restrict" }
| RETURNS { "returns" }
| REVOKE { "revoke" }
| ROLE { "role" }
| ROLLBACK { "rollback" }
| ROWS { "rows" }
| RULE { "rule" }
| SAVEPOINT { "savepoint" }
| SCHEMA { "schema" }
| SCROLL { "scroll" }
| SEARCH { "search" }
| SECOND_P { "second" }
| SECURITY { "security" }
| SEQUENCE { "sequence" }
| SEQUENCES { "sequences" }
| SERIALIZABLE { "serializable" }
| SERVER { "server" }
| SESSION { "session" }
| SET { "set" }
| SHARE { "share" }
| SHOW { "show" }
| SIMPLE { "simple" }
| SNAPSHOT { "snapshot" }
| STABLE { "stable" }
| STANDALONE_P { "standalone" }
| START { "start" }
| STATEMENT { "statement" }
| STATISTICS { "statistics" }
| STDIN { "stdin" }
| STDOUT { "stdout" }
| STORAGE { "storage" }
| STRICT_P { "strict" }
| STRIP_P { "strip" }
| SYSID { "sysid" }
| SYSTEM_P { "system" }
| TABLES { "tables" }
| TABLESPACE { "tablespace" }
| TEMP { "temp" }
| TEMPLATE { "template" }
| TEMPORARY { "temporary" }
| TEXT_P { "text" }
| TRANSACTION { "transaction" }
| TRIGGER { "trigger" }
| TRUNCATE { "truncate" }
| TRUSTED { "trusted" }
| TYPE_P { "type" }
| TYPES_P { "types" }
| UNBOUNDED { "unbounded" }
| UNCOMMITTED { "uncommitted" }
| UNENCRYPTED { "unencrypted" }
| UNKNOWN { "unknown" }
| UNLISTEN { "unlisten" }
| UNLOGGED { "unlogged" }
| UNTIL { "until" }
| UPDATE { "update" }
| VACUUM { "vacuum" }
| VALID { "valid" }
| VALIDATE { "validate" }
| VALIDATOR { "validator" }
| VALUE_P { "value" }
| VARYING { "varying" }
| VERSION_P { "version" }
| VIEW { "view" }
| VOLATILE { "volatile" }
| WHITESPACE_P { "whitespace" }
| WITHOUT { "without" }
| WORK { "work" }
| WRAPPER { "wrapper" }
| WRITE { "write" }
| XML_P { "xml" }
| YEAR_P { "year" }
| YES_P { "yes" }
| ZONE { "zone" }

(* Column identifier --- keywords that can be column, table, etc names.
 *
 * Many of these keywords will in fact be recognized as type or function
 * names too; but they have special productions for the purpose, and so
 * can't be treated as "generic" type or function names.
 *
 * The type names appearing here are not usable as function names
 * because they can be followed by LPAREN in type_name productions, which
 * looks too much like a function call for an LR(1) parser.
 *)
col_name_keyword:
| BETWEEN { "between" }
| BIGINT { "bigint" }
| BIT { "bit" }
| BOOLEAN_P { "boolean" }
| CHAR_P { "char" }
| CHARACTER { "character" }
| COALESCE { "coalesce" }
| DEC { "dec" }
| DECIMAL_P { "decimal" }
| EXISTS { "exists" }
| EXTRACT { "extract" }
| FLOAT_P { "float" }
| GREATEST { "greatest" }
| INOUT { "inout" }
| INT_P { "int" }
| INTEGER { "integer" }
| INTERVAL { "interval" }
| LEAST { "least" }
| NATIONAL { "national" }
| NCHAR { "nchar" }
| NONE { "none" }
| NULLIF { "nullif" }
| NUMERIC { "numeric" }
| OUT_P { "out" }
| OVERLAY { "overlay" }
| POSITION { "position" }
| PRECISION { "precision" }
| REAL { "real" }
| ROW { "row" }
| SETOF { "setof" }
| SMALLINT { "smallint" }
| SUBSTRING { "substring" }
| TIME { "time" }
| TIMESTAMP { "timestamp" }
| TREAT { "treat" }
| TRIM { "trim" }
| VALUES { "values" }
| VARCHAR { "varchar" }
| XMLATTRIBUTES { "xmlattributes" }
| XMLCONCAT { "xmlconcat" }
| XMLELEMENT { "xmlelement" }
| XMLEXISTS { "xmlexists" }
| XMLFOREST { "xmlforest" }
| XMLPARSE { "xmlparse" }
| XMLPI { "xmlpi" }
| XMLROOT { "xmlroot" }
| XMLSERIALIZE { "xmlserialize" }

(* Type/function identifier --- keywords that can be type or function names.
 *
 * Most of these are keywords that are used as operators in expressions;
 * in general such keywords can't be column names because they would be
 * ambiguous with variables, but they are unambiguous as function identifiers.
 *
 * Do not include POSITION, SUBSTRING, etc here since they have explicit
 * productions in a_expr to support the goofy SQL9x argument syntax.
 * - thomas 2000-11-28
 *)
type_func_name_keyword:
| AUTHORIZATION { "authorization" }
| BINARY { "binary" }
| COLLATION { "collation" }
| CONCURRENTLY { "concurrently" }
| CROSS { "cross" }
| CURRENT_SCHEMA { "current_schema" }
| FREEZE { "freeze" }
| FULL { "full" }
| ILIKE { "ilike" }
| INNER_P { "inner" }
| IS { "is" }
| ISNULL { "isnull" }
| JOIN { "join" }
| LEFT { "left" }
| LIKE { "like" }
| NATURAL { "natural" }
| NOTNULL { "notnull" }
| OUTER_P { "outer" }
| OVER { "over" }
| OVERLAPS { "overlaps" }
| RIGHT { "right" }
| SIMILAR { "similar" }
| VERBOSE { "verbose" }

(* Reserved keyword --- these keywords are usable only as a col_label.
 *
 * Keywords appear here if they could not be distinguished from variable,
 * type, or function names in some contexts.  Don't put things here unless
 * forced to.
 *)
reserved_keyword:
| ALL { "all" }
| ANALYSE { "analyse" }
| ANALYZE { "analyze" }
| AND { "and" }
| ANY { "any" }
| ARRAY { "array" }
| AS { "as" }
| ASC { "asc" }
| ASYMMETRIC { "asymmetric" }
| BOTH { "both" }
| CASE { "case" }
| CAST { "cast" }
| CHECK { "check" }
| COLLATE { "collate" }
| COLUMN { "column" }
| CONSTRAINT { "constraint" }
| CREATE { "create" }
| CURRENT_CATALOG { "current_catalog" }
| CURRENT_DATE { "current_date" }
| CURRENT_ROLE { "current_role" }
| CURRENT_TIME { "current_time" }
| CURRENT_TIMESTAMP { "current_timestamp" }
| CURRENT_USER { "current_user" }
| DEFAULT { "default" }
| DEFERRABLE { "deferrable" }
| DESC { "desc" }
| DISTINCT { "distinct" }
| DO { "do" }
| ELSE { "else" }
| END_P { "end" }
| EXCEPT { "except" }
| FALSE_P { "false" }
| FETCH { "fetch" }
| FOR { "for" }
| FOREIGN { "foreign" }
| FROM { "from" }
| GRANT { "grant" }
| GROUP_P { "group" }
| HAVING { "having" }
| IN_P { "in" }
| INITIALLY { "initially" }
| INTERSECT { "intersect" }
| INTO { "into" }
| LATERAL_P { "lateral" }
| LEADING { "leading" }
| LIMIT { "limit" }
| LOCALTIME { "localtime" }
| LOCALTIMESTAMP { "localtimestamp" }
| NOT { "not" }
| NULL_P { "null" }
| OFFSET { "offset" }
| ON { "on" }
| ONLY { "only" }
| OR { "or" }
| ORDER { "order" }
| PLACING { "placing" }
| PRIMARY { "primary" }
| REFERENCES { "references" }
| RETURNING { "returning" }
| SELECT { "select" }
| SESSION_USER { "session_user" }
| SOME { "some" }
| SYMMETRIC { "symmetric" }
| TABLE { "table" }
| THEN { "then" }
| TO { "to" }
| TRAILING { "trailing" }
| TRUE_P { "true" }
| UNION { "union" }
| UNIQUE { "unique" }
| USER { "user" }
| USING { "using" }
| VARIADIC { "variadic" }
| WHEN { "when" }
| WHERE { "where" }
| WINDOW { "window" }
| WITH { "with" }

