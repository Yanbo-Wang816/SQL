--marketing_performance contains daily ad spend and performance metrics
--in postgresql, there's no datetime, so I change datetime to date
create table marketing_data (
 date date,
 campaign_id varchar(50),
 geo varchar(50),
 cost float,
 impressions float,
 clicks float,
 conversions float
);

--check if marketing_performance is imported sucessfully
select * from marketing_data;


--website_revenue contains daily website revenue data by campaign_id and state
create table website_revenue (
 date date,
 campaign_id varchar(50),
 state varchar(2),
 revenue float
);

--check if website_revenue is imported successfully
select * from website_revenue;


--campaign_info contains attributes for each campaign
--postgresql does not contain auto increment, use serial instead
--notice that campaign_info does not contain revenue, so in create table query, I delete the revenue column
create table campaign_info (
 id serial primary key,
 name varchar(50),
 status varchar(50),
 last_updated_date date
);

--check if campaign_info is imported successfully
select * from campaign_info;


--1. Write a query to get the sum of impressions by day

SELECT date, sum(impressions) as total_impressions
from marketing_data
group by date
order by date;

--2. Write a query to get the top three revenue-generating states in order of best to worst.
-- How much revenue did the third best state generate?

select state, sum(revenue) as total_revenue
from website_revenue
group by state
order by total_revenue desc
limit 3;

--3. Write a query that shows total cost, impressions, clicks, and revenue of each campaign.
-- Make sure to include the campaign name in the output.

-- If contained null value, use coalesce(sum(md.cost, 0)) as total_cost instead
--notice that id in campaign_info is int, while in other two, they are characters, we need to change the data type

select ci.name as campaign_name, 
sum(md.cost) as total_cost, 
sum(md.impressions) as total_impressions,
sum(md.clicks) as total_clicks, 
sum(wr.revenue) as total_revenue
from campaign_info ci
left join marketing_data md on ci.id = md.campaign_id::integer
left join website_revenue wr on ci.id = wr.campaign_id::integer
group by ci.id, ci.name
order by ci.name;


--4 Write a query to get the number of conversions of Campaign5 by state.
--Which state generated the most conversions for this campaign?

-- Notice that state should be extracted from 'geo' column

select split_part(geo, '-', 2) as state, sum(md.conversions) as total_conversions
from marketing_data md
left join campaign_info ci on md.campaign_id::integer = ci.id
where ci.name = 'Campaign5'
group by split_part(md.geo, '-', 2)
order by total_conversions desc
limit 1


--5 In your opinion, which campaign was the most efficient, and why?

--CPCon: Cost Per Conversion
--ROAS: Return on Ad Spend
--CPC: Cost Per Click
--CR: Conversion Rate

with metrics as(
	select ci.name as campaign_name, sum(md.cost) as total_cost, sum(md.clicks) as total_clicks,
	sum(md.conversions) as total_conversions, sum(wr.revenue) as total_revenue
	from campaign_info ci
	left join marketing_data md on ci.id = md.campaign_id::integer
	left join website_revenue wr on ci.id = wr.campaign_id::integer
	group by ci.id, ci.name
)

select campaign_name, total_cost/total_conversions as CPCon, total_revenue/total_cost as ROAS, total_cost/total_clicks as CPC, total_conversions::float/total_clicks as CR
from metrics
order by CPCon, ROAS DESC, CPC, CR desc;

--I put the conclusion in the docx



--6 Write a query that showcases the best day of the week (e.g., Sunday, Monday, Tuesday, etc.) to run ads.

--To determine the best day of the week to run ads, 
--we can typically evaluate which day provides the best conversion rate, 
--or simply the highest number of conversions.
--here we use average_conversions

select to_char(date, 'Day') as day_of_week, avg(conversions) as average_conversions
from marketing_data
group by to_char(date, 'Day')
order by average_conversions desc
limit 1