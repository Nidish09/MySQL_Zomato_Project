select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

# 1. What is the total amount each customer spent on zomato ?

Select s.userid, sum(p.price) total_amt_spent from sales s 
inner join product p on s.product_id = p.product_id 
group by userid

# 2. How many days has each customer visited zomato ?
select userid, count(distinct created_date) as distinct_days from sales group by userid

# 3. What was the first product purchased by each customer ?
select * from
(select *, rank() over (partition by userid order by created_date asc) rnk from sales) rnk where rnk = 1

# 4. what is the most purchased items on the menu and how many times was it purchased by customers ?
select userid, count(product_id) cnt from sales where product_id =
(select product_id from sales group by product_id order by count(product_id) desc limit 1)
group by userid

# 5. Which item was the most popular for each customer ?
select * from
(select *,rank() over (partition by userid order by cnt desc) rnk from
(select userid, product_id, count(product_id) cnt from sales group by userid,product_id)a)b
where rnk = 1

# 6. Which item was purchased first by the customer after they became a member ?
Select * From
(select c.*, rank() over (partition by userid order by created_date ) rnk from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid = b.userid and created_date>=gold_signup_date )c)d
where rnk=1

# 7. Which item was purchased just before the customer became a member ?
Select * From
(select c.*, rank() over (partition by userid order by created_date desc ) rnk from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid = b.userid and created_date<=gold_signup_date )c)d
where rnk=1

# 8. What is the total orders and amount spent for each member before the became a member ?
select userid, count(created_date) as order_purchased,sum(price) as total_amt_spent from
(Select c.*, d.price from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid = b.userid and created_date<=gold_signup_date) c inner join product d on c.product_id=d.product_id)e
group by userid;

# 9. If buying  each product generates points for eg 5rs=2 zomato point and each product has different purchasing points 
#for eg  for p1 5rs=1, p2 10rs=5, p3 5rs=1 zomato points    
#calculate points collected by each customers and for which product most points have been given till now ?
select userid, sum(total_points) as total_points_earned from
(Select e.*,round(amt/points) total_points from
(select d.*, case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points from
(select c.userid,c.product_id,sum(price) amt from 
(select a.*, b.price from sales a inner join product b on a.product_id=b.product_id) c 
group by userid,product_id) d) e) f group by userid  

select f.* from
(select *, rank() over (order by total_points_earned desc) rnk from
(select product_id, sum(total_points) as total_points_earned from
(Select e.*,round(amt/points) total_points from
(select d.*, case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points from
(select c.userid,c.product_id,sum(price) amt from 
(select a.*, b.price from sales a inner join product b on a.product_id=b.product_id) c 
group by userid,product_id) d) e) f group by product_id) g) f where rnk=1

# 10. In the first one year after a cutomer joins the gold program(including their join date) irrespective of
# what the customer has purchased they earn 5 points for every 10rs spent who earned more 1 or 3 and 
# what was there points  earnings in their first year ?

select c.*, round(d.price*0.5) as total_points_earned from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid = b.userid and created_date>=gold_signup_date and created_date<= date_add(gold_signup_date, interval 1 year)) c
inner join product d on c.product_id=d.product_id 

# 11. Rank all the transations of the customers 
Select *, rank() over (partition by userid order by created_date desc) rnk from sales

# 12. Rank all the transations for each member whenever they are a zomato gold member for every non gold member transaction mark as na 
select d.*, case when rnk=0 then "na" else rnk end as Rnk from
(select c.*,cast((case when gold_signup_date is Null then 0 else rank() over (partition by userid order by created_date desc) end) as char) as rnk from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a left join goldusers_signup b
on a.userid = b.userid and created_date>=gold_signup_date ) c) d
