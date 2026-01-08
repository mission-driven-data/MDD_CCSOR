----------------------------------------------------------------
IF OBJECT_ID (N'dbo._MDD_CCSOR_RoleEpisodes') IS NOT NULL
DROP TABLE dbo._MDD_CCSOR_RoleEpisodes

select 
	re.Role
	,re.[TOTAL NONCCP HRS]
	,re.[% NONCCP HRS]
	,re.[TOT EXP CCP HRS]
	,re.[% EXP CCP HRS]
	,re.[Start Date]
	,dateadd(day,-1,lead([Start Date])
		over (partition by role
				order by [Start Date] asc )) as [End Date]
into
	_MDD_CCSOR_RoleEpisodes
from RoleHoursExpected$ re 

------------------------------------------------------------------------



IF OBJECT_ID (N'dbo._MDD_CCSOR_FteForEmps') IS NOT NULL
DROP TABLE dbo._MDD_CCSOR_FteForEmps
;with FormRole as
(
select distinct 
	ev.empvisit_id
	,ev.empvisittype
	,ev.for_emp_id 
	,e.first_name + ' ' + e.last_name  [Employee Name]
	,ev.rev_timein 
	,efdate.[CCP Effective Date] [CCP Effective Date in Form]
	,ISNULL (ev.rev_timein , efdate.[CCP Effective Date]) [CCP Effective Date]
	,priroleup.[Primary CCP Role (updated)]
	,priFTEup.[Primary CCP Role FTE (updated)]
	,secroleup.[Secondary CCP Role (updated)]
	,secFTEup.[Secondary CCP Role FTE (updated)]
	--,ISNULL(efdate.[CCP Effective Date], ev.rev_timein]) CCP_Form_EffectiveDate
	--,(select max(ld1.lookup_desc) from LookupDict ld1 where ISnumeric(svaa.answer)=1 and ld1.lookup_id= svaa.answer)
	--, svaa.answer
	,addhrsup.[Additional NonCCP hours (updated)]
	,addhrsInj.[Additional NonCCP hours (injected)]

	,priroleInj.[Primary CCP Role (Injected)]
	,priFTEInj.[Primary CCP Role FTE (Injected)]
	,secroleInj.[Secondary CCP Role (Injected)]
	,secFTEInj.[Secondary CCP Role FTE (Injected)]

from EmpVisit ev
left join employees e on e.emp_id= ev.for_emp_id
left join (select ev.empvisit_id, ISNULL (svaa.answer, a.answer)[CCP Effective Date]
			from EmpVisit ev
				inner join FormVersion fv on ev.form_ver_id = fv.form_ver_id
				inner join forms f on f.form_id = fv.form_id
				left join Category c on c.form_ver_id= fv.form_ver_id
				left join Question q on q.category_id= c.category_id
				left join SavedVisitAnswer svaa on svaa.question_id= q.question_id and svaa.clientvisit_id= ev.empvisit_id
				left join Answer a on a.answer_id= svaa.answer_id
			where ev.empvisittype in ('CCP Updates')
			and q.question_text= 'CCP Effective Date'
			and ISNULL(svaa.answer, a.answer) is not null 
			) efdate on efdate.empvisit_id= ev.empvisit_id
left join (select ev.empvisit_id, ld.lookup_desc [Primary CCP Role (updated)]
			from EmpVisit ev
				inner join FormVersion fv on ev.form_ver_id = fv.form_ver_id
				inner join forms f on f.form_id = fv.form_id
				left join Category c on c.form_ver_id= fv.form_ver_id
				left join Question q on q.category_id= c.category_id
				left join SavedVisitAnswer svaa on svaa.question_id= q.question_id and svaa.clientvisit_id= ev.empvisit_id
				left join Answer a on a.answer_id= svaa.answer_id
				left join LookupDict ld on ld.lookup_id = ISNULL (svaa.answer, a.answer)
			where ev.empvisittype in ('CCP Updates')
			and q.question_text= 'Primary CCP Role (updated)'
			and ISNULL(svaa.answer, a.answer) is not null 
			) priroleup on priroleup.empvisit_id= ev.empvisit_id
