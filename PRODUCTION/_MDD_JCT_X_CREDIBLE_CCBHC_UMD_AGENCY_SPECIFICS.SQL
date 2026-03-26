/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~~~~-~~~-~~~-~~-. 
  ~~~~~~~~~~~~~~~~~  ! CREDIBLE CCBHC UMD AGENCY SPECIFICS ! ~~~~~~~~~~~~~~~~~
    ___   _____________   __________  __   _____ ____  _____________________________________
   /   | / ____/ ____/ | / / ____/\ \/ /  / ___// __ \/ ____/ ____/  _/ ____/  _/ ____/ ___/
  / /| |/ / __/ __/ /  |/ / /      \  /   \__ \/ /_/ / __/ / /    / // /_   / // /    \__ \ 
 / ___ / /_/ / /___/ /|  / /___    / /   ___/ / ____/ /___/ /____/ // __/ _/ // /___ ___/ / 
/_/  |_\____/_____/_/ |_/\____/   /_/   /____/_/   /_____/\____/___/_/   /___/\____//____/ 
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */
/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
PREPWORK: REQUIRED / DO NOT REMOVE
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */
-- Must exist at the stop of the script within its own batch. Otherwise changes to the
-- table structure trigger a MSSQL error when it evaluates the INSERT statements below.
-- We cannot push it to its own batch immediately prior to the INSERT statements 
-- because variable scopes do not extend outside of batches because whoever invented
-- TSQL needed to feel superior to us I guess and inventing rules that don't make sense
-- and are hard to follow are the best way to ensure you're always the expert.
IF OBJECT_ID('_MDD_JCT_X_CREDIBLE_CCBHC_UMD_METADATA') IS NOT NULL
DROP TABLE _MDD_JCT_X_CREDIBLE_CCBHC_UMD_METADATA
GO


/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
AGENCY CONTEXT
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */
IF OBJECT_ID('_MDD_JCT_X_CREDIBLE_CCBHC_UMD_AGENCY_CONTEXT_CUSTOM') IS NOT NULL
DROP TABLE _MDD_JCT_X_CREDIBLE_CCBHC_UMD_AGENCY_CONTEXT_CUSTOM
-- This table can contain as many fields as you wish, but it is only expected to have one
-- row. All fields will be used to create the table called 
-- _MDD_JCT_X_CREDIBLE_CCBHC_UMD_AGENCY_CONTEXT.
--
-- Avoid using the field [Agency ID Hash] which will be a hash value to anonymously 
-- identify the domain.
SELECT
	'Enter anything you wish to report here' [Agency Notes]
INTO _MDD_JCT_X_CREDIBLE_CCBHC_UMD_AGENCY_CONTEXT_CUSTOM

/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
COLLABORATION FIELD OVERRIDES
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */
-- PURPOSE
-- This table is the agency-managed customization layer for collaboration-defined fields
-- in the CCBHC UMD extract.
--
-- HOW TO USE
-- 1) Remove "AND 1 = 0" when collaboration rules are ready.
-- 2) Keep [Service_ID] mapped to _MDD_JCT_CREDIBLE_APPOINTMENTS.[Appointment ID]
--    for rows where [Appointment Tense ID] = 1.
-- 3) Populate only the collaboration-defined outputs below:
--    [Insurance_Type]
--    [Self_Pay]
--    [Service_Format]
--    [Service_Is_Crisis]
--    [Service_Crisis_Type]
--    [Service_Is_MOUD]
--    [Service_Is_Peer_Support]
--    [Service_Is_Care_Coordination]
--    [Service_Is_Integrated_or_Physical_Health]
--    [Service_Is_Outreach]
--    [Client_Responsible_County]
--    [Employee_Type]
--
-- RULES
-- - Keep table and column names exactly as defined.
-- - Keep the prepwork block at the top unchanged.
-- - Keep this table empty if collaboration logic is not implemented yet.
IF OBJECT_ID (N'_MDD_JCT_X_CREDIBLE_CCBHC_UMD_COLLABORATION_CUSTOM') IS NOT NULL
DROP TABLE _MDD_JCT_X_CREDIBLE_CCBHC_UMD_COLLABORATION_CUSTOM
SELECT
	cv.[Appointment ID] [Service_ID]
	,CAST(NULL AS VARCHAR(MAX)) [Insurance_Type]
	,CAST(NULL AS VARCHAR(10)) [Self_Pay]
	,CAST(NULL AS VARCHAR(MAX)) [Service_Format]
	,CAST(NULL AS VARCHAR(10)) [Service_Is_Crisis]
	,CAST(NULL AS VARCHAR(MAX)) [Service_Crisis_Type]
	,CAST(NULL AS VARCHAR(10)) [Service_Is_MOUD]
	,CAST(NULL AS VARCHAR(10)) [Service_Is_Peer_Support]
	,CAST(NULL AS VARCHAR(10)) [Service_Is_Care_Coordination]
	,CAST(NULL AS VARCHAR(10)) [Service_Is_Integrated_or_Physical_Health]
	,CAST(NULL AS VARCHAR(10)) [Service_Is_Outreach]
	,CAST(NULL AS VARCHAR(MAX)) [Client_Responsible_County]
	,CAST(NULL AS VARCHAR(MAX)) [Employee_Type]
INTO _MDD_JCT_X_CREDIBLE_CCBHC_UMD_COLLABORATION_CUSTOM
FROM _MDD_JCT_CREDIBLE_APPOINTMENTS cv
WHERE cv.[Appointment Tense ID] = 1
AND cv.[Appointment Start Date] >= DATEFROMPARTS(2019,1,1)
AND 1 = 0

/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
  ~~~~~~~~~~~~~~~~~  ! NO CUSTOMIZATION REQUIRED BEYOND THIS LINE ! ~~~~~~~~~~~~~~~~~
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */

/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
METADATA
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */
IF OBJECT_ID('_MDD_JCT_X_CREDIBLE_CCBHC_UMD_METADATA') IS NOT NULL
DROP TABLE _MDD_JCT_X_CREDIBLE_CCBHC_UMD_METADATA

CREATE TABLE _MDD_JCT_X_CREDIBLE_CCBHC_UMD_METADATA (
	[Parameter] NVARCHAR(128),
	[Value Text] NVARCHAR(MAX),
	[Value Datetime] DATETIME,
	[Value Integer] INT
)

