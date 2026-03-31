/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~~~~-~~~-~~~-~~-. 
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~  !              JCT           ! ~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
IF OBJECT_ID('_MDD_JCT_AGENCY_SPECIFICS') IS NOT NULL
DROP TABLE _MDD_JCT_AGENCY_SPECIFICS;
IF OBJECT_ID('_MDD_JCT_METADATA') IS NOT NULL
DROP TABLE _MDD_JCT_METADATA
IF OBJECT_ID('_MDD_JCT_REPORT_DESIGN') IS NOT NULL
DROP TABLE _MDD_JCT_REPORT_DESIGN;
GO


/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
REPORT DESIGN
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */

-- Bold colors, used as primary colors for visualizations
DECLARE @hex_visual_color_pop_1 VARCHAR(7) = '#FF9F00'
DECLARE @hex_visual_color_pop_2 VARCHAR(7) = '#08284D'

-- Muted / Subdued colors for visualizations
DECLARE @hex_visual_color_muted_1 VARCHAR(7) = '#99D0EF'
DECLARE @hex_visual_color_muted_2 VARCHAR(7) = '#FFDE68'

-- Page Background
DECLARE @hex_dashboard_background VARCHAR(7) = '#E9F7FF'


/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
FISCAL YEAR
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */
-- Indicate the start month (int) and end month (int) of the agency's fiscal year.
DECLARE @fiscal_year_start_month INT = 7
DECLARE @fiscal_year_end_month INT = 6


/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
OVERRIDE DOMAIN
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */
-- Domain override future-proofs JCT_SHARE_DATA, which prefixes tables moved in from
-- accompanying databases. This is rarely used. If it's not empty, ask yourself hard 
-- questions.
DECLARE @domain_override VARCHAR(32) = ''

/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
BUSINESS HOURS
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */
-- Set the start and end hours of operation, in 24 hour format.
-- This impacts "Time Is Business Hours" and "Time Is Business Hours (Weekends)"
-- in _MDD_JCT_DATES_MINUTES.
-- Float between 0 (12:00 AM) and 23 (11:00PM). Set to partial numbers for mid-hour.
-- IE: 8:30AM is 8.5
DECLARE @business_hours_start FLOAT = 9.0
DECLARE @business_hours_end FLOAT = 17.0

/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
SHARE DATA EXCLUSIONS
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */
-- Write SQL that creates a list of database and tables not to bring into into your default 
-- database. The default SQL should rarely need to be modified.
-- If you need to modify this, be certain to specify a database in the FROM, as this script
-- will run against your against database, the target not source of Share Data.
IF OBJECT_ID('_MDD_JCT_SHARE_DATA_EXCLUSIONS') IS NOT NULL
DROP TABLE _MDD_JCT_SHARE_DATA_EXCLUSIONS;
SELECT DISTINCT
  [TABLE_CATALOG] [Database Name]
  ,[TABLE_NAME] [Table Name]
INTO _MDD_JCT_SHARE_DATA_EXCLUSIONS
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 1 = 0

/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
MULTI-TENANT DATA SHARING
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */
-- Set this to 1 if, when sharing data, rather than prefix all tables with the names of
-- their databases into the primary domin/database, the Share Data module will aggregate
-- or unionize tables by the same name. 
--
-- This is particularly intended for **RARE** circumstances when MSSQL is expected to
-- have multiple databases populated by the same data source but for multiple agencies
-- or tenants within that data source. 
--
-- In this scenario, we expect different databases with the same set of tables and fields
-- and field types. Identically-named tables across database are UNION'ized into single 
-- tables in the primary database, rather than duplicated and prefixed with their own 
-- unique names.
--
-- Setting this value to 1 is rare.
DECLARE @multi_tenant INT = 0

/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
MAX LOG SIZE
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */
-- Some databases my need this figure to be adjusted to ensure that the MSSQL server
-- transaction log does not fill mid-transaction. Log files are stored on a space-limited
-- drive on JC VMs. Be careful altering this.
--
-- This is the value in MB.
DECLARE @max_log_size_mb INT = 40960

/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
  ~~~~~~~~~~~~~~~~~  ! NO CUSTOMIZATION REQUIRED BEYOND THIS LINE ! ~~~~~~~~~~~~~~~~~
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */


/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
REPORT DESIGN
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */
CREATE TABLE _MDD_JCT_REPORT_DESIGN (
    -- Bold colors, used as primary colors for visualizations
    hex_visual_color_pop_1 VARCHAR(7)
    ,hex_visual_color_pop_2 VARCHAR(7)
    -- Muted / Subdued colors for visualizations
    ,hex_visual_color_muted_1 VARCHAR(7)
    ,hex_visual_color_muted_2 VARCHAR(7)
    -- Page Background
    ,hex_dashboard_background VARCHAR(7)
);
INSERT INTO _MDD_JCT_REPORT_DESIGN VALUES (

    -- Bold colors, used as primary colors for visualizations
    @hex_visual_color_pop_1
    ,@hex_visual_color_pop_2
    ,@hex_visual_color_muted_1
    ,@hex_visual_color_muted_2
    ,@hex_dashboard_background
)

/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
SET DATA PARAMETERS
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */
CREATE TABLE _MDD_JCT_AGENCY_SPECIFICS (
    domain_override VARCHAR(32)
    ,fiscal_year_start_month INT
    ,fiscal_year_end_month INT
    ,business_hours_start FLOAT
    ,business_hours_end FLOAT
);
INSERT INTO _MDD_JCT_AGENCY_SPECIFICS VALUES (
    @domain_override
    ,@fiscal_year_start_month
    ,@fiscal_year_end_month
    ,@business_hours_start
    ,@business_hours_end
)

/*.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. 
SET METADATA
.--~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~~-~~-. */
-- Create the table
CREATE TABLE _MDD_JCT_METADATA (
    [Parameter] NVARCHAR(128),
    [Value Text] NVARCHAR(128),
    [Value Datetime] DATETIME,
    [Value Integer] INT,
)

--Insert Metadata
INSERT INTO _MDD_JCT_METADATA ([Parameter], [Value Integer])
VALUES ('@multi_tenant', @multi_tenant)
