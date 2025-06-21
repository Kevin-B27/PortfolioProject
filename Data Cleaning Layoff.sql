-- STEP 1: Inspect the original data
SELECT * 
FROM layoffs;

-- STEP 2: Create a staging table to work on cleaning without altering the original dataset
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Verify the empty staging table
SELECT * 
FROM layoffs_staging;

-- Copy data from the original table to the staging table
INSERT INTO layoffs_staging
SELECT * 
FROM layoffs;

-- Identify potential duplicates by assigning row numbers based on key fields
SELECT *,
ROW_NUMBER() OVER(
  PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`
) AS row_num
FROM layoffs_staging;

-- Create a CTE to flag exact duplicates (adding more fields for higher accuracy)
WITH duplicate_cte AS (
  SELECT *,
  ROW_NUMBER() OVER(
    PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
  ) AS row_num
  FROM layoffs_staging
)
-- Check rows considered duplicates (row_num > 1)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;

-- Quick inspection of a specific company to validate duplication
SELECT *
FROM layoffs
WHERE company = 'Casper';

-- Attempt to delete duplicates directly (Note: This won't work in MySQL without using a real table)
-- Kept here for reference
WITH duplicate_cte AS (
  SELECT *,
  ROW_NUMBER() OVER(
    PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
  ) AS row_num
  FROM layoffs_staging
)
DELETE
FROM duplicate_cte
WHERE row_num > 1;

-- Workaround: Create a second staging table to handle deletions
CREATE TABLE layoffs_staging2 (
  company TEXT,
  location TEXT,
  industry TEXT,
  total_laid_off INT DEFAULT NULL,
  percentage_laid_off TEXT,
  `date` TEXT,
  stage TEXT,
  country TEXT,
  funds_raised_millions INT DEFAULT NULL,
  row_num INT
);

-- Verify the structure
SELECT * FROM layoffs_staging2 WHERE row_num > 1;

-- Insert data with row numbers into the second staging table
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
  PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
) AS row_num
FROM layoffs_staging;

-- Delete duplicate rows based on row_num
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- Final data check
SELECT * FROM layoffs_staging2;

-- STEP 3: Standardize data formats (trim spaces, unify naming)
-- Remove leading/trailing spaces from company names
SELECT DISTINCT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Standardize industry names
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Standardize country names
SELECT country
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%';

-- Remove trailing dots from country names
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Convert date from text to proper DATE format
SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Alter column type to DATE
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- STEP 4: Handle NULLs and blank values

-- Find records with NULL values in key columns
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Convert blank industry fields to NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Identify companies missing industry info
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
   OR industry = '';

-- Validate against company with known industry values
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- Attempt to fill NULL industry values using non-null data for the same company and location
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
  AND t2.industry IS NOT NULL;

-- Perform the update using self-join
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
  AND t2.industry IS NOT NULL;

-- Delete rows with missing layoff data
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Confirm deletion
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- STEP 5: Final cleanup - remove helper columns
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