left join (select ev.empvisit_id, ISNULL (svaa.answer, a.answer)[Primary CCP Role FTE (updated)]
			from EmpVisit ev
				inner join FormVersion fv on ev.form_ver_id = fv.form_ver_id
				inner join forms f on f.form_id = fv.form_id
				left join Category c on c.form_ver_id= fv.form_ver_id
				left join Question q on q.category_id= c.category_id
				left join SavedVisitAnswer svaa on svaa.question_id= q.question_id and svaa.clientvisit_id= ev.empvisit_id
				left join Answer a on a.answer_id= svaa.answer_id
			where ev.empvisittype in ('CCP Updates')
			and q.question_text= 'Primary CCP Role FTE (updated)'
			and ISNULL(svaa.answer, a.answer) is not null 
			) priFTEup on priFTEup.empvisit_id= ev.empvisit_id
left join (select ev.empvisit_id, ld.lookup_desc  [Secondary CCP Role (updated)]
			from EmpVisit ev
				inner join FormVersion fv on ev.form_ver_id = fv.form_ver_id
				inner join forms f on f.form_id = fv.form_id
				left join Category c on c.form_ver_id= fv.form_ver_id
				left join Question q on q.category_id= c.category_id
				left join SavedVisitAnswer svaa on svaa.question_id= q.question_id and svaa.clientvisit_id= ev.empvisit_id
				left join Answer a on a.answer_id= svaa.answer_id
				left join LookupDict ld on ld.lookup_id = ISNULL (svaa.answer, a.answer)
			where ev.empvisittype in ('CCP Updates')
			and q.question_text= 'Secondary CCP Role (updated)'
			and ISNULL(svaa.answer, a.answer) is not null 
			) secroleup on secroleup.empvisit_id= ev.empvisit_id
left join (select ev.empvisit_id, ISNULL (svaa.answer, a.answer)[Secondary CCP Role FTE (updated)]
			from EmpVisit ev
				inner join FormVersion fv on ev.form_ver_id = fv.form_ver_id
				inner join forms f on f.form_id = fv.form_id
				left join Category c on c.form_ver_id= fv.form_ver_id
				left join Question q on q.category_id= c.category_id
				left join SavedVisitAnswer svaa on svaa.question_id= q.question_id and svaa.clientvisit_id= ev.empvisit_id
				left join Answer a on a.answer_id= svaa.answer_id
			where ev.empvisittype in ('CCP Updates')
			and q.question_text= 'Secondary CCP Role FTE (updated)'
			and ISNULL(svaa.answer, a.answer) is not null 
			) secFTEup on secFTEup.empvisit_id= ev.empvisit_id


left join (select ev.empvisit_id, ld.lookup_desc  [Primary CCP Role (Injected)]
			from EmpVisit ev
				inner join FormVersion fv on ev.form_ver_id = fv.form_ver_id
				inner join forms f on f.form_id = fv.form_id
				left join Category c on c.form_ver_id= fv.form_ver_id
				left join Question q on q.category_id= c.category_id
				left join SavedVisitAnswer svaa on svaa.question_id= q.question_id and svaa.clientvisit_id= ev.empvisit_id
				left join Answer a on a.answer_id= svaa.answer_id
				left join LookupDict ld on ld.lookup_id = ISNULL (svaa.answer, a.answer)
			where ev.empvisittype in ('CCP Updates')
			and q.question_text= 'Primary CCP Role (updated)'
			and ISNULL(svaa.answer, a.answer) is not null 
			) priroleInj on priroleInj.empvisit_id= ev.empvisit_id
left join (select ev.empvisit_id, ISNULL (svaa.answer, a.answer)[Primary CCP Role FTE (Injected)]
			from EmpVisit ev
				inner join FormVersion fv on ev.form_ver_id = fv.form_ver_id
				inner join forms f on f.form_id = fv.form_id
				left join Category c on c.form_ver_id= fv.form_ver_id
				left join Question q on q.category_id= c.category_id
				left join SavedVisitAnswer svaa on svaa.question_id= q.question_id and svaa.clientvisit_id= ev.empvisit_id
				left join Answer a on a.answer_id= svaa.answer_id
			where ev.empvisittype in ('CCP Updates')
			and q.question_text= 'Primary CCP Role FTE (Injected)'
			and ISNULL(svaa.answer, a.answer) is not null 
			) priFTEInj on priFTEInj.empvisit_id= ev.empvisit_id
left join (select ev.empvisit_id, ld.lookup_desc  [Secondary CCP Role (Injected)]
			from EmpVisit ev
				inner join FormVersion fv on ev.form_ver_id = fv.form_ver_id
				inner join forms f on f.form_id = fv.form_id
				left join Category c on c.form_ver_id= fv.form_ver_id
				left join Question q on q.category_id= c.category_id
				left join SavedVisitAnswer svaa on svaa.question_id= q.question_id and svaa.clientvisit_id= ev.empvisit_id
				left join Answer a on a.answer_id= svaa.answer_id
				left join LookupDict ld on ld.lookup_id = ISNULL (svaa.answer, a.answer)
			where ev.empvisittype in ('CCP Updates')
			and q.question_text= 'Secondary CCP Role (Injected)'
			and ISNULL(svaa.answer, a.answer) is not null 
			) secroleInj on secroleInj.empvisit_id= ev.empvisit_id
left join (select ev.empvisit_id, ISNULL (svaa.answer, a.answer)[Secondary CCP Role FTE (Injected)]
			from EmpVisit ev
				inner join FormVersion fv on ev.form_ver_id = fv.form_ver_id
				inner join forms f on f.form_id = fv.form_id
				left join Category c on c.form_ver_id= fv.form_ver_id
				left join Question q on q.category_id= c.category_id
				left join SavedVisitAnswer svaa on svaa.question_id= q.question_id and svaa.clientvisit_id= ev.empvisit_id
				left join Answer a on a.answer_id= svaa.answer_id
			where ev.empvisittype in ('CCP Updates')
			and q.question_text= 'Secondary CCP Role FTE (Injected)'
			and ISNULL(svaa.answer, a.answer) is not null 
			) secFTEInj on secFTEInj.empvisit_id= ev.empvisit_id

left join (select ev.empvisit_id, ISNULL (svaa.answer, a.answer)[Additional NonCCP hours (updated)]
			from EmpVisit ev
				inner join FormVersion fv on ev.form_ver_id = fv.form_ver_id
				inner join forms f on f.form_id = fv.form_id
				left join Category c on c.form_ver_id= fv.form_ver_id
				left join Question q on q.category_id= c.category_id
				left join SavedVisitAnswer svaa on svaa.question_id= q.question_id and svaa.clientvisit_id= ev.empvisit_id
				left join Answer a on a.answer_id= svaa.answer_id
			where ev.empvisittype in ('CCP Updates')
			and q.question_text= 'Additional NonCCP hours (updated)'
			and ISNULL(svaa.answer, a.answer) is not null 
			) addhrsup on addhrsup.empvisit_id= ev.empvisit_id
left join (select ev.empvisit_id, ISNULL (svaa.answer, a.answer)[Additional NonCCP hours (injected)]
			from EmpVisit ev
				inner join FormVersion fv on ev.form_ver_id = fv.form_ver_id
				inner join forms f on f.form_id = fv.form_id
				left join Category c on c.form_ver_id= fv.form_ver_id
				left join Question q on q.category_id= c.category_id
				left join SavedVisitAnswer svaa on svaa.question_id= q.question_id and svaa.clientvisit_id= ev.empvisit_id
				left join Answer a on a.answer_id= svaa.answer_id
			where ev.empvisittype in ('CCP Updates')
			and q.question_text= 'Additional NonCCP hours (injected)'
			and ISNULL(svaa.answer, a.answer) is not null 
			) addhrsInj on addhrsInj.empvisit_id= ev.empvisit_id

where ev.empvisittype in ('CCP Updates')

) 

Select 
	--fr.*
	--,
	fr.empvisit_id
	,isnull(fr.for_emp_id, e.emp_id) EmpID
	,case when isnull(fr.[CCP Effective Date],e.date7) is null 
			then CAST ('2024-01-01' as date) 
			else isnull(fr.[CCP Effective Date],e.date7)
		end as [CCP Effective Date]
	,isnull (fr.[Employee Name], e.first_name + ' ' + e.last_name)
		[Employee Name]
	,case when isnull(fr.[Primary CCP Role (updated)],fr.[Primary CCP Role (Injected)]) is null and ld1.lookup_desc is null then 'No Role'
		when isnull(fr.[Primary CCP Role (updated)],fr.[Primary CCP Role (Injected)]) is null 
				then ld1.lookup_desc 
			else isnull(fr.[Primary CCP Role (updated)],fr.[Primary CCP Role (Injected)])
		end as [Primary CCP Role]
	,case when isnull(fr.[Primary CCP Role FTE (updated)],fr.[Primary CCP Role FTE (Injected)]) is null and e.num4 is null then 1
			when isnull(fr.[Primary CCP Role FTE (updated)],fr.[Primary CCP Role FTE (Injected)]) is null 
				then e.num4
			else isnull(fr.[Primary CCP Role FTE (updated)],fr.[Primary CCP Role FTE (Injected)])
		end as [Primary Role FTE]

	,case when isnull(fr.[Secondary CCP Role (updated)],fr.[Secondary CCP Role (Injected)]) is null and ld1.lookup_desc is null then 'No Role'
			when isnull(fr.[Secondary CCP Role (updated)],fr.[Secondary CCP Role (Injected)]) is null 
				then ld2.lookup_desc 
			else isnull(fr.[Secondary CCP Role (updated)],fr.[Secondary CCP Role (Injected)])
		end as [Secondary CCP Role]
	,case when isnull(fr.[Secondary CCP Role FTE (updated)],fr.[Secondary CCP Role FTE (Injected)]) is null and e.num4 is null then 1
		when isnull(fr.[Secondary CCP Role FTE (updated)],fr.[Secondary CCP Role FTE (Injected)]) is null 
				then e.num5
			else isnull(fr.[Secondary CCP Role FTE (updated)],fr.[Secondary CCP Role FTE (Injected)])
		end as [Secondary Role FTE]

into _MDD_CCSOR_FteForEmps	

from Employees e
left join FormRole  fr on e.emp_id= fr.for_emp_id 
left join LookupDict ld1 on ld1.lookup_id= e.dd4
left join LookupDict ld2 on ld2.lookup_id = e.dd3

--where emp_id = 4550
order by emp_id

, isnull(fr.[CCP Effective Date],e.date7)

--select * from _MDD_CCSOR_FteForEmps where empid = 4417
--select * from Employees where emp

--------------------------------------------------------------------------------------------

IF OBJECT_ID (N'dbo._MDD_CCSOR_FteEpisodes') IS NOT NULL
DROP TABLE dbo._MDD_CCSOR_FteEpisodes


;with EmpEpisodes as ---- sequences empform role/fte and if they dont have a emp form then use employee table role/fte
(select *
 , ROW_NUMBER () over (partition by empid  order by [CCP Effective Date]  ) rownum 
 ,lead([CCP Effective Date])
			over (partition by empid
					order by [CCP Effective Date] asc ) NextDate
from 
	(Select 
	* 
	,row_number () over ( partition by empid, cast ([CCP Effective Date] as date)  order by [CCP Effective Date] desc) rownum1
	from _MDD_CCSOR_FteForEmps
)x where rownum1=1 --and EmpID = 4550
union
select distinct
	NULL empvisit_id
	,ee.EmpID
	,'2024-01-01' [CCP Effective Date]
	,ee.[Employee Name]
	,ee.[Primary CCP Role]
	,ee.[Primary Role FTE]
	,ee.[Secondary CCP Role]
	,ee.[Secondary Role FTE]
	,null rownum1
	,null rownum
	,ee.[CCP Effective Date] NextDate

from
	(select *
 , ROW_NUMBER () over (partition by empid  order by [CCP Effective Date]  ) rownum 
from 
	(Select 
	* 
	,row_number () over ( partition by empid, cast ([CCP Effective Date] as date)  order by [CCP Effective Date] desc) rownum1
	from _MDD_CCSOR_FteForEmps
)x where rownum1 = 1) ee where ee.rownum = 1
--and EmpID= 4550

)

