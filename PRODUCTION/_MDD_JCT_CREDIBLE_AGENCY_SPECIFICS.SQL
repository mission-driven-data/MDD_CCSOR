/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~~~~-~~~-~~~-~~-. 
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~  !          CREDIBLE            ! ~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
IF OBJECT_ID('_MDD_JCT_CREDIBLE_METADATA') IS NOT NULL
DROP TABLE _MDD_JCT_CREDIBLE_METADATA
GO

/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
YEARS LOOKBACK
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */
-- Years to look back and forward in time for services. This limits the dataset to speed
-- up processing.
DECLARE @years_lookback INT = 3
DECLARE @years_lookforward INT = 1

/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
EXCLUDED RECORDS
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */
IF OBJECT_ID('dbo._MDD_JCT_CREDIBLE_EXCLUDED_RECORDS_CUSTOM') IS NOT NULL
DROP TABLE _MDD_JCT_CREDIBLE_EXCLUDED_RECORDS_CUSTOM;

SELECT 
    'Client' [Record Type]
    ,c.client_id [Record ID]
INTO _MDD_JCT_CREDIBLE_EXCLUDED_RECORDS_CUSTOM
FROM clients c
WHERE 1=0
UNION SELECT
    'User' [Record Type]
    ,e.emp_id [Record ID]
FROM employees e
WHERE e.profile_code = 'MASTER' -- Credible Staff
UNION SELECT
    'Program' [Record Type]
    ,p.program_id [Record ID]
FROM Programs p
WHERE 1=0
UNION SELECT
    'Appointment Type' [Record Type]
    ,vt.visittype_id [Record ID]
FROM VisitType vt
WHERE 1=0
UNION SELECT
    'Location' [Record Type]
    ,l.location_id [Record ID]
FROM [Location] l
WHERE 1=0
UNION SELECT
    'Enrollment' [Record Type]
    ,ce.episode_id [Record ID]
FROM ClientEpisode ce
WHERE 1=0
UNION SELECT
    'Scheduler' [Record Type]
    ,p.plan_id [Record ID]
FROM Planner p
WHERE 1=0


/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
AGE GROUPS
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */
-- Step 1: Create a table to define the age groups
IF OBJECT_ID('_MDD_JCT_CREDIBLE_AGE_GROUPS_CUSTOM') IS NOT NULL
DROP TABLE _MDD_JCT_CREDIBLE_AGE_GROUPS_CUSTOM;
CREATE TABLE _MDD_JCT_CREDIBLE_AGE_GROUPS_CUSTOM (
    Floor INT,
    Ceiling INT,
    GroupName NVARCHAR(50),
    SortOrder INT
);

-- Step 2: Insert age group definitions and sort order into the table
INSERT INTO _MDD_JCT_CREDIBLE_AGE_GROUPS_CUSTOM (Floor, Ceiling, GroupName, SortOrder) VALUES
(0, 14, '0-14', 1),
(15, 24, '15-24', 2),
(25, 34, '25-34', 3),
(35, 44, '35-44', 4),
(45, 54, '45-54', 5),
(55, 64, '55-64', 6),
(65, 74, '65-74', 7),
(75, 84, '75-84', 8),
(85, 94, '85-94', 9),
(95, 104, '95-104', 10)


/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
  ~~~~~~~~~~~~~~~~~  ! NO CUSTOMIZATION REQUIRED BEYOND THIS LINE ! ~~~~~~~~~~~~~~~~~
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */



/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
METADATA
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */
-- Create the table
CREATE TABLE _MDD_JCT_CREDIBLE_METADATA (
    [Parameter] NVARCHAR(128),
    [Value Text] NVARCHAR(128),
    [Value Datetime] DATETIME,
    [Value Integer] INT,
)

-- Insert Metadata
INSERT INTO _MDD_JCT_CREDIBLE_METADATA ([Parameter], [Value Integer])
VALUES ('@years_lookback', @years_lookback)

INSERT INTO _MDD_JCT_CREDIBLE_METADATA ([Parameter], [Value Integer])
VALUES ('@years_lookforward', @years_lookforward)

INSERT INTO _MDD_JCT_CREDIBLE_METADATA ([Parameter], [Value Text])
VALUES ('@domain', 
    (
        SELECT paramvalue FROM PartnerConfig WHERE parameter = 'partnerdomain'
    )
)

INSERT INTO _MDD_JCT_CREDIBLE_METADATA ([Parameter], [Value Datetime])
VALUES ('@current_date', GETDATE())

