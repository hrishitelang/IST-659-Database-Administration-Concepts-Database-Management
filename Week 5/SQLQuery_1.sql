use vbay

-- hmtelang
SELECT item_type, COUNT(*) AS count_of_items, 
MIN(item_reserve) AS min_item_reserve_prices , 
AVG(item_reserve) AS avg_item_reserve_prices, 
MAX(item_reserve) AS max_item_reserve_prices
FROM vb_items
GROUP BY item_type
ORDER BY item_type


-- hmtelang
SELECT item_name, item_type, item_reserve, 
min(item_reserve) OVER (PARTITION BY item_type) AS min_item_type_reserve,
max(item_reserve) OVER (PARTITION BY item_type) AS max_item_type_reserve,
avg(item_reserve) OVER (PARTITION BY item_type) AS avg_item_type_reserve
    FROM vb_items
    WHERE item_type = 'Antiques' or item_type = 'Collectables'
GROUP BY item_name, item_type, item_reserve


-- hmtelang
SELECT a.user_firstname, a.user_lastname, count(*) AS rating_counts, avg(cast(rating_value AS DECIMAL)) AS average_rating
FROM vb_users a
JOIN vb_user_ratings b ON a.user_id = b.rating_for_user_id
WHERE rating_astype = 'Seller'
GROUP BY a.user_firstname, a.user_lastname






--Question 4

--hmtelang
SELECT i.item_name AS item_name, COUNT(b.bid_id) AS number_of_bids
FROM vb_items i
JOIN vb_bids b ON i.item_id=b.bid_item_id 
WHERE i.item_type='Collectables'
GROUP BY i.item_name
HAVING COUNT(b.bid_id)>1
ORDER BY COUNT(b.bid_id) DESC




--Question 5
--hmtelang
SELECT i.item_id,i.item_name, ROW_NUMBER() OVER (ORDER BY b.bid_id) as bid_order,b.bid_amount, u.user_firstname+' '+u.user_lastname AS bidder
FROM vb_items i
JOIN vb_bids b ON i.item_id=b.bid_item_id
JOIN vb_users u ON u.user_id=b.bid_user_id
WHERE item_id='11'
GROUP BY i.item_id,i.item_name, b.bid_amount,b.bid_id , u.user_firstname+' '+u.user_lastname





--Question 6


--hmtelang
SELECT i.item_name, ROW_NUMBER() OVER (ORDER BY b.bid_id) AS bid_order,b.bid_amount,
lag(u.user_firstname+' '+u.user_lastname,1) OVER (ORDER BY b.bid_id ASC) AS prev_bidder, 
u.user_firstname+' '+u.user_lastname AS bidder, 
lag(u.user_firstname+' '+u.user_lastname,1) OVER (ORDER BY b.bid_id DESC) AS next_bidder
FROM vb_items i
JOIN vb_bids b on i.item_id=b.bid_item_id
JOIN vb_users u on u.user_id=b.bid_user_id
WHERE item_id='11'
GROUP BY i.item_name, b.bid_amount,b.bid_id , u.user_firstname+' '+u.user_lastname
ORDER BY bid_order

--Question 7
--hmtelang
SELECT a.user_id, Name1, r1.rating_value AS rating_value1, avg_rating1, r2.rating_value AS rating_value2, avg_rating2 FROM (
SELECT u.user_id, u.user_firstname+' '+u.user_lastname AS Name1, u.user_email, count(r1.rating_id) AS no_of_ratings , 
avg(cast(r1.rating_value AS float)) AS avg_rating1, avg(cast(r2.rating_value AS FLOAT)) AS avg_rating2
FROM vb_users u
JOIN vb_user_ratings r1 ON u.user_id = r1.rating_by_user_id
JOIN vb_user_ratings r2 ON u.user_id = r2.rating_for_user_id
GROUP BY u.user_id, u.user_firstname+' '+u.user_lastname, u.user_email
HAVING count(r1.rating_id) > 1
) a
JOIN vb_user_ratings r1 ON a.user_id = r1.rating_by_user_id
JOIN vb_user_ratings r2 ON a.user_id = r2.rating_for_user_id
WHERE ((r1.rating_value < avg_rating1) OR (r2.rating_value < avg_rating2))



--hmtelang
SELECT u.user_firstname+' '+u.user_lastname, u.user_email, b.total_valid_bids, b.total_items_bid, CAST(CAST(b.total_valid_bids AS DECIMAL(10,2)) / 
CAST(b.total_items_bid AS DECIMAL(10,2)) AS DECIMAL (10,2)) AS KPI
FROM vb_users AS u
JOIN (
    SELECT b.bid_user_id, COUNT(bid_user_id) AS total_valid_bids, COUNT(DISTINCT bid_item_id) AS total_items_bid
    FROM vb_bids AS b
    WHERE b.bid_status = 'ok'
    GROUP BY bid_user_id
) AS b on b.bid_user_id = u.user_id


--hmtelang
SELECT i.item_name, u.user_firstname+' '+u.user_lastname AS highest_bidder_name,
b.highest_bid_amount
FROM vb_items as i 
JOIN (
    SELECT DISTINCT (b.bid_item_id),
    first_value(b.bid_amount) OVER (PARTITION BY b.bid_item_id ORDER BY b.bid_amount DESC) AS highest_bid_amount,
    first_value(b.bid_user_id) OVER (PARTITION BY b.bid_item_id ORDER BY b.bid_amount DESC) AS highest_bid_user
    FROM vb_bids AS b
    WHERE bid_status = 'ok'
) AS b on b.bid_item_id = i.item_id
JOIN vb_users AS u ON u.user_id = b.highest_bid_user
WHERE i.item_sold = 0

--hmtelang
DECLARE @avg_sellers_ratings DECIMAL (10, 2)
SELECT @avg_sellers_ratings = (SELECT AVG(CAST(rating_value AS DECIMAL(10,2))) AS avg_rating FROM vb_user_ratings WHERE rating_astype = 'Seller')

SELECT u.user_firstname, u.user_lastname, r.num_of_reviews,
CAST(r.avg_rating AS DECIMAL(10,2)) AS avg_rating,
CAST(CAST(r.avg_rating AS DECIMAL(10,2)) - @avg_sellers_ratings AS FLOAT) AS avg_rating_offset
FROM vb_users as u
JOIN (
    SELECT r.rating_for_user_id, COUNT(r.rating_id) as 'num_of_reviews', AVG(CAST(r.rating_value AS DECIMAL(10,2))) AS 'avg_rating'
    FROM vb_user_ratings AS r
    WHERE rating_astype = 'Seller'
    GROUP BY r.rating_for_user_id
) AS r on r.rating_for_user_id = u.user_id