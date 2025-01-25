



--Alter PROCEDURE [dbo].[_CCSOR_Productivity]

--AS
--BEGIN
	
	SET NOCOUNT ON;


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
	,ISNULL (efdate.[CCP Effective Date], ev.rev_timein ) [CCP Effective Date]
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
			where (ev.empvisittype in ('CCP Updates', 'Employee New/Update') or f.form_id in (507,503))
			and q.question_text like  'CCP Effective Date%'
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
			where (ev.empvisittype in ('CCP Updates', 'Employee New/Update') or f.form_id in (507,503))
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
			where (ev.empvisittype in ('CCP Updates', 'Employee New/Update') or f.form_id in (507,503))
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
			where (ev.empvisittype in ('CCP Updates', 'Employee New/Update') or f.form_id in (507,503))
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
			where (ev.empvisittype in ('CCP Updates', 'Employee New/Update') or f.form_id in (507,503))
			and q.question_text= 'Secondary CCP Role FTE (updated)'
			and ISNULL(svaa.answer, a.answer) is not null 
			) secFTEup on secFTEup.empvisit_id= ev.empvisit_id
left join (select ev.empvisit_id 
				,SUBSTRING(
						svan.answer_note, 
						CHARINDEX('>', svan.answer_note) + 1, -- Start position after the first '>'
						CHARINDEX('<', svan.answer_note, CHARINDEX('>', svan.answer_note)) - CHARINDEX('>', svan.answer_note) - 1 -- Length until the next '<'
					) AS [Primary CCP Role (Injected)]
			from EmpVisit ev
				inner join SavedVisitAnswerNote svan on svan.clientvisit_id= ev.empvisit_id
				inner join Question q on q.question_id= svan.question_id	
			where ev.empvisittype in ('CCP Updates', 'Employee New/Update') 
			and q.question_text= 'Primary CCP Role (Injected)'
			and svan.answer_note is not null
			) priroleInj on priroleInj.empvisit_id= ev.empvisit_id
left join (select ev.empvisit_id--svan.answer_note-- 
				,Try_Cast (
						SUBSTRING(
							svan.answer_note, 
							CHARINDEX('>', svan.answer_note) + 1, -- Start position after the first '>'
							CHARINDEX('<', svan.answer_note, CHARINDEX('>', svan.answer_note)) - CHARINDEX('>', svan.answer_note) - 1 -- Length until the next '<'
						) AS DECIMAL(10, 2)
					)as [Primary CCP Role FTE (Injected)]
			from EmpVisit ev
				inner join SavedVisitAnswerNote svan on svan.clientvisit_id= ev.empvisit_id
				inner join Question q on q.question_id= svan.question_id
			where ev.empvisittype in ('CCP Updates', 'Employee New/Update') 
			and q.question_text= 'Primary CCP Role FTE (Injected)'
			and svan.answer_note is not null 
			) priFTEInj on priFTEInj.empvisit_id= ev.empvisit_id
left join (select ev.empvisit_id 
				,SUBSTRING(
						svan.answer_note, 
						CHARINDEX('>', svan.answer_note) + 1, -- Start position after the first '>'
						CHARINDEX('<', svan.answer_note, CHARINDEX('>', svan.answer_note)) - CHARINDEX('>', svan.answer_note) - 1 -- Length until the next '<'
					) AS [Secondary CCP Role (Injected)]
			from EmpVisit ev
				inner join SavedVisitAnswerNote svan on svan.clientvisit_id= ev.empvisit_id
				inner join Question q on q.question_id= svan.question_id	
			where ev.empvisittype in ('CCP Updates', 'Employee New/Update') 
			and q.question_text= 'Secondary CCP Role (Injected)'
			and svan.answer_note is not null
			) secroleInj on secroleInj.empvisit_id= ev.empvisit_id
