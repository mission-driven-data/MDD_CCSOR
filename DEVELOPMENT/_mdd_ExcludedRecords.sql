SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create PROCEDURE [dbo].[_mdd_CCSOR_SmartExcludedRecords]

AS
BEGIN

SET NOCOUNT ON;

IF OBJECT_ID (N'dbo._mdd_SmartExcludedRecords') IS NOT NULL
DROP TABLE dbo._mdd_SmartExcludedRecords

select c.client_id as RecordId, 'Client' as RecordType
into _mdd_SmartExcludedRecords
from clients c
where last_name like 'Test%' or first_name like 'Test%' or c.deleted = 1

union all

select e.emp_id as RecordId, 'Employee' as RecordType
from employees e
where  email like '%credibleinc.com%' or email like '%Qualifact%' or last_name like '%Test%' or first_name like '%Test%'

--select * from clients where last_name like 'Test%' or first_name like 'Test%'
--select * from employees where last_name like '%Test%' or first_name like '%Test%'

END