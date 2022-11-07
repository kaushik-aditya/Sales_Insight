-- Checking the whole Dataset
select * from sql_data.dbo.sales_data_sample


-- Data Inspection
select distinct status from sql_data.dbo.sales_data_sample 
select distinct year_id from sql_data.dbo.sales_data_sample
select distinct PRODUCTLINE from sql_data.dbo.sales_data_sample
select distinct COUNTRY from sql_data.dbo.sales_data_sample 
select distinct DEALSIZE from sql_data.dbo.sales_data_sample 
select distinct TERRITORY from sql_data.dbo.sales_data_sample

select distinct MONTH_ID from sql_data.dbo.sales_data_sample
where year_id = 2003


-- Grouping Sales by Product_Line 
select PRODUCTLINE, sum(sales) Revenue
from sql_data.dbo.sales_data_sample
group by PRODUCTLINE
order by Revenue desc


-- Grouping Sales by Year_ID
select YEAR_ID, sum(sales) Revenue
from sql_data.dbo.sales_data_sample
group by YEAR_ID
order by Revenue desc


-- Grouping Sales by Country
select country, sum(sales) Revenue
from sql_data.dbo.sales_data_sample
group by country
order by Revenue desc


-- Grouping Sales by Deal_Size
select  DEALSIZE,  sum(sales) Revenue
from sql_data.dbo.sales_data_sample
group by  DEALSIZE
order by Revenue desc


-- Finding the best month for sales in year 2005 & How much revenue generated that month ? 
select  MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from sql_data.dbo.sales_data_sample
where YEAR_ID = 2005
group by  MONTH_ID
order by Revenue desc


-- May seems to be the best month for year 2005, Product that they sell in Best Month : May & Revenue generated.  
select  MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from sql_data.dbo.sales_data_sample
where YEAR_ID = 2005 and MONTH_ID = 5 
group by  MONTH_ID, PRODUCTLINE
order by Revenue desc


-- Finding the best month for sales in year 2004 & How much revenue generated that month ? 
select  MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from sql_data.dbo.sales_data_sample
where YEAR_ID = 2004
group by  MONTH_ID
order by Revenue desc


-- November seems to be the best month for year 2004, Product that they sell in Best Month : November & Revenue generated.  
select  MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from sql_data.dbo.sales_data_sample
where YEAR_ID = 2004 and MONTH_ID = 11 
group by  MONTH_ID, PRODUCTLINE
order by Revenue desc


-- Finding the best month for sales in year 2003 & How much revenue generated that month ? 
select  MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from sql_data.dbo.sales_data_sample
where YEAR_ID = 2003
group by  MONTH_ID
order by Revenue desc


-- November seems to be the best month for year 2003 too, Product that they sell in Best Month : November & Revenue generated.  
select  MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from sql_data.dbo.sales_data_sample
where YEAR_ID = 2003 and MONTH_ID = 11 
group by  MONTH_ID, PRODUCTLINE
order by Revenue desc


--What products are most often sold together? 

select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from sql_data.dbo.sales_data_sample p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM sql_data.dbo.sales_data_sample
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

from sql_data.dbo.sales_data_sample s
order by 2 desc


-- Highest number of orders in placed in respective country
select country, sum(QUANTITYORDERED) Number_of_Orders
from sql_data.dbo.sales_data_sample
group by country
order by Number_of_Orders desc


-- Which country has the highest number of sales ?
select country, sum (sales) Revenue
from sql_data.dbo.sales_data_sample
group by country
order by Revenue desc


-- Which city has the highest number of sales in United Kingdom ?
select city, sum (sales) Revenue
from sql_data.dbo.sales_data_sample
where country = 'UK'
group by city
order by Revenue desc


-- Finding the best product in United States
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from sql_data.dbo.sales_data_sample
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by Revenue desc


-- Finding the best customer (this could be best answered with RFM)

DROP TABLE IF EXISTS #rfm;
with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from sql_data.dbo.sales_data_sample) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from sql_data.dbo.sales_data_sample)) Recency
	from sql_data.dbo.sales_data_sample
	group by CUSTOMERNAME
),
rfm_calc as
(
	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' 
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' 
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm


