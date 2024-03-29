use banking  --database bank is the cleansed version
go
--account

if OBJECT_ID('bank.dbo.account') is not null
begin
drop table bank.dbo.account
end

SELECT
	cast([account_id] as int) account_id
   ,cast([district_id] as int) district_id
   ,case
		when [frequency] = 'POPLATEK MESICNE' then 'Monthly Issuance'
		when [frequency] = 'POPLATEK TYDNE' then 'Weekly Issuance'
		when [frequency] = 'POPLATEK PO OBRATU' then 'Issuance After Transaction'
	end frequency
   ,cast([date] as date) Date_of_creation
into bank.dbo.account
FROM [banking].[dbo].[account]

-- card
if OBJECT_ID('bank.dbo.card') is not null
begin
drop table bank.dbo.card
end

SELECT 
	cast([card_id] as int) card_id
      ,cast([disp_id] as int) disp_id
      ,[type] 
      ,cast([issued] as date) date_issued 
	
	into bank.dbo.card
  FROM [dbo].[card]

-- client
if OBJECT_ID('bank.dbo.client') is not null
begin
drop table bank.dbo.client
end
;with cte
as
(
SELECT 
	cast([client_id] as int) client_id
      ,try_cast(cast([birth_number]+19000000 as varchar(20)) as date) male_dob
	  ,try_cast(cast([birth_number]+19000000-5000 as varchar(50)) as date) female_dob
      ,cast([district_id] as int) district_id

  FROM [dbo].[client]
)

select
	client_id
	,case
		when male_dob is NULL then 'F'
		when female_dob is NULL then 'M'
		end gender
	,case 
		when male_dob is null then female_dob
		when female_dob is NULL then male_dob
		end dob
	,case 
		when male_dob is null then datediff(yy,female_dob,GETDATE())
		when female_dob is NULL then datediff(yy,male_dob, GETDATE())
		end age
	,district_id
into bank.dbo.client
from cte

--disp

if OBJECT_ID('bank.dbo.disp') is not null
begin
drop table bank.dbo.disp
end

SELECT cast([disp_id] as int) disp_id
      ,cast([client_id] as int) client_id
      ,cast([account_id] as int) account_id
      ,[type]
into bank.dbo.disp
FROM [dbo].[disp]


--district

if OBJECT_ID('bank.dbo.district') is not null
begin
drop table bank.dbo.district
end
SELECT 
	   cast([A1] as int) district_id
      ,Cast([A2] as varchar(50)) district_name
      ,cast([A3] as varchar (50)) region
      ,cast([A4] as   int) no_of_inhabitants
      ,cast([A5] as	  int) [<499]
      ,cast([A6] as	  int) [500-1999]
      ,cast([A7] as	  int) [2000-9999]
      ,cast([A8] as	  int) [>10000]
      ,cast([A9] as	  int) no_of_cities
      ,cast([A10] as  float) ratio_of_urban_inhabitants
      ,cast([A11] as  int) avg_salary
      ,try_cast([A12] as  float) unemploy_rate_1995
      ,cast([A13] as float) unemploy_rate_1996
      ,cast([A14] as  int) no_of_entrepreneurs_per_1000
      ,try_cast([A15] as  int) no_of_crimes_1995
      ,cast([A16] as  int) no_of_crimes_1996

	into bank.dbo.district
  FROM [dbo].[district]

--loan
if OBJECT_ID('bank.dbo.loan') is not null
begin
drop table bank.dbo.loan
end
SELECT cast([loan_id] as int) [loan_id]
      ,cast([account_id] as int) [account_id] 
      ,cast([date] as date) date_granted
      ,cast([amount] as int) amount 
      ,cast([duration] as int) duration
      ,cast([payments] as float) monthly_payment
      ,case
		when status = 'A' then 'contract finished, no problems'
		when status = 'B' then 'contract finished, loan not payed'
		when status = 'C' then 'running contract, OK thus-far'
		when status = 'D' then 'running contract, client in debt '
		else null
		end [status]
	into bank.dbo.loan
  FROM [dbo].[loan]

--order
if OBJECT_ID('bank.dbo.order') is not null
begin
drop table [bank.dbo.order]
end
SELECT cast([order_id] as int) [order_id]
      ,cast([account_id] as int) [account_id]
      ,[bank_to]
      ,cast([account_to] as int) [account_to]
      ,cast([amount] as float) order_amount
      ,case
		when [k_symbol] = 'POJISTNE' then 'Insurance Payment'
		when [k_symbol] = 'SIPO' then 'Household Payment'
		when [k_symbol] = 'LEASING' then 'Leasing Payment'
		when [k_symbol] = 'UVER' then 'Loan Payment'
		else null
		end characterisation
		
into [bank.dbo.order]
  FROM [dbo].[order]


--trans
if OBJECT_ID('bank.dbo.trans') is not null
begin
drop table bank.dbo.trans
end
SELECT cast([trans_id] as int) [trans_id]
      ,cast([account_id] as int) [account_id] 
      ,cast([date] as date) trans_date
      ,case
		when type = 'PRIJEM' then 'Credit'
		when type = 'VYDAJ' then 'Debit (withdrawal)'
		else null
		end trans_type
      ,case
		when operation = 'VYBER KARTOU' then 'Credit Card Withdrawal'
		when operation = 'VKLAD' then 'Credit in Cash'
		when operation = 'PREVOD Z UCTU' then 'Collection from Another Bank'
		when operation = 'VYBER' then 'Withdrawal in Cash'
		when operation = 'PREVOD NA UCET' then 'Remittance to Another Bank'
		else null
		end trans_mode
      ,cast([amount] as float) trans_amount
      ,cast([balance] as float) balance
      ,case
		when [k_symbol] = 'POJISTNE' then 'Insurance Payment'
		when [k_symbol] = 'SLUZBY' then 'Payment of Statement'
		when [k_symbol] = 'UROK' then 'Interest Credited'
		when [k_symbol] = 'SANKC. UROK' then 'Sanction Interest if Negative Balance'
		when [k_symbol] = 'SIPO' then 'Household Payment'
		when [k_symbol] = 'DUCHOD' then 'Old-age Pension Payment'
		when [k_symbol] = 'UVER' then 'Loan Payment'
		else null
		end characterisation
      ,case
		when Bank = '' then NULL
		else bank
		end partner_bank 
      ,case
		when account = '' then null
		else cast(account as int)
		end partner_account

into bank.dbo.trans
  FROM [dbo].[trans]

