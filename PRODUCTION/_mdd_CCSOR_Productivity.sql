--Select top 2000 
--COUNT (distinct clientvisit_id) , emp_id, rev_timein, duration
--from clientvisit  where visittype <> 'CANCEL/NO SHOW'and  emp_id in (4767, 4473,4370) group by emp_id, rev_timein, duration order by rev_timein desc, emp_id 

--Select top 2000 clientvisit_id, emp_id, rev_timein, duration, *
--from clientvisit  cv where visittype <> 'CANCEL/NO SHOW'and  emp_id in (4767, 4473,4370) --group by emp_id, rev_timein, duration 
--order by cv.rev_timein desc, cv.emp_id 


/*
 - Group svc are 15 minutes per person in group
 - 2 roles that get split for .FTE  that map to the employee table  but have also been enterred manually to start 
	~ these have start dates based on an emp form so an emp has a role 1 and rol2 that start and then the end date is based on getting a new emp form with roles/ FTEs 
 - productivity goals are based on CCP and non CCP time by role 
		--- emp role1 .FTE  * the expected CCP hours for that role = the total expected hours for that role for that employee
			+
			emp role2 .fte * the expected CCP hours for that role = the total expected hours for that role for that employee
			= the total CCP hours for that employee 

		---	emp role1 .FTE  * the expected non CCP hours for that role = the total expected hours for that role for that employee
			+
			emp role2 .fte * the expected non CCP hours for that role = the total expected hours for that role for that employee
			= the total non CCP hours for that employee 

		-- the total of both calculations would equal the total hours worked for that employee 
		-- ccp hours are based on billable hours

		***ccp and non ccp expected hours are annual

Questions: 
- need more emp forms that have a past effective date with roles/ftes
- spreedsheet maintenance-- start dates
- mid month effective dates
- mid month role expectation change
- if no role?
- program svc that count for a specific role? 
*/




	SET NOCOUNT ON;


IF OBJECT_ID (N'dbo._mdd_Janet_SmartClientVisitEmpTime') IS NOT NULL
DROP TABLE dbo._mdd_Janet_SmartClientVisitEmpTime

;with AllServices as 
	(select
		cv.rev_timein
		, cv.rev_timeout
		, cv.client_id
		, cv.clientvisit_id
		,cv.emp_id
		,cv.visittype
		,cv.duration
		,cv.splitprimary_clientvisit_id
	from
		clientvisit cv
			where 
			 cv.splitprimary_clientvisit_id is null
			and cv.visittype <> 'No Show/Cancellation'
			)

--,GroupSvs as 
--(select
--		cv.rev_timein
--		, cv.rev_timeout
--		, cv.client_id
--		, cv.clientvisit_id
--		,cv.emp_id
--		,cv.visittype
--		,cv.duration
--		,cv.splitprimary_clientvisit_id
--	from
--		AllServices cv
--	where  
--		cv.visittype like '%Group%'
--)

--,NonGroupSvc as 
--(select
--		cv.rev_timein
--		, cv.rev_timeout
--		, cv.client_id
--		, cv.clientvisit_id
--		,cv.emp_id
--		,cv.visittype
--		,cv.duration
--		,cv.splitprimary_clientvisit_id
--	from
--		AllServices cv
--	where  
--		cv.visittype not like '%Group%'
--)



,AllTimes as 
	(select
		e.emp_id
		, cv.rev_timein as TransitionTime
	from
		employees e
		left join AllServices cv on e.emp_id = cv.emp_id
			where  cv.splitprimary_clientvisit_id is null
			and cv.visittype <> 'No Show/Cancellation'
	union

	select 
		e.emp_id
		, cv.rev_timeout as TransitionTime
	from
		employees e
		left join AllServices cv on e.emp_id = cv.emp_id
			where cv.splitprimary_clientvisit_id is null
			and cv.visittype <> 'No Show/Cancellation'
			)

,AllIntervals as
	(select 
		AllTimes.emp_id
		,count(clientvisit_id) as TotalServices
		,count(client_id) as TotalClients
		,datediff(minute,TransitionTime,NextTransitionTime) as DurationOfInterval
		,TransitionTime
		,NextTransitionTime
	from
		(select 
			AllTimes.emp_id
			,AllTimes.TransitionTime
			,lead(TransitionTime)
					over (Partition by AllTimes.emp_id
							order by TransitionTime asc ) as NextTransitionTime
		from
			AllTimes
		) AllTimes
	left join
			AllServices cv 
				on cv.emp_id = AllTimes.emp_id 
				and cv.rev_timein <= AllTimes.TransitionTime 
				and cv.rev_timeout >= AllTimes.NextTransitionTime
	group by
		AllTimes.emp_id
		,datediff(minute,TransitionTime,NextTransitionTime)
		,TransitionTime
		,NextTransitionTime
	having 
		count(clientvisit_id) > 0 and count(client_id) > 0)

	

