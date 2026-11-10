
-- Clean and standardize NYC DOB NOW Job Filings data
-- One row per job filing number

WITH source AS (

    SELECT *
    FROM {{ source('raw', 'source_nyc_dob_job_apps') }}

),

cleaned AS (

    SELECT
        -- Keep other original columns
        * EXCEPT (
            job_filing_number,
            filing_status,
            borough,
            house_no,
            street_name
        ),

        -- Identifiers
        TRIM(CAST(job_filing_number AS STRING))
            AS job_filing_id,

        -- Standardize filing status
        UPPER(TRIM(CAST(filing_status AS STRING)))
            AS filing_status,

        -- Standardize borough names to match 311
        CASE
            WHEN UPPER(TRIM(borough)) IN
                ('MANHATTAN', 'NEW YORK')
                THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN
                ('BRONX', 'THE BRONX')
                THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) = 'BROOKLYN'
                THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) = 'QUEENS'
                THEN 'Queens'
            WHEN UPPER(TRIM(borough)) = 'STATEN ISLAND'
                THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,

        -- Standardize address fields
        TRIM(CAST(house_no AS STRING))
            AS house_number,

        TRIM(CAST(street_name AS STRING))
            AS street_name,

        -- Record when staging transformation runs
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Remove records without a filing number
    WHERE job_filing_number IS NOT NULL
      AND TRIM(CAST(job_filing_number AS STRING)) != ''

    -- Keep one record per job filing number
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY job_filing_number
        ORDER BY filing_status DESC
    ) = 1

)

SELECT *
FROM cleaned
