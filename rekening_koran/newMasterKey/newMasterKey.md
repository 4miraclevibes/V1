--CURRENT--

SELECT [id]
      ,[customer_name] = BILL_NAME_RK
      ,[btp] = BILL_RK
      ,[category] = NEW
      ,[match_count] = 100
      ,[total_transactions] = 100
      ,[match_percentage] = 100
      ,[last_line_number] = 100
      ,[created_date] = NOW
      ,[type] = MT
  FROM [POWERAPPS].[dbo].[MASTER_CUSTOMER_BTP_PATTERN]



--NEW DATA--

SELECT [BILL_NAME_RK]
      ,[BILL_RK]
  FROM [POWERAPPS].[dbo].[MASTER KEY NEW]


