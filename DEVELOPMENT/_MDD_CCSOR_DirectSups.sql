
--Alter PROCEDURE [dbo].[_CCSOR_Productivity]

--AS
--BEGIN
	
	SET NOCOUNT ON;


IF OBJECT_ID (N'dbo._MDD_CCSOR_DirectSups') IS NOT NULL
DROP TABLE dbo._MDD_CCSOR_DirectSups

  select 
	es.emp_id
	,e.first_name + ' ' + e.last_name [Supervisor]
  into _MDD_CCSOR_DirectSups
  from EmployeeSupervisor es
  inner join employees e on  es.supervisor_emp_id= e.emp_id
  where es.is_indirect= 0

  --End