select
	clientvisit_id	
	,sum(WeightedDuration) as EmployeeTime
	,max(totalclients) as TotalClients
into
	--Janet_SmartClientVisitEmpTime 
	_mdd_Janet_SmartClientVisitEmpTime
from
	(select
		cv.clientvisit_id
		,cast(ai.DurationOfInterval as decimal)/cast(totalclients as decimal) as WeightedDuration
		,totalclients as TotalClients
	from
		AllServices cv
	left join
		AllIntervals ai
			on ai.TransitionTime >= rev_timein and ai.NextTransitionTime <= rev_timeout
			and ai.emp_id = cv.emp_id
	) akl
group by 
	clientvisit_id










IF OBJECT_ID (N'dbo._mdd_CCSOR_ProdServices') IS NOT NULL
DROP TABLE dbo._mdd_CCSOR_ProdServices






;with 
--EmpEpisodes as 
--(select *
-- , ROW_NUMBER () over (partition by empid  order by [CCP Effective Date]  ) rownum 
-- ,lead([CCP Effective Date])
--			over (partition by empid
--					order by [CCP Effective Date] asc ) NextDate
--from 
--	(Select 
--	* 
--	,row_number () over ( partition by empid, cast ([CCP Effective Date] as date)  order by [CCP Effective Date] desc) rownum1
--	from _MDD_CCSOR_FteForEmps
--)x where rownum1=1 --and EmpID = 4550
--union
--select distinct
--	NULL empvisit_id
--	,ee.EmpID
--	,'2024-01-01' [CCP Effective Date]
--	,ee.[Employee Name]
--	,ee.[Primary CCP Role]
--	,ee.[Primary Role FTE]
--	,ee.[Secondary CCP Role]
--	,ee.[Secondary Role FTE]
--	,null rownum1
--	,null rownum
--	,ee.[CCP Effective Date] NextDate

--from
--	(select *
-- , ROW_NUMBER () over (partition by empid  order by [CCP Effective Date]  ) rownum 
--from 
--	(Select 
--	* 
--	,row_number () over ( partition by empid, cast ([CCP Effective Date] as date)  order by [CCP Effective Date] desc) rownum1
--	from _MDD_CCSOR_FteForEmps
--)x where rownum1 = 1) ee where ee.rownum = 1
----and EmpID= 4550

--)

--,FirstStep as 
--	(select
--		ee.*
--		,re.*
--		,isnull(case when re.[Start Date] < [CCP Effective Date] then [CCP Effective Date] else re.[Start Date] end, [CCP Effective Date]) as PrimEmpAndRuleStartDate
--		,case when re.[End Date] < NextDate then re.[End Date] 
--			when NextDate is null then re.[End Date] else NextDate end as PrimEmpAndRuleEndDate

	
--	from
--		EmpEpisodes ee
--		left join _MDD_CCSOR_RoleEpisodes re on
--			(re.[Start Date] <= ee.NextDate or ee.NextDate is null) 
--			and (re.[End Date] is null or re.[End Date] >= ee.[CCP Effective Date])
--			and 
--			ee.[Primary CCP Role] = re.Role
--	) 
--,AllCombinedSteps as
--	(
--	select
--		cast(case when re2.[Start Date] < ee.PrimEmpAndRuleStartDate then ee.PrimEmpAndRuleStartDate
--			else re2.[Start Date] end as date) [Employee Episode Start Date]
--		,cast(case when re2.[End Date] > ee.PrimEmpAndRuleEndDate then ee.PrimEmpAndRuleEndDate
--			else re2.[End Date] end as date) as [Employee Episode End Date] --inclusive
--		,ee.EmpID
--		,ee.[Employee Name]
--		,(ee.[Primary Role FTE]* ee.[% EXP CCP HRS]) + (ee.[Secondary Role FTE] * re2.[% EXP CCP HRS]) [Combined Expected %]
--		,ee.[Primary CCP Role]
--		,ee.[Primary Role FTE]
--		,ee.[% EXP CCP HRS] [Primary Expected Percent]
--		,ee.[Secondary CCP Role]
--		,ee.[Secondary Role FTE]
--		,re2.[% EXP CCP HRS] [Secondary Expected Percent]
--	from
--		FirstStep ee

--		left join _MDD_CCSOR_RoleEpisodes re2 on
--			(PrimEmpAndRuleEndDate is null or re2.[Start Date] <=	PrimEmpAndRuleEndDate)
--		and
--		(re2.[End Date] is null or re2.[End Date] >= 
--					PrimEmpAndRuleStartDate)
--			and 
--			ee.[Secondary CCP Role] = re2.Role
--	)
----select * from AllCombinedSteps


