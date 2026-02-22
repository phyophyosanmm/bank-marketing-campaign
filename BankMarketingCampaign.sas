PROC FREQ DATA=lab.bank_new;
    TABLE job housing education;
RUN;


/* Step 0: Find the mode for categorical variables */
PROC FREQ DATA=lab.bank_new NOPRINT;
    TABLES job / OUT=job_freq (WHERE=(COUNT=MAX(COUNT)));
    TABLES housing / OUT=housing_freq (WHERE=(COUNT=MAX(COUNT)));
    TABLES education / OUT=education_freq (WHERE=(COUNT=MAX(COUNT)));
RUN;

/*  Create macro variables to store the modes */
DATA _NULL_;
    SET job_freq;
    CALL SYMPUTX('mode_job', job);
RUN;

DATA _NULL_;
    SET housing_freq;
    CALL SYMPUTX('mode_housing', housing);
RUN;

DATA _NULL_;
    SET education_freq;
    CALL SYMPUTX('mode_education', education);
RUN;

/* Step 1: Handle missing values (mode imputation) */
DATA lab.bank_prep;
    SET lab.bank_new;
    IF job="" THEN job = "&mode_job";
    IF housing=""  THEN housing = "&mode_housing";
    IF education="" THEN education = "&mode_education";

RUN;

PROC FREQ DATA=lab.bank_prep;
    TABLE job housing education;
RUN;

/* Inconsistency */
proc print data=lab.bank_prep;
    where age < 0 or age > 100;
run;

/* Step 1: Convert invalid ages to missing */
DATA lab.bank_prep;
    SET lab.bank_prep;
    IF age < 0 OR age > 100 THEN age = .;   
RUN;

/* Step 2: Calculate the median age */
PROC MEANS DATA=lab.bank_prep NOPRINT;
    VAR age;
    OUTPUT OUT=median_age MEDIAN=median_age_value;
RUN;

/* Step 3: Replace missing ages with the median */
DATA lab.bank_prep;
    IF _N_ = 1 THEN SET median_age;   /* bring in median value */
    SET lab.bank_prep;
    IF MISSING(age) THEN age = median_age_value;
RUN;

/* . drop unnecessary columns*/
DATA lab.bank_prep;
    SET lab.bank_prep;
    drop _TYPE_ _FREQ_ median_age_value;
RUN;
/*Capping for outlier*/
DATA lab.bank_prep;
    SET lab.bank_prep;

    /* 1. Balance: allow -2000 to 40000 */
    IF balance < -2000 THEN balance = -2000;
    ELSE IF balance > 40000 THEN balance = 40000;

    /* 2. Duration: allow 0–2000 sec */
    IF duration < 0 THEN duration = 0;
    ELSE IF duration > 2000 THEN duration = 2000;

    /* 3. Campaign: allow 1–15 contacts */
    IF campaign < 1 THEN campaign = 1;
    ELSE IF campaign > 15 THEN campaign = 15;

    /* 4. Pdays: keep -1 as special, cap positive values >730 */
    IF pdays > 730 THEN pdays = 730;

    /* 5. Previous: allow 0–10 */
    IF previous < 0 THEN previous = 0;
    ELSE IF previous > 10 THEN previous = 10;
RUN;

/* check outliers */
proc print data=lab.bank_prep;
    where balance < -2000 or balance > 40000
       or duration < 0 or duration > 2000
       or campaign < 1 or campaign > 15
       or (pdays ne -1 and pdays > 730)
       or previous > 10;
run;
	
/* Check impossible numeric values */
proc print data=lab.bank_prep;
    where age < 0 or age > 100
       or duration < 0
       or campaign < 1
       or pdays < -1
       or previous < 0;
run;

/* Check inconsistent logic: previous=0 but pdays>0 */
proc print data=lab.bank_prep;
    where previous = 0 and pdays > 0;
run;	

/* Check categorical values */
proc freq data=lab.bank_prep;
    tables job education contact poutcome ;
run;

/* =====================================
   EDA for Bank Marketing Campaign
   Dataset: lab.bank_prep
   Target: y
===================================== */
ods graphics on;

%let ds = lab.bank_prep;   
%let target = deposit;

/* ----------------------------
   1) CORRELATION (Numeric)
-----------------------------*/
/* Correlation matrix among numeric variables */
title "Correlation among Numeric Variables";
proc corr data=&ds pearson spearman plots=matrix(histogram);
   var age balance duration campaign pdays previous;
run;

/* ----------------------------
   2) RELATIONSHIPS WITH TARGET
-----------------------------*/

/* (a) Numeric vs Target - Visual comparison */
title "Boxplots of Numeric Features by Target (&target)";
proc sgplot data=&ds;
   vbox age / category=&target;
run;

proc sgplot data=&ds;
    vbox balance / category=&target;
run;

proc sgplot data=&ds;
    vbox duration / category=&target;
run;

proc sgplot data=&ds;
    vbox campaign / category=&target;
run;
proc sgplot data=&ds;
    vbox pdays / category=&target;
run;
proc sgplot data=&ds;
   vbox previous / category=&target;
run;