left join (select ev.empvisit_id--svan.answer_note-- 
				,Try_Cast (
						SUBSTRING(
							svan.answer_note, 
							CHARINDEX('>', svan.answer_note) + 1, -- Start position after the first '>'
							CHARINDEX('<', svan.answer_note, CHARINDEX('>', svan.answer_note)) - CHARINDEX('>', svan.answer_note) - 1 -- Length until the next '<'
						) AS DECIMAL(10, 2)
					)as [Secondary CCP Role FTE (Injected)]
			from EmpVisit ev
				inner join SavedVisitAnswerNote svan on svan.clientvisit_id= ev.empvisit_id
				inner join Question q on q.question_id= svan.question_id
			where ev.empvisittype in ('CCP Updates', 'Employee New/Update') 
			and q.question_text= 'Secondary CCP Role FTE (Injected)'
			and svan.answer_note is not null 
			) secFTEInj on secFTEInj.empvisit_id= ev.empvisit_id

left join (select ev.empvisit_id, ISNULL (svaa.answer, a.answer)[Additional NonCCP hours (updated)]
			from EmpVisit ev
				inner join FormVersion fv on ev.form_ver_id = fv.form_ver_id
				inner join forms f on f.form_id = fv.form_id
				left join Category c on c.form_ver_id= fv.form_ver_id
				left join Question q on q.category_id= c.category_id
				left join SavedVisitAnswer svaa on svaa.question_id= q.question_id and svaa.clientvisit_id= ev.empvisit_id
				left join Answer a on a.answer_id= svaa.answer_id
			where (ev.empvisittype in ('CCP Updates', 'Employee New/Update') or f.form_id in (507,503))
			and q.question_text= 'Additional NonCCP hours (updated)'
			and ISNULL(svaa.answer, a.answer) is not null 
			) addhrsup on addhrsup.empvisit_id= ev.empvisit_id
left join (select ev.empvisit_id--svan.answer_note-- 
				,Try_Cast (
						SUBSTRING(
							svan.answer_note, 
							CHARINDEX('>', svan.answer_note) + 1, -- Start position after the first '>'
							CHARINDEX('<', svan.answer_note, CHARINDEX('>', svan.answer_note)) - CHARINDEX('>', svan.answer_note) - 1 -- Length until the next '<'
						) AS DECIMAL(10, 2)
					)as [Additional NonCCP hours (injected)]
			from EmpVisit ev
				inner join SavedVisitAnswerNote svan on svan.clientvisit_id= ev.empvisit_id
				inner join Question q on q.question_id= svan.question_id
			where ev.empvisittype in ('CCP Updates', 'Employee New/Update') 
			and q.question_text= 'Additional NonCCP hours (injected)'
			and svan.answer_note is not null 
			) addhrsInj on addhrsInj.empvisit_id= ev.empvisit_id

where (ev.empvisittype in ('CCP Updates', 'Employee New/Update') )
) 

Select 
	--fr.*
	--,
	fr.empvisit_id
	,isnull(fr.for_emp_id, e.emp_id) EmpID


	--,efdate.[CCP Effective Date] [CCP Effective Date in Form]
	--,ISNULL (efdate.[CCP Effective Date], ev.rev_timein ) [CCP Effective Date]



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

	--Added by Ginger - maybe needs some touchups by Nicole
	--,case when isnull(fr.[Additional NonCCP hours (updated)],fr.[Additional NonCCP hours (Injected)]) is null and e.num4 is null then 1
	--	when isnull(fr.[Additional NonCCP hours (updated)],fr.[Additional NonCCP hours (Injected)]) is null 
	--			then e.num5
	--		else isnull(fr.[Additional NonCCP hours (updated)],fr.[Additional NonCCP hours (Injected)])
	--	end as [Additional NonCCP hours]
	
	,case when isnull(fr.[Additional NonCCP hours (updated)],fr.[Additional NonCCP hours (Injected)]) is not null 
				then isnull(fr.[Additional NonCCP hours (updated)],fr.[Additional NonCCP hours (Injected)])
			else null
		end as [Additional NonCCP hours]