--,
Months AS
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
	where YearNum < datepart(year,getdate()))

,MonthAndYear as
	(select * 
	from Years 
	full outer join Months on 1=1)
	--select top 10 * from MonthAndYear

,BusinessDaysAndHours as
	(select
		DateName( month , DateAdd( month , MonthNum , -1 )) NameOfMonth
		,Str(YearNum) + '-' + (case when MonthNum < 10 then '0' + ltrim(rtrim(Str(MonthNum))) else ltrim(rtrim(Str(MonthNum))) end) as YearMonthForSorting
		,DateName( month , DateAdd( month , MonthNum , -1 )) + ', ' + ltrim(rtrim(str(YearNum))) as YearMonthToDisplay
		,MonthNum
		,YearNum
		,count(case when sdp.AgencyHoliday = 'Yes' or sdp.IsWeekend = 1 then NULL else sdp.thedate end) BusinessDaysInMonth
		,sum((case when sdp.AgencyHoliday = 'Yes' or sdp.IsWeekend = 1 then 0 else 1 end)*8) BusinessHoursInMonth
	from
		monthandyear
		left join smartdateplus sdp on sdp.themonth = monthandyear.MonthNum and sdp.TheYear = monthandyear.YearNum
	group by
		DateName( month , DateAdd( month , MonthNum , -1 )) 
		,Str(YearNum) + '-' + (case when MonthNum < 10 then '0' + ltrim(rtrim(Str(MonthNum))) else ltrim(rtrim(Str(MonthNum))) end) 
		,DateName( month , DateAdd( month , MonthNum , -1 )) + ', ' + ltrim(rtrim(str(YearNum))) 
		,MonthNum
		,YearNum
	)

select
		datediff(day,cv.rev_timein,cv.transfer_date) DocumentationTimeliness
		,datediff(day,cast(cv.rev_timein as date),cast(cv.transfer_date as date)) DocumentationTimelinessMoreAccurate
		,cv.visittype
		,vt.label
		,cv.client_id
		,cv.units_of_svc
		--,cv.duration
		,cv.emp_name
		
		,l.location_desc
		,r.recipient_desc
		,isnull(ce.admission_date,ce.date_created) [Episode Start Date]
		,datediff(day,isnull(ce.admission_date,ce.date_created),cv.rev_timein) DaysOpenOnDateOfService
		,datediff(day,cast(cv.rev_timein as date),cast(cv.transfer_date as date)) - (select count(distinct p.thedate) from smartdateplus p where (p.AgencyHoliday = 'Yes' or p.IsWeekend = 1) 
				and p.thedate>=cast(cv.rev_timein as date)
				and p.thedate<=cast(cv.transfer_date as date)
				) as BusinessDaysToDoc
	,case when (DATEDIFF(year, c.dob, cv.rev_timein) 
		+ CASE WHEN (DATEADD(year,DATEDIFF(year, c.dob, cv.rev_timein) ,c.dob) > rev_timein) 
		THEN - 1 ELSE 0 END ) < 20 then 'Youth (< 20 Yrs Old)'
	when (DATEDIFF(year, c.dob, cv.rev_timein) 
		+ CASE WHEN (DATEADD(year,DATEDIFF(year, c.dob, cv.rev_timein) ,c.dob) > rev_timein) 
		THEN - 1 ELSE 0 END ) >= 20
		and
		(DATEDIFF(year, c.dob, cv.rev_timein) 
		+ CASE WHEN (DATEADD(year,DATEDIFF(year, c.dob, cv.rev_timein) ,c.dob) > rev_timein) 
		THEN - 1 ELSE 0 END ) < 60 then 'Other (20-59 Years Old)'
	when (DATEDIFF(year, c.dob, cv.rev_timein) 
		+ CASE WHEN (DATEADD(year,DATEDIFF(year, c.dob, cv.rev_timein) ,c.dob) > rev_timein) 
		THEN - 1 ELSE 0 END ) >= 60 then 'Geriatric (60+ Years Old)'
	end as AgeGroup
	,cv.rev_timein
	,cv.emp_id
	,cv.clientvisit_id
	,cv.comb_duration 
	,case when cv.visittype like '%group%' then cast (15 as smallint) else et.EmployeeTime end as [EmployeeTime]
	,cv.duration
	,cv.comb_units [Merged Units]
	,case when et.EmployeeTime is null and cv.duration = cv.comb_duration then cv.duration
		when et.EmployeeTime = cv.comb_duration and et.EmployeeTime =  cv.duration then  et.EmployeeTime
		when  cv.duration <> cv.comb_duration  and cv.duration =et.EmployeeTime  then cv.comb_duration
		when cv.duration =  cv.comb_duration and  cv.comb_duration <> et.EmployeeTime then et.EmployeeTime
		when cv.duration <>  et.EmployeeTime and  cv.duration <> cv.comb_duration and et.EmployeeTime <> cv.comb_duration then  et.EmployeeTime end as [Merged Hours]
	,cv.non_billable
	,case when cv.non_billable= 0 then 'Billable'
		when cv.non_billable= 1 then 'Non-Billable' end as [Service Non-Billable?]
		
	,cv.status [Service Status]
	--,my.*
	,'https://www.cbh3.crediblebh.com/client/my_cw_clients.asp?client_id=' + trim(str(c.client_id)) as ClientLink
	,'https://www.cbh3.crediblebh.com/visit/clientvisit_view.asp?clientvisit_id=' + trim(str(cv.clientvisit_id)) + '&provportal=0' ClientVisitLink
	,DateName( month , DateAdd( month , myr.MonthNum , -1 )) NameOfMonth
	,Str(myr.YearNum) + '-' + (case when myr.MonthNum < 10 then '0' + ltrim(rtrim(Str(myr.MonthNum))) else ltrim(rtrim(Str(myr.MonthNum))) end) as YearMonthForSorting
	,DateName( month , DateAdd( month , myr.MonthNum , -1 )) + ', ' + ltrim(rtrim(str(myr.YearNum))) as YearMonthToDisplay
	,cast(str(myr.yearnum) + '-' + str(myr.monthnum) + '-01' as date) [First Day of the Month]
	,dateadd(day,-1,(dateadd(month,1,cast(str(myr.yearnum) + '-' + str(myr.monthnum) + '-01' as date)))) [Last Day of the Month]

