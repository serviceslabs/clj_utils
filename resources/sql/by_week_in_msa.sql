-- name: sr-count-by-week
-- List the count of SRs that were booked every week
SELECT week_number, count(distinct(sr_id)) AS sr_cnt, truncate(sum(estimate), 2) as gsv
FROM (
    SELECT floor(datediff(po.booked_time, :lower_limit_time) / 7) AS week_number, po.partial_order_id sr_id, gsv_details.estimate estimate
    FROM customer_order_service_production.partial_orders po
        INNER JOIN workflow_service_production.work_items wi
        ON po.partial_order_id=wi.associated_id
        AND po.partial_order_status LIKE :sr_status
        AND wi.status != 'Excluded'
        AND po.is_test=false
        AND po.booked_time BETWEEN :lower_limit_time AND :upper_limit_time
        INNER JOIN customer_order_service_production.msa_mappings mm
        ON po.zipcode = mm.zip
        AND mm.msa_name LIKE :msa_name
        INNER JOIN (
            SELECT ml.magic_list_id ml_id, sum(ifnull(mli.high_estimate, :default_estimate)) AS estimate
            FROM magic_list_prod.magic_lists ml
            INNER JOIN magic_list_prod.magic_list_items mli
            ON ml.magic_list_id=mli.magic_list_id
            AND mli.status != 'REMOVED'
            GROUP BY ml.magic_list_id) AS gsv_details
            ON gsv_details.ml_id=po.magic_list_id) AS week_sr
GROUP BY week_sr.week_number
ORDER BY week_sr.week_number

-- name: sr-count-by-week-with-activity
-- List the count of SRs that were booked every week
SELECT week_number, count(distinct(sr_id)) AS sr_cnt, truncate(sum(estimate), 2) as gsv
FROM (
    SELECT floor(datediff(po.booked_time, :lower_limit_time) / 7) AS week_number, po.partial_order_id sr_id, gsv_details.estimate estimate
    FROM customer_order_service_production.partial_orders po
        INNER JOIN workflow_service_production.work_items wi
        ON po.partial_order_id=wi.associated_id
        AND po.partial_order_status LIKE :sr_status
        AND wi.status != 'Excluded'
        AND po.is_test=false
        AND po.booked_time BETWEEN :lower_limit_time AND :upper_limit_time
        INNER JOIN customer_order_service_production.msa_mappings mm
        ON po.zipcode = mm.zip
        AND mm.msa_name LIKE :msa_name
        INNER JOIN (
            SELECT ml.magic_list_id ml_id, sum(ifnull(mli.high_estimate, :default_estimate)) AS estimate
            FROM magic_list_prod.magic_lists ml
            INNER JOIN magic_list_prod.magic_list_items mli
            ON ml.magic_list_id=mli.magic_list_id
            AND mli.status != 'REMOVED'
            GROUP BY ml.magic_list_id) AS gsv_details
        ON gsv_details.ml_id=po.magic_list_id
    WHERE wi.work_item_id in (
          SELECT wia.work_item_id
          FROM workflow_service_production.work_item_activities wia
          WHERE wia.status LIKE :wia_status)) AS week_sr
GROUP BY week_sr.week_number
ORDER BY week_sr.week_number