,e.emp_status

into _MDD_CCSOR_FteForEmps	

from Employees e
left join FormRole  fr on e.emp_id= fr.for_emp_id 
left join LookupDict ld1 on ld1.lookup_id= e.dd4
left join LookupDict ld2 on ld2.lookup_id = e.dd3

--where emp_id = 4550
order by emp_id

, isnull(fr.[CCP Effective Date],e.date7)
--------------------------------------------------------------------------------------------


IF OBJECT_ID (N'dbo._MDD_CCSOR_FteEpisodes') IS NOT NULL
DROP TABLE dbo._MDD_CCSOR_FteEpisodes


;with EmpEpisodes as ---- sequences empform role/fte and if they dont have a emp form then use employee table role/fte
(select 
	 [empvisit_id]
      ,[EmpID]
      ,[CCP Effective Date]
      ,[Employee Name]
      ,[Primary CCP Role]
      ,[Primary Role FTE]
      ,[Secondary CCP Role]
      ,[Secondary Role FTE]
      ,[Additional NonCCP hours]
	  ,[rownum1]
,emp_status
	 , ROW_NUMBER () over (partition by empid  order by [CCP Effective Date]  ) rownum 
	 ,lead([CCP Effective Date])
				over (partition by empid
						order by [CCP Effective Date] asc ) NextDate
from 
	(Select 
	 [empvisit_id]
      ,[EmpID]
      ,[CCP Effective Date]
      ,[Employee Name]
      ,[Primary CCP Role]
      ,[Primary Role FTE]
      ,[Secondary CCP Role]
      ,[Secondary Role FTE]
      ,[Additional NonCCP hours]
,emp_status
	,row_number () over ( partition by empid, cast ([CCP Effective Date] as date)  order by [CCP Effective Date] desc) rownum1
	from _MDD_CCSOR_FteForEmps
)x where rownum1=1 --and EmpID = 4208
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
	,ee.[Additional NonCCP hours]
	,null rownum1
,emp_status
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
--and EmpID= 4208

)

