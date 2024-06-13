--CLEANING DATA IN SQL QUERIES

SELECT *
FROM Portfolio.dbo.[Nashville Housing Data for Data Cleaning]




-- 1.CONVERTING DATA TYPES - Standardizing the Date Format

SELECT SaleDate, CONVERT (Date, SaleDate)
FROM Portfolio.dbo.[Nashville Housing Data for Data Cleaning]

--UPDATE [Nashville Housing Data for Data Cleaning] --Did not work so strying with ALTER TABLE
--SET SaleDate  = CONVERT(Date,SaleDate)

ALTER TABLE[Nashville Housing Data for Data Cleaning]
ADD SaleDateConverted Date;

UPDATE [Nashville Housing Data for Data Cleaning]
SET SaleDateConverted = CONVERT(Date,SaleDate)

SELECT SaleDateConverted
FROM Portfolio.dbo.[Nashville Housing Data for Data Cleaning]

-----------------------------------------------------------------------------------------------------------------------------------------------------------------


-- 2.HANDLING NULL VALUES - Populate Property Address data - (POPULATING WITH SIMILAR VALUES)
SELECT *
FROM Portfolio.dbo.[Nashville Housing Data for Data Cleaning]
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID --notice how two same Parcel IDs have the same address. we can use this to populate the NULL addresses

SELECT a.uniqueID, a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio.dbo.[Nashville Housing Data for Data Cleaning] a 
JOIN Portfolio.dbo.[Nashville Housing Data for Data Cleaning] b			--we join the column to the same column
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID --making sure it's not the same row
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio.dbo.[Nashville Housing Data for Data Cleaning] a
JOIN Portfolio.dbo.[Nashville Housing Data for Data Cleaning] b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL
--executing the previous SELECT query to check, we see that there are no values in the query which means it has been successful

-----------------------------------------------------------------------------------------------------------------------------------------------------------------


-- 3a. SPLITTING COLUMNS (Method I) - Breaking out Property Address into Individual Columns (Address, City, State) 
SELECT PropertyAddress
FROM Portfolio.dbo.[Nashville Housing Data for Data Cleaning]
--WHERE PropertyAddress IS NULL

SELECT
SUBSTRING(propertyaddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address, --the -1 removes the comma by removing one character from the substring we want.
SUBSTRING(propertyaddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM Portfolio.dbo.[Nashville Housing Data for Data Cleaning]

ALTER TABLE Portfolio.dbo.[Nashville Housing Data for Data Cleaning] --creating the new column for Address
ADD PropertyAddressSplit nvarchar(255);

UPDATE Portfolio.dbo.[Nashville Housing Data for Data Cleaning]
SET PropertyAddressSplit = SUBSTRING(propertyaddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE Portfolio.dbo.[Nashville Housing Data for Data Cleaning] --creating the new column for City
ADD PropertyCitySplit nvarchar(255);

UPDATE Portfolio.dbo.[Nashville Housing Data for Data Cleaning]
SET PropertyCitySplit = SUBSTRING(propertyaddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

SELECT propertyaddresssplit, propertycitysplit
FROM Portfolio.dbo.[Nashville Housing Data for Data Cleaning]

-----------------------------------------------------------------------------------------------------------------------------------------------------------------


-- 3b. SPLITTING COLUMNS (Method II)- Breaking out Owner Address into Individual Columns (Address, City, State) 
SELECT OwnerAddress
FROM Portfolio.dbo.[Nashville Housing Data for Data Cleaning]

SELECT 
PARSENAME(REPLACE(owneraddress, ',', '.'), 3),
PARSENAME(REPLACE(owneraddress, ',', '.'), 2),
PARSENAME(REPLACE(owneraddress, ',', '.'), 1)
FROM Portfolio.dbo.[Nashville Housing Data for Data Cleaning]

ALTER TABLE Portfolio.dbo.[Nashville Housing Data for Data Cleaning] --creating the new column for Address
ADD OwnerAddress_Split nvarchar(255);

UPDATE Portfolio.dbo.[Nashville Housing Data for Data Cleaning]
SET OwnerAddress_Split = PARSENAME(REPLACE(owneraddress, ',', '.'), 3)

ALTER TABLE Portfolio.dbo.[Nashville Housing Data for Data Cleaning] --creating the new column for City
ADD OwnerCity_Split nvarchar(255);

UPDATE Portfolio.dbo.[Nashville Housing Data for Data Cleaning]
SET OwnerCity_Split = PARSENAME(REPLACE(owneraddress, ',', '.'), 2)

ALTER TABLE Portfolio.dbo.[Nashville Housing Data for Data Cleaning] --creating the new column for State
ADD OwnerState_Split nvarchar(255);

UPDATE Portfolio.dbo.[Nashville Housing Data for Data Cleaning]
SET OwnerState_Split = PARSENAME(REPLACE(owneraddress, ',', '.'), 1)

SELECT OwnerAddress_Split, OwnerCity_Split, OwnerState_Split --verifying all three new columns
FROM Portfolio.dbo.[Nashville Housing Data for Data Cleaning]

-----------------------------------------------------------------------------------------------------------------------------------------------------------------


-- 4.Change Y and N to 'Yes' and 'No' in 'Sold as Vacant' column
SELECT DISTINCT(SoldAsVacant), COUNT(soldasvacant) AS CNT
FROM Portfolio.dbo.[Nashville Housing Data for Data Cleaning]
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM Portfolio.dbo.[Nashville Housing Data for Data Cleaning]

UPDATE Portfolio.dbo.[Nashville Housing Data for Data Cleaning]
SET SoldAsVacant = CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

SELECT DISTINCT(SoldAsVacant), COUNT(soldasvacant) AS CNT --verifying
FROM Portfolio.dbo.[Nashville Housing Data for Data Cleaning]
GROUP BY SoldAsVacant
ORDER BY 2

-----------------------------------------------------------------------------------------------------------------------------------------------------------------


-- 5.REMOVE DUPLICATES - If data across all columns is the exact same, we need to remove the duplicates.

WITH RowNumCTE AS (
SELECT	*,
	ROW_NUMBER() OVER(   --row number helps identify duplicates
	PARTITION BY ParcelID, 
				propertyaddress,
				saleprice,
				saledate,
				legalreference
				ORDER BY 
					uniqueID
					) row_num
FROM Portfolio.dbo.[Nashville Housing Data for Data Cleaning]
)
--ORDER BY ParcelID
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress



WITH RowNumCTE AS (     
SELECT	*,
	ROW_NUMBER() OVER(   
	PARTITION BY ParcelID, 
				propertyaddress,
				saleprice,
				saledate,
				legalreference
				ORDER BY 
					uniqueID
					) row_num
FROM Portfolio.dbo.[Nashville Housing Data for Data Cleaning]
)
--ORDER BY ParcelID
DELETE						 --exact same query but now deleting
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress

-----------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 6. DELETE UNUSED COLUMNS - Delete the Property & Owner Address which we split earlier into seperate columns. (Making a copy of data before deleting columns).

SELECT *
FROM Portfolio.dbo.[Nashville Housing Data for Data Cleaning]

ALTER TABLE Portfolio.dbo.[Nashville Housing Data for Data Cleaning]
DROP COLUMN owneraddress, taxdistrict, propertyaddress		

ALTER TABLE Portfolio.dbo.[Nashville Housing Data for Data Cleaning]
DROP COLUMN owneraddresssplit, saledate				--owneraddresssplit was created by mistake		