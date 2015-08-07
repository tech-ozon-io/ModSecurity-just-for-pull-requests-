%skeleton "lalr1.cc" /* -*- C++ -*- */
%require "3.0.2"
%defines
%define parser_class_name {seclang_parser}
%define api.token.constructor
%define api.value.type variant
//%define api.namespace {ModSecurity::yy}
%define parse.assert
%code requires
{
# include <string>

namespace ModSecurity {
namespace Parser {
class Driver;
}
}

#include "actions/action.h"
#include "actions/set_var.h"
#include "actions/msg.h"
#include "actions/rev.h"
#include "actions/tag.h"
#include "actions/transformations/transformation.h"
#include "operators/operator.h"
#include "rule.h"
#include "utils/geo_lookup.h"
#include "audit_log.h"

#include "variables/variations/count.h"
#include "variables/variations/exclusion.h"
#include "variables/duration.h"
#include "variables/env.h"
#include "variables/highest_severity.h"
#include "variables/modsec_build.h"
#include "variables/time_day.h"
#include "variables/time_epoch.h"
#include "variables/time.h"
#include "variables/time_hour.h"
#include "variables/time_min.h"
#include "variables/time_mon.h"
#include "variables/time_sec.h"
#include "variables/time_wday.h"
#include "variables/time_year.h"

using ModSecurity::actions::Action;
using ModSecurity::actions::SetVar;
using ModSecurity::actions::Tag;
using ModSecurity::actions::Rev;
using ModSecurity::actions::Msg;
using ModSecurity::actions::transformations::Transformation;
using ModSecurity::operators::Operator;
using ModSecurity::Rule;
using ModSecurity::Utils::GeoLookup;

using ModSecurity::Variables::Variations::Count;
using ModSecurity::Variables::Variations::Exclusion;
using ModSecurity::Variables::Duration;
using ModSecurity::Variables::Env;
using ModSecurity::Variables::HighestSeverity;
using ModSecurity::Variables::ModsecBuild;
using ModSecurity::Variables::Time;
using ModSecurity::Variables::TimeDay;
using ModSecurity::Variables::TimeEpoch;
using ModSecurity::Variables::TimeHour;
using ModSecurity::Variables::TimeMin;
using ModSecurity::Variables::TimeMon;
using ModSecurity::Variables::TimeSec;
using ModSecurity::Variables::TimeWDay;
using ModSecurity::Variables::TimeYear;
using ModSecurity::Variables::Variable;


#define CHECK_VARIATION_DECL \
    Variable *var = NULL; \
    bool t = false;

#define CHECK_VARIATION(a) \
    if (var == NULL) { \
        if (name.at(0) == std::string(#a).at(0)) { \
            name.erase(0, 1); \
            t = true ; \
        } \
    } else { \
        t = false; \
    } \
    if (t)


/**
 * %destructor { code } THING
 *
 * %destructor is not working as expected. Apparently it was fixed on a most recent,
 * version of Bison. We are not interested to limit the usage to this newest version,
 * thus, we have to deal with memory leak when rules failed to load. Not that big
 * problem, as we don't really continue when it fails (only for SecRemoteRules).
 *
 * Information about destructor:
 * http://www.gnu.org/software/bison/manual/html_node/Destructor-Decl.html
 *
 * Patch:
 * https://www.mail-archive.com/search?l=bug-bison@gnu.org&q=subject:%22Destructor+miscompilation+with+C%2B%2B+variants%3F%22&o=newest&f=1
 */

}
// The parsing context.
%param { ModSecurity::Parser::Driver& driver }
%locations
%initial-action
{
  // Initialize the initial location.
  @$.begin.filename = @$.end.filename = &driver.file;
};
%define parse.trace
%define parse.error verbose
%code
{
#include "parser/driver.h"
}
%define api.token.prefix {TOK_}
%token
  END  0  "end of file"
  CONFIG_DIR_VAL    "+"
  COMMA    "*"
  QUOTATION_MARK  ")"
  SPACE
  PIPE
  UNKNOWN
  FREE_TEXT
;

%left ARGS CONFIG_VALUE_RELEVANT_ONLY CONFIG_VALUE_ON CONFIG_VALUE_OFF CONFIG_VALUE
%token <std::string> DIRECTIVE
%token <std::string> CONFIG_DIRECTIVE
%token <std::string> CONFIG_DIR_REQ_BODY_LIMIT
%token <std::string> CONFIG_DIR_RES_BODY_LIMIT
%token <std::string> CONFIG_DIR_REQ_BODY_LIMIT_ACTION
%token <std::string> CONFIG_DIR_RES_BODY_LIMIT_ACTION
%token <std::string> CONFIG_DIR_RULE_ENG
%token <std::string> CONFIG_DIR_REQ_BODY
%token <std::string> CONFIG_DIR_RES_BODY
%token <std::string> CONFIG_VALUE
%token <std::string> CONFIG_VALUE_ON
%token <std::string> CONFIG_VALUE_OFF
%token <std::string> CONFIG_VALUE_DETC
%token <std::string> CONFIG_VALUE_SERIAL
%token <std::string> CONFIG_VALUE_PARALLEL
%token <std::string> CONFIG_VALUE_RELEVANT_ONLY
%token <std::string> CONFIG_VALUE_PROCESS_PARTIAL
%token <std::string> CONFIG_VALUE_REJECT
%token <std::string> CONFIG_VALUE_ABORT
%token <std::string> CONFIG_VALUE_WARN

%token <std::string> CONFIG_DIR_AUDIT_DIR
%token <std::string> CONFIG_DIR_AUDIT_DIR_MOD
%token <std::string> CONFIG_DIR_AUDIT_ENG
%token <std::string> CONFIG_DIR_AUDIT_FLE_MOD
%token <std::string> CONFIG_DIR_AUDIT_LOG
%token <std::string> CONFIG_DIR_AUDIT_LOG2
%token <std::string> CONFIG_DIR_AUDIT_LOG_P
%token <std::string> CONFIG_DIR_AUDIT_STS
%token <std::string> CONFIG_DIR_AUDIT_TPE

%token <std::string> CONFIG_COMPONENT_SIG

%token <std::string> CONFIG_DIR_DEBUG_LOG
%token <std::string> CONFIG_DIR_DEBUG_LVL

%token <std::string> VARIABLE
%token <std::string> RUN_TIME_VAR_DUR
%token <std::string> RUN_TIME_VAR_ENV
%token <std::string> RUN_TIME_VAR_BLD
%token <std::string> RUN_TIME_VAR_HSV

%token <std::string> RUN_TIME_VAR_TIME
%token <std::string> RUN_TIME_VAR_TIME_DAY
%token <std::string> RUN_TIME_VAR_TIME_EPOCH
%token <std::string> RUN_TIME_VAR_TIME_HOUR
%token <std::string> RUN_TIME_VAR_TIME_MIN
%token <std::string> RUN_TIME_VAR_TIME_MON
%token <std::string> RUN_TIME_VAR_TIME_SEC
%token <std::string> RUN_TIME_VAR_TIME_WDAY
%token <std::string> RUN_TIME_VAR_TIME_YEAR

%token <std::string> CONFIG_INCLUDE
%token <std::string> CONFIG_SEC_REMOTE_RULES
%token <std::string> CONFIG_SEC_REMOTE_RULES_FAIL_ACTION

%token <std::string> CONFIG_DIR_GEO_DB

%token <std::string> OPERATOR
%token <std::string> ACTION
%token <std::string> ACTION_SEVERITY
%token <std::string> ACTION_SETVAR
%token <std::string> ACTION_MSG
%token <std::string> ACTION_TAG
%token <std::string> ACTION_REV
%token <std::string> TRANSFORMATION

%token <double> CONFIG_VALUE_NUMBER

%type <std::vector<Action *> *> actions
%type <std::vector<Variable *> *> variables
%type <Variable *> var


%printer { yyoutput << $$; } <*>;
%%
%start secrule;


secrule:
    | secrule line

line: 
    expression
    | SPACE expression
    | SPACE
      {

      }

audit_log:
    /* SecAuditLogDirMode */
    CONFIG_DIR_AUDIT_DIR_MOD
      {
        driver.audit_log->setStorageDirMode(strtol($1.c_str(), NULL, 8));
      }

    /* SecAuditLogStorageDir */
    | CONFIG_DIR_AUDIT_DIR
      {
        driver.audit_log->setStorageDir($1);
      }

    /* SecAuditEngine */
    | CONFIG_DIR_AUDIT_ENG SPACE CONFIG_VALUE_RELEVANT_ONLY
      {
        driver.audit_log->setStatus(ModSecurity::AuditLog::RelevantOnlyAuditLogStatus);
      }
    | CONFIG_DIR_AUDIT_ENG SPACE CONFIG_VALUE_OFF
      {
        driver.audit_log->setStatus(ModSecurity::AuditLog::OffAuditLogStatus);
      }
    | CONFIG_DIR_AUDIT_ENG SPACE CONFIG_VALUE_ON
      {
        driver.audit_log->setStatus(ModSecurity::AuditLog::OnAuditLogStatus);
      }

    /* SecAuditLogFileMode */
    | CONFIG_DIR_AUDIT_FLE_MOD
      {
        driver.audit_log->setFileMode(strtol($1.c_str(), NULL, 8));
      }

    /* SecAuditLog2 */
    | CONFIG_DIR_AUDIT_LOG2
      {
        driver.audit_log->setFilePath2($1);
      }

    /* SecAuditLogParts */
    | CONFIG_DIR_AUDIT_LOG_P
      {
        driver.audit_log->setParts($1);
      }

    /* SecAuditLog */
    | CONFIG_DIR_AUDIT_LOG
      {
        driver.audit_log->setFilePath1($1);
      }

    /* SecAuditLogRelevantStatus */
    | CONFIG_DIR_AUDIT_STS
      {
        std::string relevant_status($1);
        relevant_status.pop_back();
        relevant_status.erase(0, 1);
        driver.audit_log->setRelevantStatus(relevant_status);
      }

    /* SecAuditLogType */
    | CONFIG_DIR_AUDIT_TPE SPACE CONFIG_VALUE_SERIAL
      {
        driver.audit_log->setType(ModSecurity::AuditLog::SerialAuditLogType);
      }
    | CONFIG_DIR_AUDIT_TPE SPACE CONFIG_VALUE_PARALLEL
      {
        driver.audit_log->setType(ModSecurity::AuditLog::ParallelAuditLogType);
      }


expression:
    audit_log
    | DIRECTIVE SPACE variables SPACE OPERATOR SPACE QUOTATION_MARK actions QUOTATION_MARK
      {
        Operator *op = Operator::instantiate($5);
        const char *error = NULL;
        if (op->init(&error) == false) {
            driver.parserError << error;
            YYERROR;
        }
        Rule *rule = new Rule(
            /* op */ op,
            /* variables */ $3,
            /* actions */ $8
            );
        driver.addSecRule(rule);
      }
    | CONFIG_DIR_RULE_ENG SPACE CONFIG_VALUE_OFF
      {
        driver.secRuleEngine = ModSecurity::Rules::DisabledRuleEngine;
      }
    | CONFIG_DIR_RULE_ENG SPACE CONFIG_VALUE_ON
      {
        driver.secRuleEngine = ModSecurity::Rules::EnabledRuleEngine;
      }
    | CONFIG_DIR_RULE_ENG SPACE CONFIG_VALUE_DETC
      {
        driver.secRuleEngine = ModSecurity::Rules::DetectionOnlyRuleEngine;
      }
    | CONFIG_DIR_REQ_BODY SPACE CONFIG_VALUE_ON
      {
        driver.sec_request_body_access = true;
      }
    | CONFIG_DIR_REQ_BODY SPACE CONFIG_VALUE_OFF
      {
        driver.sec_request_body_access = false;
      }
    | CONFIG_DIR_RES_BODY SPACE CONFIG_VALUE_ON
      {
        driver.sec_request_body_access = true;
      }
    | CONFIG_DIR_RES_BODY SPACE CONFIG_VALUE_OFF
      {
        driver.sec_request_body_access = false;
      }
    | CONFIG_COMPONENT_SIG
      {
        driver.components.push_back($1);
      }
    /* Debug log: start */
    | CONFIG_DIR_DEBUG_LVL
      {
        driver.debug_level = atoi($1.c_str());
      }
    | CONFIG_DIR_DEBUG_LOG
      {
        driver.debug_log_path = $1;
      }
    /* Debug log: end */
    | CONFIG_DIR_GEO_DB
      {
        GeoLookup::getInstance().setDataBase($1);
      }
    /* Body limits */
    | CONFIG_DIR_REQ_BODY_LIMIT
      {
        driver.requestBodyLimit = atoi($1.c_str());
      }
    | CONFIG_DIR_RES_BODY_LIMIT
      {
        driver.responseBodyLimit = atoi($1.c_str());
      }
    | CONFIG_DIR_REQ_BODY_LIMIT_ACTION SPACE CONFIG_VALUE_PROCESS_PARTIAL
      {
        driver.requestBodyLimitAction = ModSecurity::Rules::BodyLimitAction::ProcessPartialBodyLimitAction;
      }
    | CONFIG_DIR_REQ_BODY_LIMIT_ACTION SPACE CONFIG_VALUE_REJECT
      {
        driver.requestBodyLimitAction = ModSecurity::Rules::BodyLimitAction::RejectBodyLimitAction;
      }
    | CONFIG_DIR_RES_BODY_LIMIT_ACTION SPACE CONFIG_VALUE_PROCESS_PARTIAL
      {
        driver.responseBodyLimitAction = ModSecurity::Rules::BodyLimitAction::ProcessPartialBodyLimitAction;
      }
    | CONFIG_DIR_RES_BODY_LIMIT_ACTION SPACE CONFIG_VALUE_REJECT
      {
        driver.responseBodyLimitAction = ModSecurity::Rules::BodyLimitAction::RejectBodyLimitAction;
      }
    | CONFIG_SEC_REMOTE_RULES_FAIL_ACTION SPACE CONFIG_VALUE_ABORT
      {
        driver.remoteRulesActionOnFailed = Rules::OnFailedRemoteRulesAction::AbortOnFailedRemoteRulesAction;
      }
    | CONFIG_SEC_REMOTE_RULES_FAIL_ACTION SPACE CONFIG_VALUE_WARN
      {
        driver.remoteRulesActionOnFailed = Rules::OnFailedRemoteRulesAction::WarnOnFailedRemoteRulesAction;
      }


variables:
    variables PIPE var
      {
        std::vector<Variable *> *v = $1;
        v->push_back($3);
        $$ = $1;
      }
    | var
      {
        std::vector<Variable *> *variables = new std::vector<Variable *>;
        variables->push_back($1);
        $$ = variables;
      }

var:
    VARIABLE
      {
        std::string name($1);
        CHECK_VARIATION_DECL
        CHECK_VARIATION(&) { var = new Count(new Variable(name)); }
        CHECK_VARIATION(!) { var = new Exclusion(new Variable(name)); }
        if (!var) { var = new Variable(name); }
        $$ = var;
      }
    | RUN_TIME_VAR_DUR
      {
        std::string name($1);
        CHECK_VARIATION_DECL
        CHECK_VARIATION(&) { var = new Count(new Duration(name)); }
        CHECK_VARIATION(!) { var = new Exclusion(new Duration(name)); }
        if (!var) { var = new Duration(name); }
        $$ = var;
      }
    | RUN_TIME_VAR_ENV
      {
        std::string name($1);
        CHECK_VARIATION_DECL
        CHECK_VARIATION(&) { var = new Count(new Env(name)); }
        CHECK_VARIATION(!) { var = new Exclusion(new Env(name)); }
        if (!var) { var = new Env(name); }
        $$ = var;
      }
    | RUN_TIME_VAR_BLD
      {
        std::string name($1);
        CHECK_VARIATION_DECL
        CHECK_VARIATION(&) { var = new Count(new ModsecBuild(name)); }
        CHECK_VARIATION(!) { var = new Exclusion(new ModsecBuild(name)); }
        if (!var) { var = new ModsecBuild(name); }
        $$ = var;
      }
    | RUN_TIME_VAR_HSV
      {
        std::string name($1);
        CHECK_VARIATION_DECL
        CHECK_VARIATION(&) { var = new Count(new HighestSeverity(name)); }
        CHECK_VARIATION(!) { var = new Exclusion(new HighestSeverity(name)); }
        if (!var) { var = new HighestSeverity(name); }
        $$ = var;
      }
    | RUN_TIME_VAR_TIME
      {
        std::string name($1);
        CHECK_VARIATION_DECL
        CHECK_VARIATION(&) { var = new Count(new Time(name)); }
        CHECK_VARIATION(!) { var = new Exclusion(new Time(name)); }
        if (!var) { var = new Time(name); }
        $$ = var;
      }
    | RUN_TIME_VAR_TIME_DAY
      {
        std::string name($1);
        CHECK_VARIATION_DECL
        CHECK_VARIATION(&) { var = new Count(new TimeDay(name)); }
        CHECK_VARIATION(!) { var = new Exclusion(new TimeDay(name)); }
        if (!var) { var = new TimeDay(name); }
        $$ = var;
      }
    | RUN_TIME_VAR_TIME_EPOCH
      {
        std::string name($1);
        CHECK_VARIATION_DECL
        CHECK_VARIATION(&) { var = new Count(new TimeEpoch(name)); }
        CHECK_VARIATION(!) { var = new Exclusion(new TimeEpoch(name)); }
        if (!var) { var = new TimeEpoch(name); }
        $$ = var;
      }
    | RUN_TIME_VAR_TIME_HOUR
      {
        std::string name($1);
        CHECK_VARIATION_DECL
        CHECK_VARIATION(&) { var = new Count(new TimeHour(name)); }
        CHECK_VARIATION(!) { var = new Exclusion(new TimeHour(name)); }
        if (!var) { var = new TimeHour(name); }
        $$ = var;
      }
    | RUN_TIME_VAR_TIME_MIN
      {
        std::string name($1);
        CHECK_VARIATION_DECL
        CHECK_VARIATION(&) { var = new Count(new TimeMin(name)); }
        CHECK_VARIATION(!) { var = new Exclusion(new TimeMin(name)); }
        if (!var) { var = new TimeMin(name); }
        $$ = var;
      }
    | RUN_TIME_VAR_TIME_MON
      {
        std::string name($1);
        CHECK_VARIATION_DECL
        CHECK_VARIATION(&) { var = new Count(new TimeMon(name)); }
        CHECK_VARIATION(!) { var = new Exclusion(new TimeMon(name)); }
        if (!var) { var = new TimeMon(name); }
        $$ = var;
      }
    | RUN_TIME_VAR_TIME_SEC
      {
        std::string name($1);
        CHECK_VARIATION_DECL
        CHECK_VARIATION(&) { var = new Count(new TimeSec(name)); }
        CHECK_VARIATION(!) { var = new Exclusion(new TimeSec(name)); }
        if (!var) { var = new TimeSec(name); }
        $$ = var;
      }
    | RUN_TIME_VAR_TIME_WDAY
      {
        std::string name($1);
        CHECK_VARIATION_DECL
        CHECK_VARIATION(&) { var = new Count(new TimeWDay(name)); }
        CHECK_VARIATION(!) { var = new Exclusion(new TimeWDay(name)); }
        if (!var) { var = new TimeWDay(name); }
        $$ = var;
      }
    | RUN_TIME_VAR_TIME_YEAR
      {
        std::string name($1);
        CHECK_VARIATION_DECL
        CHECK_VARIATION(&) { var = new Count(new TimeYear(name)); }
        CHECK_VARIATION(!) { var = new Exclusion(new TimeYear(name)); }
        if (!var) { var = new TimeYear(name); }
        $$ = var;
      }

actions:
    actions COMMA SPACE ACTION
      {
        std::vector<Action *> *a = $1;
        a->push_back(Action::instantiate($4));
        $$ = $1;
      }

    | actions COMMA ACTION
      {
        std::vector<Action *> *a = $1;
        a->push_back(Action::instantiate($3));
        $$ = $1;
      }
    | SPACE ACTION
      {
        std::vector<Action *> *actions = new std::vector<Action *>;
        actions->push_back(Action::instantiate($2));
        $$ = actions;

      }
    | ACTION
      {
        std::vector<Action *> *actions = new std::vector<Action *>;
        actions->push_back(Action::instantiate($1));
        $$ = actions;
      }
    | actions COMMA SPACE TRANSFORMATION
      {
        std::vector<Action *> *a = $1;
        a->push_back(Transformation::instantiate($4));
        $$ = $1;
      }

    | actions COMMA TRANSFORMATION
      {
        std::vector<Action *> *a = $1;
        a->push_back(Transformation::instantiate($3));
        $$ = $1;
      }
    | SPACE TRANSFORMATION
      {
        std::vector<Action *> *actions = new std::vector<Action *>;
        actions->push_back(Transformation::instantiate($2));
        $$ = actions;

      }
    | TRANSFORMATION
      {
        std::vector<Action *> *actions = new std::vector<Action *>;
        actions->push_back(Transformation::instantiate($1));
        $$ = actions;
      }
    | actions COMMA SPACE ACTION_SEVERITY
      {
        std::vector<Action *> *a = $1;
        a->push_back(Action::instantiate($4));
        $$ = $1;
      }
    | actions COMMA ACTION_SEVERITY
      {
        std::vector<Action *> *a = $1;
        a->push_back(Action::instantiate($3));
        $$ = $1;
      }
    | SPACE ACTION_SEVERITY
      {
        std::vector<Action *> *actions = new std::vector<Action *>;
        actions->push_back(Action::instantiate($2));
        $$ = actions;

      }
    | ACTION_SEVERITY
      {
        std::vector<Action *> *actions = new std::vector<Action *>;
        actions->push_back(Action::instantiate($1));
        $$ = actions;
      }
    | actions COMMA ACTION_SETVAR
      {
        std::vector<Action *> *a = $1;
        std::string error;
        SetVar *setVar = new SetVar($3);

        if (setVar->init(&error) == false) {
            driver.parserError << error;
            YYERROR;
        }

        a->push_back(setVar);
        $$ = $1;
      }
    | SPACE ACTION_SETVAR
      {
        std::vector<Action *> *actions = new std::vector<Action *>;
        std::string error;
        SetVar *setVar = new SetVar($2);

        if (setVar->init(&error) == false) {
            driver.parserError << error;
            YYERROR;
        }

        actions->push_back(setVar);
        $$ = actions;

      }
    | ACTION_SETVAR
      {
        std::vector<Action *> *actions = new std::vector<Action *>;
        std::string error;
        SetVar *setVar = new SetVar($1);

        if (setVar->init(&error) == false) {
            driver.parserError << error;
            YYERROR;
        }

        actions->push_back(setVar);
        $$ = actions;
      }
    | actions COMMA ACTION_MSG
      {
        std::vector<Action *> *a = $1;
        Msg *msg = new Msg($3);
        a->push_back(msg);
        $$ = $1;
      }
    | SPACE ACTION_MSG
      {
        std::vector<Action *> *actions = new std::vector<Action *>;
        Msg *msg = new Msg($2);
        actions->push_back(msg);
        $$ = actions;

      }
    | ACTION_MSG
      {
        std::vector<Action *> *actions = new std::vector<Action *>;
        Msg *msg = new Msg($1);
        actions->push_back(msg);
        $$ = actions;
      }
    | actions COMMA ACTION_TAG
      {
        std::vector<Action *> *a = $1;
        Tag *tag = new Tag($3);
        a->push_back(tag);
        $$ = $1;
      }
    | SPACE ACTION_TAG
      {
        std::vector<Action *> *actions = new std::vector<Action *>;
        Tag *tag = new Tag($2);
        actions->push_back(tag);
        $$ = actions;

      }
    | ACTION_TAG
      {
        std::vector<Action *> *actions = new std::vector<Action *>;
        Tag *tag = new Tag($1);
        actions->push_back(tag);
        $$ = actions;
      }
    | actions COMMA ACTION_REV
      {
        std::vector<Action *> *a = $1;
        Rev *rev = new Rev($3);
        a->push_back(rev);
        $$ = $1;
      }
    | SPACE ACTION_REV
      {
        std::vector<Action *> *actions = new std::vector<Action *>;
        Rev *rev = new Rev($2);
        actions->push_back(rev);
        $$ = actions;

      }
    | ACTION_REV
      {
        std::vector<Action *> *actions = new std::vector<Action *>;
        Rev *rev = new Rev($1);
        actions->push_back(rev);
        $$ = actions;
      }

%%
void
yy::seclang_parser::error (const location_type& l,
                          const std::string& m)
{
    driver.error (l, m);
}
