--select * from VisitType where visittype like '%asses%'  ---visittype_id in  (119, 413) = no show/cancel 

;with 
NoShowFormReasons as
(select cv.client_id, cv.clientvisit_id,  a.answer [Reason for Missing Appt], cv.visittype, cv.plan_id
						from 
						clientvisit cv
						left join savedvisitanswer sva on sva.clientvisit_id= cv.clientvisit_id
						left join question q on q.question_id= sva.question_id
						left join Answer a on a.answer_id= sva.answer_id
						where 
						q.question_text like '%Reason for missing scheduled appointment: %'
						--and cv.visittype_id in (119, 413)
)



,AsmtApts as
(select 
	p.plan_id
	,p.plan_time
	,p.plan_date
	,DATEADD(SECOND, DATEDIFF(SECOND, '1900-01-01', plan_time), CAST(plan_date AS DATETIME)) AS combined_datetime
	,p.visit_status
	,p.client_id
	,p.emp_id
	,vt.visittype
	,vt.visittype_id
	,ns.[Reason for Missing Appt]
	,ns.clientvisit_id
from Planner p 
inner join visittype vt on vt.visittype_id= p.visittype_id
left join NoShowFormReasons ns on ns.plan_id= p.plan_id
where vt.visittype like '%asses%'
and p.plan_date <= GETDATE()
)

,NextASMT as 
(
select * from
(
select a1.plan_id
	,a1.client_id
	,a1.combined_datetime
	,a1.visit_status
	,a1.emp_id
	,a1.visittype
	,a1.[Reason for Missing Appt]
	,a1.clientvisit_id
	,a2.combined_datetime [NextCombined_datetime]
	,a2.visit_status [NextVisit_status]
	,a2.clientvisit_id [NextSvc_id]
	,a2.[Reason for Missing Appt] [NextReasonforMissing]
	,row_number() over (partition by a1.plan_id order by a2.combined_datetime asc) RowNum
from AsmtApts a1
left join AsmtApts a2 on a1.client_id= a2.client_id
where a2.combined_datetime> a1.combined_datetime
)
x where x.RowNum= 1
)

,allAsmtApts as
(
Select aa.*
	,na.NextCombined_datetime
	,na.NextVisit_status
	,na.NextReasonforMissing
	,na.NextSvc_id
from AsmtApts aa
left join NextASMT na on na.plan_id= aa.plan_id
)





select aa.*
	, case when visit_status IN ('NOSHOW', 'CANCELLED', 'CNCLD>24hr') AND NextVisit_status IN ('NOSHOW', 'CANCELLED', 'CNCLD>24hr') THEN '2 assessment no shows/cancels in a row'
		end as [B2B Assessment Missed Appts]
	,case when (visit_status IN ('NOSHOW', 'CANCELLED', 'CNCLD>24hr')  and aa.[Reason for Missing Appt] like '%ill%' )
			AND (NextVisit_status IN ('NOSHOW', 'CANCELLED', 'CNCLD>24hr') and  aa.NextReasonforMissing like '%ill%') 
			then 'Same Illenss?'
		when (visit_status IN ('NOSHOW', 'CANCELLED', 'CNCLD>24hr')  and aa.[Reason for Missing Appt] not like '%ill%' )
			AND (NextVisit_status IN ('NOSHOW', 'CANCELLED', 'CNCLD>24hr') and  aa.NextReasonforMissing not like '%ill%') 
			then '2 Missing Asmt'
		end as [Illness Reason]
	
from allAsmtApts aa
--left join NoShowFormReasons ns on ns.plan_id= aa.plan_id

order by client_id, combined_datetime 


--considerations: what if months between 2 missing appts? what if visitttype changes to no show due to entry/documentation method? What if no reason enterred? 

--ct ID example fo illeness reason: 28589









--Are we looking to say of all the planner asmst visittypes there were two that were missed 
--OR are we trying to find if two planner appts were missed and one of them was an asmt? 

--SELECT DISTINCT VISIT_STATUS FROM Planner