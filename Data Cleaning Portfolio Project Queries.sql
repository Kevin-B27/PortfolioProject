/*
Cleaning Data in SQL Queries

*/
SELECT * 
FROM PortfolioProjecT..Nashville_Housing
----------------------------------------------------------------------------------------------------
-- Standarize Date Format

ALTER TABLE Nashville_Housing
ALTER COLUMN SaleDate DATE

 --SELECT SaleDate, CONVERT(DATE, SaleDate)
--FROM PortfolioProjecT..Nashville_Housing

----------------------------------------------------------------------------------------------------------------
-- Populate Property Address data

SELECT *
FROM PortfolioProjecT..Nashville_Housing
-- WHERE PropertyAddress IS NULL
ORDER BY ParcelID


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Nashville_Housing a
JOIN Nashville_Housing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Nashville_Housing a
JOIN Nashville_Housing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


--------------------------------------------------------
-- Breaking out Address into individual Columns(Adress, city, State)

SELECT PropertyAddress
FROM Nashville_Housing;

SELECT 
SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM Nashville_Housing

ALTER TABLE Nashville_Housing
ADD PropertySplitAddress Nvarchar(255)

UPDATE Nashville_Housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1) 

ALTER TABLE Nashville_Housing
ADD PropertySplitCity Nvarchar(255)

UPDATE Nashville_Housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress)) 

SELECT *
FROM Nashville_Housing

SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM Nashville_Housing
WHERE OwnerAddress IS NOT NULL

ALTER TABLE Nashville_Housing
ADD OwnerSplitAddress Nvarchar(255)

UPDATE Nashville_Housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)


ALTER TABLE Nashville_Housing
ADD OwnerSplitCity Nvarchar(255)

UPDATE Nashville_Housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)


ALTER TABLE Nashville_Housing
ADD OwnerSplitState Nvarchar(255)

UPDATE Nashville_Housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

SELECT *
FROM Nashville_Housing

-----------------------------------------------------------------------
-- Change Y and N to Yes and No "Sold as Vacant" Field
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM Nashville_Housing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'N' THEN 'NO'
     WHEN SoldAsVacant = 'Y' THEN 'YES'
	 ELSE SoldAsVacant
	 END
FROM Nashville_Housing

UPDATE Nashville_Housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'N' THEN 'NO'
     WHEN SoldAsVacant = 'Y' THEN 'YES'
	 ELSE SoldAsVacant
	 END


------------------------------------------------------------------
--Remove duplicate
WITH RowNumCTE AS(
SELECT *,
ROW_NUMBER () OVER (
PARTITION BY ParcelID,
             PropertyAddress,
			 SaleDate,
			 SalePrice,
			 LegalReference
			 ORDER BY
			 UniqueID) row_num

FROM Nashville_Housing
--ORDER BY ParcelID
)
SELECT * FROM RowNumCTE

WHERE row_num > 1
ORDER BY PropertyAddress


-----------------------------------------------------------
-- Delete Unused Columns

ALTER TABLE Nashville_Housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

SELECT * 
FROM Nashville_Housing