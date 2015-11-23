-- name: sr-count-by-month
-- List the count of SRs that were booked every month
SELECT mth, COUNT(DISTINCT(sr_id)) AS sr_cnt
FROM (
    SELECT month(booked_time) AS mth, po.partial_order_id sr_id
    FROM customer_order_service_production.partial_orders po
        INNER JOIN workflow_service_production.work_items wi
        ON po.partial_order_id=wi.associated_id
        AND wi.status != 'Excluded'
        AND po.is_test=false
    WHERE booked_time > :lower_limit_time
        AND booked_time < :upper_limit_time) AS month_sr
GROUP BY month_sr.mth
ORDER BY month_sr.mth

-- name: sr-with-activity-state-count-by-month
-- List the count of SRs that were booked and went into a specific activity state.
SELECT mth, COUNT(DISTINCT(sr_id)) AS sr_cnt
FROM (
    SELECT month(booked_time) AS mth, po.partial_order_id sr_id
    FROM customer_order_service_production.partial_orders po
        INNER JOIN workflow_service_production.work_items wi
        ON po.partial_order_id=wi.associated_id
        AND wi.status != 'Excluded'
        AND po.is_test=false
    WHERE booked_time > :lower_limit_time
        AND booked_time < :upper_limit_time
        AND wi.work_item_id in (
        SELECT DISTINCT(wia.work_item_id) sr_ids
        FROM workflow_service_production.work_item_activities wia
        WHERE wia.status in (:wia_statuses))) AS month_sr
GROUP BY month_sr.mth
ORDER BY month_sr.mth
