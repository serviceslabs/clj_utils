-- name: sr-channels-in-msa
-- List all channels available on SR
SELECT DISTINCT(po.channel)
FROM customer_order_service_production.partial_orders po
    INNER JOIN customer_order_service_production.msa_mappings mm
    ON po.zipcode=mm.zip
    AND mm.msa_name=:msa_name
WHERE po.booked_time > :lower_limit_time
    AND po.booked_time < :upper_limit_time

-- name: sr-booked-count-in-msa
-- List the count of SRs booked by channel
SELECT po.channel AS channel, COUNT(*) AS count
FROM customer_order_service_production.partial_orders po
    INNER JOIN customer_order_service_production.msa_mappings mm
    ON po.zipcode = mm.zip
    AND mm.msa_name=:msa_name
    AND (is_test IS NULL OR is_test=false)
    INNER JOIN workflow_service_production.work_items wi
    ON po.partial_order_id=wi.associated_id
    AND wi.status != 'Excluded'
WHERE po.booked_time > :lower_limit_time
    AND po.booked_time < :upper_limit_time
GROUP BY po.channel
ORDER BY channel asc

-- name: fixed-price-sr-booked-count-in-msa
-- List the count of SRs having fixed price Skus; Count it by channel
SELECT po.channel AS channel, COUNT(*) AS count
FROM customer_order_service_production.partial_orders po
    INNER JOIN customer_order_service_production.msa_mappings mm
    ON po.zipcode = mm.zip
    AND mm.msa_name=:msa_name
    AND (is_test IS NULL OR is_test=false)
    INNER JOIN workflow_service_production.work_items wi
    ON po.partial_order_id=wi.associated_id
    AND wi.status != 'Excluded'
    INNER JOIN magic_list_prod.magic_lists ml
    ON po.magic_list_id = ml.magic_list_id
    AND ml.magic_list_id IN (
    SELECT magic_list_id
    FROM magic_list_prod.magic_list_items mli
    WHERE is_fixed_price=true)
WHERE po.booked_time > :lower_limit_time
    AND po.booked_time < :upper_limit_time
GROUP BY po.channel
ORDER BY channel ASC

-- name: sr-booked-that-were-scheduled-in-msa
-- List the count of SRs per channel that were booked in the given time interval that were scheduled
SELECT po.channel AS channel, COUNT(*) AS count
FROM customer_order_service_production.partial_orders po
    INNER JOIN customer_order_service_production.msa_mappings mm
    ON po.zipcode = mm.zip
    AND mm.msa_name=:msa_name
    AND (is_test IS NULL OR is_test=false)
    INNER JOIN workflow_service_production.work_items wi
    ON po.partial_order_id=wi.associated_id
    AND wi.status != 'Excluded'
WHERE po.booked_time > :lower_limit_time
    AND po.booked_time < :upper_limit_time
    AND po.partial_order_id IN (
    SELECT co.partial_order_id
    FROM customer_order_service_production.customer_orders co)
GROUP BY po.channel
ORDER BY channel ASC

-- name: sr-booked-that-were-completed-in-msa
-- List the count of SRs per channel that were booked in the given time interval that were completed
SELECT po.channel AS channel, COUNT(*) AS count
FROM customer_order_service_production.partial_orders po
    INNER JOIN customer_order_service_production.msa_mappings mm
    ON po.zipcode = mm.zip
    AND mm.msa_name=:msa_name
    AND (is_test IS NULL OR is_test=false)
    INNER JOIN workflow_service_production.work_items wi
    ON po.partial_order_id=wi.associated_id
    AND wi.status != 'Excluded'
WHERE po.booked_time > :lower_limit_time
    AND po.booked_time < :upper_limit_time
    AND po.partial_order_status='COMPLETED'
    AND po.partial_order_id IN (
    SELECT co.partial_order_id
    FROM customer_order_service_production.customer_orders co
    WHERE co.order_status='COMPLETED')
GROUP BY po.channel
ORDER BY channel ASC

-- name: sr-scheduled-in-given-time-in-msa
-- List the count of SRs per channel that were first scheduled in the given time interval
SELECT po.channel AS channel, COUNT(DISTINCT(po.partial_order_id)) AS count
FROM customer_order_service_production.partial_orders po
    INNER JOIN customer_order_service_production.msa_mappings mm
    ON po.zipcode = mm.zip
    AND mm.msa_name=:msa_name
    AND (is_test IS NULL OR is_test=false)
    INNER JOIN workflow_service_production.work_items wi
    ON po.partial_order_id=wi.associated_id
    AND wi.status != 'Excluded'
    INNER JOIN (
    SELECT partial_order_id, MIN(service_start_time) first_scheduled_time
    FROM customer_order_service_production.customer_orders co
    GROUP BY co.partial_order_id) first_scheduled
    ON first_scheduled.partial_order_id=po.partial_order_id
    AND first_scheduled.first_scheduled_time > :lower_limit_time
    AND first_scheduled.first_scheduled_time < :upper_limit_time
GROUP BY po.channel

-- name: sr-completed-in-given-time-in-msa
-- List the count of SRs per channel that were completed in the given time interval
SELECT po.channel AS channel, COUNT(DISTINCT(po.partial_order_id)) AS count
FROM customer_order_service_production.partial_orders po
    INNER JOIN customer_order_service_production.msa_mappings mm
    ON po.zipcode = mm.zip
    AND mm.msa_name=:msa_name
    AND (is_test IS NULL OR is_test=false)
    INNER JOIN workflow_service_production.work_items wi
    ON po.partial_order_id=wi.associated_id
    AND po.partial_order_status='COMPLETED'
    AND wi.status != 'Excluded'
    INNER JOIN (
    SELECT partial_order_id, MIN(service_start_time) first_scheduled_time
    FROM customer_order_service_production.customer_orders co
    WHERE co.order_status='COMPLETED'
    GROUP BY co.partial_order_id) first_scheduled
    ON first_scheduled.partial_order_id=po.partial_order_id
    AND first_scheduled.first_scheduled_time > :lower_limit_time
    AND first_scheduled.first_scheduled_time < :upper_limit_time
GROUP BY po.channel
ORDER BY po.channel asc