,FirstStep as -- every emp's employee table role/fte and sequence of empform role/fte 
	(select
		ee.*
		,re.*
		,isnull(case when re.[Start Date] < [CCP Effective Date] then [CCP Effective Date] else re.[Start Date] end, [CCP Effective Date]) as PrimEmpAndRuleStartDate
		,case when re.[End Date] < NextDate then re.[End Date] 
			when NextDate is null then re.[End Date] else NextDate end as PrimEmpAndRuleEndDate

	
	from
		EmpEpisodes ee
		left join _MDD_CCSOR_RoleEpisodes re on
			(re.[Start Date] <= ee.NextDate or ee.NextDate is null) 
			and (re.[End Date] is null or re.[End Date] >= ee.[CCP Effective Date])
			and 
			ee.[Primary CCP Role] = re.Role
	) 

,AllCombinedSteps as
	(
	select
		cast(case when re2.[Start Date] < ee.PrimEmpAndRuleStartDate then ee.PrimEmpAndRuleStartDate
			else re2.[Start Date] end as date) [Employee Episode Start Date]
		,dateadd(day,-1,cast(case when re2.[End Date] is null and ee.PrimEmpAndRuleEndDate is not null then ee.PrimEmpAndRuleEndDate
			when re2.[End Date] > ee.PrimEmpAndRuleEndDate then ee.PrimEmpAndRuleEndDate
			else re2.[End Date] end as date)) as [Employee Episode End Date] --inclusive
		,ee.EmpID
		,ee.[Employee Name]
		,(ee.[Primary Role FTE]* ee.[% EXP CCP HRS]) + (ee.[Secondary Role FTE] * re2.[% EXP CCP HRS]) [Combined Expected %]
		,ee.[Primary CCP Role]
		,ee.[Primary Role FTE]
		,ee.[% EXP CCP HRS] [Primary Expected Percent]
		,ee.[Secondary CCP Role]
		,ee.[Secondary Role FTE]
		,re2.[% EXP CCP HRS] [Secondary Expected Percent]
	from
		FirstStep ee

		left join _MDD_CCSOR_RoleEpisodes re2 on
			((PrimEmpAndRuleEndDate is not null and re2.[Start Date] <= PrimEmpAndRuleEndDate and (re2.[End Date] is null or (re2.[End Date]>= PrimEmpAndRuleStartDate  and re2.[End Date] <= PrimEmpAndRuleEndDate)))
			or
			(PrimEmpAndRuleEndDate is null and (re2.[End Date] is null or re2.[End Date] > PrimEmpAndRuleStartDate)))
		--	(PrimEmpAndRuleEndDate is null or re2.[Start Date] <=	PrimEmpAndRuleEndDate)
		--and
		--(re2.[End Date] is null or re2.[End Date] >= 
		--			PrimEmpAndRuleStartDate)
			and 
			ee.[Secondary CCP Role] = re2.Role
--where ee.EmpID = 3908
	)

,Months AS
	(SELECT 1 AS MonthNum
	UNION ALL
	SELECT MonthNum + 1 as MonthNum 
	FROM Months 
	WHERE MonthNum <12)

,Years as 
	(select 2018 as YearNum
	union all
	select YearNum + 1 as YearNum
	from Years 
	where YearNum < datepart(year,getdate()) + 1)

,MonthAndYear as
	(select * 
	from Years 
	full outer join Months on 1=1)

,MoreMonthInfo as
	(select
		 Str(YearNum) + '-' + (case when MonthNum < 10 then '0' + ltrim(rtrim(Str(MonthNum))) else ltrim(rtrim(Str(MonthNum))) end) as YearMonthForSorting
		,DateName( month , DateAdd( month , MonthNum , -1 )) + ', ' + ltrim(rtrim(str(YearNum))) as [Month and Year]
		,DateName( month , DateAdd( month , MonthNum , -1 )) [Month Name]
		,yearnum [Year Name]
		,cast(str(yearnum) + '-' + str(monthnum) + '-01' as date) [First Day of the Month]
		,dateadd(day,-1,(dateadd(month,1,cast(str(yearnum) + '-' + str(monthnum) + '-01' as date)))) [Last Day of the Month]
		,dateadd(month,1,cast(str(yearnum) + '-' + str(monthnum) + '-01' as date)) [First Day of the Next Month]
		,dateadd(day,-1,cast(str(yearnum) + '-' + str(monthnum) + '-01' as date)) [Last Day of the Previous Month] 
		,cast(str(yearnum) +'-01-01' as date) [First Day of the Calendar Year]
		,cast('12-31-' + str(yearnum) as date) [Last Day of the Calendar Year]
		,dateadd(day,1,cast('12-31-' + str(yearnum) as date)) [First Day of the Next Calendar Year]
		,dateadd(day,-1,cast(str(yearnum) +'-01-01' as date)) [Last Day of the Previous Calendar Year]
		,datediff(day,cast(str(yearnum) + '-' + str(monthnum) + '-01' as date),dateadd(day,-1,(dateadd(month,1,cast(str(yearnum) + '-' + str(monthnum) + '-01' as date))))) +1 DaysInMonth
		from
			MonthAndYear)
,WithMonths as
	(
	select
		mmi.[Year Name]
		,mmi.[Month Name]
		,mmi.YearMonthForSorting
		,mmi.[Month and Year]
		,mmi.DaysInMonth
		,(cast(mmi.DaysInMonth as decimal)/365)*100 PercentOfYear
		,(cast(mmi.DaysInMonth as decimal)/365) *2080 Total100PercentFTEHoursThisMonth
		,acs.[Combined Expected %]
		,acs.EmpID
		,case when acs.[Employee Episode Start Date] > mmi.[First Day of the Month] then acs.[Employee Episode Start Date] else mmi.[First Day of the Month] end [Beginning of Month Ep]
		,case when acs.[Employee Episode End Date] <= mmi.[Last Day of the Month] then acs.[Employee Episode End Date] else mmi.[Last Day of the Month] end [End of Month Ep]
		,datediff(day,case when acs.[Employee Episode Start Date] > mmi.[First Day of the Month] then acs.[Employee Episode Start Date] else mmi.[First Day of the Month] end,
				case when acs.[Employee Episode End Date] <= mmi.[Last Day of the Month] then acs.[Employee Episode End Date] else mmi.[Last Day of the Month] end) DaysToapply
		--,sum(acs.[Combined Expected %] * mmi.DaysInMonth) /max(mmi.daysinmonth) MonthlyExpectedPercent
		,acs.[Primary CCP Role]
		,acs.[Primary Role FTE]
		,acs.[Secondary CCP Role]
		,acs.[Secondary Role FTE]
	from
		MoreMonthInfo mmi
		left join AllCombinedSteps acs on 
			acs.[Employee Episode Start Date] <= mmi.[Last Day of the Month]
			and (acs.[Employee Episode End Date] is null or dateadd(day,-1,acs.[Employee Episode End Date]) > mmi.[Last Day of the Previous Month])
	--where acs.EmpID = 3908
	
	)

select
	wm.EmpID
	,wm.[Month and Year]
	,wm.[Month Name]
	,wm.[Year Name]
	,wm.YearMonthForSorting
	,wm.PercentOfYear
	,sum(wm.[Combined Expected %] * wm.DaysToapply)/wm.DaysInMonth ExpectationPercentForMonth
	,2080 * (wm.PercentOfYear/100) * (sum(wm.[Combined Expected %] * wm.DaysToapply)/wm.DaysInMonth) HoursExpectedInMonth
		,[Primary CCP Role]
		,[Primary Role FTE]
		,[Secondary CCP Role]
		,[Secondary Role FTE]
into
	_MDD_CCSOR_FteEpisodes
from 
	WithMonths wm
group by
wm.EmpID
	,wm.[Month and Year]
	,wm.[Month Name]
	,wm.[Year Name]
	,wm.[Month and Year]
	,wm.YearMonthForSorting
	,wm.DaysInMonth
	,wm.PercentOfYear
	,[Primary CCP Role]
		,[Primary Role FTE]
		,[Secondary CCP Role]
		,[Secondary Role FTE]
--select * from _MDD_CCSOR_FteEpisodes e where e.EmpID = 3908