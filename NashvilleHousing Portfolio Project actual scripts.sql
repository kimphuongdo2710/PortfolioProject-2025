/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM PortfolioProject..NashvilleHousing


--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

SELECT SaleDate, CONVERT(Date,SaleDate)
FROM PortfolioProject..NashvilleHousing

	--not work
	--UPDATE NashvilleHousing
	--SET SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate Date


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
--WHERE PropertyAddress is null
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]

SELECT *
FROM NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Breaking out PropertyAddress into Individual Columns (Address, City)

SELECT 
	PropertyAddress
	, SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address
	, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress)) AS City
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress))

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Breaking out OwnerAddress into Individual Columns (Address, City)
--Option 1: Use ALTER & UPDATE
SELECT OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing
WHERE OwnerAddress is not null

SELECT OwnerAddress
		, SUBSTRING(OwnerAddress, 1, CHARINDEX(', ',OwnerAddress)-1) AS Address
		, SUBSTRING(OwnerAddress, 
					CHARINDEX(', ', OwnerAddress) + 2, 
					CHARINDEX(' ', OwnerAddress, CHARINDEX(', ', OwnerAddress) + 2) - CHARINDEX(', ', OwnerAddress) - 3)  
					AS City
		, SUBSTRING(OwnerAddress, CHARINDEX(', ', OwnerAddress, CHARINDEX(', ', OwnerAddress)+1) + 2, 2) AS State
FROM PortfolioProject.dbo.NashvilleHousing
WHERE OwnerAddress is not null

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress = SUBSTRING(OwnerAddress, 1, CHARINDEX(', ',OwnerAddress)-1)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitCity = SUBSTRING(OwnerAddress, 
					CHARINDEX(', ', OwnerAddress) + 2, 
					CHARINDEX(' ', OwnerAddress, CHARINDEX(', ', OwnerAddress) + 2) - CHARINDEX(', ', OwnerAddress) - 3)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitState NVARCHAR(255)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitState = SUBSTRING(OwnerAddress, CHARINDEX(', ', OwnerAddress, CHARINDEX(', ', OwnerAddress)+1) + 2, 2)


SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerSplitAddress, OwnerSplitCity, OwnerSplitState

--Option 2: Use PARSENAME

SELECT 
	OwnerAddress,
	PARSENAME(REPLACE(OwnerAddress,',','.'), 3) AS OwnerSplitAddress,
	PARSENAME(REPLACE(OwnerAddress,',','.'), 2) AS OwnerSplitCity,
	PARSENAME(REPLACE(OwnerAddress,',','.'), 1) AS OwnerSplitState
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'), 3)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'), 2)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitState NVARCHAR(255)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'), 1)

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2 desc


SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant),
		CASE 
			WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant
			END
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant

UPDATE PortfolioProject.dbo.NashvilleHousing
SET SoldAsVacant = CASE 
			WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant
			END


-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH ROWNUMCTE AS (
					SELECT *, 
					ROW_NUMBER () OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
										ORDER BY UniqueID) AS Rownum
					FROM PortfolioProject.dbo.NashvilleHousing)
DELETE 
FROM ROWNUMCTE
WHERE Rownum > 1

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate






-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO


















