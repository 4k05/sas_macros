/*Logstdcap macro*/
/*Transforming input variables to log scale, standardising them, and optionally capping them to +/- 3 std*/
/*Version date: 08/12/2020*/

/*Instructions to invoke the macro:*/
	/*1) First if saved as a separate file include it:*/
	/*%include "\\path\path\path\logstdcap_transform_macro_git.sas";*/

	/*2)a Then invoke the macro without capping values:*/
	/*%logstdcap(your_table, list variables seperated by space, donotcap);*/

	/*2)b Or invoke the macro with capping values:*/
	/*%logstdcap(your_table, list variables seperated by space, cap);*/


/*logstdcap transform macro*/
%macro logstdcap(table_in,vars_to_trans,cap_or_not);
%let vars = ;
proc contents data = &table_in. (keep=&vars_to_trans.) noprint out = work.temp_contents (keep = name varnum);run;
proc sort data = work.temp_contents; by varnum; run;
proc sql; select name into:vars separated by '|' from work.temp_contents; quit;
/*%put &vars.;*/
data _null_; i=0; do until ( x = ''); i=i+1; x=scan("&vars.",i,'|'); end; call symput("numofvars",i-1);run;
/*%put &numofvars.;*/
%let logtrans = ;
%macro logtrans;
%do j=1 %to &numofvars.;
%let logtrans = &logtrans.
"%scan(&vars.,&j.,|)"n = log("%scan(&vars.,&j.,|)"n + 1) %nrstr(;);
%end;
%mend;
%logtrans;
/*%put &logtrans.;*/
data &table_in._log;
set &table_in.;
&logtrans.
run;
/*cap where standardised value is outside of -3 and 3 range*/
proc standard data = &table_in._log out  = &table_in._logstd mean = 0 std  = 1; var &vars_to_trans.;run;
%let capping = ;
%if &cap_or_not. = donotcap %then %do;
%end;
%if &cap_or_not. = cap %then %do;
%macro capping;
%do j=1 %to &numofvars.;
%let capping = &capping.
case when "%scan(&vars.,&j.,|)"n = .  then .
	 when "%scan(&vars.,&j.,|)"n < -3  then -3
	 when "%scan(&vars.,&j.,|)"n > 3 then 3
	 else "%scan(&vars.,&j.,|)"n end as "%scan(&vars.,&j.,|)"n,;
%end;
%mend;
%capping;
/*%put &capping.;*/
%end;
proc sql;
create table &table_in. as
select
&capping. *
from &table_in._logstd
;quit;
proc sql;
drop table &table_in._log;
drop table &table_in._logstd;
;quit;
%mend;