into _mdd_CCSOR_ProdServices


from
	monthandyear myr
	left join clientvisit cv oN YEAR(cv.rev_timein) = myr.yearnum
       AND MONTH(cv.rev_timein) = myr.monthnum
	inner join clients c on cv.client_id = c.client_id
	inner join visittype vt on cv.visittype_id = vt.visittype_id
	left join location l on cv.location_id = l.location_id
	left join clientepisode ce on cv.episode_id = ce.episode_id 
	left join RecipientType r on cv.recipient_id = r.recipient_id
	left join BusinessDaysAndHours my on my.MonthNum = datepart(month,cv.rev_timein) and my.YearNum = datepart(year,cv.rev_timein)
	left join _mdd_Janet_SmartClientVisitEmpTime et on cv.clientvisit_id = et.clientvisit_id
	--left join _MDD_CCSOR_FteEpisodes empeps on empeps.EmpID= cv.emp_id
	--left join AllCombinedSteps epr on epr.EmpID= cv.emp_id
	--left join employees e on cv.emp_id =e.emp_id
where 
	splitprimary_clientvisit_id is null	
	and cv.rev_timein >= '2022-01-01'
	--select * from _MDD_CCSOR_FteEpisodes empeps
;

IF OBJECT_ID (N'dbo._mdd_CCSOR_Productivity') IS NOT NULL
DROP TABLE dbo._mdd_CCSOR_Productivity


select cv.*
	,empeps.ExpectationPercentForMonth
	,empeps.HoursExpectedInMonth
	,empeps.PercentOfYear
	,empeps.[Primary CCP Role]
	,empeps.[Primary Role FTE]
	,empeps.[Secondary CCP Role]
	,empeps.[Secondary Role FTE]

into _mdd_CCSOR_Productivity

from _MDD_CCSOR_FteEpisodes empeps


left join _mdd_CCSOR_ProdServices cv on empeps.EmpID= cv.emp_id and cv.YearMonthForSorting= empeps.YearMonthForSorting
where --cv.visittype like '%Group%'
EmpID is not null
order by cv.rev_timein  desc

--select * from _mdd_CCSOR_Productivity where visittype <> 'CANCEL/NO SHOW' order by emp_id, rev_timein desc