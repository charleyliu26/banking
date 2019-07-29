use bank
go

/*At what age do on average (provide all necessary statistics to back up your suggestion) our clients take on the “most” debt (define “most”) to the bank.*/

;with cte
as
(select
	c.client_id
	,FLOOR(DATEDIFF(YY,c.dob,L.date_granted)/10)*10 age_bin
	,l.loan_id
	,disp.type
	,L.date_granted
	,l.amount
	,l.duration
	,L.status
	,a.account_id
from client c
join disp
	on C.client_id = disp.client_id
join account a
	on a.account_id=disp.account_id
join loan l
	on l.account_id=a.account_id
where disp.TYPE='owner'
)

select distinct
	 age_bin
	,AVG(amount) over (partition by age_bin) avg_amount
from cte



/* What is the longest continuous credit card transaction spending spree per customer? What age bin are they in? Are they an outlier according to stdev for their age bin?
 */
 


 ;with a
 as
(
select distinct
	t.account_id
	,datediff(dd,MIN(t.trans_date) over (PARTITION by t.account_id), max(t.trans_date) over (PARTITION by t.account_id)) date_diff
	,FLOOR(DATEDIFF(YY,c.dob,max(t.trans_date) over (PARTITION by t.account_id))/10)*10 age_bin
	,trans_mode
	,C.client_id
from trans t
join disp
	on	t.account_id = disp.account_id
join client c
	on C.client_id=disp.client_id
where trans_mode = 'Credit Card Withdrawal'
)

select 
	client_id
	,account_id
	,date_diff
	,trans_mode
	,stdev(date_diff) over (partition by age_bin) st_dev
	,case
		when date_diff > (3*stdev(date_diff) over (partition by age_bin)) + avg(date_diff) over (partition by age_bin) then 'outlier'
		when date_diff < (avg(date_diff) over (partition by age_bin) - 3*stdev(date_diff) over (partition by age_bin)) then 'outlier'
		else 'not outlier'
		end 
	,cast(avg(date_diff) over (partition by age_bin) as float) avg_spree_age_bin
	,age_bin
from a
order by date_diff desc


