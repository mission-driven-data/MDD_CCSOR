SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


Create PROCEDURE [dbo].[sp_mdd_SmartAgingClient]


AS
BEGIN
	
	SET NOCOUNT ON;



IF OBJECT_ID (N'dbo._mdd_SmartAgingClient') IS NOT NULL
DROP TABLE dbo._mdd_SmartAgingClient



;with
	BillingNotes as
		(select
			*
		from
			(select 
				sl.action_date [Last Note Date]
				,sl.description [Last Note]
				,e.last_name + ', ' + e.first_name [Last Note Author]
				,row_number() over (partition by sl.clientvisit_id order by sl.action_date desc) RowNum
				,sl.clientvisit_id
			from
				Z_ServiceLedger sl
				left join employees e on sl.emp_id = e.emp_id
			where sl.action_type = 'NOTES'
			) AllNotes
		where
			allnotes.RowNum = 1
		)
select distinct
	cvb.*
	,cv.rev_timein [Service Date]
	,p.program_desc [Service Program]
	,pa.payer_description [Current Payer]
	,'https://www.cbh3.crediblebh.com/client/my_cw_clients.asp?client_id=' + rtrim(ltrim(cast(cvb.client_id as varchar))) as ClientLink	
	,'https://www.cbh3.crediblebh.com/billing/claim_history.asp?clientvisit_id=' + rtrim(ltrim(str(cvb.clientvisit_id))) as ClientVisitLink
	,case when datediff(day,cv.rev_timein,getdate()) < 31 then '0-30'
		 when datediff(day,cv.rev_timein,getdate()) < 61 and datediff(day,cv.rev_timein,getdate()) >= 31 then '31-60'
		 when datediff(day,cv.rev_timein,getdate()) < 91 and datediff(day,cv.rev_timein,getdate()) >= 61 then '61-90'
		 when datediff(day,cv.rev_timein,getdate()) < 121 and datediff(day,cv.rev_timein,getdate()) >= 91 then '91-120'
		 when datediff(day,cv.rev_timein,getdate()) < 181 and datediff(day,cv.rev_timein,getdate()) >= 121 then '121-180'
		 when  datediff(day,cv.rev_timein,getdate()) >= 181 then '181+'
		 end as [Aging Bucket Service Date]
	,case when datediff(day,cv.rev_timein,getdate()) < 31 then 1 
		 when datediff(day,cv.rev_timein,getdate()) < 61 and datediff(day,cv.rev_timein,getdate()) >= 31 then 2
		 when datediff(day,cv.rev_timein,getdate()) < 91 and datediff(day,cv.rev_timein,getdate()) >= 61 then 3
		 when datediff(day,cv.rev_timein,getdate()) < 121 and datediff(day,cv.rev_timein,getdate()) >= 91 then 4
		 when datediff(day,cv.rev_timein,getdate()) < 181 and datediff(day,cv.rev_timein,getdate()) >= 121 then 5
		 when  datediff(day,cv.rev_timein,getdate()) >= 181 then 6
		 end as [Aging Bucket for Sorting Service Date]

	,case when datediff(day,cvb.age_date,getdate()) < 31 then '0-30'
		 when datediff(day,cvb.age_date,getdate()) < 61 and datediff(day,cvb.age_date,getdate()) >= 31 then '31-60'
		 when datediff(day,cvb.age_date,getdate()) < 91 and datediff(day,cvb.age_date,getdate()) >= 61 then '61-90'
		 when datediff(day,cvb.age_date,getdate()) < 121 and datediff(day,cvb.age_date,getdate()) >= 91 then '91-120'
		 when datediff(day,cvb.age_date,getdate()) < 181 and datediff(day,cvb.age_date,getdate()) >= 121 then '121-180'
		 when  datediff(day,cvb.age_date,getdate()) >= 181 then '181+'
		 end as [Aging Bucket Age Date]
	,case when datediff(day,cvb.age_date,getdate()) < 31 then 1 
		 when datediff(day,cvb.age_date,getdate()) < 61 and datediff(day,cvb.age_date,getdate()) >= 31 then 2
		 when datediff(day,cvb.age_date,getdate()) < 91 and datediff(day,cvb.age_date,getdate()) >= 61 then 3
		 when datediff(day,cvb.age_date,getdate()) < 121 and datediff(day,cvb.age_date,getdate()) >= 91 then 4
		 when datediff(day,cvb.age_date,getdate()) < 181 and datediff(day,cvb.age_date,getdate()) >= 121 then 5
		 when  datediff(day,cvb.age_date,getdate()) >= 181 then 6
		 end as [Aging Bucket for Sorting Age Date]
--	,c.first_name [Client First Name]
--	,c.last_name [Client Last Name]
--	,c.first_name + ' ' + c.last_name [Client Full Name]
	,c.dob [Client DOB]
	,c.ssn [Client SSN]
	,l.location_desc [Service Location]
	,cv.visittype [Service Type]
	,cv.status [Service Status]
	,rt.recipient_desc [Recipient Type]
	,cv.cptcode
	,ci.ins_id [Current Client Insurance Id]
	,(select string_agg(cl.claim_id, ',') from Z_Claim cl where cvb.clientvisit_id = cl.clientvisit_id and cvb.cur_payer_id = cl.payer_id) [Claim ID]
	,bn.[Last Note]
	,bn.[Last Note Author]
	,bn.[Last Note Date]
	,case when bn.[Last Note Date] is null then 2
		when datediff(day,bn.[Last Note Date],getdate()) > 20 then 1
		when datediff(day,bn.[Last Note Date],getdate()) > 13 then -1
		else 0 end as NoteFlag
into _mdd_SmartAgingClient
from
	ClientVisitBilling cvb 
	left join Z_Claim cl on cvb.clientvisit_id = cl.clientvisit_id and cvb.cur_payer_id = cl.payer_id
	left join clientvisit cv on cvb.clientvisit_id = cv.clientvisit_id
	left join programs p on cv.program_id = p.program_id
	left join Payer pa on cvb.cur_payer_id = pa.payer_id
	left join Clients c on cvb.client_id = c.client_id
	left join location l on cv.location_id = l.location_id
	left join RecipientType rt on cv.recipient_id = rt.recipient_id
	left join clientinsurance ci on ci.clientins_id = cvb.cur_clientins_id
	left join BillingNotes bn on cvb.clientvisit_id = bn.clientvisit_id

where
	 cvb.client_due <> 0

	 end