,FirstStep as -- every emp's employee table role/fte and sequence of empform role/fte 
	(
	select
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
		cast(case when re2.[Start Date] is null then ee.PrimEmpAndRuleStartDate when re2.[Start Date] < ee.PrimEmpAndRuleStartDate then ee.PrimEmpAndRuleStartDate
			else re2.[Start Date] end as date) [Employee Episode Start Date]
		,dateadd(day,-1,cast(case when re2.[End Date] is null and ee.PrimEmpAndRuleEndDate is not null then ee.PrimEmpAndRuleEndDate
			when re2.[End Date] > ee.PrimEmpAndRuleEndDate then ee.PrimEmpAndRuleEndDate
			else re2.[End Date] end as date)) as [Employee Episode End Date] --inclusive
		,ee.EmpID
		,ee.[Employee Name]
,ee.emp_status
		,case when ee.[Secondary Role FTE] is not null then (ee.[Primary Role FTE]* ee.[% EXP CCP HRS]) + (ee.[Secondary Role FTE] * re2.[% EXP CCP HRS])
			else (ee.[Primary Role FTE]* ee.[% EXP CCP HRS]) end [Combined Expected %]
		,ee.[Primary CCP Role]
		,ee.[Primary Role FTE]
		,ee.[% EXP CCP HRS] [Primary Expected Percent]
		,ee.[Secondary CCP Role]
		,ee.[Secondary Role FTE]
		,re2.[% EXP CCP HRS] [Secondary Expected Percent]
		,ee.[Additional NonCCP hours]
	from
		FirstStep ee

		left join _MDD_CCSOR_RoleEpisodes re2 on
			((PrimEmpAndRuleEndDate is not null and re2.[Start Date] <= PrimEmpAndRuleEndDate and (re2.[End Date] is null or (re2.[End Date]>= PrimEmpAndRuleStartDate  and re2.[End Date] <= PrimEmpAndRuleEndDate)))
			or
			(PrimEmpAndRuleEndDate is null and (re2.[End Date] is null or re2.[End Date] > PrimEmpAndRuleStartDate)))
			and 

			ee.[Secondary CCP Role] = re2.Role
--where ee.EmpID = 4208
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
		,MonthNum
		,YearNum
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
		,mmi.MonthNum
		,mmi.YearNum
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
		,acs.[Additional NonCCP hours]
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
		,max(wm.[Additional NonCCP hours])/12  [Additional NonCCP hours to adjust]
	,case when max(wm.[Additional NonCCP hours]) > 0 
		then  (2080 * (wm.PercentOfYear/100) * (sum(wm.[Combined Expected %] * wm.DaysToapply)/wm.DaysInMonth)) - (max(wm.[Additional NonCCP hours])/12)
		else (2080 * (wm.PercentOfYear/100) * (sum(wm.[Combined Expected %] * wm.DaysToapply)/wm.DaysInMonth)) end[Adjusted Expected Hours for Month]
	,wm.MonthNum
	,wm.YearNum
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
	,wm.MonthNum
	,wm.YearNum
		--,wm.[Additional NonCCP hours]
--select * from _MDD_CCSOR_FteEpisodes e where e.EmpID = 3908
--select * from _MDD_CCSOR_FteEpisodes e where e.EmpID = 3908







--------------------------------------------------------------------------
--***SMART CLIENT VISIT****



IF OBJECT_ID (N'dbo._mdd_Janet_SmartClientVisitEmpTime_AllTimes') IS NOT NULL
DROP TABLE dbo._mdd_Janet_SmartClientVisitEmpTime_AllTimes

select
	e.emp_id
	, cv.rev_timein as TransitionTime
	,cast(rev_timein as date) TransitionTimeDate
into
	_mdd_Janet_SmartClientVisitEmpTime_AllTimes
from
	employees e
	left join clientvisit cv on e.emp_id = cv.emp_id
where 
	cv.splitprimary_clientvisit_id is null
	and cv.visittype not in ( 'No Show/Cancellation', 'CANCEL/NO SHOW')
	and cv.rev_timein >= '2024-01-01'
union

select 
	e.emp_id
	, cv.rev_timeout as TransitionTime
	,cast(rev_timeout as date) TransitionTimeDate
from
	employees e
	left join clientvisit cv on e.emp_id = cv.emp_id
where 
	cv.splitprimary_clientvisit_id is null
		and cv.visittype not in ( 'No Show/Cancellation', 'CANCEL/NO SHOW')
	and cv.rev_timein >= '2024-01-01'

CREATE CLUSTERED Index IX_mdd_Janet_SmartClientVisitEmpTime_AllTimes ON _mdd_Janet_SmartClientVisitEmpTime_AllTimes (emp_id,TransitionTimeDate,TransitionTime)

IF OBJECT_ID (N'dbo._mdd_Janet_SmartClientVisitEmpTime_AllServices') IS NOT NULL
DROP TABLE dbo._mdd_Janet_SmartClientVisitEmpTime_AllServices

select
	cv.rev_timein
	, cv.rev_timeout
	, cv.client_id
	, cv.clientvisit_id
	,cv.emp_id
	,cast(cv.rev_timein as date) SvcDate
	
into
	_mdd_Janet_SmartClientVisitEmpTime_AllServices
from
	clientvisit cv
where 
	cv.splitprimary_clientvisit_id is null
	and cv.visittype not in ( 'No Show/Cancellation', 'CANCEL/NO SHOW')
	and cv.rev_timein >= '2024-01-01'

CREATE CLUSTERED Index IX_mdd_Janet_SmartClientVisitEmpTime_AllServices ON _mdd_Janet_SmartClientVisitEmpTime_AllServices (emp_id,SvcDate,rev_timein,rev_timeout)

IF OBJECT_ID (N'dbo._mdd_Janet_SmartClientVisitEmpTime_NextTransition') IS NOT NULL
DROP TABLE dbo._mdd_Janet_SmartClientVisitEmpTime_NextTransition

select 
		AllTimes.emp_id
		,AllTimes.TransitionTime
		,lead(TransitionTime)
				over (Partition by AllTimes.emp_id
						order by TransitionTime asc ) as NextTransitionTime
		,TransitionTimeDate
		,dateadd(day,-1,transitiontimedate) TransitionTimeDateMinus1
into
	_mdd_Janet_SmartClientVisitEmpTime_NextTransition
from
	_mdd_Janet_SmartClientVisitEmpTime_AllTimes AllTimes

CREATE CLUSTERED Index IX_mdd_Janet_SmartClientVisitEmpTime_NextTransition ON _mdd_Janet_SmartClientVisitEmpTime_NextTransition (emp_id,TransitionTimeDate,TransitionTimeDateMinus1)



IF OBJECT_ID (N'dbo._mdd_Janet_SmartClientVisitEmpTime_AllIntervals') IS NOT NULL
DROP TABLE dbo._mdd_Janet_SmartClientVisitEmpTime_AllIntervals

select 
	AllTimes.emp_id
	,count(clientvisit_id) as TotalServices
	,count(client_id) as TotalClients
	,datediff(minute,TransitionTime,NextTransitionTime) as DurationOfInterval
	,TransitionTime
	,NextTransitionTime
	,TransitionTimeDate
into
	_mdd_Janet_SmartClientVisitEmpTime_AllIntervals
from
	_mdd_Janet_SmartClientVisitEmpTime_NextTransition AllTimes
left join
		_mdd_Janet_SmartClientVisitEmpTime_AllServices cv 
			on cv.emp_id = AllTimes.emp_id 
			and (cv.svcdate = alltimes.transitiontimedate
				or cv.svcdate = alltimes.transitiontimedateminus1)

where 
	cv.rev_timein <= AllTimes.TransitionTime 
	and cv.rev_timeout >= AllTimes.NextTransitionTime
group by
	AllTimes.emp_id
	,datediff(minute,TransitionTime,NextTransitionTime)
	,TransitionTime
	,NextTransitionTime
	,TransitionTimeDate
having 
	count(clientvisit_id) > 0 and count(client_id) > 0
	
CREATE CLUSTERED Index IX_mdd_Janet_SmartClientVisitEmpTime_AllIntervals ON _mdd_Janet_SmartClientVisitEmpTime_AllIntervals (emp_id,TransitionTimeDate)
	

IF OBJECT_ID (N'dbo._mdd_Janet_SmartClientVisitEmpTime') IS NOT NULL
DROP TABLE dbo._mdd_Janet_SmartClientVisitEmpTime

select
	clientvisit_id	
	,sum(WeightedDuration) as EmployeeTime
	,max(totalclients) as TotalClients
into
	_mdd_Janet_SmartClientVisitEmpTime
from
	(select
		cv.clientvisit_id
		,cast(ai.DurationOfInterval as decimal)/cast(totalclients as decimal) as WeightedDuration
		,totalclients as TotalClients
	from
		_mdd_Janet_SmartClientVisitEmpTime_AllServices cv
	left join
		_mdd_Janet_SmartClientVisitEmpTime_AllIntervals ai
			on ai.emp_id = cv.emp_id
			and (cv.svcdate = ai.transitiontimedate
					or ai.transitiontimedate = dateadd(day,1,cv.svcdate))
	where ai.TransitionTime >= rev_timein and ai.NextTransitionTime <= rev_timeout
			
	) akl
group by 
	clientvisit_id
;



---end smart client visit
---------------------------------------------------------------



IF OBJECT_ID (N'dbo._MDD_CCSOR_ProdDeliveredSvcs') IS NOT NULL
DROP TABLE dbo._MDD_CCSOR_ProdDeliveredSvcs

select
	cv.rev_timein
	,cv.rev_timeout
	,cv.clientvisit_id
	,cv.client_id
	,cv.emp_id
	,case when cv.visittype like '%Group%' then (cv.duration/ 60 )* 15 else emptime.EmployeeTime end as [Employee Duration]
	,cv.visittype
	,cv.duration
	,emptime.EmployeeTime
	,datepart(year,cv.rev_timein) [Svc Year]
	,datepart(month,cv.rev_timein) [Svc Month]
	,'https://www.cbh3.crediblebh.com/planner/plan.asp?plan_id=' + trim(str(cv.clientvisit_id)) [Visit Link]
	,'https://www.cbh3.crediblebh.com/client/my_cw_clients.asp?client_id=' + trim(str(cv.client_id)) as ClientLink
	,cv.emp_name
	,case when cv.non_billable= 1 then 'NB'
		when cv.non_billable= 0 then 'Billable'
		end as [Billable?]
into 
	dbo._MDD_CCSOR_ProdDeliveredSvcs
from
	clientvisit cv
	left join _mdd_Janet_SmartClientVisitEmpTime emptime on cv.clientvisit_id = emptime.clientvisit_id
where 
	cv.splitprimary_clientvisit_id is null
	and cv.visittype not in ( 'No Show/Cancellation', 'CANCEL/NO SHOW')
	and cv.rev_timein >= '2022-01-01'

-------------------------------------------------------------------------------------


IF OBJECT_ID (N'dbo._MDD_CCSOR_Productivity') IS NOT NULL
DROP TABLE dbo._MDD_CCSOR_Productivity

select
	eps.*
	,sum(svcs.[Employee Duration])/60 [Hours of Productivity]
	,sum((svcs.[Employee Duration])/60 + eps.[Additional NonCCP hours to adjust])/( eps.PercentOfYear* 2080 ) [Adjusted Employee Productivity Percent]
	,case when  ((sum(svcs.[Employee Duration])/60) / (eps.[Adjusted Expected Hours for Month])) <.7 then -3
		when ((sum(svcs.[Employee Duration])/60) / (eps.[Adjusted Expected Hours for Month])) between .70 and .799999 then -2
		when ((sum(svcs.[Employee Duration])/60) / (eps.[Adjusted Expected Hours for Month])) between .8 and .899999 then -1
		when ((sum(svcs.[Employee Duration])/60) / (eps.[Adjusted Expected Hours for Month])) between .9 and .999999 then 0
		when ((sum(svcs.[Employee Duration])/60) / (eps.[Adjusted Expected Hours for Month])) >= 1 then 1
		end as [flags for close to prod expectations]
	,((sum(svcs.[Employee Duration])/60) / (eps.[Adjusted Expected Hours for Month])) [Amount of prod to expectation]
	,e.first_name + ' ' +e.last_name [Employee Name]
	,e.emp_status
	,svcs.[Billable?] 
into
	dbo._MDD_CCSOR_Productivity
from
	_MDD_CCSOR_FteEpisodes eps
	inner join Employees e on e.emp_id= eps.EmpID
	left join _MDD_CCSOR_ProdDeliveredSvcs svcs on eps.EmpID = svcs.emp_id
		and svcs.[Svc Month] = eps.monthnum  
		and svcs.[Svc Year] = eps.YearNum
group by 
	eps.[Additional NonCCP hours to adjust]
	,eps.[Adjusted Expected Hours for Month]
	,eps.EmpID
	,eps.ExpectationPercentForMonth
	,eps.HoursExpectedInMonth
	,eps.[Month and Year]
	,eps.[Month Name]
	,eps.MonthNum
	,eps.PercentOfYear
	,eps.[Primary CCP Role]
	,eps.[Primary Role FTE]
	,eps.[Secondary CCP Role]
	,eps.[Secondary Role FTE]
	,eps.[Year Name]
	,eps.YearMonthForSorting
	,eps.YearNum
	,e.first_name + ' ' +e.last_name
	,svcs.[Billable?] 
	,e.emp_status

	--end

	