/* (b) Categorical vs Target - Association tests */
title "Association between Categorical Features and Target (&target)";
proc freq data=&ds;
   tables &target*job 
          &target*marital 
          &target*education 
          &target*default 
          &target*housing 
          &target*loan 
          &target*contact 
          &target*month 
          &target*poutcome
          / chisq expected norow nocol nopercent;
run;

/* (c) Target Balance */
title "Class Distribution of Target Variable (&target)";
proc freq data=&ds;
   tables &target / nocum;
run;

ods graphics off;

/*Feature engineering*/
/* 1. Binning AGE into categories */
DATA lab.bank_prep;
    SET lab.bank_prep;
    LENGTH Age_Group $12;
    IF age < 30 THEN Age_Group = "Young";
    ELSE IF 30 <= age < 50 THEN Age_Group = "Middle";
    ELSE Age_Group = "Senior";
RUN;
/*2. Categories*/
DATA lab.bank_prep;
    SET lab.bank_prep;
    
    /* Simplify Job Categories */
    LENGTH job_simplified $20;
    IF job IN ('blue-collar', 'services', 'housemaid') THEN job_simplified = 'Manual/Service';
    ELSE IF job IN ('admin.', 'management', 'technician') THEN job_simplified = 'Professional';
    ELSE IF job IN ('unemployed', 'student', 'retired') THEN job_simplified = 'Non-Employed';
    ELSE IF job IN ('self-employe', 'entrepreneu') THEN job_simplified = 'Owner/Self-Employed';
    ELSE job_simplified = 'Other';

RUN;

/* 3. Log Transformation for BALANCE (to reduce skewness) */
DATA lab.bank_prep;
    SET lab.bank_prep;
    IF balance > 0 THEN log_balance = LOG(balance+1); /* add 1 to avoid log(0) */
    ELSE log_balance = .; 
RUN;
/*for negative balance*/
DATA lab.bank_prep;
    SET lab.bank_prep;
    /* Indicator for overdraft (negative balance) */
    IF balance < 0 THEN negative_balance = 1;
    ELSE negative_balance = 0;	
RUN;    

/* 5. Create new feature: Has_Loan (Housing OR Personal Loan) */ 
DATA lab.bank_prep; 
	SET lab.bank_prep; 
	IF housing = "yes" OR loan = "yes" THEN Has_Loan = 1;
	ELSE Has_Loan = 0; 
RUN; 
/*6.create new feature : month_num, weekdays*/
DATA lab.bank_prep;
    SET lab.bank_prep;
/* Convert month abbreviations into month numbers */
    SELECT (month);
        WHEN ('jan') month_num = 1;
        WHEN ('feb') month_num = 2;
        WHEN ('mar') month_num = 3;
        WHEN ('apr') month_num = 4;
        WHEN ('may') month_num = 5;
        WHEN ('jun') month_num = 6;
        WHEN ('jul') month_num = 7;
        WHEN ('aug') month_num = 8;
        WHEN ('sep') month_num = 9;
        WHEN ('oct') month_num = 10;
        WHEN ('nov') month_num = 11;
        WHEN ('dec') month_num = 12;
        OTHERWISE month_num = .;
    END;
/* Now build call_date */
    call_date = mdy(month_num, day, 2020);
    FORMAT call_date date9.;
/* Extract month & weekday */
    month_num   = month(call_date); /* Extract numeric month (1–12) */
    weekday_name = weekday(call_date); /* Extract weekday (1=Sunday, 2=Monday, etc.) */
RUN;

/*7. combine campaign and previous because want
 to know number of contact time influence the target variable*/

DATA lab.bank_prep;
    SET lab.bank_prep;
    /* Total contacts */
    total_contacts = SUM(campaign, previous);
RUN;
/*8. Creates a new binary variable contacted_before*/
DATA lab.bank_prep;
    SET lab.bank_prep;
   
 /* Contacted before */
    IF pdays >= 0 THEN contacted_before=1;
    ELSE contacted_before=0;
	
RUN;

/*encoding target variable*/
DATA lab.bank_prep;
	SET lab.bank_prep;
	IF deposit ="yes" THEN deposit_num =1;
	ELSE IF deposit = "no" THEN deposit_num =0;
RUN;	

/*Hypothesis 1: Age group affects subscription to term deposits.*/
PROC FREQ DATA=lab.bank_prep;
   TABLES age_group*deposit / CHISQ;
RUN;
/*Hypothesis 2: Marital status influences term deposit subscriptions*/
PROC FREQ DATA=lab.bank_prep;
   TABLES marital*deposit / CHISQ;
RUN;

/*Hypothesis 3: Customers previously contacted are more likely to subscribe.*/
PROC FREQ DATA=lab.bank_prep;
   TABLES contacted_before*deposit / CHISQ;
RUN;
/*Hypothesis 4: Total contacts affect subscription to term deposits*/
PROC FREQ DATA=lab.bank_prep;
   TABLES total_contacts*deposit / CHISQ;
RUN;
/*Hypothesis 5: Has_loan ( housing or personal loan) affects subscription to term deposits.*/
PROC FREQ DATA=lab.bank_prep;
   TABLES Has_Loan*deposit / CHISQ;
RUN;
/*Hypothesis 6: Job type influences subscription rates.*/
PROC FREQ DATA=lab.bank_prep;
   TABLES job_simplified*deposit / CHISQ;
RUN;

