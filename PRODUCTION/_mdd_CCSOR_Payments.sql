



--Alter PROCEDURE [dbo].[_CCSOR_Productivity]

--AS
--BEGIN
	
	SET NOCOUNT ON;





SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



Create PROCEDURE [dbo].[sp_mdd_CCSOR_Payments]

AS
BEGIN

SET NOCOUNT ON;

IF OBJECT_ID (N'dbo._mdd_CCSOR_Payments') IS NOT NULL
DROP TABLE dbo._mdd_CCSOR_Payments


;with InsPayment as 
(
select 
	l.action_date
	,l.action_type
	,l.clientvisit_id
	,l.client_id
	,amount
	,l.claim_id
	,l.payment_id
	,l.batch_id
	,l.payer_id
	,p.payer_name
	,l.revenue_code
	,l.serviceledger_id
	--,l.*
	
from Z_ServiceLedger l
left join Payer p on p.payer_id = l.payer_id
where l.action_type in ('INS PAYMENT ADD', 'INS PAYMENT', 'UNDO INS PAYMENT') 
and (is_reversal<>1 and  is_reversed<>1 ) --- removes any payments that were undone
--and clientvisit_id = 1074690
--order by l.clientvisit_id, l.action_date desc
)

,CtPayments as 
( 
select 
	l.action_date
	,l.action_type
	,l.clientvisit_id
	,l.client_id
	,amount
	,l.claim_id
	,l.payment_id
	,l.batch_id
	,l.payer_id
	,p.payer_name
	,l.revenue_code
	,l.serviceledger_id
	--,l.*
from Z_ServiceLedger l
left join Payer p on p.payer_id = l.payer_id

where l.action_type in ('CLIENT PAYMENT ADD', 'CLIENT PAYMENT','UNDO CLIENT PAYMENT') 
and (is_reversal<>1 and  is_reversed<>1 ) --- removes any payments that were undone
--and (clientvisit_id = 1074690 or client_id = 6973)
--order by l.clientvisit_id , l.action_date desc
)

,payments as 
(
select * 
from InsPayment ip 
union 
select * 
from CtPayments cp

--order by client_id, clientvisit_id
)
, CtVisits as 
(Select cv.clientvisit_id
,cv.cptcode
--,cpt_modifier1
--,cpt_modifier2
--,cpt_modifier3
--,cpt_modifier4
, STRING_AGG (cv.cpt_modifier1 + ', '+ cv.cpt_modifier2 + ', ' + cv.cpt_modifier3 + ', ' + cv.cpt_modifier4 , '; ') --as [Modifiers]
 within group (order by cv.cptcode) as Modifiers
 ,p.program_desc
 ,cv.visittype [Service Type]
 ,cv.emp_name
 ,L.location_desc
 ,cv.rev_timein
 ,cv.rev_timeout
 ,cvb.ins_due [Current Insurance Total Due]
 ,cvb.ins_paid_amount	[Current Insurance Total Paid]
 ,cvb.balance [Current Balane Due]
 ,cvb.service_amount
 ,cv.rate
 ,cv.contract_rate
from ClientVisit cv
left join Programs p on p.program_id= cv.program_id 
left join Location L ON L.location_id= cv.location_id
left join ClientVisitBilling cvb on cvb.clientvisit_id= cv.clientvisit_id
--where clientvisit_id = 445265
group by cv.clientvisit_id, cptcode,p.program_desc,cv.visittype ,cv.emp_name,L.location_desc ,cv.rev_timein
 ,cv.rev_timeout ,cvb.ins_due
 ,cvb.ins_paid_amount
 ,cvb.balance
 ,cvb.service_amount,cv.rate
 ,cv.contract_rate
--,cpt_modifier1
--,cpt_modifier2
--,cpt_modifier3
--,cpt_modifier4
) 



Select --distinct
case when pay.client_id is not null then pay.client_id else l.client_id end as [Client Id]
,Clients.first_name + ' ' + Clients.last_name [Client Name]
,cv.[Service Type]
,cv.cptcode
,cv.[Modifiers]
,cv.program_desc [Program of Service]
,cv.emp_name [Employee of Service]
,cv.location_desc [Location of Service]
,cv.contract_rate
,cv.rate
,cv.rev_timein
,cv.rev_timeout
,cv.[Current Balane Due]
,cv.[Current Insurance Total Due]
,cv.[Current Insurance Total Paid]
--,l.serviceledger_id
--,l.action_type
, pay.date_entered [Choose Date Entered]
,pay.check_date
,pay.date_closed
,pay.deposit_date
,pay.date_updated
,pay.amount [Payment Amount]
,pay.payment_type [Payment Type]
,pay.check_num [Check Number]
,pay.payment_location [Payment Location]
,pay.payment_id  [Payment Id]
,pay.notes
,pay.deposit_date [Deposit Date]


,pts.clientvisit_id [Associated Client Visit]
--,ctp.*
--,insp.* 
--,pts.*
,pts.action_date
,pts.action_type
,pts.amount
,pts.batch_id
,pts.claim_id
,pts.payer_id
,pts.payer_name
--,pts.clientvisit_id
,pts.payment_id
,pts.revenue_code


--,    E.last_name As Employee_Last_Name
--,    E.first_name As Employee_First_Name
, e.first_name + ' ' + e.last_name [Choose Employee(s)]
,'https://www.cbh3.crediblebh.com/visit/clientvisit_view.asp?clientvisit_id=' + trim(str(l.clientvisit_id)) + '&provportal=0' ClientVisitLink
,'https://www.cbh3.crediblebh.com/client/my_cw_clients.asp?client_id=' + trim(str(clients.client_id)) as ClientLink
--,clients.county as [Resident County]
,case when claim.billing_order = 'P' then 'Primary'
	when claim.billing_order = 'S' then 'Secondary'
	when claim.billing_order = 'T' then 'Tertiary'
	else claim.billing_order
	end as [Billing Order]
--,claim.*
,claim.allowed_amount
,claim.batch_override_rendering
,claim.charges
,claim.client_due
,claim.clientins_id
,claim.copay
,claim.date_batched
,claim.date_reconciled
,claim.disallowed_amount
,claim.eob_date
,claim.external_claim_id
,claim.status
,claim.service_closed
,claim.return_codes
,claim.retracted_amount
,claim.resubmission_type
,claim.payer_desc
,claim.ins_paid_amount
,claim.paid_status_saved



into _mdd_CCSOR_Payments


From Z_ServiceLedger l
inner join payments pts on pts.serviceledger_id= l.serviceledger_id
--left join CtPayments ctp on ctp.serviceledger_id= l.serviceledger_id
--LEFT join InsPayment insp on insp.serviceledger_id= l.serviceledger_id
left join Z_Payment pay On pay.payment_id = l.payment_id
left join Clients On Clients.client_id = l.client_id    
Inner Join Employees e On E.emp_id = pay.emp_id  
left join Z_Claim claim on claim.claim_id= pts.claim_id
left join CtVisits cv on cv.clientvisit_id = pts.clientvisit_id
--where l.clientvisit_id = 445265
order by case when pay.client_id is not null then pay.client_id else l.client_id end 
,pts.clientvisit_id


end


--24359 payment lines with no clientvisit_id

---------------------------------------------------------------------------------------------
--select * from Z_Claim cl --where clientvisit_id = 1074690-- 1069245
--left join Z_ClaimAdj  cla on cla.claim_id= cl.claim_id

--where cl.claim_id in (421694, 426176, 432623)
--order by client_id,clientvisit_id desc 



--select * from _mdd_CCSOR_Payments where [Associated Client Visit]=1069245











-------------

--select * from Z_ClaimAdj  cl
--left join Z_AdjustmentCode ac on ac.
--where cl.claim_id in (421694, 426176, 432623)

--select * from Z_AdjustmentCode
-- * from Z_AdjustmentType
--select * from adju
---recommend union ctp and insp , left join adjustments but more likley just drill through to new table for adjustments

