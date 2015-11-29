-- name: generic-sr-and-gsv-detail
-- List the count of SRs and their GSV limiting them by Booked time, MSA, SR Status, WIA status
SELECT po.*, truncate(sum(sv_details.estimate), 2) gsv
FROM customer_order_service_production.partial_orders po
    INNER JOIN customer_order_service_production.msa_mappings mm
    ON po.zipcode = mm.zip
    AND mm.msa_name LIKE :msa_name
    AND (is_test IS NULL OR is_test=false)
    INNER JOIN workflow_service_production.work_items wi
    ON po.partial_order_id=wi.associated_id
    AND wi.status != 'Excluded'
    AND po.partial_order_status like :sr_status
    INNER JOIN (
        SELECT mli.magic_list_id, SUM(IFNULL(mli.high_estimate, :default_estimate)) estimate
        FROM magic_list_prod.magic_list_items mli
        WHERE mli.status != 'REMOVED'
        GROUP BY mli.magic_list_id
    ) sv_details
    ON sv_details.magic_list_id=po.magic_list_id
WHERE po.booked_time > :lower_limit_time
    AND po.booked_time < :upper_limit_time
    AND wi.work_item_id in (
        SELECT wia.work_item_id
        FROM workflow_service_production.work_item_activities wia
        WHERE wia.status REGEXP :wia_status
    )
GROUP BY po.partial_order_id

-- name: generic-sr-count-and-gsv
-- List the count of SRs and their GSV limiting them by Booked time, MSA, SR Status, WIA status
SELECT COUNT(DISTINCT(po.partial_order_id)) sr_cnt, truncate(sum(sv_details.estimate), 2) gsv
FROM customer_order_service_production.partial_orders po
    INNER JOIN customer_order_service_production.msa_mappings mm
    ON po.zipcode = mm.zip
    AND mm.msa_name LIKE :msa_name
    AND (is_test IS NULL OR is_test=false)
    INNER JOIN workflow_service_production.work_items wi
    ON po.partial_order_id=wi.associated_id
    AND wi.status != 'Excluded'
    AND po.partial_order_status like :sr_status
    INNER JOIN (
        SELECT mli.magic_list_id, SUM(IFNULL(mli.high_estimate, :default_estimate)) estimate
        FROM magic_list_prod.magic_list_items mli
        WHERE mli.status != 'REMOVED'
        GROUP BY mli.magic_list_id
    ) sv_details
    ON sv_details.magic_list_id=po.magic_list_id
WHERE po.booked_time > :lower_limit_time
    AND po.booked_time < :upper_limit_time
    AND wi.work_item_id in (
        SELECT wia.work_item_id
        FROM workflow_service_production.work_item_activities wia
        WHERE wia.status REGEXP :wia_status
    )

-- name: generic-sr-count-and-gsv-with-history
-- List the count of SRs and their GSV with 2 levels of activity history
SELECT COUNT(DISTINCT(po.partial_order_id)) sr_cnt, truncate(sum(sv_details.estimate), 2) gsv
FROM customer_order_service_production.partial_orders po
    INNER JOIN customer_order_service_production.msa_mappings mm
    ON po.zipcode = mm.zip
    AND mm.msa_name LIKE :msa_name
    AND (is_test IS NULL OR is_test=false)
    INNER JOIN workflow_service_production.work_items wi
    ON po.partial_order_id=wi.associated_id
    AND wi.status != 'Excluded'
    AND po.partial_order_status like :sr_status
    INNER JOIN (
        SELECT mli.magic_list_id, SUM(IFNULL(mli.high_estimate, :default_estimate)) estimate
        FROM magic_list_prod.magic_list_items mli
        WHERE mli.status != 'REMOVED'
        GROUP BY mli.magic_list_id
    ) sv_details
    ON sv_details.magic_list_id=po.magic_list_id
WHERE po.booked_time > :lower_limit_time
    AND po.booked_time < :upper_limit_time
    AND wi.work_item_id in (
        SELECT wia1.work_item_id
        FROM workflow_service_production.work_item_activities wia1
        INNER JOIN workflow_service_production.work_item_activities wia2
        ON wia1.work_item_id=wia2.work_item_id
        AND wia1.status REGEXP :wia1_status_regex
        AND wia2.status REGEXP :wia2_status_regex
        AND wia1.created_time < wia2.created_time
        AND wia1.work_item_activity_id != wia2.work_item_activity_id
    )

-- name: generic-sr-count-and-gsv-by-first-scheduled-time
-- List the count of SRs and their GSV limiting them by Booked time, MSA, SR Status, WIA status
SELECT COUNT(DISTINCT(po.partial_order_id)) AS sr_cnt, truncate(sum(sv_details.estimate), 2) gsv
FROM customer_order_service_production.partial_orders po
INNER JOIN customer_order_service_production.msa_mappings mm
ON po.zipcode = mm.zip
AND mm.msa_name LIKE :msa_name
AND (is_test IS NULL OR is_test=false)
INNER JOIN workflow_service_production.work_items wi
ON po.partial_order_id=wi.associated_id
AND wi.status != 'Excluded'
AND po.partial_order_status like :sr_status
INNER JOIN (
    SELECT partial_order_id, MIN(service_start_time) first_scheduled_time
    FROM customer_order_service_production.customer_orders co
    GROUP BY co.partial_order_id) first_scheduled
ON first_scheduled.partial_order_id=po.partial_order_id
AND first_scheduled.first_scheduled_time BETWEEN :lower_limit_time AND :upper_limit_time
INNER JOIN (
    SELECT mli.magic_list_id, SUM(IFNULL(mli.high_estimate, :default_estimate)) estimate
    FROM magic_list_prod.magic_list_items mli
    WHERE mli.status != 'REMOVED'
    GROUP BY mli.magic_list_id
) sv_details
ON sv_details.magic_list_id=po.magic_list_id

-- name: count-completed-srs
-- List the list of SRs and their GSV that were completed on the given time
SELECT COUNT(DISTINCT(po.partial_order_id)) AS sr_cnt, truncate(sum(sv_details.estimate), 2) gsv
FROM customer_order_service_production.partial_orders po
INNER JOIN customer_order_service_production.msa_mappings mm
ON po.zipcode = mm.zip
AND mm.msa_name LIKE :msa_name
AND (is_test IS NULL OR is_test=false)
INNER JOIN workflow_service_production.work_items wi
ON po.partial_order_id=wi.associated_id
AND wi.status != 'Excluded'
INNER JOIN (
    SELECT mli.magic_list_id, SUM(IFNULL(mli.high_estimate, :default_estimate)) estimate
    FROM magic_list_prod.magic_list_items mli
    WHERE mli.status != 'REMOVED'
    GROUP BY mli.magic_list_id
) sv_details
ON sv_details.magic_list_id=po.magic_list_id
WHERE po.partial_order_id in (
	SELECT co.partial_order_id
	FROM customer_order_service_production.customer_orders co
	WHERE co.completed_time BETWEEN :lower_limit_time AND :upper_limit_time
	AND order_status='COMPLETED'
);
